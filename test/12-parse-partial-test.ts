import { expect } from "chai"

import { saveRepr } from "./fixtures/helpers"
import pairs from "./fixtures/partial-pairs"
import setups from "./fixtures/setups"
import wsonFactory from "./wsonFactory"

for (const setup of setups) {
  describe(setup.name, () => {
    const wson = wsonFactory(setup.options)

    function collectPartial(s: string | undefined, nrs: any[], backrefCb?: (refNum: number) => any) {
      const result: any[] = []
      let nrIdx = 0

      function cb(isValue: boolean, value: any, pos: number) {
        result.push(isValue)
        result.push(value)
        result.push(pos)
        return nrs[nrIdx++]
      }

      wson.parsePartial(s, {howNext: nrs[nrIdx++], cb, backrefCb})

      return result
    }

    describe("parse partial", () => {
      for (const pair of pairs) {
        if (pair.failPos != null) {
          it(`should fail to parse '${pair.s}' at ${pair.failPos}`, () => {
            let e
            try {
              collectPartial(pair.s, pair.nrs, pair.backrefCb)
            } catch (someE) {
              e = someE
            }
            expect(e.name).to.be.equal("ParseError")
            expect(e.pos).to.be.equal(pair.failPos)
          })
        } else {
          it(`should parse '${pair.s}' as ${saveRepr(pair.col)} (nrs=${saveRepr(pair.nrs)})`, () => {
            expect(collectPartial(pair.s, pair.nrs, pair.backrefCb)).to.be.deep.equal(pair.col)
          })
        }
      }
    })
  })
}
