
import ./strimpl

import ../stringlib/percent_format
import pkg/pybuiltins/[asciiImpl, reprImpl]
proc tpyreprImpl(s: string): string = pyreprImpl(s)  ## XXX: as pyreprImpl has a optional arg: escape127 so mismatch

genPercentAndExport PyStr, tpyreprImpl, pyasciiImpl, disallowPercentb=true
