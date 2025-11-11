
import std/jsffi
from ../common import importNode, catchJsErrAndRaise, inDeno

const NodeJs = defined(nodejs)

using path: cstring
when NodeJs:
  type 
    Dir = JsObject  ## fs.Dir
    Dirent* = JsObject  ## fs.Dirent

  # readdirSync returns array, which might be too expensive.
  proc opendirSync(p: cstring): Dir{.importNode(fs, opendirSync).}
  proc closeSync(self: Dir){.importcpp.}
  proc readSync(self: Dir): Dirent{.importcpp.}

  iterator scandirJs*(path): Dirent =
    var dir: Dir
    catchJsErrAndRaise:
      dir = opendirSync(path)
    var d: Dirent
    while true:
      d = readSync(dir)
      if d.isNull: break
      yield d
else:
  type Dirent* = JsObject  ## Deno.DirEntry
  proc readDirSync(path: cstring): JsObject#[IteratorObject<DirEntry>]#{.importjs: "Deno.readDirSync(#)".}
  iterator iterItems(obj: JsObject): JsObject =
    ## Yields the `values` of each field in a JsObject, wrapped into a JsObject.
    var v: JsObject
    {.emit: "for (`v` of `obj`) {".}
    yield v
    {.emit: "}".}
  iterator scandirJs*(path): Dirent =
      var it: JsObject
      catchJsErrAndRaise:
        it = readDirSync(path)
      for d in it.iterItems:
        yield d.to Dirent

proc name*(dirent: Dirent): string =
  $dirent["name"].to(cstring)

