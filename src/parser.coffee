'use strict'

assert = require 'assert'
_ = require 'lodash'
transcribe = require './transcribe'
errors = require './errors'

class Source

  constructor: (@parser, @s) ->
    @sLen = @s.length
    @rest = @s
    # @parts = @s.split transcribe.splitRe
    # @partIdx = null
    @splitRe = new RegExp transcribe.splitBrick, 'g'
    @pos = null
    @isEnd = false
    @next()

  # nextX: ->
  #   while not @isEnd
  #     if @partIdx?
  #       @partIdx++
  #       @pos += @part.length
  #     else  
  #       @partIdx = 0
  #       @pos = 0
  #     if @partIdx >= @parts.length
  #       @isEnd = true
  #     else  
  #       @part = @parts[@partIdx]
  #       @isText = @partIdx % 2 == 0
  #     if @part.length > 0
  #       break
  #   return

  next: ->
    if @pos?
      @pos += @part.length
    else
      @pos = 0

    if @pos >= @sLen
      @isEnd = true
    else
      if @nt?
        @part = @nt
        @isText = false
        @nt = null
      else
        m = @splitRe.exec @rest
        restPos = @pos + @rest.length - @sLen
        # console.log 'next rest=%s, m=%j restPos=%s', @rest, m, restPos
        if m?
          if m.index > restPos
            partLen = m.index - restPos
            @isText = true
            @part = @rest.slice restPos, restPos + partLen
            @nt = m[0]
          else
            @isText = false
            @part = m[0]
        else    
          @part = @rest.slice restPos
          @isText = true
    # console.log 'next.. source=%j', @
    return  


  advance: (n) ->
    # console.log 'advance', n, @isEnd
    @rest = @s.slice @pos + n
    @splitRe = new RegExp transcribe.splitBrick, 'g'
    @nt = null
    @part = ''
    @pos += n
    @next()
    # console.log 'advance.. source=%j', @


class State

  constructor: (@source, @parent, @allowPartial) ->
    @isBackreffed = false

  throwError: (cause, offset=0) ->
    throw new errors.ParseError @source.s, @source.pos + offset, cause

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
    'default': ->
      if @allowPartial
        @isPartial = true
        @stage = null
      else
        @throwError()


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
      connector = @source.parser.getConnector name
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
        # console.log '.end ', connector, @value, newValue
        if _.isObject newValue
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

  parsePartial: (s, nextRaw, cb) ->
    assert typeof s == 'string', 'parse expects a string, got: ' + s
    source = new Source @, s
    while not source.isEnd
      pos = source.pos
      if _.isArray nextRaw
        source.advance nextRaw[1]
        if source.isEnd
          break
        nextRaw = nextRaw[0]
      if nextRaw == true
        nextRaw = cb source.isText, source.part, pos
        source.next()
      else if nextRaw == false
        state = new State source, null, true
        state.fetchValue()
        if state.isPartial
          nextRaw = cb false, source.part, pos
          source.next()
        else
          nextRaw = cb true, state.value, pos
      else
        return false
    return true

  getConnector: (name) ->
    if @connectors
      connector = @connectors[name]
    connector

Parser.Source = Source
module.exports = Parser

