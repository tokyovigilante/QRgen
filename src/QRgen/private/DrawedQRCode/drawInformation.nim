import
  "."/[type],
  ".."/[drawing, qrTypes]

# nimony port — the original `calcLen` was generic over `uint16 | uint32` with
# a `when T is …` compile-time mask. Two concrete overloads are simpler here and
# avoid nimony's generic/`when T is` friction. Both return the bit length of the
# value (position of the highest set bit), e.g. `0000000001101010` -> 7.
func calcLen(bits: uint16): uint8 =
  result = 16'u8
  while result > 0'u8:
    let mask: uint16 = 0x8000'u16 shr (16'u8 - result)
    if (bits and mask) == mask:
      return result
    result = result - 1'u8

func calcLen(bits: uint32): uint8 =
  result = 32'u8
  while result > 0'u8:
    let mask: uint32 = 0x80000000'u32 shr (32'u8 - result)
    if (bits and mask) == mask:
      return result
    result = result - 1'u8

proc drawFormatInformation*(self: var DrawedQRCode) =
  ## Draws the format information of the drawing.
  let eclBits: uint16 =
    case self.ecLevel
    of qrECL: 0b01'u16
    of qrECM: 0b00'u16
    of qrECQ: 0b11'u16
    of qrECH: 0b10'u16
  var bits: uint16 = uint16((int(eclBits) shl 3) + int(self.mask))
  const gPolynomial: uint16 = 0b101_0011_0111'u16
  let polynomialLen: uint8 = gPolynomial.calcLen
  var
    ecBits: uint16 = bits shl 10
    ecBitsLen: uint8 = ecBits.calcLen
  while ecBitsLen > 10'u8:
    let polynomial: uint16 = gPolynomial shl (ecBitsLen - polynomialLen)
    ecBits = ecBits xor polynomial
    ecBitsLen = ecBits.calcLen
  bits = (bits shl 11) or (ecBits shl 1)
  bits = bits xor 0b10_101_00000100100'u16
  template check(i: uint8): bool = ((bits shr (15'u8 - i)) and 0x01'u16) == 0x01'u16
  for i in 0'u8..5'u8:
    if check i:
      self.drawing.fillPoint i, 8'u8
      self.drawing.fillPoint 8'u8, self.drawing.size-1'u8-i
  if check 6'u8:
    self.drawing.fillPoint 7'u8, 8'u8
    self.drawing.fillPoint 8'u8, self.drawing.size-7'u8
  if check 7'u8:
    self.drawing.fillPoint 8'u8, 8'u8
    self.drawing.fillPoint self.drawing.size-8'u8, 8'u8
  if check 8'u8:
    self.drawing.fillPoint 8'u8, 7'u8
    self.drawing.fillPoint self.drawing.size-7'u8, 8'u8
  for i in 9'u8..14'u8:
    if check i:
      self.drawing.fillPoint 8'u8, 14'u8-i
      self.drawing.fillPoint self.drawing.size-15'u8+i, 8'u8

proc drawVersionInformation*(self: var DrawedQRCode) =
  ## Draws the version information of drawings with a `version` equal to or
  ## greater than 7.
  if self.version < 7'u8:
    return
  var bits: uint32 = uint32(self.version)
  const gPolynomial: uint32 = 0b1_1111_0010_0101'u32
  let polynomialLen: uint8 = gPolynomial.calcLen
  var
    ecBits: uint32 = bits shl 12
    ecBitsLen: uint8 = ecBits.calcLen
  while ecBitsLen > 12'u8:
    let polynomial: uint32 = gPolynomial shl (ecBitsLen - polynomialLen)
    ecBits = ecBits xor polynomial
    ecBitsLen = ecBits.calcLen
  bits = (bits shl 26) or (ecBits shl 14)
  template check(i: uint8): bool = ((bits shr (31'u8 - i)) and 0x01'u32) == 0x01'u32
  for i in 0'u8..17'u8:
    if check i:
      self.drawing.fillPoint 5'u8 - i div 3'u8, self.drawing.size-9'u8-(i mod 3'u8)
      self.drawing.fillPoint self.drawing.size-9'u8-(i mod 3'u8), 5'u8 - i div 3'u8
