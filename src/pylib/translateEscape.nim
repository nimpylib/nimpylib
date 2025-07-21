
import std/macros
import std/unicode
import std/strformat

const allowNimEscape*{.booldefine: "nimpylibTranslateEscapeAllowNimExt"
.} = false ## - if false(default), use extract Python's format;  \
## - if true, allow Nim's escape format like `\u{...}`, `\p`, `\N`

when allowNimEscape:
  template `?+`(bothC, onlyNimC): untyped = {bothC, onlyNimC}
  template `?+*`(bothC; onlyNimChars): untyped = {bothC} + onlyNimChars
else:
  template `?+`(bothC, _): untyped = bothC
  template `?+*`(bothC; _): untyped = bothC

# compiler/lineinfos.nim
type
  TranslateEscapeErr* = enum
    teeExtBad_uCurly = (-1, "bad hex digit in \\u{...}")  ## Nim's EXT
    teeBadEscape = "invalid escape sequence"
    teeBadOct = "invalid octal escape sequence"  ## SyntaxWarning in Python
    teeUniOverflow = "illegal Unicode character"
    teeTrunc_x2 = "truncated \\xXX escape"
    teeTrunc_u4 = "truncated \\uXXXX escape"
    teeTrunc_U8 = "truncated \\UXXXXXXXX escape"

type
  Token = object     # a Nim token
    literal: string  # the parsed (string) literal

type
  LexMessage* = proc(info: LineInfo, kind: TranslateEscapeErr, nimStyleErrMsg: string)
  Lexer*[U: static[bool], M] = object
    ## `U` means whether supporting escape about unicode;
    ## `M` is a `proc(LineInfo, TranslateEscapeErr, string)`,
    ##  leaving as a generic to allow custom pragma like `{.raises: [].}`
    bufLen: int
    bufpos: int
    buf: string

    lineInfo*: LineInfo
    lexMessageImpl: M  # static method no supported by Nim


proc newLexerNoMessager[U: static[bool], M](s: string): Lexer[U, M] =
  result.buf = s
  result.bufLen = s.len


proc newLexerImpl[U: static[bool], M](s: string, messager: M): Lexer[U, M] =
  result = newLexerNoMessager[U, M](s)
  result.lexMessageImpl = messager

template newLexer*[U: static[bool]](s: string, messager): Lexer =
  ## create a new lexer with a messager
  bind newLexerImpl
  newLexerImpl[U, typeof(messager)](s, messager)

template allow_unicode[U: static[bool], M](L: Lexer[U, M]): bool = U


proc staticLexMessageImpl(info: LineInfo, kind: TranslateEscapeErr, nimStyleErrMsg: string){.compileTime.} =
  let errMsg = '\n' & fmt"""
File "{info.filename}", line {info.line}, col {info.column}
  {nimStyleErrMsg}"""  # Updated to use nimStyleErrMsg
  case kind
  of teeBadEscape:
    warning errMsg
  else:
    error errMsg
  #else: debugEcho errMsg

proc newStaticLexer*[U: static[bool]](s: string): Lexer[U, LexMessage]{.compileTime.} =
  ## use Nim-Like error message
  result = newLexerNoMessager[U, LexMessage](s)
  result.lexMessageImpl = staticLexMessageImpl

proc lexMessage[U: static[bool], M](L: Lexer[U, M], kind: TranslateEscapeErr, nimStyleErrMsg: string) =
  var info = L.lineInfo
  # XXX: when is multiline string, we cannot know where the position is,
  #  as Nim has been translated multiline as single-line.
  info.column += L.bufpos + 1  # plus 1 to become 1-based
  L.lexMessageImpl(info, kind, nimStyleErrMsg)

func handleOctChars(L: var Lexer, xi: var int) =
  ## parse at most 3 chars
  for _ in 0..2:
    let c = L.buf[L.bufpos]
    if c notin {'0'..'7'}: break
    xi = (xi * 8) + (ord(c) - ord('0'))
    inc(L.bufpos)
    if L.bufpos == L.bufLen: break

proc handleHexChar(L: var Lexer, xi: var int; position: int, eKind: TranslateEscapeErr) =
  ## parseHex in std/parseutils allows `_` and prefix `0x`, which shall not be allowed here
  template invalid(c) =
    lexMessage(L, eKind,
      "expected a hex digit, but found: " & c &
        "; maybe prepend with 0")
  if L.bufpos == L.bufLen: invalid("END")
  let c = L.buf[L.bufpos]
  case c
  of '0'..'9':
    xi = (xi shl 4) or (ord(c) - ord('0'))
    inc(L.bufpos)
  of 'a'..'f':
    xi = (xi shl 4) or (ord(c) - ord('a') + 10)
    inc(L.bufpos)
  of 'A'..'F':
    xi = (xi shl 4) or (ord(c) - ord('A') + 10)
    inc(L.bufpos)
  of '"', '\'':
    if position <= 1: invalid(c)
    # do not progress the bufpos here.
    elif position == 0: inc(L.bufpos)
  else:
    invalid(c)

const
  CR = '\r'
  LF = '\n'
  FF = '\f'
  BACKSPACE = '\b'
  ESC = '\e'

template uncheckedAddUnicodeCodePoint(s: var string, i: int) =
  ## add a Unicode codepoint to the string, assuming `i` is a valid codepoint
  s.add cast[Rune](i)


proc getEscapedChar(L: var Lexer, tok: var Token) =
  inc(L.bufpos)               # skip '\'
  when L.allow_unicode:
    template uniOverErr(curVal: string) =
      lexMessage(L, teeUniOverflow,
        "Unicode codepoint must be lower than 0x10FFFF, but was: " & curVal)
    
  template invalidEscape() =
    lexMessage(L, teeBadEscape, "invalid character constant")

  template doIf(cond, body) =
    when cond: body
    else: invalidEscape()

  template addTokLitOnAllowNim(cOrS) =
    doIf allowNimEscape:
      tok.literal.add(cOrS)
      inc(L.bufpos)
  let c = L.buf[L.bufpos]
  case c
  of 'n' ?+ 'N':
    tok.literal.add('\L')
    inc(L.bufpos)
  of 'p', 'P':
    addTokLitOnAllowNim("\p")
  of 'r' ?+* {'R', 'c', 'C'}:
    tok.literal.add(CR)
    inc(L.bufpos)
  of 'l' ?+ 'L':
    tok.literal.add(LF)
    inc(L.bufpos)
  of 'f' ?+ 'F':
    tok.literal.add(FF)
    inc(L.bufpos)
  of 'e', 'E':
    addTokLitOnAllowNim(ESC)
  of 'a' ?+ 'A':
    tok.literal.add('\a')
    inc(L.bufpos)
  of 'b' ?+ 'B':
    tok.literal.add(BACKSPACE)
    inc(L.bufpos)
  of 'v' ?+ 'V':
    tok.literal.add('\v')
    inc(L.bufpos)
  of 't' ?+ 'T':
    tok.literal.add('\t')
    inc(L.bufpos)
  of '\'', '\"':
    tok.literal.add(c)
    inc(L.bufpos)
  of '\\':
    tok.literal.add('\\')
    inc(L.bufpos)
  of 'x' ?+ 'X':
    inc(L.bufpos)
    var xi = 0
    handleHexChar(L, xi, 1, teeTrunc_x2)
    handleHexChar(L, xi, 2, teeTrunc_x2)
    tok.literal.add(chr(xi))
  of 'U':
   doIf L.allow_unicode:
    # \Uhhhhhhhh
    inc(L.bufpos)
    var xi = 0
    let start = L.bufpos
    for i in 0..7:
      handleHexChar(L, xi, i, teeTrunc_U8)
    if xi > 0x10FFFF:
      uniOverErr L.buf[start..L.bufpos-2]
    uncheckedAddUnicodeCodePoint(tok.literal, xi)
  of 'u':
   doIf L.allow_unicode:
    inc(L.bufpos)
    var xi = 0
    template handle4Hex =
      for i in 1..4:
        handleHexChar(L, xi, i, teeTrunc_u4)
    when allowNimEscape:
      if L.buf[L.bufpos] == '{':
        inc(L.bufpos)
        let start = L.bufpos
        while L.buf[L.bufpos] != '}':
          handleHexChar(L, xi, 0, teeExtBad_uCurly)
        if start == L.bufpos:
          lexMessage(L, teeExtBad_uCurly,
            "Unicode codepoint cannot be empty")
        inc(L.bufpos)
        if xi > 0x10FFFF:
          uniOverErr L.buf[start..L.bufpos-2]
      else: handle4Hex
    else: handle4Hex
    uncheckedAddUnicodeCodePoint(tok.literal, xi)
  of '0'..'7':
    var xi = 0
    handleOctChars(L, xi)
    tok.literal.add(chr(xi))
  else:
    invalidEscape()
    tok.literal.add('\\')
    inc(L.bufpos)
    tok.literal.add(c)
    inc(L.bufpos)

proc getString(L: var Lexer, tok: var Token) =
  var pos = L.bufpos

  while pos < L.bufLen:
    let c = L.buf[pos]
    if c == '\\':
      L.bufpos = pos
      getEscapedChar(L, tok)
      pos = L.bufpos
    else:
      tok.literal.add(c)
      pos.inc
  L.bufpos = pos

proc getString(L: var Lexer): Token =
  L.getString result

proc translateEscape*(L: var Lexer): string =
  L.getString().literal

proc translateEscape*(pattern: static[string],
  allow_unicode: static[bool] = true,
): string{.compileTime.} =
  ## like `translateEscapeWithErr` but without lineInfo error msg
  var L = newStaticLexer[allow_unicode](pattern)
  L.translateEscape

macro getLineInfoObj(n): LineInfo =
  ## get the line info from a node
  let linfo = n.lineInfoObj
  result = nnkObjConstr.newTree(bindSym"LineInfo",
    nnkExprColonExpr.newTree(ident"filename", newLit linfo.filename),
    nnkExprColonExpr.newTree(ident"line", newLit linfo.line),
    nnkExprColonExpr.newTree(ident"column", newLit linfo.column)
  )

template translateEscapeWithErr*(pattern: static[string],
  allow_unicode: static[bool] = true,
): string =
  bind newStaticLexer, getLineInfoObj, translateEscape
  const res = block:
    var L = newStaticLexer[allow_unicode](pattern)
    L.lineInfo = pattern.getLineInfoObj
    L.translateEscape 
  res
