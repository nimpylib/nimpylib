
import ./import_utils
importTestPyLib os
from std/os as std_os import parentDir

suite "os":
  test "listdir":
    let d = currentSourcePath().parentDir()
    let ls = os.listdir(d)
    check "test_os.nim" in ls


