###
parser = require '../src/grammar'

# parser = p()

strs = [
  'abc'
  '#123'
  '[abc]'
  '[]'
  '[abc|def]'
  '[aaa|bbb|ccc]'
  '{}'
  '{a:aa}'
  '{a:aa|b:bb}'
  '{a|b:bb}'
  # 'abc]'
]

options = 
  unescape: (s) -> s
  literal: (s) -> Number s

for s in strs
  try
    x = parser.parse s, options
  catch err  
    console.log "failed: '%s': %s", s, err
    continue
  console.log "ok: '%s' -> %j ", s, x
###  


