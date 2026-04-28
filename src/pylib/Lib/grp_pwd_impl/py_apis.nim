
import pkg/grp_pwd/apisTmpl
import ../../pyerrors/oserr
import pkg/pybuiltins/list
import ../../pystring

template add(ls: PyList, x) = ls.append x
genApis PyList, PyStr, raiseErrno

when isMainModule:
  echo getgrnam"root"


