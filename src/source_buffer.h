#include "base_buffer.h"
#include "target_buffer.h"

class SourceBuffer: public BaseBuffer {

  public:

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

    static inline Ctype getCtype(uint16_t c) {
      switch (c) {
        case '{':
          return OBJECT;
        case '}':
          return ENDOBJECT;
        case '[':
          return ARRAY;
        case ']':
          return ENDARRAY;
        case ':':
          return IS;
        case '#':
          return LITERAL;
        case '|':
          return PIPE;
        case '`':
          return QUOTE;
      }  
      return TEXT;
    }

    SourceBuffer():
      nextIdx(0)
    {}

    inline int next() {
      size_t len = buffer_.size();
      if (nextIdx >= len) {
        nextType = END;
      } else {
        nextChar = buffer_[nextIdx++];
        nextType = SourceBuffer::getCtype(nextChar);
        if (nextType == QUOTE) {
          if (nextIdx == len) {
            return SYNTAX_ERROR;
          }
          uint16_t c = buffer_[nextIdx++];
          nextChar = getUnescapeChar(c);
          if (!nextChar) {
            return SYNTAX_ERROR;
          }
          nextType = TEXT;
        }
      }
      return 0;
    }

    inline int pullUnescaped(TargetBuffer& target) {
      while (true) {
        target.push(nextChar);
        int err = next();
        if (err) {
          return err;
        }
        if (nextType != TEXT) {
          break;
        }
      }
      return 0;
    }

    inline int pullUnescaped(std::string& target) {
      while (true) {
        target.push_back(nextChar);
        int err = next();
        if (err) {
          return err;
        }
        if (nextType != TEXT) {
          break;
        }
      }
      return 0;
    }

    inline int pullUnescapedBuffer() {
      nextBuffer.clear();
      return pullUnescaped(nextBuffer);
    }  

    inline int pullUnescapedString() {
      nextString.clear();
      return pullUnescaped(nextString);
    }  


    size_t nextIdx;
    uint16_t nextChar;
    Ctype nextType;
    TargetBuffer nextBuffer;
    std::string nextString;
};


