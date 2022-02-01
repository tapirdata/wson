import * as _ from 'lodash';

import {
  PartialCb,
  BackrefCb,
  Value,
  ConnectorBag,
  HowNext,
  AnyArgs,
  PreConnector,
  WsonClass,
  Connector,
  Splitter,
  Creator,
  Postcreator,
  Precreator,
} from './types';
import { Parser } from './parser';
import { Stringifier } from './stringifier';
import { escape, unescape } from './transcribe';
import { ParseOptions, ParsePartialOptions, StringifyOptions, WsonOptions } from './options';
import { ParseError, StringifyError } from './errors';

interface Splitable<A extends AnyArgs> {
  __wsonsplit__: () => A;
}

interface Postcreateable<T, A extends AnyArgs> {
  __wsonpostcreate__: (args: A) => T | null | undefined;
}

interface WsonPrototype<T, A extends AnyArgs> {
  __wsonsplit__?: () => A;
  __wsonpostcreate__?: () => T | undefined | null;
}

function normConnector<T, A extends AnyArgs>(name: string, pre: object): Connector<T, A> {
  const preConnector: PreConnector<T, A> | null = _.isFunction(pre) ? null : (pre as PreConnector<T, A>);
  const by: WsonClass<T, A> = preConnector ? preConnector.by : (pre as WsonClass<T, A>);
  const prototype = by.prototype as WsonPrototype<T, A>;

  // normalize split
  let split: Splitter<T, A> = () => [] as unknown as A;
  if (preConnector && _.isFunction(preConnector.split)) {
    split = preConnector.split;
  } else {
    if (_.isFunction(prototype.__wsonsplit__)) {
      split = (x: T) => (x as unknown as Splitable<A>).__wsonsplit__();
    }
  }

  // normalize create
  let create: Creator<T, A> | undefined;
  let precreate: Precreator<T> | undefined;
  let postcreate: Postcreator<T, A> | undefined;
  if (preConnector && _.isFunction(preConnector.create)) {
    create = preConnector.create;
  } else {
    const { __wsoncreate__ } = by;
    if (_.isFunction(__wsoncreate__)) {
      create = (args: A) => __wsoncreate__(args);
    } else {
      if (preConnector && _.isFunction(preConnector.postcreate)) {
        postcreate = preConnector.postcreate;
      } else {
        const { __wsonpostcreate__ } = prototype;
        if (_.isFunction(__wsonpostcreate__)) {
          postcreate = (x: T, args: A) => {
            const x1 = (x as unknown as Postcreateable<T, A>).__wsonpostcreate__(args);
            return _.isObject(x1) ? x1 : x;
          };
        }
      }
      if (postcreate) {
        if (preConnector && _.isFunction(preConnector.precreate)) {
          precreate = preConnector.precreate;
        } else {
          const { __wsonprecreate__ } = by;
          if (_.isFunction(__wsonprecreate__)) {
            precreate = () => __wsonprecreate__();
          } else {
            precreate = () => Object.create(prototype) as T;
          }
        }
      } else {
        create = (args: A) => new by(...(args as unknown as A));
      }
    }
  }
  return {
    name,
    by,
    split,
    create,
    precreate,
    postcreate,
    hasCreate: create != null,
  };
}

export class Wson {
  public escape: (s: string) => string;
  public unescape: (s: string) => string;
  public getTypeid: (x: Value) => number;
  public stringify: (x: Value, options?: StringifyOptions) => string;
  public parse: (s: string, options?: ParseOptions) => Value;
  public parsePartial: (s: string, options: ParsePartialOptions) => Value;
  public connectorOfCname: (s: string) => Connector | null;
  public connectorOfValue: (x: Value) => Connector | null;

  constructor({ connectors: pres, addon, useAddon, version }: WsonOptions = {}) {
    if (version != null && version !== 1) {
      throw new Error('Only WSON version 1 is supported');
    }

    if (addon) {
      useAddon = useAddon !== false;
    } else {
      if (useAddon === true) {
        throw new Error('wson-addon is not supplied');
      }
    }

    const stringifyOptions: StringifyOptions = {};
    const parseOptions: ParseOptions = {};

    let connectors: ConnectorBag;
    if (pres != null) {
      connectors = _.mapValues(pres, (pre, name) => normConnector(name, pre));
      stringifyOptions.connectors = connectors;
      parseOptions.connectors = connectors;
    }

    if (useAddon) {
      if (addon == null) {
        throw new Error('missing Addon');
      }
      const stringifier = new addon.Stringifier(StringifyError, stringifyOptions);
      const parser = new addon.Parser(ParseError, parseOptions);

      this.escape = (s: string) => stringifier.escape(s);
      this.unescape = (s: string) => parser.unescape(s);
      this.getTypeid = (x: Value) => stringifier.getTypeid(x);
      this.stringify = (x: Value, options?: StringifyOptions) => stringifier.stringify(x, options?.haverefCb);
      this.parse = (s: string, options?: ParseOptions) => parser.parse(s, options?.backrefCb);
      this.parsePartial = (s: string, options: ParsePartialOptions, cb1?: PartialCb) => {
        let howNext: HowNext;
        let cb: PartialCb;
        let backrefCb: BackrefCb | null = null;
        if (_.isObject(options)) {
          ({ howNext, cb, backrefCb = null } = options);
        } else {
          howNext = options;
          cb = cb1 as PartialCb;
        }
        const safeCb = (isText: boolean, part: string, pos: number) => {
          let result;
          try {
            result = cb(isText, part, pos);
          } catch (e) {
            if (e instanceof Error) {
              return e;
            } else {
              return new Error(JSON.stringify(e));
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
      this.connectorOfCname = (cname) => parser.connectorOfCname(cname);
      this.connectorOfValue = (value: unknown) => stringifier.connectorOfValue(value);
    } else {
      const stringifier = new Stringifier(stringifyOptions);
      const parser = new Parser(parseOptions);

      this.escape = (s) => escape(s);
      this.unescape = (s) => unescape(s);
      this.getTypeid = (x) => stringifier.getTypeid(x);
      this.stringify = (x, options?: StringifyOptions) =>
        stringifier.stringify(x, undefined, options ? options.haverefCb : null);
      this.parse = (s, options?: ParseOptions) => parser.parse(s, options || {});
      this.parsePartial = (s: string, options: ParsePartialOptions, cb1?: PartialCb) => {
        if (!_.isObject(options)) {
          if (cb1 == null) {
            throw new Error('no callback specified');
          }
          options = {
            howNext: options,
            cb: cb1,
          };
        }
        return parser.parsePartial(s, options);
      };
      this.connectorOfCname = (cname) => parser.connectorOfCname(cname);
      this.connectorOfValue = (value: Value) => stringifier.connectorOfValue(value);
    }
  }
}

export interface Factory {
  (options?: WsonOptions): Wson;
  Wson: typeof Wson;
  ParseError: typeof ParseError;
  StringifyError: typeof StringifyError;
}

const factory = ((createOptions?: WsonOptions) => {
  return new Wson(createOptions);
}) as Factory;

// legacy
factory.Wson = Wson;
factory.ParseError = ParseError;
factory.StringifyError = StringifyError;

export default factory;
export { Connector, ParseError, ParseOptions, StringifyError, StringifyOptions, WsonOptions };
