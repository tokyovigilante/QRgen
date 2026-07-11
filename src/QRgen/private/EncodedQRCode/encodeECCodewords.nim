import
  "."/[type, utils],
  ".."/[bitArray, qrCapacities]

proc gf256Mod285Multiply(x, y: uint8): uint8 =
  ## Returns the multiplication of `x` and `y` using Galois Field 256 and
  ## the primitive polynomial 0x11D.
  ##
  ## .. note:: Nimony port — the original truncated the reduction constant
  ##    `0x11D` to a `uint8` (285 mod 256 = 0x1D), which is exactly the low
  ##    byte reduction of a GF(256) shift. We write `0x1D'u8` directly so the
  ##    arithmetic type is unambiguous; the result is bit-identical.
  result = 0'u8
  for i in 0'u8 .. 7'u8:
    result = (result shl 1'u8) xor ((result shr 7'u8) * 0x1D'u8)
    result = result xor (((y shr (7'u8 - i)) and 0x01'u8) * x)

proc calcGeneratorPolynomial(self: EncodedQRCode): seq[uint8] =
  ## Calculates the generator polynomial used to generate the ECC.
  let degree: uint8 = blockECCodewords[self]
  result = newSeqOfCap[uint8](int(degree))
  result.setLen(int(degree))
  result[degree - 1'u8] = 1'u8
  var root: uint8 = 1
  template mult(pos: untyped) =
    result[pos] = gf256Mod285Multiply(result[pos], root)
  for _ in 0'u8 ..< degree:
    for i in 0'u8 ..< degree - 1'u8:
      mult(i)
      result[i] = result[i] xor result[i+1]
    mult(degree - 1'u8)
    root = gf256Mod285Multiply(root, 0x02'u8)

proc calcBlockPositions(self: EncodedQRCode): seq[uint16] =
  ## Returns the positions of all data blocks and the last item is where
  ## the ECC blocks start.
  let blocks: int = int(group1Blocks[self]) + int(group2Blocks[self])
  result = newSeqOfCap[uint16](blocks + 1)
  result.setLen(blocks + 1)
  result[0] = 0'u16
  for i in 1'u8 .. group1Blocks[self] + group2Blocks[self]:
    result[i] = result[i-1] + (
      if i <= group1Blocks[self]: uint16(group1BlockDataCodewords[self])
      else: uint16(group2BlockDataCodewords[self])
    )

proc encodeECCodewords*(self: var EncodedQRCode) =
  ## Encodes the ECC codewords by calculating them using the generator
  ## polynomial and the data codewords.
  let
    positions: seq[uint16] = self.calcBlockPositions
    generator: seq[uint8] = self.calcGeneratorPolynomial
    degree: uint8 = cast[uint8](generator.len)
  for i in 0'u8 ..< cast[uint8](positions.len) - 1'u8:
    for j in positions[i] ..< positions[i+1]:
      let actualEcPos: uint16 = uint16(
        int(positions[positions.len - 1]) +
        int(blockECCodewords[self]) * int(i))
      let factor = self.data[j] xor self.data[actualEcPos]
      # Left-shift the ECC region by one, appending a zero. (The original had
      # a moveMem fast path guarded by `when not defined(js)`; nimony has no
      # moveMem/addr, and the delete+append below is exactly equivalent.)
      self.data.unsafeDelete actualEcPos
      self.data.unsafeAdd 0'u8
      for k in 0'u8 ..< degree:
        self.data[actualEcPos+k] =
          self.data[actualEcPos+k] xor gf256Mod285Multiply(generator[k], factor)
