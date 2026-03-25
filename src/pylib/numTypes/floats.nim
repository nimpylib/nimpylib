
import std/math
import ../pystring/strimpl
import ./floats/init
export init.float

import pkg/float_utils/[integer_ratio, floathex]
export integer_ratio

func hex*(x: float): PyStr = str floathex.hex(x)
func floatFromhex*(s: PyStr): float =
  floathex.floatFromhex $s
func fromhex*(_: typedesc[float], s: PyStr): float =
  floatFromhex s

when isMainModule:
  let s = str "asdsa"
  echo float.fromhex s
