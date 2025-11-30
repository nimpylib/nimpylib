
import ./[pylifecycle, frames]

proc toCSighandler*(p: PySigHandler): CSigHandler =
  proc (signalnum: CSignal){.noconv.} =
    let frame = getFrameOrNil(2)
    p(signalnum, frame)


proc toPySighandler*(p: CSigHandler|NimSigHandler): PySigHandler =
  proc (signalnum: PySignal, _: PFrame){.closure.} =
    p(CSignal signalnum)
