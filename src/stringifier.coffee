'use strict'

_ = require 'lodash'
transcribe = require './transcribe'

class Stringifier 

  stringifyArray: (x) ->
    result = '['
    first = true
    for elem in x
      if first
        first = false
      else
        result += '|'
      result += @stringify elem
    result + ']'

  stringifyKey: (x) ->
    if x
      transcribe.escape x
    else
      '#'

  stringifyObject: (x) ->
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
        result += @stringify value
    result + '}'

  stringify: (x) ->
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
          if _.isArray x
            @stringifyArray x
          else if _.isObject x
            @stringifyObject x
          else
            throw new Error "cannot stringify #{typeof x}: '#{x}' #{if _.isObject x then 'by ' + x.constructor.toString()}"



factory = () ->
  new Stringifier()
factory.Stringifier = Stringifier  

module.exports = factory

