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

const sj = JSON.stringify(x)
const st = wsonJs.stringify(x)

suite.add("JSON.parse", () => JSON.parse(sj))
suite.add("WSON-js.parse", () => wsonJs.parse(st))
suite.add("WSON-addon.parse", () => wsonAddon.parse(st))

suite.on("cycle", (event: any) => {
  console.log(String(event.target))
})

suite.run({async: true})
