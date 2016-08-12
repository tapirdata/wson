import * as errors from './errors';

let regExpQuoteSet = (function(chars) {
  let o = {};
  for (let i = 0; i < chars.length; i++) {
    let c = chars[i];
    o[c] = true;
  }
  return o;
})('-\\()+*.?[]^$');

let quoteRegExp = function(char) {
  if (regExpQuoteSet[char]) {
    return '\\' + char;
  } else {
    return char;
  }
};

let charOfXar = {
//xar: char
  o: '{',
  c: '}',
  a: '[',
  e: ']',
  i: ':',
  l: '#',
  p: '|',
  q: '\`'
};

let prefix = '\`';

var charBrick = '';
var splitBrick = '';
var xarOfChar = {};
for (let xar in charOfXar) {
  let char = charOfXar[xar];
  xarOfChar[char] = xar;
  charBrick += quoteRegExp(char);
  if (char !== prefix) {
    splitBrick += quoteRegExp(char);
  }
}

let charRe = new RegExp('[' + charBrick + ']', 'gm');
let xarRe = new RegExp(quoteRegExp(prefix) + '(.?)', 'gm');
splitBrick = '([' + splitBrick + '])';

export default (function() {
  return {
    prefix,
    charOfXar,
    xarOfChar,
    charBrick,
    charRe,
    xarRe,
    splitBrick,
    unescape: function(s) {
      return s.replace(xarRe, (all, xar, pos) => {
        let char = charOfXar[xar];
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
})();

