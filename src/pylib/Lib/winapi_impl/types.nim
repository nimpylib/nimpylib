
{.push importc, header: "<Windows.h>".}
type
  DWORD* = uint32  ## unlike `winlean.DWORD`, this is unsigned
  WINBOOL* = enum
    FALSE = 0u32
    TRUE = 1u32
  HANDLE* = pointer
  LPPROC_THREAD_ATTRIBUTE_LIST* = pointer
  STARTUPINFOEX* = object
    StartupInfo*: STARTUPINFO
    lpAttributeList*: LPPROC_THREAD_ATTRIBUTE_LIST
  STARTUPINFO* = object
    dwFlags*: int
    wShowWindow*: int

{.pop.}
