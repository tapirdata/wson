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
        case '[':
          return OBJECT;
        case ']':
          return ENDOBJECT;
        case '{':
          return ARRAY;
        case '}':
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
          // std::cout << "next: nextIdx=" << nextIdx << " c=" << (char)c << " nextChar=" << nextChar << std::endl;
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
    /*
        uint16_t c = buffer_[idx++];
        if (nextType == TEXT) {
          textBeginIdx = idx - 1;
          while (idx < len) {
            c = buffer_[idx++];
            // std::cout << "next: idx:" << idx << " c=" << (char)c << " " << SourceBuffer::getCtype(c) << std::endl;
            if (SourceBuffer::getCtype(c) != TEXT) {
              --idx;
              break;
            }
          }
          textEndIdx = idx;
        } 
    */    

    size_t nextIdx;
    uint16_t nextChar;
    Ctype nextType;

};


