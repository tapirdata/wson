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
  # if setup.options.useAddon
  #   continue
  describe setup.name, ->
    wson = wsonFactory setup.options

    collectPartial = (s, nrs) ->
      # console.log 'collectPartial', s, nrs
      result = []
      nrIdx = 0

      cb = (isValue, value) ->
        result.push isValue
        result.push value
        nrs[nrIdx++]

      wson.parsePartial s, nrs[nrIdx++], cb

      return result  

    describe 'parse partial', ->
      pairs = require './fixtures/partial-pairs'
      for pair in pairs
        do (pair) ->
          if pair.failPos?
            it "should fail to parse '#{pair.s}' at #{pair.failPos}", ->
              try
                collectPartial pair.s, pair.nrs
              catch e_
                e = e_
              expect(e).to.be.instanceof wsonFactory.ParseError
              expect(e.pos).to.be.equal pair.failPos
          else
            it "should parse '#{pair.s}' as #{saveRepr pair.col} (nrs=#{saveRepr pair.nrs})", ->
              expect(collectPartial pair.s, pair.nrs).to.be.deep.equal pair.col



