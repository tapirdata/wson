// tslint:disable:max-classes-per-file

export class WsonError extends Error {
  constructor() {
    super()
  }
}

export class ParseError extends WsonError {

  public s: string
  public pos: number
  public cause: string
  public message: string
  public name: string

  constructor(s: string, pos: number, cause: string) {
    super()
    this.s = s
    this.pos = pos
    this.cause = cause
    this.name = "ParseError"
    if (this.pos == null) {
      this.pos = this.s.length
    }
    if (!this.cause) {
      let char
      if (this.pos >= this.s.length) {
        char = "end"
      } else {
        char = `'${this.s[this.pos]}'`
      }
      this.cause = `unexpected ${char}`
    }
    this.message = `${this.cause} at '${this.s.slice(0, this.pos)}^${this.s.slice(this.pos)}'`
  }
}

export class StringifyError extends WsonError {

  public x: any
  public name: string
  public message: string

  constructor(x: any, cause?: string) {
    super()
    this.x = x
    this.name = "StringifyError"
    let xStr
    try {
      xStr = JSON.stringify(this.x)
    } catch (error) {
      xStr = String(x)
    }

    this.message = `cannot stringify '${xStr}' (type=${typeof this.x})${cause ? ` ${cause}` : ""}`
  }
}
