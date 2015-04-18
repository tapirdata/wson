'use strict'

timerFactory = require './timer'
tsonFactory = require '../src'

x =
  a: 42
  b: 'foobar'
  c: [1, 4, 9, 16]
  rest:
    x: true
    y: false
    z: ['foo', 'bar', null, 'baz']

nativeTson = tsonFactory()
jsTson = tsonFactory native: false

sj = JSON.stringify x
st = jsTson.stringify x

timer = timerFactory()

# JSON.parse sj
# jsTson.parse st
console.log 'native:', nativeTson.parse st

for i in [0..100]
  timer.put 'JSON.parse      ', (-> JSON.parse sj), 100
  timer.put 'jsTson.parse    ', (-> jsTson.parse st), 100
  timer.put 'nativeTson.parse', (-> nativeTson.parse st), 100

timer.report()  

