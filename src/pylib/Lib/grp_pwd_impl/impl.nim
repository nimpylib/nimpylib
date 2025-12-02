
import std/posix
import std/strutils
import ../../pyerrors/oserr

const MayMulThrd#[SingleThread]# = compileOption"threads"
when MayMulThrd:
  import ../../pyconfig/os
  import std/locks
template genGetXOrImpl(namOrId; X; Res: typedesc, ctype, ntype){.dirty.} =
  proc `def X OnNotFound`(name: ctype) =
    raise newException(KeyError,
      "get$1$2(): $2 not found: $3" % [
      astToStr(X), astToStr(namOrId), repr(name)]
    )
  proc `get X namOrId`*(name: ctype, onFound: proc (x: ptr Res){.raises: [].},
      onNotFound: proc (name: ctype) = `def X OnNotFound`,
    ): cint{.effectsOf: onNotFound.} =
    ## .. note:: returns 0 on success, including not found! (
    ##  at which time `onNotFound` is called)
    var p: ptr Res = nil
    when MayMulThrd:
     when HAVE_GETPWNAM_R:
      const
        DEFAULT_BUFSIZE = 1024
      var tmpX{.noInit.}: Res

      var bufsize = sysconf(`SC_GET X R_SIZE_MAX`)
      if bufsize == -1:
        bufsize = DEFAULT_BUFSIZE

      var buf: pointer = nil
      while true:
        buf = realloc(buf, bufsize)
        # no need to check for nil, realloc() crashes if it fails
        #if buf2 == nil: raise newException(MemoryError, "getgrnam(): out of memory")
        result = `get X namOrId r`(name, tmpX.addr, cast[cstring](buf), bufsize, p.addr)
        if result != 0:
          p = nil
        if not p.isNil or result != ERANGE:
          break
        bufsize *= 2
    else:
      p = `get X namOrId`(name)
    if p.isNil:
      onNotFound(name)
    else:
      onFound(p)

  template `get X namOrId attr`*(name: ntype; attr): untyped =
    var res: Res.attr
    proc cb(x: ptr Res) =
      res = x.attr
    if `get X namOrId`(ctype name, cb) != 0:
      raiseErrno()
    res
template genGetXNamOr(id; X; Res: typedesc){.dirty.} =
  export Res, id
  genGetXOrImpl(id,  X, Res, id, BiggestInt)
  genGetXOrImpl(nam, X, Res, cstring, string)
  # The setpwent(), getpwent() and endpwent() functions are not required to
  # be thread-safe.
  # https://pubs.opengroup.org/onlinepubs/009696799/functions/setpwent.htm
  when MayMulThrd:
    var `X lock`: Lock
    `X lock`.initLock()
  iterator `get X all impl`*(): ptr Res =
    when MayMulThrd:
      `X lock`.acquire()
    `set X ent`()
    while true:
      var res = posix.`get X ent`()
      if res.isNil:
        break
      yield res
    `end X ent`()
    when MayMulThrd:
      `X lock`.release()

genGetXNamOr(Gid, gr, Group)
genGetXNamOr(Uid, pw, Passwd)

