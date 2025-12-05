
template cmpBody(op, a, b) =
  const opS = astToStr(op)
  # Shortcut: if the lengths differ, the arrays differ
  when opS == "==":
    if a.len != b.len: return
  elif opS == "!=":
    if a.len != b.len: return true

  for i, e in a:
    if e != b[i]:
      # We have an item that differs.
      result = op(e, b[i])
      return
  # No more items to compare -- compare sizes
  result = op(a.len, b.len)

func `<=`*[A, B](a: openarray[A], b: openarray[B]): bool = cmpBody `<=`, a, b
func `<`* [A, B](a: openarray[A], b: openarray[B]): bool = cmpBody `<`,  a, b
