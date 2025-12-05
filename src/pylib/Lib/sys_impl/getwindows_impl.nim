
import std/options
#import ../../Objects/structseq
import std/[os,
  winlean, widestrs
]
import ../../pyconfig/pc
when defined(windows):
  import ./getwindows/embed_rc
  {.link: FILENAME_TO_LINK.}

type
  WindowsError = OSError
  #TODO:namedtuple
  WindowsVersion = tuple[
    major, minor, build, platform: int, service_pack: string,
    service_pack_major, service_pack_minor, suite_mask, product_type: int,
    platform_version: WindowsVersionFromKernel32,
  ]
  WindowsVersionFromKernel32 = tuple[
    realMajor, realMinor, realBuild: int
  ]
#genNamedTuple TWindowsVersion


type
  WORD = uint16
  WCHAR{.importc, header: "<Windows.h>".} = Utf16Char
  OSVERSIONINFOEXW{.importc, header: "<Windows.h>"#["<winnt.h>"]#.} = object
    dwOSVersionInfoSize:DWORD
    dwMajorVersion:     DWORD
    dwMinorVersion:     DWORD
    dwBuildNumber:      DWORD
    dwPlatformId:       DWORD
    szCSDVersion:      array[128, WCHAR]
    wServicePackMajor: WORD
    wServicePackMinor: WORD
    wSuiteMask:        WORD
    wProductType:      BYTE
    wReserved:         BYTE

  VS_FIXEDFILEINFO{.importc, header: "<verrsrc.h>".} = object
   dwSignature,
    dwStrucVersion,
    dwFileVersionMS,
    dwFileVersionLS,
    dwProductVersionMS,
    dwProductVersionLS,
    dwFileFlagsMask,
    dwFileFlags,
    dwFileOS,
    dwFileType,
    dwFileSubtype,
    dwFileDateMS,
    dwFileDateLS: DWORD


proc sys_getwindowsversion_from_kernel32(): WindowsVersionFromKernel32 =
  ## `_getwindowsversion_from_kernel32`
#ifndef MS_WINDOWS_DESKTOP
  when not MS_WINDOWS_DESKTOP: #TODO: not defined(windows_desktop):
    # cannot read version info on non-Windows platforms
    raise newException(OSError, "cannot read version info on this platform")
  else:
    {.push header: "<Windows.h>".}
    proc GetModuleHandleW(lpModuleName: WideCString): HANDLE {.importc.}
    proc GetFileVersionInfoSizeW(lptstrFilename: WideCString, lpdwHandle: ptr DWORD): DWORD {.importc.}
    proc GetFileVersionInfoW(lptstrFilename: WideCString, dwHandle: DWORD, dwLen: DWORD, lpData: pointer): WINBOOL {.importc.}
    proc VerQueryValueW(pBlock: pointer, lpSubBlock: WideCString, lplpBuffer: ptr ptr VS_FIXEDFILEINFO, puLen: ptr uint32): WINBOOL {.importc.}
    {.pop.}

    var hKernel32 = default HANDLE
    var kernel32_path: array[MAX_PATH, WCHAR]
    var verblock_size: DWORD = 0
    var ffi: ptr VS_FIXEDFILEINFO = nil
    var ffi_len: uint32 = 0
    var realMajor, realMinor, realBuild: DWORD

    static: assert WideCString is ptr UncheckedArray[Utf16Char]
    # Get handle to kernel32.dll
    let kernName = newWideCString("kernel32.dll").toWideCString
    hKernel32 = GetModuleHandleW(kernName)
    let kernel32_path_p = cast[WideCString](kernel32_path[0].addr)
    if hKernel32 == default(HANDLE) or getModuleFileNameW(hKernel32, kernel32_path_p, MAX_PATH) == 0:
      raiseOSError(osLastError())

    verblock_size = GetFileVersionInfoSizeW(kernel32_path_p, nil)
    if verblock_size == 0:
      raiseOSError(osLastError())

    var verblock = alloc(verblock_size)
    defer: dealloc(verblock)

    let EMP_WS = newWideCString("").toWideCString

    if verblock.isNil or
       0 == GetFileVersionInfoW(kernel32_path_p, 0, verblock_size, verblock) or
       0 == VerQueryValueW(verblock, EMP_WS, ffi.addr, ffi_len.addr):
      raiseOSError(osLastError())

    # Extract version components
    let prodMS = ffi.dwProductVersionMS
    let prodLS = ffi.dwProductVersionLS
    realMajor = (prodMS shr 16) and 0xFFFF
    realMinor = prodMS and 0xFFFF
    realBuild = (prodLS shr 16) and 0xFFFF

    return (int(realMajor), int(realMinor), int(realBuild))


var cached_windows_version: Option[WindowsVersion]
var pos{.compileTime.} = 0
proc getwindowsversion*(): WindowsVersion =
    if cached_windows_version.isSome:
        return cached_windows_version.unsafeGet()

    var ver: OSVERSIONINFOEXW

    ver.dwOSVersionInfoSize = DWORD sizeof(ver)
    if 0.WINBOOL == getVersionExW(cast[ptr OSVERSIONINFO](ver.addr)):
        #return PyErr_SetFromWindowsErr(0)
        raiseOSError(osLastError())

    var version: WindowsVersion

    template SET_VERSION_INFO(CALL) =
        let item = CALL
        #if (item == NULL): goto_error
        version[pos] = item
        static: pos.inc

    template PyLong_FromLong(val: SomeInteger): untyped = int val
    template PyUnicode_FromWideChar(val, _): untyped =
      let ws = newWideCString(val.len)
      for i in 0 ..< val.len:
        ws[i] = val[i]
      $ws
    SET_VERSION_INFO(PyLong_FromLong(ver.dwMajorVersion));
    SET_VERSION_INFO(PyLong_FromLong(ver.dwMinorVersion));
    SET_VERSION_INFO(PyLong_FromLong(ver.dwBuildNumber));
    SET_VERSION_INFO(PyLong_FromLong(ver.dwPlatformId));
    SET_VERSION_INFO(PyUnicode_FromWideChar(ver.szCSDVersion, -1));
    SET_VERSION_INFO(PyLong_FromLong(ver.wServicePackMajor));
    SET_VERSION_INFO(PyLong_FromLong(ver.wServicePackMinor));
    SET_VERSION_INFO(PyLong_FromLong(ver.wSuiteMask));
    SET_VERSION_INFO(PyLong_FromLong(ver.wProductType));

    # GetVersion will lie if we are running in a compatibility mode.
    # We need to read the version info from a system file resource
    # to accurately identify the OS version. If we fail for any reason,
    # just return whatever GetVersion said.
    var realVersion: WindowsVersionFromKernel32
    try:
      realVersion = sys_getwindowsversion_from_kernel32()
    except WindowsError: discard
    if realVersion == default WindowsVersionFromKernel32:
      realVersion = (
          ver.dwMajorVersion,
          ver.dwMinorVersion,
          ver.dwBuildNumber
      )

    SET_VERSION_INFO(realVersion)

    cached_windows_version = some version

    return version

