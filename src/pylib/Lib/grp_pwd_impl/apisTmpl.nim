#[
Index Attribute Meaning
0 gr_name "the name of the group"
1 gr_passwd "the (encrypted) group password; often empty"
2 gr_gid "the numerical group ID"
3 gr_mem "all the group member’s user names"


Index Attribute Meaning
0 pw_name "Login name"
1 pw_passwd "Optional encrypted password"
2 pw_uid "Numerical user ID"
3 pw_gid "Numerical group ID"
4 pw_gecos "User name or comment field"
5 pw_dir "User home directory"
6 pw_shell "User command interpreter"

]#


import ../../Objects/structseq
import ./impl

export impl, structseq

template genApis*(List, Str; raiseErrno; uniqueId: string){.dirty.} =
  declMapCTypeToNim cMnim, uniqueId:
    (ntyPtr, List[Str])

  proc toPyNim*(s: cstringArray; res: var List[Str]) =
    #res.setLen res.len + s.len
    res = `new List`[Str]()
    var i = 0
    while true:
      let e = s[i]
      if e.isNil: break
      res.add $e
      i.inc

  template genGetXOrImpl(namOrId; X; Res: typedesc, ctype, ntype){.dirty.} =
    proc `get X namOrId`*(name: ntype): `struct Res` =
      var result_t: `struct Res` #[
      #XXX: NIM-BUG: maybe too many layer of template? tho `struct Res` is `ref`,
      here using `x.toPyNim result` makes nim Error:
'result' is of type <struct_Passwd> which cannot be captured as
it would violate memory safety, declared here:
src/pylib/Lib/grp_pwd_impl/apisTmpl.nim(55, 18); using '-d:nimNoLentIterators'
helps in some cases. Consider using a <ref T> which can be captured.]#
      let err = `get X namOrId`(ctype(name), proc (x: ptr Res) =
        x.toPyNim result_t
      )
      if err != 0:
        raiseErrno(err)
      result_t

  template genGetXNamOr(id; X; Res: typedesc){.dirty.} =
    cstructGenNamedTuple Res, mapCTypeToNim = cMnim

    genGetXOrImpl(id,  X, Res, id, BiggestInt)
    genGetXOrImpl(nam, X, Res, cstring, string)

    iterator `get X all`*(): `struct Res` =
      var res{.noInit.}: `struct Res`
      for x in `get X all impl`():
        x.toPyNim res
        yield res

    template `exp X`*{.dirty.} =
      export `get X id`, `get X nam`, `get X all`, `struct Res`

  genGetXNamOr(Gid, gr, Group)
  genGetXNamOr(Uid, pw, Passwd)

template genApis*(List, Str; raiseErrno){.dirty.} =
  genApis(List, Str, raiseErrno, "grp_pwd_impl.apis@" & $List & $Str)



