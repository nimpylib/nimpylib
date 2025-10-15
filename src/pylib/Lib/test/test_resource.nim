

import ./import_utils
importPyLib resource
pyimport os
pyimport unittest
pyimport sys
pyimport time # sleep
#from std/os as std_os import nil
import std/unittest
import ./support/os_helper

var self = newTestCase()

const CAN_GET_RLIMIT_FSIZE = compiles(resource.getrlimit(resource.RLIMIT_FSIZE))
const CAN_GET_RLIMIT_CPU = compiles(resource.getrlimit(resource.RLIMIT_CPU))

suite "ResourceTests":
  var cur, max: int
  skipIf(sys.platform == "vxworks",
         "setting RLIMIT_FSIZE is not supported on VxWorks"): test "fsize_ismax":
    when CAN_GET_RLIMIT_FSIZE:
      (cur, max) = resource.getrlimit(resource.RLIMIT_FSIZE)
      #[RLIMIT_FSIZE should be RLIM_INFINITY, which will be a really big
number on a platform with large file support.  On these platforms,
we need to test that the get/setrlimit functions properly convert
the number to a C long long and that the conversion doesn't raise
an error.]#
      self.assertEqual(resource.RLIM_INFINITY, typeof(resource.RLIM_INFINITY)(max))
      resource.setrlimit(resource.RLIMIT_FSIZE, (cur, max))

  test "fsize_enforced":
    #def test_fsize_enforced(self):
        when compiles(resource.getrlimit(resource.RLIMIT_FSIZE)):
          (cur, max) = resource.getrlimit(resource.RLIMIT_FSIZE)
          # Check to see what happens when the RLIMIT_FSIZE is small.  Some
          # versions of Python were terminated by an uncaught SIGXFSZ, but
          # pythonrun.c has been fixed to ignore that exception.  If so, the
          # write() should return EFBIG when the limit is exceeded.

          # At least one platform has an unlimited RLIMIT_FSIZE and attempts
          # to change it raise ValueError instead.
          var limit_set = false
          try:
            try:
              resource.setrlimit(resource.RLIMIT_FSIZE, (1024, max))
              limit_set = true
            except ValueError:
              limit_set = false

            var f = open(os_helper.TESTFN, fmWrite)
            try:
              for _ in 1..1024:
                 f.write('X')
              try:
                f.write('Y')
                f.flushFile()
                # On some systems (e.g., Ubuntu on hppa) the flush()
                # doesn't always cause the exception, but the close()
                # does eventually.  Try flushing several times in
                # an attempt to ensure the file is really synced and
                # the exception raised.
                for i in 0..4:
                  time.sleep(0.1) # 100ms
                  f.flushFile()
              except OSError:
                if not limit_set:
                  raise
              if limit_set:
                # Close will attempt to flush the byte we wrote
                # Restore limit first to avoid getting a spurious error
                resource.setrlimit(resource.RLIMIT_FSIZE, (cur, max))
            finally:
              f.close()
          finally:
            if limit_set:
              resource.setrlimit(resource.RLIMIT_FSIZE, (cur, max))
            os_helper.unlink(os_helper.TESTFN)

  test "fsize_toobig":
    # Be sure that setrlimit is checking for really large values
    let too_big = high int  #10.float64.pow(50).int
    when CAN_GET_RLIMIT_FSIZE:
      let (_, max) = resource.getrlimit(resource.RLIMIT_FSIZE)
      try:
        resource.setrlimit(resource.RLIMIT_FSIZE, (too_big, max))
      except #[OverflowError, ]#ValueError:
        discard
      try:
        resource.setrlimit(resource.RLIMIT_FSIZE, (max, too_big))
      except #[OverflowError, ]#ValueError:
        discard

  skipUnless hasattr(resource, "getrusage"), "needs getrusage": test "getrusage":
    self.assertRaises(TypeError, resource.getrusage)
    
    {.push hint[XDeclaredButNotUsed]: off.}
    let
      _#[usageself]# = resource.getrusage(resource.RUSAGE_SELF)
      _#[usagechildren]# = resource.getrusage(resource.RUSAGE_CHILDREN)
    # May not be available on all systems.
    template t_may_fail(suffix) =
      when declared(resource.`RUSAGE suffix`):
        try:
          let `usage suffix` = resource.getrusage(resource.`RUSAGE suffix`)
        except ValueError#[, AttributeError]#:
          discard
    t_may_fail BOTH
    t_may_fail THREAD
    {.pop.}

  # Issue 6083: Reference counting bug
  skipIf sys.platform == "vxworks", "setting RLIMIT_CPU is not supported on VxWorks": test "setrusage_refcount":
    when CAN_GET_RLIMIT_CPU:
      let _#[limits]# = resource.getrlimit(resource.RLIMIT_CPU)
      type BadSequence = object
      proc len(self: BadSequence): int = 2
      proc `[]`(self: BadSequence, key: int): int =
        if key in [0, 1]:
          return len(0..<1_000_000)
        raise newException(IndexDefect, "")
      let s = BadSequence()
      resource.setrlimit(resource.RLIMIT_CPU, s)

  test "pagesize":
    let pagesize = resource.getpagesize()
    self.assertIsInstance(pagesize, int)
    self.assertGreaterEqual(pagesize, 0)

  #[ No need to test
  skipUnless sys.platform in ["linux", "android"], "Linux only": test "linux_constants":
    for attr in ["MSGQUEUE", "NICE", "RTPRIO", "RTTIME", "SIGPENDING"]:
      try:
        self.assertIsInstance(getattr(resource, "RLIMIT_" & attr), int)
      except AttributeError:
        discard

  test "freebsd_contants":
    for attr in ["SWAP", "SBSIZE", "NPTS"]:
      try:
        self.assertIsInstance(getattr(resource, "RLIMIT_" & attr), int)
      except AttributeError:
        discard
  ]#

#[ XXX: TODO: after os.uname() -> sys.platform() -> support.requires_linux_version()
  skipUnless hasattr(resource, "prlimit"), "no prlimit":
    skipUnless support.requires_linux_version(2, 6, 36):
      test "prlimit":
        self.assertRaises(TypeError, resource.prlimit)
        # TODO: ProcessLookupError is not defined in oserr
        #self.assertRaises(ProcessLookupError, resource.prlimit, -1, resource.RLIMIT_AS)
        let limit = resource.getrlimit(resource.RLIMIT_AS)
        self.assertEqual(resource.prlimit(0, resource.RLIMIT_AS), limit)
        self.assertEqual(resource.prlimit(0, resource.RLIMIT_AS, limit),
                       limit)

  ]#
  # Issue 20191: Reference counting bug
  skipUnless hasattr(resource, "prlimit"), "no prlimit":
    #skipUnless support.requires_linux_version(2, 6, 36):
      test "prlimit_refcount":
        type BadSeq = object
        proc len(self: BadSeq): int = 2

        let limits = resource.getrlimit(resource.RLIMIT_AS)
        let arrlimits = [limits[0], limits[1]]
        proc `[]`(self: BadSeq, key: int): int =
          return arrlimits[key] - 1  # new reference
        self.assertEqual(resource.prlimit(0, resource.RLIMIT_AS, BadSeq()),
                       limits)
