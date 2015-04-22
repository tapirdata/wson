#include "base_buffer.h"
#include "target_buffer.h"

class SourceBuffer: public BaseBuffer {

  public:

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
      err(0),
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

    inline void pullUnescaped(TargetBuffer& target) {
      while (true) {
        target.push(nextChar);
        next();
        if (err || nextType != TEXT) {
          break;
        }
      }
    }

    inline void pullUnescaped(std::string& target) {
      while (true) {
        target.push_back(nextChar);
        next();
        if (err || nextType != TEXT) {
          break;
        }
      }
    }

    inline void pullUnescapedBuffer() {
      nextBuffer.clear();
      pullUnescaped(nextBuffer);
    }

    inline void pullUnescapedString() {
      nextString.clear();
      pullUnescaped(nextString);
    }

    void makeError(TargetBuffer& msg) {
      size_t errIdx = nextIdx;
      uint16_t errChar = nextChar;
      if (nextType == END) {
        errChar = 0;
      } else {
        --errIdx;
      }
      msg.append(std::string("Unexpected '"));
      if (errChar) {
        msg.push(nextChar);
      }
      msg.append(std::string("' at '"));
      msg.append(getBuffer(), 0, errIdx);
      msg.push('^');
      msg.append(getBuffer(), errIdx);
      msg.append(std::string("'"));
    }

    int err;
    size_t nextIdx;
    uint16_t nextChar;
    Ctype nextType;
    TargetBuffer nextBuffer;
    std::string nextString;
};


