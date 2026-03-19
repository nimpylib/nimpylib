

import ../bytesimpl
export bytesimpl


const
  Whitespace = {' ', '\t', '\v', '\r', '\l', '\f'}

func ISSPACE*(s: PyBytes, pos: int): bool =
  ## Checks unicode space at unicode char's `pos`
  s.getChar(pos) in Whitespace

