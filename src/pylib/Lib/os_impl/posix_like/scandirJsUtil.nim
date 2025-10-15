
import std/jsffi
from ../common import importNode, catchJsErrAndRaise
export isNull, catchJsErrAndRaise

type 
  Dir* = JsObject  ## fs.Dir
  Dirent* = JsObject  ## fs.Dirent

# readdirSync returns array, which might be too expensive.
proc opendirSync*(p: cstring): Dir{.importNode(fs, opendirSync).}
proc closeSync*(self: Dir){.importcpp.}
proc readSync*(self: Dir): Dirent{.importcpp.}


proc name*(dirent: Dirent): string =
  $dirent["name"].to(cstring)

