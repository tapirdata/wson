
#include "serializer.h"
#include "target_buffer.h"


// using namespace v8;
using v8::Handle;
using v8::Local;
using v8::Object;
using v8::Array;
using v8::String;
using v8::Value;


class Serializer {
  public:
    TargetBuffer target;

    void putEscaped(Handle<String> s) {
      if (s->Length() == 0) {
        target.push('#');
      } else {  
        target.appendHandleEscaped(s);
      }
    }

    void sort1(Handle<Array> array) {
      if (array->Length() < 2) {
        return;
      } 
      Local<Value> sortArgs[] = { array };
      NanNew(Serializer::sortArray)->Call(NanGetCurrentContext()->Global(), 1, sortArgs);
    }

    void putValue(Handle<Value> x) {
      if (x->IsUndefined()) {
        target.push('#');
        target.push('u');
      } else if (x->IsNull()) {
        target.push('#');
        target.push('n');
      } else if (x->IsBoolean()) {
        target.push('#');
        if (x->BooleanValue()) {
          target.push('t');
        } else {
          target.push('f');
        }
      } else if (x->IsString()) {
        putEscaped(Handle<String>::Cast(x));
      } else if (x->IsNumber()) {
        target.push('#');
        Local<String> s = x->ToString();
        target.appendHandle(s);
      } else if (x->IsArray()) {
        Handle<Array> array = Handle<Array>::Cast(x);
        int len = array->Length();
        target.push('[');
        for (int i=0; i<len; ++i) {
          putValue(array->Get(i));
          if (i + 1 != len) {
            target.push('|');
          }  
        }
        target.push(']');
      } else if (x->IsObject()) {
        Handle<Object> obj = Handle<Object>::Cast(x);
        Local<Array> keys = obj->GetOwnPropertyNames();
        sort1(keys);
        target.push('{');
        int len = keys->Length();
        for (int i=0; i<len; ++i) {
          Local<String> key = keys->Get(i).As<String>();
          putEscaped(key);
          Local<Value> value = obj->Get(key);
          if (!value->IsBoolean() || !value->BooleanValue()) {
            target.push(':');
            putValue(value);
          }
          if (i + 1 != len) {
            target.push('|');
          }  
        }
        target.push('}');
      }
    }  

    static v8::Persistent<v8::Function> sortArray;
    static void Init();
};  

v8::Persistent<v8::Function> Serializer::sortArray;

void Serializer::Init() {
  Local<String> sortArrayCode = NanNew("(function(array) {array.sort(); })");
  v8::Local<Value> sortArray = NanCompileScript(sortArrayCode)->Run();
  v8::Local<v8::Function> sortArrayFn = v8::Local<v8::Function>::Cast(sortArray);
  NanAssignPersistent(Serializer::sortArray, sortArrayFn);
}

NAN_METHOD(Escape) {
  TargetBuffer target;
  if (args.Length() < 1 || !(args[0]->IsString())) {
    return NanThrowTypeError("First argument should be a string");
  }    
  Local<String> s = args[0].As<String>();
  target.appendHandleEscaped(s);
  NanReturnValue(target.getHandle());
}

NAN_METHOD(Serialize) {
  Serializer serializer;
  if (args.Length() > 0) {
    serializer.putValue(args[0]);
  }
  NanReturnValue(serializer.target.getHandle());
}

void InitSerializer() {
  Serializer::Init();
}

