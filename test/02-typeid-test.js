import { expect } from 'chai';

import wsonFactory from './wsonFactory';
import iterable from './fixtures/setups';
import pairs from './fixtures/typeid-pairs';

for (let i = 0; i < iterable.length; i++) {
  let setup = iterable[i];
  describe(setup.name, function() {
    let wson = wsonFactory(setup.options);
    return describe('typeid', function() {
      return pairs.map((pair) =>
        (function(pair) {
          let [x, typeid] = pair;
          return it(`should get typeid of ${JSON.stringify(x)} as '${typeid}' `, () => expect(wson.getTypeid(x)).to.be.equal(typeid)
          );
        })(pair));
    }
    );
  }
  );
}


