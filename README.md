# wson

[![npm version](https://img.shields.io/npm/v/wson.svg?style=flat-square)](https://www.npmjs.com/package/wson)
[![Build Status](https://secure.travis-ci.org/tapirdata/wson.png?branch=master)](https://travis-ci.org/tapirdata/wson)
[![Dependency Status](https://david-dm.org/tapirdata/wson.svg)](https://david-dm.org/tapirdata/wson)
[![devDependency Status](https://david-dm.org/tapirdata/wson/dev-status.svg)](https://david-dm.org/tapirdata/wson#info=devDependencies)
> A Stringifier and Parser for the WSON data-interchange format.

## Usage

```bash
$ npm install wson
```

```js
import wsonFactory from 'wson'
const WSON = wsonFactory()

const entry = {
  name: 'otto',
  size: 177.3,
  completed: ['forth', 'javascript', "c++", 'haskell'],
  active: true,
}

const s = WSON.stringify(entry)
console.log(s)
// '{active|completed:[forth|javascript|c++|haskell]|name:otto|size:#177.3}'

const newEntry = WSON.parse(s)
// equivalent to entry

```

There is somewhat faster native C++ implementation of a WSON-parser and -stringifyer: [wson-addon](https://www.npmjs.com/package/wson-addon).
Since version 2.6.0 of this module the optional dependency to `wson-addon` been removed. Now the native implementation can be attached manually
by using the option `addon`:

```js
import wsonFactory from 'wson'
import addon from 'wson-addon'
const WSON = wsonFactory({ addon })
```
## Motivation (why yet another format?)

We demanded a format that:
- is deterministic (stringification does not depend on key insertion order or unjustified assumptions about the js-engine).
- is textual, so it can be used as a key itself.
- is terse, especially does grow linearly in length when stringified recursively (`\`-escaping grows exponentially).
- is reasonably human readable.
- can be parsed reasonably fast.
- can handle [cyclic structures](#backrefs).
- is [extensible](#custom-objects).
- can parse strings that contain WSON mixed [with other stuff](#parse-partial).

Since we found shortcomings in all present formats, we decided to create WSON:

### WSON

This is an informal description of the WSON-Syntax. There is also an EBNF-file in the doc-directory and a [syntax-diagram](http://tapirdata.github.io/wson/doc/wson.xhtml) created from it.    

#### Escaping

There 8 special characters: `{`, `}`, `[`, `]`, `#`, `:`, `|`, `` ` ``. If they occur in strings the will be escaped using these counterparts:

| original | escaped |
|:--------:|:-------:|
|   {      |   `o    |
|   }      |   `c    |
|   [      |   `a    |
|   ]      |   `e    |
|   #      |   `l    |
|   :      |   `i    |
|   \|     |   `p    |
|   \`     |   `q    |

The special characters are chosen to be expectable rare in natural language texts to minimize the need for escaping. E.g. delimiter is `|` instead of `,`.


#### Strings

Strings are stringified verbatim (without quotes). If they have special characters in them, they got escaped. The empty string is stringified as `#`.

###### Examples:

| javascript          | WSON            |
|---------------------|-----------------|
| "abc"               | abc             |
| "say: \\"hello\\""  | say`i "hello"   |
| ""                  | #               |

#### Literals

Booleans, `null`, `undefined` are stringified by these patterns:

| javascript          | WSON            |
|---------------------|-----------------|
| false               | #f              |
| true                | #t              |
| null                | #n              |
| undefined           | #u              |

Numbers are stringified by `#` prepended to the number converted to a string.

###### Examples:

| javascript          | WSON            |
|---------------------|-----------------|
| 42                  | #42             |
| 42.1                | #42.1           |

`Date`-objects are stringified by `#d` prepended to the `valueOf`-number (i.e. the milliseconds since midnight 01 January, 1970 UTC) converted to a string.

###### Examples:

| javascript              | WSON            |
|-------------------------|-----------------|
| new Date(1400000000000) | #d1400000000000 |


#### Arrays

Arrays are stringified by their stringified components concatenated by `|`, enclosed by `[`, `]`.

| javascript              | WSON              |
|-------------------------|-------------------|
| []                      | []                |
| ["foo"]                 | [foo]             |
| [""]                    | [#]               |
| ["foo",true,42]         | [foo\|#t\|#42]    |
| ["foo",["bar","baz"]]   | [foo\|[bar\|baz]] |

#### Objects

Objects are stringified by their stringified key-value pairs concatenated by `|`, enclosed by `{`, `}`.
Key-value pairs are stringified this way:
- If the value is `true`: just the escaped key (This is meant to be handy for set-like objects.)
- Else: escaped key `:` stringified value

The pairs are sorted by key (sorting is done before escaping).


| javascript               | WSON                    |
|--------------------------|-------------------------|
| {}                       | {}                      |
| {a: "A", b: "B"}         | {a:A\|b:B}              |
| {b: "A", a: "B"}         | {a:A\|b:B}              |
| {a: true, b: true}       | {a\|b}                  |
| {a: {c: 42}, b: [3,4]}   | {a:{c:#42}\|b:[#3\|#4]} |
| {a: "A", "": "B"}        | {a:A\|#:B}              |

#### Values

A **value** can be any of **string**, **literal**, **array**, and **object**.
Note that array components and object values are **values**, but object keys are **strings**.

<a name="backrefs"></a>
#### Backrefs

WSON is able to stringify and parse cyclic structures by means of **backrefs**. A **backref** is represented by `|` followed by a number, that says how many levels to go up. (0 resolves to the current array or objects, 1 resolves to the structure that contains the current structure and so on.)

| javascript               | WSON                    |
|--------------------------|-------------------------|
| x = {}; x.y = x          | {y:\|0}                 |
| x = {a:[]}; x.a.push(x)  | {a:[\|1]}               |

<a name="custom-objects"></a>
#### Custom Objects

WSON can be extended to stringify and parse **custom objects** by means of **connectors**.

A **connector** is used to stringify a **custom object** by:
- `by`: the objects's constructor. Only objects with exactly that constructor use this **connector** to stringify.
- `split`: a function of `obj` that returns an array of arguments `args` that can be used to recreate `obj`. This may be specified as member function  `__wsonsplit__`, too.

A **connector** is used to create a **custom object** by:
- `create`: a function that takes an array of arguments `args` to create the object `obj`. This may be specified as static member function  `__wsoncreate__`, too.

Alternatively these functions may be used to use 2-stage creation:
- `precreate`: a function that creates the (empty) object `obj`. This may be specified as static member function  `__wsonprecreate__`, too.
- `postcreate`: a function that takes `obj` and `args` to populate `obj`. Should return `obj`, `null`, `undefined` or a new instance of `by`. This may be specified as member function  `__wsonpostcreate__`, too.

If no `create` or `postcreate` are specified, a default `create` is implemented as `new by(...args)`. NOTE: This behaviour has changed since v2.2.0 as the old mechanism (auto-implementing `postcreate` by calling the contructor as a function without `new`) is no longer available in modern typescript.

An extended WSON stringifier/parser is created by passing a `connectors` option to `wson`. `connectors` should be an object that maps **cname** keys to **connector** objects. If a value is given as a function `Foo` the **connector** is constructed as `{by: Foo}`.

The WSON representation of a **custom object** is:

  `[:` **cname** (list of args, each prepended by `|`) `]`

###### Examples:

Provide a `__wsonsplit__` method (use default `create`):
```js
import wsonFactory from 'wson'

class Point {
  constructor(x, y) {
    this.x = x 
    this.y = y 
  }
  __wsonsplit__() {
    return [this.x, this.y]
  }
}

const WSON = wsonFactory({connectors: {Point}})

const point1 = new Point(3, 4)

const s = WSON.stringify(point1);
console.log('s=', s); // [:Point|#3|#4]
const point2 = WSON.parse(s);
```

Or equivalently specify `split` non-invasievely:
```js
import wsonFactory from 'wson';

class Point {
  constructor(x, y) {
    this.x = x 
    this.y = y 
  }
}

const WSON = wsonFactory({connectors: {
  Point: {
    by: Point,
    split: (point) => [point.x, point.y],
  }
}})

const point1 = new Point(3, 4)
const s = WSON.stringify(point1)
console.log('s=', s) // [Point:#3|#4]
const point2 = WSON.parse(s)
```

Specify `split` and `postcreate` (use default `precreate`):
```js
import wsonFactory from 'wson';

class Point {
  constructor(x, y) {
    this.x = x 
    this.y = y 
  }
}

const WSON = wsonFactory({connectors: {
  Point: {
    by: Point,
    // reverse order of args for some strange reason
    split: (point) => [point.y, point.x],
    postcreate: (point, args) => { [point.y, point.x] = args; return point }
  }
}});

const point1 = new Point(3, 4)
const s = WSON.stringify(point1)
console.log('s=', s) // [Point:#4|#3]
const point2 = WSON.parse(s)
```

Alternately you could specify `create` (see Corner cases below):
```js
const WSON = wsonFactory({connectors: {
  Point: {
    by: Point,
    split: (point) => [point.y, point.x],
    create: (args) => new Point(args[1], args[0]),
  }
}});
```

###### Corner cases:

You *can* use together **backrefs** and **custom objects**. For example this will work:

```js
const pointCyc = new Point(5) // leave 'y' undefined for now
const points = [pointCyc, pointCyc]
pointCyc.y = points
const s = WSON.stringify(pointCyc)
```
provided that:
- You use 2-stage creation (don't use `create`).
- `postcreate` does return that very object which has been passed in (or `null`).

## API

#### const WSON = wsonFactory(options)

Creates a new WSON processor. Recognized options are:
- `addon` (optional native module)
- `useAddon` (boolean, default: `undefined`):
  - `false`: An installed `wson-addon` is ignored.
  - `true`: The addon is forced. An exception is thrown if the addon is missing.
  - `undefined`: The addon is used when it is available.
- `version` (number, default: `undefined`): the WSON-version to create the processor for. This document describes version 1. If this is `undefined`, the last available version is used.
- `connectors` (optional): an object that maps **cnames** to [connectors](#custom-objects).

#### WSON.stringify(val, options)

Returns the WSON representation of `val`.
- `options`:
  - `haverefCb` (`function(val)`): a function that can create backrefs outside of `val`. It should return an integer >= 0 for a preexistent enclosing object, otherwise `null`. I.e. `haverefCb` and `backrefCb` are expected to be inverses.

#### WSON.parse(str, options)

Returns the value of the WSON string `str`. If `str` is ill-formed, a `ParseError` will be thrown.
- `options`:
  - `backrefCb` (`function(refIdx)`): a function that can resolve backrefs outside of the item that corresponds to `str`. `refIdx=0` will refer to next enclosing object.

<a name="parse-partial"></a>
#### WSON.parsePartial(str, options)

Parse a string with embedded WSON strings by intercepting the WSON lexer/parser.

- `str`: The string to be parsed.
- `options`:
  - `howNext`: determines how the next chunk should be handled. This may be an array `[nextRaw, skip]` or just boolean `nextRaw`. `skip` is the number of characters to be skipped first (Say, they have been proceeded by other means). Then, if `nextRaw` is:
    - `true`, just the lexer is to be used. The next `value` passed to `cb` will be either:
      - One of the special characters `{`, `}`, `[`, `]`, `#`, `:`, `|`. This is signaled by `isValue == false`.
      - A non-empty string that results by unescaping until the next special character. This is signaled by `isValue == true`.
    - `false`, an attempt to parse is requested. The next `value` passed to `cb` will be either:
      - One of the special characters `}`, `]`, `:`, `|` that may not start a valid WSON string. This is signaled by `isValue == false`.
      - The value of the next WSON string. This is signaled by `isValue == true`. If this sub-string is ill-formed, a `ParseError` will be thrown.
    Any other value of `howNext` will cause `parsePartial` to stop immediately with a result of `false`.
  - `cb` (`function(isValue, value, pos)`): This callback reports the next chunk according to `howNext`. `pos` will be set to the next (yet unparsed) position in `str`. The return value of `cb` is used as `howNext` for next parsing step.
  - `backrefCb` (`function(refIdx)`): a function that can resolve backrefs outside of the item that corresponds to `str`. `refIdx=0` will refer to next enclosing object.

If `parseNext` happens to parse the complete `str`, it will return `true`.

#### WSON.escape(str)

Returns `str` with the special characters replaced by their corresponding escape sequences.

#### WSON.unescape(str)

Returns `str` with encountered escape sequence replaced by their counterparts. If `str` contains invalid escape sequences, a `ParseError` will be thrown.

#### WSON.getTypeid(value)

Returns a numeric type-id of `value`. This function is exposed as it may be useful for extending WSON.

|  value                 | typeid |
|:----------------------:|:------:|
|  `undefined`           |   1    |
|  `null`                |   2    |
|  `Boolean`             |   4    |
|  `Number` (`NaN`, too) |   8    |
|  `Date`                |   16   |
|  `String`              |   20   |
|  `Array`               |   24   |
|   other `Object`       |   32   |


#### WSON.connectorOfCname(cname)

Returns the normalized [connector](#custom-objects) for **cname** (or `null` if none is found).

#### WSON.connectorOfValue(value)

Returns the normalized [connector](#custom-objects) for `value` (or `null` if none is found).

#### wson.ParseError

This may be thrown by `WSON.parse` and `WSON.parsePartial`. It provides these fields:
- `s`: the original ill-formed string.
- `pos`: the position in `s` where passing has stumbled.
- `cause`: some textual description of what caused to reject the string `s`.

