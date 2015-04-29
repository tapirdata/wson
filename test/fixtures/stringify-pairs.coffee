extdefs = require './extdefs'

Point = extdefs.Point
Polygon = extdefs.Polygon

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
  # complex
  [[[]], '[[]]']
  [[[],[]], '[[]|[]]']
  [[{}], '[{}]']
  [{y:[], x:true}, '{x|y:[]}']
  [{a:{}}, '{a:{}}']
  [{a:{a:['b',{c:3}],b:{c:[8,2]}}}, '{a:{a:[b|{c:#3}]|b:{c:[#8|#2]}}}']
  [{'[a]':'[b]'}, '{`aa`e:`ab`e}']
  #cyclic
  [cycArr0, '[a||0]']
  [cycArr1, '[a|[b||0]]']
  [cycArr2, '[a|[b||1]]']
  [cycObj0, '{a:#3|x:|0}']
  [cycObj1, '{a:#3|b:{r0:|0}}']
  [cycObj2, '{a:#3|b:{r1:|1}}']
  # extension
  [new Point(3, 4), '[:Point|#3|#4]'] 
  [new Polygon([new Point(3, 4), new Point(12, 5)]), '[:Polygon|[:Point|#3|#4]|[:Point|#12|#5]]'] 
  [cycPoint, '[:Point||0|#9]'] 
  # fail
  ['__fail__', '']
  # escape
  ['__fail__', '`zabc']
  ['__fail__', 'ab`zc']
  ['__fail__', 'ab`']
  # literal
  ['__fail__', '#x']
  ['__fail__', '#123x']
  ['__fail__', '#[x]']
  # syntax
  ['__fail__', '[']
  ['__fail__', '}']
  ['__fail__', '{']
  ['__fail__', '|']
  ['__fail__', ':']
  ['__fail__', 'a#b']
  ['__fail__', 'a|b']
  ['__fail__', 'a[b]']
  ['__fail__', '[]a']
  ['__fail__', '[]]']
  ['__fail__', '[a:4]']
  ['__fail__', '{[}]']
  ['__fail__', '[a|]']
  ['__fail__', '{|}']
  ['__fail__', '{|a}']
  ['__fail__', '{a|}']
  ['__fail__', '{|a:b}']
  ['__fail__', '{a:b|}']
  ['__fail__', '{a:}']
  ['__fail__', '{a:b:}']
  # backref
  ['__fail__', '[|]']
  ['__fail__', '[|a]']
  ['__fail__', '[|-1]']
  ['__fail__', '[|1]']
  ['__fail__', '[:Polygon||0]']
]

