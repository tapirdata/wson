'use strict'

_ = require 'lodash'
wsonFactory = require './wsonFactory'
extdefs = require './fixtures/extdefs'

chai = require 'chai'
expect = chai.expect

for setup in require './fixtures/setups'
  describe setup.name, ->
    Point = extdefs.Point
    wson = wsonFactory setup.options
    it 'should allow to get connector by cname', ->
      connector = wson.connectorOfCname 'Point'
      expect(connector).to.exist
      expect(connector.by).to.be.equal Point
    it 'should allow to get connector by value', ->
      connector = wson.connectorOfValue new Point
      expect(connector).to.exist
      expect(connector.by).to.be.equal Point


