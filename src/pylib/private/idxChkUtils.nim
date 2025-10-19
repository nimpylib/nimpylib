
import std/macros
from std/strutils import startsWith
template chkIdx*(arr; i: int) =
  let L = arr.len
  if i >= L:
    raise newException(IndexDefect, formatErrorIndexBound(i, L-1))

proc wrapChkIdxImpl(i, def: NimNode): NimNode =
  result = newStmtList()
  let
    name = def.name
    tmpName = ident(name.strVal & "unchkIdx")
    params = def.params
    pragma = def.pragma
    arr = params[1][0]
    exported = def[0].kind == nnkPostfix and def[0][0].eqIdent"*"
  def[0] = tmpName   # not use `.name` to ensure it unexported
  var
    importPragmaIdx = -1
  for i, p in pragma:
    let colon = p.kind == nnkExprColonExpr
    let pname = if colon: p[0]
    else: p
    if pname.kind == nnkIdent and pname.strVal.startsWith"import":
      importPragmaIdx = i
      if not colon:
        pragma[i] = nnkExprColonExpr.newTree(pname, newLit name.strVal)
      break

  def.pragma = pragma
  result.add def


  var body = newStmtList()
  body.add newCall(bindSym"chkIdx", arr, i)
  var call = newCall(tmpName)
  for i in 1..<params.len:
    call.add params[i][0]
  body.add call
  var ndef = copyNimNode def
  ndef.add if exported: name.postfix"*" else: name
  for i in 1..<def.len-1:
    ndef.add def[i].copyNimTree
  ndef.add body

  var npragma = pragma
  if importPragmaIdx >= 0:
    # COW
    npragma = copyNimNode pragma
    for ii, pp in pragma:
      if ii == importPragmaIdx: continue
      npragma.add pp

  ndef.pragma = npragma
  result.add ndef

macro wrapChkIdx*(i; def): untyped = wrapChkIdxImpl(i, def) ## \
  ## Insert a private proc whose name is `def.name & "nochkIdx"`
  ## And make `def` check against `i`, assuming `def`'s 1st param has `.len` property
macro wrapChkIdx*(def): untyped =
  let i = def.params[2][0]
  wrapChkIdxImpl(i, def)

