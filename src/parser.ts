// tslint:disable:max-classes-per-file

import { ParseError } from "./errors"
import transcribe from "./transcribe"

function assert(cond: boolean, message: string) {
  if (!cond) {
    throw new ParseError("", 0, message)
  }
}

type Stage = any

class Source {

  public parser: Parser
  public s: string
  public sLen: number
  public rest: string
  public splitRe: RegExp
  public pos: number
  public isEnd: boolean
  public part: string
  public nt: string | null
  public isText: boolean

  constructor(parser: Parser, s: string) {
    this.parser = parser
    this.s = s
    this.sLen = this.s.length
    this.rest = this.s
    this.splitRe = new RegExp(transcribe.splitBrick, "g")
    this.isEnd = false
    this.next()
  }

  public next() {
    if (this.pos != null) {
      this.pos += this.part.length
    } else {
      this.pos = 0
    }

    if (this.pos >= this.sLen) {
      this.isEnd = true
    } else {
      if (this.nt != null) {
        this.part = this.nt
        this.isText = false
        this.nt = null
      } else {
        const m = this.splitRe.exec(this.rest)
        const restPos = (this.pos + this.rest.length) - this.sLen
        if (m != null) {
          if (m.index > restPos) {
            const partLen = m.index - restPos
            this.isText = true
            this.part = this.rest.slice(restPos, restPos + partLen)
            this.nt = m[0]
          } else {
            this.isText = false
            this.part = m[0]
          }
        } else {
          this.part = this.rest.slice(restPos)
          this.isText = true
        }
      }
    }
  }

  public skip(n: number) {
    this.rest = this.s.slice(this.pos + n)
    this.nt = null
    this.part = ""
    this.pos += n
    this.next()
  }
}

class State {

  public source: Source
  public parent: State | null
  public allowPartial: boolean
  public isBackreffed: boolean
  public isPartial: boolean
  public backrefCb: (ref: number) => any
  public value: any
  protected stage: Stage
  protected vetoBackref?: boolean

  constructor(source: Source, parent: State | null, allowPartial: boolean= false) {
    this.source = source
    this.parent = parent
    this.allowPartial = allowPartial
    this.isBackreffed = false
  }

  public throwError(cause: string= "", offset: number= 0) {
    throw new ParseError(this.source.s, this.source.pos as number + offset, cause)
  }

  public next() {
    this.source.next()
  }

  public scan() {
    const result: any[] = []
    while (this.stage) {
      if (this.source.isEnd) {
        this.throwError()
      }
      let handler
      if (this.source.isText) {
        handler = this.stage.text
      } else {
        handler = this.stage[this.source.part]
      }
      if (!handler) {
        handler = this.stage.default
      }
      if (!handler) {
        this.throwError()
      }
      result.push(handler.call(this))
    }
    return result
  }

  public getText() {
    try {
      return transcribe.unescape(this.source.part)
    } catch (err) {
      if (err.name === "ParseError") {
        this.throwError(err.cause, err.pos)
      }
      throw err
    }
  }

  public invalidLiteral(part: string) {
    this.throwError(`unexpected literal '${part}'`)
  }

  public invalidBackref(part: string, offset= 0) {
    this.throwError(`unexpected backref '${part}'`, offset)
  }

  public getLiteral() {
    let value
    if (this.source.isEnd || !this.source.isText) {
      value = ""
    } else {
      const { part } = this.source
      switch (part) {
        case "t":
          value = true
          break
        case "f":
          value = false
          break
        case "n":
          value = null
          break
        case "NaN":
          value = NaN
          break
        case "u":
          value = undefined
          break
        default:
          if (part[0] === "d") {
            value = Number(part.slice(1))
            if (value !== value) { // NaN
              this.invalidLiteral(part)
            }
            value = new Date(value)
          } else {
            value = Number(part)
            if (value !== value) { // NaN
              this.invalidLiteral(part)
            }
          }
      }
      this.next()
    }
    return value
  }

  public getBackreffed(hereRefNum: number) {
    const { part } = this.source
    // console.log ('getBackreffed', hereRefNum, this.source)
    if (this.source.isEnd || !this.source.isText) {
      this.invalidBackref(part)
    }
    let refNum = Number(part)
    if (!(refNum >= 0)) {
      this.invalidBackref(part)
    }
    refNum += hereRefNum
    let state: State = this
    while (refNum > 0) {
      const parentState = state.parent
      if (parentState != null) {
        state = parentState
      } else if (state.backrefCb != null) {
        const value = state.backrefCb(refNum - 1)
        if (value != null) {
          this.next()
          return value
        } else {
          this.invalidBackref(part)
        }
      } else {
        this.invalidBackref(part)
      }
      --refNum
    }
    if (state.vetoBackref) {
      this.invalidBackref(part)
    }
    this.next()
    state.isBackreffed = true
    return state.value
  }

  public fetchValue() {
    this.stage = this.stageValueStart
    return this.scan()
  }

  public fetchArray() {
    this.stage = this.stageArrayStart
    return this.scan()
  }

  public fetchObject() {
    this.stage = this.stageObjectStart
    return this.scan()
  }

  public getValue() {
    this.fetchValue()
    if (!this.source.isEnd) {
      this.throwError() // "unexpected extra text"
    }
    return this.value
  }

  private get stageValueStart() { return {
    "text"() {
      this.value = this.getText()
      this.next()
      this.stage = null
    },
    ["#"]() {
      this.next()
      this.value = this.getLiteral()
      this.stage = null
    },
    "["() {
      this.next()
      this.fetchArray()
      this.stage = null
    },
    "{"() {
      this.next()
      this.fetchObject()
      this.stage = null
    },
    "|"() {
      this.next()
      this.value = this.getBackreffed(1)
      this.stage = null
    },
    "default"() {
      if (this.allowPartial) {
        this.isPartial = true
        this.stage = null
      } else {
        this.throwError()
      }
    },
  } as any }

  private get stageArrayStart() { return {
    "]"() {
      this.value = []
      this.next()
      this.stage = null
    },
    ":"() {
      this.next()
      this.stage = this.stageCustomStart
    },
    "default"() {
      this.value = []
      this.stage = this.stageArrayNext
    },
  } as any }

  private get stageArrayNext() { return {
    "text"() {
      this.value.push(this.getText())
      this.next()
      this.stage = this.stageArrayHave
    },
    "#"() {
      this.next()
      this.value.push(this.getLiteral())
      this.stage = this.stageArrayHave
    },
    "["() {
      this.next()
      const state = new State(this.source, this)
      state.fetchArray()
      this.value.push(state.value)
      this.stage = this.stageArrayHave
    },
    "{"() {
      this.next()
      const state = new State(this.source, this)
      state.fetchObject()
      this.value.push(state.value)
      this.stage = this.stageArrayHave
    },
    "|"() {
      this.next()
      this.value.push(this.getBackreffed(0))
      this.stage = this.stageArrayHave
    },
  } as any }

  private get stageArrayHave() { return {
    "|"() {
      this.next()
      this.stage = this.stageArrayNext
    },
    "]"() {
      this.next()
      this.stage = null
    },
  } as any }

  private get stageObjectStart() { return {
    "}"() {
      this.value = {}
      this.next()
      this.stage = null
    },
    "default"() {
      this.value = {}
      this.stage = this.stageObjectNext
    },
  } as any }

  private get stageObjectNext() { return {
    "text"() {
      this.key = this.getText()
      this.next()
      this.stage = this.stageObjectHaveKey
    },
    "#"() {
      this.next()
      this.key = ""
      this.stage = this.stageObjectHaveKey
    },
  } as any }

  private get stageObjectHaveKey() { return {
    ":"() {
      this.next()
      this.stage = this.stageObjectHaveColon
    },
    "|"() {
      this.next()
      this.value[this.key] = true
      this.stage = this.stageObjectNext
    },
    "}"() {
      this.next()
      this.value[this.key] = true
      this.stage = null
    },
  } as any }

  private get stageObjectHaveColon() { return {
    "text"() {
      this.value[this.key] = this.getText()
      this.next()
      this.stage = this.stageObjectHaveValue
    },
    "#"() {
      this.next()
      this.value[this.key] = this.getLiteral()
      this.stage = this.stageObjectHaveValue
    },
    "["() {
      this.next()
      const state = new State(this.source, this)
      state.fetchArray()
      this.value[this.key] = state.value
      this.stage = this.stageObjectHaveValue
    },
    "{"() {
      this.next()
      const state = new State(this.source, this)
      state.fetchObject()
      this.value[this.key] = state.value
      this.stage = this.stageObjectHaveValue
    },
    "|"() {
      this.next()
      this.value[this.key] = this.getBackreffed(0)
      this.stage = this.stageObjectHaveValue
    },
  } as any }

  private get stageObjectHaveValue() { return {
    "|"() {
      this.next()
      this.stage = this.stageObjectNext
    },
    "}"() {
      this.next()
      this.stage = null
    },
  } as any }

  private get stageCustomStart() { return {
    text() {
      const cname = this.getText()
      const connector = this.source.parser.connectorOfCname(cname)
      if (!connector) {
        this.throwError(`no connector for '${cname}'`)
      }
      this.next()
      if (connector.hasCreate) {
        this.vetoBackref = true
      } else {
        this.value = connector.precreate()
      }
      this.connector = connector
      this.args = []
      this.stage = this.stageCustomHave
    },
  } as any }

  private get stageCustomNext() { return {
    "text"() {
      this.args.push(this.getText())
      this.next()
      this.stage = this.stageCustomHave
    },
    "#"() {
      this.next()
      this.args.push(this.getLiteral())
      this.stage = this.stageCustomHave
    },
    "["() {
      this.next()
      const state = new State(this.source, this)
      state.fetchArray()
      this.args.push(state.value)
      this.stage = this.stageCustomHave
    },
    "{"() {
      this.next()
      const state = new State(this.source, this)
      state.fetchObject()
      this.args.push(state.value)
      this.stage = this.stageCustomHave
    },
    "|"() {
      this.next()
      this.args.push(this.getBackreffed(0))
      this.stage = this.stageCustomHave
    },
  } as any }

  private get stageCustomHave() { return {
    "|"() {
      this.next()
      this.stage = this.stageCustomNext
    },
    "]"() {
      const { connector } = this
      if (connector.hasCreate) {
        this.value = connector.create(this.args)
      } else {
        const newValue = connector.postcreate(this.value, this.args)
        if (typeof newValue === "object") {
          if (newValue !== this.value) {
            if (this.isBackreffed) {
              this.throwError("backreffed value is replaced by postcreate")
            }
            this.value = newValue
          }
        }
      }
      this.next()
      this.stage = null
    },
  } as any }

}

class Parser {

  protected connectors: any

  constructor(options: any = {}) {
    this.connectors = options.connectors
  }

  public parse(s: string, options?: any) {
    assert(typeof s === "string", `parse expects a string, got: ${s}`)
    const source = new Source(this, s)
    const state = new State(source, null)
    state.backrefCb = options.backrefCb
    return state.getValue()
  }

  public parsePartial(s: string, options?: any) {
    let { howNext } = options
    const { cb } = options
    assert(typeof s === "string", `parse expects a string, got: ${s}`)
    const source = new Source(this, s)
    let nextRaw
    while (!source.isEnd) {
      if (typeof howNext === "object") { // array
        let nSkip
        [nextRaw, nSkip] = howNext
        if (nSkip > 0) {
          source.skip(nSkip)
          if (source.isEnd) {
            break
          }
        }
      } else {
        nextRaw = howNext
      }
      if (nextRaw === true) {
        const { isText, part } = source
        source.next()
        howNext = cb(isText, part, source.pos)
      } else if (nextRaw === false) {
        const state = new State(source, null, true)
        state.backrefCb = options.backrefCb
        state.fetchValue()
        if (state.isPartial) {
          const { part } = source
          source.next()
          howNext = cb(false, part, source.pos)
        } else {
          howNext = cb(true, state.value, source.pos)
        }
      } else {
        return false
      }
    }
    return true
  }

  public connectorOfCname(cname: string) {
    let connector
    if (this.connectors) {
      connector = this.connectors[cname]
    }
    return connector
  }
}

export default Parser
export { Source }
