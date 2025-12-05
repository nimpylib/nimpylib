
import std/[
  osproc, strutils, sequtils,
]
const HasWMI = defined(pylib_can_compile_wmi)
import std/registry
when HasWMI:
  import std/[sugar,]
  import ../wmi
import ../../pysugar/unpack
template `:=`(lhs: untyped, rhs) =
  rhs.unpackValues(lhs)
import ../../private/envvarsCompat
from ../../collections_abc/cmpOA import `<=`

const HAS_SYS_GETWINDOWSVERSION = declared(sys.getwindowsversion)
when HAS_SYS_GETWINDOWSVERSION or HasWMI:
  import std/strformat

when HasWMI:
  proc private_wmi_query(table: string, keys: openArray[string]): seq[string] =
    let table = if table == "OS": "Win32_OperatingSystem"
    elif table == "CPU": "Win32_Processor"
    else:
      raise newException(ValueError, "unknown WMI table: " & table)
    let data = wmi.exec_query(fmt"SELECT {keys.join','} FROM {table}").split('\0')
    let dict_data = collect:
      for ii in data:
        let i = ii.split('=', 2)
        {i[0]: i[1]}
    collect:
      for k in keys:
        dict_data[k]

const
  WIN32_CLIENT_RELEASES = [
    ([10, 1, 0], "post11"),
    ([10, 0, 22000], "11"),
    ([6, 4, 0], "10"),
    ([6, 3, 0], "8.1"),
    ([6, 2, 0], "8"),
    ([6, 1, 0], "7"),
    ([6, 0, 0], "Vista"),
    ([5, 2, 3790], "XP64"),
    ([5, 2, 0], "XPMedia"),
    ([5, 1, 0], "XP"),
    ([5, 0, 0], "2000"),
  ]

  WIN32_SERVER_RELEASES = [
    ([10, 1, 0], "post2025Server"),
    ([10, 0, 26100], "2025Server"),
    ([10, 0, 20348], "2022Server"),
    ([10, 0, 17763], "2019Server"),
    ([6, 4, 0], "2016Server"),
    ([6, 3, 0], "2012ServerR2"),
    ([6, 2, 0], "2012Server"),
    ([6, 1, 0], "2008ServerR2"),
    ([6, 0, 0], "2008Server"),
    ([5, 2, 0], "2003Server"),
    ([5, 0, 0], "2000Server"),
  ]

proc win32_edition*: string =
  try:
      const cvkey = r"SOFTWARE\Microsoft\Windows NT\CurrentVersion"
      result = getUnicodeValue(cvkey, "EditionId", HKEY_LOCAL_MACHINE)
  except OSError:
      discard

proc win32_is_iot*: bool =
  win32_edition() in ["IoTUAP", "NanoServer", "WindowsCoreHeadless", "IoTEdgeOS"]

proc private_win32_ver(version, csd, ptype: string): tuple[version, csd, ptype: string, is_client: bool] =
  ## `_win32_ver`

  # Try using WMI first, as this is the canonical source of data
  var
    version, ptype: string
    csd = csd
  when HasWMI:
    var
      product_type, spmajor, spminor: string
      is_client: bool

    try:
      (version, product_type, ptype, spmajor, spminor) = private_wmi_query("OS", [
          "Version",
          "ProductType",
          "BuildType",
          "ServicePackMajorVersion",
          "ServicePackMinorVersion",
      ]).unpack(5)
      let is_client = parseInt(product_type) == 1
      let csd = (
        if spminor != "" and spminor != "0":
          fmt"SP{spmajor}.{spminor}"
        else:
          fmt"SP{spmajor}"
      )
      return (version, csd, ptype, is_client)
    except OSError:
        discard

  # Fall back to a combination of sys.getwindowsversion and "ver"
  when not HAS_SYS_GETWINDOWSVERSION:
    return (version, csd, ptype, true)
  else:
    let
      winver = getwindowsversion()
      is_client = when compiles(winver.product_type):
        winver.product_type == 1
      else: true

    let (major, minor) = try:
        version = private_syscmd_ver()[2]
        (major, minor, build) := map(version.split('.'), parseInt) 
        (major, minor)
    except ValueError:
        (major, minor, build) := (
          if winver.platform_version != default typeof winver.platform_version:
            winver.platform_version
          else:
            winver.unpack(3)
        )
        version = fmt"{major}.{minor}.{build}"
        (major, minor)

    # getwindowsversion() reflect the compatibility mode Python is
    # running under, and so the service pack value is only going to be
    # valid if the versions match.
    if winver.unpack(2) == (major, minor):
        when compiles(winver.service_pack_major):
            csd = "SP" & $winver.service_pack_major
        else:
          if csd[0..12] == "Service Pack ":
              csd = "SP" & csd[13..^1]

    try:
        const cvkey = r"SOFTWARE\Microsoft\Windows NT\CurrentVersion"
        ptype = getUnicodeValue(cvkey, "CurrentType", HKEY_LOCAL_MACHINE)
    except OSError:
        discard

    return (version, csd, ptype, is_client)

template E(s: string): bool = s == ""
proc private_get_machine_win32*: string =
  ## `_get_machine_win32`
  when HasWMI:
    try:
      (arch, *_) := wmi_query("CPU", "Architecture")
      try:
        const None = ""
        arch = ["x86", "MIPS", "Alpha", "PowerPC", None,
                "ARM", "ia64", None, None,
                "AMD64", None, None, "ARM64",
        ][parseInt(arch)]
        if arch != "":
          return arch
      except (ValueError, IndexError):
          discard
    except OSError:
      discard
  result = getEnvCompat("PROCESSOR_ARCHITEW6432")
  if E result:
    result = getEnvCompat("PROCESSOR_ARCHITECTURE")

{.push warning[ImplicitDefaultValue]: off.}
proc win32_ver*(release, version, csd, ptype = ""): tuple[release, version, csd, ptype: string] =
  {.pop.}

  var is_client: bool
  (result.version, result.csd, result.ptype, is_client) = private_win32_ver(version, csd, ptype)
  result.release = release

  if not E result.version:
    let
      intversion = result.version.split('.').map(parseInt)
      releases = (if is_client: WIN32_CLIENT_RELEASES else: WIN32_SERVER_RELEASES)
    for (v, r) in releases:
      if v <= intversion:
        result.release = r
        break
    # Python:
    #result.release = next((r for v, r in releases if v <= intversion), release))

when isMainModule:
  let (rel, ver, csd, ptype) = win32_ver()
  echo "release: ", repr rel
  echo "version: ", repr ver
  echo "csd: ", repr csd
  echo "ptype: ", repr ptype

  echo private_syscmd_ver()

