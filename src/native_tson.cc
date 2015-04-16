#include <iostream>
#include <string>
#include <vector>
#include <nan.h>

// using namespace v8;
using v8::Handle;
using v8::Local;
using v8::Object;
using v8::Array;
using v8::String;
using v8::Value;
using v8::FunctionTemplate;

int square (int x) {
  return x * x;
}

typedef std::vector<uint16_t> ucs2;

void appendUcs2(ucs2& target, Handle<String> source, int start=0, int length=-1) {
  size_t oldSize = target.size();
  // std::cout << "target.size=" << target.size() << " capacity=" << target.capacity() << std::endl;
  target.resize(oldSize + (length >= 0 ? length : source->Length() - start), 'X');
  // std::cout << ".target.size=" << target.size() << " capacity=" << target.capacity() << std::endl;
  source->Write(target.data() + oldSize, start, length, String::NO_NULL_TERMINATION);
}

void appendUcs2(ucs2& target, ucs2& source, int start=0, int length=-1) {
  ucs2::iterator sourceBegin = source.begin() + start;
  ucs2::iterator sourceEnd = length < 0 ? source.end() : sourceBegin + length;
  target.insert(target.end(), sourceBegin, sourceEnd);
}

NAN_METHOD(Foo) {
  std::string monty("montü");
  std::cout << "Foo" << std::endl;
  NanScope();
  Local<Object> obj = NanNew<Object>();
  Local<Object> a = NanNew<Array>(10);
  a->Set(2, NanNew("a0"));
  a->Set(5, NanNew(monty));
  obj->Set(NanNew("planet"), NanNew("world"));
  obj->Set(NanNew("a"), a);
  if (args.Length() > 0) {
    obj->Set(NanNew("len"), NanNew(args.Length()));
    // Local<String> arg0 = Local<String>::Cast(args[0]);
    v8::String::Utf8Value s0(args[0]->ToString()); 
    std::string s(*s0);
    std::cout << "args[0]: " << s << std::endl;
  }
  if (args.Length() > 1) {
    int x = args[1]->NumberValue();
    a->Set(0, NanNew(square(x)));
  }
  NanReturnValue(obj);
}

NAN_METHOD(Escape) {
  ucs2 result;

  ucs2 zz;
  zz.push_back('x');
  zz.push_back('y');
  zz.push_back('z');

  std::string name("otto");

  result.push_back('a');
  result.push_back('b');
  result.push_back(8364);

  appendUcs2(result, zz);
  result.insert(result.end(), name.begin(), name.end());
  
  if (args.Length() > 0) {
    if (args[0]->IsString()) {
      Local<String> arg0 = Local<String>::Cast(args[0]);
      appendUcs2(result, arg0);
    }
  }
  Local<String> tt = NanNew<String>(result.data(), result.size());
  // Local<String> tt = NanNew<String>("mumu");
  NanReturnValue(tt);
}

void Init(Handle<Object> exports) {
  exports->Set(NanNew("foo"), NanNew<FunctionTemplate>(Foo)->GetFunction());
  exports->Set(NanNew("escape"), NanNew<FunctionTemplate>(Escape)->GetFunction());
}

NODE_MODULE(native_tson, Init)


