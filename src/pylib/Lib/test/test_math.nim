## Given many funcs in math wraps std/math,
##  we only tests others

import ./import_utils
importPyLib math
importPyLib sys
pyimport unittest
from std/unittest import suiteStarted,  TestStatus, testStarted, suiteEnded, checkpoint, fail, TestResult,
  suite, test, check, expect
import std/options
import std/strformat

const
  NINF = NegInf
const
  # cached
  F_INF = Inf
  F_NINF = NegInf
  F_NAN = NaN

proc to_ulps(x: float): int64 =
  ##[Convert a non-NaN float x to an integer, in such a way that
  adjacent floats are converted to adjacent integers.  Then
  abs(ulps(x) - ulps(y)) gives the difference in ulps between two
  floats.

  The results from this function will only make sense on platforms
  where native doubles are represented in IEEE 754 binary64 format.

  Note: 0.0 and -0.0 are converted to 0 and -1, respectively.
  ]##
  result = cast[int64](x) #struct.unpack("<q", struct.pack("<d", x))[0]
  if result < 0:
      result = cast[int64](not (cast[uint64](result) + (1u64 shl 63)))

const None = none string
proc ulp_abs_check(expected, got: float, ulp_tol: int, abs_tol: float): Option[string] =
  ##[Given finite floats `expected` and `got`, check that they're
  approximately equal to within the given number of ulps or the
  given absolute tolerance, whichever is bigger.

  Returns None on success and an error message on failure.
  ]##
  let
    ulp_error = abs(to_ulps(expected) - to_ulps(got))
    abs_error = abs(expected - got)

  # Succeed if either abs_error <= abs_tol or ulp_error <= ulp_tol.
  if abs_error <= abs_tol or ulp_error <= ulp_tol:
      return None
  else:
      return some fmt("error = {abs_error:.3g} ({ulp_error} ulps); " &
             "permitted error = {abs_tol:.3g} or {ulp_tol} ulps")

template isinstance(e; T): bool = system.`is` e, system.T
proc result_check[T, U](expected: T, got: U, ulp_tol=5, abs_tol=0.0): Option[string] =
  # Common logic of MathTests.(ftest, test_testcases, test_mtestcases)
  ##[Compare arguments expected and got, as floats, if either
  is a float, using a tolerance expressed in multiples of
  ulp(expected) or absolutely (if given and greater).

  As a convenience, when neither argument is a float, and for
  non-finite floats, exact equality is demanded. Also, nan==nan
  as far as this function is concerned.

  Returns None on success and an error message on failure.
  ]##
  template pass = discard

  # Check exactly equal (applies also to strings representing exceptions)
  when system.`is`(T, U):
    if got == expected:
      when system.`is`(T, SomeFloat):
        if got == 0.0 and expected == 0.0:
          if math.copysign(1.0, got) != math.copysign(1.0, expected):
            return some fmt"expected {expected}, got {got} (zero has wrong sign)"
        return None

  var failure = some"not equal"

  # Turn mixed float and int comparison (e.g. floor()) to all-float
  when isinstance(expected, float) and isinstance(got, int):
    let got = float(got)
  elif isinstance(got, float) and isinstance(expected, int):
    let expected = float(expected)

  when isinstance(expected, float) and isinstance(got, float):
    if math.isnan(expected) and math.isnan(got):
      # Pass, since both nan
      failure = None
    elif math.isinf(expected) or math.isinf(got):
      # We already know they're not equal, drop through to failure
      pass
    else:
      # Both are finite floats (now). Are they close enough?
      failure = ulp_abs_check(expected, got, ulp_tol, abs_tol)

  # arguments are not equal, and if numeric, are too far apart
  if failure != None:
    var fail_msg = fmt"expected {repr(expected)}, got {repr(got)}"
    fail_msg &= fmt" ({failure})"
    return some fail_msg
  else:
    return None

proc ftest(self: auto, name: string, got: auto, expected: auto; ulp_tol=5, abs_tol=0.0) =
  ##[Compare arguments expected and got, as floats, if either
  is a float, using a tolerance expressed in multiples of
  ulp(expected) or absolutely, whichever is greater.

  As a convenience, when neither argument is a float, and for
  non-finite floats, exact equality is demanded. Also, nan==nan
  in this function.
  ]##
  let failure = result_check(expected, got, ulp_tol, abs_tol)
  if failure != None:
      let msg = fmt"{name}: {failure}"
      when nimvm: doAssert false, msg
      else: fail(msg)

template ftest(self: untyped, got, expected; ulp_tol=5, abs_tol=0.0) =
  self.ftest(astToStr(got), got, expected, ulp_tol, abs_tol)

suite "cbrt":
  test "cpython:test_math.testCbrt":
    template testCbrt =
      let self = newTestCase()
      self.ftest(math.cbrt(0.0), 0)
      self.ftest(math.cbrt(1.0), 1)
      self.ftest(math.cbrt(8.0), 2)
      self.ftest(math.cbrt(0.0), 0.0)
      self.ftest(math.cbrt(-0.0), -0.0)
      self.ftest(math.cbrt(1.2), 1.062658569182611)
      self.ftest(math.cbrt(-2.6), -1.375068867074141)
      self.ftest(math.cbrt(27.0), 3)
      self.ftest(math.cbrt(-1.0), -1)
      self.ftest(math.cbrt(-27.0), -3)
      assertEqual(math.cbrt(INF), INF)
      assertEqual(math.cbrt(NINF), NINF)
      assertTrue(math.isnan(math.cbrt(NAN)))
    testCbrt()
    static:
      testCbrt()


suite "gamma":
  test "gamma(-integer)":
    for i in (-1)..(-1000):
      check isnan gamma float i
      # XXX: TODO: PY-DIFF expect DomainError: discard gamma float i

suite "ldexp":
  proc test_call(): bool =
    let res = ldexp(1.5, 2)
    result = res == 6.0
    if not result:
      echo "ldexp(", 1.5, ", ", 2, "), expected ", 6.0, " got ", res
  check test_call()
  const res = test_call()
  check res

suite "sumprod":
  test "array":
    let a = [1,2,3]
    check 14.0 == sumprod(a,a)

  test "CPython:test_math.testSumProd":
    template sumprod(a, b): untyped = math.sumprod(a, b)
    def testSumProd():

#[ TODOL Decimal is not implemented (as of 0.9.3)
        Decimal = decimal.Decimal
        Fraction = fractions.Fraction
]#

        # Core functionality
        #assertEqual(sumprod(iter([10, 20, 30]), (1, 2, 3)), 140)
        assertEqual(sumprod([1.5, 2.5], [3.5, 4.5]), 16.5)
        empI = [0]
        assertEqual(sumprod(empI, empI), 0)
        assertEqual(sumprod([-1.0], [1.0]), -1)
        assertEqual(sumprod([1], [-1]), -1)


#[ : nim is static-typed
        # Type preservation and coercion
        for v in [
            (10, 20, 30),
            (1.5, -2.5),
            (Fraction(3, 5), Fraction(4, 5)),
            (Decimal(3.5), Decimal(4.5)),
            (2.5, 10),             # float/int
            (2.5, Fraction(3, 5)), # float/fraction
            (25, Fraction(3, 5)),  # int/fraction
            (25, Decimal(4.5)),    # int/decimal
        ]:
            for p, q in [(v, v), (v, v[::-1])]:
                with subTest(p=p, q=q):
                    expected = sum(p_i * q_i for p_i, q_i in zip(p, q, strict=True))
                    actual = sumprod(p, q)
                    assertEqual(expected, actual)
                    assertEqual(type(expected), type(actual))
]#

        # Bad arguments
        check not compiles(sumprod())               # No args
        check not compiles(sumprod([0]))           # One arg
        check not compiles(sumprod([0], [0], [0]))   # Three args
        check not compiles(sumprod(None, [10]))   # Non-iterable
        check not compiles(sumprod([10], None))   # Non-iterable
        check not compiles(sumprod(['x'], [1.0]))

        # Uneven lengths
        expect(ValueError): discard sumprod([10, 20], [30])
        expect(ValueError): discard sumprod([10], [20, 30])

        # Overflows
#[ : nim's int overflow
        assertEqual(sumprod([10**20], [1]), 10**20)
        assertEqual(sumprod([1], [10**20]), 10**20)

        assertRaises(OverflowError, sumprod, [10**1000], [1.0])
        assertRaises(OverflowError, sumprod, [1.0], [10**1000])
]#

        assertEqual(sumprod([10**3], [10**3]), 10**6)
  

# SYNTAX-BUG: assertEqual(sumprod([10**7]*10**5, [10**7]*10**5), 10**19)

#[ : static-typed
        type ARuntimeError = object of CatchableError
        # Error in iterator
        def raise_after(n):
            for i in range(n):
                yield i
            raise ARuntimeError
        with assertRaises(ARuntimeError):
            sumprod(range(10), raise_after(5))
        with assertRaises(ARuntimeError):
            sumprod(raise_after(5), range(10))
]#

#[
        from test.test_iter import BasicIterClass

        assertEqual(sumprod(BasicIterClass(1), [1]), 0)
        assertEqual(sumprod([1], BasicIterClass(1)), 0)
]#

#[ : static-typed TODO
        # Error in multiplication
        type
          MultiplyType = ref object of RootObj
          BadMultiplyType = object of BadMultiplyType

        method `*`(self: MultiplyType)
        func BadMultiply: BadMultiplyType = BadMultiplyType 0
        def `*`(self: BadMultiplyType, other):
          raise ARuntimeError
        def `*`(other: auto, self: BadMultiplyType):
          raise ARuntimeError
        expect (ARuntimeError):
            sumprod([10, BadMultiply(), 30], [1, 2, 3])
        expect (ARuntimeError):
            sumprod([1, 2, 3], [10, BadMultiply(), 30])
]#


        #[
        # Error in addition
        with assertRaises(TypeError):
            sumprod(['abc', 3], [5, 10])
        with assertRaises(TypeError):
            sumprod([5, 10], ['abc', 3])
        ]#

        # Special values should give the same as the pure python recipe
        assertEqual(sumprod([10.1, math.inf], [20.2, 30.3]), math.inf)
        assertEqual(sumprod([10.1, math.inf], [math.inf, 30.3]), math.inf)
        assertEqual(sumprod([10.1, math.inf], [math.inf, math.inf]), math.inf)
        assertEqual(sumprod([10.1, -math.inf], [20.2, 30.3]), -math.inf)
        assertTrue(math.isnan(sumprod([10.1, math.inf], [-math.inf, math.inf])))
        assertTrue(math.isnan(sumprod([10.1, math.nan], [20.2, 30.3])))
        assertTrue(math.isnan(sumprod([10.1, math.inf], [math.nan, 30.3])))
        assertTrue(math.isnan(sumprod([10.1, math.inf], [20.3, math.nan])))

#[ XXX: in nimpylib, result is -7.5 instead of 0.0
        # Error cases that arose during development
        assertEqual(
          sumprod( [-5.0, -5.0, 10.0], [1.5, 4611686018427387904.0, 2305843009213693952.0] ),
          0.0)
]#
    testSumProd()

suite "constants":
  test "nan":
    # `math.nan` must be a quiet NaN with positive sign bit
    check (isnan(math.nan))
    check (copysign(1.0, nan) == 1.0)
  test "inf":
    check:
      isinf(inf)
      inf > 0.0
      inf == F_INF
      -inf == F_NINF

suite "classify":
  # test "isnan": discard # isnan is alias of that in std/math
  test "isinf":
    check (isinf(F_INF))
    check (isinf(F_NINF))
    check (isinf(1E400))
    check (isinf(-1E400))
    check not (isinf(F_NAN))
    check not (isinf(0.0))
    check not (isinf(1.0))
  test "isfinite":
    check:
      isfinite(0.0)
      isfinite(-0.0)
      isfinite(1.0)
      isfinite(-1.0)
      not (isfinite(F_NAN))
      not (isfinite(F_INF))
      not (isfinite(F_NINF))

suite "nextafter_ulp":
  template assertEqualSign(a, b) =
    let
      sa = copysign(1.0, a)
      sb = copysign(1.0, b)
    check sa == sb
  template assertIsNaN(x) =
    check isnan(x)
  test "nextafter":
    #@requires_IEEE_754
    def test_nextafter():
        # around 2^52 and 2^63
        assertEqual(math.nextafter(4503599627370496.0, -INF),
                         4503599627370495.5)
        assertEqual(math.nextafter(4503599627370496.0, INF),
                         4503599627370497.0)
        assertEqual(math.nextafter(9223372036854775808.0, 0.0),
                         9223372036854774784.0)
        assertEqual(math.nextafter(-9223372036854775808.0, 0.0),
                         -9223372036854774784.0)

        # around 1.0
        assertEqual(math.nextafter(1.0, -INF),
                         float_fromhex("0x1.fffffffffffffp-1"))
        assertEqual(math.nextafter(1.0, INF),
                         float_fromhex("0x1.0000000000001p+0"))
        assertEqual(math.nextafter(1.0, -INF, steps=1),
                         float_fromhex("0x1.fffffffffffffp-1"))
        assertEqual(math.nextafter(1.0, INF, steps=1),
                         float_fromhex("0x1.0000000000001p+0"))
        assertEqual(math.nextafter(1.0, -INF, steps=3),
                         float_fromhex("0x1.ffffffffffffdp-1"))
        assertEqual(math.nextafter(1.0, INF, steps=3),
                         float_fromhex("0x1.0000000000003p+0"))

        # x == y: y is returned
        for steps in range(1, 5):
            assertEqual(math.nextafter(2.0, 2.0, steps=steps), 2.0)
            assertEqualSign(math.nextafter(-0.0, +0.0, steps=steps), +0.0)
            assertEqualSign(math.nextafter(+0.0, -0.0, steps=steps), -0.0)

        # around 0.0
        smallest_subnormal = sys.float_info.min * sys.float_info.epsilon
        assertEqual(math.nextafter(+0.0, INF), smallest_subnormal)
        assertEqual(math.nextafter(-0.0, INF), smallest_subnormal)
        assertEqual(math.nextafter(+0.0, -INF), -smallest_subnormal)
        assertEqual(math.nextafter(-0.0, -INF), -smallest_subnormal)
        assertEqualSign(math.nextafter(smallest_subnormal, +0.0), +0.0)
        assertEqualSign(math.nextafter(-smallest_subnormal, +0.0), -0.0)
        assertEqualSign(math.nextafter(smallest_subnormal, -0.0), +0.0)
        assertEqualSign(math.nextafter(-smallest_subnormal, -0.0), -0.0)

        # around infinity
        largest_normal = sys.float_info.max
        assertEqual(math.nextafter(INF, 0.0), largest_normal)
        assertEqual(math.nextafter(-INF, 0.0), -largest_normal)
        assertEqual(math.nextafter(largest_normal, INF), INF)
        assertEqual(math.nextafter(-largest_normal, -INF), -INF)

        # NaN
        assertIsNaN(math.nextafter(NAN, 1.0))
        assertIsNaN(math.nextafter(1.0, NAN))
        assertIsNaN(math.nextafter(NAN, NAN))

        assertEqual(1.0, math.nextafter(1.0, INF, steps=0))
        expect(ValueError):
            discard math.nextafter(1.0, INF, steps = -1)
    test_nextafter()
  test "ulp":
    const FLOAT_MAX = high float64
    #@requires_IEEE_754
    def test_ulp():
        assertEqual(math.ulp(1.0), sys.float_info.epsilon)
        # use int ** int rather than float ** int to not rely on pow() accuracy
        assertEqual(math.ulp(2.0 ** 52), 1.0)
        assertEqual(math.ulp(2.0 ** 53), 2.0)
        assertEqual(math.ulp(2.0 ** 64), 4096.0)

        # min and max
        assertEqual(math.ulp(0.0),
                         sys.float_info.min * sys.float_info.epsilon)
        assertEqual(math.ulp(FLOAT_MAX),
                         FLOAT_MAX - math.nextafter(FLOAT_MAX, -INF))

        # special cases
        assertEqual(math.ulp(INF), INF)
        assertIsNaN(math.ulp(math.nan))

        # negative number: ulp(-x) == ulp(x)
        for x in [0.0, 1.0, 2.0 ** 52, 2.0 ** 64, INF]:
            #with subTest(x=x):
                assertEqual(math.ulp(-x), math.ulp(x))
    test_ulp()

suite "ldexp":
  test "static":
    const f = ldexp(1.0, 2)
    static: assert f == 4.0, $f
  test "small":
    check:
      ldexp(0.0, 1) == 0
      ldexp(1.0, 1) == 2
      ldexp(1.0, -1) == 0.5
      ldexp(-1.0, 1) == -2
  test "non-normal first arg":
    check:
      ldexp(INF, 30) == INF
      ldexp(NINF, -213) == NINF
      isnan(ldexp(NAN, 0))
  test "large second arg":
    const si = sizeof(system.int)
    var ints: seq[float]
    if si == 1: discard
    if si >= 2: ints.add 1e5
    if si >= 4: ints.add 1e9  # 1e10 is bigger than int32.high
    if si >= 8: ints.add 1e18 # 1e20 is bigger than int64.high

    for f in ints:
      let n = int f
      check:
        ldexp(INF, -n) ==  INF
        ldexp(NINF, -n) ==  NINF
        ldexp(1.0, -n) == 0.0
        ldexp(-1.0, -n) == -0.0
        ldexp(0.0, -n) == 0.0
        ldexp(-0.0, -n) == -0.0
        isnan(math.ldexp(NAN, -n))
      expect OverflowDefect: discard ldexp(1.0, n)
      expect OverflowDefect: discard ldexp(-1.0, n)
      check:
        ldexp(0.0, n) == 0.0
        ldexp(-0.0, n) == -0.0
        ldexp(INF, n) == INF
        ldexp(NINF, n) == NINF
        isnan(ldexp(NAN, n))
