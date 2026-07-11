import
  "."/[type, utils],
  ".."/[bitArray, qrCapacities, qrCharacters, qrTypes]

template getVal16(c: char): uint16 =
  ## Helper template to get the alphanumeric value of `c` as a uint16.
  uint16(getAlphanumericValue c)

template encodeNumericModeData(self: var EncodedQRCode, data: string) =
  ## Encodes `data` via the numeric mode encoding algorithm.
  for i in step(0, data.len, 3):
    # ISO/IEC 18004 §7.4.3: every full 3-digit group is encoded in a fixed
    # 10 bits, regardless of leading zeros. The reduced 7/4-bit widths apply
    # only to a trailing 2/1-digit remainder (handled below).
    self.data.add(
      getVal16(data[i]) * 100'u16 + getVal16(data[i+1]) * 10'u16 +
        getVal16(data[i+2]),
      10'u8
    )
  case (data.len mod 3)
  of 1: self.data.add getVal16(data[^1]), 4'u8
  of 2: self.data.add getVal16(data[^2]) * 10'u16 + getVal16(data[^1]), 7'u8
  else: discard

template encodeAlphanumericModeData(self: var EncodedQRCode, data: string) =
  ## Encodes `data` via the alphanumeric mode encoding algorithm.
  for i in step(0, data.len, 2):
    self.data.add getVal16(data[i]) * 45'u16 + getVal16(data[i+1]), 11'u8
  if (data.len mod 2) == 1:
    self.data.add getVal16(data[^1]), 6'u8

template encodeByteModeData(self: var EncodedQRCode, data: string) =
  ## Encodes `data` via the byte mode encoding algorithm.
  for c in data:
    self.data.add uint16(cast[uint8](c)), 8'u8

proc encodeDataCodewords*(self: var EncodedQRCode, data: string) =
  ## Depending on `self.mode`, the data will be encoded using numeric,
  ## alphanumeric or byte mode encoding algorithms.
  case self.mode
  of qrNumericMode:      encodeNumericModeData self, data
  of qrAlphanumericMode: encodeAlphanumericModeData self, data
  of qrByteMode:         encodeByteModeData self, data

proc finishDataEncoding*(self: var EncodedQRCode) =
  ## Adds the terminator bits and missing bits, and if there are more bytes
  ## unfilled, fills them with `0b11101100` and `0b00010001`.
  var missingBits: uint16 =
    (totalDataCodewords[self] * 8'u16) - self.data.pos
  let terminatorBits: uint8 =
    if missingBits > 4'u16: 4'u8
    else: cast[uint8](missingBits)
  self.data.add 0'u16, terminatorBits
  missingBits = missingBits - uint16(terminatorBits + self.data.nextByte)
  let missingBytes: uint16 = missingBits div 8'u16
  for _ in 1'u16 .. (missingBytes div 2'u16):
    self.data.add 0b11101100'u16, 8'u8
    self.data.add 0b00010001'u16, 8'u8
  if (missingBytes mod 2'u16) == 1'u16:
    self.data.add 0b11101100'u16, 8'u8
