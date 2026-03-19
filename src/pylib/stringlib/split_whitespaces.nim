
import ./split/[
  common, split_whitespace, rsplit_whitespace
]
import ../builtins/[
  list
]

proc_gen_split_whitespace split_whitespace,  PyList, append
proc_gen_split_whitespace rsplit_whitespace, PyList, append
