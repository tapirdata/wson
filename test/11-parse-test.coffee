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
  # if setup.options.useAddon
  #   continue
  describe setup.name, ->
    wson = wsonFactory setup.options
    describe 'parse', ->
      pairs = require './fixtures/stringify-pairs'
      for pair in pairs
        do (pair) ->
          if not _.has pair, 's'
            return
          if pair.parseFailPos?
            it "should fail to parse '#{pair.s}' at #{pair.parseFailPos}", ->
              try
                wson.parse pair.s, backrefCb: pair.backrefCb
              catch e_
                e = e_
              expect(e).to.be.instanceof wsonFactory.ParseError
              if failPos?
                expect(e.pos).to.be.equal pair.parseFailPos
          else
            it "should parse '#{pair.s}' as #{saveRepr pair.x}", ->
              expect(wson.parse pair.s, backrefCb: pair.backrefCb).to.be.deep.equal pair.x


