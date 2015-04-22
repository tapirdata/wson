assert = require 'assert'

regExpQuoteSet = do (chars='-\\()+*.?[]^$') ->
  o = {}
  for c in chars
    o[c] = true
  o

quoteRegExp = (char) ->
  if regExpQuoteSet[char]
    '\\' + char
  else
    char

charOfXar = 
#xar: char
  b: '{'
  c: '}'
  a: '['
  e: ']'
  i: ':'
  n: '#'
  p: '|'
  q: '`'

prefix = '`'  

module.exports = do ->    
  charBrick = ''
  splitBrick = ''
  xarOfChar = {}
  for xar, char of charOfXar
    xarOfChar[char] = xar
    charBrick += quoteRegExp char
    if char != prefix
      splitBrick += quoteRegExp char 
  return { 
    prefix: prefix
    charOfXar: charOfXar
    xarOfChar: xarOfChar  
    charRe: new RegExp '[' + charBrick + ']', 'gm'
    xarRe: new RegExp quoteRegExp(prefix) + '(.)', 'gm'
    splitRe: new RegExp '([' + splitBrick + '])'
    unescape: (s) ->
      s.replace @xarRe, (all, xar) =>
        char = @charOfXar[xar]
        assert char?, "unxpected xar: '#{xar}'"
        char
    escape: (s) ->  
      s.replace @charRe, (char) => @prefix + @xarOfChar[char]
  }    

