start
  = value

/*
additive
  = left:multiplicative "+" right:additive { return left + right; }
  / multiplicative

multiplicative
  = left:primary "*" right:multiplicative { return left * right; }
  / primary

primary
  = integer
  / "(" additive:additive ")" { return additive; }
*/  

text
  = chars:[^#*:|{}[\]]+ { return chars.join(""); }

value
  = x:text { return options.unescape(x); }
  / '#' x:text { return options.literal(x); }
  / '#' { return ''; }
  / array
  / object


arrayElement
  = value

arrayElements
  = head:arrayElement tail:('|' arrayElement)* {
    var result = [head];
    for (i=0; i<tail.length; ++i) {
      result.push(tail[i][1]);
    }
    return result;
  }
  / '' { return []; }

array
  = '[' x:arrayElements ']' { return x; }

objectKey
  = x:text { return options.unescape(x); }
  / '#' { return ''; }

objectElement
  = key:objectKey ':' x:value {return [key, x]}
  / key:objectKey {return [key, true]}

objectElements
  = head:objectElement tail:('|' objectElement)* {
    var result = {};
    result[head[0]] = head[1];
    for (i=0; i<tail.length; ++i) {
      var elem = tail[i][1]
      result[elem[0]] = elem[1];
    }
    return result;
  }
  / '' {return {}; }

object
  = '{' x:objectElements '}' { return x; }

