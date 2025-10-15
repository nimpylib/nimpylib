
import std/strutils except rsplit, split, strip
import ./bytesimpl
import ./strip, ./split/[split, rsplit]
export strip, split, rsplit
import ../stringlib/meth
import ../version
import ../nimpatch/castChar

template `*`*(a: PyBytes; i: int): PyBytes =
  bind repeat, PyBytes
  PyBytes repeat($a, i)
template `*`*(i: int, a: PyBytes): PyBytes =
  bind `*`
  a * i

func count*(a: PyBytes, sub: PyBytes): int =
  meth.count(a, sub)

func count*(a: PyBytes, sub: PyBytes, start: int): int =
  meth.count(a, sub, start)

func count*(a: PyBytes, sub: PyBytes, start=0, `end`: int): int =
  meth.count(a, sub, start, `end`)

template chkChr(i): char =
  if i not_in 0..256:
    raise newException(ValueError, "ValueError: byte must be in range(0, 256)")
  castChar(i)
func count*(a: PyBytes, sub: int): int = count($a, chkChr sub)
func count*(a: PyBytes, sub: int, start: int): int =
  count(($a)[start..^1], chkChr sub)
func count*(a: PyBytes, sub: int, start=0, `end`: int): int =
  count(($a)[start..^`end`], chkChr sub)

template casefold*(a: PyBytes): PyBytes =
  bind pybytes
  pybytes strutils.toLowerAscii(a)
  
func lower*(a: PyBytes): PyBytes = pybytes toLowerAscii $a
func upper*(a: PyBytes): PyBytes = pybytes toUpperAscii $a

template titleImpl(result; s, isupper, islower, upper, lower, iter, adder) =
  var previous_is_cased = false
  for c in s.iter:
    var nc: typeof(c)
    if islower(c):
      if not previous_is_cased:
        nc = upper(c)
      previous_is_cased = true
    elif isupper(c):
      if previous_is_cased:
        nc = lower(c)
      previous_is_cased = true
    else:
      previous_is_cased = false
    result.adder nc

func title*(a: PyBytes): PyBytes =
  result.titleImpl a, isUpperAscii, isLowerAscii,
      toUpperAscii, toLowerAscii, chars, `+=`

func capitalize*(a: PyBytes): PyBytes =
  ## make the first character have upper case and the rest lower case.
  ## 
  if len(a) == 0:
    return pybytes ""
  result = a.getChar(0).toUpperAscii() + substr(a, 1).lower()

template seWith(seWith){.dirty.} =
  func sewith*(a: PyBytes, suffix: char): bool =
    meth.seWith(a, suffix)
  func sewith*(a: PyBytes, suffix: int): bool =
    meth.seWith(a, chkChr suffix)
  func sewith*[Tup: tuple](a: PyBytes, suffix: Tup): bool =
    meth.seWith(a, suffix)
  func sewith*[Suf: PyBytes | tuple](a: PyBytes, suffix: Suf, start: int): bool =
    meth.seWith(a, suffix, start)
  func sewith*[Suf: PyBytes | tuple](a: PyBytes, suffix: Suf,
      start, `end`: int): bool =
    meth.seWith(a, suffix, start, `end`)

seWith startsWith
seWith endsWith

func find*(a: PyBytes, b: int, start = 0, `end` = len(a)): int =
  meth.find1(a, b, start, `end`)

func rfind*(a: PyBytes, b: int, start = 0, `end` = len(a)): int =
  meth.rfind1(a, b, start, `end`)

func index*(a: PyBytes, b: int, start = 0, `end` = len(a)): int =
  meth.index1(a, b, start)

func rindex*(a: PyBytes, b: int, start = 0, `end` = len(a)): int =
  meth.rindex1(a, b, start, `end`)


func find*(a: PyBytes, b: PyBytes, start = 0, `end` = len(a)): int =
  meth.find(a, b, start, `end`)

func rfind*(a: PyBytes, b: PyBytes, start = 0, `end` = len(a)): int =
  meth.rfind(a, b, start, `end`)

func index*(a: PyBytes, b: PyBytes, start = 0, `end` = len(a)): int =
  meth.index(a, b, start)

func rindex*(a: PyBytes, b: PyBytes, start = 0, `end` = len(a)): int =
  meth.rindex(a, b, start, `end`)

func contains*(a: PyBytes, o: PyBytes): bool{.borrow.}
func contains*(a: PyBytes, o: int): bool = a.find(o) != -1

template W(isX) =
  func isX*(a: PyBytes): bool = meth.isX($a)

func isascii*(a: PyBytes): bool{.pysince(3,7).} = meth.isascii($a)
W isspace
W isalpha
W isdigit

template firstChar(s: PyBytes): char = s.getChar 0
template bytesAllAlpha(s: PyBytes, isWhat, notWhat): untyped =
  s.allAlpha isWhat, notWhat, chars, firstChar
func islower*(a: PyBytes): bool = a.bytesAllAlpha isLowerAscii, isUpperAscii
func isupper*(a: PyBytes): bool = a.bytesAllAlpha isUpperAscii, isLowerAscii
func istitle*(a: PyBytes): bool =
  a.istitleImpl isUpperAscii, isLowerAscii, chars, firstChar

func center*(a: PyBytes, width: int, fillchar = ' '): PyBytes =
  ## Mimics Python bytes.center(width: int, fillchar = b" ") -> bytes
  pybytes meth.center(a, width, fillchar)

func ljust*(a: PyBytes, width: int, fillchar = ' ' ): PyBytes =
  pybytes meth.ljust(a, width, fillchar)
func rjust*(a: PyBytes, width: int, fillchar = ' ' ): PyBytes =
  pybytes meth.rjust(a, width, fillchar)

func center*(a: PyBytes, width: int, fillchar: PyBytes): PyBytes =
  meth.center(a, width, fillchar)

func ljust*(a: PyBytes, width: int, fillchar: PyBytes): PyBytes =
  meth.ljust(a, width, fillchar)
  
func rjust*(a: PyBytes, width: int, fillchar: PyBytes ): PyBytes =
  meth.rjust(a, width, fillchar)

func zfill*(a: PyBytes, width: int): PyBytes =
  PyBytes meth.zfill($a, width)

func removeprefix*(a: PyBytes, suffix: PyBytes): PyBytes =
  meth.removeprefix(a, suffix)
func removesuffix*(a: PyBytes, suffix: PyBytes): PyBytes =
  meth.removesuffix(a, suffix)

func replace*(a: PyBytes, sub, by: PyBytes|char): PyBytes =
  meth.replace(a, sub, by)

func replace*(a: PyBytes, sub, by: PyBytes|char, count: int): PyBytes =
  ## bytes.replace(sub, by, count = -1)'
  ##
  ## count may be negative or zero.
  meth.replace(a, sub, by, count)

func expandtabs*(a: PyBytes, tabsize=8): PyBytes =
  bytes expandtabsImpl(a, tabsize, a.len, chars)

func join*[T](sep: PyBytes, a: openArray[T]): PyBytes =
  ## Mimics Python join() -> bytes
  meth.join(sep, a)

func partition*(a: PyBytes, sep: PyBytes): tuple[before, sep, after: PyBytes] =
  meth.partition(a, sep)

func rpartition*(a: PyBytes, sep: PyBytes): tuple[before, sep, after: PyBytes] =
  meth.rpartition(a, sep)


