'use strict'

wsonFactory = require './wsonFactory'

chai = require 'chai'
expect = chai.expect


for setup in require './fixtures/setups'
  describe setup.name, ->
    wson = wsonFactory setup.options
    describe 'unescape', ->
      pairs = require './fixtures/escape-pairs'
      for [s, xs] in pairs
        do (s, xs) ->
          if s?
            it "should unescape '#{xs}' as '#{s}' ", ->
              expect(wson.unescape xs).to.be.equal s
          else
            it "should not unescape '#{xs}'", ->
              expect(-> wson.unescape xs).to.throw()

