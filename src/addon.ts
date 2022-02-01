import {
  Connector,
  HaverefCb,
  BackrefCb,
  PartialCb,
  HowNext,
  Value,
  BaseStringifyErrorClass,
  BaseParseErrorClass,
  ConnectorBag,
} from './types';

export interface AddonCreateOptions {
  connectors?: ConnectorBag;
}

interface AddonStringifier {
  escape(s: string): string;
  stringify(x: Value, haverefCb?: HaverefCb | null): string;
  getTypeid(x: Value): number;
  connectorOfValue<V extends Value>(x: V): Connector<V> | null;
}

interface AddonParser {
  unescape(s: string): string;
  parse(s: string, backrefCb?: BackrefCb | null): Value;
  parsePartial(s: string, howNext: HowNext, cb: PartialCb, backrefCb?: BackrefCb | null): Value;
  connectorOfCname(cname: string): Connector<Value>;
}

export interface AddonFactory {
  Stringifier: new (err: BaseStringifyErrorClass, opt: AddonCreateOptions) => AddonStringifier;
  Parser: new (err: BaseParseErrorClass, opt: AddonCreateOptions) => AddonParser;
}
