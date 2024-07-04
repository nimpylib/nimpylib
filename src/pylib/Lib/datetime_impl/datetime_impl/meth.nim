
import std/macros
import std/times
import ./decl
import ../timedelta_impl/decl
import ../timezone_impl/[
  decl, meth_by_datetime
]

macro getRangeStr(typ: typedesc): string =
  let tNode = typ.getType[1]
  let t =
    if tNode.typeKind == ntyEnum: tNode.getTypeInst
    # if use others other than getTypeInst for enum,
    # `ord` will always start with 0 (even for enum whose first item is 1-ord)
    else: tNode.getTypeImpl
  result = quote do:
    $`t`.low.ord & ".." & $`t`.high.ord

template raiseValueError(msg) =
    raise newException(ValueError, msg)

template chkSto(x: typed, aliasX: untyped; typ: typedesc) =
  var aliasX: typ
  try:
    aliasX = typ(x)
  except RangeDefect:
    raiseValueError(astToStr(x) & " must be in " & typ.getRangeStr)

func ltoUpper(c: char): char = chr(c.ord + 'A'.ord - 'a'.ord)
func ltoCap(s: string): string = s[0].ltoUpper & s.substr(1)

macro catRange(x): untyped =
  ident(x.strVal.ltoCap & "Range")

template chkSto(x: typed, aliasX: untyped) = chkSto(x, aliasX, catRange(x))

{.push warning[ProveInit]: off.}
# for MonthdayRange:
# when `except RangeDefect`, a exception is raised, so the routinue just stops 
# so this is safe.
proc datetime*(year, month, day: int,
  hour=0, minute=0, second=0, microsecond=0,
  tzinfo: tzinfo = nil, # *, fold=0
): datetime{.raises: [ValueError].} =
  runnableExamples:
    let dt = datetime(1900, 2, 28)
    echo repr dt
  chkSto month, mon, Month

  #chkSto day, d, MonthdayRange
  if day < 1 or day > getDaysInMonth(mon, year):
    raiseValueError "day is out of range for month"
  let d = MonthdayRange(day)

  chkSto hour, h
  chkSto minute, min
  chkSto second, s
  let nanosecond = microsecond * 1000
  chkSto nanosecond, ns
  
  result = newDatetime(times.dateTime(
    year, mon, d, h, min, s, ns, 
      zone = if tzinfo.isTzNone: local() else: tzinfo.toNimTimezone
  ), tzinfo)

{.pop.}


using self: datetime

const OneDayMs = convert(Days, Microseconds, 1)
template chkOneDay(delta: timedelta) =
  if abs(delta.inMicroseconds) > OneDayMs:
    raise newException(ValueError, "offset must be a timedelta" &
                         " strictly between -timedelta(hours=24) and" &
                         " timedelta(hours=24).")

func utcoffset*(self): timedelta =
  if self.tzinfo.isTzNone: return TimeDeltaNone
  result = self.tzinfo.utcoffset(self)
  result.chkOneDay()
func dst*(self): timedelta =
  if self.tzinfo.isTzNone: return TimeDeltaNone
  result = self.tzinfo.dst(self)
  result.chkOneDay()

proc `+`*(self; delta: timedelta): datetime =
  newDatetime(self.asNimDatetime + delta.asDuration)
