import pixie,data,ansicolors,osproc,streams,strutils,terminal,os

template exec*(command: string, input: untyped): string =
  var p = startProcess(command,workingDir = getCurrentDir(),options = {poStdErrToStdOut, poUsePath,poEvalCommand})
  var op = outputStream(p)

  let ip {.inject.} = inputStream(p)
  input
  ip.close()

  var res: string
  var line = newStringOfCap(120)
  while true:
    if op.readLine(line):
      res.add line
      res.add '\n'
    elif not running(p):
      break
  close(p)
  res

proc execStr*(command: string, input: string | seq[byte]): string =
  exec(command):
    ip.write(input)

let typeface = readTypeface(fontFile)

proc newFont(color: colortypes.Color): Font=
  result = newFont(typeface)
  result.size = fontSize
  result.paint.color = color

proc renderSpans(code: string): seq[Span]=
  let data = execStr(batCmd,code).parseAnsiColors()

  var color: colortypes.Color

  for i in data:
    if i.kind != Data:
      if i.kind == AnsiOpKind.Fg:
        let (r, g, b) = i.color.color2rgb(baseColors, brightColors)
        color = color(rgb(r, g, b))
      elif i.kind == AnsiOpKind.Reset or i.kind == AnsiOpKind.ResetFg:
        color = parseHtmlHex(foreground)
    else:
      result.add(newSpan(i.str, newFont(color)))

proc calcCodeSize(code: string): IVec2=
  typeset(renderSpans(code)).layoutBounds().ivec2() + ivec2(padding,padding) * 2

proc renderCode*(code: string, imageSize: IVec2): Image =
  result = newImage(imageSize.x, imageSize.y)
  result.fill(parseHtmlHex(background))
  result.fillText(typeset(renderSpans(code)), translate(vec2(padding, padding)))

proc img2rgba(x: Image): seq[byte] =
  result = newSeqOfCap[byte](x.width * x.height * 4)
  for i in x.data:
    let rgba = i.rgba()
    result.add([rgba.r, rgba.g, rgba.b, rgba.a])

proc progressBar(current,max: int)=
  var p = int(current * 100 / max)
  echo "[$1$2]" % [repeat('*',p),repeat(' ',100 - p)]
  cursorUp(1)

iterator renderCodeAll(code: string,size = calcCodeSize(code)): seq[byte] =
  for i in countup(0, code.high, textSkip):
    yield img2rgba renderCode(code[0 .. i], size)
    progressBar(i,code.high)
  echo "done"
  yield img2rgba renderCode(code, size)

func mkffmpegCmd(pixFmt: string,size: IVec2,output: string): string=
  return "ffmpeg -y -f rawvideo -vcodec rawvideo -pix_fmt $1 -s:v $2x$3 -r $4 -i - -an -c:v h264_nvenc -preset p7 -profile:v high -tune 4 $5" % [pixFmt,$size.x,$size.y,$frameRate,output]

template renderVideo(code: string, output: string = "bin/output.mp4") =
  let size = calcCodeSize(code)
  echo size
  let cmd = mkffmpegCmd("rgba",size,output)
  echo "Running: ", cmd
  echo exec(cmd,
    for i in renderCodeAll(code,size):
      ip.writeData(i[0].unsafeAddr,i.len())
  )

renderVideo(
  readFile(paramStr(1))
)