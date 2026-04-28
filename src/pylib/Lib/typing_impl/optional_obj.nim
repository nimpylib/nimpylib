import pkg/pytyping/optional_obj as pkg_optional_obj
export pkg_optional_obj
template expOptObjCvt* =
  export optional_obj except newOptionalObj, isSome, isNone, OptionalObj
