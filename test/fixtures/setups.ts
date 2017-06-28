import { Foo, Point, Polygon } from "./extdefs"

const connectors = {
  Point: {
    by: Point,
    split(p: Point) { return p.__wsonsplit__() },
    precreate() { return Object.create(Point.prototype) },
    postcreate(obj: Point, args: any[]) { obj.initialize(...args) },
  },
  Polygon: {
    by: Polygon,
    split(p: Polygon) { return p.points },
    create(points: Point[]) { return new Polygon(points) },
    hasCreate: true,
  },
  Foo: {
    by: Foo,
    split(foo: Foo) { return [foo.y, foo.x] },
    precreate() { return Object.create(Foo.prototype) },
    postcreate(obj: Foo, args: any[]) { obj.y = args[0]; obj.x = args[1]; return obj},
  },
}

export default [
  {name: "WSON-js", options: {useAddon: false, connectors}},
  {name: "WSON-addon", options: {useAddon: true, connectors}},
]
