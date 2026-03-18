
import ../stringlib/err
export err
type
  SystemExit* = object of CatchableError
  AttributeError* = object of CatchableError
  NameError* = object of CatchableError
