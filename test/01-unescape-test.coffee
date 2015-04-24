'use strict'

Tson = require '../src'

chai = require 'chai'
expect = chai.expect


describe 'Tson unescape', ->
  tson = new Tson()
  describe 'unescape', ->
    pairs = require './fixtures/escape-pairs'
    for [s, xs] in pairs
      do (s, xs) ->
        if s?
          it "should unescape '#{xs}' as '#{s}' ", ->
            expect(tson.unescape xs).to.be.equal s
        else
          it "should not unescape '#{xs}'", ->
            expect(-> tson.unescape xs).to.throw()

