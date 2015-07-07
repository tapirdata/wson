'use strict'

_ = require 'lodash'

try
  addon = require 'wson-addon'
catch
  addon = null

errors = require './errors'

normConnectors = (cons) ->
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

    stringifyOptions = {}
    parseOptions = {}
    if options.connectors
      connectors = normConnectors options.connectors
      stringifyOptions.connectors = connectors
      parseOptions.connectors = connectors
    else
      connectors = null
    @connectors = connectors

    if useAddon
      stringifier = new addon.Stringifier errors.StringifyError, stringifyOptions
      parser = new addon.Parser errors.ParseError, parseOptions

      @escape = (s) -> stringifier.escape s
      @unescape = (s) -> parser.unescape s
      @stringify = (x) -> stringifier.stringify x
      @parse = (s, options) -> parser.parse s, options?.backrefCb
      @parsePartial = (s, options) ->
        if _.isObject options
          howNext = options.howNext
          cb      = options.cb
          backrefCb = options.backrefCb
        else
          howNext = arguments[1]
          cb      = arguments[2]
        safeCb = ->
          try
            result = cb.apply null, arguments
          catch e
            if e instanceof Error
              return e
            else
              return new Error e
          if result == true or result == false or _.isArray result
            return result
          else
            return null
        parser.parsePartial s, howNext, safeCb, backrefCb

    else
      transcribe = require './transcribe'
      Stringifier = require './stringifier'
      Parser = require './parser'
      stringifier = new Stringifier stringifyOptions
      parser = new Parser parseOptions

      @escape = (s) -> transcribe.escape s
      @unescape = (s) -> transcribe.unescape s
      @stringify = (x) -> stringifier.stringify x
      @parse = (s, options) ->
        parser.parse s, options or {}
      @parsePartial = (s, options) ->
        if not _.isObject options
          options =
            howNext: arguments[1]
            cb:      arguments[2]
        parser.parsePartial s, options


factory = (options) ->
  new Wson options

factory.Wson = Wson
factory.ParseError = errors.ParseError
factory.StringifyError = errors.StringifyError

module.exports = factory
