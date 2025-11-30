
import ./handler_types
template ifInvalidOnVcc*(signalnum: CSignal, handleExc) =
  when defined(windows):
    if signalnum in {SIGABRT, SIGBREAK, SIGFPE, SIGILL, SIGINT, SIGSEGV, SIGTERM}: discard
    else:
      handleExc

