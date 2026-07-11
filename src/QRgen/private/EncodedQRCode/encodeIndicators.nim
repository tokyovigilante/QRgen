import
  "."/[type],
  ".."/[bitArray, qrTypes]

proc encodeModeIndicator*(self: var EncodedQRCode) =
  ## Encodes the mode indicator according to the specified `mode`.
  self.data.add uint16(cast[uint8](self.mode)), 4'u8

proc encodeCharCountIndicator*(self: var EncodedQRCode, data: string) =
  ## Encodes the character count indicator, which is the length of `data`.
  ## Depending on the mode and version, the indicator will be more or less
  ## bits long.
  template modeCases(numericVal, alphanumericVal, byteVal: uint8): uint8 =
    case self.mode
    of qrNumericMode: numericVal
    of qrAlphanumericMode: alphanumericVal
    of qrByteMode: byteVal
  self.data.add(cast[uint16](data.len), (
    if self.version <= 9'u8:    modeCases 10'u8, 9'u8, 8'u8
    elif self.version >= 27'u8: modeCases 14'u8, 13'u8, 16'u8
    else:                       modeCases 12'u8, 11'u8, 16'u8
  ))
