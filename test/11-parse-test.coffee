'use strict'

tsonFactory = require './tsonFactory'

chai = require 'chai'
expect = chai.expect

saveRepr = (x) ->
  try
    JSON.stringify x
  catch  
    String x  

for setup in require './fixtures/setups'
  describe setup.name, ->
    tson = tsonFactory setup.options
    describe 'parse', ->
      pairs = require './fixtures/stringify-pairs'
      for [x, s] in pairs
        do (x, s) ->
          if x == '__fail__'
            it "should fail to parse '#{s}'", ->
              expect(-> tson.parse s).to.throw()
          else
            it "should parse '#{s}' as #{saveRepr x}", ->
              expect(tson.parse s).to.be.deep.equal x


