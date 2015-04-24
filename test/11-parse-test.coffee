'use strict'

# JSON = require 'JSON'
Tson = require '../src'

chai = require 'chai'
expect = chai.expect


describe 'Tson parse', ->
  tson = new Tson(hi: true)
  describe 'parse', ->
    pairs = require './fixtures/stringify-pairs'
    for [x, s] in pairs
      do (x, s) ->
        if x == '__fail__'
          it "should fail to parse '#{s}'", ->
            expect(-> tson.parse s).to.throw()
        else
          it "should parse '#{s}' as '#{JSON.stringify x}'", ->
            expect(tson.parse s).to.be.deep.equal x


