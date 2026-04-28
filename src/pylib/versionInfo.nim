## to be imported by ./version
# Values for PY_RELEASE_LEVEL */


const
  Major* = 0
  Minor* = 9
  Patch* = 15

  ReleaseLevel* = "alpha"
  Serial* = 0


const sep = '.'
template asVersion(major, minor, patch: int): string =
  $major & sep & $minor & sep & $patch

const
  Version* = asVersion(Major, Minor, Patch)
