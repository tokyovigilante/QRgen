import
  "."/[type, utils],
  ".."/[bitArray, qrCapacities]

proc calcEcBlockPositions(self: EncodedQRCode): seq[uint16] =
  ## Returns a `seq` with all the first positions of ECC blocks in `self`.
  let blocks: int = int(group1Blocks[self]) + int(group2Blocks[self])
  result = newSeqOfCap[uint16](blocks)
  result.setLen(blocks)
  for i in 0'u8 ..< group1Blocks[self] + group2Blocks[self]:
    result[i] = uint16(int(blockECCodewords[self]) * int(i))

proc interleaveECCodewords*(self: var EncodedQRCode) =
  ## Interleaves the ECC codewords of `self`.
  ##
  ## The order is: 1st ECC from B1, then 1st from B2, 2nd from B1, 2nd from
  ## B2, etc.
  let
    firstEcBlockPos: uint16 = self.calcEcStart
    positions: seq[uint16] = self.calcEcBlockPositions
  var
    dataCopy: seq[uint8] = self.data[int(firstEcBlockPos) .. ^1]
    n: uint16 = firstEcBlockPos
  for i in 0'u8 ..< blockECCodewords[self]:
    for j in positions:
      self.data[n] = dataCopy[j + i]
      n = n + 1'u16
