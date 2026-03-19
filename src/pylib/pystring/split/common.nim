
import ../strimpl
export strimpl
import pkg/pystrutils/split/[common, gen]
import ../../stringlib/[splits, errHandle]
import ../consts

template common_split_whitespace(s, maxsplit): untyped =
  bind split_whitespace
  split_whitespace(s, maxsplit)

template common_rsplit_whitespae(s, maxsplit): untyped =
  bind rsplit_whitespace
  rsplit_whitespace(s, maxsplit)


func ISSPACE*(s: PyStr, pos: int): bool =
  ## Checks unicode space at unicode char's `pos`
  s.runeAtPos(pos) in unicodeSpaces

template proc_gen_split*(split, PyList, PyStr; append){.dirty.} =
  bind norm_maxsplit, PREPARE_CAP
  bind postdo, noEmptySep
  bind common_split_whitespace
  bind common_rsplit_whitespae
  iterator split*(a: PyStr, sep = None, maxsplit = -1): PyStr =
    ## with unicode whitespaces as sep.
    ## rsplit_whitespace
    ## treat runs of whitespaces as one sep (i.e.
    ##   discard empty strings from result),
    ## while Nim's `unicode.split(s)` doesn't
    ##
    for i in `common split whitespace`(a, maxsplit=maxsplit):
      yield i

  iterator splitNoCheck(s: string, sep: char|string, maxsplit = -1): PyStr{.inline.} =
    for i in strutils.split(s, sep, maxsplit): yield PyStr i
  iterator splitNoCheck(s: string, sep: PyStr, maxsplit = -1): PyStr{.inline.} =
    for i in strutils.split(s, $sep, maxsplit): yield PyStr i

  iterator split*(a: PyStr,
      sep: PyStr|string|char, maxsplit = -1): PyStr{.inline.} =
    noEmptySep sep
    for i in splitNoCheck($a, sep, maxsplit): yield i

  template retSeq(iter; maxsplit) = 
    result = `new PyList OfCap`[PyStr](PREPARE_CAP maxsplit)
  
    for i in iter: result.append i
    postdo split

  iterator `split whitespace`*(pystr: PyStr, maxsplit = -1): PyStr =
    for i in `common split whitespace`(pystr, maxsplit=maxsplit):
      yield i

  proc `split whitespace`*(pystr: PyStr, maxsplit = -1): PyList[PyStr] =  
    let str_len = pystr.byteLen
    retSeq `common split whitespace`(pystr, maxsplit), norm_maxsplit(maxsplit, str_len)

  proc split*(pystr: PyStr, sep = None, maxsplit = -1): PyList[PyStr] =
    `split whitespace`(pystr, maxsplit=maxsplit)

  # strutils.split func does not use any predicted capacity.

  template byteLen(s: string): int = s.len
  template byteLen(c: char): int = 1

  proc split*(a: PyStr, sep: PyStr|string|char, maxsplit = -1): PyList[PyStr] =
    noEmptySep sep
    # CPython uses unicode len, here using byte-len shall be fine.
    let
      str_len = a.byteLen
      sep_len = sep.byteLen
    retSeq splitNoCheck($a, sep, maxsplit), norm_maxsplit(maxsplit, str_len=str_len, sep_len=sep_len)

template gen_splitlines*(PyList; PyStr; append){.dirty.} =
  iterator splitlines*(self: PyStr, keepends = false): PyStr =
    for i in splitlines[PyStr](self, keepends):
      yield i
  proc splitlines*(self: PyStr, keepends=false): PyList[PyStr] =

    #[ From split.h splitlines L340
      /* This does not use the preallocated list because splitlines is
        usually run with hundreds of newlines.  The overhead of
        switching between PyList_SET_ITEM and append causes about a
        2-3% slowdown for that common case.  A smarter implementation
        could move the if check out, so the SET_ITEMs are done first
        and the appends only done when the prealloc buffer is full.
        That's too much work for little gain.*/]#
    result = `new PyList`[PyStr]()
    for i in splitlines(self, keepends=keepends):
      result.append i

template gen_splitlines*(PyStr){.dirty.} = gen_splitlines PyList, PyStr, append
