import { Value } from '../../src/types';

export const pairs: [Value, number][] = [
  [undefined, 1],
  [null, 2],
  [false, 4],
  [true, 4],
  [42, 8],
  [NaN, 8],
  [new Date(123), 16],
  ['', 20],
  [[], 24],
  [{}, 32],
];
