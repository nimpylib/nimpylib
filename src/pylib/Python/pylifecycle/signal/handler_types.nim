
when defined(js):
  type CSignal* = cstring
  type PySignal* = cstring
else:
  type CSignal* = cint
  type PySignal* = int

type
  PySigHandler* = proc (signalnum: PySignal, frame: PFrame){.closure.}
  CSigHandler* = proc (signalnum: CSignal) {.noconv.}  ## PyOS_sighandler_t
  NimSigHandler* = proc (signalnum: PySignal){.nimcall.}
