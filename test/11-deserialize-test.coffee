'use strict'

# JSON = require 'JSON'
tsonFactory = require '../src'

chai = require 'chai'
expect = chai.expect


describe 'TSON deserialize', ->
  tson = tsonFactory()
  describe 'deserialize', ->
    szPairs = require './fixtures/sz-pairs'
    for [x, s] in szPairs
      do (x, s) ->
        if x == '__fail__'
          it "should fail to deserialize '#{s}'", ->
            expect(-> tson.deserialize s).to.throw()
        else  
          it "should deserialize '#{s}' as '#{JSON.stringify x}'", ->
            expect(tson.deserialize s).to.be.deep.equal x


