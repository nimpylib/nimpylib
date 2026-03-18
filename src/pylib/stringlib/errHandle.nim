
import ./err

template noEmptySep*(sep) =
  when sep is not char:
    if sep.len == 0:
      raise newException(ValueError, "empty separator")

template retIfWider*[S](a: S) =
  if len(a) >= width:
    return a

template chkLen*(a): int = 
  ## 1. returns if wider; 2. raises if not 1 len; 3. length as result
  bind retIfWider
  retIfWider a
  let le = len(fillchar)
  if le != 1:
    raise newException(TypeError, 
      "The fill character must be exactly one character long")
  le

