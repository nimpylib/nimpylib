
import ./bytesimpl
import ../translateEscape

func b*(c: char{lit}): PyBytes = pybytes c
proc b*(s: static[string]{lit}): PyBytes =
  ## XXX: Currently
  ## `\Uxxxxxxxx` and `\uxxxx` 
  ## is supported as an extension.
  pybytes translateEscape(s, allow_unicode=false)

func br*(s: string{lit}): PyBytes =
  pybytes s

template rawB(pre){.dirty.} =
  template pre*(s): PyBytes =
    bind br
    br s

rawB rb
rawB Rb
rawB Br
