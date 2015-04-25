'use strict'

assert = require 'assert'
_ = require 'lodash'
transcribe = require './transcribe'
errors = require './errors'


class Source

  constructor: (s) ->
    @parts = s.split transcribe.splitRe
    @nextIdx = 0
    @isEnd = false
    @next()

  next: ->
    parts = @parts
    idx = @nextIdx
    loop
      if idx >= parts.length
        @isEnd = true
        break
      @isText = idx % 2 == 0
      part = parts[idx++]
      if not @isText or part.length > 0
        break
    @nextIdx = idx
    @part = part
    return


class State

  constructor: (@source) ->

  throwError: (cause, offset=0) ->
    # console.log 'throwError cause="%s" offset=%s source=', cause, offset, @source
    if 1 or not @source.isEnd
      pos = 0
      idx = 0
      while idx < @source.nextIdx - 1
        pos += @source.parts[idx++].length
      pos += offset  
    s = @source.parts.join ''
    throw new errors.ParseError s, pos, cause

  next: ->
    @source.next()

  scan: ->
    while @stage
      if @source.isEnd
        @throwError()
      if @source.isText
        handler = @stage.text
      else  
        handler = @stage[@source.part]
      if not handler
        handler = @stage.default
      # console.log "part='%s', stage=%j, handler=%s", @source.part, _.keys(@stage), handler
      if not handler
        @throwError()
      handler.call @
      # console.log 'stage=', @stage

  stageValueStart:
    text: ->
      @value = @getText()
      @next()
      @stage = null
    '#': ->
      @next()
      @value = @getLiteral()
      @stage = null
    '[': ->
      @next()
      @fetchArray()
      @stage = null
    '{': ->
      @next()
      @fetchObject()
      @stage = null

  stageArrayStart:
    ']': ->
      @next()
      @stage = null
    'default': ->
      @stage = @stageArrayNext

  stageArrayNext:
    text: ->
      @value.push @getText()
      @next()
      @stage = @stageArrayHave
    '#': ->
      @next()
      @value.push @getLiteral()
      @stage = @stageArrayHave
    '[': ->
      @next()
      state = new State @source
      state.fetchArray()
      @value.push state.value
      @stage = @stageArrayHave
    '{': ->
      @next()
      state = new State @source
      state.fetchObject()
      @value.push state.value
      @stage = @stageArrayHave

  stageArrayHave:
    '|': ->
      @next()
      @stage = @stageArrayNext
    ']': ->
      @next()
      @stage = null

  stageObjectStart:
    '}': ->
      @next()
      @stage = null
    'default': ->
      @stage = @stageObjectNext

  stageObjectNext:
    text: ->
      @key = @getText()
      @next()
      @stage = @stageObjectHaveKey
    '#': ->  
      @next()
      @key = ''
      @stage = @stageObjectHaveKey

  stageObjectHaveKey:
    ':': ->  
      @next()
      @stage = @stageObjectHaveColon
    '|': ->
      @next()
      @value[@key] = true
      @stage = @stageObjectNext
    '}': ->
      @next()
      @value[@key] = true
      @stage = null

  stageObjectHaveColon:
    text: ->
      @value[@key] = @getText()
      @next()
      @stage = @stageObjectHaveValue
    '#': ->
      @next()
      @value[@key] = @getLiteral()
      @stage = @stageObjectHaveValue
    '[': ->  
      @next()
      state = new State @source
      state.fetchArray()
      @value[@key] = state.value
      @stage = @stageObjectHaveValue
    '{': ->  
      @next()
      state = new State @source
      state.fetchObject()
      @value[@key] = state.value
      @stage = @stageObjectHaveValue

  stageObjectHaveValue:
    '|': ->
      @next()
      @stage = @stageObjectNext
    '}': ->
      @next()
      @stage = null


  getText: ->
    try
      transcribe.unescape @source.part
    catch err
      # console.log 'err=', err
      if err instanceof errors.ParseError
        @throwError err.cause, err.pos
      throw err

  getLiteral: ->
    if @source.isEnd or not @source.isText
      value = ''
    else  
      part = @source.part
      switch part
        when 't'
          value = true
        when 'f'
          value = false
        when 'n'
          value = null
        when 'u'
        else
          value = Number part
          if _.isNaN value
            @throwError "unexpected literal '#{part}'"
      @next()    
    value  

  fetchValue: ->
    @stage = @stageValueStart
    @scan()

  fetchArray: ->
    @stage = @stageArrayStart
    @value = []
    @scan()

  fetchObject: ->
    @stage = @stageObjectStart
    @value = {}
    @scan()

  getValue: ->
    @fetchValue()
    if not @source.isEnd
      # console.log 'ERROR: source=', @source
      @throwError() # "unexpected extra text"
    @value


class Parser

  parse: (s) ->
    assert typeof s == 'string', 'parse expects a string, got: ' + s
    source = new Source s
    state = new State source
    state.getValue()


module.exports = Parser

