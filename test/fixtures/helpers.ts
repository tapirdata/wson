import util = require("util")

export function saveRepr(x: any) {
  try {
    return util.inspect(x, {depth: null})
  } catch (error0)  {
    try {
      return JSON.stringify(x)
    } catch (error1) {
      return String(x)
    }
  }
}

export interface Pair {
  x?: any
  s: string
  failPos?: number
  stringifyFailPos?: number
  parseFailPos?: number
  backrefCb?: (refNum: number) => any
  haverefCb?: (item: any) => number | null
  nrs?: any
  col?: any
}
