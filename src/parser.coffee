'use strict'

assert = require 'assert'
_ = require 'lodash'
grammar = require './grammar'

regExpQuoteSet = do (chars='-\\()+*.?[]^$') ->
  o = {}
  for c in chars
    o[c] = true
  o

class Source

  constructor: (@parser, s) ->
    assert typeof s == 'string', 'parse expects a string, got: ' + s
    @parts = s.split @parser.splitRe
    @partIdx = -1
    @next()

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

  throwError: (extra) ->
    parts = @parts
    idx = @partIdx
    part = @part
    msg = "unexpected '#{part}' in '#{parts.slice(0, idx).join('') + '^' + parts.slice(idx).join('')}'"
    if extra
      msg = "#{msg} #{extra}"
    throw new Error msg


class Stage

  constructor: (@source, @parent) ->
    @done = false
    @state = 'start'
    @init()

  init: ->

  next: ->  
    source = @source
    handlers = @handlers[@state]
    if source.term
      handler = handlers[source.part]
      if not handler
        handler = handlers.terminal
    else  
      handler = handlers.text
    # console.log "%s.next part='%s'", @, source.part
    if not handler
      @source.throwError @
    handler.call @

   pop: ->
     parent = @parent
     # console.log 'pop @=%s, parent=%s', @, parent
     if not parent
       @source.throwError @
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
        @result = @source.parser.unescape @source.part
        @source.next()
        @state = 'end'
        @
      '#': -> 
        @source.next()
        @state = 'literal'
        @
      '[': ->
        @source.next()
        new ArrayStage @source, @
      '{': ->
        @source.next()
        new ObjectStage @source, @
    literal:
      text: ->
        part = @source.part
        @source.next()
        @result = @source.parser.literal part
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
    @source.next()
    @pop()

  handleText: ->
    @putValue @source.parser.unescape @source.part
    @source.next()
    @

  handleValue: ->
    stage = new ValueStage @source, @
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
        @source.next()
        @state = 'next'
        @


class ObjectStage extends Stage

  name: 'ObjectStage'

  init: ->
    @result = {}

  putValue: (value) ->
    if not @key?
      @source.throwError @
    @result[@key] = value
    @state = 'have'
    @key = null

  handleClose: ->
    @source.next()
    @pop()

  handleKey: ->
    @key = @source.parser.unescape @source.part
    @result[@key] = true
    @source.next()
    @state = 'key'
    @

  handleEmptyKey: ->
    @key = ''
    @result[@key] = true
    @source.next()
    @state = 'key'
    @

  handleText: ->
    @putValue @source.parser.unescape @source.part
    @source.next()
    @

  handleValue: ->
    stage = new ValueStage @source, @
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
        @source.next()
        @state = 'next'
        @
      ':': ->
        @source.next()
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
        @source.next()
        @state = 'next'
        @


class Parser

  @quoteRegExp: (char) ->
    if regExpQuoteSet[char]
      '\\' + char
    else
      char

  charOfXar:
  #xar: char
    b: '{'
    c: '}'
    a: '['
    e: ']'
    i: ':'
    n: '#'
    p: '|'
    q: '`'
  prefix: '`'  

  unescape: (s) ->
    s.replace @xarRe, (all, xar) =>
      char = @charOfXar[xar]
      assert char?, "unxpected xar: '#{xar}'"
      char

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

  myParse: (s) ->
    source = new Source @, s
    stage = new ValueStage source
    loop
      stage = stage.next()
      if stage.done
        return stage.result

  pegParse: (s) ->
    options = 
      unescape: (s) => @unescape s
      literal: (s) => @literal s
    grammar.parse s, options  

  parse: (s) ->
    @myParse s

do ->    
  splitBrick = ''
  for xar, char of Parser::charOfXar
    if char != Parser::prefix
      splitBrick += Parser.quoteRegExp char 
  Parser::xarRe = new RegExp Parser.quoteRegExp(Parser::prefix) + '(.)', 'gm'
  Parser::splitRe = new RegExp '([' + splitBrick + '])'


factory = () ->
  new Parser()
factory.Parser = Parser  

module.exports = factory

