

import std/bitops
import ./decl
import ../reimporter

template is_integer*(_: NimInt): bool{.pysince(3,12).} = true
template as_integer_ratio*(self: NimInt): (NimInt, NimInt){.pysince(3,8).} = (self, 1)

proc bit_lengthUsingBitops*(x: SomeInteger): int =
  ## inner usage.
  ##
  ## undefined result if x == 0
  ## 
  ## .. note:: though in ArchLinux with `__GNUC__` == 15 the result for x==0 is 0,
  ##   you cannot tell this behavior reliable.
  const BitPerByte = 8
  sizeof(x) * BitPerByte - bitops.countLeadingZeroBits x

proc bit_length*(self: NimInt): NimInt =
  when defined(noUndefinedBitOpts):
    bit_lengthUsingBitops self
  else:
    1 + fastLog2 abs(self)

template bit_count*(self: NimInt): NimInt{.pysince(3,10).} =
  self.countSetBits()

template conjugate*(self: NimInt): NimInt = self
