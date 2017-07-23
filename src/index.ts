import _ = require("lodash")
import { ParseError, StringifyError } from "./errors"
import { AnyCb, BackrefCb, Connector } from "./options"
import Parser from "./parser"
import Stringifier from "./stringifier"
import transcribe from "./transcribe"

let addon: any
try {
  // tslint:disable-next-line:no-var-requires
  addon = require("wson-addon").default
} catch (error) {
  addon = null
}



function normConnectors(cons: any) {
  if (_.isObject(cons) && !_.isEmpty(cons)) {
    const connectors: { [name: string]: any } = {}
    for (const name of Object.keys(cons)) {
      const con = cons[name]
      let connector: Connector
      if (_.isFunction(con)) {
        connector = {
          by: con,
        } as Connector
      } else {
        connector = _.clone(con)
      }
      connector.name = name
      const by = connector.by

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
      connectors[name] = connector
    }
    return connectors
  }
}

export class Wson {

  public escape: (s: string) => string
  public unescape: (s: string) => string
  public getTypeid: (x: any) => number
  public stringify: (x: any, options?: any) => string
  public parse: (s: string, options?: any) => any
  public parsePartial: (s: string, options?: any) => any
  public connectorOfCname: (s: string) => any
  public connectorOfValue: (x: any) => any

  constructor(wsonOptions: any = {}) {
    const { version } = wsonOptions
    if ((version != null) && version !== 1) {
      throw new Error("Only WSON version 1 is supported")
    }

    let { useAddon } = wsonOptions

    if (addon) {
      useAddon = useAddon !== false
    } else {
      if (useAddon === true) {
        throw new Error("wson-addon is not installed")
      }
    }

    const stringifyOptions: any = {}
    const parseOptions: any = {}
    let connectors
    if (wsonOptions.connectors) {
      connectors = normConnectors(wsonOptions.connectors)
      stringifyOptions.connectors = connectors
      parseOptions.connectors = connectors
    } else {
      connectors = null
    }

    if (useAddon) {
      const stringifier = new addon.Stringifier(StringifyError, stringifyOptions)
      const parser = new addon.Parser(ParseError, parseOptions)

      this.escape = (s: string) => stringifier.escape(s)
      this.unescape = (s: string) => parser.unescape(s)
      this.getTypeid = (x: any) => stringifier.getTypeid(x)
      this.stringify = (x: any, options: any) => stringifier.stringify(x, options ? options.haverefCb : null)
      this.parse = (s: string, options: any) => parser.parse(s, options ? options.backrefCb : null)
      this.parsePartial = (s: string, options: any, cb1?: AnyCb) => {
        let howNext: any
        let cb: AnyCb
        let backrefCb: BackrefCb | undefined
        if (_.isObject(options)) {
          ({ howNext, cb, backrefCb } = options)
        } else {
          howNext = options
          cb = cb1 as AnyCb
        }
        const safeCb = (...args: any[]) => {
          let result
          try {
            result = cb(...args)
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

      this.escape = (s) => transcribe.escape(s)
      this.unescape = (s) => transcribe.unescape(s)
      this.getTypeid = (x) => stringifier.getTypeid(x)
      this.stringify = (x, options) => stringifier.stringify(x, undefined, options ? options.haverefCb : null)
      this.parse = (s, options) => parser.parse(s, options || {})
      this.parsePartial = (s: string, options: any, cb1?: AnyCb) => {
        if (!_.isObject(options)) {
          options = {
            howNext: options,
            cb:      cb1,
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
  (options?: any): Wson
  Wson: typeof Wson
  ParseError: typeof ParseError
  StringifyError: typeof StringifyError
}

const factory = ((createOptions?: any) => {
  return new Wson(createOptions)
}) as Factory

factory.Wson = Wson
factory.ParseError = ParseError
factory.StringifyError = StringifyError

export default factory
export { ParseError, StringifyError }
