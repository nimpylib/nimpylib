
type
  Cleanup = proc ()
  TestCase* = ref object of RootObj
    longMessage*: bool
    `private.testMethodName`*: string
    `private.cleanups`*: seq[Cleanup]

func newTestCase*(methodName="runTest"): TestCase =
  result = TestCase()
  result.`private.testMethodName` = methodName


template isNone(s: string): bool = s.len == 0
proc formatMessage*(self: TestCase, msg, standardMsg: string): string =
  ## `_formatMessage`
  if not self.longMessage:
    return if msg.isNone: standardMsg else: msg
  if msg.isNone:
    return standardMsg
  standardMsg & " : " & msg
  # try:
    # don't switch to '{}' formatting in Python 2.X
    # it changes the way unicode input is handled
    # return '%s : %s' % (standardMsg, msg)
  # except UnicodeDecodeError:
  #   return  '%s : %s' % (safe_repr(standardMsg), safe_repr(msg))
