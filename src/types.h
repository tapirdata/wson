#ifndef TSON_TYPES_H_
#define TSON_TYPES_H_

#include <nan.h>
#include <vector>

typedef std::vector<uint16_t> usc2vector;

enum Ctype {
  TEXT,
  OBJECT,
  ENDOBJECT,
  ARRAY,
  ENDARRAY,
  IS,
  LITERAL,
  PIPE,
  QUOTE,
  END,
};


#define SYNTAX_ERROR -1

#endif // TSON_TYPES_H_

