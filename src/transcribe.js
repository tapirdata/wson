import * as errors from './errors';

let regExpQuoteSet;
{
  let o = {};
  for (const c of '-\\()+*.?[]^$') {
    o[c] = true;
  }
  regExpQuoteSet = o;
}

function quoteRegExp(char) {
  if (regExpQuoteSet[char]) {
    return '\\' + char;
  } else {
    return char;
  }
};

const charOfXar = {
  o: '{',
  c: '}',
  a: '[',
  e: ']',
  i: ':',
  l: '#',
  p: '|',
  q: '\`'
};

const prefix = '\`';

let charBrick = '';
let splitBrick = '';
let xarOfChar = {};
{
  for (const xar in charOfXar) {
    const char = charOfXar[xar];
    xarOfChar[char] = xar;
    charBrick += quoteRegExp(char);
    if (char !== prefix) {
      splitBrick += quoteRegExp(char);
    }
  }
}

const charRe = new RegExp('[' + charBrick + ']', 'gm');
const xarRe = new RegExp(quoteRegExp(prefix) + '(.?)', 'gm');
splitBrick = '([' + splitBrick + '])';

export default {
  // prefix,
  // charOfXar,
  // xarOfChar,
  // charBrick,
  // charRe,
  // xarRe,
  splitBrick,
  unescape: function(s) {
    return s.replace(xarRe, (all, xar, pos) => {
      const char = charOfXar[xar];
      if (char == null) {
        throw new errors.ParseError(s, pos + 1); // , "unexpected escape '#{xar}'"
      }
      return char;
    }
    );
  },
  escape: function(s) {
    return s.replace(charRe, char => prefix + xarOfChar[char]);
  }
};

