{.used.}
import ./utils
addPatch((2,1,1), true):
  # introduced in nim-lang/Nim#22572
  proc newStringUninit*(len: Natural): string =
    ## just fallback
    newString(len)

  proc newSeqUninit*[T](len: Natural): seq[T] =
    when declared(newSeqUninitialized):
      newSeqUninitialized[T](len)
    elif declared(setLenUninit):
      result.setLenUninit(len)
    else:
      newSeq[T](len)
  
  proc setLenUninit*[T](s: var seq[T], newlen: Natural) = s.setLen newLen

when not declared(setLenUninit):  # XXX: currently (as of 2.3.1), no such for JS
  # system only declares it
  #  `when defined(nimHasSetLengthSeqUninitMagic)`
  proc setLenUninit*[T](s: var seq[T], newlen: Natural) = s.setLen newLen
