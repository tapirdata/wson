import * as _ from "lodash"
import { ParseError, StringifyError } from "./errors"
import { PartialCb, BackrefCb, Connector } from "./types"
import { Parser } from "./parser"
import { Stringifier } from "./stringifier"
import { escape, unescape } from "./transcribe"
import { StringifyOptions, ParseOptions, ParsePartialOptions, WsonOptions } from "./options"

function normConnectors(cons?: Record<string, any>) {
  if (_.isObject(cons) && !_.isEmpty(cons)) {
    const connectors: Record<string, Connector<any>> = {}
    for (const name of Object.keys(cons)) {
      const con = cons[name]
      const connector: Partial<Connector<any>> =
        _.isFunction(con)
        ? { by: con }
        : _.clone(con)
      connector.name = name
      const { by } = connector

      // normalize split
      if (!_.isFunction(connector.split)) {
        if (_.isFunction(by.prototype.__wsonsplit__)) {
          connector.split = (x: any) => x.__wsonsplit__()
        } else {
          connector.split = (x: any) => []
        }
      }

      let hasCreate = false
      // normalize create
      if (_.isFunction(connector.create)) {
        hasCreate = true
      } else if (_.isFunction(by.__wsoncreate__)) {
        connector.create = (args: any[]) => by.__wsoncreate__(args)
        hasCreate = true
      } else {
        const connectorHasPostcreate = _.isFunction(connector.postcreate)
        const protoHasPostcreate = _.isFunction(by.prototype.__wsonpostcreate__)
        if (connectorHasPostcreate || protoHasPostcreate) {
          // normalize precreate
          connector.hasCreate = false
          if (!_.isFunction(connector.precreate)) {
            if (_.isFunction(by.__wsonprecreate__)) {
              connector.precreate = () => by.__wsonprecreate__()
            } else {
              connector.precreate = () => Object.create(by.prototype)
            }
          }
          // normalize precreate
          if (!connectorHasPostcreate) {
            connector.postcreate = (x: any, args: any[]) => {
              const x1 = x.__wsonpostcreate__(args)
              return _.isObject(x1) ? x1 : x
            }
          }
        } else { // no postcreate
          connector.create = (args: any[]) => new by(...args)
          hasCreate = true
        }
      }
      connector.hasCreate = hasCreate
      connectors[name] = connector as Connector<any>
    }
    return connectors
  }
}

export class Wson {
  public escape: (s: string) => string
  public unescape: (s: string) => string
  public getTypeid: (x: any) => number
  public stringify: (x: any, options?: StringifyOptions) => string
  public parse: (s: string, options?: ParseOptions) => any
  public parsePartial: (s: string, options: ParsePartialOptions) => any
  public connectorOfCname: (s: string) => any
  public connectorOfValue: (x: any) => any

  constructor({connectors, addon, useAddon, version }: WsonOptions = {}) {
    if ((version != null) && version !== 1) {
      throw new Error("Only WSON version 1 is supported")
    }

    if (addon) {
      useAddon = useAddon !== false
    } else {
      if (useAddon === true) {
        throw new Error("wson-addon is not supplied")
      }
    }

    const stringifyOptions: any = {}
    const parseOptions: any = {}
    if (connectors) {
      connectors = normConnectors(connectors)
      stringifyOptions.connectors = connectors
      parseOptions.connectors = connectors
    }

    if (useAddon) {
      const stringifier = new addon!.Stringifier(StringifyError, stringifyOptions)
      const parser = new addon!.Parser(ParseError, parseOptions)

      this.escape = (s: string) => stringifier.escape(s)
      this.unescape = (s: string) => parser.unescape(s)
      this.getTypeid = (x: any) => stringifier.getTypeid(x)
      this.stringify = (x: any, options?: StringifyOptions) => stringifier.stringify(x, options?.haverefCb)
      this.parse = (s: string, options?: ParseOptions) => parser.parse(s, options?.backrefCb)
      this.parsePartial = (s: string, options: ParsePartialOptions, cb1?: PartialCb) => {
        let howNext: any
        let cb: PartialCb
        let backrefCb: BackrefCb | null = null
        if (_.isObject(options)) {
          ({ howNext, cb, backrefCb = null } = options)
        } else {
          howNext = options
          cb = cb1 as PartialCb
        }
        const safeCb = (isText: boolean, part: string, pos: number) => {
          let result
          try {
            result = cb(isText, part, pos)
          } catch (e) {
            if (e instanceof Error) {
              return e
            } else {
              return new Error(e)
            }
          }
          if (result === true || result === false || _.isArray(result)) {
            return result
          } else {
            return null
          }
        }
        return parser.parsePartial(s, howNext, safeCb, backrefCb)
      }
      this.connectorOfCname = (cname) => parser.connectorOfCname(cname)
      this.connectorOfValue = (value) => stringifier.connectorOfValue(value)

    } else {
      const stringifier = new Stringifier(stringifyOptions)
      const parser = new Parser(parseOptions)

      this.escape = (s) => escape(s)
      this.unescape = (s) => unescape(s)
      this.getTypeid = (x) => stringifier.getTypeid(x)
      this.stringify = (x, options?: StringifyOptions) => stringifier.stringify(x, undefined, options ? options.haverefCb : null)
      this.parse = (s, options?: ParseOptions) => parser.parse(s, options || {})
      this.parsePartial = (s: string, options: ParsePartialOptions, cb1?: PartialCb) => {
        if (!_.isObject(options)) {
          if (cb1 == null) {
            throw new Error("no callback specified")
          }
          options = {
            howNext: options,
            cb: cb1,
          }
        }
        return parser.parsePartial(s, options)
      }
      this.connectorOfCname = (cname) => parser.connectorOfCname(cname)
      this.connectorOfValue = (value) => stringifier.connectorOfValue(value)
    }
  }
}

export interface Factory {
  (options?: WsonOptions): Wson
  Wson: typeof Wson
  ParseError: typeof ParseError
  StringifyError: typeof StringifyError
}

const factory = ((createOptions?: WsonOptions) => {
  return new Wson(createOptions)
}) as Factory

// legacy
factory.Wson = Wson
factory.ParseError = ParseError
factory.StringifyError = StringifyError

export default factory
export {
  Connector,
  ParseError,
  ParseOptions,
  StringifyError,
  StringifyOptions,
  WsonOptions
}
