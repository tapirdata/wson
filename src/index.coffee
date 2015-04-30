'use strict'

_ = require 'lodash'

try
  addon = require 'wson-addon'
catch
  addon = null

errors = require './errors'

normStringifyConnectors = (cons) ->
  if _.isObject(cons) and not _.isEmpty(cons)
    connectors = {}
    for name, con of cons
      if _.isFunction con
        connector =
          by: con
      else
        connector = _.clone con
      connector.name = name
      if not _.isFunction connector.split
        connector.split = (x) -> x.__wsonsplit__()
      connectors[name] = connector
    connectors


normParseConnectors = (cons) ->
  if _.isObject(cons) and not _.isEmpty(cons)
    connectors = {}
    for name, con of cons
      if _.isFunction con
        connector =
          by: con
      else
        connector = _.clone con
      connector.name = name
      if _.isFunction connector.create
        connector.hasCreate = true
      else
        connector.hasCreate = false
        do (connector) ->
          if not _.isFunction connector.precreate
            connector.precreate = ->
              Object.create connector.by.prototype
          if not _.isFunction connector.postcreate
            connector.postcreate = (obj, args) ->
              ret = connector.by.apply obj, args
              if Object(ret) == ret then ret else obj
      connectors[name] = connector
    connectors



class Wson

  constructor: (options) ->
    options or= {}
    if options.version? and options.version != 1
      throw new Error "Only WSON version 1 is supported"

    useAddon = options.useAddon

    if addon
      useAddon = useAddon != false
    else
      if useAddon == true
        throw new Error "wson-addon is not installed"

    if options.connectors
      stringifyOptions =
        connectors: normStringifyConnectors options.connectors
      parseOptions =
        connectors: normParseConnectors options.connectors
    else
      stringifyOptions = {}
      parseOptions = {}

    # console.log 'options=', options
    # console.log 'stringifyOptions=', stringifyOptions
    # console.log 'parseOptions=', parseOptions

    if useAddon
      stringifier = new addon.Stringifier errors.StringifyError, stringifyOptions
      parser = new addon.Parser errors.ParseError, parseOptions

      @escape = (x) -> stringifier.escape x
      @unescape = (x) -> parser.unescape x
      @stringify = (x) -> stringifier.stringify x
      @parse = (x) -> parser.parse x

    else
      transcribe = require './transcribe'
      Stringifier = require './stringifier'
      Parser = require './parser'
      stringifier = new Stringifier stringifyOptions
      parser = new Parser parseOptions

      @escape = (s) -> transcribe.escape s
      @unescape = (s) -> transcribe.unescape s
      @stringify = (x) -> stringifier.stringify x
      @parse = (s) -> parser.parse s



factory = (options) ->
  new Wson options

factory.Wson = Wson
factory.ParseError = errors.ParseError
factory.StringifyError= errors.StringifyError

module.exports = factory
