

module.exports = [
  {
    s: '', 
    col: []
    nrs: [false]
  }
  {
    s: 'abc', 
    col: [true, 'abc']
    nrs: [false]
  }
  {
    s: '[ab|c]', 
    col: [true, ['ab', 'c']]
    nrs: [false]
  }
  {
    s: ':', 
    col: [false, ':']
    nrs: [false]
  }
  {
    s: ':abc',
    col: [false, ':', true, 'abc']
    nrs: [false, false]
  }
  {
    s: 'abc|', 
    col: [true, 'abc', false, '|']
    nrs: [false, false]
  }
  {
    s: 'abc|def', 
    col: [true, 'abc', false, '|', true, 'def']
    nrs: [false, false, false]
  }
  {
    s: '[ab:|c]', 
    failPos: 3,
    nrs: [false]
  }  
  {
    s: '[ab|c]', 
    col: [true, ['ab', 'c']]
    nrs: [false]
  }
  {
    s: '[ab|c]',
    col: [false, '[', true, 'ab', false, '|', true, 'c', false, ']']
    nrs: [true, false, false, false, true]
  }
  {
    s: '[[ab|c]]',
    col: [false, '[', true, ['ab', 'c'], false, ']']
    nrs: [true, false, true]
  }
  {
    s: 'ab|c',
    col: [true, 'ab', true, 'c']
    nrs: [false, [false, 1]]
  }
  {
    s: ':foo{bar:[x|y]|:baz:{u:vw}}',
    col: [
      false, ':'
      true, 'foo'
      false, '{'
      true, 'bar'
      false, ':'
      true, ['x', 'y']
      false, '|'
      false, ':'
      true, 'baz'
      false, ':'
      true, u: 'vw'
      false, '}'
    ]
    nrs: [false, true, true, true, true, false, true, true, true, true, false, true]
  }
]  


