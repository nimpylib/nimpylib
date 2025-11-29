
```Nim
>>> dumpTree:
...   (i*2 `for` i in s `if` i == 1)
... 

  Par  # may be `Bracket` for `[...]`; `Curly` for `{...}`
    Infix
      Ident "*"
      Ident "i"
      Command
        IntLit 2
        Command
          AccQuoted
            Ident "for"
          Infix
            Ident "in"
            Ident "i"
            Command
              Ident "s"
              Command
                AccQuoted
                  Ident "if"
                Infix
                  Ident "=="
                  Ident "i"
                  IntLit 1
```


```Nim
>>> dumpTree:
...   ((i, j) `for` i in s `for` j in s2 `if` i == 1)
... 

  TupleConstr  # may be `Bracket` for `[...]`; `Curly` for `{...}`
    Command
      TupleConstr
        Ident "i"
        Ident "j"
      Command
        AccQuoted
          Ident "for"
        Infix
          Ident "in"
          Ident "i"
          Command
            Ident "s"
            Command
              AccQuoted
                Ident "for"
              Infix
                Ident "in"
                Ident "s2"
                Command
                  Ident "n"
                  Command
                    AccQuoted
                      Ident "if"
                    Infix
                      Ident "=="
                      Ident "i"
                      IntLit 1

```

var compen = newPyDict

```Nim
>>> dumpTree:
...   {i: j+1 `for` i in s `for` j in s2 `if` i == 1}
... 

  TableConstr
    ExprColonExpr
      Ident "i"
      Infix
        Ident "+"
        Ident "j"
        Command
          IntLit 1
          Command
            AccQuoted
              Ident "for"
            Infix
              Ident "in"
              Ident "i"
              Command
                Ident "s"
                Command
                  AccQuoted
                    Ident "for"
                  Infix
                    Ident "in"
                    Ident "j"
                    Command
                      Ident "s2"
                      Command
                        AccQuoted
                          Ident "if"
                        Infix
                          Ident "=="
                          Ident "i"
                          IntLit 1
```
