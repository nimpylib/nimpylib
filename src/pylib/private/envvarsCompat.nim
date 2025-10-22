
const InJs = defined(js)
const NodeJs = defined(nodejs)
when InJs:
  import std/jsffi
  import ../jsutils/denoAttrs
  let js_env{.importDenoOrProcess(env).}: JsObject
  const jsgetExpr = when NodeJs: "[]" else: "get"

  proc get(deno_env: JsObject; s: cstring): JsObject #[cstring or undefined]#{.importcpp: jsgetExpr.}

when InJs and not NodeJs:
  proc getEnvCompat(s: string): string =
    let res = js_env.get cstring s
    if not res.isUndefined:
      result = $res.to(cstring)

  proc existsEnvCompat(s: string): bool = js_env.has(cstring s).to bool
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
  
