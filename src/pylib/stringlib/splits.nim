
import ./split/[
  common, split_whitespace, rsplit_whitespace, gen
]

proc_gen_split split,  seq, add
proc_gen_split rsplit, seq, add
proc splitlines*[S](self: S, keepends = false): seq[S] =
  for i in splitlines[S](self, keepends): result.add(i)
