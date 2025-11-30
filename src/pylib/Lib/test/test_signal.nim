
import ./import_utils
importPyLib signal
pyimport unittest
pyimport sys
pyimport os
pyimport errno
import std/unittest

var self = newTestCase()

proc trivial_signal_handler_impl(signalnum: PySignal) = discard

template trivial_signal_handler(self): untyped = trivial_signal_handler_impl


suite "PosixTests":
  skipIf(os.name == "nt", "Not valid on Windows"):
    #skipIf(PySignal is_not SomeInteger, "In Js, PySignal type is not SomeInteger"):
    test "out_of_range_signal_number_raises_error":
        const InvSignal = when defined(js): "4242" else: 4242
        self.assertRaises(ValueError, signal.getsignal, InvSignal)

        self.assertRaises(ValueError, signal.signal, InvSignal,
                          self.trivial_signal_handler)

        self.assertRaises(ValueError, signal.strsignal, InvSignal)

    test "setting_signal_handler_to_none_raises_error":
        self.assertRaises(TypeError, signal.signal,
                          signal.SIGUSR1, None)

    test "getsignal":
        let hup = signal.signal(signal.SIGHUP, self.trivial_signal_handler)
        #self.assertIsInstance(hup, signal.Handlers)
        #self.assertEqual(signal.getsignal(signal.SIGHUP),
        #                self.trivial_signal_handler)
        signal.signal(signal.SIGHUP, hup)
        self.assertEqual(signal.getsignal(signal.SIGHUP), hup)

    #test "no_repr_is_called_on_signal_handler":
        # See https://github.com/python/cpython/issues/112559.


    skipIf(sys.platform.startswith("netbsd"), "gh-124083: strsignal is not supported on NetBSD"):
      test "strsignal":
        self.assertIn("Interrupt", signal.strsignal(signal.SIGINT))
        self.assertIn("Terminated", signal.strsignal(signal.SIGTERM))
        self.assertIn("Hangup", signal.strsignal(signal.SIGHUP))


skipUnless hasattr(signal, "pidfd_send_signal"), "pidfd support not built in": test "pidfd_send_signal":
  try:
    signal.pidfd_send_signal(0, signal.SIGINT)
    fail()
  except OSError:
    let errno = getErrno()
    if errno == ENOSYS:
      self.skipTest "kernel does not support pidfds"
    elif errno == EPERM:
      self.skipTest "Not enough privileges to use pidfs"
    check errno == EBADF

  let my_pidfd = os.open("/proc/" & $os.getpid(), os.O_DIRECTORY)
  defer: os.close(my_pidfd)

  #expect TypeError:
  #  signal.pidfd_send_signal(my_pidfd, signal.SIGINT, newPyObject(), 0)
  #  check getCurrentExceptionMsg() == "siginfo must be None"


  expect KeyboardInterrupt:
    signal.pidfd_send_signal(my_pidfd, signal.SIGINT)
