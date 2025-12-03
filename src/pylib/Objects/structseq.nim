## minic CPython's structseq

import std/macros

proc mapCTypeToNim(cT: NimNode): NimNode =
  case cT.typeKind
  of {ntyInt..ntyInt64}: bindSym"BiggestInt"
  of {ntyUInt..ntyUInt64}: bindSym"BiggestUInt"
  of {ntyFloat..ntyFloat64}: bindSym"BiggestFloat"
  of ntyCString: bindSym"string"
  else: cT

template toNim(i: SomeSignedInt): BiggestInt = i
template toNim(i: SomeUnsignedInt): BiggestUInt = i
template toNim(f: SomeFloat): BiggestFloat = f
template toNim(s: cstring): string = $s

proc cstructGenNamedTupleImpl(cT: NimNode, genName: string, exported: bool): NimNode =
  result = newStmtList()
  let nT = ident genName
  let typImpl = getTypeImpl(cT)
  assert typImpl.typeKind == ntyObject
  assert typImpl[0].kind == nnkEmpty
  assert typImpl[1].kind == nnkEmpty

  var mayExp = if exported:
    proc (x: NimNode): NimNode = x.postfix"*"
  else:
    proc (x: NimNode): NimNode = x
  let
    resultId = ident"result"
    toNimId = bindSym"toNim"
    toNimDefId = ident"toNim".mayExp
    dollarId = ident"$".mayExp
    getitemId = ident"[]".mayExp
    cParam = ident"cObj"
    nParam = ident"nObj"
  var
    toNimBody = newStmtList parseStmt"new result"
    dollarBody = newStmtList quote do:
      result = `genName`
  template asgnA(dest, src, attr, attrMap): NimNode{.dirty.} =
    quote do: `dest`.`attr` = `attrMap` `src`.`attr`

  let emptyn = newEmptyNode()
  var fields = newNimNode nnkRecList
  var fieldListValue = newNimNode nnkBracket
  var preStr = "("
  for oriFDef in typImpl[2]:
    # oriFDef.kind == nnkIdentDefs
    let fDef = oriFDef.copyNimNode
    for idxInIdentDef in 0..<oriFDef.len-2:
      let fStrVal = oriFDef[idxInIdentDef].strVal
      let fStr = newLit fStrVal
      let f = ident fStrVal  # purge symbol type info
      fDef.add f.mayExp
      toNimBody.add asgnA(resultId, cParam, f, toNimId)
      fieldListValue.add fStr
      dollarBody.add quote do:
        result.add `preStr`
        result.add `fStr`
        result.add '='
        result.add repr `nParam`.`f`

      preStr = ", "
    fDef.add mapCTypeToNim oriFDef[^2]
    fDef.add oriFDef.last
    fields.add fDef
  dollarBody.add quote do: result.add ')'

  let objFields = nnkRefTy.newTree nnkObjectTy.newTree(emptyn, emptyn, fields)
  result.add quote do:
    type `nT`* = `objFields`
  result.add quote do:
    proc `toNimDefId`(`cParam`: sink `cT`): `nT` = `toNimBody`
    proc `toNimDefId`(`cParam`: ptr`cT`): `nT`{.inline.} = `cParam`[].toNim
    proc `dollarId`(`nParam`: `nT`): string = `dollarBody`
    macro `getitemId`(`nParam`: `nT`, getitemIdx: static[int]): untyped =
      const fieldList = `fieldListValue`
      var idx = getitemIdx
      if idx < 0: idx = fieldList.len - idx
      newDotExpr(`nparam`, ident fieldList[idx])

macro cstructGenNamedTuple*[T: object](desc: typedesc[T], genName: static[string], exported: static[bool] = true) =
  ##[
    Generate a `ref object` type (because CPython's namedtuple is passed by ref),
      attr can be access via index (e.g. you can access the 1st attr via `obj[0]`).

    .. note:: all generated are exported if `exported` (default).
  ]##

  let cT = desc.getType[1]
  cstructGenNamedTupleImpl(cT, genName, exported)

macro cstructGenNamedTuple*[T: object](desc: typedesc[T], exported: static[bool] = true) =
  ## Generate with name "struct_" prefix
  let cT = desc.getType[1]
  let nTStr = "struct_" & cT.strVal
  cstructGenNamedTupleImpl(cT, nTStr, exported)

when isMainModule and defined(posix):
  import std/posix
  cstructGenNamedTuple Passwd
  let c = getpwnam"root"
  let n = c.toNim
  echo n
  echo n[0]


