
import ./pystring/strimpl
import ./pybytes/bytesimpl
import ./builtins/reprImpl

func fspath*(s: string): PyStr = str s
func fspath*(c: char): PyStr = str c

type
  FsPath = PyStr|PyBytes

when defined(js) and NimMajor == 2 and NimMinor < 3:
  type PathLike*[T: FsPath] = T  ## os.PathLike, repr in nim-lang/Nim#25043, fixed in Nim#25044
else:
 type
  PathLike*[T: FsPath] = concept self  ## os.PathLike
    T  # XXX: still to prevent wrong compiler hint: `T is not used`
    self.fspath is T

type
  CanIOOpenT*[T] = int | PathLike[T]


template mapPathLike*[T](s: PathLike[T], nimProc): T =
  when T is PyStr: str nimProc s.fspath
  else: bytes nimProc s.fspath
template mapPathLike*[T](nexpr): T =
  when T is PyStr: str nexpr
  else: bytes nexpr


func `$`*(p: PathLike): string =
  $p.fspath


proc `$`*(p: CanIOOpenT): string =
  ## Mainly for error message
  when p is int: "fd: " & $int(p)
  else: $p

func pathrepr*(p: PathLike[PyBytes]): string = p.pyreprbImpl
func pathrepr*(p: PathLike[PyStr]): string = p.pyreprImpl
