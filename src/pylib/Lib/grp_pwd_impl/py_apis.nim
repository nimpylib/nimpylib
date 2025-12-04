
import ./apisTmpl
import ../../pyerrors/oserr
import ../../builtins/list
import ../../pystring

template add(ls: PyList, x) = ls.append x
genApis PyList, PyStr, raiseErrno

when isMainModule:
  echo getgrnam"root"


