## rely pylib/Lib/nos

import pkg/posixos/touch as touchLib
import pkg/posixos/posix_like/unlink as unlinkLib
import pkg/posixos/posix_like/stat as statLib
import ./types

using self: Path

proc touch*(self; mode=0o666, exist_ok=true) =
  ## Create this file with the given access mode, if it doesn't exist.    
  touchLib.touch($self, mode, exist_ok)

proc unlink*(self) =
  ## for missing_ok==False
  unlinkLib.unlink $self

proc stat*(self): stat_result = statLib.stat($self)