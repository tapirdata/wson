'use strict'

assert = require 'assert'
_ = require 'lodash'

nativeTson = require('bindings') 'native_tson'

if true
  tsonParser = require './parser'

  class TSON

    constructor: ->
      @parser = tsonParser()

    escape: (s) ->  
      nativeTson.escape s

    unescape: (s) ->  
      @parser.unescape s

    stringify: (x) ->
      nativeTson.serialize x

    parse: (s) ->
      @parser.parse s
else  

  tsonParser = require './parser'
  tsonSerializer = require './serializer'

  class TSON

    constructor: ->
      @serializer = tsonSerializer()
      @parser = tsonParser()

    escape: (s) ->  
      @serializer.escape s

    unescape: (s) ->  
      @parser.unescape s

    stringify: (x) ->
      @serializer.serializeValue x

    parse: (s) ->
      @parser.parse s


factory = (options) ->
  new TSON options
factory.TSON = TSON

module.exports = factory
