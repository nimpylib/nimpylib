# [0.9.14] - 2025-12-18
## 🚀 Features
### Lib
- grp, pwd (665257e) (415c35a)
- sys.getwindowsversion (not tested) (9894ccd)
- platform.node,release,processor (f5ea536)
- winapi for `_winapi` (wip) (63edb74)
- os: get,set xx id (104b798)
- signal: sup JS (with test) (7aaadd5)
- test: support/dunder_init (wip) (6e5a1a3)

### Object
- structseq: cstructGenNamedTuple (7f4b321)
- genobject (65a0fc9)

### js
- Lib/os.name (28d053e)

### pysugar
- util: unpackValues (0d84684)

### sugar
- comprehension:
  - `|`/`,`->`for`,`if` (b33a908)
  - uses `` `for` ``, `` `if` `` instead of `|`, `,` (f7de565)

### utils
- jsarrays, idxChkUtils (2d47d96)

## 🐛 Bug Fixes
### fixup
- 6edc40902: numTypes/ints not compile if -d:noUndefinedBitOpts (79c2ad7)


### Lib/random
- IndexDefect if random.getrandom(0), array('i').buffer_info() (fd2a613)
- randbytes's len a little longer; fix(js): randbytes's char not trunc and endian wrong (59d6655)

### NIM-BUG
- `cast[char]` not trunc on JS (2e8be8b)

### js
- Lib/random not compile "undeclared identifier: 'gRandom'" (77a4208)
- workaround NIM-BUG: nim-lang/Nim#25043 (ab906ad)
- Lib/stat not compile (d21de64)
- Deno cannot run (when gen sys.argv) (dba576f)
- NIM-BUG: Lib/stat not compile (fa2187b)
- Lib/shutil not compile (6fdc79e)
- os.listdir,os.walk,os.scandir not compile (6dad97f)
- Lib/tempfile not compile (TODO:io) (1c3f207)

## ⚡ Performance
## Lib/math
- isqrt: use static table over loop (c96a3b6)

## 🚜 Refactor
### dedup
- bit_length (e9f14d1)

### list_decl
- mv `<=` `<` for openArray to collections_abc/cmpOA (51ce408)

## 📚 Documentation
### mustRewriteExtern
- add link for nim-meta/math_comprehension (skip ci) (3c191e1)

## ⚙️ Miscellaneous Tasks
### nimble
- sup nimble@v0.16.4's declarativeparser (ef74938)

### test
- some for pysugar, some for os-about (379a1ff)
- test_math for cbrt (e372329)

### test/Lib
- resource (b510499)
- min_max (d7a7558)

## 💼 Other
### NIM-BUG
- regression: rt&static in runnableExample... (a3d8eb3)

### Effect System
- add `raises` pragma for some api (d51e76e)


