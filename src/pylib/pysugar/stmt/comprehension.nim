import std/macros
import ./utils
import ../../builtins/[list, set, dict]

type
  ClauseKind = enum ckFor, ckIf
  Clause = object
    kind: ClauseKind
    loopVar: NimNode
    iterable: NimNode
    condition: NimNode

func isClauseStart(n: NimNode): bool =
  if n.kind == nnkCommand and n.len == 2:
    let head = n[0]
    if head.kind == nnkAccQuoted and head.len == 1:
      let ident = head[0]
      if ident.eqIdent("for") or ident.eqIdent("if"):
        return true
  return false

proc parseChain(n: NimNode): tuple[target: NimNode, clauses: seq[Clause]] =
  # Base case: The command that starts the chain
  # We expect n to be Command(Target, ClauseStart)
  if n.kind == nnkCommand and n.len == 2 and isClauseStart(n[1]):
    result.target = n[0]
    var curr = n[1]
    while curr != nil:
      # curr is Command(AccQuoted(for/if), Content)
      let kindIdent = curr[0][0]
      let content = curr[1]
      
      var nextNode: NimNode = nil
      
      if kindIdent.eqIdent("for"):
        # content should be Infix(in, loopVar, iterable)
        if content.kind == nnkInfix and content.len == 3 and content[0].eqIdent("in"):
          let loopVar = content[1]
          let rhs = content[2]
          var iterable: NimNode
          
          # Check if rhs contains next clause
          if rhs.kind == nnkCommand and rhs.len == 2 and isClauseStart(rhs[1]):
            iterable = rhs[0]
            nextNode = rhs[1]
          else:
            iterable = rhs
            nextNode = nil
            
          result.clauses.add Clause(kind: ckFor, loopVar: loopVar, iterable: iterable)
        else:
          # Invalid for clause, stop parsing or error?
          # Treat as end of chain?
          break
      elif kindIdent.eqIdent("if"):
        var condition: NimNode
        if content.kind == nnkCommand and content.len == 2 and isClauseStart(content[1]):
          condition = content[0]
          nextNode = content[1]
        else:
          condition = content
          nextNode = nil
        result.clauses.add Clause(kind: ckIf, condition: condition)
        
      curr = nextNode
    return

  # Recursive steps for nodes that might contain the chain on the right
  var childIdx = -1
  
  case n.kind
  of nnkInfix: childIdx = 2
  of nnkPrefix: childIdx = 1
  of nnkCommand, nnkCall: 
    if n.len > 0: childIdx = n.len - 1
  else: discard
  
  if childIdx != -1:
    let sub = parseChain(n[childIdx])
    if sub.target != nil:
      # Found chain in child. Reconstruct n.
      let newNode = n.copyNimNode()
      for i in 0 ..< n.len:
        if i == childIdx:
          newNode.add(sub.target)
        else:
          newNode.add(n[i])
      result.target = newNode
      result.clauses = sub.clauses
      return

  # Not a comprehension chain
  result.target = nil

proc generateLoops(clauses: seq[Clause], innerBody: NimNode): NimNode =
  result = innerBody
  # Process clauses in reverse order
  for i in countdown(clauses.len - 1, 0):
    let c = clauses[i]
    case c.kind
    of ckFor:
      result = newNimNode(nnkForStmt).add(c.loopVar, c.iterable, newStmtList(result))
    of ckIf:
      result = newIfStmt((c.condition, newStmtList(result)))

proc rewriteCompensiveImpl*(n: NimNode, toPyExpr: proc (ele: NimNode): NimNode{.raises: [].}): tuple[rewriten: bool, res: NimNode] =
  ## like `rewriteCompensive`_ but no check on kind of `n` and assumes n.len > 0
  template ret(node) =
    result.res = node
    return

  if n.len != 1:
    ret n

  let first = n[0]
  var 
    targetExpr: NimNode
    clauses: seq[Clause]
    isDict = false
    keyExpr: NimNode # only for dict

  if n.kind == nnkTableConstr:
    # Dict comprehension: {k: v for ...}
    # first is ExprColonExpr(k, v_chain)
    if first.kind == nnkExprColonExpr and first.len == 2:
      let parsed = parseChain(first[1])
      if parsed.target != nil:
        isDict = true
        keyExpr = first[0]
        targetExpr = parsed.target
        clauses = parsed.clauses
      else:
        ret n
    else:
      ret n
  else:
    # List/Set/Gen comprehension
    let parsed = parseChain(first)
    if parsed.target != nil:
      targetExpr = parsed.target
      clauses = parsed.clauses
    else:
      ret n

  result.rewriten = true
  
  # Apply toPyExpr
  targetExpr = toPyExpr(targetExpr)
  if isDict:
    keyExpr = toPyExpr(keyExpr)
    
  for i in 0 ..< clauses.len:
    if clauses[i].kind == ckFor:
      clauses[i].iterable = toPyExpr(clauses[i].iterable)
    elif clauses[i].kind == ckIf:
      clauses[i].condition = toPyExpr(clauses[i].condition)

  # Helper to infer type
  proc inferType(e: NimNode): NimNode =
    let funcBody = generateLoops(clauses, nnkReturnStmt.newTree(e))
    let body = newCall(quote do:
      proc (): auto = `funcBody`
    )
    getTypeof body

  result.res = case n.kind
  of nnkBracket:
    # List comprehension
    let elemType = inferType(targetExpr)
    
    let resSym = genSym(nskVar, "res")
    let appendStmt = newCall(newDotExpr(resSym, ident("add")), targetExpr)
    
    let outerLoop = generateLoops(clauses, appendStmt)
    
    let newListId = bindSym"newPyList"
    
    quote do:
      block:
        var `resSym` = newSeq[`elemType`]()
        `outerLoop`
        `newListId`(`resSym`)

  of nnkCurly:
    # Set comprehension
    let elemType = inferType(targetExpr)
    
    let resSym = genSym(nskVar, "res")
    let addStmt = newCall(bindSym("add"), resSym, targetExpr)

    let outerLoop = generateLoops(clauses, addStmt)

    let newSetId = bindSym"newPySet"
    quote do:
      block:
        var `resSym` = `newSetId`[`elemType`]()
        `outerLoop`
        `resSym`

  of nnkTableConstr:
    # Dict comprehension
    let kType = inferType(keyExpr)
    let vType = inferType(targetExpr)
    
    let resSym = genSym(nskVar, "res")
    
    let assignStmt = newAssignment(
      newNimNode(nnkBracketExpr).add(resSym, keyExpr),
      targetExpr
    )
    
    let outerLoop = generateLoops(clauses, assignStmt)
    
    let newDictId = bindSym"newPyDict"
    quote do:
      block:
        var `resSym` = `newDictId`[`kType`, `vType`]()
        `outerLoop`
        `resSym`

  of nnkPar: # not nnkTupleConstr
    # Generator expression
    let elemType = inferType(targetExpr)
    
    let yieldStmt = newNimNode(nnkYieldStmt).add(targetExpr)
    let outerLoop = generateLoops(clauses, yieldStmt)
    
    let iterSym = genSym(nskIterator, "gen")
    
    quote do:
      iterator `iterSym`(): `elemType` {.closure.} =
        `outerLoop`
      `iterSym`
  else:
    error"unreachable"

proc rewriteCompensive*(n: NimNode; toPyExpr: proc (ele: NimNode): NimNode{.raises: [].}): tuple[rewriten: bool, res: NimNode] =
  if n.kind notin {nnkBracket, nnkCurly, nnkTableConstr, nnkPar} or n.len == 0:
    return (false, n)
  rewriteCompensiveImpl(n, toPyExpr)

when isMainModule:
  proc asIs(x: NimNode): NimNode = x
  macro comp(n: untyped): untyped =
    result = rewriteCompensive(n, asIs).res
    #echo result.repr

  let l = comp [i `for` i in [1, 2, 3] `if` i > 1]
  assert @l == @[2, 3]
  
  const tab = [[1,2,-1], [3,4,-3]]
  let l2 = comp [i+1 `for` row in tab `for` i in row `if` i > 0]
  assert @l2 == @[2,3,4,5]

  let s = comp {i*2 `for` i in [1, 2, 3] `if` i > 1}
  assert s.len == 2
  assert 4 in s
  assert 6 in s

  let d = comp {i: i+1 `for` i in [1, 2, 3] `if` i > 1}
  assert d.len == 2
  assert d[2] == 3
  assert d[3] == 4

  let g = comp (i `for` i in [1, 2, 3] `if` i > 1)
  import std/sequtils
  assert toSeq(g()) == @[2, 3]
  
  echo "All tests passed!"

