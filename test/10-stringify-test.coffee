'use strict'

wsonFactory = require './wsonFactory'

chai = require 'chai'
expect = chai.expect

try
  util = require 'util'
catch  
  util = null
  
saveRepr = (x) ->
  if util
    util.inspect x, depth: null
  else  
    try
      JSON.stringify x
    catch  
      String x  

for setup in require './fixtures/setups'
  describe setup.name, ->
    wson = wsonFactory setup.options
    describe 'stringify', ->
      pairs = require './fixtures/stringify-pairs'
      for [x, s] in pairs
        do (x, s) ->
          if x == '__fail__'
            return
          if s == '__fail__'
            it "should fail to stringify #{saveRepr x}", ->
              expect(-> wson.stringify x).to.throw()
          else
            it "should stringify #{saveRepr x} as '#{s}' ", ->
              expect(wson.stringify x).to.be.equal s

