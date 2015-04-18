#include "serializer.h"

using v8::Handle;
using v8::Object;
using v8::FunctionTemplate;

void Init(Handle<Object> exports) {
  InitSerializer();
  exports->Set(NanNew("escape"), NanNew<FunctionTemplate>(Escape)->GetFunction());
  exports->Set(NanNew("serialize"), NanNew<FunctionTemplate>(Serialize)->GetFunction());
}

NODE_MODULE(native_tson, Init)


