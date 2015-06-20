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

    collectPartial = (s, fOk) ->
      result = []

      wson.parsePartial s, (isValue, value) ->
        result.push isValue
        result.push value
        if fOk?
          fOk isValue, value

      return result  

    describe 'parse partial', ->
      pairs = require './fixtures/partial-pairs'
      for [s, l, fOk] in pairs
        do (s, l, fOk) ->
          cb = (isValue, v) ->
            result.push isValue
            result.push v
          if l == '__fail__'
            it "should fail to parse '#{s}'", ->
              expect(-> collectPartial s).to.throw()
          else
            it "should parse '#{s}' as #{saveRepr l} #{if fOk then '(truncated)' else ''}", ->
              expect(collectPartial s, fOk).to.be.deep.equal l



