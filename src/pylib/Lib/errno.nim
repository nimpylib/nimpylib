
import pkg/py_commontypes/dict as dictLib
import pkg/py_commontypes/dict_decl
import pkg/pystrbytes_decl/strimpl
export strimpl
export dictLib

import ./n_errno except errorcode
export n_errno except errorcode

declErrorcodeWith[int, PyStr] newPyDict
export errorcode
