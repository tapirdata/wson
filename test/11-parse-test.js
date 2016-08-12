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
  // if setup.options.useAddon
  //   continue
  let setup = iterable[i];
  describe(setup.name, function() {
    let wson = wsonFactory(setup.options);
    return describe('parse', function() {
      return pairs.map((pair) =>
        (function(pair) {
          if (!_.has(pair, 's')) {
            return;
          }
          if (pair.parseFailPos != null) {
            return it(`should fail to parse '${pair.s}' at ${pair.parseFailPos}`, function() {
              try {
                wson.parse(pair.s, {backrefCb: pair.backrefCb});
              } catch (e_) {
                var e = e_;
              }
              expect(e).to.be.instanceof(Error)
              expect(e.name).to.be.equal('ParseError');
              if (typeof failPos !== 'undefined' && failPos !== null) {
                return expect(e.pos).to.be.equal(pair.parseFailPos);
              }
            }
            );
          } else {
            return it(`should parse '${pair.s}' as ${saveRepr(pair.x)}`, () => expect(wson.parse(pair.s, {backrefCb: pair.backrefCb})).to.be.deep.equal(pair.x)
            );
          }
        })(pair));
    }
    );
  }
  );
}


