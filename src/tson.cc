#include "transcribe.h"
#include "stringifier.h"
#include "parser.h"

using v8::Handle;
using v8::Object;
using v8::FunctionTemplate;

void Init(Handle<Object> exports) {
  Stringifier::Init(exports);
  Parser::Init(exports);
  exports->Set(NanNew("escape"), NanNew<FunctionTemplate>(Escape)->GetFunction());
  exports->Set(NanNew("unescape"), NanNew<FunctionTemplate>(Unescape)->GetFunction());
}

NODE_MODULE(native_tson, Init)


