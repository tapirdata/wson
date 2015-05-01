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
  Foo:
    by: extdefs.Foo
    split: (foo) -> [foo.y, foo.x]
    postcreate: (foo, args) ->
      extdefs.Foo.call foo, args[1], args[0]


module.exports = [
  {name: 'WSON-js', options: {useAddon: false, connectors: connectors}}
  {name: 'WSON-addon', options: {useAddon: true, connectors: connectors}}
]

