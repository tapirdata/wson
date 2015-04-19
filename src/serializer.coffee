'use strict'

_ = require 'lodash'
pp = require './pp'

class Serializer 

  serializeArray: (x) ->
    result = '['
    first = true
    for elem in x
      if first
        first = false
      else
        result += '|'
      result += @serializeValue elem
    result + ']'

  serializeKey: (x) ->
    if x
      pp.escape x
    else
      '#'

  serializeObject: (x) ->
    keys = _.keys(x).sort()
    result = '{'
    first = true
    for key in keys
      if first
        first = false
      else
        result += '|'
      value = x[key]
      result += @serializeKey key
      if value != true
        result += ':' 
        result += @serializeValue value
    result + '}'

  serializeValue: (x) ->
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
            pp.escape x
        else    
          if _.isArray x
            @serializeArray x
          else if _.isObject x
            @serializeObject x
          else
            throw new Error "cannot stringify #{typeof x}: '#{x}' #{if _.isObject x then 'by ' + x.constructor.toString()}"



factory = () ->
  new Serializer()
factory.Serializer = Serializer  

module.exports = factory

