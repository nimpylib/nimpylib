
import ./import_utils
importPyLib()
pyimport stat, nil
pyimport unittest
pyimport os
import ./support/os_helper
import ./support/io_helper

type StatModule = object
template statmod(self): untyped = StatModule
{.experimental: "dotOperators".}
#template `.`(self: typedesc[StatModule]; attr: untyped, args: varargs[untyped]): untyped = stat.attr(args)
import std/macros
macro `.`(self: typedesc[StatModule]; attr: untyped): untyped =
  result = newDotExpr(ident"stat", attr)
macro `.()`(self: typedesc[StatModule]; attr: untyped, args: varargs[untyped]): untyped =
  result = newCall(newDotExpr(ident"stat", attr))
  for i in args: result.add i
#[
macro statmod(self): typed =
  let ls = bindSym("unittest", brForceOpen)
  ls.expectKind nnkOpenSymChoice
  for i in ls:
    echo i.symKind
]#
static:
    echo stat.S_IMODE(1)

const
    format_funcs = ["S_ISBLK", "S_ISCHR", "S_ISDIR", "S_ISFIFO", "S_ISLNK",
                    "S_ISREG", "S_ISSOCK", "S_ISDOOR", "S_ISPORT", "S_ISWHT"]

proc deepReplaceWithNew(stmts: NimNode, newExpr: NimNode, itPred: proc(x: NimNode): bool) =
  assert stmts.len > 0
  for i in 0..<stmts.len:
    let it{.inject.} = stmts[i]
    if itPred(it):
      stmts[i] = newExpr
    elif it.len > 0:
      it.deepReplaceWithNew newExpr, itPred

template deepReplaceItWithNew(stmts: NimNode, itExpr; newExpr: NimNode){.dirty.} =
  stmts.deepReplaceWithNew(newExpr) do(it: NimNode) -> bool: itExpr

macro static_for_format_funcs(x; body) =
  result = newStmtList()
  let blkPre = "static_format_" & x.strval

  for i in format_funcs:
    let blkName = genSym(nskLabel, blkPre & $i)
    body.deepReplaceItWithNew it.kind == nnkContinueStmt, nnkBreakStmt.newTree(blkName)
    result.add newBlockStmt(
      blkName,
      newStmtList(
        newConstStmt(x, newStrLitNode i),
        body
    ))
#[
macro static_for(x_in_static_iter; body) =
  let
    x = x_in_static_iter[0]
    static_iter = x_in_static_iter[1]
  bindSym"static_forAux".newCall(x, static_iter, body)
]#
macro callMethod(self; funcname: static[string], arg1; elseDo): untyped =
  let
    attr = newDotExpr(self, ident funcname)
    call = attr.newCall arg1
  quote do:
    when compiles(`call`): `call`
    else: `elseDo`

proc assertS_IS_impl(self: auto, name: static[PyStr], mode: auto) =
    # test format, lstrip is for S_IFIFO
    let fmt = getattr(self.statmod, "S_IF" + name.lstrip("F"))
    self.assertEqual(self.statmod.S_IFMT(mode), fmt)
    # test that just one function returns true
    const testname = "S_IS" + name
    static_for_format_funcs funcname:
        let res = callMethod(self.statmod, funcname, mode):
            if funcname == testname:
                raise newException(ValueError, funcname)
            else:
                continue
        if funcname == testname:
          self.assertTrue(res)
        else:
          self.assertFalse(res)

from ../stat_impl/types import Mode
proc get_st_mode(fname: string, lstat: bool): Mode =
  (
    if lstat: os.lstat(fname)
    else: os.stat(fname)
  ).st_mode

class TestFilemodeStat(unittest.TestCase):
    formats = {"S_IFBLK", "S_IFCHR", "S_IFDIR", "S_IFIFO", "S_IFLNK",
               "S_IFREG", "S_IFSOCK", "S_IFDOOR", "S_IFPORT", "S_IFWHT"}
    def setUp(self):
        try:
            os.remove(TESTFN)
        except OSError:
            try:
                os.rmdir(TESTFN)
            except OSError:
                pass
        try:
          os.remove(chmodTESTFN)
        except OSError: pass

    def tearDown(self):
      self.setUp()
  

    def get_mode(self, fname=TESTFN, lstat=True):
        st_mode = get_st_mode(fname, lstat)
        modestr = self.statmod.filemode(st_mode)
        return (st_mode, modestr)
    define assertS_IS(self, name, mode):
      assertS_IS_impl(self, name, mode)

    #@os_helper.skip_unless_working_chmod
    def test_mode(self):
        create_writable_file(chmodTESTFN)
        #with open(chmodTESTFN, "w"): pass
        os_name = getattr(os, "name", "")
        if os_name == "posix":
            os.chmod(chmodTESTFN, 0o700)

            (st_mode, modestr) = self.get_mode(chmodTESTFN)

            self.assertEqual(modestr, "-rwx------")
            self.assertS_IS("REG", st_mode)
            imode = self.statmod.S_IMODE(st_mode)
            self.assertEqual(imode,
                             self.statmod.S_IRWXU)
            self.assertEqual(self.statmod.filemode(imode),
                             "?rwx------")

            os.chmod(chmodTESTFN, 0o070)
            (st_mode, modestr) = self.get_mode(chmodTESTFN)
            self.assertEqual(modestr, "----rwx---")
            self.assertS_IS("REG", st_mode)
            self.assertEqual(self.statmod.S_IMODE(st_mode),
                             self.statmod.S_IRWXG)

            os.chmod(chmodTESTFN, 0o007)
            (st_mode, modestr) = self.get_mode(chmodTESTFN)
            self.assertEqual(modestr, "-------rwx")
            self.assertS_IS("REG", st_mode)
            self.assertEqual(self.statmod.S_IMODE(st_mode),
                             self.statmod.S_IRWXO)

            os.chmod(chmodTESTFN, 0o444)
            (st_mode, modestr) = self.get_mode(chmodTESTFN)
            self.assertS_IS("REG", st_mode)
            self.assertEqual(modestr, "-r--r--r--")
            self.assertEqual(self.statmod.S_IMODE(st_mode), 0o444)
        else:
            os.chmod(chmodTESTFN, 0o500)
            (st_mod, modes) = self.get_mode(chmodTESTFN)
            self.assertEqual(modes[0:3], "-r-")
            self.assertS_IS("REG", st_mod)
            self.assertEqual(self.statmod.S_IMODE(st_mod), 0o444)

            os.chmod(chmodTESTFN, 0o700)
            (st_mod, modes) = self.get_mode(chmodTESTFN)
            self.assertEqual(modes[0:3], "-rw")
            self.assertS_IS("REG", st_mod)
            self.assertEqual(self.statmod.S_IFMT(st_mod),
                             self.statmod.S_IFREG)
            self.assertEqual(self.statmod.S_IMODE(st_mod), 0o666)


when isMainModule:
  unittest.main()
