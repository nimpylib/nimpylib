
when not defined(js):
  import std/asyncdispatch as stdasyncLib
else:
  import std/asyncjs as stdasyncLib
  template waitFor(f: Future): untyped = await f
export stdasyncLib except async

template run*(f): untyped =
  bind waitFor
  waitFor f


