'use strict'

_ = require 'lodash'
transcribe = require './transcribe'
errors = require './errors'

class Stringifier

  constructor: (options) ->
    options or= {}
    @connectors = options.connectors


  getBackref: (x, haves, haverefCb) ->
    for have, idx in haves
      if have is x
        return haves.length - idx - 1
    if haverefCb?
      idx = haverefCb x
      if idx?
        return haves.length + idx

  findConnector: (x) ->
    # console.log 'find connectors:', @connectors
    constr = x.constructor
    if @connectors and constr? and constr != Object
      for name, connector of @connectors
        # console.log 'find', connector, x
        if connector.by == constr
          return connector

  stringifyArray: (x, haves, haverefCb) ->
    haves.push x
    result = '['
    first = true
    for elem in x
      if first
        first = false
      else
        result += '|'
      result += @stringify elem, haves, haverefCb
    haves.pop()
    result + ']'

  stringifyKey: (x) ->
    if x
      transcribe.escape x
    else
      '#'

  stringifyObject: (x, haves, haverefCb) ->
    connector = @findConnector x
    if connector
      # console.log 'x=', x, 'con=', connector
      return @stringifyConnector connector, x, haves, haverefCb
    haves.push x
    keys = _.keys(x).sort()
    result = '{'
    first = true
    for key in keys
      if first
        first = false
      else
        result += '|'
      value = x[key]
      result += @stringifyKey key
      if value != true
        result += ':'
        result += @stringify value, haves, haverefCb
    haves.pop()
    result + '}'

  stringifyConnector: (connector, x, haves, haverefCb) ->
    haves.push x
    result = '[:' + transcribe.escape(connector.name)
    args = connector.split x
    for elem in args
      result += '|'
      result += @stringify elem, haves, haverefCb
    haves.pop()
    result + ']'

  stringify: (x, haves, haverefCb) ->
    haves or= []
    if x == null
      '#n'
    else
      switch typeof x
        when 'undefined'
          '#u'
        when 'boolean'
          if x
            '#t'
          else
            '#f'
        when 'number'
          '#' + x.toString()
        when 'string'
          if x.length == 0
            '#'
          else
            transcribe.escape x
        else
          backref = @getBackref x, haves, haverefCb
          if backref?
            '|' + backref
          else if _.isArray x
            @stringifyArray x, haves, haverefCb
          else if _.isObject x
            if x instanceof Date
              '#d' + x.valueOf().toString()
            else
              @stringifyObject x, haves, haverefCb
          else
            throw new errors.StringifyError x

# Stringifier.norm = normConnectors
module.exports = Stringifier

