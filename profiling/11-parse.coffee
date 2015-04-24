'use strict'

Benchmark = require 'benchmark'
Tson = require '../src'

suite = new Benchmark.Suite()

x =
  a: 42
  b: 'foobar'
  c: [1, 4, 9, 16]
  rest:
    x: true
    y: false
    z: ['foo', 'bar', null, 'baz']

hiTson = new Tson hi: true
jsTson = new Tson hi: false

sj = JSON.stringify x
st = jsTson.stringify x

suite.add 'JSON.parse', -> JSON.parse sj
suite.add 'jsTson.parse', -> jsTson.parse st
suite.add 'hiTson.parse', -> hiTson.parse st

suite.on 'cycle', (event) ->
  console.log String(event.target)
# suite.on 'complete', ->
#   console.log 'Fastest is ' + @filter('fastest').pluck('name')

suite.run async: true

