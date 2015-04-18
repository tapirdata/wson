#ifndef TSON_TARGET_BUFFER_H_
#define TSON_TARGET_BUFFER_H_

#include "base_buffer.h"
#include <iostream>

using v8::Handle;
using v8::Local;
using v8::String;

inline uint16_t getEscapeChar(uint16_t c) {
  switch (c) {
    case '{':
      return 'b';
    case '}':
      return 'c';
    case '[':
      return 'a';
    case ']':
      return 'e';
    case ':':
      return 'i';
    case '#':
      return 'n';
    case '|':
      return 'p';
    case '`':
      return 'q';
  }  
  return 0;
}

inline uint16_t getUnescapeChar(uint16_t c) {
  switch (c) {
    case 'b':
      return '{';
    case 'c':
      return '}';
    case 'a':
      return '[';
    case 'e':
      return ']';
    case 'i':
      return ':';
    case 'n':
      return '#';
    case 'p':
      return '|';
    case 'q':
      return '`';
  }  
  return 0;
}

class TargetBuffer: public BaseBuffer {

  public:

    TargetBuffer() {}

    template<typename S>
    void appendEscaped(const S& source, int start=0, int length=-1) {
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

    template<typename S>
    int appendUnescaped(const S& source, int start=0, int length=-1) {
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

    /* 
    void simpleAppendHandleEscaped(Handle<String> source, int start=0, int length=-1) {
      TargetBuffer source1;
      source1.appendHandle(source, start, length);
      appendEscaped(source1.buffer_);
    }
    */

    void appendHandleEscaped(Handle<String> source, int start=0, int length=-1) {
      size_t oldSize = buffer_.size();
      if (length < 0) {
        length = source->Length() - start;
      }
      buffer_.resize(oldSize + length);
      uint16_t* putBegin = buffer_.data() + oldSize;
      source->Write(putBegin, start, length, String::NO_NULL_TERMINATION);

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

    int appendHandleUnescaped(Handle<String> source, int start=0, int length=-1) {
      TargetBuffer source1;
      source1.appendHandle(source, start, length);
      return appendUnescaped(source1.buffer_);
    }

    /*
    static bool compare(const TargetBuffer& a, const TargetBuffer& b) {
      return compareUsc2vector(a.buffer_, b.buffer_);
    }
    */

};

#endif // TSON_TARGET_BUFFER_H_


