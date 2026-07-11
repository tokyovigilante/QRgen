## BUG 1 regression (ISO/IEC 18004 §7.4.3): every full 3-digit numeric group is
## encoded in a fixed 10 bits regardless of leading zeros; only a trailing
## 2/1-digit remainder uses 7/4 bits.

import std/syncio
import QRgen/private/qrTypes
import QRgen/private/bitArray
import QRgen/private/qrCode
import QRgen/private/EncodedQRCode/type
import QRgen/private/EncodedQRCode/encodeIndicators
import QRgen/private/EncodedQRCode/encodeDataCodewords
import QRgen/private/EncodedQRCode/encodedQRCode
import testkit

proc numericSegmentPos(data: string): uint16 {.raises.} =
  ## Bit position after mode indicator (4) + char count indicator (10, numeric
  ## v1) + the encoded numeric data segment.
  var qr = newEncodedQRCode newQRCode(data)
  qr.encodeModeIndicator
  qr.encodeCharCountIndicator data
  qr.encodeDataCodewords data
  qr.data.pos

echo "test_numeric"
try:
  # "012" -> one full group in 10 bits (buggy code emitted 7): 4 + 10 + 10
  check(numericSegmentPos("012") == 24'u16, "\"012\" segment is 10 bits")
  # "00012" -> "000" in 10 bits + "12" remainder in 7: 4 + 10 + 17
  check(numericSegmentPos("00012") == 31'u16, "\"00012\" zero group + remainder")
  # "0123456789" -> 3 full groups (30) + "9" (4): 4 + 10 + 34
  check(numericSegmentPos("0123456789") == 48'u16, "\"0123456789\" segment bits")

  # Full pipeline data codewords for "0123456789" (numeric, v1-L, single block
  # so encode == encodeOnly for the data region). Hand-derived from the spec.
  let qr = encode newQRCode("0123456789")
  let want = [16'u8, 40, 12, 86, 106, 105]
  var okVec = true
  for i in 0 ..< 6:
    if qr.data[i] != want[i]: okVec = false
  check(okVec, "0123456789 data codewords 0..5")
  check(int(qr.version) == 1, "0123456789 fits in version 1")

  # Upstream's own vector (no zero-led group) must still be correct.
  let qr2 = encode newQRCode("8675309")
  let want2 = [16'u8, 31, 99, 132, 164, 0]
  var okVec2 = true
  for i in 0 ..< 6:
    if qr2.data[i] != want2[i]: okVec2 = false
  check(okVec2, "8675309 data codewords 0..5 unchanged")
except:
  check(false, "unexpected DataSizeDefect")

finish()
