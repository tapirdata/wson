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

module.exports = [
  ['abc', 'abc']
  ['', '#']
  ['a[b]c', 'a`ab`ec']
  [3, '#3']
  [true, '#t']
  [false, '#f']
  [null, '#n']
  [undefined, '#u']
  [undefined, '#u']
  [new Date(1400000000000), '#d1400000000000']
  [':abc', '`iabc']
  # array
  [['ab'], '[ab]']
  [[], '[]']
  [['a',''], '[a|#]']
  [['ab', 'c'], '[ab|c]']
  [['ab', 3, true, 'c', null], '[ab|#3|#t|c|#n]']
  # object
  [{}, '{}']
  [{a: 'aa', '': 'bb'}, '{#:bb|a:aa}']
  [{a: 'aa', b: 'bb'}, '{a:aa|b:bb}']
  [{a: 3, b: 4}, '{a:#3|b:#4}']
  [{a: '3', b: true}, '{a:3|b}']
  [{a: '3', b: null}, '{a:3|b:#n}']
  [{'300':'3'}, '{300:3}']
  # complex
  [[[]], '[[]]']
  [[[],[]], '[[]|[]]']
  [[{}], '[{}]']
  [{y:[], x:true}, '{x|y:[]}']
  [{a:{}}, '{a:{}}']
  [{a:{a:['b',{c:3}],b:{c:[8,2]}}}, '{a:{a:[b|{c:#3}]|b:{c:[#8|#2]}}}']
  [{'[a]':'[b]'}, '{`aa`e:`ab`e}']
  # cyclic
  [cycArr0, '[a||0]']
  [cycArr1, '[a|[b||0]]']
  [cycArr2, '[a|[b||1]]']
  [cycObj0, '{a:#3|x:|0}']
  [cycObj1, '{a:#3|b:{r0:|0}}']
  [cycObj2, '{a:#3|b:{r1:|1}}']
  # ext backref
  [{a: 3, b: [100]}, '{a:#3|b:|1}', null, (refNum) -> refNum; [[100],[101],[102]][refNum]]
  [{a: 3, b: [101]}, '{a:#3|b:|2}', null, (refNum) -> refNum; [[100],[101],[102]][refNum]]
  # extension
  [new Point(3, 4), '[:Point|#3|#4]']
  [new Polygon([new Point(3, 4), new Point(12, 5)]), '[:Polygon|[:Point|#3|#4]|[:Point|#12|#5]]']
  [new Foo(3, 4), '[:Foo|#4|#3]']
  [cycPoint, '[:Point||0|#9]']
  # fail
  ['__fail__', '', 0]
  # escape
  ['__fail__', '`zabc', 1]
  ['__fail__', 'ab`zc', 3]
  ['__fail__', 'ab`', 3]
  # literal
  ['__fail__', '#x', 1]
  ['__fail__', '#123x', 1]
  ['__fail__', '#[x]', 1]
  # syntax
  ['__fail__', '[', 1]
  ['__fail__', '}', 0]
  ['__fail__', '{', 1]
  ['__fail__', '|', 0]
  ['__fail__', ':', 0]
  ['__fail__', 'a#b', 1]
  ['__fail__', 'a|b', 1]
  ['__fail__', 'a[b]', 1]
  ['__fail__', '[]a', 2]
  ['__fail__', '[]]', 2]
  ['__fail__', '[a:4]', 2]
  ['__fail__', '{[}]', 1]
  ['__fail__', '[a|]', 3]
  ['__fail__', '{|}', 1]
  ['__fail__', '{|a}',1]
  ['__fail__', '{a|}', 3]
  ['__fail__', '{|a:b}', 1]
  ['__fail__', '{a:b|}', 5]
  ['__fail__', '{a:}']
  ['__fail__', '{a:b:}', 4]
  # backref
  ['__fail__', '[|]', 2]
  ['__fail__', '[|a]', 2]
  ['__fail__', '[|-1]', 2]
  ['__fail__', '[|1]', 2]
  ['__fail__', '[:Polygon||0]', 11]
]

