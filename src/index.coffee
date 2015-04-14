'use strict'

assert = require 'assert'
_ = require 'lodash'

mustRegExpQuote = ((chars) ->
  o = {}
  for c in chars
    o[c] = true
  o
)('-\\()+*.?[]^$')

quoteRegExp = (char) ->
  if mustRegExpQuote[char]
    '\\' + char
  else
    char


class Stage

  constructor: (@machine, @parent) ->
    @done = false
    @state = 'start'
    @init()

  init: ->

  next: ->  
    machine = @machine
    handlers = @handlers[@state]
    if machine.term
      handler = handlers[machine.part]
      if not handler
        handler = handlers.terminal
    else  
      handler = handlers.text
    # console.log "%s.next part='%s'", @, machine.part
    if not handler
      @machine.throwError @
    handler.call @

   pop: ->
     parent = @parent
     # console.log 'pop @=%s, parent=%s', @, parent
     if not parent
       @machine.throwError @
     parent.putValue @result
     parent

   toString: ->
     "#{@name}(state=#{@state}, result=#{JSON.stringify(@result)})"


class ValueStage extends Stage

  name: 'ValueStage'

  putValue: (value) ->
    @result = value
    @state = 'end'

  handlers:
    start:
      text: ->
        @result = @machine.tson.unquote @machine.part
        @machine.next()
        @state = 'end'
        @
      '#': -> 
        @machine.next()
        @state = 'literal'
        @
      '[': ->
        @machine.next()
        new ArrayStage @machine, @
      '{': ->
        @machine.next()
        new ObjectStage @machine, @
    literal:
      text: ->
        part = @machine.part
        @machine.next()
        switch part
          when 't'
            @result = true
          when 'f'
            @result = false
          when 'n'
            @result = null
          when 'u'
          else
            @result = Number part
            if _.isNaN @result
              @throwError @
        @state = 'end'
        @
      terminal: ->
        @result = ''
        @state = 'end'
        @
    end:
      end: ->
        @done = true
        @
      terminal: ->
        @pop()


class ArrayStage extends Stage

  name: 'ArrayStage'

  init: ->
    @result = []

  putValue: (value) ->
    @result.push value
    @state = 'have'

  handleClose: ->
    @machine.next()
    @pop()

  handleText: ->
    @putValue @machine.tson.unquote @machine.part
    @machine.next()
    @

  handleValue: ->
    stage = new ValueStage @machine, @
    stage.next()

  handlers:
    start:
      ']': -> @handleClose()
      text: -> @handleText()
      '#': -> @handleValue()
      '[': -> @handleValue()
      '{': -> @handleValue()
    next:
      text: -> @handleText()
      '#': -> @handleValue()
      '[': -> @handleValue()
      '{': -> @handleValue()
    have:
      ']': -> @handleClose()
      '|': ->
        @machine.next()
        @state = 'next'
        @


class ObjectStage extends Stage

  name: 'ObjectStage'

  init: ->
    @result = {}

  putValue: (value) ->
    if not @key?
      @machine.throwError @
    @result[@key] = value
    @state = 'have'
    @key = null

  handleClose: ->
    @machine.next()
    @pop()

  handleKey: ->
    @key = @machine.tson.unquote @machine.part
    @result[@key] = true
    @machine.next()
    @state = 'key'
    @

  handleEmptyKey: ->
    @key = ''
    @result[@key] = true
    @machine.next()
    @state = 'key'
    @

  handleText: ->
    @putValue @machine.tson.unquote @machine.part
    @machine.next()
    @

  handleValue: ->
    stage = new ValueStage @machine, @
    stage.next()

  handlers:
    start:
      '}': -> @handleClose()
      text: -> @handleKey()
      '#': -> @handleEmptyKey()
    next:
      text: -> @handleKey()
      '#': -> @handleEmptyKey()
    key:
      '}': -> @handleClose()
      '|': ->
        @machine.next()
        @state = 'next'
        @
      ':': ->
        @machine.next()
        @state = 'colon'
        @
    colon:
      text: -> @handleText()
      '#': -> @handleValue()
      '[': -> @handleValue()
      '{': -> @handleValue()
    have:
      '}': -> @handleClose()
      '|': ->
        @machine.next()
        @state = 'next'
        @


class DeMachine

  throwError: (extra) ->
    parts = @parts
    idx = @partIdx
    part = @part
    msg = "unexpected '#{part}' in '#{parts.slice(0, idx).join('') + '^' + parts.slice(idx).join('')}'"
    if extra
      msg = "#{msg} #{extra}"
    throw new Error msg

  constructor: (@tson, @parts) ->

  next: ->
    parts = @parts
    idx = @partIdx
    # console.log "parts=#{parts}, idx=#{idx}"
    loop
      ++idx
      if idx >= parts.length
        part = 'end'
        term = true
        break
      part = parts[idx]
      term = idx % 2 == 1
      # console.log "  part=#{part}, idx=#{idx}"
      if term or part.length > 0
        break
    @partIdx = idx
    @part = part  
    @term = term  
    return

  deserialize: ->
    @partIdx = -1
    @next()
    stage = new ValueStage @
    loop
      stage = stage.next()
      if stage.done
        return stage.result


class TSON
  charOfQu:
  #qu: char
    b: '{'
    c: '}'
    a: '['
    e: ']'
    i: ':'
    n: '#'
    p: '|'
    q: '`'
  prefix: '`'  

  quote: (s) ->  
    s.replace @charRe, (char) => @prefix + @quOfChar[char]

  unquote: (s) ->  
    s.replace @quRe, (all, qu) =>
      char = @charOfQu[qu]
      assert char?, "unxpected qu: '#{qu}'"
      char

  serializeArray: (x) ->
    '[' + (_.map(x, @serialize, @).join '|') + ']'

  serializeKey: (x) ->
    if x
      @quote x
    else
      '#'

  serializeObject: (x) ->
    keys = _.keys(x).sort()
    parts = []
    for key in keys
      value = x[key]
      if value == true
        parts.push @serializeKey key
      else if value != undefined
        parts.push "#{@serializeKey key}:#{@serialize value}"
    '{' + (parts.join '|') + '}'

  serialize: (x) ->
    switch
      when x == null
        '#n'
      when x == undefined
        '#u'
      when x == true
        '#t'
      when x == false
        '#f'
      when _.isNumber x
        '#' + x.toString()
      when _.isString x
        if x.length == 0
          '#'
        else  
          @quote x
      when _.isArray x
        @serializeArray x
      when _.isObject x
        @serializeObject x
      else
        throw new Error "cannot serialize #{typeof x}: '#{x}' #{if _.isObject x then 'by ' + x.constructor.toString()}"

  deserialize: (s) ->
    assert _.isString(s), 'deserialize expects a string, got: ' + s
    parts = s.split @splitRe
    machine = new DeMachine @, parts
    machine.deserialize()


do ->    
  quOfChar = {}
  charBrick = ''
  quBrick = ''
  splitBrick = ''
  for qu, char of TSON::charOfQu
    quOfChar[char] = qu
    charBrick += quoteRegExp char
    if char != TSON::prefix
      splitBrick += quoteRegExp char 
  TSON::quOfChar = quOfChar  
  TSON::charRe = new RegExp '[' + charBrick + ']', 'gm'
  TSON::quRe = new RegExp quoteRegExp(TSON::prefix) + '(.)', 'gm'
  TSON::splitRe = new RegExp '([' + splitBrick + '])'


factory = (options) ->
  new TSON options

factory.TSON = TSON

module.exports = factory
