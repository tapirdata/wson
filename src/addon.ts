import { Connector, HaverefCb, BackrefCb, PartialCb, HowNext } from "./types"

type AddonErrorClass = any

export interface AddonCreateOptions {
  connectors?: Record<string, Connector<any>>
}

interface AddonStringifier {
  escape(s: string): string
  stringify(x: any, haverefCb?: HaverefCb | null): string
  getTypeid(x: any): number
  connectorOfValue(value: any): Connector<any>
}

interface AddonParser {
  unescape(s: string): string
  parse(s: string, backrefCb?: BackrefCb | null): any
  parsePartial(s: string, howNext: HowNext, cb: PartialCb, backrefCb: BackrefCb | null): any
  connectorOfCname(cname: string): Connector<any>
}

export interface Addon {
  Stringifier: new(err: AddonErrorClass, opt: AddonCreateOptions) => AddonStringifier
  Parser: new(err: AddonErrorClass, opt: AddonCreateOptions) => AddonParser
}

