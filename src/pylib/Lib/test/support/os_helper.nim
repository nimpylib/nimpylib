
from std/strutils import startsWith
import std/os as std_os
#import std/options
import ../../os
import ../../sys
import ../../time

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

type S = string
using filename: S

{.pragma: CbPragma, raises: [OSError], nimcall.}
type Cb = proc (filename: S){.CbPragma.}
template predeff(name; argname){.dirty.} =
  var `name Impl`: Cb
  template `asgn name`(impl){.dirty.} = `name Impl` = impl
  template `def name`(body){.dirty.} =
    proc `t name Impl`(argname: S){.CbPragma.} = body
    `asgn name` `t name Impl`

proc os_unlink(filename: S){.CbPragma.} =
  try: unlink(filename)
  except NotImplementedError as e: raise newException(OSError, "not impl arg", e)

predeff unlink, filename
if sys.platform.startswith("win"):
    proc waitfor(fun: Cb, pathname: string, waitall=false){.raises: [OSError].} =
        # Perform the operation
        fun(pathname)
        # Now setup the wait loop
        var name, dirname: string
        if waitall:
            dirname = pathname
        else:
            (dirname, name) = os.path.split(pathname)
            if dirname == "": dirname = "."
        # Check for `pathname` to be removed from the filesystem.
        # The exponential backoff of the timeout amounts to a total
        # of ~1 second after which the deletion is probably an error
        # anyway.
        # Testing on an i7@4.3GHz shows that usually only 1 iteration is
        # required when contention occurs.
        var timeout = 0.01
        while timeout < 1.000:
            # Note we are only testing for the existence of the file(s) in
            # the contents of the directory regardless of any security or
            # access rights.  If we have made it this far, we have sufficient
            # permissions to do that much using Python's equivalent of the
            # Windows API FindFirstFile.
            # Other Windows APIs can fail or give incorrect results when
            # dealing with files that are pending deletion.
            let L = os.listdir(dirname)
            if not (if waitall: len(L) > 0 else: name in L):
                return
            # Increase the timeout and try again
            try: time.sleep(timeout)
            except ValueError: doAssert false, "unreachable"
            timeout *= 2
        #[
        logging.getLogger("os_helper").warning(
            "tests may fail, delete still pending for %s",
            pathname,
            stack_info=True,
            stacklevel=4,
        )
        ]#
        echo "tests may fail, delete still pending for " & pathname

    defunlink:
        waitfor(
          os_unlink,
          filename
        )
else:
    asgnunlink os_unlink
    #_rmdir = os.rmdir

proc unlink*(filename) =
    try:
        unlinkImpl(filename)
    except FileNotFoundError, NotADirectoryError:
        discard

