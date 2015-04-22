
#include "parser.h"
#include "target_buffer.h"
#include "source_buffer.h"
#include <cstdlib>

using v8::Local;
using v8::Persistent;
using v8::Value;
using v8::String;
using v8::Object;
using v8::Function;
using v8::FunctionTemplate;


class ParserSource {
  public:
    SourceBuffer source;
    v8::Local<v8::Value> getLiteral();
    v8::Local<v8::Array> getArray();
    v8::Local<v8::Object> getObject();
    v8::Local<v8::Value> getValue();
};

v8::Local<v8::Value> ParserSource::getLiteral() {
  NanEscapableScope();
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
  return NanEscapeScope(value);
}  

v8::Local<v8::Array> ParserSource::getArray() {
  NanEscapableScope();
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
  return NanEscapeScope(value);
}  

v8::Local<v8::Object> ParserSource::getObject() {
  NanEscapableScope();
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
  return NanEscapeScope(value);
}  

v8::Local<v8::Value> ParserSource::getValue() {
  NanEscapableScope();
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
  return NanEscapeScope(value);
}
 



Parser::Parser() {};
Parser::~Parser() {};

Persistent<Function> Parser::constructor;
Persistent<Function> Parser::parse;

NAN_METHOD(Parser::New) {
  NanScope();

  Parser* obj = new Parser();
  obj->val_ = args[0]->IsUndefined() ? 0 : args[0]->NumberValue();
  obj->Wrap(args.This());

  NanReturnValue(args.This());
}

NAN_METHOD(Parser::Parse) {
  NanScope();
  if (args.Length() < 1 || !(args[0]->IsString())) {
    return NanThrowTypeError("First argument should be a string");
  }
  Local<String> s = args[0].As<String>();
  ParserSource ps;
  ps.source.appendHandle(s);
  ps.source.next();
  Local<Value> result = ps.getValue();
  if (ps.source.err) {
    TargetBuffer errorMsg;
    ps.source.makeError(errorMsg);
    return NanThrowError(errorMsg.getHandle());
  }
  NanReturnValue(result);

}

Local<Object> Parser::NewInstance(Local<Value> arg) {
  NanEscapableScope();

  const unsigned argc = 1;
  Local<Value> argv[argc] = { arg };
  Local<Function> cons = NanNew<Function>(constructor);
  Local<Object> instance = cons->NewInstance(argc, argv);
  // instance->Set(NanNew("ppp"), NanNew("qqq"));

  return NanEscapeScope(instance);
}

void Parser::Init() {
  NanScope();

  Local<FunctionTemplate> newTpl = NanNew<FunctionTemplate>(New);
  newTpl->SetClassName(NanNew("Parser"));
  newTpl->InstanceTemplate()->SetInternalFieldCount(1);

  Local<FunctionTemplate> parseTpl = NanNew<FunctionTemplate>(Parse);
  NanAssignPersistent(parse, parseTpl->GetFunction());

  newTpl->PrototypeTemplate()->Set(NanNew("parse"), parseTpl->GetFunction());

  NanAssignPersistent(constructor, newTpl->GetFunction());
}





