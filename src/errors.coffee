'use strict'

class WsonError extends Error
  constructor: ->
    if Error.captureStackTrace
      Error.captureStackTrace @, @constructor


class ParseError extends WsonError
  name: 'ParseError'
  constructor: (@s, @pos, @cause) ->
    super()
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
    super()
    try
      xStr = JSON.stringify @x
    catch
      xStr = String x

    @message = "cannot stringify '#{xStr}' (type=#{typeof @x})#{if cause then ' ' + cause else ''}"


exports.ParseError = ParseError
exports.StringifyError = StringifyError


