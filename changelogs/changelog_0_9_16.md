
# [0.9.16] - 2026-05-11


## 🐛 Bug Fixes


### Bfafbe6 

- readd pysince for complex(HasIndex,.) (535a48f)


### Dba576f1ab 

- nodejs cannot run if no -d:nodejs (f8621a4)


### Fix 

- fixup! chore(dep): collections_abc (37ac784)
- fixup! chore(dep): py_intfloat (948c495)
- fixup! chore(dep): pysugar (2e4b51e)
 

## 📚 Documentation


### Readme 

- add link for npython and nimpylibs (5690a8a)
 

## 🚀 Features

### Lib/unittest 

- assertAlmostEqual, assertNotAlmostEqual (038e731)


### Sugar 

- async def (when js, only esm) (a4996b4)
- def: yield  (generator) (4ca2868)
 

## ⚙️ Miscellaneous Tasks


### Dep 

- pysimperr (12c4e99)
- pyunittest (97df0e3)
- auditfunc (5d25f4a)
- handy_sugars update (6cc9c92)
- collections_abc (011f0f0)
- pyerrors, pystrbytes_decl, pyio_abc (8c5ccd4)
- pytime_utils (7d5d507)
- pywarnings, cstruct2namedtuple (2a0ccd3)
- posixos, pysignal, pystat, ... (c0f2d92)
- pytime (7cb70bd)
- datetime (8d787dc)
- py_locale_utf8_encoding (9ba599c)
- pypathlib (e5019cf)
- functools (03d4511)
- grp_pwd, py_winapi (8d16079)
- py_constants (5446ecb)
- pytyping (e6dda22)
- py_commontypes (1b92395)
- intobject (457d699)
- py_sys_stdio (6ada045)
- pystrbyteslike_decl (adf6730)
- pybuiltins (c6fd39e)
- py_version (2045bd1)
- pysugar (1231eb3)
- jscompat to v0.1.5 (f55c7bf)
- pybisect, pyitertools (6e6b36f)
- py_intfloat (1909928)
- pyrandom (fc143bb)
- pytempfile, pyshutil (0344024)
- pystr, pybytes; break(rm): stringlib (08f85d9)
- ops (0416c63)
- pystdlib (6691e9e)


### Test 

- tfloat was moved to nimpylib/float_utils (b035217)
 

## 💼 Other




### NIM-BUG 

- compile crash on test_resource's fileFlush (8b72af3)
 

## 🚜 Refactor




### Python 

- mv some to Lib/sys_impl (30fdb14)


### NumTypes 

- merge HasIndex declaration (9446335)
 