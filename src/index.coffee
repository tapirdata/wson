'use strict'

assert = require 'assert'
_ = require 'lodash'

nativeTson = require('bindings') 'native_tson'

class TSON

  constructor: (options) ->
    options or= {}
    if options.native == false
      @escape = (s) -> require('./transcribe').escape s
      @unescape = (s) -> require('./transcribe').unescape s

      stringifier = require('./stringifier')()
      @stringify = (x) -> stringifier.stringify x

      parser = require('./parser')()
      @parse = (s) -> parser.parse s

    else
      @escape = nativeTson.escape
      @unescape = nativeTson.unescape

      stringifier = nativeTson.createStringifier()
      @stringify = stringifier.stringify

      parser = nativeTson.createParser()
      @parse = parser.parse


factory = (options) ->
  # options = native: false
  new TSON options
factory.TSON = TSON

module.exports = factory
