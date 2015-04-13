'use strict'

# JSON = require 'JSON'
tsonFactory = require '../src'

chai = require 'chai'
expect = chai.expect


describe 'TSON serialize', ->
  tson = tsonFactory()
  describe 'serialize', ->
    szPairs = require './fixtures/sz-pairs'
    for [x, s] in szPairs
      do (x, s) ->
        if s == '__fail__'
          it "should fail to serialize '#{JSON.stringify x}'", ->
            expect(-> tson.serialize x).to.throw()
        else  
          it "should serialize '#{JSON.stringify x}' as '#{s}' ", ->
            expect(tson.serialize x).to.be.equal s

