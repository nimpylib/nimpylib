
import ./private/mathutils

type
  PyRange*[T] = ref object ## Python-like range object
    start*, stop*: T  ## `start`, `stop`, `step` are exported since Python 3.3
    step*, len: int

func `$`*[T](rng: PyRange[T]): string =
  const sep = ", "
  if rng.step == 1: "range(" & $rng.start & sep & $rng.stop & ')'
  else: "range(" & $rng.start & sep & $rng.stop & sep & $rng.step & ')'

func repr*[T](rng: PyRange[T]): string = $rng

func range*[T: SomeInteger](start, stop, step: T): PyRange[T] =
  ## Creates new range object with given *start*, *stop* and *step* of any integer type
  if unlikely(step == 0):
    raise newException(ValueError, "range() arg 3 must not be zero!")
  result = PyRange[T](start: start, stop: stop, step: step,
    len: rangeLen(start, stop, step)
  )

template range*[T: SomeInteger](start, stop: T): PyRange[T] =
  ## Shortcut for range(start, stop, 1)
  bind range
  range(start, stop, 1)

template range*[T: SomeInteger](stop: T): PyRange[T] =
  ## Shortcut for range(0, stop, 1)
  bind range
  range(0, stop)

template len*[T](rng: PyRange[T]): int =
  rng.len

iterator items*[T](rng: PyRange[T]): T =
  var res = rng.start
  if rng.step > 0:
    while res <= (rng.stop - 1):
      yield res
      res += rng.step
  else:
    let opposite = -rng.step
    while res >= (rng.stop + 1):
      yield res
      res -= opposite

func `@`*[T](rng: PyRange[T]): seq[T] =
  ## EXT: range to Nim seq
  result = newSeqOfCap[T](rng.len)
  for i in rng:
    result.add i

func contains*[T](x: PyRange[T], y: T): bool =
  ## Checks if given value is in range
  result =
    if x.step > 0:
      y >= x.start and y < x.stop
    else:
      y > x.stop and y <= x.start
  result = result and ((y - x.start) mod x.step == 0)

func `[]`*[T](x: PyRange[T], y: Natural): T {.inline.} =
  ## Get value from range by its index
  assert y < x.len, "Index out of bounds"
  result = x.start + (x.step * y)

func min*[T](x: PyRange[T]): T {.inline.} =
  ## Get minimum value from range. Python's `max(range(...))`
  if unlikely(x.len == 0):
    raise newException(ValueError, "min() arg is an empty sequence")
  x[if x.step > 0: 0 else: x.len - 1]

func max*[T](x: PyRange[T]): T {.inline.} =
  ## Get maximum value from range. Python's `max(range(...))`
  if unlikely(x.len == 0):
    raise newException(ValueError, "max() arg is an empty sequence")
  x[if x.step > 0: x.len - 1 else: 0]

func count*[T](r: PyRange[T], x: T): int =
  int(x in r)

func index*[T](r: PyRange[T], x: T): int =
  if x notin r:
    raise newException(ValueError, $x & " is not in range")
  int((x - r.start) div r.step)
  

func `==`[T](x, y: PyRange[T]): bool =
  ## Since Python 3.3:
  ## Compares based on the sequence of values they define 
  ## (instead of comparing based on object identity).
  let eqLen = x.len == y.len
  if eqLen and x.len == 0: return true  # empty ranges are equal

  if x.start == y.start and x.step == y.step:
      if x.stop == y.stop: return true
      return eqLen
