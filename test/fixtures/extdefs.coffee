'use strict'

class Point
  constructor: (@x, @y) ->
  __wsonsplit__: () -> [@x, @y]


class Polygon
  constructor: (@points=[]) ->

exports.Point = Point
exports.Polygon = Polygon

