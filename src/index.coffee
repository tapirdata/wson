'use strict'

assert = require 'assert'
_ = require 'lodash'

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
