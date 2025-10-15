
import ./utils
addPatch((2,3,1), defined(js)):
  # fixes in nim-lang/Nim#25223
  template castChar*(i: SomeInteger): char = cast[char](i and 255)
when not hasBug:
  template castChar*(i: SomeInteger): char = cast[char](i)
{.used.}