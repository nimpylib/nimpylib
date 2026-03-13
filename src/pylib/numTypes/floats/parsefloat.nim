

import pkg/nimpatch/parsefloat
func parsePyFloat*(a: openArray[char], res: var BiggestFloat): int =
  ## Almost the same as parseFloat in std/parseutils
  ## but respects the sign of NaNs, unlike Nim's before 2.3.1
  ##
  ## .. hint:: this does not strip whitespaces, just like parseFloat
  parseFloat(a, res)

