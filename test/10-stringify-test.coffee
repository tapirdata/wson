'use strict'

# JSON = require 'JSON'
tsonFactory = require '../src'

chai = require 'chai'
expect = chai.expect


describe 'TSON stringify', ->
  tson = tsonFactory()
  describe 'stringify', ->
    pairs = require './fixtures/stringify-pairs'
    for [x, s] in pairs
      do (x, s) ->
        if x == '__fail__'
          return
        if s == '__fail__'
          it "should fail to stringify '#{JSON.stringify x}'", ->
            expect(-> tson.stringify x).to.throw()
        else  
          it "should stringify '#{JSON.stringify x}' as '#{s}' ", ->
            expect(tson.stringify x).to.be.equal s

