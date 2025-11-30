
#npython: Include/cpython/pyatomic.nim
const SingleThread* = defined(js) or not compileOption"threads"
when SingleThread:
  template orSingleThrd(body, js): untyped = js
else:
  template orSingleThrd(body, js): untyped = body

template Py_atomic_load_ptr*[T](obj: ptr T): T = orSingleThrd(atomicLoadN(obj, ATOMIC_SEQ_CST), obj[])
template Py_atomic_store_ptr*[T](obj: ptr T, value: T) = orSingleThrd atomicStoreN(obj, value, ATOMIC_SEQ_CST):
  obj[] = value

template Py_atomic_load*[T](obj: T): T =
  bind Py_atomic_load_ptr
  Py_atomic_load_ptr(obj.addr)


template Py_atomic_store*[T](obj: T, value: T) =
  bind Py_atomic_store_ptr
  Py_atomic_store_ptr(obj.addr, value)

