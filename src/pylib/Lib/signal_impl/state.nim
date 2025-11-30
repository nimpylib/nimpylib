
import ./[pylifecycle, pynsig, c_py_handler_cvt]
import ./pyatomic
const Js = defined(js)
when Js:
  import ../../jsutils/consts

const DWin* = defined(windows)
when DWin:
  import std/winlean

type
  handler = object
    tripped*: bool
    fn*: PySigHandler
when Js:
  import std/tables
  type DefaultDict[K, V] = distinct Table[K, V]
  proc `[]`*[K, V](d: DefaultDict[K, V]; key: K): V = (Table[K, V](d)).getOrDefault key
  proc `[]`*[K, V](d: var DefaultDict[K, V]; key: K): var V =
    if key notin Table[K, V](d):
      Table[K, V](d)[key] = default V
    Table[K, V](d)[key]
  proc `[]=`*[K, V](d: var DefaultDict[K, V]; key: K, value: V) = Table[K, V](d)[key] = value
  iterator items*[K, V](d: DefaultDict[K, V]): K =
    for key in Table[K, V](d): key

  type THandlers = DefaultDict[PySignal, handler]
else:
  type THandlers = array[Py_NSIG, handler]
type
  signal_state_t* = object
    handlers*: THandlers

    when DWin:
      sigint_event*: Handle
    
    default_handler*, ignore_handler*: PySigHandler

proc signal_install_handlers() =
  template ignIfDecl(sig) =
    when declared(sig):
      discard PyOS_setsig(sig, SIG_IGN)
  ignIfDecl SIGPIPE
  ignIfDecl SIGXFZ
  ignIfDecl SIGXFSZ

proc initPySignal(state: var signal_state_t, install_signal_handlers: bool) =
  state.default_handler = SIG_DFL.toPySighandler
  state.ignore_handler = SIG_IGN.toPySighandler
  when DWin:
    state.sigint_event = createEvent(
      nil, 1, 0, nil
    )
  if install_signal_handlers:
    signal_install_handlers()
  
var
  state: signal_state_t

proc initPySignal*(install_signal_handlers: bool) =
  state.initPySignal install_signal_handlers

initPySignal not defined(pylibConfigIsolated)

template signal_global_state*: signal_state_t =
  bind state
  state

when DWin:
  template global_sigint_event*: Handle =
    bind state
    state.sigint_event


template Handlers*: untyped =
  bind state
  state.handlers

#[
type ClosurePtr = object
  env, prc: pointer

template getAddrT[T](x: T): ptr T = cast[ptr T](x.addr)
template getAddr(x: proc): ptr pointer = bind getAddrT; getAddrT[pointer](x)
proc getAddr(x: proc{.closure.}): ptr ClosurePtr =
  #bind getAddrT
  let tmp = ClosurePtr(env: x.rawEnv, prc: x.rawProc)
  getAddrT[ClosurePtr](
    tmp
  )


proc get_handler*(i: cint): PySighandler =
  bind getAddr, Py_atomic_load_ptr
  cast[PySigHandler](Py_atomic_load_ptr(Handlers[i].fn.getAddr))

proc set_handler*(i: cint, fn: PySigHandler) =
  bind getAddr, Py_atomic_store_ptr
  Py_atomic_store_ptr(Handlers[i].fn.getAddr, fn)
]#

when compileOption("threads"):
  import  std/locks
  var lock: Lock
  lock.initLock()
  template withLock(body) =
    lock.withLock body
else:
  template withLock(body) =
    body
  template deinitLock(_) =
    discard

proc get_handler*(i: PySignal): PySighandler =
  withLock: result = Handlers[i].fn
proc set_handler*(i: PySignal, fn: PySigHandler) =
  withLock: Handlers[i].fn = fn

when Js:
  import std/jsffi

  type Dict = JsAssoc[cstring, int]
  var dummy: Dict
  let SignalMap* = os_constants["signals"].to Dict  # internal. JS only
  assert not SignalMap.isUndefined

  var SignalRange: distinct JsObject
  iterator items*(obj: Dict): cstring =
    ## Yields the `names` of each field in a JsObject,
    ##   differs from jsffi's `keys` which calls `hasOwnProperty`
    var k: cstring
    {.emit: "for (var `k` in `obj`) {".}
    yield k
    {.emit: "}".}
  iterator items*(obj: typeof(SignalRange)): cstring =
    for key in SignalMap:
      yield key
  proc contains*(obj: typeof(Dict); value: PySignal): bool =
    for i in obj:
      if i == value: return true
else:
  const SignalRange = cint(1) ..< Py_NSIG.cint
export SignalRange

when (NimMajor, NimMinor, NimPatch) >= (2, 1, 1):
  ## XXX: FIXED-NIM-BUG: though nimAllowNonVarDestructor is defined at least since 2.0.6,
  ## it still cannot be compiled till abour 2.1.1
  using destSelf: signal_state_t
else:
  using destSelf: var signal_state_t

proc PySignal_Fini(destSelf) =
  for signum in SignalRange:
    let fn = get_handler(signum)
    Py_atomic_store(Handlers[signum].tripped, false)
    set_handler(signum, nil)
    if not fn.isNil and fn != destSelf.default_handler and 
      fn != destSelf.ignore_handler:
        discard PyOS_setsig(signum, SIG_DFL)
  when DWin:
    if destSelf.sigint_event != Handle(0):
      discard closeHandle(destSelf.sigint_event)

proc PySignal_Fini*() = PySignal_Fini state

proc `=destroy`(destSelf) =
  PySignal_Fini(destSelf)
  deinitLock lock
