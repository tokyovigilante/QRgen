## Upstream encoder fixed vectors (alphanumeric + byte modes), ported from the
## Nim-2 test suite. These exercise the encode paths the BUG-1 fix did not touch
## and pin the byte-level output.

import std/syncio
import QRgen/private/qrTypes
import QRgen/private/bitArray
import QRgen/private/qrCode
import QRgen/private/EncodedQRCode/encodedQRCode
import testkit

proc checkVec(qr: EncodedQRCode, want: openArray[uint8], name: string) =
  var ok = true
  for i in 0 ..< want.len:
    if qr.data[i] != want[i]: ok = false
  check(ok, name)

echo "test_encode_vectors"
try:
  # Alphanumeric: "HELLO WORLD" at ecLevel Q (v1, single block).
  checkVec(encode newQRCode("HELLO WORLD", qrECQ),
    [32'u8, 91, 11, 120, 209, 114, 220, 77, 67, 64, 236, 17, 236],
    "HELLO WORLD (alphanumeric, Q)")
  # Byte: "Hello, world!" at default ecLevel L (v1, single block).
  checkVec(encode newQRCode("Hello, world!"),
    [64'u8, 212, 134, 86, 198, 198, 242, 194, 7, 118, 247, 38, 198, 66, 16,
     236, 17, 236, 17],
    "Hello, world! (byte, L)")
except:
  check(false, "unexpected DataSizeDefect")

finish()
