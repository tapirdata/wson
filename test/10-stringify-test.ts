import { expect } from 'chai';
import * as _ from 'lodash';

import { safeRepr } from './fixtures/helpers';
import { setups } from './fixtures/setups';
import { pairs } from './fixtures/stringify-pairs';
import { wsonFactory } from './wsonFactory';

for (const setup of setups) {
  describe(setup.name, () => {
    const wson = wsonFactory(setup.options);
    describe('stringify', () => {
      for (const pair of pairs) {
        if (!_.has(pair, 'x')) {
          continue;
        }
        if (pair.stringifyFailPos != null) {
          it(`should fail to stringify ${safeRepr(pair.x)}`, () => {
            expect(() => wson.stringify(pair.x, { haverefCb: pair.haverefCb })).to.throw();
          });
        } else {
          it(`should stringify ${safeRepr(pair.x)} as ${safeRepr(pair.s)} `, () => {
            expect(wson.stringify(pair.x, { haverefCb: pair.haverefCb })).to.be.equal(pair.s);
          });
        }
      }
    });
  });
}
