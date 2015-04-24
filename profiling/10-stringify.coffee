'use strict'

Benchmark = require 'benchmark'
Tson = require '../src'

jsTson = new Tson hi: false
hiTson = new Tson hi: true

suite = new Benchmark.Suite()

x =
  a: 42
  b: 'foobar'
  c: [1, 4, 9, 16]
  rest:
    x: true
    y: false
    z: ['foo', 'bar', null, 'baz']

# x = ['foo', 'bar', 123, true, ['a', 'b']]
# x = {a: true, b: true, c:true, d: true}

suite.add 'JSON.stringify', -> JSON.stringify x
suite.add 'jsTson.stringify', -> jsTson.stringify x
suite.add 'hiTson.stringify', -> hiTson.stringify x

suite.on 'cycle', (event) ->
  console.log String(event.target)
# suite.on 'complete', ->
#   console.log 'Fastest is ' + @filter('fastest').pluck('name')

suite.run async: true
