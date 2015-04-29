'use strict'

_ = require 'lodash'

try
  addon = require 'wson-addon'
catch
  addon = null

errors = require './errors'


# normalizeExt = (ext) ->
#   ext = _.clone ext
#   if not _.isFunction ext.splitter
#     ext.split = (x) -> x.__wsonsplit__()
#   if not _.isFunction ext.factory
#     ext.factory = (args...) ->
#       obj = Object.create ext.constr
#       ret = ext.constr.apply obj, args
#       if Object(ret) == ret then ret else obj
#   ext  


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

    if useAddon
      stringifier = new addon.Stringifier errors.StringifyError options
      parser = new addon.Parser errors.ParseError options

      @escape = (x) -> stringifier.escape x
      @unescape = (x) -> parser.unescape x
      @stringify = (x) -> stringifier.stringify x
      @parse = (x) -> parser.parse x

    else
      transcribe = require './transcribe'
      Stringifier = require './stringifier'
      Parser = require './parser'
      stringifier = new Stringifier options
      parser = new Parser options

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
