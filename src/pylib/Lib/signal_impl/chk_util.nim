
import ./state

proc chkSigRng*(signalnum: cint|int|cstring) =
  if signalnum not_in (
    when signalnum is cstring: SignalMap
    else: SignalRange
  ):
    raise newException(ValueError, "signal number out of range")
