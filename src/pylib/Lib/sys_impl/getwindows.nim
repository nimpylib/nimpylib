## only export symbols for windows platform, e.g. `getwindowsversion`
when defined(windows):
  import ./getwindows_impl
  export getwindows_impl
