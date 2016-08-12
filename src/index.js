import _ from 'lodash';

try {
  var addon = require('wson-addon');
} catch (error) {
  var addon = null;
}

import { ParseError, StringifyError } from './errors';

let normConnectors = function(cons) {
  if (_.isObject(cons) && !_.isEmpty(cons)) {
    let connectors = {};
    for (let name in cons) {
      let con = cons[name];
      if (_.isFunction(con)) {
        var connector =
          {by: con};
      } else {
        var connector = _.clone(con);
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
        (function(connector) {
          if (!_.isFunction(connector.precreate)) {
            connector.precreate = () => Object.create(connector.by.prototype);
          }
          if (!_.isFunction(connector.postcreate)) {
            return connector.postcreate = function(obj, args) {
              let ret = connector.by.apply(obj, args);
              if (Object(ret) === ret) { return ret; } else { return obj; }
            };
          }
        })(connector);
      }
    }
    return connectors;
  }
};


class Wson {

  constructor(options) {
    if (!options) { options = {}; }
    if ((options.version != null) && options.version !== 1) {
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

    let stringifyOptions = {};
    let parseOptions = {};
    if (options.connectors) {
      var connectors = normConnectors(options.connectors);
      stringifyOptions.connectors = connectors;
      parseOptions.connectors = connectors;
    } else {
      var connectors = null;
    }
    // @_connectors = connectors

    if (useAddon) {
      var stringifier = new addon.Stringifier(StringifyError, stringifyOptions);
      var parser = new addon.Parser(ParseError, parseOptions);

      this.escape = s => stringifier.escape(s);
      this.unescape = s => parser.unescape(s);
      this.getTypeid = x => stringifier.getTypeid(x);
      this.stringify = (x, options) => stringifier.stringify(x, __guard__(options, x1 => x1.haverefCb));
      this.parse = (s, options) => parser.parse(s, __guard__(options, x => x.backrefCb));
      this.parsePartial = function(s, options) {
        if (_.isObject(options)) {
          var { howNext } = options;
          var { cb }      = options;
          var { backrefCb } = options;
        } else {
          var howNext = arguments[1];
          var cb      = arguments[2];
        }
        let safeCb = function() {
          try {
            var result = cb.apply(null, arguments);
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
      let transcribe = require('./transcribe').default;
      let Stringifier = require('./stringifier').default;
      let Parser = require('./parser').default;
      var stringifier = new Stringifier(stringifyOptions);
      var parser = new Parser(parseOptions);

      this.escape = s => transcribe.escape(s);
      this.unescape = s => transcribe.unescape(s);
      this.getTypeid = x => stringifier.getTypeid(x);
      this.stringify = (x, options) => stringifier.stringify(x, null, __guard__(options, x1 => x1.haverefCb));
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

function __guard__(value, transform) {
  return (typeof value !== 'undefined' && value !== null) ? transform(value) : undefined;
}
