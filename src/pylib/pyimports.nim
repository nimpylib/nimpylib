
import std/macros

func prefixPyLib(pymodule: NimNode): NimNode =
  if pymodule.strVal in ["sys", "n_sys"]:
    ident"pylib".infix("/", ident"Lib".infix("/", pymodule))
  else:
    ident"pkg".infix("/", ident"pystdlib".infix("/", pymodule))

func slash(pre, suf: NimNode): NimNode = infix(pre, "/", suf)
func dotToSlash(pymodule: NimNode): NimNode =
  if pymodule.kind == nnkDotExpr:
    dotToSlash(pymodule[0]).slash(pymodule[1])
  else:
    pymodule

proc moduleToPyModule(pymodule: NimNode): NimNode =
  case pymodule.kind
  of nnkIdent:
    #quote do: pyLib/Lib/`pymodule`
    return prefixPyLib(pymodule)
  of nnkDotExpr:
    return prefixPyLib(pymodule.dotToSlash)
  of nnkInfix:
    if pymodule[0].eqIdent"as":
      return prefixPyLib(pymodule[1]).infix("as", pymodule[2])
  else: discard
  error("invalid module name in import statement", pymodule)

proc pyfrom_importImpl(pymodule: NimNode, nameMayAliases: seq[NimNode]|NimNode): NimNode =
  result = newNimNode nnkFromStmt
  result.add moduleToPyModule(pymodule)
  for name in nameMayAliases:
    result.add name

proc pyimportAllImpl(pymodule: NimNode): NimNode =
  result = newNimNode nnkImportStmt
  result.add moduleToPyModule(pymodule)

proc pyimportImpl(pymodules: seq[NimNode]|NimNode): NimNode =
  for pymodule in pymodules:
    if pymodule.kind == nnkInfix and
        pymodule[0].eqIdent"as":
      result = nnkImportStmt.newTree moduleToPyModule(pymodule)
    elif pymodule.kind == nnkPrefix and pymodule[0].eqIdent"*":
      # from xxx import * -> import *xxx
      result = pyimportAllImpl pymodule[1]
    else:
      # import xxx -> from xxx import nil
      result = pyfrom_importImpl(pymodule, @[newNilLit()])

macro pyfrom_import*(pymodule: untyped, nameMayAliases: varargs[untyped]): untyped =
  pyfrom_importImpl(pymodule, nameMayAliases)

macro pyimportAll*(pymodules: varargs[untyped]): untyped =
  result = newStmtList()
  for pymodule in pymodules:
    result.add pyimportAllImpl(pymodule)

macro pyimports*(import_stmts): untyped =
  result = newStmtList()

  for st in import_stmts:
    case st.kind
    of nnkFromStmt:
      let pymodule = st[0]
      result.add pyfrom_importImpl(pymodule, st[1..^1])
    of nnkImportStmt:
      result.add pyimportImpl st
    else:
      error("invalid imports statement in pyimports", st)

