## # Drawing implementation
##
## This module implements a simple `Drawing` object which consists of a
## 2D matrix stored in a regular `seq[uint8]` and it's `size`.
##
## `[]` checks whether the module at `x,y` is dark (`true`) or light (`false`);
## `[]=` sets it. Nimony note: mixed-width unsigned arithmetic promotes to
## `uint64`, so bit-position math is done via `int` and narrowed explicitly.

type
  Drawing* = object
    ## A Drawing object used by `DrawedQRCode`.
    ##
    ## .. note:: A `Drawing` is always a square, hence it's `size` is both
    ##    it's width and it's height.
    matrix*: seq[uint8]
    size*: uint8

func newDrawing*(size: uint8): Drawing =
  ## Creates a new `Drawing` object with the size `size`.
  let matrixSize: int = (int(size) * int(size)) div 8 + 1
  result = Drawing(matrix: newSeqOfCap[uint8](matrixSize), size: size)
  result.matrix.setLen(matrixSize)

func `[]`*(self: Drawing, x, y: uint8): bool =
  ## Returns true if the module at position `x,y` is dark, else false.
  let bitPos: int = int(y) * int(self.size) + int(x)
  let shift: uint8 = uint8(7 - (bitPos mod 8))
  ((self.matrix[bitPos div 8] shr shift) and 0x01'u8) == 0x01'u8

func `[]`*(self: Drawing, x: Slice[uint8], y: uint8): uint16 =
  ## Returns a `uint16` with the bits in the range `x` at row `y`.
  result = 0'u16
  let bitPosY: int = int(y) * int(self.size)
  for b in (bitPosY + int(x.a)) .. (bitPosY + int(x.b)):
    let shift: uint8 = uint8(7 - (b mod 8))
    result = uint16((int(result) shl 1) +
      int((self.matrix[b div 8] shr shift) and 0x01'u8))

func `[]`*(self: Drawing, x: uint8, y: Slice[uint8]): uint16 =
  ## Returns a `uint16` with the bits in the range `y` at column `x`.
  result = 0'u16
  for yy in y.a .. y.b:
    let b: int = int(self.size) * int(yy) + int(x)
    let shift: uint8 = uint8(7 - (b mod 8))
    result = uint16((int(result) shl 1) +
      int((self.matrix[b div 8] shr shift) and 0x01'u8))

func `[]=`*(self: var Drawing, x, y: uint8, val: bool) =
  ## Sets the module at position `x,y` to dark if `val` is true, else light.
  let bitPos: int = int(y) * int(self.size) + int(x)
  let arrPos: int = bitPos div 8
  let shift: uint8 = uint8(7 - (bitPos mod 8))
  self.matrix[arrPos] =
    if val:
      self.matrix[arrPos] or (0x01'u8 shl shift)
    else:
      self.matrix[arrPos] and (0xFF'u8 xor (0x01'u8 shl shift))

template fillPoint*(self: var Drawing, x, y: uint8) =
  ## A helper template to set the module at position `x,y` to dark.
  self[x, y] = true

template flipPoint*(self: var Drawing, x, y: uint8) =
  ## A helper template to flip the state of the module at position `x,y`.
  self[x, y] = not self[x, y]

func fillRectangle*(self: var Drawing, xRange, yRange: Slice[uint8]) =
  ## Set all modules where `x` is in `xRange` and `y` is in `yRange` to dark.
  for y in yRange.a .. yRange.b:
    for x in xRange.a .. xRange.b:
      self.fillPoint x, y

template fillRectangle*(self: var Drawing, xRange: Slice[uint8], y: uint8) =
  ## Set all modules where `x` is in `xRange` and `y` is `y` to dark.
  self.fillRectangle xRange, y..y

template fillRectangle*(self: var Drawing, x: uint8, yRange: Slice[uint8]) =
  ## Set all modules where `y` is in `yRange` and `x` is `x` to dark.
  self.fillRectangle x..x, yRange

template fillRectangle*(self: var Drawing, xyRange: Slice[uint8]) =
  ## Set all modules where both x and y are in `xyRange` to dark.
  self.fillRectangle xyRange, xyRange

func `[]`*(self: Drawing, i: int): uint8 =
  ## Get the value of `self.matrix` at index `i`.
  self.matrix[i]

template len*(self: Drawing): int =
  ## Get the value of `self.matrix.len`.
  self.matrix.len
