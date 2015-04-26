'use strict'

wsonFactory = require './wsonFactory'

chai = require 'chai'
expect = chai.expect


for setup in require './fixtures/setups'
  describe setup.name, ->
    wson = wsonFactory setup.options
    describe 'escape', ->
      pairs = require './fixtures/escape-pairs'
      for [s, xs] in pairs
        if s?
          do (s, xs) ->
            it "should escape '#{s}' as '#{xs}' ", ->
              expect(wson.escape s).to.be.equal xs

