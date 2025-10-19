
# XXX:
#when (NimMajor, NimMajor, NimPatch) < (2, 3, 1): {.error: "".}

import pylib/builtins/[min_max
  ,list
  ,iters
  ,pytuple
]

import pylib/Lib/unittest

import std/sugar
from std/random as nim_random import nil
import std/tables

proc randrange(n: int): int = nim_random.rand 0..<n
proc neg(x: int): int = -x

template gen_key(): untyped =
  let
    data = collect:
      for i in 0..<100:
        randrange(200)
    keys = collect:
      for elem in data:
        {elem: randrange(50)}
    f = (x: int) => keys[x]
  (data, f)

const TupleCanPassAsIterable = false
when TupleCanPassAsIterable:
  template Tup(exp) = exp
else:
  template Tup(exp) = discard

proc test_max[T](self: T) =

        self.assertEqual(max("123123"), '3')
        self.assertEqual(max(1, 2, 3), 3)
        Tup: self.assertEqual(max((1, 2, 3, 1, 2, 3)), 3)
        self.assertEqual(max([1, 2, 3, 1, 2, 3]), 3)

        #[
        self.assertEqual(max(1, 2, 3.0), 3.0)
        self.assertEqual(max(1, 2.0, 3), 3)
        self.assertEqual(max(1.0, 2, 3), 3)
        ]#

        self.assertTrue( not compiles(max(42)) )

        #[ See ./min_max_rt_err
        with self.assertRaisesRegex(
            ValueError,
            r"max\(\) iterable argument is empty"
        ):
            max(())
        ]#

        #[ no need to test, and hard to test
        class BadSeq:
            def __getitem__(self, index):
                raise ValueError
        self.assertRaises(ValueError, max, BadSeq())
        ]#

        #[
        for stmt in [
            "max(key=int)",                 # no args
            "max(default=None)",
            "max(1, 2, default=None)",      # require container for default
            "max(default=None, key=int)",
            "max(1, key=int)",              # single arg not iterable
            "max(1, 2, keystone=int)",      # wrong keyword
            "max(1, 2, key=int, abc=int)",  # two many keywords
            "max(1, 2, key=1)",             # keyfunc is not callable
        ]:
            try:
                exec(stmt, globals())
            except TypeError:
                pass
            else:
                self.fail(stmt)
        ]#

        self.assertEqual(max([1,], key=neg), 1)     # one elem iterable
        self.assertEqual(max([1,2], key=neg), 1)    # two elem iterable
        self.assertEqual(max(1, 2, key=neg), 1)     # two elems

        #self.assertEqual(max((), default=None), None)    # zero elem iterable
        #self.assertEqual(max((1,), default=None), 1)     # one elem iterable
        #self.assertEqual(max((1,2), default=None), 2)    # two elem iterable

        #self.assertEqual(max((), default=1, key=neg), 1)
        self.assertEqual(max([1, 2], default=3, key=neg), 1)

        self.assertEqual(max([1, 2], key=None), 2)

        let (data, f) = gen_key()
        self.assertEqual(max(data, key=f),
                         sorted(reversed(data), key=f)[^1])

proc test_min[T](self: T) =
        self.assertEqual(min("123123"), '1')
        self.assertEqual(min(1, 2, 3), 1)
        Tup: self.assertEqual(min((1, 2, 3, 1, 2, 3)), 1)
        self.assertEqual(min([1, 2, 3, 1, 2, 3]), 1)

        #[
        self.assertEqual(min(1, 2, 3.0), 1)
        self.assertEqual(min(1, 2.0, 3), 1)
        self.assertEqual(min(1.0, 2, 3), 1.0)
        ]#

        self.assertTrue not compiles min()

        #[ See ./min_max_ct_err
        with self.assertRaisesRegex(
            TypeError,
            "min expected at least 1 argument, got 0"
        ):
            min()
        ]#

        self.assertTrue not compiles(min(42))
        #self.assertRaises(TypeError, min, 42)

        #[ See ./min_max_rt_err
        with self.assertRaisesRegex(
            ValueError,
            r"min\(\) iterable argument is empty"
        ):
            min(())
        ]#

        #[ no need to test, and hard to test
        class BadSeq:
            def __getitem__(self, index):
                raise ValueError
        self.assertRaises(ValueError, min, BadSeq())
        ]#

        #[
        for stmt in [
            "min(key=int)",                 # no args
            "min(default=None)",
            "min(1, 2, default=None)",      # require container for default
            "min(default=None, key=int)",
            "min(1, key=int)",              # single arg not iterable
            "min(1, 2, keystone=int)",      # wrong keyword
            "min(1, 2, key=int, abc=int)",  # two many keywords
            "min(1, 2, key=1)",             # keyfunc is not callable
          ]:

            try:
                exec(stmt, globals())
            except TypeError:
                pass
            else:
                self.fail(stmt)
        ]#

        self.assertEqual(min([1,], key=neg), 1)     # one elem iterable
        self.assertEqual(min([1,2], key=neg), 2)    # two elem iterable
        self.assertEqual(min(1, 2, key=neg), 2)     # two elems

        #self.assertEqual(min((), default=None), None)    # zero elem iterable
        #self.assertEqual(min((1,), default=None), 1)     # one elem iterable
        #self.assertEqual(min((1,2), default=None), 1)    # two elem iterable

        #self.assertEqual(min((), default=1, key=neg), 1)
        self.assertEqual(min([1, 2], default=1, key=neg), 2)

        self.assertEqual(min([1, 2], key=None), 1)

        let (data, f) = gen_key()
        self.assertEqual(min(data, key=f),
                         sorted(data, key=f)[0])


var e: TestCase
e.test_max()
e.test_min()
