'use strict'

try
  hitson = require 'hitson'
catch
  hitson = null

errors = require './errors'

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
      stringifier = new hitson.Stringifier errors.StringifyError
      parser = new hitson.Parser errors.ParseError

      @escape = (x) -> stringifier.escape x
      @unescape = (x) -> parser.unescape x
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

   @ParseError = errors.ParseError
   @StringifyError= errors.StringifyError

      
module.exports = Tson
