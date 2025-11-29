
import std/macros
func getTypeof*(e: NimNode): NimNode =
  newCall("typeof", e)
