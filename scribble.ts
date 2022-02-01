import wsonFactory from './src'
import addon from 'wson-addon'
import { Connector } from './src/types';
import { Pair } from './test/fixtures/helpers';

const connectors: Record<string, Connector<any>> = {};

const setups = [
  {
    name: "basic",
    options: {
      connectors,
    },
  },
  {
    name: "native",
    options: {
      connectors,
      addon,
    },
  },
]

const pairs: Pair[] = [
  {
    x: ["ab"],
    s: "[ab]",
  },
  {
    x: [],
    s: "[]",
  },
]

for (const { s, x } of pairs) {
  for (const setup of setups) {
  const WSON = wsonFactory(setup.options)
    console.log(`${setup.name}:`)
    console.log('  s=', s, 'x=', x)
    try {
      const result = WSON.parse(s)
      console.log('  result=', result)
    } catch (err) {
      console.log('  err=', err)
    }
  }
}


