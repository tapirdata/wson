#ifndef TSON_TARGET_BUFFER_H_
#define TSON_TARGET_BUFFER_H_

#include "base_buffer.h"
#include <iostream>

class TargetBuffer: public BaseBuffer {

  public:

    TargetBuffer() {}

    /*
    template<typename S>
    inline void appendEscaped(const S& source, int start=0, int length=-1) {
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
    */

    template<typename S>
    inline int appendUnescaped(const S& source, int start=0, int length=-1) {
      if (length < 0) {
        length = source.size() - start;
      }
      typename S::const_iterator sourceBegin = source.begin() + start;
      typename S::const_iterator sourceEnd = sourceBegin + length;
      typename S::const_iterator sourcePick = sourceBegin;
      buffer_.reserve(buffer_.size() + length);
      while (sourcePick != sourceEnd) {
        uint16_t xc = *sourcePick++;
        if (xc == '`') {
          if (sourcePick == sourceEnd) {
            return SYNTAX_ERROR;
          }
          xc = *sourcePick++;
          uint16_t c = getUnescapeChar(xc);
          if (!c) {
            return SYNTAX_ERROR;
          }
          push (c);
        } else {
          push (xc);
        }  
      }  
      return 0;
    }

    inline void appendHandleEscaped(v8::Handle<v8::String> source, int start=0, int length=-1) {
      size_t oldSize = buffer_.size();
      if (length < 0) {
        length = source->Length() - start;
      }
      buffer_.resize(oldSize + length);
      uint16_t* putBegin = buffer_.data() + oldSize;
      source->Write(putBegin, start, length, v8::String::NO_NULL_TERMINATION);

      uint16_t* checkIt = putBegin;
      int escCount = 0;

      while (checkIt != putBegin + length) {
        uint16_t c = *checkIt++;
        uint16_t xc = getEscapeChar(c);
        if (xc) {
          ++escCount;
        }
      }
      if (escCount) {
        buffer_.resize(buffer_.size() + escCount, 'X');
        uint16_t* replBegin = buffer_.data();
        uint16_t* replTo = replBegin + buffer_.size();
        uint16_t* replFrom = replTo - escCount;
        while (escCount > 0) {
          // std::cout << "repl " << replFrom - replBegin << "->" << replTo - replBegin << std::endl;
          uint16_t c = *--replFrom;
          uint16_t xc = getEscapeChar(c);
          // std::cout << "repl c=" << c << "->" << xc << std::endl;
          if (xc) {
            *--replTo = xc;
            *--replTo = '`';
            --escCount;  
          } else {
            *--replTo = c;
          }
        }
      }
    }  

    inline int appendHandleUnescaped(v8::Handle<v8::String> source, int start=0, int length=-1) {
      TargetBuffer source1;
      source1.appendHandle(source, start, length);
      return appendUnescaped(source1.buffer_);
    }

    inline void clear() {
      buffer_.resize(0);
    }


};

#endif // TSON_TARGET_BUFFER_H_


