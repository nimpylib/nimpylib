
const sup_io = not defined(js)
when not sup_io:
  import std/jsffi
  import ../../../jsutils/denoAttrs
  type Uint8Array = JsObject
  proc writeFileSync(p: cstring, data: Uint8Array){.importNode(fs, writeFileSync).}
  proc encode(s: cstring): Uint8Array{.importjs: "new TextEncoder().encode(#)".}
  proc writeFile*(fn: string, data: string) =
    writeFileSync(fn.cstring, encode(cstring data))
proc create_writable_file*(filename: string) =
  try:
    writeFile(filename, "")
  except IOError: discard


  
  
