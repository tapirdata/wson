'use strict'

Tson = require '../src'

chai = require 'chai'
expect = chai.expect


describe 'Tson escape', ->
  tson = new Tson()
  describe 'escape', ->
    pairs = require './fixtures/escape-pairs'
    for [s, xs] in pairs
      if s?
        do (s, xs) ->
          it "should escape '#{s}' as '#{xs}' ", ->
            expect(tson.escape s).to.be.equal xs

