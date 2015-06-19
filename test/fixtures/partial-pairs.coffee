

module.exports = [
  ['', [false, null]]
  ['abc', [true, 'abc', false, null]]
  ['[ab|c]', [true, ['ab', 'c'], false, null]]
  [':', [false, ':', false, null]]
  [':abc', [false, ':', true, 'abc', false, null]]
  ['abc|', [true, 'abc', false, '|', false, null]]
  ['abc|def', [true, 'abc', false, '|', true, 'def', false, null]]
  ['[ab:|c]', '__fail__']
]  


