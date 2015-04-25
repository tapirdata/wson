'use strict'

tsonFactory = require './tsonFactory'

chai = require 'chai'
expect = chai.expect


for setup in require './fixtures/setups'
  describe setup.name, ->
    tson = tsonFactory setup.options
    describe 'escape', ->
      pairs = require './fixtures/escape-pairs'
      for [s, xs] in pairs
        if s?
          do (s, xs) ->
            it "should escape '#{s}' as '#{xs}' ", ->
              expect(tson.escape s).to.be.equal xs

