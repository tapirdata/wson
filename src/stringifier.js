import _ from 'lodash';
import transcribe from './transcribe';
import errors from './errors';

class Stringifier {

  constructor(options) {
    if (!options) { options = {}; }
    this.connectors = options.connectors;
  }


  getBackref(x, haves, haverefCb) {
    for (var idx = 0; idx < haves.length; idx++) {
      let have = haves[idx];
      if (have === x) {
        return haves.length - idx - 1;
      }
    }
    if (haverefCb != null) {
      var idx = haverefCb(x);
      if (idx != null) {
        return haves.length + idx;
      }
    }
  }

  connectorOfValue(x) {
    // console.log 'find connectors:', @connectors
    let constr = x.constructor;
    if (this.connectors && (constr != null) && constr !== Object) {
      for (let name in this.connectors) {
        // console.log 'find', connector, x
        let connector = this.connectors[name];
        if (connector.by === constr) {
          return connector;
        }
      }
    }
  }

  stringifyArray(x, haves, haverefCb) {
    haves.push(x);
    let result = '[';
    let first = true;
    for (let i = 0; i < x.length; i++) {
      let elem = x[i];
      if (first) {
        first = false;
      } else {
        result += '|';
      }
      result += this.stringify(elem, haves, haverefCb);
    }
    haves.pop();
    return result + ']';
  }

  stringifyKey(x) {
    if (x) {
      return transcribe.escape(x);
    } else {
      return '#';
    }
  }

  stringifyObject(x, haves, haverefCb) {
    let connector = this.connectorOfValue(x);
    if (connector) {
      // console.log 'x=', x, 'con=', connector
      return this.stringifyConnector(connector, x, haves, haverefCb);
    }
    haves.push(x);
    let keys = _.keys(x).sort();
    let result = '{';
    let first = true;
    for (let i = 0; i < keys.length; i++) {
      let key = keys[i];
      if (first) {
        first = false;
      } else {
        result += '|';
      }
      let value = x[key];
      result += this.stringifyKey(key);
      if (value !== true) {
        result += ':';
        result += this.stringify(value, haves, haverefCb);
      }
    }
    haves.pop();
    return result + '}';
  }

  stringifyConnector(connector, x, haves, haverefCb) {
    haves.push(x);
    let result = `[:${transcribe.escape(connector.name)}`;
    let args = connector.split(x);
    for (let i = 0; i < args.length; i++) {
      let elem = args[i];
      result += '|';
      result += this.stringify(elem, haves, haverefCb);
    }
    haves.pop();
    return result + ']';
  }

  getTypeid(x) {
    if (x === null) {
      return 2;
    } else {
      switch (typeof x) {
        case 'undefined':
          return 1;
        case 'boolean':
          return 4;
        case 'number':
          return 8;
        case 'string':
          return 20;
        case 'object':
          if (x instanceof Date) {
            return 16;
          } else if (_.isArray(x)) {
            return 24;
          } else {
            return 32;
          }
        default:
          return 0;
      }
    }
  }
          

  stringify(x, haves, haverefCb) {
    if (!haves) { haves = []; }
    let typeid = this.getTypeid(x);
    switch (typeid) {
      case 0:
        throw new errors.StringifyError(x);
      case 1:
        return '#u';
      case 2:
        return '#n';
      case 4:
        if (x) { return '#t'; } else { return '#f'; }
      case 8:
        return `#${x.toString()}`;
      case 16:
        return `#d${x.valueOf().toString()}`;
      case 20:
        if (x.length === 0) {
          return '#';
        } else {
          return transcribe.escape(x);
        }
      default:
        let backref = this.getBackref(x, haves, haverefCb);
        if (backref != null) {
          return `|${backref}`;
        } else if (typeid === 24) {
          return this.stringifyArray(x, haves, haverefCb);
        } else {
          return this.stringifyObject(x, haves, haverefCb);
        }
    }
  }
}

// Stringifier.norm = normConnectors
export default Stringifier;

