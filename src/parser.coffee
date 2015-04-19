'use strict'

assert = require 'assert'
_ = require 'lodash'
pp = require './pp'


class Source

  constructor: (s) ->
    assert typeof s == 'string', 'parse expects a string, got: ' + s
    @parts = s.split pp.splitRe
    @partIdx = 0
    @next()

  next: ->
    parts = @parts
    idx = @partIdx
    loop
      if idx >= parts.length
        part = 'end'
        term = false
        break
      term = idx % 2 == 0
      part = parts[idx++]
      if not term or part.length > 0
        break
    @partIdx = idx
    @part = part  
    @term = term  
    return

  literal: (s) ->
    switch s
      when 't'
        true
      when 'f'
        false
      when 'n'
        null
      when 'u'
      else
        result = Number s
        if _.isNaN result
          throw new Error "unexpected literal '#{s}'"
        result      

  throwError: (extra) ->
    parts = @parts
    idx = @partIdx
    part = @part
    msg = "unexpected '#{part}' in '#{parts.slice(0, idx).join('') + '^' + parts.slice(idx).join('')}'"
    if extra
      msg = "#{msg} #{extra}"
    throw new Error msg


class State

  constructor: (@source, @stage, @value, @parent) ->

  next: ->  
    source = @source
    stage = @stage
    if source.term
      handler = stage.text
    else  
      handler = stage[source.part]
      if not handler
        handler = stage.default
    if not handler
      @source.throwError @
    handler.call @

  pop: ->
    parent = @parent
    if not parent
      @source.throwError @
    parent.stage.putValue.call parent, @value

  putArrayValue: (x) ->   
    @value.push x
    @stage = stages.arrayHave
    @

  putObjectValue: (x) ->   
    @value[@key] = x
    @stage = stages.objectHave
    @

  arrayText: ->
    @value.push pp.unescape @source.part
    @source.next()
    @stage = stages.arrayHave
    @

  arrayValue: ->
    new State @source, stages.valueStart, undefined, @

  arrayNext: ->
    @source.next()
    @stage = stages.arrayNext
    @

  arrayClose: ->
    @source.next()
    @pop()

  objectClose: ->
    @source.next()
    @pop()

  objectKey: ->
    @key = pp.unescape @source.part
    @value[@key] = true
    @source.next()
    @stage = stages.objectKey
    @

  objectEmptyKey: ->
    @key = ''
    @value[@key] = true
    @source.next()
    @stage = stages.objectKey
    @

  objectColon: ->
    @source.next()
    @stage = stages.objectColon
    @

  objectText: ->
    @value[@key] = pp.unescape @source.part
    @source.next()
    @stage = stages.objectHave
    @

  objectValue: ->
    new State @source, stages.valueStart, undefined, @

  objectNext: ->
    @source.next()
    @stage = stages.objectNext
    @


stages = 
  valueStart:
    text: ->
      @value = pp.unescape @source.part
      @source.next()
      @stage = stages.valueEnd
      @
    '#': -> 
      @source.next()
      @stage = stages.valueLiteral
      @
    '[': ->
      @source.next()
      new State @source, stages.arrayStart, [], @
    '{': ->
      @source.next()
      new State @source, stages.objectStart, {}, @
    putValue: (value) ->
      @value = value
      @stage = stages.valueEnd
      @
  valueLiteral:
    text: ->
      part = @source.part
      try
        @value = @source.literal part
      catch err
        @source.throwError @
      @source.next()
      @stage = stages.valueEnd
      @
    default: ->
      @value = ''
      @stage = stages.valueEnd
      @
  valueEnd:
    end: ->
      @done = true
      @
    default: ->
      @pop()

  arrayStart:    
    text: -> @arrayText()
    '#': -> @arrayValue()
    '[': -> @arrayValue()
    '{': -> @arrayValue()
    ']': -> @arrayClose()
    putValue: (x) -> @putArrayValue(x)
  arrayNext:  
    text: -> @arrayText()
    '#': -> @arrayValue()
    '[': -> @arrayValue()
    '{': -> @arrayValue()
    putValue: (x) -> @putArrayValue(x)
  arrayHave:
    '|': -> @arrayNext()
    ']': -> @arrayClose()

  objectStart:
    text: -> @objectKey()
    '#': -> @objectEmptyKey()
    '}': -> @objectClose()
  objectNext:
    text: -> @objectKey()
    '#': -> @objectEmptyKey()
  objectKey:
    '|': -> @objectNext()
    '}': -> @objectClose()
    ':': -> @objectColon()
  objectColon:
    text: -> @objectText()
    '#': -> @objectValue()
    '[': -> @objectValue()
    '{': -> @objectValue()
    putValue: (x) -> @putObjectValue(x)
  objectHave:
    '}': -> @objectClose()
    '|': -> @objectNext()


class Parser

  parse: (s) ->
    source = new Source s
    state = new State source, stages.valueStart
    loop
      state = state.next()
      if state.done
        return state.value

  unescape: (s) ->
    unescaper.unescape s


factory = () ->
  new Parser()
factory.Parser = Parser  

module.exports = factory

###
factory.makeState = (s) ->
  source = new Source s
  new State source, stages.valueStart
###  


