// tslint:disable:max-classes-per-file

class Point {

  public x?: number
  public y?: number

  constructor(...args: number[]) {
    this.initialize(...args)
  }

  public initialize(x?: number, y?: number) {
    this.x = x
    this.y = y
  }

  public __wsonsplit__() { return [this.x, this.y] }
}

class Polygon {

  public points: Point[]

  constructor(points?: Point[]) {
    this.points = points || []
  }
}

class Foo {

  public x: any
  public y: any

  constructor(x: any, y: any) {
    this.x = x
    this.y = y
  }
}

export { Foo, Point, Polygon }
