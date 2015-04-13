'use strict'

assert = require 'assert'

mustRegExpQuote = ((chars) ->
  o = {}
  for c in chars
    o[c] = true
  o
)('-\\()+*.?[]^$')

quoteRegExp = (char) ->
  if mustRegExpQuote[char]
    '\\' + char
  else
    char


class TSON
  @defaultCharOfQu:
  #qu: char
    b: '{'
    c: '}'
    a: '['
    e: ']'
    i: ':'
    n: '#'
    p: '|'
    q: '`'
  @defaultPrefix: '`'  

  constructor: (options) ->
    options or= {}
    charOfQu = options.charOfQu or @constructor.defaultCharOfQu
    prefix = options.prefix or @constructor.defaultPrefix
    quOfChar = {}
    charBrick = ''
    quBrick = ''
    for qu, char of charOfQu
      quOfChar[char] = qu
      # quBrick += quoteRegExp qu
      charBrick += quoteRegExp char
    @charOfQu = charOfQu  
    @quOfChar = quOfChar  
    @charRe = new RegExp '[' + charBrick + ']', 'gm'
    @quRe = new RegExp quoteRegExp(prefix) + '(.)', 'gm'
    @prefix = prefix

  quote: (s) ->  
    s.replace @charRe, (char) => @prefix + @quOfChar[char]

  unquote: (s) ->  
    s.replace @quRe, (all, qu) =>
      char = @charOfQu[qu]
      assert char?, "unxpected qu: '#{qu}'"
      char
  
  serialize: (x) ->
    String x

  deserialize: (s) ->


factory = (options) ->
  new TSON options

factory.TSON = TSON

module.exports = factory
