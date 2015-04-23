#ifndef TSON_PARSER_H_
#define TSON_PARSER_H_

#include "parser_source.h"

class Parser: public node::ObjectWrap {

  public:
    static void Init(v8::Handle<v8::Object>);

  private:
    Parser();
    ~Parser();

    static v8::Persistent<v8::Function> constructor;
    static NAN_METHOD(New);
    static NAN_METHOD(Parse);

    ParserSource ps_;
};

#endif // TSON_PARSER_H_


