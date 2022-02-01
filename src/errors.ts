import { BaseParseError, BaseStringifyError, Value } from './types';

export class ParseError extends BaseParseError {
  name = 'ParseError';

  constructor(s: string, pos: number, cause: string) {
    super(s, pos, cause);
    if (this.pos == null) {
      this.pos = this.s.length;
    }
    if (!this.cause) {
      let char;
      if (this.pos >= this.s.length) {
        char = 'end';
      } else {
        char = `'${this.s[this.pos]}'`;
      }
      this.cause = `unexpected ${char}`;
    }
    this.message = `${this.cause} at '${this.s.slice(0, this.pos)}^${this.s.slice(this.pos)}'`;
  }
}

export class StringifyError extends BaseStringifyError {
  name = 'StringifyError';

  constructor(x: Value, cause: string) {
    super(x, cause);
    let xStr;
    try {
      xStr = JSON.stringify(this.x);
    } catch (error) {
      xStr = String(x);
    }

    this.message = `cannot stringify '${xStr}' (type=${typeof this.x})${cause ? ` ${cause}` : ''}`;
  }
}
