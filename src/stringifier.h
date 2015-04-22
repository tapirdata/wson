#ifndef TSON_SERIALIZER_H_
#define TSON_SERIALIZER_H_

#include <nan.h>

class Stringifier : public node::ObjectWrap {
  public:
    static void Init();
    static v8::Local<v8::Object> NewInstance(v8::Local<v8::Value> arg);
    double Val() const { return val_; }

  private:
    Stringifier();
    ~Stringifier();

    static v8::Persistent<v8::Function> constructor;
    static v8::Persistent<v8::Function> stringify;
    static NAN_METHOD(New);
    static NAN_METHOD(Stringify);
    double val_;
};


#endif // TSON_SERIALIZER_H_

