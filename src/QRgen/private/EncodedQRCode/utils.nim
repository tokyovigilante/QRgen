## This module contains some utilities used in this directory's modules.

import
  "."/[type],
  ".."/[qrCapacities]

# nimony rejects a generic `[]*[T](self: QRCapacity[T], ...)` template (the
# `uint8|uint16` constraint fails to resolve), so provide one concrete overload
# per element type instead.
template `[]`*(self: QRCapacity[uint8], qr: EncodedQRCode): uint8 =
  ## Get the `uint8` value stored in `self` from the `ecLevel`/`version` of `qr`.
  self[qr.ecLevel][qr.version]

template `[]`*(self: QRCapacity[uint16], qr: EncodedQRCode): uint16 =
  ## Get the `uint16` value stored in `self` from the `ecLevel`/`version` of `qr`.
  self[qr.ecLevel][qr.version]

template `^=`*(self: untyped, expr: untyped) =
  ## A helper template operator like the one found in C, where `self` is xored
  ## with `expr` and assigned to `self`.
  self = self xor expr

iterator step*(start, stop, step: int): int =
  ## A simple iterator to iterate starting from `start`, increasing by `step`
  ## until `stop` is reached.
  var x = start
  while x <= stop - step:
    yield x
    x = x + step

proc calcEcStart*(self: EncodedQRCode): uint16 =
  ## Returns the position of the first block of ECC in `self`.
  uint16(
    int(group1Blocks[self]) * int(group1BlockDataCodewords[self]) +
    int(group2Blocks[self]) * int(group2BlockDataCodewords[self])
  )
