'use strict'

assert = require 'assert'
_ = require 'lodash'

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

  serializeArray: (x) ->
    '[' + (_.map(x, @serialize, @).join '|') + ']'

  serializeObject: (x) ->
    keys = _.keys(x).sort()
    parts = []
    for key in keys
      value = x[key]
      if value == true
        parts.push @quote key
      else if value != undefined
        parts.push "#{@quote key}:#{@serialize value}"
    '{' + (parts.join '|') + '}'

  serialize: (x) ->
    switch
      when x == null
        '#n'
      when x == undefined
        '#u'
      when x == true
        '#t'
      when x == false
        '#f'
      when _.isNumber x
        '#' + x.toString()
      when _.isString x
        @quote x
      when _.isArray x
        @serializeArray x
      when _.isObject x
        @serializeObject x
      else
        throw new Error "cannot serialize #{typeof x}: '#{x}' #{if _.isObject x then 'by ' + x.constructor.toString()}"

  deserialize: (s) ->


factory = (options) ->
  new TSON options

factory.TSON = TSON

module.exports = factory
