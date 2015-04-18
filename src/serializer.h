#ifndef TSON_SERIALIZER_H_
#define TSON_SERIALIZER_H_

#include <nan.h>

NAN_METHOD(Escape);
NAN_METHOD(Serialize);
void InitSerializer();

#endif // TSON_SERIALIZER_H_

