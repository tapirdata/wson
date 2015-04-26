'use strict'

try
  addon = require 'wson-addon'
catch
  addon = null

errors = require './errors'

class Wson

  constructor: (options) ->
    options or= {}

    useAddon = options.useAddon

    if addon
      useAddon = useAddon != false
    else  
      if useAddon == true
        console.warn 'addon not found; using js-wson'
        useAddon = false

    if useAddon
      stringifier = new addon.Stringifier errors.StringifyError
      parser = new addon.Parser errors.ParseError

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

      
module.exports = Wson
