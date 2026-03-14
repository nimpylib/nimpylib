
##[ snprintf() and vsnprintf() wrappers.

   If the platform has vsnprintf, we use it, else we
   emulate it in a half-hearted way.  Even if the platform has it, we wrap
   it because platforms differ in what vsnprintf does in case the buffer
   is too small:  C99 behavior is to return the number of characters that
   would have been written had the buffer not been too small, and to set
   the last byte of the buffer to \0.  At least MS _vsnprintf returns a
   negative value instead, and fills the entire buffer with non-\0 data.
   Unlike C99, our wrappers do not support passing a null buffer.

   The wrappers ensure that str[size-1] is always \0 upon return.

   PyOS_snprintf and PyOS_vsnprintf never write more than size bytes
   (including the trailing '\0') into str.

   Return value (rv):

    When 0 <= rv < size, the output conversion was unexceptional, and
    rv characters were written to str (excluding a trailing \0 byte at
    str[rv]).

    When rv >= size, output conversion was truncated, and a buffer of
    size rv+1 would have been needed to avoid truncation.  str[size-1]
    is \0 in this case.

    When rv < 0, "something bad happened".  str[size-1] is \0 in this
    case too, but the rest of str is unreliable.  It could be that
    an error in format codes was detected by libc, or on platforms
    with a non-C99 vsnprintf simply that the buffer wasn't big enough
    to avoid truncation, or on platforms without any vsnprintf that
    PyMem_Malloc couldn't obtain space for a temp buffer.

   CAUTION:  Unlike C99, str != NULL and size > 0 are required.
   Also, size must be smaller than INT_MAX.
]##

import std/macros

proc snprintf(str: cstring, size: csize_t, format: cstring): cint{.importc, header: "<stdio.h>", cdecl, varargs.}

macro PyOS_snprintf*(str: cstring, size: csize_t, format: cstring, va: varargs[typed]): cint =
  let call = newCall(bindSym"snprintf", str, size, format)
  for i in va: call.add i

  result = newStmtList quote do:
    assert(`str`.isNil.not);
    assert(`size` > 0);
    assert(`size` <= (int.high - 1));
    assert(`format`.isNil.not);

    template goto_Done =
      if size > 0:
        `str`[`size`-1] = '\0'
      return
    if `size` > int.high - 1:
      result = -666
      goto_Done

    result = `call`
    goto_Done
