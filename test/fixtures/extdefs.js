class Point {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }
  __wsonsplit__() { return [this.x, this.y]; }
}


class Polygon {
  constructor(points) {
    this.points = points || [];
  }
}

class Foo {
  constructor(x, y) {
    this.x = x;
    this.y = y;
  }
}


export { Point };
export { Polygon };
export { Foo };


