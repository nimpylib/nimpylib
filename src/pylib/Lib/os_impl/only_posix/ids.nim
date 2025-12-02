##[

## Overview
```
set[[r]e][s]{g,u}id
getres{g,u}id
- r -> real
- e -> effective
- s -> saved

{g,s}et{g,u}id

{g,s}etsid
- s -> session

{g,s}etp{gid,grp}
```

## Function signatures & descriptions
### for User's Gid and Uid (X = g or u)
- setXid   (rid)
- setreXid (rid, eid)
- setresXid(rid, eid, sid)

- getpgid(pid) -> Pid
- setpgid(pid, gid)

### for Process Group
- getpgrp(pid) -> Pid
- setpgrp()[ -> cint]

### For Session
- setsid() -> Pid
- getsid(pid) -> Pid


]##

import std/posix
from ../common import raiseErrno

const UnistdH = "<unistd.h>"
template getresXid(name, T){.dirty.} =
  proc name(r, e, s: var T): cint{.importc, header: UnistdH.}
  proc name*(): tuple[r, e, s: int] =
    var rgid, egid, sgid: T
    if name(rgid, egid, sgid) < 0:
      raiseErrno()
    (rgid.int, egid.int, sgid.int)

getresXid getresgid, Gid
getresXid getresuid, Uid


template chk(ret: cint) =
  if ret < 0:
    raiseErrno()


template setXid(X, T){.dirty.} =
  proc `set X id`*(rid: int) =
    chk `set X id`(rid.T)
  proc `setre X id`*(rid, eid: int) =
    chk `setre X id`(rid.T, eid.T)
  proc `setres X id`(rid, eid, savedId: T): cint{.importc, header: UnistdH.}
  proc `setres X id`*(rid, eid, savedId: int) =
    chk `setres X id`(rid.T, eid.T, savedId.T)
  

setXid g, Gid
setXid u, Uid

proc getpgid*(pid: int): int =
  chk getpgid(pid.Pid)
proc setpgid*(pid, id: int) =
  chk setpgid(pid.Pid, id.Pid)

proc getpgrp*(): int =
  let ret = posix.getpgrp()
  if ret < 0:
    raiseErrno()
  ret.int

proc setpgrp*() =
  chk posix.setpgrp()

proc setsid*: int =
  let ret = posix.setsid()
  if ret < 0:
    raiseErrno()
  ret.int

proc getsid*(pid: int): int =
  let ret = posix.getsid(pid.Pid)
  if ret < 0:
    raiseErrno()
  ret.int

