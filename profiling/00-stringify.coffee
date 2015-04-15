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


for i in [0..4]
  timed (-> JSON.stringify x), 10000, 'JSON.stringify'
  timed (-> tson.stringify x), 10000, 'tson.stringify'
