'use strict'

_ = require 'lodash'
transcribe = require './transcribe'
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
    connectors  
          

class Stringifier

  constructor: (options) ->
    options or= {}
    @connectors = normConnectors options.connectors


  getBackref: (x, haves) ->
    for have, idx in haves
      if have is x
        return haves.length - idx - 1 
  
  findConnector: (x) ->
    # console.log 'find connectors:', @connectors
    constr = x.constructor
    if @connectors and constr? and constr != Object
      for name, connector of @connectors
        # console.log 'find', connector, x
        if connector.by == constr
          return connector

  stringifyArray: (x, haves) ->
    haves.push x
    result = '['
    first = true
    for elem in x
      if first
        first = false
      else
        result += '|'
      result += @stringify elem, haves
    haves.pop()
    result + ']'

  stringifyKey: (x) ->
    if x
      transcribe.escape x
    else
      '#'

  stringifyObject: (x, haves) ->
    connector = @findConnector x
    if connector
      # console.log 'x=', x, 'con=', connector
      return @stringifyConnector connector, x, haves
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
        result += @stringify value, haves
    haves.pop()
    result + '}'

  stringifyConnector: (connector, x, haves) ->
    haves.push x
    result = '[:' + transcribe.escape(connector.name) + '|'
    args = connector.split x
    first = true
    for elem in args
      if first
        first = false
      else
        result += '|'
      result += @stringify elem, haves
    haves.pop()
    result + ']'

  stringify: (x, haves) ->
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
          backref = @getBackref x, haves
          if backref?
            '|' + backref
          else if _.isArray x
            @stringifyArray x, haves
          else if _.isObject x
            if x instanceof Date
              '#d' + x.valueOf().toString()
            else 
              @stringifyObject x, haves
          else
            throw new errors.StringifyError x

# Stringifier.norm = normConnectors
module.exports = Stringifier

