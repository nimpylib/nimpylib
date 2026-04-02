
import std/unittest
import std/strformat
import pkg/float_utils/round_float
import ./[types, util]

when defined(nimPreviewSlimSystem):
  import std/floatformat

template failureException(_; msg) =
  block:
    #`pragmaBlock`
    checkpoint(`msg`)
    #`printOuts`
    fail()

const None = ""
proc assertAlmostEqualImpl[T](self: TestCase; first, second: T, places_or_delta: auto, msg=None; op: auto; opS: string) =
  ##[Fail if the two objects are unequal as determined by their
     difference rounded to the given number of decimal places
     (default 7) and comparing to zero, or by comparing that the
     difference between the two objects is more than the given
     delta.

     Note that decimal places (from zero) are usually not the same
     as significant digits (measured from the most significant digit).

     If the two objects compare equal then they will automatically
     compare almost equal.
  ]##
  if op(first == second):
    # shortcut
    return

  let diff = abs(first - second)
  let x = when places_or_delta is T:
    let delta = places_or_delta
    if op(diff <= delta):
      return

    fmt"{delta} delta"
  else:
    let places = places_or_delta
    if op(round(diff, places) == 0):
      return

    fmt"{places} places"

  let standardMsg = fmt"{first} {opS} {second} within {x} ({diff} difference)"
  let tmsg = self.formatMessage(msg, standardMsg)
  self.failureException(tmsg)

template gen(assertAlmostEqual, op, opS){.dirty.} =
  proc assertAlmostEqual*[T: not SomeInteger](first, second: T, places=7, msg=None){.genSelf.} =
    when not declared(self):
      let self = newTestCase()
    self.`assertAlmostEqual Impl`(first, second, places, msg, op, opS)
  proc assertAlmostEqual*[T: not SomeInteger](first, second: T, delta: T, msg=None){.genSelf.} =
    when not declared(self):
      let self = newTestCase()
    self.`assertAlmostEqual Impl`(first, second, delta, msg, op, opS)

func asIs(x: bool): bool{.inline.} = x
gen assertAlmostEqual, asIs, "=="
gen assertNotAlmostEqual, `not`, "!="

