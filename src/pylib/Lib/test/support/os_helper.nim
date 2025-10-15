
import std/os as std_os
#import std/options
#import ../../os

const
  fn = "tempfiletest"
  TESTFN* = currentSourcePath().parentDir()/../fn

# XXX: if currentSourcePath is in a FS like exfat, chmod on it won't toggle exception,
#  but its mode just keeps unchanged
# TempDir is likely of tmpfs, which is chmod-able
let chmodTESTFN* = getHomeDir()/fn

#[
var b_can_chmod = none bool
proc can_chmod: bool =
  if not b_can_chmod.isNone:
    return b_can_chmod.unsafeGet
  when not declared(os.chmod):
    b_can_chmod = some false
    return
  else:
    try:
      var f = open(TESTFN, fmWrite)
      defer: f.close

      os.chmod(TESTFN, 0o555)
      let mode1 = os.stat(TESTFN).st_mode
      os.chmod(TESTFN, 0o777)
      let mode2 = os.stat(TESTFN).st_mode
]#

  

