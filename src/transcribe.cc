
#include "transcribe.h"
#include "target_buffer.h"

NAN_METHOD(Unescape) {
  TargetBuffer target;
  if (args.Length() < 1 || !(args[0]->IsString())) {
    return NanThrowTypeError("First argument should be a string");
  }
  v8::Local<v8::String> s = args[0].As<v8::String>();
  int err = target.appendHandleUnescaped(s);
  if (err) {
    return NanThrowError("Unexpected escape sequence");
  }
  NanReturnValue(target.getHandle());
}

NAN_METHOD(Escape) {
  TargetBuffer target;
  if (args.Length() < 1 || !(args[0]->IsString())) {
    return NanThrowTypeError("First argument should be a string");
  }
  v8::Local<v8::String> s = args[0].As<v8::String>();
  target.appendHandleEscaped(s);
  NanReturnValue(target.getHandle());
}

