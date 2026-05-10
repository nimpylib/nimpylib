
import std/options
import pkg/pystdlib/n_sys as n_sys_lib
export n_sys_lib
import pkg/pystdlib/sys_impl/geninfos
import ../version as versionLib
template asis[T](x: T): T = x
genImplementation asis, none(string)

