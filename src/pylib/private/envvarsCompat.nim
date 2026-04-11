
const InJs = defined(js)
const NodeJs = defined(nodejs)
when InJs:
  import std/jsffi
  import pkg/jscompat/utils/denoAttrs
  import pkg/jscompat/utils/dispatch
  let js_env{.importDenoOrProcess(env).}: JsObject

when InJs and not NodeJs:
  proc getEnvCompat(s: string): string =
    let res = if notDeno: js_env[cstring s] else: js_env.get(cstring s)
    if not res.isUndefined:
      result = $res.to(cstring)

  proc existsEnvCompat(s: string): bool =
    if notDeno:
      var key2 = s.cstring
      var ret: bool
      {.emit: "`ret` = `key2` in process.env;".}
      result = ret
    else:
      result = js_env.has(cstring s).to bool
  proc putEnvCompat(s: string, val: string) =
    js_env.set(cstring s, cstring val)
  proc delEnvCompat(s: string) =
    js_env.delete(cstring s)
else:
  when NimMajor == 1:
    import std/os
  else:
    import std/envvars
  template getEnvCompat(s: string): string =
    bind getEnv
    getEnv(s)
  template existsEnvCompat(s: string): bool =
    bind existsEnv
    existsEnv(s)
  template putEnvCompat(s: string, val: string) =
    bind putEnv
    putEnv(s, val)
  template delEnvCompat(s: string) =
    bind delEnv
    delEnv(s)

export getEnvCompat, existsEnvCompat, putEnvCompat, delEnvCompat
  
