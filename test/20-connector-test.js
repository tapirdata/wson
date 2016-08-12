import _ from 'lodash';
import { expect } from 'chai';

import wsonFactory from './wsonFactory';
import * as extdefs from './fixtures/extdefs';
import iterable from './fixtures/setups';

for (let i = 0; i < iterable.length; i++) {
  let setup = iterable[i];
  describe(setup.name, function() {
    let { Point } = extdefs;
    let wson = wsonFactory(setup.options);
    it('should allow to get connector by cname', function() {
      let connector = wson.connectorOfCname('Point');
      expect(connector).to.exist;
      return expect(connector.by).to.be.equal(Point);
    }
    );
    return it('should allow to get connector by value', function() {
      let connector = wson.connectorOfValue(new Point());
      expect(connector).to.exist;
      return expect(connector.by).to.be.equal(Point);
    }
    );
  }
  );
}


