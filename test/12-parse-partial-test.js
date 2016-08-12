import { expect } from 'chai';

import wsonFactory from './wsonFactory';
import iterable from './fixtures/setups';
import pairs from './fixtures/partial-pairs';

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

    let collectPartial = function(s, nrs, backrefCb) {
      // console.log 'collectPartial', s, nrs
      let result = [];
      let nrIdx = 0;

      let cb = function(isValue, value, pos) {
        result.push(isValue);
        result.push(value);
        result.push(pos);
        return nrs[nrIdx++];
      };

      wson.parsePartial(s, {howNext: nrs[nrIdx++], cb, backrefCb});

      return result;
    };

    return describe('parse partial', function() {
      return pairs.map((pair) =>
        (function(pair) {
          if (pair.failPos != null) {
            return it(`should fail to parse '${pair.s}' at ${pair.failPos}`, function() {
              try {
                collectPartial(pair.s, pair.nrs, pair.backrefCb);
              } catch (e_) {
                var e = e_;
              }
              expect(e.name).to.be.equal('ParseError');
              return expect(e.pos).to.be.equal(pair.failPos);
            }
            );
          } else {
            return it(`should parse '${pair.s}' as ${saveRepr(pair.col)} (nrs=${saveRepr(pair.nrs)})`, () => expect(collectPartial(pair.s, pair.nrs, pair.backrefCb)).to.be.deep.equal(pair.col)
            );
          }
        })(pair));
    }
    );
  }
  );
}



