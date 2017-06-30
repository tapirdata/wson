// tslint:disable:max-classes-per-file

export class Point {

  public x?: number
  public y?: number

  constructor(x: number = 0, y: number = 0) {
    this.__wsonpostcreate__([x, y])
  }

  public __wsonsplit__() {
    return [this.x, this.y]
  }

  public __wsonpostcreate__(args: number[]) {
    [this.x, this.y] = args
  }

}

export class Polygon {

  public points: Point[]

  constructor(points?: Point[]) {
    this.points = points || []
  }
}

export class Foo {

  public x: any
  public y: any

  constructor(x: any, y: any) {
    this.x = x
    this.y = y
  }
}

export class Role {

  public name: string
  public isAdmin: boolean

  constructor(name: string, isAdmin: boolean = false) {
    this.name = name
    this.isAdmin = isAdmin
  }

  public __wsonsplit__() {
    return [this.name, this.isAdmin]
  }

}
