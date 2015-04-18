'use strict'

round = (value, precision) ->
  precision = Math.pow 10, precision
  Math.round(value * precision) / precision


class Timer
  constructor: ->
    @entries = {}

  put: (name, fn, count=1000) ->
    entry = @entries[name]
    if not entry 
      entry =
        totalUsed: 0
        count: 0
      @entries[name] = entry    
    i = 0
    tStart = Date.now()
    while i < count
      ++i
      fn()
    tEnd = Date.now()
    used = (tEnd - tStart) / count
    if entry.minUsed?
      entry.minUsed = Math.min entry.minUsed, used
    else  
      entry.minUsed = used
    if entry.maxUsed?
      entry.maxUsed = Math.max entry.maxUsed, used
    else  
      entry.maxUsed = used

    entry.totalUsed += used
    entry.count += 1

   report: ->   
     for name, entry of @entries
       console.log "%s %sμs (%sμs..%sμs)", name,
         round(entry.totalUsed / entry.count * 1000, 2)
         round(entry.minUsed * 1000, 2)
         round(entry.maxUsed * 1000, 2)
 
factory = ->
  new Timer()

module.exports = factory
