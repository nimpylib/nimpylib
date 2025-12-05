
import std/[options, nativesockets,]
import ../sys
import ../os as pyos
import ./dos
when defined(windows):
  import ./windows

type
  UnameResult = tuple[
    system: string,
    node: string,
    release: string,
    version: string,
    machine: string,
    processor: string
  ]

var unameCache: Option[UnameResult] = none(UnameResult)

proc unknownAsBlank(val: string): string =
  if val == "unknown": ""
  else: val

when not declared(pyos.uname):
  proc private_node(default=""): string =
    ## Helper to determine the node name of this machine.
    try:
        return gethostname()
    except OSError:
        # Still not working...
        return default


template E(s: string): bool = s == ""

proc uname*(): UnameResult =
  ## Fairly portable uname interface. Returns a tuple
  ## of strings (system, node, release, version, machine, processor)
  ## identifying the underlying platform.
  ##
  ## Note that unlike the os.uname function this also returns
  ## possible processor information as an additional tuple entry.
  ##
  ## Entries which cannot be determined are set to ''.

  if unameCache.isSome:
    return unameCache.get()

  var
    system, node, release, version, machine, processor: string
    infos: pyos.uname_result

  when declared(pyos.uname):
    # Nim's os.uname returns (sysname, nodename, release, version, machine)
    infos = pyos.uname()
    system = infos.sysname
    node = infos.nodename
    release = infos.release
    version = infos.version
    machine = infos.machine
  else:
    system = sys.platform
    node = private_node()
  
  if infos == default pyos.uname_result:
   
    # uname is not available
    # Try win32_ver() on Windows platforms
    #if system == "win32":
    when defined(windows):
      let tmp = win32_ver()
      release = tmp[0]
      version = tmp[1]
      if E machine:
        machine = private_get_machine_win32()

    # Try the 'ver' system command available on some platforms
    if E(release) or E version:
      (system, release, version) = private_syscmd_ver(system)

      # Normalize system to what win32_ver() normally returns
      # (_syscmd_ver() tends to return the vendor name as well)
      if system == "Microsoft Windows":
          system = "Windows"
      elif system == "Microsoft" and release == "Windows":
          # Under Windows Vista and Windows Server 2008,
          # Microsoft changed the output of the ver command. The
          # release is no longer printed.  This causes the
          # system and release to be misidentified.
          system = "Windows"
          if "6.0" == version[0..2]:
              release = "Vista"
          else:
              release = ""
      # In case we still don't know anything useful, we'll try to
      # help ourselves
      if system in ["win32", "win16"]:
          if not version:
              if system == "win32":
                  version = "32bit"
              else:
                  version = "16bit"
          system = "Windows"

  # System specific extensions
  if system == "OpenVMS":
    # OpenVMS seems to have release and version mixed up
    if release == "" or release == "0":
      release = version
      version = ""

  # Normalize name
  if system == "Microsoft" and release == "Windows":
    system = "Windows"
    release = "Vista"

  # On Android, return the name and version of the OS rather than the kernel.
  #when defined(android):
  if sys.platform == "android":
    system = "Android"
    release = "" # Placeholder for android_ver().release

  # Normalize responses on iOS
  if sys.platform == "ios":
    system = "iOS"
    release = "" # Placeholder for ios_ver()

  let vals = (system, node, release, version, machine, processor)
  result = UnameResult (
    unknownAsBlank(vals[0]),
    unknownAsBlank(vals[1]),
    unknownAsBlank(vals[2]),
    unknownAsBlank(vals[3]),
    unknownAsBlank(vals[4]),
    unknownAsBlank(vals[5])
  )
  unameCache = some(result)
