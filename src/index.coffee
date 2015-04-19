'use strict'

assert = require 'assert'
_ = require 'lodash'

nativeTson = require('bindings') 'native_tson'

class TSON

  constructor: (options) ->
    options or= {}
    if options.native == false
      serializer = require('./serializer')()
      @escape = (s) -> require('./pp').escape s
      @stringify = (x) -> serializer.serializeValue x
    else  
      @escape = nativeTson.escape
      @stringify = nativeTson.serialize

    if options.native == false
      parser = require('./parser')()
      @unescape = (s) -> require('./pp').unescape s
      @parse = (s) -> parser.parse s
    else  
      @unescape = nativeTson.unescape
      @parse = nativeTson.parse


factory = (options) ->
  options = native: false
  new TSON options
factory.TSON = TSON

module.exports = factory
