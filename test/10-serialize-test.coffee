'use strict'

tsonFactory = require '../src'

chai = require 'chai'
expect = chai.expect


describe 'TSON serialize', ->
  tson = tsonFactory()
  describe 'serialize', ->
    return # TODO
    szPairs = require './fixtures/sz-pairs'
    for [x, s] in szPairs
      if x != '__fail__'
        do (x, s) ->
          it "should serialize '#{x}' as '#{s}' ", ->
            expect(tson.serialize x).to.be.equal s


