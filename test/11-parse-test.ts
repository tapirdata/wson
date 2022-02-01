import { expect } from 'chai';
import * as _ from 'lodash';

import { ParseError } from '../src';
import { safeRepr } from './fixtures/helpers';
import { setups } from './fixtures/setups';
import { pairs } from './fixtures/stringify-pairs';
import { wsonFactory } from './wsonFactory';

for (const setup of setups) {
  describe(setup.name, () => {
    const wson = wsonFactory(setup.options);
    describe('parse', () => {
      for (const pair of pairs) {
        const { s } = pair;
        if (s == null) {
          continue;
        }
        if (pair.parseFailPos != null) {
          it(`should fail to parse '${s}' at ${pair.parseFailPos}`, () => {
            let e;
            try {
              wson.parse(s, { backrefCb: pair.backrefCb });
            } catch (someE) {
              e = someE as ParseError;
            }
            if (e == null) {
              throw new Error('ParseError expected');
            }
            expect(e.name).to.be.equal('ParseError');
            expect(e.pos).to.be.equal(pair.parseFailPos);
          });
        } else {
          it(`should parse '${s}' as ${safeRepr(pair.x)}`, () => {
            expect(wson.parse(s, { backrefCb: pair.backrefCb })).to.be.deep.equal(pair.x);
          });
        }
      }
    });
  });
}
