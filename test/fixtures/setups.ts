import addon from 'wson-addon';
import { Foo, FooArgs, Point, Polygon, Role } from './extdefs';
import { WsonOptions } from '../../src/options';

const connectors = {
  Point,
  Polygon: {
    by: Polygon,
    split(p: Polygon): Point[] {
      return p.points;
    },
    create(points: Point[]): Polygon {
      return new Polygon(points);
    },
  },
  Foo: {
    by: Foo,
    split(foo: Foo): FooArgs {
      return [foo.y, foo.x];
    },
    postcreate(obj: Foo, args: FooArgs): void {
      obj.y = args[0];
      obj.x = args[1];
    },
  },
  Role,
};

export const setups: { name: string; options: WsonOptions }[] = [
  { name: 'WSON-js', options: { addon, useAddon: false, connectors } },
  { name: 'WSON-addon', options: { addon, useAddon: true, connectors } },
];
