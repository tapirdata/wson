
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

    int fetchValueText();
    int fetchValueLiteralEmpty();
    int fetchValueLiteral();

    int fetchArrayText();
    int fetchArrayValue();

    int putValue(Handle<Value>);
    int putArrayValue(Handle<Value>);

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
  NULL, // OBJECT
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
  &State::fetchArrayText, // TEXT
  NULL, // OBJECT
  NULL, // ENDOBJECT
  &State::fetchArrayValue,// ARRAY
  &State::toArrayClose,   // ENDARRAY
  NULL, // IS
  &State::fetchArrayValue, // LITERAL
  NULL, // PIPE
  NULL, // QUOTE
  NULL, // END
  NULL  // DEFAULT
}; 

State::Tx txsArrayNext[] = {
  &State::fetchArrayText, // TEXT
  NULL, // OBJECT
  NULL, // ENDOBJECT
  &State::fetchArrayValue,// ARRAY
  NULL, // ENDARRAY
  NULL, // IS
  &State::fetchArrayValue, // LITERAL
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
  if (!put) {
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
  if (!put) {
    return SYNTAX_ERROR;
  }
  done_ = true;
  return (parent_->*put)(value);
}  

int State::fetchValueText() {
  source_.pullUnescapedBuffer();
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
  source_.pullUnescapedString();
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
  source_.pullUnescapedBuffer();
  return putArrayValue(source_.nextBuffer.getHandle());
}

int State::fetchArrayValue() {
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
      // std::cout << "scan done" << std::endl;
      return 0;
    }
  }  
}

  

class Parser {

  public:  
    Parser() {}

    void MakeError(const SourceBuffer& source, TargetBuffer& msg) {
      msg.append(std::string("Unexpected '"));
      msg.push(source.nextChar);
      msg.append(std::string("' at '"));
      msg.append(source.getBuffer(), 0, source.nextIdx - 1);
      msg.push('^');
      msg.append(source.getBuffer(), source.nextIdx - 1);
      msg.append(std::string("'"));
    }  

    void parse(Handle<String> s, Handle<Value> &result, TargetBuffer& errorMsg) {
      int err;
      SourceBuffer source;
      source.appendHandle(s);
      err = source.next();
      if (err) {
        return MakeError(source, errorMsg);
      }
      State state(source, &stageValueStart);
      err = state.scan();
      if (err) {
        return MakeError(source, errorMsg);
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


