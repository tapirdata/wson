import util = require('util');

import { HowNext, Value } from '../../src/types';

export function safeRepr(x: unknown): string {
  try {
    return util.inspect(x, { depth: null });
  } catch (error0) {
    try {
      return JSON.stringify(x);
    } catch (error1) {
      return String(x);
    }
  }
}

export interface Pair {
  x?: Value;
  s?: string;
  failPos?: number;
  stringifyFailPos?: number;
  parseFailPos?: number;
  backrefCb?: (refNum: number) => Value;
  haverefCb?: (item: Value) => number | null;
  nrs?: HowNext[];
  col?: unknown[];
}
