
# [0.9.15] - 2026-04-02




## 🚀 Features




### Sugar 

- pyimports; deprecate using `pylib/Lib/xxx` (b08c3c2)
 

## ⚙️ Miscellaneous Tasks




### Changelog 

- cliff.toml (a12196e)


### Ci 

- docs: use doc-deploy [skip ci] (855971d)
- use nim devel; disable hints and warnings [skip ci] (201498f)


### Dep 

- jscompat (4343a50)
- translateEscape (046b468)
- nimpatch (de6103b)
- handy_sugars (trans_imp) (a2f0505)
- nimpatch to v0.1.1 (40264d9)
- autoconf_sugars (70ea47f)
- dtoa_c (1cd60c6)
- errno (da66523)
- float_utils (7bc5a9f)
- handy_sugars (platformUtils) (0515e37)
- pycomplex (bfafbe6)
- unicode_case (8aa9dc9)
- pyformats (8b8fa4e)
- pystrutils (741eb92)
- unicode_space_decimal (914a209)
- since_version (1237cb9)
- pymath (df19d83)
- float_utils to v0.1.1 (f160bf6)


### Nimble 

- for nimble develop (232ebb9)
 

## 💼 Other




### NIM-BUG 

- round -> ^ -> sysFatal deadloop (d9b9182)


### Mysnprinf 

- use Nim's macro over C's (6fa0d45)


### Other 

- wip (b8a8ba6)
- wip dedup split_whitespace (6234674)
- dedup pystring,pybytes (16ab7d5)
- for n_math as pymath (6e969f5)
- for numTypes/floats into pkg/float_utils (63e0a98)
- test_datetime failed if sizeof(int) < 8 (5bda85e)
 

## 🚜 Refactor




### Stringlib 

- no dep on simperr (f62d3d7)


### Stringlib/split 

- merge common code (62a6072)
 