
from std/algorithm import reversed
import ./bytesimpl
from ../pyerrors import TypeError
import pkg/pystrbytes_decl
export pystrbytes_decl.repr

func reversed*(s: PyBytes): PyBytes =
  pybytes reversed $s

proc ord*(a: PyBytes): int =
  ## Raises TypeError if len(a) is not 1.

  when not defined(release):
    let ulen = a.len
    if ulen != 1:
      raise newException(TypeError, 
        "TypeError: ord() expected a character, but string of length " & $ulen & " found")
  result = a[0]

