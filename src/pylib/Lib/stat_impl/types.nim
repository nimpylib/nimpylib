
when defined(windows):
  type Mode = cushort
elif defined(js):
  from ../os_impl/posix_like/chmodsJs import Mode
else:
  from std/posix import Mode
export Mode
