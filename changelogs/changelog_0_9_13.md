# v0.9.13 - 2025-08-08

## Bug Fixes

* py:

  * type:

    * TypeError if using float for x, X, o specifier. (53368bcbc)
    * flags are now considered. (f56ae5c30)
    * add range check and error message as Python's; `s % v` where v is SomeNumber now works on JS. (323e6fa6e)
    * `%s`, `%r`, `%a`, `%b` raised AssertDefect for non-string. (fb1597066)
    * translateEscape: allow error message as Python's. (37a6cddac)
    * translateEscape: support bytes mode; disallow Nim's special escape unless `-d:nimpylibTranslateEscapeAllowNimExt`. (c0a6f744c)

  * tuple:

    * `tuple.len` gave 0 for non-literal. (a7f4e0722)
    * one-char string in tuple was not accepted; renamed `getRune` to `getAsRune`. (635426327)

  * bytes:

    * `@`: "Error: cannot instantiate: 'newSeqUninitialized[T]'". (5c1743471)

  * builtins:

    * `$` and `repr` for list, set, dict, etc., just used `system`'s. (d658f78f8)

  * sugar:

    * `with .. as ..` did not compile. (d3ebb73c3)
    * `with <infix instead of as>` did not compile. (ba1a32d34)

  * str:

    * `str.format`: support non-static format string. (87075a9ec)
    * `str.format_map`: fixed compatibility. (f43a58dee)

  * TemporaryDirectory:

    * `with TemporaryDirectory(..) as n` gave `n` not as string. (a99eb0eee)

  * print:

    * did not compile when `-d:deno`. (80e5a0655)

* nimpatch:

  * `newUninit`: `system.setLenUninit` only declared on `defined(nimHasSetLengthSeqUninitMagic)`. (899052c28)

## Feature Additions

* EXT:

  * `@range`, list(@-able). (9651010a6)

* py:

  * `%c`: for string; for bytes, accept integer too. (f51abb9c0)
  * `%`: static format string evaluation at compile time; TypeError also at compile time. (7dcd1ce54)
  * `%`: `*` accepts variable. (b6679a2f1)
  * `str.format`: for bool, char, cstring, and `typeinfo.Any`. (7e2ca6865)

* js:

  * partly support due to lack of `system.getTypeInfo`. (0ff3439c9)
  * support %-format (printf-format). (afa0f3204)

* builtins:

  * `$` for `Any`. (07feb1c06)

## Improvements

* py:

  * `opt`: `Py_normalize_encoding` accepts `cstring` now. (2e06f94cc)
  * `opt`: refined `pushDigitChar` overflow check; raise `ValueError` over `OverflowDefect`. (f575d2a85)
  * `opt`: faster parse flags; bound checks turned off. (59f75d0a1)
  * `opt`: `%`: passing `tuple[T,...]` as array of `T` over `Any`. (52fe21ccb)

* str:

  * `format`: no longer `add char` for string snippets between interpolators. (4de10d499)

* percent_format:

  * merged common code; fixed overflow checks missed 's'. (da5cb5eb1)

## Breaking Changes

* py:

  * `Py_FormatEx`'s arguments accept `Getitem`-able over `openArray[(string, string)]`. (8bf740783)

## Refactor

* py:

  * replaced `parse,get` with `parseNumberAs,getAs`; `parseChar,getAsChar`. (d97ffd082)
  * renamed `getAsBiggestXxx,getSomeNumberAsBiggestXxx`. (b1997b734)

## Chores

* CI:

  * `testC`, `testJs`: allow `workflow_dispatch`. (a43a7d605)

* nimble:

  * task `testExamples`. (30db10368)
