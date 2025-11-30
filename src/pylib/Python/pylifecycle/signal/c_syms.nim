
import ../../../pyconfig/signal
export signal
const
  HAVE_BROKEN_PTHREAD_SIGMASK* = defined(cygwin) # XXX: cygwin not supported
  PYPTHREAD_SIGMASK* = HAVE_PTHREAD_SIGMASK and not HAVE_BROKEN_PTHREAD_SIGMASK
  HAVE_SIGSET_T* = PYPTHREAD_SIGMASK or HAVE_SIGWAIT or
    HAVE_SIGWAITINFO or HAVE_SIGTIMEDWAIT

import ./handler_types
when defined(windows):
  import std/winlean
  export winlean
  template sig(sym) =
    let sym*{.importc, header: "<signal.h>".}: cint

  let
    CTRL_C_EVENT*{.importc, header: "<Windows.h>".}: cint
    CTRL_BREAK_EVENT*{.importc, header: "<Windows.h>".}: cint
  let
    SIG_DFL*{.importc, header: "<signal.h>".}: CSighandler
    SIG_IGN*{.importc, header: "<signal.h>".}: CSighandler
    SIG_ERR*{.importc, header: "<signal.h>".}: CSighandler
elif defined(js):
  import std/jsffi
  import ../../../jsutils/consts
  type SignalError = object of OSError
  let
    SIG_DFL*: CSighandler = proc (x: CSignal){.noconv.} = discard "DFL"
    SIG_IGN*: CSighandler = proc (x: CSignal){.noconv.} = discard "IGN"
    SIG_ERR*: CSighandler = proc (signal: CSignal){.noconv.} =
      raise newException(SignalError, $signal) #TODO:signal
  template isSIG_DFL(h: CSigHandler): bool = h.isNull or h == SIG_DFL

  template sig(sym) =
    const sym* = astToStr sym
  sig SIGHUP
  sig SIGALRM
  sig SIGPIPE
  sig SIGQUIT
  sig SIGCHLD
else:
  import std/posix except EINTR, ERANGE
  export posix except EINTR, ERANGE
  let
    ITIMER_REAL*{.importc, header: "<sys/time.h>".}: cint
    ITIMER_VIRTUAL*{.importc, header: "<sys/time.h>".}: cint
    ITIMER_PROF*{.importc, header: "<sys/time.h>".}: cint

when not defined(js):
  template isSIG_DFL(h: CSigHandler): bool = h == SIG_DFL

export isSIG_DFL

when declared(sig):
  sig SIGBREAK
  sig SIGABRT
  sig SIGFPE
  sig SIGILL
  sig SIGINT
  sig SIGSEGV
  sig SIGTERM

when HAVE_SIGACTION:
  proc sigaction*(a1: cint; a2: ptr Sigaction; a3: var Sigaction): cint{.importc: "sigaction", header: "<sys/signal.h>".}
  ## XXX: posix/winlean's a2 cannot be nil (a var Sigaction)

when defined(js):
  import ../../../jsutils/denoAttrs
  import ../../../jsutils/jsarrays
  proc js_signal(a1: CSignal, a2: CSighandler) {.
    importDenoOrProcess(addSignalListener, addListener)
  .}
  proc js_unsignal(a1: CSignal, a2: CSigHandler) {.
    importDenoOrProcess(removeSignalListener, removeListener)
  .}
  proc js_getsignals(a1: CSignal): JsArray[CSighandler]{.
    importjs: "process.listeners(#)".}
  proc getsignal*(a1: CSignal): CSigHandler =
    let arr = js_getsignals(a1)
    if arr.len > 0: return arr[^1]
  proc c_signal*(sig: CSignal, handler: CSigHandler): CSigHandler =
    result = getsignal(sig)
    if not result.isNil:
      js_unsignal(sig, result)
    if handler.isSIG_DFL:
      return
    js_signal(sig, handler)
else:
  proc c_signal*(a1: CSignal, a2: CSighandler): CSighandler {.
    importc: "signal", header: "<signal.h>".}  # XXX: std/posix's lacks restype

