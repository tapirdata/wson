'use strict'

errors = require './errors'

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
  o: '{'
  c: '}'
  a: '['
  e: ']'
  i: ':'
  l: '#'
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
    xarRe: new RegExp quoteRegExp(prefix) + '(.?)', 'gm'
    splitRe: new RegExp '([' + splitBrick + '])'
    unescape: (s) ->
      s.replace @xarRe, (all, xar, pos) =>
        char = @charOfXar[xar]
        if not char?
          throw new errors.ParseError s, pos + 1 # , "unexpected escape '#{xar}'"
        char
    escape: (s) ->
      s.replace @charRe, (char) => @prefix + @xarOfChar[char]
  }

