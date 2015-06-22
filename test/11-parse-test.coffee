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
    describe 'parse', ->
      pairs = require './fixtures/stringify-pairs'
      for pair in pairs
        do (pair) ->
          [x, s, failPos] = pair
          if x == '__fail__'
            it "should fail to parse '#{s}' at #{failPos}", ->
              try
                wson.parse s
              catch e_
                e = e_
              expect(e).to.be.instanceof wsonFactory.ParseError
              if failPos?
                expect(e.pos).to.be.equal failPos
          else
            it "should parse '#{s}' as #{saveRepr x}", ->
              expect(wson.parse s).to.be.deep.equal x


