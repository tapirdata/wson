import { ParseError } from "./errors"

let regExpQuoteSet: { [char: string]: true }
{
  const o: { [char: string]: true } = {}
  for (const c of "-\\()+*.?[]^$") {
    o[c] = true
  }
  regExpQuoteSet = o
}

function quoteRegExp(char: string) {
  if (regExpQuoteSet[char]) {
    return "\\" + char
  } else {
    return char
  }
}

const charOfXar: { [xar: string]: string } = {
  o: "{",
  c: "}",
  a: "[",
  e: "]",
  i: ":",
  l: "#",
  p: "|",
  q: "\`",
}

const prefix = "\`"

let charBrick = ""
let splitBrick = ""
const xarOfChar: { [char: string]: string } = {}
{
  for (const xar of Object.keys(charOfXar)) {
    const char = charOfXar[xar]
    xarOfChar[char] = xar
    charBrick += quoteRegExp(char)
    if (char !== prefix) {
      splitBrick += quoteRegExp(char)
    }
  }
}

const charRe = new RegExp("[" + charBrick + "]", "gm")
const xarRe = new RegExp(quoteRegExp(prefix) + "(.?)", "gm")
splitBrick = "([" + splitBrick + "])"

export function unescape(s: string) {
  return s.replace(xarRe, (all, xar, pos) => {
    const char = charOfXar[xar]
    if (char == null) {
      throw new ParseError(s, pos + 1, "") // , "unexpected escape '#{xar}'"
    }
    return char
  },
  )
}

export function escape(s: string) {
  return s.replace(charRe, (char) => prefix + xarOfChar[char])
}

export const splitRe = new RegExp(splitBrick)
