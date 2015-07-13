'use strict'

wsonFactory = require './wsonFactory'

chai = require 'chai'
expect = chai.expect


for setup in require './fixtures/setups'
  describe setup.name, ->
    wson = wsonFactory setup.options
    describe 'typeid', ->
      pairs = require './fixtures/typeid-pairs'
      for pair in pairs
        do (pair) ->
          [x, typeid] = pair
          it "should get typeid of #{JSON.stringify x} as '#{typeid}' ", ->
            expect(wson.getTypeid x).to.be.equal typeid


