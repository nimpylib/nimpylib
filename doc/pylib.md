# Nim Pylib

> Just write Python code in Nim!

## import pylib
The mostly suggested style is
```Nim
import pkg/pylib
```

However, omitting the `pkg/` prefix shall be fine at most cases:

```Nim
import pylib
```

## import Python-like stdlib

under `pyimports` macro, you can write as if in Python, except for `import *`:

  For star import, use `import *MOD` instead of `from MOD import *`,
  for example:

  ```Nim
  pyimports:
    import *random
  # or a single line `pyimportAll random`
  ```


### Appendix: Cheatsheet for rough alternative between Nim and Python

> Outside `pyimports` macro, beware you're writing Nim, following is cheatsheet.

| Nim pylib                        | Python                               |
| --------------------------       | --------------------------           |
| `from demo/LIB import nil`  | `import demo.LIB`                          |
| `import demo/LIB`           | `from demo.LIB import *`                   |
| `from demo/LIB import XXX`  | `import demo.LIB; from demo.LIB import XXX`|

### Deprecated stdlib import notations
The traditional notation for importing pystdlib is deprecated and may be unavailable in the future.

For example, `import pylib/Lib/math`
shall be replaced with `pyimportAll math`.

------

Wondering how many libs are available in NimPylib?

Here are the
[Lib Docs](Lib/).

