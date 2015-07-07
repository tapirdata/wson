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
  if setup.options.useAddon
    continue
  describe setup.name, ->
    wson = wsonFactory setup.options

    collectPartial = (s, nrs, backrefCb) ->
      # console.log 'collectPartial', s, nrs
      result = []
      nrIdx = 0

      cb = (isValue, value, pos) ->
        result.push isValue
        result.push value
        result.push pos
        nrs[nrIdx++]

      wson.parsePartial s, howNext: nrs[nrIdx++], cb: cb, backrefCb: backrefCb

      return result

    describe 'parse partial', ->
      pairs = require './fixtures/partial-pairs'
      for pair in pairs
        do (pair) ->
          if pair.failPos?
            it "should fail to parse '#{pair.s}' at #{pair.failPos}", ->
              try
                collectPartial pair.s, pair.nrs, pair.backrefCb
              catch e_
                e = e_
              expect(e).to.be.instanceof wsonFactory.ParseError
              expect(e.pos).to.be.equal pair.failPos
          else
            it "should parse '#{pair.s}' as #{saveRepr pair.col} (nrs=#{saveRepr pair.nrs})", ->
              expect(collectPartial pair.s, pair.nrs, pair.backrefCb).to.be.deep.equal pair.col



