import _ from 'lodash';
import { ParseError, StringifyError } from './errors';
import transcribe  from './transcribe';
import Stringifier from './stringifier';
import Parser from './parser';

let addon = null
try {
  addon = require('wson-addon');
} catch (error) {
}


const normConnectors = function(cons) {
  if (_.isObject(cons) && !_.isEmpty(cons)) {
    const connectors = {};
    for (const name of Object.keys(cons)) {
      const con = cons[name];
      let connector;
      if (_.isFunction(con)) {
        connector = {
          by: con
        };
      } else {
        connector = _.clone(con);
      }
      connector.name = name;
      
      if (!_.isFunction(connector.split)) {
        connector.split = x => x.__wsonsplit__();
      }
      connectors[name] = connector;

      if (_.isFunction(connector.create)) {
        connector.hasCreate = true;
      } else {
        connector.hasCreate = false;
        if (!_.isFunction(connector.precreate)) {
          connector.precreate = () => Object.create(connector.by.prototype);
        }
        if (!_.isFunction(connector.postcreate)) {
          connector.postcreate = function(obj, args) {
            const ret = connector.by.apply(obj, args);
            if (Object(ret) === ret) {
              return ret;
            } else {
              return obj;
            }
          };
        }
      }
    }
    return connectors;
  }
};


class Wson {

  constructor(options = {}) {
    const { version } = options;
    if ((version != null) && version !== 1) {
      throw new Error("Only WSON version 1 is supported");
    }

    let { useAddon } = options;

    if (addon) {
      useAddon = useAddon !== false;
    } else {
      if (useAddon === true) {
        throw new Error("wson-addon is not installed");
      }
    }

    const stringifyOptions = {};
    const parseOptions = {};
    let connectors;
    if (options.connectors) {
      connectors = normConnectors(options.connectors);
      stringifyOptions.connectors = connectors;
      parseOptions.connectors = connectors;
    } else {
      connectors = null;
    }

    if (useAddon) {
      const stringifier = new addon.Stringifier(StringifyError, stringifyOptions);
      const parser = new addon.Parser(ParseError, parseOptions);

      this.escape = s => stringifier.escape(s);
      this.unescape = s => parser.unescape(s);
      this.getTypeid = x => stringifier.getTypeid(x);
      this.stringify = (x, options) => stringifier.stringify(x, options ? options.haverefCb : null);
      this.parse = (s, options) => parser.parse(s, options ? options.backrefCb : null);
      this.parsePartial = function(s, options) {
        let howNext, cb, backrefCb;
        if (_.isObject(options)) {
          ({ howNext, cb, backrefCb } = options);
        } else {
          [, howNext, cb] = arguments;
        }
        const safeCb = function() {
          let result;
          try {
            result = cb.apply(null, arguments);
          } catch (e) {
            if (e instanceof Error) {
              return e;
            } else {
              return new Error(e);
            }
          }
          if (result === true || result === false || _.isArray(result)) {
            return result;
          } else {
            return null;
          }
        };
        return parser.parsePartial(s, howNext, safeCb, backrefCb);
      };
      this.connectorOfCname = cname => parser.connectorOfCname(cname);  
      this.connectorOfValue = value => stringifier.connectorOfValue(value);

    } else {
      const stringifier = new Stringifier(stringifyOptions);
      const parser = new Parser(parseOptions);

      this.escape = s => transcribe.escape(s);
      this.unescape = s => transcribe.unescape(s);
      this.getTypeid = x => stringifier.getTypeid(x);
      this.stringify = (x, options) => stringifier.stringify(x, null, options ? options.haverefCb : null);
      this.parse = (s, options) => parser.parse(s, options || {});
      this.parsePartial = function(s, options) {
        if (!_.isObject(options)) {
          options = {
            howNext: arguments[1],
            cb:      arguments[2]
          };
        }
        return parser.parsePartial(s, options);
      };
      this.connectorOfCname = cname => parser.connectorOfCname(cname);  
      this.connectorOfValue = value => stringifier.connectorOfValue(value);
    }
  }
}


function factory(options) {
  return new Wson(options);
}

factory.Wson = Wson;
factory.ParseError = ParseError;
factory.StringifyError = StringifyError;

export default factory;
export { Wson };
export { ParseError };
export { StringifyError };
