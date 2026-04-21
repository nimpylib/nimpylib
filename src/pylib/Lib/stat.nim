
import ./n_stat
import pkg/pystat/types

export n_stat except filemode

import ../pystring/strimpl
import ../version

proc filemode*(omode: int|Mode): PyStr{.pysince(3,3).} =
  str n_stat.filemode(omode)

