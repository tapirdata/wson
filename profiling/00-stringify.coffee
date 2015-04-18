'use strict'

timerFactory = require './timer'
tsonFactory = require '../src'

nativeTson = tsonFactory()
jsTson = tsonFactory native: false

timer = timerFactory()

# JSON.stringify x
# jsTson.stringify x
# nativeTson.stringify x

for i in [0..100]
  x =
    i: i
    a: 42
    b: 'foobar' + i
    c: [1, 4, 9, 16, i]
    rest:
      x: true
      y: false
      z: [i, 'foo', 'bar', null, 'baz']
      i: i

  timer.put 'JSON.stringify      ', (-> JSON.stringify x), 500
  timer.put 'jsTson.stringify    ', (-> jsTson.stringify x), 500
  timer.put 'nativeTson.stringify', (-> nativeTson.stringify x), 500

timer.report()  
