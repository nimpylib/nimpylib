
import ./import_utils
importTestPyLib tempfile
pyimport unittest
pyimport os
pyimport shutil

import std/unittest
const HasIO = declared(TemporaryFileWrapper)  #TODO:io
when HasIO:
  from std/os import fileExists
suite "Lib/tempfile":
  skipUnless HasIO, "require io": test "NamedTemporaryFile":
    var tname: string
    const cont = b"content"
    with NamedTemporaryFile() as f:  # open in binary mode by default
      tname = f.name
      f.write(cont)
      f.flush()
      check fileExists f.name
      f.seek(0)
      check f.read() == cont
    check not fileExists tname


  test "delete_false":
    let t = tempfile.TemporaryDirectory(delete=false)
    t.close()
    let working_dir = t.name
    check path.isdir(working_dir)
    shutil.rmtree(working_dir)

