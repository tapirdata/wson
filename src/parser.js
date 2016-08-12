import assert from 'assert';
import transcribe from './transcribe';
import { ParseError } from './errors';

class Source {

  constructor(parser, s) {
    this.parser = parser;
    this.s = s;
    this.sLen = this.s.length;
    this.rest = this.s;
    // @parts = @s.split transcribe.splitRe
    // @partIdx = null
    this.splitRe = new RegExp(transcribe.splitBrick, 'g');
    this.pos = null;
    this.isEnd = false;
    this.next();
  }


  next() {
    if (this.pos != null) {
      this.pos += this.part.length;
    } else {
      this.pos = 0;
    }

    if (this.pos >= this.sLen) {
      this.isEnd = true;
    } else {
      if (this.nt != null) {
        this.part = this.nt;
        this.isText = false;
        this.nt = null;
      } else {
        let m = this.splitRe.exec(this.rest);
        let restPos = (this.pos + this.rest.length) - this.sLen;
        if (m != null) {
          if (m.index > restPos) {
            let partLen = m.index - restPos;
            this.isText = true;
            this.part = this.rest.slice(restPos, restPos + partLen);
            this.nt = m[0];
          } else {
            this.isText = false;
            this.part = m[0];
          }
        } else {
          this.part = this.rest.slice(restPos);
          this.isText = true;
        }
      }
    }
  }


  skip(n) {
    this.rest = this.s.slice(this.pos + n);
    this.splitRe = new RegExp(transcribe.splitBrick, 'g');
    this.nt = null;
    this.part = '';
    this.pos += n;
    return this.next();
  }
}


class State {

  constructor(source, parent, allowPartial) {
    this.source = source;
    this.parent = parent;
    this.allowPartial = allowPartial;
    this.isBackreffed = false;
  }

  throwError(cause, offset=0) {
    throw new ParseError(this.source.s, this.source.pos + offset, cause);
  }

  next() {
    return this.source.next();
  }

  scan() {
    return (() => { let result = []; while (this.stage) {
      if (this.source.isEnd) {
        this.throwError();
      }
      if (this.source.isText) {
        var handler = this.stage.text;
      } else {
        var handler = this.stage[this.source.part];
      }
      if (!handler) {
        var handler = this.stage.default;
      }
      if (!handler) {
        this.throwError();
      }
      result.push(handler.call(this));
    } return result; })();
  }

  getText() {
    try {
      return transcribe.unescape(this.source.part);
    } catch (err) {
      if (err.name === 'ParseError') {
        this.throwError(err.cause, err.pos);
      }
      throw err;
    }
  }


  invalidLiteral(part) {
    return this.throwError(`unexpected literal '${part}'`);
  }

  invalidBackref(part, offset=0) {
    return this.throwError(`unexpected backref '${part}'`, offset);
  }


  getLiteral() {
    if (this.source.isEnd || !this.source.isText) {
      var value = '';
    } else {
      let { part } = this.source;
      switch (part) {
        case 't':
          var value = true;
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
            if (value !== value) { // NaN
              this.invalidLiteral(part);
            }
            value = new Date(value);
          } else {
            value = Number(part);
            if (value !== value) { // NaN
              this.invalidLiteral(part);
            }
          }
      }
      this.next();
    }
    return value;
  }

  getBackreffed(hereRefNum) {
    let { part } = this.source;
    console.log ('getBackreffed', hereRefNum, this.source)
    if (this.source.isEnd || !this.source.isText) {
      this.invalidBackref(part);
    }
    let refNum = Number(part);
    if (!(refNum >= 0)) {
      this.invalidBackref(part);
    }
    refNum += hereRefNum;
    let state = this;
    while (refNum > 0) {
      let parentState = state.parent;
      if (parentState != null) {
        state = parentState;
      } else if (state.backrefCb != null) {
        let value = state.backrefCb(refNum - 1);
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

  fetchValue() {
    this.stage = this.stageValueStart;
    return this.scan();
  }

  fetchArray() {
    this.stage = this.stageArrayStart;
    return this.scan();
  }

  fetchObject() {
    this.stage = this.stageObjectStart;
    return this.scan();
  }

  getValue() {
    this.fetchValue();
    if (!this.source.isEnd) {
      this.throwError(); // "unexpected extra text"
    }
    return this.value;
  }
}

State.prototype.stageValueStart = {
  text: function() {
    this.value = this.getText();
    this.next();
    return this.stage = null;
  },
  ['#']: function() {
    this.next();
    this.value = this.getLiteral();
    return this.stage = null;
  },
  ['[']: function() {
    this.next();
    this.fetchArray();
    return this.stage = null;
  },
  ['{']: function() {
    this.next();
    this.fetchObject();
    return this.stage = null;
  },
  ['|']: function() {
    this.next();
    this.value = this.getBackreffed(1);
    return this.stage = null;
  },
  ['default']: function() {
    if (this.allowPartial) {
      this.isPartial = true;
      return this.stage = null;
    } else {
      return this.throwError();
    }
  }
}


State.prototype.stageArrayStart = {
  [']']: function() {
    this.value = [];
    this.next();
    return this.stage = null;
  },
  [':']: function() {
    this.next();
    return this.stage = this.stageCustomStart;
  },
  ['default']: function() {
    this.value = [];
    return this.stage = this.stageArrayNext;
  }
}


State.prototype.stageArrayNext = {
  text: function() {
    this.value.push(this.getText());
    this.next();
    return this.stage = this.stageArrayHave;
  },
  ['#']: function() {
    this.next();
    this.value.push(this.getLiteral());
    return this.stage = this.stageArrayHave;
  },
  ['[']: function() {
    this.next();
    let state = new State(this.source, this);
    state.fetchArray();
    this.value.push(state.value);
    return this.stage = this.stageArrayHave;
  },
  ['{']: function() {
    this.next();
    let state = new State(this.source, this);
    state.fetchObject();
    this.value.push(state.value);
    return this.stage = this.stageArrayHave;
  },
  ['|']: function() {
    this.next();
    this.value.push(this.getBackreffed(0));
    return this.stage = this.stageArrayHave;
  }
};

State.prototype.stageArrayHave = {
  ['|']: function() {
    this.next();
    return this.stage = this.stageArrayNext;
  },
  [']']: function() {
    this.next();
    return this.stage = null;
  }
};

State.prototype.stageObjectStart = {
  ['}']: function() {
    this.value = {};
    this.next();
    return this.stage = null;
  },
  ['default']: function() {
    this.value = {};
    return this.stage = this.stageObjectNext;
  }
};

State.prototype.stageObjectNext = {
  text: function() {
    this.key = this.getText();
    this.next();
    return this.stage = this.stageObjectHaveKey;
  },
  ['#']: function() {
    this.next();
    this.key = '';
    return this.stage = this.stageObjectHaveKey;
  }
};

State.prototype.stageObjectHaveKey = {
  [':']: function() {
    this.next();
    return this.stage = this.stageObjectHaveColon;
  },
  ['|']: function() {
    this.next();
    this.value[this.key] = true;
    return this.stage = this.stageObjectNext;
  },
  ['}']: function() {
    this.next();
    this.value[this.key] = true;
    return this.stage = null;
  }
};

State.prototype.stageObjectHaveColon = {
  text: function() {
    this.value[this.key] = this.getText();
    this.next();
    return this.stage = this.stageObjectHaveValue;
  },
  ['#']: function() {
    this.next();
    this.value[this.key] = this.getLiteral();
    return this.stage = this.stageObjectHaveValue;
  },
  ['[']: function() {
    this.next();
    let state = new State(this.source, this);
    state.fetchArray();
    this.value[this.key] = state.value;
    return this.stage = this.stageObjectHaveValue;
  },
  ['{']: function() {
    this.next();
    let state = new State(this.source, this);
    state.fetchObject();
    this.value[this.key] = state.value;
    return this.stage = this.stageObjectHaveValue;
  },
  ['|']: function() {
    this.next();
    this.value[this.key] = this.getBackreffed(0);
    return this.stage = this.stageObjectHaveValue;
  }
};

State.prototype.stageObjectHaveValue = {
  ['|']: function() {
    this.next();
    return this.stage = this.stageObjectNext;
  },
  ['}']: function() {
    this.next();
    return this.stage = null;
  }
};

State.prototype.stageCustomStart = {
  text: function() {
    let cname = this.getText();
    let connector = this.source.parser.connectorOfCname(cname);
    if (!connector) {
      this.throwError(`no connector for '${cname}'`);
    }
    this.next();
    if (connector.hasCreate) {
      this.vetoBackref = true;
    } else {
      this.value = connector.precreate();
    }
    this.connector = connector;
    this.args = [];
    return this.stage = this.stageCustomHave;
  }
};

State.prototype.stageCustomNext = {
  text: function() {
    this.args.push(this.getText());
    this.next();
    return this.stage = this.stageCustomHave;
  },
  ['#']: function() {
    this.next();
    this.args.push(this.getLiteral());
    return this.stage = this.stageCustomHave;
  },
  ['[']: function() {
    this.next();
    let state = new State(this.source, this);
    state.fetchArray();
    this.args.push(state.value);
    return this.stage = this.stageCustomHave;
  },
  ['{']: function() {
    this.next();
    let state = new State(this.source, this);
    state.fetchObject();
    this.args.push(state.value);
    return this.stage = this.stageCustomHave;
  },
  ['|']: function() {
    this.next();
    this.args.push(this.getBackreffed(0));
    return this.stage = this.stageCustomHave;
  }
};

State.prototype.stageCustomHave = {
  ['|']: function() {
    this.next();
    return this.stage = this.stageCustomNext;
  },
  [']']: function() {
    let { connector } = this;
    if (connector.hasCreate) {
      this.value = connector.create(this.args);
    } else {
      let newValue = connector.postcreate(this.value, this.args);
      if (typeof newValue === 'object') {
        if (newValue !== this.value) {
          if (this.isBackreffed) {
            this.throwError("backreffed value is replaced by postcreate");
          }
          this.value = newValue;
        }
      }
    }
    this.next();
    return this.stage = null;
  }
};




class Parser {

  constructor(options) {
    if (!options) { options = {}; }
    this.connectors = options.connectors;
  }

  parse(s, options) {
    assert(typeof s === 'string', `parse expects a string, got: ${s}`);
    let source = new Source(this, s);
    let state = new State(source);
    state.backrefCb = options.backrefCb;
    return state.getValue();
  }

  parsePartial(s, options) {
    let { howNext } = options;
    let { cb }      = options;
    assert(typeof s === 'string', `parse expects a string, got: ${s}`);
    let source = new Source(this, s);
    while (!source.isEnd) {
      if (typeof howNext === 'object') { // array
        var [nextRaw, nSkip] = howNext;
        if (nSkip > 0) {
          source.skip(nSkip);
          if (source.isEnd) {
            break;
          }
        }
      } else {
        var nextRaw = howNext;
      }
      if (nextRaw === true) {
        let { isText } = source;
        var { part } = source;
        source.next();
        howNext = cb(isText, part, source.pos);
      } else if (nextRaw === false) {
        let state = new State(source, null, true);
        state.backrefCb = options.backrefCb;
        state.fetchValue();
        if (state.isPartial) {
          var { part } = source;
          source.next();
          howNext = cb(false, part, source.pos);
        } else {
          howNext = cb(true, state.value, source.pos);
        }
      } else {
        return false;
      }
    }
    return true;
  }

  connectorOfCname(cname) {
    if (this.connectors) {
      var connector = this.connectors[cname];
    }
    return connector;
  }
}

Parser.Source = Source;
export default Parser;

