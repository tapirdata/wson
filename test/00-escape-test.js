import { expect } from 'chai';

import wsonFactory from './wsonFactory';
import iterable from './fixtures/setups';
import pairs from './fixtures/escape-pairs';


console.log('wsonFactory=', wsonFactory)

for (let i = 0; i < iterable.length; i++) {
  let setup = iterable[i];
  describe(setup.name, function() {
    let wson = wsonFactory(setup.options);
    return describe('escape', function() {
      for (let j = 0; j < pairs.length; j++) {
        let [s, xs] = pairs[j];
        if (s != null) {
          ((s, xs) =>
            it(`should escape '${s}' as '${xs}' `, () => expect(wson.escape(s)).to.be.equal(xs)
            )
          )(s, xs);
        }
      }
    }
    );
  }
  );      
}

