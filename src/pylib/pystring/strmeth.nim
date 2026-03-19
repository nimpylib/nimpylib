
import std/unicode except split
import std/strutils except strip, split, rsplit

import ./strimpl
export strimpl  # for runnableExamples
import ./strip, ./split/[split, rsplit]
export strip, split, rsplit
import ../stringlib/meth
import ../version

import pkg/nimpatch/castChar

# str.format is in ./format

template `*`*(a: StringLike, i: int): PyStr =
  bind repeat
  a.repeat(i)
template `*`*(i: int, a: StringLike): PyStr =
  bind `*`
  a * i

func count*(a: PyStr, sub: PyStr): int =
  meth.count(a, sub)

func count*(a: PyStr, sub: PyStr, start: int): int =
  meth.count(a, sub, start)

func count*(a: PyStr, sub: PyStr, start=0, `end`: int): int =
  meth.count(a, sub, start, `end`)

func casefold*(a: PyStr): PyStr{.pysince(3,3).} =
  ## str.casefold()
  ##
  ## `str.lower()` is used for most characters, but, for example,
  ## Cherokee letters is casefolded to their uppercase counterparts,
  ## and some will be converted to their normal case, e.g. "ß" -> "ss"
  str meth.casefold toRunes a

func lower*(a: PyStr): PyStr =
  ## str.lower
  ## 
  ## not the same as Nim's `unicode.toLower`, see examples
  runnableExamples:
    import std/unicode
    let dotI = Rune 0x0130  # İ  (LATIN CAPITAL LETTER I WITH DOT ABOVE)
    assert str(dotI).lower() == "i\u0307"  ## i̇ (\u0207 is a upper dot)
    assert dotI.toLower() == Rune('i')
  str meth.toLower toRunes a

func upper*(a: PyStr): PyStr =
  ## str.upper
  ## 
  ## not the same as Nim's `unicode.toUpper`, see examples
  runnableExamples:
    import std/unicode
    let a = "ᾷ"
    # GREEK SMALL LETTER ALPHA WITH PERISPOMENI AND YPOGEGRAMMENI
    assert str(a).upper() == "Α͂Ι"  # 3 chars
    assert a.toUpper() == a   # Nim just maps it as-is.
    # There is more examples... (101 characters in total)
  str meth.toUpper toRunes a


func title*(a: PyStr): PyStr =
  ## str.title()
  ## 
  ## not the same as `title proc` in std/unicode, see example.
  runnableExamples:
    let s = "ǉ"  # \u01c9
    let u = str(s)
    assert u.title() == "ǈ"  # \u01c8
    import std/unicode
    assert unicode.title(s) == "Ǉ"  # \u01c7
  # currently titleImpl is ok for ascii only.
  #result.titleImpl a, isUpper, isLower, toUpper, toLower, runes, `+=`
  str meth.toTitle toRunes a


func capitalize*(a: PyStr): PyStr =
  ## make the first character have title/upper case and the rest lower case.
  ## 
  ## changed when Python 3.8: the first character will have title case.
  ## 
  ## while Nim's `unicode.capitalize` only make the first character upper-case.
  str meth.capitalize toRunes a


export strutils.startsWith, strutils.endsWith

template seWith(seWith){.dirty.} =
  func sewith*(a: PyStr, suffix: char): bool =
    meth.seWith(a, suffix)
  func sewith*(a: char, suffix: PyStr): bool =
    meth.seWith(a, suffix)
  func sewith*[Tup: tuple](a: PyStr, suffix: Tup): bool =
    meth.seWith(a, suffix)
  func sewith*[Suf: PyStr | tuple](a: PyStr, suffix: Suf, start: int): bool =
    meth.seWith(a, suffix, start)
  func sewith*[Suf: PyStr | tuple](a: PyStr, suffix: Suf,
      start, `end`: int): bool =
    meth.seWith(a, suffix, start, `end`)

seWith startsWith
seWith endsWith

func find*(a: PyStr, b: PyStr, start = 0, `end` = len(a)): int =
  if b.len == 1:
    meth.find1($a, $b, start, `end`)
  else:
    meth.find($a, $b, start, `end`)

func rfind*(a: PyStr, b: PyStr, start = 0, `end` = len(a)): int =
  if b.len == 1:
    meth.rfind1($a, $b, start, `end`)
  else:
    meth.rfind($a, $b, start, `end`)

func index*(a, b: PyStr, start = 0, `end` = len(a)): int =
  if b.len == 1:
    meth.index1($a, $b, start, `end`)
  else:
    meth.index($a, $b, start, `end`)

func rindex*(a, b: PyStr, start = 0, `end` = len(a)): int =
  if b.len == 1:
    meth.rindex1($a, $b, start, `end`)
  else:
    meth.rindex($a, $b, start, `end`)


template wrapBool(prc){.dirty.} =
  func prc*(a: PyStr): bool = meth.prc(toRunes a)

wrapBool isspace
wrapBool isalpha
wrapBool isdecimal
func isascii*(a: PyStr): bool{.pysince(3,7).} = meth.isascii(toRunes a)

wrapBool islower
wrapBool isupper
wrapBool istitle


func center*(a: PyStr, width: int, fillchar = ' '): PyStr =
  ## Mimics Python str.center(width: int, fillchar: str=" ") -> str
  meth.center(a, width, fillchar)

func ljust*(a: PyStr, width: int, fillchar = ' ' ): PyStr =
  meth.ljust a, width, fillchar
func rjust*(a: PyStr, width: int, fillchar = ' ' ): PyStr =
  meth.rjust a, width, fillchar

func center*(a: PyStr, width: int, fillchar: PyStr): PyStr =
  meth.center(a, width, fillchar)

func ljust*(a: PyStr, width: int, fillchar: PyStr): PyStr =
  meth.ljust(a, width, fillchar)
  
func rjust*(a: PyStr, width: int, fillchar: PyStr ): PyStr =
  meth.rjust(a, width, fillchar)

func zfill*(a: PyStr, width: int): PyStr =
  meth.zfill(a, width)

func removeprefix*(a: PyStr, suffix: PyStr): PyStr =
  meth.removeprefix(a, suffix)
func removesuffix*(a: PyStr, suffix: PyStr): PyStr =
  meth.removesuffix(a, suffix)

func replace*(a: PyStr, sub, by: PyStr|char): PyStr =
  meth.replace(a, sub, by)

func replace*(a: PyStr, sub, by: PyStr|char, count: int): PyStr =
  ## str.replace(sub, by, count = -1)
  ##
  ## count may be negative or zero.
  meth.replace(a, sub, by, count)

func expandtabs*(a: PyStr, tabsize=8): PyStr =
  str expandtabsImpl(a, tabsize, a.byteLen, runes)

func join*[T](sep: PyStr, a: openArray[T]): PyStr =
  ## Mimics Python join() -> string
  meth.join(sep, a)

template partitionImpl(partition): untyped =
  let res = meth.partition($a, $sep)
  (str res[0], str res[1], str res[2])

func partition*(a: PyStr, sep: PyStr): tuple[before, sep, after: PyStr] =
  partitionImpl partition

func rpartition*(a: PyStr, sep: PyStr): tuple[before, sep, after: PyStr] =
  partitionImpl rpartition
