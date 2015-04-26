'use strict'

wsonFactory = require './wsonFactory'

chai = require 'chai'
expect = chai.expect

saveRepr = (x) ->
  try
    JSON.stringify x
  catch  
    String x  

for setup in require './fixtures/setups'
  describe setup.name, ->
    wson = wsonFactory setup.options
    describe 'parse', ->
      pairs = require './fixtures/stringify-pairs'
      for [x, s] in pairs
        do (x, s) ->
          if x == '__fail__'
            it "should fail to parse '#{s}'", ->
              expect(-> wson.parse s).to.throw()
          else
            it "should parse '#{s}' as #{saveRepr x}", ->
              expect(wson.parse s).to.be.deep.equal x


