'use strict'

Benchmark = require 'benchmark'
tsonFactory = require '../src'

nativeTson = tsonFactory()
jsTson = tsonFactory native: false

suite = new Benchmark.Suite()

x = 
  a: 42
  b: 'foobar'
  c: [1, 4, 9, 16]
  rest:
    x: true
    y: false
    z: ['foo', 'bar', null, 'baz']

suite.add 'JSON.stringify', -> JSON.stringify x
suite.add 'jsTson.stringify', -> jsTson.stringify x
suite.add 'nativeTson.stringify', -> nativeTson.stringify x

suite.on 'cycle', (event) ->
  console.log String(event.target)
# suite.on 'complete', ->
#   console.log 'Fastest is ' + @filter('fastest').pluck('name')

suite.run async: true
