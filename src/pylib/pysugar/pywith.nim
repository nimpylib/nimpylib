import std/macros

# Python-like with
# Should support both normal Nim types that have a `close` proc defined
# or Python-like context managers (hasn't been tested thoroughly)

type
  # I tried doing matching with `compiles` but it didn't work...
  CtxManagerPy[T] = concept c
    c.enter() is T
    c.exit()
  
  CtxManager[T] = concept c
    c.open() is T
    c.close()

macro with*(args: varargs[untyped]): untyped =
  ## Python-like with statement. Supports most of the possible
  ## variants Python with statement supports. Context managers
  ## are supported but need to use `enter()` and `exit()` or `open()`
  ## and `close()` instead of the underscored names.
  let hi = args.len - 1
  # Body of the with statement
  let body = args[hi]

  # Code to be inserted before the body
  var beforeStmt = newStmtList()
  # Code to be inserted in the finally branch of the try: finally: 
  var finallyStmt = newStmtList()

  # Skip last element (the body)
  for i in 0 ..< hi:
    let arg = args[i]
    # Variable name for the injected variable. If the name is empty, then
    # the user won't see it, but we generate it anyway so that you can
    # "discard" context managers or values in `with` as in Python
    template genVarName: NimNode = genSym(nskVar, "injectedVar")
    # nnkInfix -> "with A() as a:"
    # nnkIdent -> "with something:"
    # otherwise - calls like "with myCall():", etc
    let (varName, exp) = 
      if arg.kind == nnkInfix and arg[0].eqIdent"as":
        (arg[2], arg[1])
      elif arg.kind == nnkInfix: (genVarName(), arg)
      else: (genVarName(), arg)

    # Variable name for the context manager itself (if it exists)
    let ctx = 
      if exp.kind == nnkIdent: exp 
      else: genSym(nskVar, "ctxMgr")
    
    # Cache if this expression is a context manager (python style or normal)
    let
      sctx = $ctx
      isCtxOpen = genSym(nskConst, sctx & "IsOpen")
      isCtxEnter = genSym(nskConst, sctx & "IsEnter")

    # If it's a context manager, we create an additional variable for it
    # and get the variable via the open call
    # Otherwise just assign the variable to the expression
    beforeStmt.add quote do:
      {.push hint[XDeclaredButNotUsed]: off.}
      const `isCtxOpen` = `exp` is CtxManager
      const `isCtxEnter` = `exp` is CtxManagerPy
      {.pop.}
    
      when `isCtxOpen` or `isCtxEnter`:
        var `ctx` = `exp`
        var `varName` = when `isCtxOpen`: `ctx`.open() else: `ctx`.enter()
      else:
        var `varName` = `exp`
    
    # Use insert instead of add so that finally statements are inserted
    # in the reverse order - consistent with what Python does
    finallyStmt.insert(0, quote do:
      when `isCtxOpen`: `ctx`.close()
      elif `isCtxEnter`: `ctx`.exit()
      else: `varName`.close()
    )
  
  result = quote do:
    block:
      `beforeStmt`
      try:
        `body`
      finally:
        `finallyStmt`
  
  when defined(pylibDebug):
    echo repr result
