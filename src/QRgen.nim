## # The main QRgen API
##
## The main QRgen API provides a single procedure to create qr codes, `newQR`
## and another procedure to print them to an output format, `print`.
##
## It does also provide the required Types and Defects you may need to
## store the result of both procedures or to pass them arguments.
## You can find those in the `export section<#19>`_.
##
## Check
## `the print module<QRgen/private/DrawedQRCode/print.html#12>`_
## to learn about all print options.
##
## Check
## `the renderer module<QRgen/renderer.html#12>`_
## to learn about rendering QR codes into pixie's `Image` objectsn which can
## be rendered to PNG and other formats.
##
## # Usage example
##
## Here is a basic example to generate a QR code of an URL and show it
## in your terminal:

runnableExamples:
  let urlQR = newQR("https://my-url.domain")
  urlQR.printTerminal

import
  QRgen/private/[
    DrawedQRCode/drawedQRCode,
    DrawedQRCode/print,
    EncodedQRCode/encodedQRCode,
    qrCode,
    qrTypes
  ]

export
  drawedQRCode.DrawedQRCode,
  print,
  qrCode.DataSizeDefect,
  qrTypes

proc newQR*(
  data: string,
  ecLevel: QRECLevel,
  mode: QRMode,
  version: QRVersion
): DrawedQRCode {.raises: DataSizeDefect.} =
  ## Creates a new `DrawedQRCode` with an explicit `mode` and `version`.
  newQRCode(data, ecLevel, mode, version).encode.draw

proc newQR*(data: string, ecLevel: QRECLevel = qrECL): DrawedQRCode
    {.raises: DataSizeDefect.} =
  ## Creates a new `DrawedQRCode` from `data`, choosing the most efficient
  ## mode and the smallest version that fits automatically.
  ##
  ## .. note:: Nimony port — the mode/version defaults are computed in-body
  ##    rather than as default parameter values. Nimony's compiler currently
  ##    crashes on a default parameter that references another parameter
  ##    (`version = data.getSmallestVersion(mode, ecLevel)`).
  let mode = data.getMostEfficientMode
  let version = data.getSmallestVersion(mode, ecLevel)
  newQRCode(data, ecLevel, mode, version).encode.draw
