import Benchmark from 'benchmark';
import Wson from '../src';

let suite = new Benchmark.Suite();

let x = {
  a: 42,
  b: 'foobar',
  c: [1, 4, 9, 16],
  rest: {
    x: true,
    y: false,
    z: ['foo', 'bar', null, 'baz']
  }
};

let wsonJs = Wson({useAddon: false});
let wsonAddon = Wson({useAddon: true});

let sj = JSON.stringify(x);
let st = wsonJs.stringify(x);

suite.add('JSON.parse', () => JSON.parse(sj));
suite.add('WSON-js.parse', () => wsonJs.parse(st));
suite.add('WSON-addon.parse', () => wsonAddon.parse(st));

suite.on('cycle', event => console.log(String(event.target))
);

suite.run({async: true});

