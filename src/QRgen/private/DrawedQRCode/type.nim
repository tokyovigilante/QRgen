import
  ".."/[drawing, EncodedQRCode/encodedQRCode, qrTypes]

type
  Mask* = uint8
    ## The applied mask pattern, 0..7. (Nimony port — a plain `uint8` rather
    ## than `range[0'u8..7'u8]`; the range prover fights the mask arithmetic.)

  DrawedQRCode* = object
    ## An object holding the drawing of a `EncodedQRCode`, `drawing`, the
    ## rest of it's information: `version` and `ecLevel`, and the mask which
    ## was used to draw it `mask`.
    version*: QRVersion
    ecLevel*: QRECLevel
    mask*: Mask
    drawing*: Drawing

func sizeForVersion(version: QRVersion): uint8 =
  uint8((int(version) - 1) * 4 + 21)

func newDrawedQRCode*(
  version: QRVersion,
  ecLevel: QRECLevel = qrECL
): DrawedQRCode =
  ## Creates a new `DrawedQRCode` object with the specified `version` and
  ## `ecLevel`.
  DrawedQRCode(version: version,
               ecLevel: ecLevel,
               drawing: newDrawing(sizeForVersion(version)))

func newDrawedQRCode*(qr: EncodedQRCode): DrawedQRCode =
  ## Creates a new `DrawedQRCode` from an exisiting `EncodedQRCode` object.
  DrawedQRCode(version: qr.version,
               ecLevel: qr.ecLevel,
               drawing: newDrawing(sizeForVersion(qr.version)))
