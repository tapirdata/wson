'use strict'

_ = require 'lodash'
transcribe = require './transcribe'
errors = require './errors'

class Stringifier

  getBackref: (x, haves) ->
    for have, idx in haves
      if have is x
        return haves.length - idx - 1 


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


module.exports = Stringifier

