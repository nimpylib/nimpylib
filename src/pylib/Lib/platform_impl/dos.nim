
import std/[
  #[re,]# pegs, strutils, osproc, sequtils,
]
import ../sys

proc norm_version(version: string, build=""): string =
  ##[ `_norm_version`
   Normalize the version and build strings and return a single
      version string using the format major.minor.build (or patchlevel).
  ]##
  var l = version.split('.')
  if build != "":
      l.add(build)
  let strings =
    try: l.mapIt $parseInt(it)
    except ValueError: l
  strutils.join(strings[0..2], ".")

{.push warning[ImplicitDefaultValue]: off.}
proc private_syscmd_ver*(system, release, version="",
               supported_platforms = @["win32", "win16", "dos"]
    ): tuple[system, release, version: string] =
    ## `_syscmd_ver`
    {.pop.}
    if sys.platform not_in supported_platforms:
        return (system, release, version)

    # Try some common cmd strings
    var info: string
    block loop:
      for cmd in ["ver", "command /c ver", "cmd /c ver"]:
        try:
            info = osproc.execProcess(cmd,
              options = {poUsePath, poEvalCommand}
            )
            break loop
        except OSError: # as why:
            #print("Command %s failed: %s" % (cmd, why))
            continue
      return (system, release, version)

    # re"""(?:([\w ]+) ([\w.]+) .*\[.* ([\d.]+)\])"""
    # .. note:: the `system` pattern wants to
    #  match as more as words before ' ' @ '[' pattern until the last one (not included)
    let ver_output = peg"""
        s <- system ' ' release ' ' @ '[' version ']'
        release_pat <- (\w / '.')+
        system <- {( !(' ' release_pat ' ' '[') .)+}
        release <- {release_pat}
        version <- @ ' ' {(\d / '.')+}
    """

    # Parse the output
    info = info.strip()
    #let m = info.findAll(ver_output)
    #if m.len > 0:
    var m = newSeq[string](3)
    if info.match(ver_output, m):
        result = (m[0], m[1], m[2])
        # Strip trailing dots from version and release
        if result.release[^1] == '.':
            result.release = result.release[0..^2]
        if result.version[^1] == '.':
            result.version = result.version[0..^2]
        # Normalize the version and build strings (eliminating additional
        # zeros)
        result.version = norm_version(result.version)
    else:
        result = (system, release, version)