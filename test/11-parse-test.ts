import { expect } from "chai"
import * as _ from "lodash"

import { saveRepr } from "./fixtures/helpers"
import setups from "./fixtures/setups"
import pairs from "./fixtures/stringify-pairs"
import wsonFactory from "./wsonFactory"

for (const setup of setups) {
  describe(setup.name, () => {
    const wson = wsonFactory(setup.options)
    describe("parse", () => {
      for (const pair of pairs) {
        if (!_.has(pair, "s")) {
          continue
        }
        if (pair.parseFailPos != null) {
          it(`should fail to parse '${pair.s}' at ${pair.parseFailPos}`, () => {
            let e
            try {
              wson.parse(pair.s, {backrefCb: pair.backrefCb})
            } catch (someE) {
              e = someE
            }
            expect(e.name).to.be.equal("ParseError")
            expect(e.pos).to.be.equal(pair.parseFailPos)
          })
        } else {
          it(`should parse '${pair.s}' as ${saveRepr(pair.x)}`, () => {
            expect(wson.parse(pair.s, {backrefCb: pair.backrefCb})).to.be.deep.equal(pair.x)
          })
        }
      }
    })
  })
}
