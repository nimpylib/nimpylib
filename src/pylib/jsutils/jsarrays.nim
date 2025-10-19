
import std/jsffi
import ../private/idxChkUtils

type JsArray*[T] = distinct JsObject#JsAssoc[int, T]

proc newJsArray*[T]: JsArray[T]{.importjs: "[@]".}
proc add*[T](arr: JsArray[T]; x: T){.importcpp: "push".}
proc newJsArray*[T](x: openArray[T]): JsArray[T] =
  result = newJsArray[T]()
  for i in x: result.add i

using arr: JsArray
proc len*(arr): int{.importjs: "#.length".}
proc high*(arr): int = arr.len - 1
proc toString*(arr): cstring{.importcpp.}
proc `$`*(arr): string =
  result.add '['
  let L = arr.len
  if L > 0:
    result.add $arr[0]
    for i in 1..<L:
      result.add ", "
      result.add $arr[i]
  result.add ']'


proc contains*[T](arr: JsArray[T]; x: T): bool{.importcpp: "includes".}
proc `[]`*[T](arr: JsArray[T]; i: int): T{.importcpp: "#[#]", wrapChkIdx.}
proc `[]=`*[T](arr: JsArray[T]; i: int; x : T){.importcpp: "#[#] = #", wrapChkIdx.}
proc pop*[T](arr: JsArray[T]): T{.importcpp, wrapChkIdx(0).}
proc delete*(arr: JsArray; i: int) {.importjs: "#.splice(#, 1)", wrapChkIdx.}
proc del*(arr: JsArray; i: int) =
  arr.chkIdx i
  discard jsDelete arr[i]
  if arr.len > 0:
    `[]= unchkIdx`(arr, i, arr.pop())
proc `[]`*[T](arr: JsArray[T]; i: BackwardsIndex): T = arr[arr.len-int(i)]
proc `[]=`*[T](arr: JsArray[T]; i: BackwardsIndex; x: T) = arr[arr.len-int(i)] = x

iterator items*[T](arr: JsArray[T]): T =
  for i in cast[JsObject](arr): yield i.to T
iterator pairs*[T](arr: JsArray[T]): (int, T) =
  var i = 0
  for e in arr:
    yield (i, e)
    i.inc

proc `==`*[T](a, b: JsArray[T]): bool =
  if a.len != b.len: return
  for i, e in a:
    if e != b[i]: return
  return true

proc `@`*[T](arr: JsArray[T]): seq[T] =
  result = (when declared(newSeqUninit): newSeqUninit else: newSeq)[T](arr.len)
  for i, e in arr:
    result[i] = e

when isMainModule:
  let oriData = [1, 2, 3, 4]
  let a = newJsArray[int](oriData)

  import std/sequtils

  assert a == newJsArray[int](toSeq 1..4)
  assert @a == @oriData
  a[0] = 10
  assert a[0] == 10
  assert 2 in a
  assert @a == @[10, 2, 3, 4]
  a.del 0
  assert @a == @[4, 2, 3]
  a.delete 0
  var ls: seq[int]
  for e in a: ls.add e
  assert ls == @[2, 3]
  assert @a == ls

