extdefs = require './extdefs'

# connectors =
#   Point:
#     by: extdefs.Point
#     create: ->
#     split: ->

connectors =
  Point: extdefs.Point
  Polygon:
    by: extdefs.Polygon
    create: (points) -> new extdefs.Polygon points
    split: (p) -> p.points

module.exports = [
  {name: 'WSON-js', options: {useAddon: false, connectors: connectors}}
  {name: 'WSON-addon', options: {useAddon: true, connectors: connectors}}
]

