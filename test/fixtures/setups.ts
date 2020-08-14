import { Foo, Point, Polygon, Role } from "./extdefs"
import addon from "wson-addon"

const connectors = {
  Point,
  Polygon: {
    by: Polygon,
    split(p: Polygon) { return p.points },
    create(points: Point[]) { return new Polygon(points) },
  },
  Foo: {
    by: Foo,
    split(foo: Foo) { return [foo.y, foo.x] },
    postcreate(obj: Foo, args: any[]) {
      obj.y = args[0]
      obj.x = args[1]
    },
  },
  Role,
}

export default [
  {name: "WSON-js", options: {addon, useAddon: false, connectors}},
  {name: "WSON-addon", options: {addon, useAddon: true, connectors}},
]
