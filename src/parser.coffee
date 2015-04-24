'use strict'

assert = require 'assert'
_ = require 'lodash'
transcribe = require './transcribe'


class Source

  constructor: (s) ->
    @parts = s.split transcribe.splitRe
    @nextIdx = 0
    @next()

  next: ->
    parts = @parts
    idx = @nextIdx
    loop
      if idx >= parts.length
        part = 'end'
        isText = false
        break
      isText = idx % 2 == 0
      part = parts[idx++]
      if not isText or part.length > 0
        break
    @nextIdx = idx
    @part = part
    @isText = isText
    return


class State

  constructor: (@source) ->

  throwError: (cause) ->
    badIdx = @source.nextIdx
    if badIdx > 0
      --badIdx
    cause or= "unexpected '#{@source.part}'"
    msg = "#{cause} in '#{@source.parts.slice(0, badIdx).join('') + '^' + @source.parts.slice(badIdx).join('')}'"
    throw new Error msg

  next: ->
    @source.next()

  scan: ->
    while @stage
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
      @value = transcribe.unescape @source.part
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
      @value.push transcribe.unescape @source.part
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
      @key = transcribe.unescape @source.part
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
      @value[@key] = transcribe.unescape @source.part
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

  getLiteral: ->
    if not @source.isText
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
    if @source.isText or @source.part != 'end'
      # console.log 'ERROR: source=', @source
      @throwError "unexpected extra text"
    @value


class Parser

  parse: (s) ->
    assert typeof s == 'string', 'parse expects a string, got: ' + s
    source = new Source s
    state = new State source
    state.getValue()


factory = () ->
  new Parser()
factory.Parser = Parser

module.exports = factory

