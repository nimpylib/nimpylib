
import std/typeinfo
export typeinfo

type
  HookProc* = proc (event: string; args: varargs[Any]){.raises: [].}
  HookEntry* = tuple[
    hookCFunction: HookProc,
    userData: Any,
  ]

