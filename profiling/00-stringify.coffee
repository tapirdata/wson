'use strict'

timerFactory = require './timer'
tsonFactory = require '../src'

nativeTson = tsonFactory()
jsTson = tsonFactory native: false

timer = timerFactory()

# JSON.stringify x
# jsTson.stringify x
# nativeTson.stringify x

x = (i) -> 
  i: i
  a: 42
  b: 'foobar' + i
  c: [1, 4, 9, 16, i]
  rest:
    x: true
    y: false
    z: [i, 'foo', 'bar', null, 'baz']
    i: i

for i in [0..100]

  timer.put 'JSON.stringify      ', (-> JSON.stringify x(i)), 500
  timer.put 'jsTson.stringify    ', (-> jsTson.stringify x(i)), 500
  timer.put 'nativeTson.stringify', (-> nativeTson.stringify x(i)), 500

timer.report()  
