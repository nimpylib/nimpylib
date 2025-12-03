
import std/posix
import ../../Objects/structseq

template doubletime(tv: TimeVal): float =
  float(tv.tv_sec) + float(tv.tv_usec) / 1000000.0

proc toPyNim(tv: TimeVal, res: var float) = res = tv.doubletime
proc toPyNim(i: clong, res: var int) = res = i

genNamedTuple(RUsage):
 type
  struct_rusage* = ref object
    ru_utime*: float
    ru_stime*: float
    ru_maxrss*: int
    ru_ixrss*: int
    ru_idrss*: int
    ru_isrss*: int
    ru_minflt*: int
    ru_majflt*: int
    ru_nswap*: int
    ru_inblock*: int
    ru_oublock*: int
    ru_msgsnd*: int
    ru_msgrcv*: int
    ru_nsignals*: int
    ru_nvcsw*: int
    ru_nivcsw*: int


proc toPyObject*(rusage: RUsage): struct_rusage =
  rusage.toPyNim result

