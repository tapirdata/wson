
#include "stringifier.h"
#include "target_buffer.h"

using v8::Local;
using v8::Value;
using v8::String;
using v8::Array;
using v8::Object;
using v8::Function;
using v8::FunctionTemplate;

class StringifierTarget {
  public:
    inline void putText(Local<String>);
    inline void putValue(Local<Value>);

    static void Init();
    static inline void Sort(Local<Array>);

    TargetBuffer target;

  private:
    static v8::Persistent<Function> sort;
};

void StringifierTarget::Sort(Local<Array> array) {
  NanScope();
  if (array->Length() < 2) {
    return;
  }
  Local<Value> args[] = { array };
  NanNew(sort)->Call(NanGetCurrentContext()->Global(), 1, args);
}

void StringifierTarget::putText(Local<String> s) {
  if (s->Length() == 0) {
    target.push('#');
  } else {
    target.appendHandleEscaped(s);
  }
}

void StringifierTarget::putValue(Local<Value> x) {
  NanScope();
  if (x->IsString()) {
    putText(x.As<String>());
  } else if (x->IsNumber()) {
    target.push('#');
    target.appendHandle(x->ToString());
  } else if (x->IsUndefined()) {
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
  } else if (x->IsArray()) {
    Local<Array> array = x.As<Array>();
    uint32_t len = array->Length();
    target.push('[');
    for (uint32_t i=0; i<len; ++i) {
      putValue(array->Get(i));
      if (i + 1 != len) {
        target.push('|');
      }
    }
    target.push(']');
  } else if (x->IsObject()) {
    Local<Object> obj = x.As<Object>();
    Local<Array> keys = obj->GetOwnPropertyNames();
    Sort(keys);
    target.push('{');
    uint32_t len = keys->Length();
    for (uint32_t i=0; i<len; ++i) {
      Local<String> key = keys->Get(i).As<String>();
      putText(key);
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

void StringifierTarget::Init() {
  NanScope();
  Local<String> sortCode = NanNew("(function(array) {array.sort(); })");
  Local<Value> sortScript = NanCompileScript(sortCode)->Run();
  Local<Function> sortFn = Local<Function>::Cast(sortScript);
  NanAssignPersistent(StringifierTarget::sort, sortFn);
}


Stringifier::Stringifier() {};
Stringifier::~Stringifier() {};

v8::Persistent<v8::Function> Stringifier::constructor;
v8::Persistent<v8::Function> Stringifier::stringify;
v8::Persistent<v8::Function> StringifierTarget::sort;

NAN_METHOD(Stringifier::New) {
  NanScope();

  Stringifier* obj = new Stringifier();
  obj->val_ = args[0]->IsUndefined() ? 0 : args[0]->NumberValue();
  obj->Wrap(args.This());

  NanReturnValue(args.This());
}

NAN_METHOD(Stringifier::Stringify) {
  NanScope();
  StringifierTarget st;
  st.target.reserve(128);
  st.putValue(args[0]);
  NanReturnValue(st.target.getHandle());
}

Local<Object> Stringifier::NewInstance(Local<Value> arg) {
  NanEscapableScope();

  const unsigned argc = 1;
  Local<Value> argv[argc] = { arg };
  Local<Function> cons = NanNew<Function>(constructor);
  Local<Object> instance = cons->NewInstance(argc, argv);

  return NanEscapeScope(instance);
}

void Stringifier::Init() {
  NanScope();

  Local<FunctionTemplate> newTpl = NanNew<FunctionTemplate>(New);
  newTpl->SetClassName(NanNew("Stringifier"));
  newTpl->InstanceTemplate()->SetInternalFieldCount(1);

  Local<FunctionTemplate> stringifyTpl = NanNew<FunctionTemplate>(Stringify);
  NanAssignPersistent(stringify, stringifyTpl->GetFunction());

  newTpl->PrototypeTemplate()->Set(NanNew("stringify"), stringifyTpl->GetFunction());

  NanAssignPersistent(constructor, newTpl->GetFunction());

  StringifierTarget::Init();
}


