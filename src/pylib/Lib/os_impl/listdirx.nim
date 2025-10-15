
import std/os
import ./common
import ./listcommon

when InJs:
  import ./posix_like/scandirJsUtil
  iterator walkDirImpl(path: string): string =
      var dir: Dir
      let cs = cstring(path)
      catchJsErrAndRaise:
        dir = opendirSync(cs)
      var dirent: Dirent
      while true:
        dirent = dir.readSync()
        if dirent.isNull: break
        let de = dirent.name #newDirEntry[T](name = dirent.name, dir = spath, hasIsFileDir=dirent)
        yield de
      dir.closeSync
else:
  iterator walkDirImpl(path: string): string =
    for i in walkDir(path, relative=true, checkDir=true):
      yield i.path
proc listdir*[T](p: PathLike[T]): PyList[T]{.raises: [OSError].} =
  sys.audit("os.listdir", p)
  result = newPyList[T]()
  p.tryOsOp:
    for i in walkDirImpl($p):
      result.append i

proc listdir*: PyList[PyStr] = listdir(PyStr".")

