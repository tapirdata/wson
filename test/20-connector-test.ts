import { expect } from 'chai';
import * as _ from 'lodash';

import { Point } from './fixtures/extdefs';
import { setups } from './fixtures/setups';
import { wsonFactory } from './wsonFactory';

for (const setup of setups) {
  describe(setup.name, () => {
    const wson = wsonFactory(setup.options);
    it('should allow to get connector by cname', () => {
      const connector = wson.connectorOfCname('Point');
      expect(connector).to.exist;
      if (!connector) {
        return;
      }
      expect(connector.by).to.be.equal(Point);
    });
    it('should allow to get connector by value', () => {
      const connector = wson.connectorOfValue(new Point(0, 0));
      expect(connector).to.exist;
      if (!connector) {
        return;
      }
      expect(connector.by).to.be.equal(Point);
    });
  });
}
