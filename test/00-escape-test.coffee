'use strict'

tsonFactory = require '../src'

chai = require 'chai'
expect = chai.expect


describe 'TSON escape', ->
  tson = tsonFactory()
  describe 'escape', ->
    pairs = require './fixtures/escape-pairs'
    for [s, xs] in pairs
      if s?
        do (s, xs) ->
          it "should escape '#{s}' as '#{xs}' ", ->
            expect(tson.escape s).to.be.equal xs

