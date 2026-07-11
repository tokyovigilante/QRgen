import
  "."/[type, utils],
  ".."/[bitArray, qrCapacities]

iterator g1BlockPositions(self: EncodedQRCode): uint16 =
  ## Iterates over every starting position of the blocks in group 1.
  var pos: uint16 = 0
  var b: uint8 = 0
  while b < group1Blocks[self]:
    yield pos
    pos = pos + uint16(group1BlockDataCodewords[self])
    b = b + 1'u8

iterator g2BlockPositions(self: EncodedQRCode): uint16 =
  ## Iterates over every starting position of the blocks in group 2.
  var pos: uint16 =
    uint16(int(group1Blocks[self]) * int(group1BlockDataCodewords[self]))
  var b: uint8 = 0
  while b < group2Blocks[self]:
    yield pos
    pos = pos + uint16(group2BlockDataCodewords[self])
    b = b + 1'u8

proc interleaveDataCodewords*(self: var EncodedQRCode) =
  ## Interleaves the data codewords of `self`.
  ##
  ## The order is: 1st data codeword from B1, then 1st from B2, 2nd from B1,
  ## 2nd from B2, etc.
  if group1Blocks[self] == 1'u8 and group2Blocks[self] == 0'u8:
    return
  var
    dataCopy: seq[uint8] = self.data[0 .. int(self.calcEcStart) - 1]
    n: uint16 = 0
  template setData(pos: untyped) =
    self.data[n] = dataCopy[pos]
    n = n + 1'u16
  for i in 0'u8 ..< group1BlockDataCodewords[self]:
    for j in self.g1BlockPositions: setData(j + i)
    for j in self.g2BlockPositions: setData(j + i)
  if group2Blocks[self] > 0'u8:
    for j in self.g2BlockPositions:
      setData(j + group2BlockDataCodewords[self] - 1'u8)
