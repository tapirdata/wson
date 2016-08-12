class WsonError extends Error {
  constructor() {
    super()
    if (Error.captureStackTrace) {
      Error.captureStackTrace(this, this.constructor);
    }
  }
}


class ParseError extends WsonError {
  constructor(s, pos, cause) {
    super();
    this.s = s;
    this.pos = pos;
    this.cause = cause;
    this.name = 'ParseError';
    // console.log 'ParseError "%s" pos=%s cause="%s"', @s, @pos, @cause
    if (this.pos == null) {
      this.pos = this.s.length;
    }
    if (!this.cause) {
      if (this.pos >= this.s.length) {
        var char = "end";
      } else {
        var char = `'${this.s[this.pos]}'`;
      }
      this.cause = `unexpected ${char}`;
    }
    this.message = `${this.cause} at '${this.s.slice(0, this.pos)}^${this.s.slice(this.pos)}'`;
  }
}


class StringifyError extends WsonError {
  constructor(x, cause) {
    super();
    this.x = x;
    this.name = 'StringifyError';
    try {
      var xStr = JSON.stringify(this.x);
    } catch (error) {
      var xStr = String(x);
    }

    this.message = `cannot stringify '${xStr}' (type=${typeof this.x})${cause ? ` ${cause}` : ''}`;
  }
}


export { ParseError };
export { StringifyError };


