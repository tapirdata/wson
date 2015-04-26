'use strict'

class WsonError extends Error

class ParseError extends WsonError
  name: 'ParseError'
  constructor: (@s, @pos, @cause) ->
    # console.log 'ParseError "%s" pos=%s cause="%s"', @s, @pos, @cause
    if not @pos?
      @pos = @s.length
    if not @cause
      if @pos >= @s.length
        char = "end"
      else  
        char = "'#{@s[@pos]}'"
      @cause = "unexpected #{char}"
    @message = "#{@cause} at '#{@s.slice 0, @pos}^#{@s.slice @pos}'"


class StringifyError extends WsonError
  name: 'StringifyError'
  constructor: (@x, cause) ->
    try
      xStr = JSON.stringify @x
    catch  
      xStr = String x  

    @message = "cannot stringify '#{xStr}' (type=#{typeof @x})#{if cause then ' ' + cause else ''}"


exports.ParseError = ParseError
exports.StringifyError = StringifyError


