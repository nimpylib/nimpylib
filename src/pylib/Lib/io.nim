from std/terminal import isatty

import ../io_abc  # PathLike
export io_abc except `$`
import pkg/pyio_open
export pyio_open

import pkg/posixos/posix_like/truncate

func isatty*(f: IOBase): bool = f.isatty()

proc truncate*(self: IOBase): int{.discardable.} =
  runnableExamples:
    const fn = "tempfiletest"
    var f = open(fn, "w+")
    discard f.write("123")
    f.seek(0)
    f.truncate()
    assert f.read() == ""
    f.close()
  result = self.tell().int
  truncate self.fileno, result

proc truncate*(self: IOBase, size: int64): int64{.discardable.} =
  truncate self.fileno, size
  size

proc isatty(p: CanIOOpenT): bool =
  when p is int:
    result = p.isatty()
  else:
    var f: File
    if f.open($p, fmRead):
      result = f.isatty()
      f.close()
