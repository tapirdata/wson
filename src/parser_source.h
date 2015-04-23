#ifndef TSON_PARSER_SOURCE_H_
#define TSON_PARSER_SOURCE_H_

#include "source_buffer.h"

class ParserSource {
  public:
    SourceBuffer source;
    v8::Local<v8::Value> getLiteral();
    v8::Local<v8::Array> getArray();
    v8::Local<v8::Object> getObject();
    v8::Local<v8::Value> getValue();
};


#endif // TSON_PARSER_SOURCE_H_

