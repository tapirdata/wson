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
    describe 'stringify', ->
      pairs = require './fixtures/stringify-pairs'
      for [x, s] in pairs
        do (x, s) ->
          if x == '__fail__'
            return
          if s == '__fail__'
            it "should fail to stringify #{saveRepr x}", ->
              expect(-> tson.stringify x).to.throw()
          else
            it "should stringify #{saveRepr x} as '#{s}' ", ->
              expect(tson.stringify x).to.be.equal s

