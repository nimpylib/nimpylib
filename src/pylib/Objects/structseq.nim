## minic CPython's structseq

import std/macros
import std/macrocache
export macros.NimTypeKind, macros.parseExpr

type MapCTypeToNim = CacheTable
using
  self: MapCTypeToNim
  key: NimTypeKind

proc contains*(self; key): bool = self.contains $key
proc `[]`*(self; key): NimNode = self[$key]
proc `[]=`*(self; key; val: NimNode) = self[$key] = val

proc `[]`*(self; key: NimNode): NimNode =
  let t = key.typeKind
  if self.contains t: self[t]
  else: key

template declMapCTypeToNimImpl(mapCTypeToNim; uniqueId: string; additionDo){.dirty.} =
  ## XXX: (due to Nim's CacheTable lacks `del` method)
  ##   so this template exists to dup a new one
  bind CacheTable, `[]`, `[]=`, bindSym
  bind NimTypeKind
  const mapCTypeToNim = CacheTable uniqueId
  static:
    template m(x: NimTypeKind, v: NimNode) =
      mapCTypeToNim[x] = v
    template m(x: NimTypeKind, v: string) =
      m x, bindSym v
    template m(x: Slice, v) =
      for i in x: m i, v
    m ntyInt..ntyInt64: "BiggestInt"
    m ntyUInt..ntyUInt64: "BiggestUInt"
    m ntyFloat..ntyFloat64: "BiggestFloat"
    m ntyCString: "string"
    additionDo

macro declMapCTypeToNim*(mapCTypeToNim; uniqueId = astToStr(mapCTypeToNim);
                            additionalMaps) =
  result = newCall(bindSym"declMapCTypeToNimImpl", mapCTypeToNim, uniqueId)
  let lastArg = newStmtList()
  for kv in additionalMaps:
    let (k, v) = (kv[0], kv[1])
    let resV = newLit v.repr
    lastArg.add quote do: m `k`, parseExpr `resV`
  result.add lastArg

template declMapCTypeToNim*(mapCTypeToNim; uniqueId = astToStr(mapCTypeToNim)){.dirty.} =
  declMapCTypeToNimImpl(mapCTypeToNim, uniqueId): discard

declMapCTypeToNim mapCTypeToNim, "structseq.default.mapCTypeToNim"

template directToPyNim(Tsrc, Tdst){.dirty.} =
  template toPyNim*(i: Tsrc; res: var Tdst) = res = i
directToPyNim SomeSignedInt, BiggestInt
directToPyNim SomeUnsignedInt,BiggestUInt
directToPyNim SomeFloat, BiggestFloat
template toPyNim*(s: cstring; res: var string) = res = $s

proc oneElement(collection: NimNode, kind: NimNodeKind): NimNode =
  collection.expectKind kind
  collection.expectLen 1
  collection[0]

proc unpackExportedAsStr(node: NimNode): (string, bool) =
  if node.kind == nnkPostfix and node[0].eqIdent"*":
    (node[1].strVal, true)
  else:
    (node.strVal, false)

proc cstructGenNamedTupleImpl(cT: NimNode,
    exported: bool, # proc(x: NimNode): NimNode,
    genName: string, fieldList: NimNode = nil, mapCTypeToNimTab = mapCTypeToNim): NimNode =
  result = newStmtList()
  let nT = ident genName

  let mayExp = if exported:
    proc (x: NimNode): NimNode = x.postfix"*"
  else:
    proc (x: NimNode): NimNode = x
  let cTImpl = getTypeImpl(cT)
  assert cTImpl.typeKind == ntyObject
  assert cTImpl[0].kind == nnkEmpty
  assert cTImpl[1].kind == nnkEmpty
  template fieldsGivenOr(ifExpr, orExpr): untyped =
    if fieldList.isNil: ifExpr
    else: orExpr

  let targetFieldList = fieldsGivenOr(cTImpl[2], fieldList)
  targetFieldList.expectKind nnkRecList

  let
    resultId = ident"result"
    toNimId = ident"toPyNim"
    toNimDefId = ident"toPyNim".mayExp
    dollarId = ident"$".mayExp
    getitemId = ident"[]".mayExp
    cParam = ident"cObj"
    nParam = ident"nObj"
  var
    toNimBody = newStmtList quote do: result = `nT`()
    dollarBody = newStmtList quote do:
      result = `genName`

  template asgnToNim(dest, src, attr): NimNode{.dirty.} =
    quote do: `toNimId`(`src`.`attr`, `dest`.`attr`)

  let emptyn = newEmptyNode()
  var fields = newNimNode nnkRecList
  var fieldListValue = newNimNode nnkBracket
  var preStr = "("
  for oriFDef in targetFieldList:
    # oriFDef.kind == nnkIdentDefs
    let fDef = oriFDef.copyNimNode
    for idxInIdentDef in 0..<oriFDef.len-2:
      let (fieldName, _) = oriFDef[idxInIdentDef].unpackExportedAsStr
      let fStrVal = fieldName
      let fStr = newLit fStrVal
      let f = ident fStrVal  # purge symbol type info
      fDef.add f.mayExp
      toNimBody.add asgnToNim(resultId, cParam, f)
      fieldListValue.add fStr
      dollarBody.add quote do:
        result.add `preStr`
        result.add `fStr`
        result.add '='
        result.add repr `nParam`.`f`

      preStr = ", "
    var targetType = oriFDef[^2]
    fDef.add fieldsGivenOr(mapCTypeToNimTab[targetType], targetType)
    fDef.add oriFDef.last
    fields.add fDef
  dollarBody.add quote do: result.add ')'

  let nTobjDef = nnkRefTy.newTree nnkObjectTy.newTree(emptyn, emptyn, fields)
  let nTypeDef = quote do:
    type `nT`* = `nTobjDef`
  result.add nTypeDef
  result.add quote do:
    proc `toNimDefId`(`cParam`: sink `cT`; `resultId`: var `nT`) = `toNimBody`
    proc `toNimDefId`(`cParam`: ptr`cT`; `resultId`: var `nT`){.inline.} = `cParam`[].`toNimId` `resultId`
    proc `dollarId`(`nParam`: `nT`): string = `dollarBody`
    macro `getitemId`(`nParam`: `nT`, getitemIdx: static[int]): untyped =
      const fieldList = `fieldListValue`
      var idx = getitemIdx
      if idx < 0: idx = fieldList.len - idx
      newDotExpr(`nparam`, ident fieldList[idx])

proc genNamedTupleImpl(cT: NimNode, stmtDef: NimNode): NimNode =
  let typSec = stmtDef.oneElement(nnkStmtList)
  let typDef = typSec.oneElement(nnkTypeSection)
  assert typDef.kind == nnkTypeDef
  let (name, exported) = typDef[0].unpackExportedAsStr

  let objRefTy = typDef[2]
  assert objRefTy.kind == nnkRefTy # TODO: allow object
  let objTy = objRefTy[0]
  cstructGenNamedTupleImpl(cT, exported, name, objTy[2])

macro genNamedTuple*[T: object](desc: typedesc[T], stmtDef) =
  let cT = desc.getType[1]
  genNamedTupleImpl(cT, stmtDef)

macro cstructGenNamedTuple*[T: object](desc: typedesc[T], genName: static[string], exported: static[bool] = true) =
  ##[
    Generate a `ref object` type (because CPython's namedtuple is passed by ref),
      attr can be access via index (e.g. you can access the 1st attr via `obj[0]`).

    .. note:: all generated are exported if `exported` (default).
  ]##

  let cT = desc.getType[1]
  cstructGenNamedTupleImpl(cT, exported, genName)

macro cstructGenNamedTuple*[T: object](desc: typedesc[T], exported: static[bool] = true;
                                       mapCTypeToNim: static[MapCTypeToNim]=mapCTypeToNim) =
  ## Generate with name "struct_" prefix.
  let cT = desc.getType[1]
  let nTStr = "struct_" & cT.strVal
  cstructGenNamedTupleImpl(cT, exported, nTStr, mapCTypeToNimTab=mapCTypeToNim)

when isMainModule and defined(posix):
  import std/posix
  cstructGenNamedTuple Passwd
  let c = getpwnam"root"
  var n: struct_passwd
  c.toPyNim n
  echo n
  echo n[0]


