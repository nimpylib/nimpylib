##[

unstable.

.. note::
  Why haven't implemented the pysugar?

  as `a = yield b` is invalid syntax in nim,

  workaround: use `(a = yield b)`

  See Also: below test code
]##
import ../noneType
import ../pyerrors/[simperr, signals]
from std/typetraits import genericParams

const pylibGeneratorSendStrict{.booldefine.} = not defined(release)
template whenStrictGen(body) =
  when pylibGeneratorSendStrict: body

type
  PyGenerator*[Yield; Send = NoneType; Return = NoneType] = ref object
    old_value{.noInit.}: Send
    ret{.noInit.}: Return

    iter: iterator (value: Send): Yield

    err: ref CatchableError
    closed: bool
    when pylibGeneratorSendStrict:
      started: bool


#[ status:
not-started  0
just-started 1
running      1
closed|err   0
]#

template getRetType[T: PyGenerator](self: T, i = 2): typedesc =
  T.genericParams[i]

template newImpl(it) =
  new result
  result.iter = it

proc newWithReturnPyGenerator*[T, V, R](iter: iterator (value: V): T
  ): PyGenerator[T, V, R] = newImpl iter
proc newPyGenerator*[T; V=NoneType](iter: iterator (value: V): T
  ): PyGenerator[T, V] = newImpl iter
proc newPyGenerator*[T](iter: iterator (): T): PyGenerator[T] =
  newImpl iterator(_: NoneType): T = iter

template newPyGeneratorTempl*(T, V, body): PyGenerator[T, V]{.dirty.} =
  ## inner. debug purpose
  newPyGenerator(iterator (value: V): T = body)

template newPyGeneratorTempl*(T, body): PyGenerator[T]{.dirty.} =
  ## inner. debug purpose
  newPyGenerator(iterator (): T = body)

using self: PyGenerator
proc finished(self): bool = self.closed or finished self.iter
proc close*(self) = self.closed = true


# === send ===

template sendImplNoChk(doIterVal) =
  doIterVal self.iter(self.old_value)
  self.started = true
  if self.finished:
    raise newStopIteration(self.ret)

template sendImpl(errCond, msg) =
  template asgnResult(v) = result=v 
  whenStrictGen:
    if errCond:
      raise newException(TypeError, msg)
  sendImplNoChk asgnResult

proc send*[T, V](self: PyGenerator[T, V]; _: NoneType): T =
  sendImpl(self.started, "can't send None value to a started generator")

proc send*[T, V](self: PyGenerator[T, V]; v: V): T =
  sendImpl(not self.started, "can't send non-None value to a just-started generator")
  self.old_value = v


proc throw*[E: CatchableError](self: PyGenerator, val: ref E) =
  self.err = val
  self.closed = true
  template discardVal(v) = discard v  
  sendImplNoChk discardVal


##[

[a = ]yield b
...
[return V]
|
v

yield b
if self.err != nil:
  let e = self.err
  self.err = nil
  raise e
[a = value]
...
[raise newStopIteration(V)]

]##

when isMainModule:
  let g = newPyGeneratorTempl(int, int):
    yield 0
    echo 'v', value
    yield 1
    echo 'v', value
  echo g.send(None)
  echo g.send(10)
  echo g.send(11)
