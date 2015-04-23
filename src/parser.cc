
#include "parser.h"

using v8::Local;
using v8::Persistent;
using v8::Value;
using v8::String;
using v8::Object;
using v8::Function;
using v8::FunctionTemplate;


Parser::Parser() {};
Parser::~Parser() {};

Persistent<Function> Parser::constructor;

NAN_METHOD(Parser::New) {
  NanScope();
  if (args.IsConstructCall()) {
    Parser* obj = new Parser();
    obj->Wrap(args.This());
    NanReturnValue(args.This());
  } else {
    const int argc = 0;
    Local<Value> argv[argc] = {};
    Local<Function> cons = NanNew<Function>(constructor);
    NanReturnValue(cons->NewInstance(argc, argv));
  }  
}

NAN_METHOD(Parser::Parse) {
  NanScope();
  Parser* self = node::ObjectWrap::Unwrap<Parser>(args.This());
  ParserSource &ps = self->ps_;
  if (args.Length() < 1 || !(args[0]->IsString())) {
    return NanThrowTypeError("First argument should be a string");
  }
  Local<String> s = args[0].As<String>();
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

void Parser::Init(v8::Handle<v8::Object> exports) {
  NanScope();

  Local<FunctionTemplate> newTpl = NanNew<FunctionTemplate>(New);
  newTpl->SetClassName(NanNew("Parser"));
  newTpl->InstanceTemplate()->SetInternalFieldCount(1);

  NODE_SET_PROTOTYPE_METHOD(newTpl, "parse", Parse);

  NanAssignPersistent(constructor, newTpl->GetFunction());
  exports->Set(NanNew("Parser"), newTpl->GetFunction());
}





