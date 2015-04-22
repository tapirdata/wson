
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

/*
void Parser::Init() {
}

*/

NAN_METHOD(Parse) {
  NanScope();
  if (args.Length() < 1 || !(args[0]->IsString())) {
    return NanThrowTypeError("First argument should be a string");
  }
  Local<String> s = args[0].As<String>();
  SourceBuffer source;
  source.appendHandle(s);
  source.next();
  Local<Value> result = source.getValue();
  if (source.err) {
    TargetBuffer errorMsg;
    source.makeError(errorMsg);
    return NanThrowError(errorMsg.getHandle());
  }
  NanReturnValue(result);

}

void InitParser() {
  // Parser::Init();
}

