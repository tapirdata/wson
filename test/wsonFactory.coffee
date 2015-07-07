'use strict'

Wson = require '../src/'

factory = (options) ->
  Wson options


factory.ParseError = Wson.ParseError
module.exports = factory
