
```Nim
>>> dumpTree:
...   (i | i in s, i == 1)
... 

  TupleConstr  # may be `Bracket` for `[...]`; `Curly` for `{...}`
    Infix
      Ident "in"
      Infix
        Ident "|"
        Ident "i"
        Ident "i"
      Ident "s"
    Infix
      Ident "=="
      Ident "i"
      IntLit 1
```


```Nim
>>> dumpTree:
...   ((i, j) | i in s, j in s2, i == 1)
... 

  TupleConstr
    Infix
      Ident "in"
      Infix
        Ident "|"
        TupleConstr
          Ident "i"
          Ident "j"
        Ident "i"
      Ident "s"
    Infix
      Ident "in"
      Ident "j"
      Ident "s2"
    Infix
      Ident "=="
      Ident "i"
      IntLit 1
```

var compen = newPyDict

```Nim
>>> dumpTree:
...   {i: j | i in s, j in s2, i == 1}
... 

  TableConstr
    ExprColonExpr
      Ident "i"
      Infix
        Ident "in"
        Infix
          Ident "|"
          Ident "j"
          Ident "i"
        Ident "s"
    Infix
      Ident "in"
      Ident "j"
      Ident "s2"
    Infix
      Ident "=="
      Ident "i"
      IntLit 1
```
