
import std/winlean
when NimMajor >= 2:
  import std/oserrors
else:
  import std/os


proc ConnectNamedPipe*(hNamedPipe: HANDLE, lpOverlapped: pointer): WINBOOL{.importc, header: "<namedpipeapi.h>".}


template WaitForSignaleObject*(hObject: HANDLE, dwMilliseconds: DWORD): DWORD =
  waitForSingleObject(hObject, dwMilliseconds)

template GetExitCodeProcess*(hProcess: HANDLE, lpExitCode: var DWORD): WINBOOL =
  getExitCodeProcess(hProcess, lpExitCode)

proc CloseHandle*(hObject: HANDLE) =
  if closeHandle(hObject) == 0:
    raiseOSError(osLastError())
