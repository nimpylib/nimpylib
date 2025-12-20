import pkg/pyrepr

func pyreprImpl*(s: string, escape127: static[bool] = false): string =
  ## Python's `repr`
  ## but returns Nim's string.
  ##
  ##   nim's Escape Char feature can be enabled via `-d:useNimCharEsc`,
  ##     in which '\e' (i.e.'\x1B' in Nim) will be replaced by "\\e"
  ## 
  runnableExamples:
    # NOTE: string literal's `repr` is `system.repr`, as following. 
    assert repr("\"") == "\"\\\"\""   # string literal of "\""
    # use pyrepr for any StringLike and returns a PyStr
    assert pyreprImpl("\"") == "'\"'"
  pyrepr(s, escape127)

func pyreprbImpl*(s: string): string =
  'b' & s.pyreprImpl(true)
