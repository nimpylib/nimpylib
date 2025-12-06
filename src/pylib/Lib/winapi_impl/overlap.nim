
import std/winlean
import std/os
import ./consts

proc cancelIoEx*(handle: HANDLE, overlapped: ptr OVERLAPPED): WINBOOL {.importc: "CancelIoEx", header: "<IoAPI.h>".}

type
  OverlappedObjectObj = object
    overlapped*: winlean.OVERLAPPED
    handle*: HANDLE
    pending*: DWORD
    completed*: bool
    read_buffer*: string  ## bytes
    write_buffer*: DWORD
  OverlappedObject* = ref OverlappedObjectObj

proc `=destroy`*(self: OverlappedObjectObj) =
  let err = getLastError()
  var bytes: DWORD
  if self.pending != 0:
    if cancelIoEx(self.handle, self.overlapped.addr) == 0 and
        getOverlappedResult(self.handle, self.overlapped.addr, bytes, 1) != 0:
      # The operation is no longer pending -- nothing to do
      discard
    #elif isFiniting
    else:
      #[The operation is still pending, but the process is
        probably about to exit, so we need not worry too much
        about memory leaks.  Leaking self prevents a potential
        crash.  This can happen when a daemon thread is cleaned
        up at exit -- see #19565.  We only expect to get here
        on Windows XP.]#
      discard closeHandle(self.handle)
      setLastError(err)
      return
  discard closeHandle(self.handle)
  setLastError(err)
  #if self.write_buffer != 0:
  #self.write_buffer.setLen(0)

proc getbuffer*(self: OverlappedObject): auto =
  if not self.completed:
    raise newException(ValueError, "can't get read buffer before GetOverlappedResult() " &
                        "signals the operation completed")
  self.read_buffer

proc cancel*(self: OverlappedObject) =
  var res: WINBOOL
  if self.pending == 0:
    res = cancelIoEx(self.handle, self.overlapped.addr)
  if res == 0 and getLastError() != ERROR_NOT_FOUND:
    raiseOSError(OSErrorCode(getLastError()))
  self.pending = 0

proc event*(self: OverlappedObject): HANDLE = self.overlapped.hEvent


proc newOverlapped*(handle: HANDLE): OverlappedObject =
  OverlappedObject(
    overlapped: winlean.OVERLAPPED(
      hEvent: cast[HANDLE](0)
    ),
    handle: handle,
    pending: 0,
  )


proc GetOverlappedResult*(self: OverlappedObject, wait: bool): tuple[transferred: DWORD, err: DWORD] =
  var transferred: DWORD
  let res = getOverlappedResult(self.handle, self.overlapped.addr, transferred, WINBOOL wait)
  let err = (if res != 0: DWORD ERROR_SUCCESS else: getLastError())
  case err
  of ERROR_SUCCESS, ERROR_MORE_DATA, ERROR_OPERATION_ABORTED:
    self.completed = true
    self.pending = 0
  of ERROR_IO_INCOMPLETE:
    discard
  else:
    self.pending = 0
    raiseOSError(OSErrorCode(err))
  if self.completed and self.read_buffer.len > 0:
    if transferred != self.read_buffer.len:
      self.read_buffer.setLen(transferred)
  return (transferred, err)

