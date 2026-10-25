## # QRCode implementation
##
## This module implements an object to hold the initial data of a `QRCode`,
## being the string wanted to be used to create a QRCode with. This string is
## also used to know which size the QR code will need to be to hold that data
## and in which mode it will be encoded.
##
## The main procedures consist of the functions mentioned earlier,
## `setMostEfficientMode` to set the best mode to encode the data and
## `setSmallestVersion` to set the smallest QR code size where the data can
## fit.

import
  "."/[
    qrCapacities,
    qrCharacters,
    qrTypes
  ]

type
  QRCode* = object
    ## An object holding the data string to encode, `data`, the mode in which
    ## it will be encoded, `mode`, the size the QR code will need to hold the
    ## data, `version`, and the error correction level used to generate the
    ## generate the error correction codewords, `ecLevel`.
    mode*: QRMode
    version*: QRVersion
    ecLevel*: QRECLevel
    data*: string

  DataSizeDefect* = ErrorCode
    ## Raised when `data` can't fit in any QR code version with the specified
    ## `mode` and `ecLevel`, or in the explicitly specified `version`.
    ##
    ## .. note:: Nimony port — an alias of `ErrorCode`: nimony raises
    ##    `ErrorCode` values or `ref` objects only (#2695), and an oversized
    ##    payload raises `ValueError`. Catch it with `except ErrorCode` (or a
    ##    bare `except`).

template getCapacities(mode: QRMode): QRCapacity[uint16] =
  ## A helper template to get `mode`'s capacities.
  case mode
  of qrNumericMode: numericModeCapacities
  of qrAlphanumericMode: alphanumericModeCapacities
  of qrByteMode: byteModeCapacities

proc getMostEfficientMode*(data: string): QRMode =
  result = qrNumericMode
  for c in data:
    if c notin alphaNumericValues:
      result = qrByteMode
      return
    elif result != qrAlphanumericMode and c notin numericValues:
      result = qrAlphanumericMode

proc getSmallestVersion*(
  data: string,
  mode: QRMode,
  ecLevel: QRECLevel
): QRVersion {.raises: DataSizeDefect.} =
  result = 1'u8
  for version in getCapacities(mode)[ecLevel]:
    if cast[uint16](data.len) <= version:
      return result
    result = result + 1'u8
  # Nimony raises `ErrorCode` values or `ref` objects only (nimony #2695):
  # an oversized payload is the `ValueError` code.
  raise ValueError

proc newQRCode*(
  data: string,
  ecLevel: QRECLevel,
  mode: QRMode,
  version: QRVersion
): QRCode {.raises: DataSizeDefect.} =
  ## Creates a new `QRCode` object with the specified `data`, `ecLevel`, `mode`
  ## and `version`.
  ##
  ## .. note:: Only the size will be checked.
  result = QRCode(mode: mode, version: version, ecLevel: ecLevel, data: data)
  if cast[uint16](result.data.len) >
      getCapacities(result.mode)[result.ecLevel][result.version]:
    raise ValueError

proc newQRCode*(data: string, ecLevel: QRECLevel = qrECL): QRCode
    {.raises: DataSizeDefect.} =
  ## Creates a new `QRCode` from `data`, choosing the most efficient mode and
  ## the smallest version that fits automatically.
  ##
  ## .. note:: Nimony port — mode/version are computed in-body rather than as
  ##    parameter defaults (see the note on `newQR`).
  let mode = data.getMostEfficientMode
  let version = data.getSmallestVersion(mode, ecLevel)
  newQRCode(data, ecLevel, mode, version)
