## # Printing a DrawedQRCode
##
## Nimony port. The original module used `std/strformat`'s compile-time `fmt`
## interpolation (unavailable under nimony) and a large set of `{.dirty.}`
## templates to emit rounded/rect/embedded-image SVG variants. This port keeps
## the two surfaces that matter for embedding QRgen — a terminal dump and a
## plain-square-module SVG string — built with ordinary string concatenation.
## The rounded-module / rounded-alignment / separation / embedded-image options
## of the Nim-2 `printSvg` are intentionally not ported (they are cosmetic and
## were out of scope). The default (square) SVG is byte-for-byte what the Nim-2
## `printSvg` produced with default arguments.

import
  std/syncio,
  "."/[type],
  ".."/[drawing]

proc printTerminal*(self: DrawedQRCode) =
  ## Print a `DrawedQRCode` to the terminal using `stdout`.
  var res: string = "\n\n\n\n\n"
  for y in 0'u8 ..< self.drawing.size:
    res.add "          "
    for x in 0'u8 ..< self.drawing.size:
      if self.drawing[x, y]:
        res.add "██"
      else:
        res.add "  "
    res.add "\n"
  res.add "\n\n\n\n\n"
  stdout.write res

proc printSvg*(
  self: DrawedQRCode,
  light: string = "#ffffff",
  dark: string = "#000000",
  class: string = "qrCode",
  id: string = ""
): string =
  ## Print a `DrawedQRCode` in SVG format (returned as a `string`), using plain
  ## square modules. `light` is the background colour and `dark` the module
  ## colour.
  let sp10: int = int(self.drawing.size) + 10
  result =
    "<svg class=\"" & class & "\" id=\"" & id & "\" version=\"1.1\"" &
    " xmlns=\"http://www.w3.org/2000/svg\"" &
    " viewBox=\"-5 -5 " & $sp10 & " " & $sp10 & "\">" &
    "<path class=\"qrLight\" fill=\"" & light & "\"" &
    " d=\"M-5,-5h" & $sp10 & "v" & $sp10 & "h-" & $sp10 & "Z\"></path>" &
    "<path class=\"qrDark\" fill=\"" & dark & "\" d=\""
  for y in 0'u8 ..< self.drawing.size:
    for x in 0'u8 ..< self.drawing.size:
      if self.drawing[x, y]:
        result.add "M" & $int(x) & "," & $int(y) & "h1v1h-1Z"
  result.add "\"></path></svg>"
