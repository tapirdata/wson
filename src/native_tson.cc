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

typedef std::vector<uint16_t> usc2vector;

inline uint16_t getEscapeChar(uint16_t c) {
  switch (c) {
    case '{':
      return 'b';
    case '}':
      return 'c';
    case '[':
      return 'a';
    case ']':
      return 'e';
    case ':':
      return 'i';
    case '#':
      return 'n';
    case '|':
      return 'p';
    case '`':
      return 'q';
  }  
  return 0;
}

class TargetBuffer {
  private:
    usc2vector buffer_;

  public:

    TargetBuffer() {}

    inline void push(uint16_t c) {
      buffer_.push_back(c);
    }

    template<typename S>
    void append(const S& source, int start=0, int length=-1) {
      if (length < 0) {
        length = source.size() - start;
      }
      typename S::const_iterator sourceBegin = source.begin() + start;
      typename S::const_iterator sourceEnd = sourceBegin + length;
      buffer_.reserve(buffer_.size() + length);
      buffer_.insert(buffer_.end(), sourceBegin, sourceEnd);
    }

    inline void appendHandle(Handle<String> source, int start=0, int length=-1) {
      size_t oldSize = buffer_.size();
      if (length < 0) {
        length = source->Length() - start;
      }
      buffer_.resize(oldSize + length);
      source->Write(buffer_.data() + oldSize, start, length, String::NO_NULL_TERMINATION);
    }

    template<typename S>
    void appendEscaped(const S& source, int start=0, int length=-1) {
      if (length < 0) {
        length = source.size() - start;
      }
      typename S::const_iterator sourceBegin = source.begin() + start;
      typename S::const_iterator sourceEnd = sourceBegin + length;
      typename S::const_iterator sourcePick = sourceBegin;
      buffer_.reserve(buffer_.size() + length  + 10);
      while (sourcePick != sourceEnd) {
        uint16_t c = *sourcePick++;
        uint16_t xc = getEscapeChar(c);
        if (xc) {
          push('`');
          push(xc);
        } else {
          push (c);
        }  
      }  
    }

    void appendHandleEscaped(Handle<String> source, int start=0, int length=-1) {
      TargetBuffer source1;
      source1.appendHandle(source, start, length);
      appendEscaped(source1.buffer_);
    }

    Local<String> getHandle() {
      return NanNew<String>(buffer_.data(), buffer_.size());
    }
};

class Serializer {
  public:
    TargetBuffer target;

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
        target.appendHandleEscaped(Handle<String>::Cast(x));
      } else if (x->IsNumber()) {
        target.push('#');
        Local<String> s = x->ToString();
        target.appendHandleEscaped(s);
      } else if (x->IsArray()) {
        Handle<Array> y = Handle<Array>::Cast(x);
        int len = y->Length();
        target.push('[');
        for (int i=0; i<len; ++i) {
          putValue(y->Get(i));
          if (i + 1 != len) {
            target.push('|');
          }  
        }
        target.push(']');
      }
    }  
};  


NAN_METHOD(Escape) {
  TargetBuffer target;
  if (args.Length() > 0) {
    Handle<Value> x = args[0];
    if (x->IsString()) {
      target.appendHandleEscaped(Local<String>::Cast(args[0]));
    }
  }
  NanReturnValue(target.getHandle());
}

NAN_METHOD(Serialize) {
  Serializer serializer;
  if (args.Length() > 0) {
    serializer.putValue(args[0]);
  }
  NanReturnValue(serializer.target.getHandle());
}



int square (int x) {
  return x * x;
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


void Init(Handle<Object> exports) {
  exports->Set(NanNew("foo"), NanNew<FunctionTemplate>(Foo)->GetFunction());
  exports->Set(NanNew("escape"), NanNew<FunctionTemplate>(Escape)->GetFunction());
  exports->Set(NanNew("serialize"), NanNew<FunctionTemplate>(Serialize)->GetFunction());
}

NODE_MODULE(native_tson, Init)


