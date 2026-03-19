
type
  IsSpaceAt*[S] = proc (s: S, pos: int): bool{.nosideEffect.}

func `suf--`*(i: var int): int{.inline.} =
  ## `i--` in C
  result = i
  i.dec

const STRINGLIB_MUTABLE* = false  # XXX: What's this?
# in all of asciilib.h, ucs{1,2,4}lib.h, just define as `0`

# unicodeobject.c split L9876
template norm_maxsplit*(maxsplit: int, str_len): int =
  if maxsplit < 0: (str_len - 1) div 2 + 1
  else: maxsplit

# `PREALLOC_SIZE` (unicodeobject.c L17, used in L59) uses 12 as min len.
const DefSplitCap* = 12

# split.h PREALLOC_SIZE L17
template PREPARE_CAP*(maxcount): int =
  ## `maxcount` shall be Natural
  min(DefSplitCap, maxcount)

# unicodeobject.c L9907
func norm_maxsplit*(maxsplit: int, str_len, sep_len: int): int =
  if maxsplit < 0:
    result = if sep_len == 0: 0 else: (str_len div sep_len) + 1
    if result < 0: result = str_len

template postdo(split_name) =
  const name = astToStr(split_name)
  when name[0] == 'r':  # rsplit[_whitespace]
    result.reverse()

template proc_gen_split_whitespace*(split_name; Seq; append){.dirty.} =
  bind postdo
  bind norm_maxsplit, PREPARE_CAP
  proc split_name*[S](pystr: S, maxsplit = -1): Seq[S] =
    let
      str_len = len(pystr)
      maxcount = norm_maxsplit(maxsplit, str_len)
    result = `new Seq OfCap`[S](PREPARE_CAP(maxcount))
    for i in pystr.`split_name impl`(str_len=str_len, maxsplit=maxcount):
      result.append i
    postdo split_name
