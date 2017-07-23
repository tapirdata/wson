import Benchmark = require("benchmark")
import wsonFactory from "../src"

const wsonJs = wsonFactory({useAddon: false})
const wsonAddon = wsonFactory({useAddon: true})

const suite = new Benchmark.Suite()

const x = {
  a: 42,
  b: "foobar",
  c: [1, 4, 9, 16],
  rest: {
    x: true,
    y: false,
    z: ["foo", "bar", null, "baz"],
  },
}

// x = ['foo', 'bar', 123, true, ['a', 'b']]
// x = {a: true, b: true, c:true, d: true}

suite.add("JSON.stringify", () => JSON.stringify(x))
suite.add("WSON-js.stringify", () => wsonJs.stringify(x))
suite.add("WSON-addon.stringify", () => wsonAddon.stringify(x))

suite.on("cycle", (event: any) => {
  console.log(String(event.target))
})

suite.run({async: true})
