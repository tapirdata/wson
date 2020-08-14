import * as _ from "lodash"
import { StringifyError } from "./errors"
import { Connector, HaverefCb } from "./types"
import transcribe from "./transcribe"

class Stringifier {

  private connectors: Record<string, Connector<any>>

  constructor(options: any = {}) {
    this.connectors = options.connectors
  }

  public getTypeid(x: any) {
    if (x === null) {
      return 2
    } else {
      switch (typeof x) {
        case "undefined":
          return 1
        case "boolean":
          return 4
        case "number":
          return 8
        case "string":
          return 20
        case "object":
          if (x instanceof Date) {
            return 16
          } else if (_.isArray(x)) {
            return 24
          } else {
            return 32
          }
        default:
          return 0
      }
    }
  }

  public stringify(x: any, haves: any[]= [], haverefCb?: HaverefCb | null): string {
    const typeid = this.getTypeid(x)
    switch (typeid) {
      case 0:
        throw new StringifyError(x)
      case 1:
        return "#u"
      case 2:
        return "#n"
      case 4:
        if (x) { return "#t" } else { return "#f" }
      case 8:
        return `#${x.toString()}`
      case 16:
        return `#d${x.valueOf().toString()}`
      case 20:
        if (x.length === 0) {
          return "#"
        } else {
          return transcribe.escape(x)
        }
      default:
        const backref = this.getBackref(x, haves, haverefCb)
        if (backref != null) {
          return `|${backref}`
        } else if (typeid === 24) {
          return this.stringifyArray(x, haves, haverefCb)
        } else {
          return this.stringifyObject(x, haves, haverefCb)
        }
    }
  }

  public connectorOfValue(x: any) {
    const constr = x.constructor
    if (this.connectors && (constr != null) && constr !== Object) {
      for (const name of Object.keys(this.connectors)) {
        const connector = this.connectors[name]
        if (connector.by === constr) {
          return connector
        }
      }
    }
  }

  protected getBackref(x: any, haves: any[], haverefCb?: HaverefCb | null): number | null {
    for (const [idx, have] of haves.entries()) {
      if (have === x) {
        return haves.length - idx - 1
      }
    }
    if (haverefCb != null) {
      const idx = haverefCb(x)
      if (idx != null) {
        return haves.length + idx
      }
    }
    return null
  }

  protected stringifyArray(x: any, haves: any[], haverefCb?: HaverefCb | null) {
    haves.push(x)
    let result = "["
    let first = true
    for (const elem of x) {
      if (first) {
        first = false
      } else {
        result += "|"
      }
      result += this.stringify(elem, haves, haverefCb)
    }
    haves.pop()
    return result + "]"
  }

  protected stringifyKey(x?: string) {
    if (x) {
      return transcribe.escape(x)
    } else {
      return "#"
    }
  }

  protected stringifyObject(x: any, haves: any[], haverefCb?: HaverefCb | null) {
    const connector = this.connectorOfValue(x)
    if (connector) {
      return this.stringifyConnector(connector, x, haves, haverefCb)
    }
    haves.push(x)
    const keys = _.keys(x).sort()
    let result = "{"
    let first = true
    for (const key of keys) {
      if (first) {
        first = false
      } else {
        result += "|"
      }
      const value: any = x[key]
      result += this.stringifyKey(key)
      if (value !== true) {
        result += ":"
        result += this.stringify(value, haves, haverefCb)
      }
    }
    haves.pop()
    return result + "}"
  }

  protected stringifyConnector(connector: Connector<any>, x: any, haves: any[], haverefCb?: HaverefCb | null) {
    haves.push(x)
    let result = `[:${transcribe.escape(connector.name as string)}`
    const args: any[] = connector.split(x)
    for (const elem of args) {
      result += "|"
      result += this.stringify(elem, haves, haverefCb)
    }
    haves.pop()
    return result + "]"
  }

}

// Stringifier.norm = normConnectors
export default Stringifier
