#ifndef TSON_STINGIFIER_H_
#define TSON_STINGIFIER_H_

#include "stringifier_target.h"

class Stringifier: public node::ObjectWrap {
  public:
    static void Init(v8::Handle<v8::Object>);

  private:
    Stringifier();
    ~Stringifier();

    static v8::Persistent<v8::Function> constructor;
    static NAN_METHOD(New);
    static NAN_METHOD(Stringify);

    StringifierTarget st_;
};


#endif // TSON_STINGIFIER_H_

