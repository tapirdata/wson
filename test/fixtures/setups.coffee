extdefs = require './extdefs'

extensions = [{
  name: 'Point'
  constr: extdefs.Point
}]

module.exports = [
  {name: 'WSON-js', options: {useAddon: false, extensions: extensions}}
  # {name: 'WSON-addon', options: {useAddon: true}, extensions: extensions}
]

