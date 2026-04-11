
import pylib

def f(x):
  for i in range(x):
    yield i

let it = f(2)
assert next(it) == 0
assert next(it) == 1
doAssertRaises(StopIteration):
  discard next(it)
