#include "parser_source.h"

v8::Local<v8::Value> ParserSource::getLiteral() {
  v8::Local<v8::Value> value;
  if (source.nextType == TEXT) {
    switch (source.nextChar) {
      case 'u':
        source.next();
        value = NanUndefined();
        break;
      case 'n':
        source.next();
        value = NanNull();
        break;
      case 'f':
        source.next();
        value = NanFalse();
        break;
      case 't':
        source.next();
        value = NanTrue();
        break;
      default: {
        source.pullUnescapedString();
        if (source.err)
          break;
        const char* begin = source.nextString.data();
        char* end;
        int x = strtol(begin, &end, 10);
        if (end == begin + source.nextString.size()) {
          value = NanNew<v8::Number>(x);
          break;
        } else {
          double x = strtod(begin, &end);
          if (end == begin + source.nextString.size()) {
            value = NanNew<v8::Number>(x);
            break;
          }
        }
        source.err = SYNTAX_ERROR;
      }
    }
  } else {
    value = NanNew<v8::String>();
  }
  return value;
}

v8::Local<v8::Array> ParserSource::getArray() {
  v8::Local<v8::Array> value = NanNew<v8::Array>();
  switch (source.nextType) {
    case ENDARRAY:
      source.next();
      break;
    default:
      goto stageNext;
  }
  goto end;

stageNext:
  switch (source.nextType) {
    case TEXT:
      source.pullUnescapedBuffer();
      if (source.err)
        break;
      value->Set(value->Length(), source.nextBuffer.getHandle());
      goto stageHave;
    case LITERAL:
      source.next();
      value->Set(value->Length(), getLiteral());
      if (source.err) goto end;
      goto stageHave;
    case ARRAY:
      source.next();
      value->Set(value->Length(), getArray());
      if (source.err) goto end;
      goto stageHave;
    case OBJECT:
      source.next();
      value->Set(value->Length(), getObject());
      if (source.err) goto end;
      goto stageHave;
    default:
      source.err = SYNTAX_ERROR;
  }
  goto end;

stageHave:
  switch (source.nextType) {
    case ENDARRAY:
      source.next();
      break;
    case PIPE:
      source.next();
      goto stageNext;
    default:
      source.err = SYNTAX_ERROR;
  }
  goto end;

end:
  return value;
}

v8::Local<v8::Object> ParserSource::getObject() {
  v8::Local<v8::Object> value = NanNew<v8::Object>();
  v8::Local<v8::String> key;

  switch (source.nextType) {
    case ENDOBJECT:
      source.next();
      break;
    default:
      goto stageNext;
  }
  goto end;

stageNext:
  switch (source.nextType) {
    case TEXT:
      source.pullUnescapedBuffer();
      if (source.err)
        break;
      key = source.nextBuffer.getHandle();
      goto stageHaveKey;
    case LITERAL:
      source.next();
      key = NanNew<v8::String>();
      goto stageHaveKey;
    default:
      source.err = SYNTAX_ERROR;
  }
  goto end;

stageHaveKey:
  switch (source.nextType) {
    case ENDOBJECT:
      source.next();
      value->Set(key, NanTrue());
      break;
    case PIPE:
      source.next();
      value->Set(key, NanTrue());
      goto stageNext;
    case IS:
      source.next();
      goto stageHaveColon;
    default:
      source.err = SYNTAX_ERROR;
  }
  goto end;

stageHaveColon:
  switch (source.nextType) {
    case TEXT:
      source.pullUnescapedBuffer();
      if (source.err)
        break;
      value->Set(key, source.nextBuffer.getHandle());
      goto stageHaveValue;
    case LITERAL:
      source.next();
      value->Set(key, getLiteral());
      if (source.err) goto end;
      goto stageHaveValue;
    case ARRAY:
      source.next();
      value->Set(key, getArray());
      if (source.err) goto end;
      goto stageHaveValue;
    case OBJECT:
      source.next();
      value->Set(key, getObject());
      if (source.err) goto end;
      goto stageHaveValue;
    default:
      source.err = SYNTAX_ERROR;
  }
  goto end;

stageHaveValue:
  switch (source.nextType) {
    case ENDOBJECT:
      source.next();
      break;
    case PIPE:
      source.next();
      goto stageNext;
    default:
      source.err = SYNTAX_ERROR;
  }
  goto end;

end:
  return value;
}

v8::Local<v8::Value> ParserSource::getValue() {
  v8::Local<v8::Value> value;
  switch (source.nextType) {
    case TEXT:
      source.pullUnescapedBuffer();
      if (source.err)
        break;
      value = source.nextBuffer.getHandle();
      break;
    case LITERAL:
      source.next();
      value = getLiteral();
      break;
    case ARRAY:
      source.next();
      value = getArray();
      break;
    case OBJECT:
      source.next();
      value = getObject();
      break;
    default:
      source.err = SYNTAX_ERROR;
  }
  if (source.nextType != END) {
    source.err = SYNTAX_ERROR;
  }
  return value;
}

