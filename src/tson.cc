#include "serializer.h"
#include "parser.h"

using v8::Handle;
using v8::Object;
using v8::FunctionTemplate;

void Init(Handle<Object> exports) {
  InitSerializer();
  InitParser();
  exports->Set(NanNew("escape"), NanNew<FunctionTemplate>(Escape)->GetFunction());
  exports->Set(NanNew("serialize"), NanNew<FunctionTemplate>(Serialize)->GetFunction());
  exports->Set(NanNew("unescape"), NanNew<FunctionTemplate>(Unescape)->GetFunction());
  exports->Set(NanNew("parse"), NanNew<FunctionTemplate>(Parse)->GetFunction());
}

NODE_MODULE(native_tson, Init)


