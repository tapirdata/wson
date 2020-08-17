
type Pair = [null | string, string]

const pairs: Pair[] = [
  ["",    ""],
  ["abc", "abc"],
  ["a:bc", "a`ibc"],
  ["a:b:c", "a`ib`ic"],
  ["ab`c", "ab`qc"],
  ["x:#3|y1:[otto|{t|u:ok}]", "x`i`l3`py1`i`aotto`p`ot`pu`iok`c`e"],
  [null, "ab`xc"],
]

export { pairs }
