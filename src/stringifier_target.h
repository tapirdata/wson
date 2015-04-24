#ifndef TSON_STINGIFIER_TARGET_H_
#define TSON_STINGIFIER_TARGET_H_

#include "target_buffer.h"
#include <algorithm>

class StringifierTarget;

class ObjectAdaptor {
  public:
    inline void putObject(v8::Local<v8::Object> obj);
    inline void sort();
    inline void emit(StringifierTarget&);
  private:
    struct Entry {
      size_t keyBeginIdx;
      size_t keyLength;
      v8::Handle<v8::Value> value;
    };
    TargetBuffer keyBunch;
    std::vector<Entry> entries;
    std::vector<size_t> entryIdxs;
    friend struct OaLess;
}; 

class StringifierTarget {
  public:
    StringifierTarget(): oaIdx_(0) {}
    inline void putText(v8::Local<v8::String>);
    inline void putText(const usc2vector& buffer, size_t start, size_t length);
    inline void putValue(v8::Local<v8::Value>);
    inline void clear() {
      target.clear();
      oaIdx_ = 0;
    };

    static void Init();
    // static inline void Sort(v8::Local<v8::Array>);

    TargetBuffer target;

  private:
    enum {
      STATIC_OA_NUM = 8
    };
    ObjectAdaptor oas_[STATIC_OA_NUM];
    size_t oaIdx_;

    ObjectAdaptor* getOa() {
      if (oaIdx_ < STATIC_OA_NUM) {
        return &oas_[oaIdx_++];
      } else {
        oaIdx_++;
        return new ObjectAdaptor();
      }  
    } 

    void releaseOa(ObjectAdaptor* oa) {
      if (oaIdx_ > STATIC_OA_NUM) {
        delete oa;
      }  
      --oaIdx_;
    } 
};

void StringifierTarget::putText(v8::Local<v8::String> s) {
  if (s->Length() == 0) {
    target.push('#');
  } else {
    target.appendHandleEscaped(s);
  }
}
void StringifierTarget::putText(const usc2vector& buffer, size_t start, size_t length) {
  if (length == 0) {
    target.push('#');
  } else {
    target.appendEscaped(buffer, start, length);
  }
}

void StringifierTarget::putValue(v8::Local<v8::Value> x) {
  if (x->IsString()) {
    putText(x.As<v8::String>());
  } else if (x->IsNumber()) {
    target.push('#');
    target.appendHandle(x->ToString());
  } else if (x->IsUndefined()) {
    target.push('#');
    target.push('u');
  } else if (x->IsNull()) {
    target.push('#');
    target.push('n');
  } else if (x->IsBoolean()) {
    target.push('#');
    if (x->BooleanValue()) {
      target.push('t');
    } else {
      target.push('f');
    }
  } else if (x->IsArray()) {
    v8::Local<v8::Array> array = x.As<v8::Array>();
    uint32_t len = array->Length();
    target.push('[');
    for (uint32_t i=0; i<len; ++i) {
      putValue(array->Get(i));
      if (i + 1 != len) {
        target.push('|');
      }
    }
    target.push(']');
  } else if (x->IsObject()) {
    ObjectAdaptor *oa = getOa();
    oa->putObject(x.As<v8::Object>());
    oa->sort();
    oa->emit(*this);
    releaseOa(oa);
  }
}

void ObjectAdaptor::putObject(v8::Local<v8::Object> obj) {
  v8::Local<v8::Array> keys = obj->GetOwnPropertyNames();
  uint32_t len = keys->Length();
  entries.resize(len);
  entryIdxs.resize(len);
  keyBunch.clear();
  for (uint32_t i=0; i<len; ++i) {
    entryIdxs[i] = i;
    Entry& entry = entries[i];
    v8::Local<v8::String> key = keys->Get(i).As<v8::String>();
    entry.keyBeginIdx = keyBunch.size();
    entry.keyLength = key->Length();
    entry.value = obj->Get(key);
    keyBunch.appendHandle(key);
  }  
} 
struct OaLess {
  OaLess(const ObjectAdaptor& oa): oa_(oa) {}
  const ObjectAdaptor& oa_;
  bool operator()(size_t idxA, size_t idxB) {
    const uint16_t* keyData = oa_.keyBunch.getBuffer().data();
    const ObjectAdaptor::Entry& entryA = oa_.entries[idxA];
    const ObjectAdaptor::Entry& entryB = oa_.entries[idxB];
    const uint16_t* itA = keyData + entryA.keyBeginIdx;
    const uint16_t* itB = keyData + entryB.keyBeginIdx;
    const uint16_t* endA = itA + entryA.keyLength;
    const uint16_t* endB = itB + entryB.keyLength;
    while (itA != endA) {
      if (itB == endB) {  // B ends -> extra A-tail
        return false;
      }
      uint16_t cA = *itA++;
      uint16_t cB = *itB++;
      if (cA < cB) {
        return true;
      } else if (cA > cB) {
        return false;
      }
    }
    // A ends;
    if (itB == endB) {
      // equal
      return false;
    } else {
      // extra B-tail
      return true;
    }
  }
};


void ObjectAdaptor::sort() {
  if (entryIdxs.size() > 1) {
    OaLess oaLess(*this);
    std::sort(entryIdxs.begin(), entryIdxs.end(), oaLess);
    // std::swap(entryIdxs[0], entryIdxs[1]);
  }
}  

void ObjectAdaptor::emit(StringifierTarget& st) {
  // const uint16_t* keyData = keyBunch.getBuffer().data();
  const usc2vector& keyBuffer = keyBunch.getBuffer();
  st.target.push('{');
  uint32_t len = entries.size();
  for (uint32_t i=0; i<len; ++i) {
    size_t entryIdx = entryIdxs[i];
    Entry& entry = entries[entryIdx];
    st.putText(keyBuffer, entry.keyBeginIdx, entry.keyLength);
    if (!entry.value->IsBoolean() || !entry.value->BooleanValue()) {
      st.target.push(':');
      st.putValue(entry.value);
    }
    if (i + 1 != len) {
      st.target.push('|');
    }
  }  
  st.target.push('}');
}


#endif // TSON_STINGIFIER_TARGET_H_

