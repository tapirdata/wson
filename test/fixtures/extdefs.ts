export type PointArgs = [number | undefined, number | undefined];
export class Point {
  public x?: number;
  public y?: number;

  constructor(...args: PointArgs) {
    this.__wsonpostcreate__(args);
  }

  public __wsonsplit__(): PointArgs {
    return [this.x, this.y];
  }

  public __wsonpostcreate__(args: PointArgs): void {
    [this.x, this.y] = args;
  }
}

export class Polygon {
  public points: Point[];

  constructor(points?: Point[]) {
    this.points = points || [];
  }
}

export type FooValue = unknown;
export type FooArgs = [FooValue, FooValue];

export class Foo {
  constructor(public x: FooValue, public y: FooValue) {}
}

export type RoleArgs = [string, boolean];

export class Role {
  public name: string;
  public isAdmin: boolean;

  constructor(name: string, isAdmin = false) {
    this.name = name;
    this.isAdmin = isAdmin;
  }

  public __wsonsplit__(): RoleArgs {
    return [this.name, this.isAdmin];
  }
}
