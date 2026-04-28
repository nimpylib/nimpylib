
from ./collections_abc import Iterable
import pkg/py_constants/pybool
export pybool

proc bool*[T](arg: T): PyBool = pybool(arg)  ## Alias for `pybool`_

func all*[T](iter: Iterable[T]): PyBool =
  ## Checks if all values in iterable are truthy
  result = true
  for element in iter:
    if not bool(element):
      return false

func any*[T](iter: Iterable[T]): PyBool =
  ## Checks if at least one value in iterable is truthy
  result = false
  for element in iter:
    if bool(element):
      return true
