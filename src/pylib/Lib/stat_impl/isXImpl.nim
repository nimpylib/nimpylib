

import ./[types, defines]

const Js = defined(js)
when Js:
  import std/macros
  import ./consts
  macro S_IS2S_IF(id): untyped =
    var s = id.strVal
    s = s.substr(4, s.high)
    if s == "FIFO":
      ident "S_IFIFO"
    else:
      ident "S_IF" & s

proc int_AsMode_t*(value: int): Mode =
  if value == typeof(value).high:
    return Mode.high
  result = Mode(value)

template impChk(name) =
  when Js:
    proc `name`*(mode: Mode): bool =
      (mode.cint and S_IFMT_val) == S_IS2S_IF name
  else:
    proc `c name`(mode: Mode): cint{.importc: astToStr(name), header: SYS_STAT_H.}
    template `name`*(mode: Mode): bool = `c name`(mode) != 0

impChk S_ISDIR
impChk S_ISCHR
impChk S_ISREG

impChk S_ISBLK
impChk S_ISFIFO
impChk S_ISLNK
impChk S_ISSOCK


template S_ISDOOR*(mode: Mode): bool = false
template S_ISPORT*(mode: Mode): bool = false
template S_ISWHT*(mode: Mode): bool = false
