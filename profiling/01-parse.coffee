'use strict'

timed = require './timed'
tson = require('../src')()

x =
  a: 42
  b: 'foobar'
  c: [1, 4, 9, 16]
  rest:
    x: true
    y: false
    z: ['foo', 'bar', null, 'baz']

sj = JSON.stringify x
st = tson.stringify x

for i in [0..4]
  timed (-> JSON.parse sj), 10000, 'JSON.parse'
  timed (-> tson.parse st), 10000, 'tson.parse'

