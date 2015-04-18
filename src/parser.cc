
#include "parser.h"
#include "target_buffer.h"

using v8::Handle;
using v8::Local;
using v8::Value;
using v8::String;

class Parser {

  public:  
    static void Init();
};

void Parser::Init() {
}

NAN_METHOD(Unescape) {
  TargetBuffer target;
  if (args.Length() > 0) {
    Handle<Value> x = args[0];
    if (!x->IsString()) {
      return NanThrowTypeError("First argument should be a string");
    }
    int err = target.appendHandleUnescaped(Local<String>::Cast(args[0]));
    if (err < 0) {
      return NanThrowError("Unexpected escape sequence");
    }
  }
  NanReturnValue(target.getHandle());
}

NAN_METHOD(Parse) {
  NanReturnValue(NanNew("hoho"));
}

void InitParser() {
  Parser::Init();
}


