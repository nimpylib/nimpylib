## .. note:: global random state is indenpendent from Nim's std/random's
##
## .. note:: `random()` algorithm differs Python's,
##   meaning the same seed produces different result
## 
## TODO: PyRandom uses method; impl SysRandom
## TODO: commandLine pysince(3,13)

import std/options

import pkg/py_version
import pkg/py_constants/noneType
import pkg/py_commontypes/list
import pkg/pystrbytes_decl/bytesimpl
import pkg/collections_abc

import ./n_random
import pkg/pyrandom/macroutils

using self: PyRandom

export n_random except randbytes, choices, triangular

genGbls:
  proc seed*(self; _: NoneType) = self.seed()
  proc seed*(self; val: int64) = self.seed(some(val))

  func randbytes*(self; n: int): PyBytes{.pysince(3,9).} =
    bytes n_random.randbytes(self, n)

  func shuffle*[T](self; x: var PyList[T]) =
    n_random.shuffleImpl(self, x)

  func sample*[T](self; population: Sequence[T], k: int): PyList[T] =
    list n_random.sample(self, @population, k)

  func sample*[T](self; population: Sequence[T], k: int, counts: Sequence[T]): PyList[T]{.pysince(3,9).} =
    list n_random.sample(self, @population, k, @counts)

  func choice*[T](self; ls: Sequence[T]): T =
    if ls.len == 0:
      raise newException(IndexError, "Cannot choose from an empty sequence")

    ls[self.randint(0, len(ls))]

  func choices*[T](self; population: Sequence[T];
      weights: NoneType|Sequence[T] = None;
      cum_weights: NoneType|Sequence[T] = None;
      k=1): PyList[T] =
    when cum_weights is NoneType:
      let cum_weights = none(openArray[T])
      when weights is NoneType:
        let weights = cum_weights
    elif not (weights is NoneType):
      # when weights is_not NoneType and cum_weights is_not NoneType:
      {.error: "Cannot specify both weights and cumulative weights".}
    template `@`(x: Option): Option = x

    list n_random.choices(self, @population, @weights, @cum_weights, k=k)

  func triangular*[F: SomeFloat](self; low: F = 0.0, high: F = 1.0; mode: F|NoneType = None): F =
    when mode is NoneType: n_random.triangular(self, low, high)
    else: n_random.triangular(self, low, high, mode)
