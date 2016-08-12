import _ from 'lodash';
import { expect } from 'chai';
import wsonFactory from './wsonFactory';
import iterable from './fixtures/setups';
import pairs from './fixtures/stringify-pairs';

try {
  var util = require('util');
} catch (error) {
  var util = null;
}

let saveRepr = function(x) {
  if (util) {
    return util.inspect(x, {depth: null});
  } else {
    try {
      return JSON.stringify(x);
    } catch (error1) {
      return String(x);
    }
  }
};

for (let i = 0; i < iterable.length; i++) {
  let setup = iterable[i];
  describe(setup.name, function() {
    let wson = wsonFactory(setup.options);
    return describe('stringify', function() {
      return pairs.map((pair) =>
        (function(pair) {
          if (!_.has(pair, 'x')) {
            return;
          }
          if (pair.stringifyFailPos != null) {
            return it(`should fail to stringify ${saveRepr(pair.x)}`, () => expect(() => wson.stringify(pair.x, {haverefCb: pair.haverefCb})).to.throw()
            );
          } else {
            return it(`should stringify ${saveRepr(pair.x)} as '${pair.s}' `, () => expect(wson.stringify(pair.x, {haverefCb: pair.haverefCb})).to.be.equal(pair.s)
            );
          }
        })(pair));
    }
    );
  }
  );
}

