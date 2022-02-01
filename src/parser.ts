import { ParseError } from './errors';
import { unescape, splitRe } from './transcribe';
import { AnyArgs, AnyArray, AnyRecord, BackrefCb, Connector, ConnectorBag, Value } from './types';
import { ParseOptions, ParsePartialOptions } from './options';

function assert(cond: boolean, message: string) {
  if (!cond) {
    throw new ParseError('', 0, message);
  }
}

class Source {
  public parser: Parser;
  public s: string;
  public sLen: number;
  public pos: number;
  public isEnd: boolean;
  public part: string;
  public nextChar: string | null;
  public isText: boolean;

  constructor(parser: Parser, s: string) {
    this.parser = parser;
    this.s = s;
    this.sLen = s.length;
    this.pos = 0;
    this.isEnd = false;
    this.part = '';
    this.nextChar = null;
    this.isText = false;
    this.next();
  }

  next(): void {
    if (this.pos != null) {
      this.pos += this.part.length;
    } else {
      this.pos = 0;
    }

    if (this.pos >= this.sLen) {
      this.isEnd = true;
    } else {
      if (this.nextChar != null) {
        this.part = this.nextChar;
        this.isText = false;
        this.nextChar = null;
      } else {
        const rest = this.s.slice(this.pos);
        const m = splitRe.exec(rest);
        if (m != null) {
          if (m.index > 0) {
            const partLen = m.index;
            this.isText = true;
            this.part = this.s.slice(this.pos, this.pos + partLen);
            this.nextChar = m[0];
          } else {
            this.isText = false;
            this.part = m[0];
          }
        } else {
          this.part = rest;
          this.isText = true;
        }
      }
    }
  }

  skip(n: number): void {
    this.nextChar = null;
    this.part = '';
    this.pos += n;
    this.next();
  }
}

const stageValueStart = {
  text(this: State) {
    this.value = this.getText();
    this.next();
    this.stage = null;
  },
  ['#'](this: State) {
    this.next();
    this.value = this.getLiteral();
    this.stage = null;
  },
  '['(this: State) {
    this.next();
    this.fetchArray();
    this.stage = null;
  },
  '{'(this: State) {
    this.next();
    this.fetchObject();
    this.stage = null;
  },
  '|'(this: State) {
    this.next();
    this.value = this.getBackreffed(1);
    this.stage = null;
  },
  default(this: State) {
    if (this.allowPartial) {
      this.isPartial = true;
      this.stage = null;
    } else {
      this.throwError();
    }
  },
};

const stageArrayStart = {
  ']'(this: State) {
    this.value = [];
    this.next();
    this.stage = null;
  },
  ':'(this: State) {
    this.next();
    this.stage = stageCustomStart;
  },
  default(this: State) {
    this.value = [];
    this.stage = stageArrayNext;
  },
};

const stageArrayNext = {
  text(this: State) {
    (this.value as AnyArray).push(this.getText());
    this.next();
    this.stage = stageArrayHave;
  },
  '#'(this: State) {
    this.next();
    (this.value as AnyArray).push(this.getLiteral());
    this.stage = stageArrayHave;
  },
  '['(this: State) {
    this.next();
    const state = new State(this.source, this);
    state.fetchArray();
    (this.value as AnyArray).push(state.value);
    this.stage = stageArrayHave;
  },
  '{'(this: State) {
    this.next();
    const state = new State(this.source, this);
    state.fetchObject();
    (this.value as AnyArray).push(state.value);
    this.stage = stageArrayHave;
  },
  '|'(this: State) {
    this.next();
    (this.value as AnyArray).push(this.getBackreffed(0));
    this.stage = stageArrayHave;
  },
};

const stageArrayHave = {
  '|'(this: State) {
    this.next();
    this.stage = stageArrayNext;
  },
  ']'(this: State) {
    this.next();
    this.stage = null;
  },
};

const stageObjectStart = {
  '}'(this: State) {
    this.value = {};
    this.next();
    this.stage = null;
  },
  default(this: State) {
    this.value = {};
    this.stage = stageObjectNext;
  },
};

const stageObjectNext = {
  text(this: State) {
    this.key = this.getText();
    this.next();
    this.stage = stageObjectHaveKey;
  },
  '#'(this: State) {
    this.next();
    this.key = '';
    this.stage = stageObjectHaveKey;
  },
};

const stageObjectHaveKey = {
  ':'(this: State) {
    this.next();
    this.stage = stageObjectHaveColon;
  },
  '|'(this: State) {
    this.next();
    (this.value as AnyRecord)[this.key as string] = true;
    this.stage = stageObjectNext;
  },
  '}'(this: State) {
    this.next();
    (this.value as AnyRecord)[this.key as string] = true;
    this.stage = null;
  },
};

const stageObjectHaveColon = {
  text(this: State) {
    (this.value as AnyRecord)[this.key as string] = this.getText();
    this.next();
    this.stage = stageObjectHaveValue;
  },
  '#'(this: State) {
    this.next();
    (this.value as AnyRecord)[this.key as string] = this.getLiteral();
    this.stage = stageObjectHaveValue;
  },
  '['(this: State) {
    this.next();
    const state = new State(this.source, this);
    state.fetchArray();
    (this.value as AnyRecord)[this.key as string] = state.value;
    this.stage = stageObjectHaveValue;
  },
  '{'(this: State) {
    this.next();
    const state = new State(this.source, this);
    state.fetchObject();
    (this.value as AnyRecord)[this.key as string] = state.value;
    this.stage = stageObjectHaveValue;
  },
  '|'(this: State) {
    this.next();
    (this.value as AnyRecord)[this.key as string] = this.getBackreffed(0);
    this.stage = stageObjectHaveValue;
  },
};

const stageObjectHaveValue = {
  '|'(this: State) {
    this.next();
    this.stage = stageObjectNext;
  },
  '}'(this: State) {
    this.next();
    this.stage = null;
  },
};

const stageCustomStart = {
  text(this: State) {
    const cname = this.getText();
    const connector = this.source.parser.connectorOfCname(cname);
    if (!connector) {
      this.throwError(`no connector for '${cname}'`);
    }
    this.next();
    if (connector.hasCreate) {
      this.vetoBackref = true;
    } else {
      this.value = connector.precreate?.();
    }
    this.connector = connector;
    this.args = [];
    this.stage = stageCustomHave;
  },
};

const stageCustomNext = {
  text(this: State) {
    (this.args as AnyArray).push(this.getText());
    this.next();
    this.stage = stageCustomHave;
  },
  '#'(this: State) {
    this.next();
    (this.args as AnyArray).push(this.getLiteral());
    this.stage = stageCustomHave;
  },
  '['(this: State) {
    this.next();
    const state = new State(this.source, this);
    state.fetchArray();
    (this.args as AnyArray).push(state.value);
    this.stage = stageCustomHave;
  },
  '{'(this: State) {
    this.next();
    const state = new State(this.source, this);
    state.fetchObject();
    (this.args as AnyArray).push(state.value);
    this.stage = stageCustomHave;
  },
  '|'(this: State) {
    this.next();
    (this.args as AnyArray).push(this.getBackreffed(0));
    this.stage = stageCustomHave;
  },
};

const stageCustomHave = {
  '|'(this: State) {
    this.next();
    this.stage = stageCustomNext;
  },
  ']'(this: State) {
    const { connector } = this;
    if (connector == null) {
      throw new Error('missing connector');
    }
    if (connector.hasCreate) {
      this.value = connector.create?.(this.args as AnyArgs);
    } else {
      const newValue = connector.postcreate?.(this.value, this.args as AnyArgs);
      if (typeof newValue === 'object') {
        if (newValue !== this.value) {
          if (this.isBackreffed) {
            this.throwError('backreffed value is replaced by postcreate');
          }
          this.value = newValue;
        }
      }
    }
    this.next();
    this.stage = null;
  },
};

type Handler = (this: State) => void;

export interface Stage {
  [key: string]: Handler;
}

class State {
  public source: Source;
  public parent: State | null;
  public allowPartial: boolean;
  public isBackreffed: boolean;
  public isPartial: boolean;
  public backrefCb: BackrefCb | null;
  public key?: string;
  public value: Value;
  public args?: AnyArgs;
  public connector: Connector | null;
  public stage: Stage | null;
  public vetoBackref?: boolean;

  constructor(source: Source, parent: State | null, allowPartial = false) {
    this.source = source;
    this.parent = parent;
    this.allowPartial = allowPartial;
    this.isPartial = false;
    this.backrefCb = null;
    this.isBackreffed = false;
    this.connector = null;
    this.stage = null;
  }

  public throwError(cause = '', offset = 0): never {
    throw new ParseError(this.source.s, this.source.pos + offset, cause);
  }

  public next() {
    this.source.next();
  }

  public scan() {
    const result: Value[] = [];
    while (this.stage) {
      if (this.source.isEnd) {
        this.throwError();
      }
      let handler;
      if (this.source.isText) {
        handler = this.stage.text;
      } else {
        handler = this.stage[this.source.part];
      }
      if (!handler) {
        handler = this.stage.default;
      }
      if (!handler) {
        this.throwError();
      }
      result.push(handler.call(this));
    }
    return result;
  }

  public getText() {
    try {
      return unescape(this.source.part);
    } catch (err) {
      if (err instanceof ParseError && err.name === 'ParseError') {
        this.throwError(err.cause, err.pos);
      }
      throw err;
    }
  }

  public invalidLiteral(part: string) {
    this.throwError(`unexpected literal '${part}'`);
  }

  public invalidBackref(part: string, offset = 0) {
    this.throwError(`unexpected backref '${part}'`, offset);
  }

  public getLiteral() {
    let value;
    if (this.source.isEnd || !this.source.isText) {
      value = '';
    } else {
      const { part } = this.source;
      switch (part) {
        case 't':
          value = true;
          break;
        case 'f':
          value = false;
          break;
        case 'n':
          value = null;
          break;
        case 'NaN':
          value = NaN;
          break;
        case 'u':
          value = undefined;
          break;
        default:
          if (part[0] === 'd') {
            value = Number(part.slice(1));
            if (value !== value) {
              // NaN
              this.invalidLiteral(part);
            }
            value = new Date(value);
          } else {
            value = Number(part);
            if (value !== value) {
              // NaN
              this.invalidLiteral(part);
            }
          }
      }
      this.next();
    }
    return value;
  }

  public getBackreffed(hereRefNum: number): Value {
    const { part } = this.source;
    // console.log ('getBackreffed', hereRefNum, this.source)
    if (this.source.isEnd || !this.source.isText) {
      this.invalidBackref(part);
    }
    let refNum = Number(part);
    if (!(refNum >= 0)) {
      this.invalidBackref(part);
    }
    refNum += hereRefNum;
    // eslint-disable-next-line @typescript-eslint/no-this-alias
    let state = this as State;
    while (refNum > 0) {
      const parentState = state.parent;
      if (parentState != null) {
        state = parentState;
      } else if (state.backrefCb != null) {
        const value = state.backrefCb(refNum - 1);
        if (value != null) {
          this.next();
          return value;
        } else {
          this.invalidBackref(part);
        }
      } else {
        this.invalidBackref(part);
      }
      --refNum;
    }
    if (state.vetoBackref) {
      this.invalidBackref(part);
    }
    this.next();
    state.isBackreffed = true;
    return state.value;
  }

  public fetchValue() {
    this.stage = stageValueStart;
    return this.scan();
  }

  public fetchArray() {
    this.stage = stageArrayStart;
    return this.scan();
  }

  public fetchObject() {
    this.stage = stageObjectStart;
    return this.scan();
  }

  public getValue() {
    this.fetchValue();
    if (!this.source.isEnd) {
      this.throwError(); // "unexpected extra text"
    }
    return this.value;
  }
}

export class Parser {
  protected connectors: ConnectorBag;

  constructor(options: ParseOptions = {}) {
    this.connectors = options.connectors || {};
  }

  parse(s: string, { backrefCb = null }: ParseOptions = {}): Value {
    assert(typeof s === 'string', `parse expects a string, got: ${s}`);
    const source = new Source(this, s);
    const state = new State(source, null);
    state.backrefCb = backrefCb;
    return state.getValue();
  }

  parsePartial(s: string, { howNext, cb, backrefCb }: ParsePartialOptions): Value {
    assert(typeof s === 'string', `parse expects a string, got: ${s}`);
    const source = new Source(this, s);
    let nextRaw;
    while (!source.isEnd) {
      if (Array.isArray(howNext)) {
        let nSkip;
        [nextRaw, nSkip] = howNext;
        if (nSkip > 0) {
          source.skip(nSkip);
          if (source.isEnd) {
            break;
          }
        }
      } else {
        nextRaw = howNext;
      }
      if (nextRaw === true) {
        const { isText, part } = source;
        source.next();
        howNext = cb(isText, part, source.pos);
      } else if (nextRaw === false) {
        const state = new State(source, null, true);
        state.backrefCb = backrefCb || null;
        state.fetchValue();
        if (state.isPartial) {
          const { part } = source;
          source.next();
          howNext = cb(false, part, source.pos);
        } else {
          howNext = cb(true, state.value as string, source.pos);
        }
      } else {
        return false;
      }
    }
    return true;
  }

  public connectorOfCname(cname: string): Connector | null {
    let connector: Connector | null = null;
    if (this.connectors) {
      connector = this.connectors[cname];
    }
    return connector;
  }
}

export { Source };
