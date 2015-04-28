'use strict'

class Point
  constructor: (@x, @y) ->
  __wsonsplit__: () -> [@x, @y]


class Rect
  constructor: (@ul, @lr) ->
  __wsonsplit__: () -> [@ul, @lr]


exports.Point = Point
exports.Rect = Rect

