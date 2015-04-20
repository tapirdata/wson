
#include "parser.h"
#include "target_buffer.h"
#include "source_buffer.h"
#include <cstdlib>

using v8::Handle;
using v8::Local;
using v8::Value;
using v8::String;
using v8::Number;
using v8::Boolean;
using v8::Array;
using v8::Object;

class Stage;

class State {
  public:
    typedef int (State::*Tx)();
    typedef int (State::*Put)(Handle<Value>);

    State(SourceBuffer& source, Stage* stage, State* parent=NULL):
      source_(source),
      stage_(stage),
      parent_(parent),
      done_(false)
    {}  
    SourceBuffer& source_;
    Stage *stage_;
    State *parent_;
    Handle<Value> value;
    Handle<String> key_;
    bool done_;

    int toEnd();
    int toValueLiteral();
    int toValueClose();

    int toArrayStart();
    int toArrayNext();
    int toArrayClose();

    int toObjectStart();
    int toObjectKeyEmpty();
    int toObjectColon();
    int toObjectNext();
    int toObjectClose();

    int fetchValueText();
    int fetchValueLiteralEmpty();
    int fetchValueLiteral();

    int fetchArrayText();
    int fetchArrayChild();

    int fetchObjectKey();
    int fetchObjectText();
    int fetchObjectChild();

    int putValue(Handle<Value>);
    int putArrayValue(Handle<Value>);
    int putObjectValue(Handle<Value>);

    int scan();
};

class Stage {
  public:
    Stage(State::Tx* transitions, State::Put put=NULL):
      transitions_(transitions),
      put_(put)
    {}  

    enum ExtraCtype {
      DEFAULT = SourceBuffer::END + 1
    };

    State::Tx getTransition(SourceBuffer::Ctype type) const {
      State::Tx transition = transitions_[type];
      if (transition == NULL) {
        transition = transitions_[DEFAULT];
      }
      return transition;
    }

    State::Put getPut() const {
      return put_;
    }  

  private:  
    State::Tx* transitions_;
    State::Put put_;
};

State::Tx txsValueStart[] = {
  &State::fetchValueText, // TEXT
  &State::toObjectStart,  // OBJECT
  NULL, // ENDOBJECT
  &State::toArrayStart,   // ARRAY
  NULL, // ENDARRAY
  NULL, // IS
  &State::toValueLiteral, // LITERAL
  NULL, // PIPE
  NULL, // QUOTE
  NULL, // END
  NULL  // DEFAULT
}; 

State::Tx txsValueLiteral[] = {
  &State::fetchValueLiteral, // TEXT
  NULL, // OBJECT
  NULL, // ENDOBJECT
  NULL, // ARRAY
  NULL, // ENDARRAY
  NULL, // IS
  NULL, // LITERAL
  NULL, // PIPE
  NULL, // QUOTE
  NULL, // END
  &State::fetchValueLiteralEmpty, // DEFAULT
}; 

State::Tx txsValueEnd[] = {
  NULL, // TEXT
  NULL, // OBJECT
  NULL, // ENDOBJECT
  NULL, // ARRAY
  NULL, // ENDARRAY
  NULL, // IS
  NULL, // LITERAL
  NULL, // PIPE
  NULL, // QUOTE
  &State::toEnd, // END
  &State::toValueClose, // DEFAULT
};  

State::Tx txsArrayStart[] = {
  &State::fetchArrayText,  // TEXT
  &State::fetchArrayChild, // OBJECT
  NULL, // ENDOBJECT
  &State::fetchArrayChild, // ARRAY
  &State::toArrayClose,    // ENDARRAY
  NULL, // IS
  &State::fetchArrayChild, // LITERAL
  NULL, // PIPE
  NULL, // QUOTE
  NULL, // END
  NULL  // DEFAULT
}; 

State::Tx txsArrayNext[] = {
  &State::fetchArrayText,  // TEXT
  &State::fetchArrayChild, // OBJECT
  NULL, // ENDOBJECT
  &State::fetchArrayChild, // ARRAY
  NULL, // ENDARRAY
  NULL, // IS
  &State::fetchArrayChild, // LITERAL
  NULL, // PIPE
  NULL, // QUOTE
  NULL, // END
  NULL  // DEFAULT
}; 

State::Tx txsArrayHave[] = {
  NULL, // TEXT
  NULL, // OBJECT
  NULL, // ENDOBJECT
  NULL, // ARRAY
  &State::toArrayClose, // ENDARRAY
  NULL, // IS
  NULL, // LITERAL
  &State::toArrayNext,  // PIPE
  NULL, // QUOTE
  NULL, // END
  NULL  // DEFAULT
}; 

State::Tx txsObjectStart[] = {
  &State::fetchObjectKey,   // TEXT
  NULL, // OBJECT
  &State::toObjectClose,    // ENDOBJECT
  NULL, // ARRAY
  NULL, // ENDARRAY
  NULL, // IS
  &State::toObjectKeyEmpty, // LITERAL
  NULL, // PIPE
  NULL, // QUOTE
  NULL, // END
  NULL  // DEFAULT
}; 

State::Tx txsObjectNext[] = {
  &State::fetchObjectKey, // TEXT
  NULL, // OBJECT
  NULL, // ENDOBJECT
  NULL, // ARRAY
  NULL, // ENDARRAY
  NULL, // IS
  &State::toObjectKeyEmpty, // LITERAL
  NULL, // PIPE
  NULL, // QUOTE
  NULL, // END
  NULL  // DEFAULT
}; 


State::Tx txsObjectHaveKey[] = {
  NULL, // TEXT
  NULL, // OBJECT
  &State::toObjectClose, // ENDOBJECT
  NULL, // ARRAY
  NULL, // ENDARRAY
  &State::toObjectColon, // IS
  NULL, // LITERAL
  &State::toObjectNext, // PIPE
  NULL, // QUOTE
  NULL, // END
  NULL  // DEFAULT
}; 

State::Tx txsObjectHaveColon[] = {
  &State::fetchObjectText, // TEXT
  &State::fetchObjectChild, // OBJECT
  NULL, // ENDOBJECT
  &State::fetchObjectChild, // ARRAY
  NULL, // ENDARRAY
  NULL, // IS
  &State::fetchObjectChild, // LITERAL
  NULL, // PIPE
  NULL, // QUOTE
  NULL, // END
  NULL  // DEFAULT
}; 

State::Tx txsObjectHaveValue[] = {
  NULL, // TEXT
  NULL, // OBJECT
  &State::toObjectClose, // ENDOBJECT
  NULL, // ARRAY
  NULL, // ENDARRAY
  NULL, // IS
  NULL, // LITERAL
  &State::toObjectNext, // PIPE
  NULL, // QUOTE
  NULL, // END
  NULL  // DEFAULT
}; 

State::Tx txsEmpty[] = {
  NULL, // TEXT
  NULL, // OBJECT
  NULL, // ENDOBJECT
  NULL, // ARRAY
  NULL, // ENDARRAY
  NULL, // IS
  NULL, // LITERAL
  NULL, // PIPE
  NULL, // QUOTE
  NULL, // END
  NULL  // DEFAULT
}; 

Stage stageValueStart(txsValueStart, &State::putValue);
Stage stageValueLiteral(txsValueLiteral);
Stage stageValueEnd(txsValueEnd);
Stage stageArrayStart(txsArrayStart, &State::putArrayValue);
Stage stageArrayNext(txsArrayNext, &State::putArrayValue);
Stage stageArrayHave(txsArrayHave);
Stage stageObjectStart(txsObjectStart);
Stage stageObjectNext(txsObjectNext);
Stage stageObjectHaveKey(txsObjectHaveKey);
Stage stageObjectHaveColon(txsObjectHaveColon, &State::putObjectValue);
Stage stageObjectHaveValue(txsObjectHaveValue);

int State::toEnd() {
  done_ = true;
  return 0;
};

int State::toValueLiteral() {
  source_.next();
  stage_ = &stageValueLiteral;
  return 0;
}  

int State::toValueClose() {
  if (!parent_) {
    return SYNTAX_ERROR;
  }
  State::Put put = parent_->stage_->getPut();
  if (put == NULL) {
    return SYNTAX_ERROR;
  }
  done_ = true;
  return (parent_->*put)(value);
}  

int State::toArrayStart() {
  source_.next();
  State state(source_, &stageArrayStart, this);
  state.value = NanNew<Array>();
  return state.scan();
}  

int State::toArrayNext() {
  source_.next();
  stage_ = &stageArrayNext;
  return 0;
}

int State::toArrayClose() {
  source_.next();
  if (!parent_) {
    return SYNTAX_ERROR;
  }
  State::Put put = parent_->stage_->getPut();
  if (put == NULL) {
    return SYNTAX_ERROR;
  }
  done_ = true;
  return (parent_->*put)(value);
}  

int State::toObjectStart() {
  source_.next();
  State state(source_, &stageObjectStart, this);
  state.value = NanNew<Object>();
  return state.scan();
}  

int State::toObjectKeyEmpty() {
  source_.next();
  key_ = NanNew<String>();
  value.As<Object>()->Set(key_, NanTrue());
  stage_ = &stageObjectHaveKey;
  return 0;
}  

int State::toObjectColon() {
  source_.next();
  stage_ = &stageObjectHaveColon;
  return 0;
}  

int State::toObjectNext() {
  source_.next();
  stage_ = &stageObjectNext;
  return 0;
}  

int State::toObjectClose() {
  source_.next();
  if (!parent_) {
    return SYNTAX_ERROR;
  }
  State::Put put = parent_->stage_->getPut();
  if (!put) {
    return SYNTAX_ERROR;
  }
  done_ = true;
  return (parent_->*put)(value);
}  

int State::fetchValueText() {
  int err = source_.pullUnescapedBuffer();
  if (err) {
    return err;
  }
  value = source_.nextBuffer.getHandle();
  stage_ = &stageValueEnd;
  return 0;
};

int State::fetchValueLiteralEmpty() {
  value = NanNew<String>();
  stage_ = &stageValueEnd;
  return 0;
}  

int State::fetchValueLiteral() {
  int err = source_.pullUnescapedString();
  if (err) {
    return err;
  }
  value = source_.nextBuffer.getHandle();
  stage_ = &stageValueEnd;
  const std::string& text = source_.nextString;
  bool valueOk = false;
  if (text.size() == 1) {
    switch(text[0]) {
      case 't': {
        value = NanTrue();
        valueOk = true;
        break;
      }
      case 'f': {
        value = NanFalse();
        valueOk = true;
        break;
      }
      case 'n': {
        value = NanNull();
        valueOk = true;
        break;
      }
      case 'u': {
        value = NanUndefined();
        valueOk = true;
        break;
      }
    }
  }
  if (not valueOk) {
    const char* begin = text.data();
    char* end;
    int x = strtol(begin, &end, 10);
  if (end == begin + text.size()) {
    value = NanNew<Number>(x);
    } else {
      double x = strtod(begin, &end);
      if (end == begin + text.size()) {
        value = NanNew<Number>(x);
      } else {
        return SYNTAX_ERROR;
      }  
    }
  }
  stage_ = &stageValueEnd;
  return 0;
};

int State::fetchArrayText() {
  int err = source_.pullUnescapedBuffer();
  if (err) {
    return err;
  }
  return putArrayValue(source_.nextBuffer.getHandle());
}

int State::fetchArrayChild() {
  State state(source_, &stageValueStart, this);
  return state.scan();
}  

int State::fetchObjectKey() {
  int err = source_.pullUnescapedBuffer();
  if (err) {
    return err;
  }
  key_ = source_.nextBuffer.getHandle();
  value.As<Object>()->Set(key_, NanTrue());
  stage_ = &stageObjectHaveKey;
  return 0;
}

int State::fetchObjectText() {
  int err = source_.pullUnescapedBuffer();
  if (err) {
    return err;
  }
  value.As<Object>()->Set(key_, source_.nextBuffer.getHandle());
  stage_ = &stageObjectHaveValue;
  return 0;
}  

int State::fetchObjectChild() {
  State state(source_, &stageValueStart, this);
  return state.scan();
}  

int State::putValue(Handle<Value> x) {
  value = x;
  stage_ = &stageValueEnd;
  return 0;
}  

int State::putArrayValue(Handle<Value> x) {
  Handle<Array> arrayValue = value.As<Array>();
  arrayValue->Set(arrayValue->Length(), x);
  stage_ = &stageArrayHave;
  return 0;
}  

int State::putObjectValue(Handle<Value> x) {
  value.As<Object>()->Set(key_, x);
  stage_ = &stageObjectHaveValue;
  return 0;
}  


int State::scan() {
  int err;
  while (true) {
    Tx transition = stage_->getTransition(source_.nextType);
    // std::cout << "scan: nextType=" << source_.nextType << " transition=" << transition << std::endl;
    if (transition == NULL) {
      return SYNTAX_ERROR;
    }
    err = (this->*transition)();
    if (err) {
      return err;
    } else if (done_) {
      return 0;
    }
  }  
}

  

class Parser {

  public:  
    Parser() {}

    void MakeError(const SourceBuffer& source, TargetBuffer& msg) {
      size_t errIdx = source.nextIdx > 0 ? source.nextIdx - 1 : 0; 
      uint16_t errChar = source.nextIdx > 0 ? source.nextChar : 0; 
      msg.append(std::string("Unexpected '"));
      if (errChar) {
        msg.push(source.nextChar);
      }
      msg.append(std::string("' at '"));
      msg.append(source.getBuffer(), 0, errIdx);
      msg.push('^');
      msg.append(source.getBuffer(), errIdx);
      msg.append(std::string("'"));
    }  

    void parse(Handle<String> s, Handle<Value> &result, TargetBuffer& errorMsg) {
      int err;
      SourceBuffer source;
      source.appendHandle(s);
      err = source.next();
      if (err) {
        MakeError(source, errorMsg);
        return;
      }
      State state(source, &stageValueStart);
      err = state.scan();
      if (err) {
        MakeError(source, errorMsg);
        return;
      }
      result = state.value;
    }

    static void Init();
};

void Parser::Init() {
}


NAN_METHOD(Unescape) {
  TargetBuffer target;
  if (args.Length() < 1 || !(args[0]->IsString())) {
    return NanThrowTypeError("First argument should be a string");
  }
  Local<String> s = args[0].As<String>();
  int err = target.appendHandleUnescaped(s);
  if (err) {
    return NanThrowError("Unexpected escape sequence");
  }
  NanReturnValue(target.getHandle());
}

NAN_METHOD(Parse) {
  if (args.Length() < 1 || !(args[0]->IsString())) {
    return NanThrowTypeError("First argument should be a string");
  }
  Local<String> s = args[0].As<String>();
  Local<Value> result;
  TargetBuffer errorMsg;
  Parser parser;
  parser.parse(s, result, errorMsg);
  if (errorMsg.getBuffer().size()) {
    return NanThrowError(errorMsg.getHandle());
  }    
  NanReturnValue(result);
}

void InitParser() {
  Parser::Init();
}


