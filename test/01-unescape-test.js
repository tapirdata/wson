import { expect } from 'chai';

import wsonFactory from './wsonFactory';
import iterable from './fixtures/setups';
import pairs from './fixtures/escape-pairs';

for (let i = 0; i < iterable.length; i++) {
  let setup = iterable[i];
  describe(setup.name, function() {
    let wson = wsonFactory(setup.options);
    return describe('unescape', function() {
      return pairs.map(([s, xs]) =>
        (function(s, xs) {
          if (s != null) {
            return it(`should unescape '${xs}' as '${s}' `, () => expect(wson.unescape(xs)).to.be.equal(s)
            );
          } else {
            return it(`should not unescape '${xs}'`, () => expect(() => wson.unescape(xs)).to.throw()
            );
          }
        })(s, xs));
    }
    );
  }
  );
}

