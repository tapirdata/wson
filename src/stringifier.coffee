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

  connectorOfValue: (x) ->
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
    connector = @connectorOfValue x
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

  getTypeid: (x) ->
    if x == null
      2
    else
      switch typeof x
        when 'undefined'
          1
        when 'boolean'
          4
        when 'number'
          8
        when 'string'
          20
        when 'object'
          if x instanceof Date
            16
          else if _.isArray x
            24
          else
            32
        else
          0
          

  stringify: (x, haves, haverefCb) ->
    haves or= []
    typeid = @getTypeid x
    switch typeid
      when 0
        throw new errors.StringifyError x
      when 1
        '#u'
      when 2
        '#n'
      when 4
        if x then '#t' else '#f'
      when 8
        '#' + x.toString()
      when 16
        '#d' + x.valueOf().toString()
      when 20
        if x.length == 0
          '#'
        else
          transcribe.escape x
      else
        backref = @getBackref x, haves, haverefCb
        if backref?
          '|' + backref
        else if typeid == 24
          @stringifyArray x, haves, haverefCb
        else
          @stringifyObject x, haves, haverefCb

# Stringifier.norm = normConnectors
module.exports = Stringifier

