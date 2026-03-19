
import ./strimpl
from std/unicode import toRunes, Rune
import std/sets
import pkg/pystrutils/strips

func strip*(self: PyStr): PyStr = str self.toRunes.strip()
func lstrip*(self: PyStr): PyStr = str self.toRunes.lstrip()
func rstrip*(self: PyStr): PyStr = str self.toRunes.rstrip()

converter asSet(s: PyStr): HashSet[Rune] =
  result = initHashSet[Rune](s.len)
  for key in s.runes: result.incl(key)

func strip*(self: PyStr,  chars: PyStr): PyStr =
  str self.toRunes.strip(chars=chars.asSet)
func lstrip*(self: PyStr, chars: PyStr): PyStr =
  str self.toRunes.lstrip(chars=chars.asSet)
func rstrip*(self: PyStr, chars: PyStr): PyStr =
  str self.toRunes.rstrip(chars=chars.asSet)
