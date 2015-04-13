'use strict'

tsonFactory = require '../src'

chai = require 'chai'
expect = chai.expect


describe 'TSON unquote', ->
  tson = tsonFactory()
  describe 'unquote', ->
    quPairs = require './fixtures/qu-pairs'
    for [s, qus] in quPairs
      do (s, qus) ->
        if s?
          it "should unquote '#{qus}' as '#{s}' ", ->
            expect(tson.unquote qus).to.be.equal s
        else    
          it "should not unquote '#{qus}'", ->
            expect(-> tson.unquote qus).to.throw()

