extdefs = require './extdefs'

Point = extdefs.Point
Polygon = extdefs.Polygon
Foo = extdefs.Foo

cycArr0 = ['a']; cycArr0.push cycArr0
cycArr1 = ['a', ['b']]; cycArr1[1].push cycArr1[1]
cycArr2 = ['a', ['b']]; cycArr2[1].push cycArr2

cycObj0 = a: 3; cycObj0.x = cycObj0
cycObj1 = a: 3, b: {}; cycObj1.b.r0 = cycObj1.b
cycObj2 = a: 3, b: {}; cycObj2.b.r1 = cycObj2

cycPoint = new Point 8, 9
cycPoint.x = cycPoint

extBacks = [[100],[101],[102]]

backrefCb = (refNum) ->
  extBacks[refNum]

haverefCb = (item) ->
  for back, idx in extBacks
    if item == back
      return idx
  null  


module.exports = [
  {
    x: 'abc'
    s: 'abc'
  }
  {
    x: ''
    s: '#'
  }
  {
    x: 'a[b]c'
    s: 'a`ab`ec'
  }
  {
    x: 3
    s: '#3'
  }
  {
    x: true
    s: '#t'
  }
  {
    x: false
    s: '#f'
  }
  {
    x: null
    s: '#n'
  }
  {
    x: undefined
    s: '#u'
  }
  {
    x: undefined
    s: '#u'
  }
  {
    x: new Date(1400000000000)
    s: '#d1400000000000'
  }
  {
    x: ':abc'
    s: '`iabc'
  }
  # array
  {
    x: ['ab']
    s: '[ab]'
  }
  {
    x: []
    s: '[]'
  }
  {
    x: ['a', '']
    s: '[a|#]'
  }
  {
    x: ['ab', 'c']
    s: '[ab|c]'
  }
  {
    x: ['ab', 3, true, 'c', null]
    s: '[ab|#3|#t|c|#n]'
  }
  # object
  {
    x: {}
    s: '{}'
  }
  {
    x: {a: 'aa', '': 'bb'}
    s: '{#:bb|a:aa}'
  }
  {
    x: {a: 'aa', b: 'bb'}
    s: '{a:aa|b:bb}'
  }
  {
    x: {a: 3, b: 4}
    s: '{a:#3|b:#4}'
  }
  {
    x: {a: '3', b: true}
    s: '{a:3|b}'
  }
  {
    x: {a: '3', b: null}
    s: '{a:3|b:#n}'
  }
  {
    x: {'300': '3'}
    s: '{300:3}'
  }
  # complex
  {
    x: [[]]
    s: '[[]]'
  }
  {
    x: [[], []],
    s: '[[]|[]]'
  }
  {
    x: [{}]
    s: '[{}]'
  }
  {
    x: {y:[], x:true} 
    s: '{x|y:[]}'
  }
  {
    x: {a:{}}
    s: '{a:{}}'
  }
  {
    x: {a:{a:['b',{c:3}],b:{c:[8,2]}}}, 
    s:'{a:{a:[b|{c:#3}]|b:{c:[#8|#2]}}}'
  }
  {
    x: {'[a]':'[b]'}
    s: '{`aa`e:`ab`e}'
  }
  # cyclic
  {
    x: cycArr0
    s: '[a||0]'
  }
  {
    x: cycArr1
    s: '[a|[b||0]]'
  }
  {
    x: cycArr2
    s: '[a|[b||1]]'
  }
  {
    x: cycObj0
    s: '{a:#3|x:|0}'
  }
  {
    x: cycObj1
    s: '{a:#3|b:{r0:|0}}'
  }
  {
    x: cycObj2
    s: '{a:#3|b:{r1:|1}}'
  }
  # ext backref
  {
    x: {a: 3, b: extBacks[0]}
    s: '{a:#3|b:|1}' 
    backrefCb: backrefCb
    haverefCb: haverefCb
  }
  {
    x: {a: 3, b: extBacks[2]}
    s: '{a:#3|b:|3}'
    backrefCb: backrefCb
    haverefCb: haverefCb
  }
  {
    s: '{a:#3|b:|4}'
    backrefCb: backrefCb
    haverefCb: haverefCb
    parseFailPos: 9
  }
  {
    x: extBacks[0]
    s: '|0' 
    backrefCb: backrefCb
    haverefCb: haverefCb
  }
  {
    x: extBacks[1]
    s: '|1' 
    backrefCb: backrefCb
    haverefCb: haverefCb
  }
  # extension
  {
    x: new Point(3, 4)
    s: '[:Point|#3|#4]'
  }
  {
    x: new Polygon([new Point(3,4), new Point(12, 5)])
    s: '[:Polygon|[:Point|#3|#4]|[:Point|#12|#5]]'
  }
  {
    x: new Foo(3, 4)
    s: '[:Foo|#4|#3]'
  }
  {
    x: cycPoint
    s: '[:Point||0|#9]'
  }
  # fail
  {
    s: ''
    parseFailPos: 0
  }
  # escape
  {
    s: '`zabc'
    parseFailPos: 1
  }
  {
    s: 'ab`zc'
    parseFailPos: 3
  }
  {
    s: 'ab`'
    parseFailPos: 3
  }
  # literal
  {
    s: '#x'
    parseFailPos: 1
  }
  {
    s: '#123x'
    parseFailPos: 1
  }
  {
    s: '#[x]'
    parseFailPos: 1
  }
  # syntax
  {
    s: '['
    parseFailPos: 1
  }
  {
    s: '}'
    parseFailPos: 0
  }
  {
    s: '{'
    parseFailPos: 1
  }
  {
    s: '|'
    parseFailPos: 0
  }
  {
    s: ':'
    parseFailPos: 0
  }
  {
    s: 'a#b'
    parseFailPos: 1
  }
  {
    s: 'a|b'
    parseFailPos: 1
  }
  {
    s: 'a[b]'
    parseFailPos: 1
  }
  {
    s: '[]a'
    parseFailPos: 2
  }
  {
    s: '[]]'
    parseFailPos: 2
  }
  {
    s: '[a:4]'
    parseFailPos: 2
  }
  {
    s: '{[}]'
    parseFailPos: 1
  }
  {
    s: '[a|]'
    parseFailPos: 3
  }
  {
    s: '{|}'
    parseFailPos: 1
  }
  {
    s: '{|a}'
    parseFailPos:1
  }
  {
    s: '{a|}'
    parseFailPos: 3
  }
  {
    s: '{|a:b}'
    parseFailPos: 1
  }
  {
    s: '{a:b|}'
    parseFailPos: 5
  }
  {
    s: '{a:}'
    parseFailPos: 3
  }
  {
    s: '{a:b:}'
    parseFailPos: 4
  }
  # backref
  {
    s: '[|]'
    parseFailPos: 2
  }
  {
    s: '[|a]'
    parseFailPos: 2
  }
  {
    s: '[|-1]'
    parseFailPos: 2
  }
  {
    s: '[|1]'
    parseFailPos: 2
  }
  {
    s: '[:Polygon||0]'
    parseFailPos: 11
  }
]

