import ansiparse,strutils,sequtils
from terminal import Style

type
  ColorKind* = enum
    Default,TrueColor
  Color* = object
    case kind* : ColorKind
    of Default:
      index* : uint8
    of TrueColor:
      r*,g*,b* : uint8
  AnsiOpKind* {.pure.} = enum
    Reset,ResetStyle,ResetFg,ResetBg,Style,Fg,Bg,Data
  AnsiOpMaybe* = object
    case kind* : AnsiOpKind
    of Reset,ResetStyle,ResetFg,ResetBg:
      discard
    of AnsiOpKind.Style:
      style* : Style
    of Fg,Bg:
      color* : Color
    of Data:
      str* : string

func mk256Color(x: SomeInteger): Color = Color(kind: Default,index: cast[uint8](x))
func mkRGBColor(r,g,b: SomeInteger): Color = Color(kind: TrueColor,r: cast[uint8](r),g: cast[uint8](g),b: cast[uint8](b))
func mkOpReset(kind: AnsiOpKind): auto = AnsiOpMaybe(kind: kind)
func mkOpStyle(style: Style): auto = AnsiOpMaybe(kind: AnsiOpKind.Style,style: style)
func mkOpFg(color: Color): auto = AnsiOpMaybe(kind: Fg,color: color)
func mkOpBg(color: Color): auto = AnsiOpMaybe(kind: Bg,color: color)
func mkOpStr(str: string): auto = AnsiOpMaybe(kind: Data,str: str)

proc handleParameters(x: seq[int]): AnsiOpMaybe=
  case x[0]
  of 0:
    return mkOpReset(Reset)
  of 1 .. 9:
    return mkOpStyle(x[0].Style)
  of 10:
    return mkOpReset(ResetStyle)
  of 30 .. 37:
    return mkOpFg(mk256Color(x[0] - 30))
  of 38:
    case x[1]
    of 2:
      assert x.len() >= 5
      return mkOpFg(mkRGBColor(x[2],x[3],x[4]))
    of 5:
      return mkOpFg(mk256Color(x[2]))
    else:
      discard
  of 39:
    return mkOpReset(ResetFg)
  of 40 .. 47:
    return mkOpBg(mk256Color(x[0] - 40))
  of 48:
    case x[1]
    of 2:
      assert x.len() >= 5
      return mkOpBg(mkRGBColor(x[2],x[3],x[4]))
    of 5:
      return mkOpBg(mk256Color(x[2]))
    else:
      discard
  of 49:
    return mkOpReset(ResetBg)
  else:
    assert false

proc parseAnsiColors* (x: string): seq[AnsiOpMaybe]=
  for i in x.parseAnsi():
    case i.kind
    of CSI:
      try:
        var pz = i.parameters.split(';').map(parseInt)
        result.add handleParameters(pz)
      except:
        discard
    of String:
      result.add mkOpStr(i.str)

proc parseColor(x: string): (uint8,uint8,uint8)=
  let k = x.parseHexInt()
  result[0] = cast[uint8](k shr 16)
  result[1] = cast[uint8](k shr 8)
  result[2] = cast[uint8](k)

const twoSixteenLUT = block:
  var colors: array[216,(uint8,uint8,uint8)]
  for r in 0'u8 .. 5'u8:
    for g in 0'u8 .. 5'u8:
      for b in 0'u8 .. 5'u8:
        let index = 36 * r + 6 * g + b
        template f(x): auto= uint8(x.float * (256 / 6))
        colors[index] = (f(r),f(g),f(b))
  colors

proc color2rgb* (x: Color,base,bright: seq[string]): (uint8,uint8,uint8)=
  case x.kind
  of TrueColor:
    return (x.r,x.g,x.b)
  of Default:
    case x.index
    of 0 .. 7:
      return parseColor(base[x.index])
    of 8 .. 15:
      return parseColor(bright[x.index - 8])
    of 16 .. 231:
      return twoSixteenLUT[x.index - 16]
    of 232 .. 255:
      let k = cast[uint8]((x.index - 232).uint * 255 div 24)
      return (k,k,k)
