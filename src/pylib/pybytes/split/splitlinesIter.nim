
import ./common
import ./reimporter

# Table of https://docs.python.org/3/library/stdtypes.html#str.splitlines
const LineBreaks = [
  '\r',
  '\n',
]

template IS_LINKBREAK(str: PyBytes, pos): bool =
  str.getChar(pos) in LineBreaks

template IS_CAR_NL(s: PyBytes, pos, str_len): bool =
  s.getChar(pos) == '\r' and pos + 1 < str_len and self.getChar(pos+1) == '\n'


gen_splitlines PyBytes

