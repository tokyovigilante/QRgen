## # Bit array implementation
##
## This module implements a simple `BitArray` object which consists of a
## regular `seq[uint8]` and a `pos`.
##
## There are 2 main procedures, one to add more bits to the BitArray,
## `add`, and another to skip to the next byte, `nextByte`.
##
## .. note:: Nimony port — `add` takes a `uint16` value rather than being
##    generic over `SomeUnsignedInt`. Every value this library packs fits in
##    16 bits, and the emitted bits are identical; this avoids nimony's
##    generic-arithmetic friction. Callers pass `uint16` (a `uint8` is widened
##    at the call site).

type
  BitArray* = object
    ## A BitArray object used by `EncodedQRCode`.
    ##
    ## `pos` is used to keep track of where new bits will be placed.
    pos*: uint16
    data*: seq[uint8]

proc newBitArray*(size: uint16): BitArray =
  ## Creates a new `BitArray` object whose `data` will have a cap of `size`
  ## and it's len will also be set to `size`.
  result = BitArray(pos: 0'u16, data: newSeqOfCap[uint8](int(size)))
  result.data.setLen(int(size))

template `[]`*(self: BitArray, i: untyped): untyped =
  ## Get the value of `data` in index (or slice) `i`. `i` is untyped so both an
  ## integer index (yielding a `uint8`) and a slice (yielding `seq[uint8]`)
  ## work — nimony rejects the `SomeInteger`/`HSlice` typeclass template params.
  self.data[i]

template `[]=`*(self: var BitArray, i: untyped, val: uint8) =
  ## Set the value of `data` in index `i` to `val`.
  self.data[i] = val

proc nextByte*(self: var BitArray): uint8 =
  ## Moves `pos` to the next byte, unless it is pointing to the start of an
  ## empty byte, returning the amount of bits skipped.
  let bytePos: uint8 = cast[uint8](self.pos mod 8'u16)
  result =
    if bytePos > 0'u8: 8'u8 - bytePos
    else: 0'u8
  self.pos = self.pos + uint16(result)

proc add*(self: var BitArray, val: uint16, len: uint8) =
  ## Add `len` amount of bits from `val` starting from the rightmost bit.
  if len == 0'u8: return
  let
    arrPos: uint16 = self.pos div 8'u16
    bitsLeft: uint8 = 8'u8 - cast[uint8](self.pos mod 8'u16)
  if len <= bitsLeft:
    self.data[arrPos] = self.data[arrPos] + cast[uint8](
      (val and uint16(0xFF'u8 shr (8'u8 - len))) shl (bitsLeft - len)
    )
  else:
    let
      bytes: uint8 = (len - bitsLeft) div 8'u8
      remBits: uint8 = (len - bitsLeft) mod 8'u8
    if remBits > 0'u8:
      self.data[arrPos + uint16(bytes) + 1'u16] =
        cast[uint8](val shl (8'u8 - remBits))
    var v: uint16 = val shr remBits
    for i in 0'u8 ..< bytes:
      self.data[arrPos + uint16(bytes) - uint16(i)] = cast[uint8](v)
      v = v shr 8'u8
    self.data[arrPos] = self.data[arrPos] +
      cast[uint8](v and uint16(0xFF'u8 shr (8'u8 - bitsLeft)))
  self.pos = self.pos + uint16(len)

template unsafeAdd*(self: var BitArray, val: uint8) =
  ## Add `val` to the end of `data`.
  self.data.add val

template unsafeDelete*(self: var BitArray, pos: uint16) =
  ## Remove the value from `data` in position `pos`.
  self.data.delete int(pos)

template unsafeSet*(self: var BitArray, pos, val: untyped) =
  ## Sets the value from `data` in position `pos` to `val`. `pos` is passed
  ## through untyped so a `BackwardsIndex` (`^1`) is accepted.
  self.data[pos] = val

template len*(self: BitArray): int =
  ## Get the len of `self.data`.
  self.data.len
