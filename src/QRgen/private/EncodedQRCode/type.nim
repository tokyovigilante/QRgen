import
  ".."/[bitArray, qrCode, qrCapacities, qrTypes]

type
  EncodedQRCode* = object
    ## An object holding the encode data of a `QRCode`, `data`, and the rest
    ## of it's information: `mode`, `version` and `ecLevel`.
    mode*: QRMode
    version*: QRVersion
    ecLevel*: QRECLevel
    data*: BitArray

proc newEncodedQRCode*(
  version: QRVersion,
  ecLevel: QRECLevel = qrECL,
  mode: QRMode = qrByteMode
): EncodedQRCode =
  ## Creates a new `EncodedQRCode` object with the specified `mode`, `version`
  ## and `ecLevel`.
  let dataSize: int = int(totalDataCodewords[ecLevel][version])
  let eccSize: int =
    (int(group1Blocks[ecLevel][version]) + int(group2Blocks[ecLevel][version])) *
      int(blockECCodewords[ecLevel][version])
  EncodedQRCode(mode: mode,
                version: version,
                ecLevel: ecLevel,
                data: newBitArray(uint16(dataSize + eccSize)))

proc newEncodedQRCode*(qr: QRCode): EncodedQRCode =
  ## Creates a new `EncodedQRCode` from an exisiting `QRCode` object.
  newEncodedQRCode(qr.version, qr.ecLevel, qr.mode)
