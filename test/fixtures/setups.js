import * as extdefs from './extdefs';

let connectors = {
  Point: {
    by: extdefs.Point,
    split(p) { return p.__wsonsplit__(); },
    precreate() { return Object.create(extdefs.Point.prototype); },
    postcreate(obj, args) { return extdefs.Point.apply(obj, args); }
  },
  Polygon: {
    by: extdefs.Polygon,
    split(p) { return p.points; },
    create(points) { return new extdefs.Polygon(points); },
    hasCreate: true
  },
  Foo: {
    by: extdefs.Foo,
    split(foo) { return [foo.y, foo.x]; },
    precreate() { return Object.create(extdefs.Foo.prototype); },
    postcreate(foo, args) {
      return extdefs.Foo.call(foo, args[1], args[0]);
    }
  }
};

export default [
  {name: 'WSON-js', options: {useAddon: false, connectors: connectors}},
  {name: 'WSON-addon', options: {useAddon: true, connectors: connectors}}
];

