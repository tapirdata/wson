'use strict'

assert = require 'assert'
_ = require 'lodash'

nativeTson = require('bindings') 'native_tson'

class TSON

  constructor: (options) ->
    options or= {}
    if options.native == false
      serializer = require('./serializer')()
      @escape = (s) -> serializer.escape s
      @stringify = (x) -> serializer.serializeValue x
    else  
      @escape = nativeTson.escape
      @stringify = nativeTson.serialize

    if options.native == false
      parser = require('./parser')()
      @unescape = (s) -> parser.unescape s
      @parse = (s) -> parser.parse s
    else  
      @unescape = nativeTson.unescape
      # parser = require('./parser')()
      # @parse = (s) -> parser.parse s
      @parse = nativeTson.parse



factory = (options) ->
  new TSON options
factory.TSON = TSON

module.exports = factory
