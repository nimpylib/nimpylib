import std/macros
import ../../builtins/[list, set, dict]

# We need to identify the structure:
# (Expr | LoopVar) in Iterable
# This is parsed as:
# Infix(Ident("in"), Infix(Ident("|"), Expr, LoopVar), Iterable)

func isCompensiveInfix(n: NimNode): bool =
  if n.kind == nnkInfix and n.len == 3 and n[0].eqIdent("in"):
    let lhs = n[1]
    if lhs.kind == nnkInfix and lhs.len == 3 and lhs[0].eqIdent("|"):
      return true
  return false

proc extractCompensiveParts(n: NimNode): tuple[expr, loopVar, iterable: NimNode] =
  # n is Infix(in, Infix(|, expr, loopVar), iterable)
  let lhs = n[1]
  result.expr = lhs[1]
  result.loopVar = lhs[2]
  result.iterable = n[2]

proc generateLoops(clauses: openArray[NimNode], innerBody: NimNode): NimNode =
  # clauses are the remaining children of the constructor
  # clause can be:
  # - Infix(in, loopVar, iterable) -> for loop
  # - Expr -> if condition
  
  result = innerBody
  
  # We process clauses in reverse order to nest them correctly
  for i in countdown(clauses.len - 1, 0):
    let clause = clauses[i]
    if clause.kind == nnkInfix and clause.len == 3 and clause[0].eqIdent("in"):
      # for loop
      let loopVar = clause[1]
      let iterable = clause[2]
      result = newNimNode(nnkForStmt).add(loopVar, iterable, newStmtList(result))
    else:
      # if condition
      result = newIfStmt((clause, newStmtList(result)))

proc generateLoops(loopVar, iterable: NimNode, clauses: openArray[NimNode], innerBody: NimNode): NimNode =
  # Overload to include the first loop
  result = generateLoops(clauses, innerBody)
  result = newNimNode(nnkForStmt).add(loopVar, iterable, newStmtList(result))

proc rewriteCompensiveImpl*(n: NimNode, toPyExpr: proc (ele: NimNode): NimNode{.raises: [].}): tuple[rewriten: bool, res: NimNode] =
  ## like `rewriteCompensive`_ but no check on kind of `n` and assumes n.len > 0
  template ret(node) =
    result.res = node
    return

  let first = n[0]
  var 
    targetExpr: NimNode
    loopVar: NimNode
    iterable: NimNode
    isDict = false
    keyExpr: NimNode # only for dict

  if n.kind == nnkTableConstr:
    # Dict comprehension: {k: v | i in s, ...}
    # first is ExprColonExpr(k, v_node)
    # v_node is Infix(in, Infix(|, v, i), s)
    if first.kind == nnkExprColonExpr and first.len == 2:
      if isCompensiveInfix(first[1]):
        isDict = true
        keyExpr = first[0]
        let parts = extractCompensiveParts(first[1])
        targetExpr = parts.expr
        loopVar = parts.loopVar
        iterable = parts.iterable
      else:
        ret n
    else:
      ret n
  else:
    # List/Set/Gen comprehension
    if isCompensiveInfix(first):
      let parts = extractCompensiveParts(first)
      targetExpr = parts.expr
      loopVar = parts.loopVar
      iterable = parts.iterable
    else:
      ret n

  result.rewriten = true
  iterable = toPyExpr iterable
  targetExpr = toPyExpr targetExpr

  # Collect subsequent clauses
  var clauses: seq[NimNode] = @[]
  # The first clause is the one embedded in the first element
  # We need to reconstruct it as a standard clause node for generateLoops?
  # No, generateLoops handles the *additional* clauses.
  # The first loop is defined by loopVar and iterable extracted above.
  
  # Wait, the structure is:
  # [ (x | i in s), (j in s2), (cond) ]
  # The first element contains the yield expr and the first loop.
  # Subsequent elements are subsequent clauses.
  
  for i in 1 ..< n.len:
    clauses.add(n[i])

  # Helper to infer type of an expression within the loop context
  proc getTypeOf(e: NimNode): NimNode =
    newCall("typeof", e)
  proc inferType(e: NimNode): NimNode =
    let funcBody = generateLoops(loopVar, iterable, clauses, nnkReturnStmt.newTree(e))
    let body = newCall(quote do:
      proc (): auto = `funcBody`
    )
    getTypeof body

  result.res = case n.kind
  of nnkBracket:
    # List comprehension
    let elemType = inferType(targetExpr)
    
    let resSym = genSym(nskVar, "res")
    let appendStmt = newCall(newDotExpr(resSym, ident("append")), targetExpr)
    
    # The outermost loop
    let outerLoop = generateLoops(loopVar, iterable, clauses, appendStmt)
    
    let newListId = bindSym"newPyList"
    
    quote do:
      block:
        var `resSym` = `newListId`[`elemType`]()
        `outerLoop`
        `resSym`

  of nnkCurly:
    # Set comprehension
    let elemType = inferType(targetExpr)
    
    let resSym = genSym(nskVar, "res")
    let addStmt = newCall(bindSym("add"), resSym, targetExpr)
    
    let outerLoop = generateLoops(loopVar, iterable, clauses, addStmt)

    let newSetId = bindSym"newPySet"
    quote do:
      block:
        var `resSym` = `newSetId`[`elemType`]()
        `outerLoop`
        `resSym`

  of nnkTableConstr:
    # Dict comprehension
    keyExpr = toPyExpr keyExpr
    let kType = inferType(keyExpr)
    let vType = inferType(targetExpr)
    
    let resSym = genSym(nskVar, "res")
    
    let assignStmt = newAssignment(
      newNimNode(nnkBracketExpr).add(resSym, keyExpr),
      targetExpr
    )
    
    let outerLoop = generateLoops(loopVar, iterable, clauses, assignStmt)
    
    let newDictId = bindSym"newPyDict"
    quote do:
      block:
        var `resSym` = `newDictId`[`kType`, `vType`]()
        `outerLoop`
        `resSym`

  of nnkTupleConstr:
    # Generator expression
    let elemType = inferType(targetExpr)
    
    let yieldStmt = newNimNode(nnkYieldStmt).add(targetExpr)
    let outerLoop = generateLoops(loopVar, iterable, clauses, yieldStmt)
    
    let iterSym = genSym(nskIterator, "gen")
    
    quote do:
      iterator `iterSym`(): `elemType` {.closure.} =
        `outerLoop`
      `iterSym`
  else:
    error"unreachable"

proc rewriteCompensive*(n: NimNode; toPyExpr: proc (ele: NimNode): NimNode{.raises: [].}): tuple[rewriten: bool, res: NimNode] =
  if n.kind notin {nnkBracket, nnkCurly, nnkTableConstr, nnkTupleConstr} or n.len == 0:
    return (false, n)
  rewriteCompensiveImpl(n, toPyExpr)

when isMainModule:
  proc asIs(x: NimNode): NimNode = x
  macro comp(n: untyped): untyped =
    #echo treeRepr n
    result = rewriteCompensive(n, asIs).res
    # echo result.repr

  let l = comp [i | i in [1, 2, 3], i > 1]
  assert @l == @[2, 3]
  
  let s = comp {i | i in [1, 2, 3], i > 1}
  assert s.len == 2
  assert 2 in s
  assert 3 in s

  let d = comp {i: i*2 | i in [1, 2, 3], i > 1}
  assert d.len == 2
  assert d[2] == 4
  assert d[3] == 6

  let g = comp (i | i in [1, 2, 3], i > 1)
  import std/sequtils
  assert toSeq(g()) == @[2, 3]
  
  echo "All tests passed!"

