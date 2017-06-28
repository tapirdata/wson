import _ = require("lodash")
import addon from "wson-addon"
import { ParseError, StringifyError } from "./errors"
import { Cb, Connector } from "./options"
import Parser from "./parser"
import Stringifier from "./stringifier"
import transcribe from "./transcribe"

// let addon = null
// try {
//   addon = require('wson-addon').default;
// } catch (error) {
// }

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

      if (!_.isFunction(connector.split)) {
        connector.split = (x) => x.__wsonsplit__()
      }
      connectors[name] = connector

      if (_.isFunction(connector.create)) {
        connector.hasCreate = true
      } else {
        connector.hasCreate = false
        if (!_.isFunction(connector.precreate)) {
          connector.precreate = () => Object.create(connector.by.prototype)
        }
        if (!_.isFunction(connector.postcreate)) {
          connector.postcreate = (obj, args) => {
            const ret = connector.by.apply(obj, args)
            if (Object(ret) === ret) {
              return ret
            } else {
              return obj
            }
          }
        }
      }
    }
    return connectors
  }
}

export class Wson {

  protected escape: (s: string) => string
  protected unescape: (s: string) => string
  protected getTypeid: (x: any) => number
  protected stringify: (x: any, options?: any) => string
  protected parse: (s: string, options?: any) => any
  protected parsePartial: (s: string, options?: any) => any
  protected connectorOfCname: (s: string) => any
  protected connectorOfValue: (x: any) => any

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
      this.parsePartial = (s: string, options: any) => {
        let howNext: any
        let cb: (...args: any[]) => any
        let backrefCb: Cb | undefined
        if (_.isObject(options)) {
          ({ howNext, cb, backrefCb } = options)
        } else {
          [, howNext, cb] = arguments
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
      this.parsePartial = (s, options) => {
        if (!_.isObject(options)) {
          options = {
            howNext: arguments[1],
            cb:      arguments[2],
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
  (options: any): any
  Wson: typeof Wson
  ParseError: typeof ParseError
  StringifyError: typeof StringifyError
}

const factory = ((createOptions: any) => {
  return new Wson(createOptions)
}) as Factory

factory.Wson = Wson
factory.ParseError = ParseError
factory.StringifyError = StringifyError

export default factory
export { ParseError, StringifyError }
