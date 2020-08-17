import { expect } from "chai"

import { pairs } from "./fixtures/escape-pairs"
import { setups } from "./fixtures/setups"
import { wsonFactory } from "./wsonFactory"

for (const setup of setups) {
  describe(setup.name, () => {
    const wson = wsonFactory(setup.options)
    describe("escape", () => {
      for (const pair of pairs) {
        const [s, xs] = pair
        if (s != null) {
          it(`should escape '${s}' as '${xs}' `, () => {
            expect(wson.escape(s)).to.be.equal(xs)
          })
        }
      }
    })
  })
}
