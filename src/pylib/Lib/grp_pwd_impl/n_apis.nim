
import std/os
import ./apisTmpl

template raiseOSErrorWithErrno(i: cint) =
  raiseOSError(OSErrorCode i)

genApis seq, string, raiseOSErrorWithErrno 

when isMainModule:
  echo getgrnam"root"

