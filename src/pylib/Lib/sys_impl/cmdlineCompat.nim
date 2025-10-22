
const Js = defined(js)

template jsOr(a, b): untyped =
  when Js: a else: b

when Js:
  import std/jsffi
  import ../../jsutils/denoAttrs
  
  let argsStart =
    if inDeno: 0
    else: 2

  type Argv = JsObject
  let argv{.importDenoOrProcess(args, argv).}: Argv
  #bindExpr[] argv, nodeno("process.argv", "Deno.args", "[]")
  proc len(a: Argv): int{.importjs: "#.length".}

  proc paramCountCompat*(): int = argv.len - argsStart
  proc paramStrCompat*(i: int): string =
    when not defined(nodejs):
      if inDeno:
        if i == 0:
          # XXX: must ES module
          let name{.importc: "import.meta.filename".}: cstring
          return $name
    let ii = i - 1
    let res = argv[ii+argsStart]
    if res.isUndefined:
      raise newException(IndexDefect, formatErrorIndexBound(ii, argv.len - argsStart - 1))
    $(res.to cstring)
  proc commandLineParamsImpl(): seq[string] =
    ## minic std/cmdline's
    let L = argv.len
    let argn = L - argsStart
    result = newSeqOfCap[string](argn)
    for i in argsStart ..< L:
      result.add $(argv[i].to cstring)
else:
  when defined(nimPreviewSlimSystem):
    import std/syncio
  when NimMajor == 1:
    import std/os
  else:
    import std/cmdline
  template paramCountCompat*(): int =
    bind paramCount
    paramCount()
  template paramStrCompat*(i: int): string =
    bind paramStr
    paramStr(i)

proc commandLineParamsCompat*(): seq[string] =
  jsOr commandLineParamsImpl(), commandLineParams()

