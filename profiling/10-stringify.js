import Benchmark from 'benchmark';
import Wson from '../src';

let wsonJs = Wson({useAddon: false});
let wsonAddon = Wson({useAddon: true});

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

// x = ['foo', 'bar', 123, true, ['a', 'b']]
// x = {a: true, b: true, c:true, d: true}

suite.add('JSON.stringify', () => JSON.stringify(x));
suite.add('WSON-js.stringify', () => wsonJs.stringify(x));
suite.add('WSON-addon.stringify', () => wsonAddon.stringify(x));

suite.on('cycle', event => console.log(String(event.target))
);
// suite.on 'complete', ->
//   console.log 'Fastest is ' + @filter('fastest').pluck('name')

suite.run({async: true});
