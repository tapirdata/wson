
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

class Parser {

  public:  
    Parser(Handle<String> s) {
      source.appendHandle(s);
    }

    SourceBuffer source;
    Handle<Value> value;

    int parse() {
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
  Parser parser(s);
  int err = parser.parse();
  if (err) {
    return NanThrowError("Syntax Error");
  }
  NanReturnValue(parser.value);
}

void InitParser() {
  Parser::Init();
}


