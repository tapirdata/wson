'use strict'

timed = (fn, count, name) ->
  # console.log 'startng "%s"...', name
  tStart = Date.now()
  i = 0
  while i < count
    fn()
    ++i
  tEnd = Date.now()
  used = tEnd - tStart
  console.log "'%s' used total: %sms; per call: %sms", name, used, used/count
  return

module.exports = timed
