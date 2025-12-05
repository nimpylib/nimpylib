
import std/[strutils, sequtils]
import ../../platform
import ../../unittest

using min_version: tuple[major, minor, micro: int]

proc requires_unix_version*(sysname: string, min_version: tuple[major, minor, micro: int]) =
  ## `__init__._requires_unix_version`
  let
    min_version_txt =
      $min_version.major & '.' &
      $min_version.minor & '.' &
      $min_version.micro
  let version_txt = platform.release().split('-', 1)[0]
  let skip = (
    if platform.system() == sysname:
      try:
        let version = version_txt.split('.').map(parseInt)
        # ```python version < min_version ```
        (case version.len:
          of 0: (0, 0, 0)
          of 1: (version[0], 0, 0)
          of 2: (version[0], version[1], 0)
          else: (version[0], version[1], version[2])
        ) < min_version
      except ValueError:
        false
    else: false
  )
  unittest.skipIf(
    skip,
    sysname & " version " & min_version_txt & " or higher is required, not " & version_txt
  )
