

when defined(windows):
  import ./util
  const
    IMS_WINDOWS_DESKTOP =
      from_c_int(HAVE_BUILTIN_AVAILABLE, 0):
        {.emit:  """/*INCLUDESECTION*/
        #include <winapifamily.h>
        """.}
        {.emit: """
        #if WINAPI_FAMILY_PARTITION(WINAPI_PARTITION_DESKTOP)
        #define MS_WINDOWS_DESKTOP 1
        #endif
        """.}
    MS_WINDOWS_DESKTOP* = bool IMS_WINDOWS_DESKTOP
else:
  const MS_WINDOWS_DESKTOP* = false
