
#include "parser.h"
#include "target_buffer.h"
#include "source_buffer.h"

using v8::Handle;
using v8::Local;
using v8::Value;
using v8::String;

class Parser {

  public:  
    Parser(Handle<String> s) {
      source.appendHandle(s);
    }

    SourceBuffer source;
    Handle<Value> value;

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
  if (err < 0) {
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
  NanReturnValue(parser.source.getHandle());
}

void InitParser() {
  Parser::Init();
}


