
import ./pylifecycle
template decl(name; T:untyped=int) =
  type name* = distinct T

decl Signals, PySignal
decl Handlers
decl Sigmasks
