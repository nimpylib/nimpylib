
const
  InNodeJs = defined(nodejs)
import std/jsffi
template importjsObject(econsts; name: string) =
  when InNodeJs:
    let econsts = require(cstring name)
  else:
    let econsts{.importjs: "(await import(\"node:" & name & "\"))".}: JsObject
template importjsObject(econsts) = importjsObject(econsts, astToStr(econsts))

template from_js_constImpl[T](econsts; name; defVal: T): T =
  bind isUndefined, to, `[]`
  let n = econsts[astToStr(name)]
  if n.isUndefined: defVal else: n.to(T)

importjsObject constants

template from_js_const*[T](name; defval: T): T =
  bind constants
  from_js_constImpl(constants, name, defval)

importjsObject os, "os"
let os_constants* = os["constants"]
assert not os_constants.isUndefined
