
when not defined(js):
  import std/asyncmacro
  import std/asyncdispatch
else:
  import std/asyncjs
  proc await[T](f: Future[T]): T{.importjs: "(await #)".}
export Future
export await
export async

import std/macros
import ./frame
export frame
import ./funcSignature
export funcSignature
import ./types
export types

template emptyn: NimNode = newEmptyNode()

proc defImpl*(signature, body: NimNode, parser: var PySyntaxProcesser; pragmas = emptyn, deftype = ident"auto", procType=nnkProcDef): NimNode
  ## if `signature` is of arrow expr (like f()->int), then def_restype is ignored
proc asyncImpl*(defsign, body: NimNode, parser: var PySyntaxProcesser;
  procType=nnkProcDef): NimNode

proc parseSignatureMayGenerics*(parser: var PySyntaxProcesser;
      generics: var NimNode; signature: NimNode,
      deftype = ident"untyped",
    ): tuple[name: NimNode, params: seq[NimNode]] =
  if parser.supportGenerics:
    parseSignature(generics, signature, deftype=deftype)
  else:
    generics = emptyn
    parseSignatureNoGenerics(signature, deftype=deftype)


template defAuxImpl{.dirty.} =
  var generics: NimNode
  let tup = parser.parseSignatureMayGenerics(generics, signature, deftype=deftype)
  let nbody = parser.parsePyBodyWithDoc body

proc defUnwareOfYield*(signature, body: NimNode,
            deftype = ident"untyped",
            parser: var PySyntaxProcesser;
            procType = nnkTemplateDef, pragmas = emptyn): NimNode =
  defAuxImpl
  result = newProc(tup, generics, nbody, procType, pragmas)

proc defAux(signature, body: NimNode,
            deftype = ident"untyped",
            parser: var PySyntaxProcesser;
            procType = nnkTemplateDef, pragmas = emptyn): NimNode =
  defAuxImpl
  if not parser.curFrameHasYield():
    result = newProc(tup, generics, nbody, procType, pragmas)
    return
  let resType = tup.params[0]
  let itTup = (name: emptyn, params: @[resType])
  let it = newProc(itTup, emptyn, nbody, nnkIteratorDef, pragmas)
  it.addPragma ident"closure"

  var procParams = @[ident"auto"]
  for i in 1..<tup.params.len:
    procParams.add(tup.params[i])
  let procTup = (name: tup.name, params: procParams)
  #XXX:generator: in Nim `x = yield y` is invalid Nim AST, so no need to use PyGenerator
  result = newProc(procTup, emptyn, newCall(ident"newPyIterator", it), procType, emptyn)

proc defImpl(signature, body: NimNode, parser: var PySyntaxProcesser; pragmas = emptyn, deftype = ident"auto", procType=nnkProcDef): NimNode =
  defAux(signature, body, parser=parser, deftype=deftype, procType=procType, pragmas=pragmas)

proc asyncImpl(defsign, body: NimNode; parser: var PySyntaxProcesser;
  procType=nnkProcDef): NimNode =
  let 
    pre = defsign[0]
    signature = defsign[1]
  expectIdent(pre,"def")
  let
    apragma = newNimNode(nnkPragma).add(bindSym"async")
    restype = newNimNode(nnkBracketExpr).add(bindSym"Future", ident"auto")
  defImpl(signature, body, parser=parser, pragmas=apragma, deftype=restype, procType=procType)
