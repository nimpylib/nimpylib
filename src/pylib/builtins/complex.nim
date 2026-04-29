## builtins.complex and its operators/methods.
## 
## Use `toNimComplex` and `pycomplex` to convert between PyComplex and Complex

#from ../noneType import NoneType
import pkg/py_version
import ../numTypes/private/hasindex

import pkg/pycomplex
export pycomplex

template complex*(real, imag: HasIndex): PyComplex{.
    pysince(3,8).} =
  bind pycomplex
  pycomplex(real.index(), imag.index())
