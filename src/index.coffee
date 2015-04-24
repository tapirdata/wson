'use strict'

assert = require 'assert'
_ = require 'lodash'

try
  hitson = require 'hitson'
catch
  hitson = null


class Tson

  constructor: (options) ->
    options or= {}

    useHi = options.hi

    if hitson
      useHi = useHi != false
    else  
      if useHi == true
        console.warn 'hitson not found; using js-tson'
        useHi = false

    if useHi
      stringifier = new hitson.Stringifier()
      parser = new hitson.Parser()

      @escape = hitson.escape
      @unescape = hitson.unescape
      @stringify = (x) -> stringifier.stringify x
      @parse = (x) -> parser.parse x

    else
      transcribe = require './transcribe'
      Stringifier = require './stringifier'
      Parser = require './parser'
      stringifier = new Stringifier()
      parser = new Parser()

      @escape = (s) -> transcribe.escape s
      @unescape = (s) -> transcribe.unescape s
      @stringify = (x) -> stringifier.stringify x
      @parse = (s) -> parser.parse s

      
module.exports = Tson
