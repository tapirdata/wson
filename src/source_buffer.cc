#include "source_buffer.h"
#include <cstdlib>

v8::Handle<v8::Value> SourceBuffer::getLiteral() {
  NanEscapableScope();
  v8::Local<v8::Value> value;
  if (nextType == TEXT) {
    switch (nextChar) {
      case 'u':
        next();
        value = NanUndefined();
        break;
      case 'n': 
        next();
        value = NanNull();
        break;
      case 'f': 
        next();
        value = NanFalse();
        break;
      case 't': 
        next();
        value = NanTrue();
        break;
      default: {
        pullUnescapedString();
        if (err)
          break;
        const char* begin = nextString.data();
        char* end;
        int x = strtol(begin, &end, 10);
        if (end == begin + nextString.size()) {
          value = NanNew<v8::Number>(x);
          break;
        } else {
          double x = strtod(begin, &end);
          if (end == begin + nextString.size()) {
            value = NanNew<v8::Number>(x);
            break;
          }  
        }
        err = SYNTAX_ERROR;
      }  
    }
  } else {
    value = NanNew<v8::String>();
  }
  return NanEscapeScope(value);
}  



v8::Handle<v8::Array> SourceBuffer::getArray() {
  NanEscapableScope();
  v8::Local<v8::Array> value = NanNew<v8::Array>();
  switch (nextType) {
    case ENDARRAY:
      next();
      break;
    default:
      goto stageNext;
  }      
  goto end;

stageNext:  
  switch (nextType) {
    case TEXT:
      pullUnescapedBuffer();
      if (err)
        break;
      value->Set(value->Length(), nextBuffer.getHandle());
      goto stageHave;
    case LITERAL:
      next();
      value->Set(value->Length(), getLiteral());
      if (err) goto end;
      goto stageHave;
    case ARRAY:
      next();
      value->Set(value->Length(), getArray());
      if (err) goto end;
      goto stageHave;
    case OBJECT:
      next();
      value->Set(value->Length(), getObject());
      if (err) goto end;
      goto stageHave;
    default:  
      err = SYNTAX_ERROR;
  }
  goto end;

stageHave:  
  switch (nextType) {
    case ENDARRAY:
      next();
      break;
    case PIPE:
      next();
      goto stageNext;
    default:
      err = SYNTAX_ERROR;
  }      
  goto end;

end:    
  return NanEscapeScope(value);
}  

v8::Handle<v8::Object> SourceBuffer::getObject() {
  NanEscapableScope();
  v8::Local<v8::Object> value = NanNew<v8::Object>();
  v8::Local<v8::String> key;

  switch (nextType) {
    case ENDOBJECT:
      next();
      break;
    default:
      goto stageNext;
  }      
  goto end;

stageNext:  
  switch (nextType) {
    case TEXT:
      pullUnescapedBuffer();
      if (err)
        break;
      key = nextBuffer.getHandle();
      goto stageHaveKey;
    case LITERAL:
      next();
      key = NanNew<v8::String>();
      goto stageHaveKey;
    default:  
      err = SYNTAX_ERROR;
  }
  goto end;

stageHaveKey:  
  switch (nextType) {
    case ENDOBJECT:
      next();
      value->Set(key, NanTrue());
      break;
    case PIPE:
      next();
      value->Set(key, NanTrue());
      goto stageNext;
    case IS:
      next();
      goto stageHaveColon;
    default:  
      err = SYNTAX_ERROR;
  }
  goto end;

stageHaveColon:  
  switch (nextType) {
    case TEXT: 
      pullUnescapedBuffer();
      if (err)
        break;
      value->Set(key, nextBuffer.getHandle());
      goto stageHaveValue;
    case LITERAL:
      next();
      value->Set(key, getLiteral());
      if (err) goto end;
      goto stageHaveValue;
    case ARRAY:
      next();
      value->Set(key, getArray());
      if (err) goto end;
      goto stageHaveValue;
    case OBJECT:
      next();
      value->Set(key, getObject());
      if (err) goto end;
      goto stageHaveValue;
    default:  
      err = SYNTAX_ERROR;
  }
  goto end;

stageHaveValue:  
  switch (nextType) {
    case ENDOBJECT:
      next();
      break;
    case PIPE:
      next();
      goto stageNext;
    default:  
      err = SYNTAX_ERROR;
  }
  goto end;

end:    
  return NanEscapeScope(value);
}  

v8::Handle<v8::Value> SourceBuffer::getValue() {
  NanEscapableScope();
  v8::Local<v8::Value> value;
  switch (nextType) {
    case TEXT:
      pullUnescapedBuffer();
      if (err)
        break;
      value = nextBuffer.getHandle();
      break;
    case LITERAL:
      next();
      value = getLiteral();
      break;
    case ARRAY:
      next();
      value = getArray();
      break;
    case OBJECT:
      next();
      value = getObject();
      break;
    default:  
      err = SYNTAX_ERROR;
  }
  if (nextType != END) {
    err = SYNTAX_ERROR;
  }
  return NanEscapeScope(value);
}
 
