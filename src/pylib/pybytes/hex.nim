
import ./bytesimpl
import ../pystring/strimpl
import std/strutils

import pkg/pyrepr

using self: PyBytes
func hex*(self): PyStr =
  # strutils.toHex returns uppercase,
  # but python's bytes.hex returns lowercase.
  str toLowerHex $self


func hex*(self; sep: char): PyStr = str toLowerHex($self, sep)

template chkLen(sep) =
  when not defined(release):
    if sep.len != 1:
      raise newException(ValueError, "sep must be length 1.")
func hex*(self; sep: PyStr|PyBytes): PyStr =
  chkLen sep
  str toLowerHex($self, sep.getChar(0))

func hex*(self; sep: char|PyStr|PyBytes, bytes_per_sep: int): PyStr =
  when sep isnot char:
    chkLen sep
  else:
    let sep = sep.getChar(0)
  var res = toLowerHex($self, sep)
  if bytes_per_sep < 0:
    res.insert sep, res.len + bytes_per_sep
  else:
    res.insert sep, bytes_per_sep
  result = str res

func fromhex*(_: typedesc[PyBytes], s: PyStr): PyBytes =
  ## bytes.fromhex(s)
  ## 
  ## spaces are allowed, unlike Nim's `strutils.parseHexStr`
  var ns = newStringOfCap s.byteLen
  for c in s.chars:
    if c != ' ': ns.add c
  result = bytes parseHexStr ns
