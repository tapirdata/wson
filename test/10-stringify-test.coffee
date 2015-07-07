'use strict'

_ = require 'lodash'
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
      for pair in pairs
        do (pair) ->
          if not _.has pair, 'x'
            return
          if pair.stringifyFailPos?
            it "should fail to stringify #{saveRepr pair.x}", ->
              expect(-> wson.stringify pair.x, haverefCb: pair.haverefCb).to.throw()
          else
            it "should stringify #{saveRepr pair.x} as '#{pair.s}' ", ->
              expect(wson.stringify pair.x, haverefCb: pair.haverefCb).to.be.equal pair.s

