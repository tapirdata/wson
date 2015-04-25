'use strict'

class TsonError extends Error

class ParseError extends TsonError
  name: 'ParseError'
  constructor: (@s, @pos, cause) ->
    if not @pos?
      @pos = @s.length
    if !cause
      if @pos >= @s.length
        cause = "unexpected end"
      else  
        cause = "unexpected '#{@s[@pos]}'"
    @message = "#{cause} at '#{@s.slice 0, @pos}^#{@s.slice @pos}'"


class StringifyError extends TsonError
  name: 'StringifyError'
  constructor: (@x, cause) ->
    try
      xStr = JSON.stringify @x
    catch  
      xStr = String x  

    @message = "cannot stringify '#{xStr}' (type=#{typeof @x})#{if cause then ' ' + cause else ''}"


exports.ParseError = ParseError
exports.StringifyError = StringifyError


