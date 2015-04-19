
#include "parser.h"
#include "target_buffer.h"
#include "source_buffer.h"

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
    typedef void (State::*txFn)();

    State(SourceBuffer& source, Stage* stage):
      source_(source),
      stage_(stage)
    {}  
    SourceBuffer& source_;
    Stage *stage_;
    Handle<Value> value_;
    Handle<String> key_;
    void valueText() {};
    void valueLiteral() {};
};

class Stage {
  public:
    Stage(State::txFn* transitions):
      transitions_(transitions)
    {}  
    State::txFn* transitions_;

    enum ExtraCtype {
      DEFAULT = SourceBuffer::END + 1
    };
};

State::txFn valueStartTx[] = {
  &State::valueText, // TEXT
  NULL, // OBJECT
  NULL, // ENDOBJECT
  NULL, // ARRAY
  NULL, // ENDARRAY
  NULL, // IS
  &State::valueLiteral, // LITERAL
  NULL, // PIPE
  NULL, // QUOTE
  NULL, // END
  NULL  // DEFAULT
};  

Stage valueStart(valueStartTx);


class Parser {

  public:  
    Parser() {}

    Handle<Value> value;

    int parse(Handle<String> s) {
      SourceBuffer source;
      source.appendHandle(s);
      State state(source, &valueStart);

      int err = source.next();
      if (err) {
        return err;
      }
      Local<Array> v = NanNew<Array>();
      int idx = 0;
      TargetBuffer iTarget;
      while (true) {
        iTarget.clear();
        // std::cout << "nextIdx=" << source.nextIdx << " nextType=" << source.nextType << std::endl;
        if (source.nextType == SourceBuffer::TEXT) {
          err = source.pullUnescaped(iTarget);
          if (err) {
            return err;
          }
          v->Set(idx++, iTarget.getHandle());
        } else {
          // v->Set(idx++, NanNew<Number>(source.nextType));
          if (source.nextType == SourceBuffer::END) {
            break;
          }
          err = source.next();
          if (err) {
            return err;
          }
        }
      }
      value = v;
      return 0;
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
  Parser parser;
  int err = parser.parse(s);
  if (err) {
    return NanThrowError("Syntax Error");
  }
  NanReturnValue(parser.value);
}

void InitParser() {
  // std::cout << "DEFAULT=" << DEFAULT << std::endl;
  Parser::Init();
}


