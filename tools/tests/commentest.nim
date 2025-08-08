
import std/os
from std/strutils import find, split

when declared(stderr):
  template err(m: string) = stderr.writeLine m
else:
  template err(m: string) = echo m

template implExecCmdEx(sym){.dirty.} =
  template myExecCmdEx(vs: varargs[untyped]): tuple = sym vs

const nims = defined(nimscript)
when nims: implExecCmdEx gorgeEx
else:
  import std/osproc  
  implExecCmdEx execCmdEx

when nims:
  proc matchFileExt(p, ext: string): bool =
    let idx = p.searchExtPos
    if idx < 0: return
    cmpPaths(p[idx .. ^1], ext) == 0

iterator walkDirWithExt(d, ext: string): string =
  when nims:
    for path in listFiles d:
      if not path.matchFileExt ext:
        continue
      yield path
  else:
    for i in walkFiles(d / ('*' & ext)): yield i
  

using codepath: string
proc collectIOComment*(codepath): tuple[input, output: string] =
  let
    source = readFile codepath
    hi = source.high
    hi1s = hi - 1

  var
    idx: int
    cur: char
  template cur_next =
    idx.inc
    cur = source[idx]
  while true:
    idx = source.find('#', idx)
    if idx < 0 or idx == hi1s: return
    cur_next
    template isCWithSp(c: char): bool = cur == c and (cur_next;cur == ' ')
    template addTillLineEnd(res: var string) =
      # we know such a comment is often short
      while idx < hi:
        cur_next
        if cur == '\r':
          if idx == hi:
            res.add cur
            return
          cur_next
        if cur == '\n':
          res.add cur
          break
        res.add cur
    if isCWithSp'<': result.input.addTillLineEnd
    elif isCWithSp'>': result.output.addTillLineEnd


const useDiffLib{.booldefine: "commentestUseDiffLib".} = off
#[
const useDiffLib
 compiles:
  {.push warning[UnusedImport]: off.}
  #`import experimental/diff` not works as here is not top-level,
  # but in a block
  include experimental/diff
  {.pop.}
]#

when useDiffLib:
  import experimental/diff
  import std/strformat
  type Finder = object
    s: string
    preidx, idx: int
    n: int
  template initFinder(ss: string): Finder = Finder(s: ss)
  proc getLine(f: var Finder, n: int): string =
    var idx: int
    while f.n <= n:
      var toStep = 1
      idx = f.s.find('\n', f.idx)
      if idx < 0: 
        toStep = 0
        idx = f.s.high
        f.n.inc
        assert f.n == n
        break
      f.preidx = f.idx
      if likely(idx > 0) and (idx.dec; f.s[idx] == '\r'):
        idx.dec
        toStep = 2
      f.idx = idx+toStep
      f.n.inc
    if idx < 0:
      # idx == -1 here iff file startswith "\r\n" and n==0
      return
    result = f.s[f.preidx..f.idx]
  proc showLine(lineNo: int, line: string): string =
    &"{lineNo+1:>3} | `{line}`"
  proc showLine(f: var Finder, lineNo: int): string =
    showLine(lineNo, f.getLine lineNo)
  iterator diffTextCachedLine(s1, s2: string): tuple[s1, s2: string] =
    let
      diffs = diffText(s1, s2)
    var
      f1 = initFinder(s1)
      f2 = initFinder(s2)
    for it in diffs:
      yield (f1.showLine(it.startA),
       f2.showLine(it.startB)
      )

  proc diffRepr(s1, s2: string): string =
    for (i1, i2) in diffTextCachedLine(s1, s2):
      result.add "expected:\n=======\n"
      result.add i1
      result.add "\ngot:\n=======\n"
      result.add i2
      result.add '\n'

else:
  proc diffRepr(s1, s2: string): string =
    result.add "expected:\n=======\n"
    result.add s1.repr
    result.add "\n\ngot:\n======\n"
    result.add s2.repr


let nimc = quoteShell(getCurrentCompilerExe())
proc testFile*(codepath; targets: openArray[string] = ["c"]) =
  let tup = codepath.collectIOComment
  for target in targets:
    let cmd = nimc & ' ' & target & " -r --usenimcache --hints:off --warnings:off " & quoteShell codepath.absolutePath
    let ret = myExecCmdEx(
      cmd,
      input = tup.input,
    )
    let suc = ret.exitCode == 0
    if not suc:
      err codepath & " failed to run on " & target & " target, msg: " & ret.output
    elif ret.output != tup.output:
      err codepath & " result diff!\n" & diffRepr(tup.output, ret.output)

proc testAllNimFiles*(dirpath: string; targets: openArray[string] = ["c"]) =
  for path in walkDirWithExt(dirpath, ".nim"):
    testFile path, targets

when isMainModule:
  var targets = @["c"]
  if paramCount() > 1: targets = paramStr(2).split ' '
  testAllNimFiles paramStr 1
