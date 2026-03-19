
import ./[common, reimporter]
import std/strutils

template postdo*(split_name) =
  const name = astToStr(split_name)
  when name[0] == 'r':  # rsplit[_whitespace]
    result.reverse()

template strutils_split(s, sep, maxsplit): untyped =
  bind split
  split(s, sep, maxsplit)

template strutils_rsplit(s, sep, maxsplit): untyped =
  bind rsplit
  rsplit(s, sep, maxsplit)


template byteLen*(s: string): int = s.len
template byteLen*(c: char): int = 1

template proc_gen_split*(split; PyList; append){.dirty.} =
  bind postdo, noEmptySep
  bind norm_maxsplit, PREPARE_CAP
  bind strutils_split
  bind strutils_rsplit
  proc `split whitespace`*[S](pystr: S, maxsplit = -1): PyList[S] =
    let
      str_len = len(pystr)
      maxcount = norm_maxsplit(maxsplit, str_len)
    result = `new PyList OfCap`[S](PREPARE_CAP(maxcount))
    for i in pystr.`split whitespace impl`(str_len=str_len, maxsplit=maxcount):
      result.append i
    postdo split
  

  iterator `split NoCheck`(s: string, sep: char|string, maxsplit = -1): string{.inline.} =
    for i in `strutils split`(s, sep, maxsplit): yield i
  iterator `split NoCheck`(s: string, sep: not (string|char), maxsplit = -1): string{.inline.} =
    for i in `strutils split`(s, $sep, maxsplit): yield i

  iterator split*[S](a: S,
      sep: S|string|char, maxsplit = -1): S{.inline.} =
    noEmptySep sep
    for i in `split NoCheck`($a, sep, maxsplit): yield S i

  proc split*[S](a: S, maxsplit = -1): PyList[S] =
    a.`split whitespace`(maxsplit)

  # strutils.split func does not use any predicted capacity.

  proc split*[S](a: S, sep: S|string|char, maxsplit = -1): PyList[S] =
    template initRes[PyStr](maxcount) = 
      result = `new PyList OfCap`[PyStr](PREPARE_CAP maxcount)
    noEmptySep sep
    # CPython uses unicode len, here using byte-len shall be fine.
    let
      str_len = a.byteLen
      sep_len = sep.byteLen
    initRes[S](norm_maxsplit(maxsplit, str_len=str_len, sep_len=sep_len))
    for i in `split NoCheck`($a, sep, maxsplit): result.append i
    postdo split

