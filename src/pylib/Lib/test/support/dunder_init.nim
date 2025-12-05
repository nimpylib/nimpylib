
var verbose* = 1
import ../../../builtins/print
import ./os_version
export os_version

template force_run*(path: typed, fun: typed; args: varargs[untyped]): untyped =
  bind verbose, print
  const funName = astToStr(fun)
  try:
    fun(args)
  except FileNotFoundError as err:
    # chmod() won't fix a missing file.
    if verbose >= 2:
      print(err.name, ": ", err)
    raise
  except OSError as err:
    if verbose >= 2:
      print(err.name, ": ", err)
      print("re-run " & funName & astToStr(args))
    os.chmod(path, stat.S_IRWXU)
    fun(args)
