'use strict'

tsonFactory = require '../src'

chai = require 'chai'
expect = chai.expect


describe 'TSON quote', ->
  tson = tsonFactory()
  describe 'quote', ->
    quPairs = require './fixtures/qu-pairs'
    for [s, qus] in quPairs
      if s?
        do (s, qus) ->
          it "should quote '#{s}' as '#{qus}' ", ->
            expect(tson.quote s).to.be.equal qus

