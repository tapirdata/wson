# wson [![Build Status](https://secure.travis-ci.org/tapirdata/wson.png?branch=master)](https://travis-ci.org/tapirdata/wson) [![Dependency Status](https://david-dm.org/tapirdata/wson.svg)](https://david-dm.org/tapirdata/wson) [![devDependency Status](https://david-dm.org/tapirdata/wson/dev-status.svg)](https://david-dm.org/tapirdata/wson#info=devDependencies)
> A Stringifier and Parser for the WSON data-interchange format.

## Usage

```bash
$ npm install wson
```

If you have installed [node-gyp](https://www.npmjs.com/package/node-gyp) and its prerequisites, this will also install the optional package [wson-addon](https://www.npmjs.com/package/wson-addon), which provides a somewhat faster (some benchmarking shows a factor of about 2) C++ implementation of a WSON stringifier/parser.

```js
WSON = require('wson')();

var entry = {
  name: "otto",
  size: 177.3,
  completed: ["forth", "javascript", "c++", "haskell"],
  active: true
};

var s = WSON.stringify(entry);
console.log(s);
// '{active|completed:[forth|javascript|c++|haskell]|name:otto|size:#177.3}'

var newEntry = WSON.parse(s);
// equivalent to entry

```
## Motivation (why just another format?)

We demand a format that:
- is stable (stringification does not depend on key insertion order).
- is textual, so it can be used as a key itself.
- is terse, especially does grow linearly in length when stringified recursively.
- is reasonably human readable.
- can be parsed reasonably fast.
- can proceed cyclic structures.
- is extensible.

Since we found shortcomings in all present formats, we decided to create WSON:

### WSON

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
|   `      |   `q    |

The special characters are choosen to be expectable rare in natural language texts to minimize the need for escaping.


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
- If the value is `true`: just the escaped key (This is meant to be handy for objects representing sets)
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

#### Backrefs

WSON is able to stringify and parse cyclic structures by means of **backrefs**. A **backref** is represented by `|` followed by a number, that says how many levels to go up. (0 resolves to the current array or objects, 1 resolves to the structure that contains the current structure and so on.)

| javascript               | WSON                    |
|--------------------------|-------------------------|
| x = {}; x.y = x          | {y:\|0}                 |
| x = {a:[]}; x.a.push(x)  | {a:[\|1]}               |

#### Custom Objects

WSON can be extended to stringify and parse custom objects by means of **connectors**.

A **connector** is used to stringify a custom object by:
- `by`: the objects's constructor. Only objects with exactly that constructor use this **connector** to stringify.
- `split`: a function of `obj` that returns an array of arguments `args` that can be used to recreate `obj`.

If `split` is ommited, `obj` must provide a method `__wsonsplit__` that return `args`.

A **connector** is used to create a custom object by:
- `create`: a function that takes an array of arguments `args` to create the object `obj`.

Alternativly these functions may be used to use 2-stage creation:
- `precreate`: a function that creates the (empty) object `obj`.
- `postcreate`: a function that takes `obj` and `args` to populate `obj`.

If no `create` is specified, missing `precreate` and `postcreate` are just created by using the constructor `by`.

An extend WSON stringifier/parser is created by passing a `connectors` option to `wson`. `connectors` should by a object that maps that map **cname** keys to **connector** objects. If a value is given as a function `Foo` the **connector** is constructed as `{by: Foo}`.



The WSON representation of custom objects is:

  `[:` **cname** (list of args, each prepeded by `|`) `]`

###### Examples:

Provide a `__wsonsplit__` method:

```js
var wson = require('wson');

var Point = function(x, y) {this.x=x; this.y=y; }
Point.prototype.__wsonsplit__ = function() {return [this.x, this.y]; }

var WSON = wson({connectors: {Point: Point}});

var point1 = new Point(3, 4);

var s = WSON.stringify(point1);
console.log('s=', s); // [Point:#3|#4]
var point2 = WSON.parse(s);
```
Or equivalently specify `split` explicitly:

```js
var wson = require('wson');

var Point = function(x, y) {this.x=x; this.y=y}

var WSON = wson({connectors: {
  Point: {
    by: Point, 
    split: function(point) {return [point.x, point.y]; }
  }
}});

var point1 = new Point(3, 4);
var s = WSON.stringify(point1);
console.log('s=', s); // [Point:#3|#4]
var point2 = WSON.parse(s);
```


## API

#### var WSON = wson(options);

Creates a new WSON processor. Recognized options are:
- `useAddon` (boolean, default: `undefined`):
  - `false`: An installed `wson-addon` is ignored.
  - `true`: The addon is forced. An exception is thrown if the addon is missing.
  - `undefined`: The addon is used when it is available.
- `version` (number, default: `undefined`): the WSON-version to create the processor for. This document describes version 1. If this is `undefined`, the last available version is used.
- `connectors` (optional): an object of  

#### var str = WSON.stringify(val);

Returns the WSON representation of `val`.


#### var val = WSON.parse(str);

Returns the value of the WSON string `str`. If `str` is ill-formed, a `ParseError` will be thrown.

