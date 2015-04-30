'use strict'

assert = require 'assert'
_ = require 'lodash'
transcribe = require './transcribe'
errors = require './errors'

class Source

  constructor: (@stringifier, s) ->
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

  constructor: (@source, @parent) ->
    @isBackreffed = false

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
      @value = []
      @next()
      @stage = null
    ':': ->
      @next()
      @stage = @stageCustomStart
    'default': ->
      @value = []
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
      state = new State @source, @
      state.fetchArray()
      @value.push state.value
      @stage = @stageArrayHave
    '{': ->
      @next()
      state = new State @source, @
      state.fetchObject()
      @value.push state.value
      @stage = @stageArrayHave
    '|': ->
      @next()
      @value.push @getBackreffed()
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
      @value = {}
      @next()
      @stage = null
    'default': ->
      @value = {}
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
      state = new State @source, @
      state.fetchArray()
      @value[@key] = state.value
      @stage = @stageObjectHaveValue
    '{': ->
      @next()
      state = new State @source, @
      state.fetchObject()
      @value[@key] = state.value
      @stage = @stageObjectHaveValue
    '|': ->
      @next()
      @value[@key] = @getBackreffed()
      @stage = @stageObjectHaveValue

  stageObjectHaveValue:
    '|': ->
      @next()
      @stage = @stageObjectNext
    '}': ->
      @next()
      @stage = null

  stageCustomStart:
    text: ->
      name = @getText()
      connector = @source.stringifier.getConnector name
      # console.log 'name=%s', name, connector
      if not connector
        @throwError "no connector for '#{name}'"
      @next()
      if connector.hasCreate
        @vetoBackref = true
      else
        @value = connector.precreate()
      @connector = connector
      @args = []
      @stage = @stageCustomHave

  stageCustomNext:
    text: ->
      @args.push @getText()
      @next()
      @stage = @stageCustomHave
    '#': ->
      @next()
      @args.push @getLiteral()
      @stage = @stageCustomHave
    '[': ->
      @next()
      state = new State @source, @
      state.fetchArray()
      @args.push state.value
      @stage = @stageCustomHave
    '{': ->
      @next()
      state = new State @source, @
      state.fetchObject()
      @args.push state.value
      @stage = @stageCustomHave
    '|': ->
      @next()
      @args.push @getBackreffed()
      @stage = @stageCustomHave

  stageCustomHave:
    '|': ->
      @next()
      @stage = @stageCustomNext
    ']': ->
      connector = @connector
      # console.log 'end ', connector, @value
      if connector.hasCreate
        @value = connector.create @args
      else
        newValue = connector.postcreate @value, @args
        # console.log '.end ', connector, @value
        if newValue != @value
          if @isBackreffed
            @throwError "backreffed value is replaced by postcreate"
          @value = newValue
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


  invalidLiteral: (part) ->
    @throwError "unexpected literal '#{part}'"

  invalidBackref: (part, offset=0) ->
    @throwError "unexpected backref '#{part}'", offset


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
          if part[0] == 'd'
            value = Number part.slice 1
            if _.isNaN value
              @invalidLiteral part
            value = new Date(value)
          else
            value = Number part
            if _.isNaN value
              @invalidLiteral part
      @next()
    value

  getBackreffed: ->
    part = @source.part
    if @source.isEnd or not @source.isText
      @invalidBackref part
    refNum = Number part
    unless refNum >= 0
      @invalidBackref part
    state = @
    while refNum > 0
      state = state.parent
      unless state
        @invalidBackref part
      --refNum
    if state.vetoBackref
      @invalidBackref part
    @next()
    state.isBackreffed = true
    state.value

  fetchValue: ->
    @stage = @stageValueStart
    @scan()

  fetchArray: ->
    @stage = @stageArrayStart
    @scan()

  fetchObject: ->
    @stage = @stageObjectStart
    @scan()

  getValue: ->
    @fetchValue()
    if not @source.isEnd
      # console.log 'ERROR: source=', @source
      @throwError() # "unexpected extra text"
    @value



class Parser

  constructor: (options) ->
    options or= {}
    @connectors = options.connectors

  parse: (s) ->
    assert typeof s == 'string', 'parse expects a string, got: ' + s
    source = new Source @, s
    state = new State source
    state.getValue()

  getConnector: (name) ->
    if @connectors
      connector = @connectors[name]
    connector


# Parser.norm = normConnectors
module.exports = Parser

