'use strict'

Benchmark = require 'benchmark'
Wson = require '../src'

suite = new Benchmark.Suite()

x =
  a: 42
  b: 'foobar'
  c: [1, 4, 9, 16]
  rest:
    x: true
    y: false
    z: ['foo', 'bar', null, 'baz']

wsonJs = Wson useAddon: false
wsonAddon = Wson useAddon: true

sj = JSON.stringify x
st = wsonJs.stringify x

suite.add 'JSON.parse', -> JSON.parse sj
suite.add 'WSON-js.parse', -> wsonJs.parse st
suite.add 'WSON-addon.parse', -> wsonAddon.parse st

suite.on 'cycle', (event) ->
  console.log String(event.target)
# suite.on 'complete', ->
#   console.log 'Fastest is ' + @filter('fastest').pluck('name')

suite.run async: true

