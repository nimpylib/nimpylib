# Comprehension

## desc

In short, in nimpylib, for list/set/dict Comprehension, enclose "for" and "if" in backticks.

### Alternative
For math-like notation, see also [nim-meta/math_comprehension](https://github.com/nim-meta/math_comprehension), like:

```
{ i | i ∈ {1, 2}, i>1 }
```

## rewrite
```
expr "for" loopVar "in" iterable ... ["if" cond "] -> expr "`for`" loopVar "in" iterable ... ["`if`" cond "]
```


