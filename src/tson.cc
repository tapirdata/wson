#include "transcribe.h"
#include "stringifier.h"
#include "parser.h"

using v8::Handle;
using v8::Object;
using v8::FunctionTemplate;

NAN_METHOD(CreateStringifier) {
  NanScope();
  NanReturnValue(Stringifier::NewInstance(args[0]));
}

NAN_METHOD(CreateParser) {
  NanScope();
  NanReturnValue(Parser::NewInstance(args[0]));
}

void Init(Handle<Object> exports) {
  Stringifier::Init();
  Parser::Init();
  exports->Set(NanNew("escape"), NanNew<FunctionTemplate>(Escape)->GetFunction());
  exports->Set(NanNew("unescape"), NanNew<FunctionTemplate>(Unescape)->GetFunction());
  exports->Set(NanNew("createStringifier"), NanNew<FunctionTemplate>(CreateStringifier)->GetFunction());
  exports->Set(NanNew("createParser"), NanNew<FunctionTemplate>(CreateParser)->GetFunction());
}

NODE_MODULE(native_tson, Init)


