
from std/os import `/../`
template execNoErr(cmd, ofn){.dirty.} =
  const res = staticExec(cmd & ofn)
  static:assert res == ""
  const FILENAME_TO_LINK* = currentSourcePath() /../ ofn

when defined(vcc):
  execNoErr("rc /nologo getplatform.rc /fo ", "getplatform.res")
else: #assume defined(gcc):
  # before https://gcc.gnu.org/bugzilla/show_bug.cgi?id=108866#c11
  #  .rc has to be `windres`-ed
  execNoErr("windres getplatform.rc -o ", "getplatform.o")


