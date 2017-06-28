import { expect } from "chai"

import pairs from "./fixtures/escape-pairs"
import setups from "./fixtures/setups"
import wsonFactory from "./wsonFactory"

for (const setup of setups) {
  describe(setup.name, () => {
    const wson = wsonFactory(setup.options)
    return describe("unescape", () => {
      for (const pair of pairs) {
        const [s, xs] = pair
        if (s != null) {
          it(`should unescape '${xs}' as '${s}' `, () => {
            expect(wson.unescape(xs)).to.be.equal(s)
          })
        } else {
          it(`should not unescape '${xs}'`, () => {
            expect(() => wson.unescape(xs)).to.throw()
          })
        }
      }
    })
  })
}
