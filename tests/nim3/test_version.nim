## BUG 2 regression: a payload whose length exactly equals a version's capacity
## must fit in that version (the capacity table is inclusive, so `<=`), and the
## v40 maximum must be accepted rather than rejected.

import std/syncio
import QRgen/private/qrTypes
import QRgen/private/qrCode
import testkit

echo "test_version"
try:
  # byte mode, v1-L capacity = 17
  check(getSmallestVersion(rep('a', 17), qrByteMode, qrECL) == 1'u8,
        "17 bytes fit in v1")
  check(getSmallestVersion(rep('a', 18), qrByteMode, qrECL) == 2'u8,
        "18 bytes need v2")
  # numeric mode, v1-L capacity = 41
  check(getSmallestVersion(rep('7', 41), qrNumericMode, qrECL) == 1'u8,
        "41 digits fit in v1")
  check(getSmallestVersion(rep('7', 42), qrNumericMode, qrECL) == 2'u8,
        "42 digits need v2")
  # v40-L numeric capacity = 7089: exact maximum accepted at v40.
  check(getSmallestVersion(rep('0', 7089), qrNumericMode, qrECL) == 40'u8,
        "7089 digits accepted at v40")
  let maxQr = newQRCode(rep('0', 7089))
  check(int(maxQr.version) == 40, "v40 maximal numeric QRCode builds")
  check(maxQr.mode == qrNumericMode, "maximal payload uses numeric mode")
except:
  check(false, "unexpected DataSizeDefect on a payload that should fit")

# One digit past the absolute maximum must still overflow.
var overflowed = false
try:
  discard getSmallestVersion(rep('7', 7090), qrNumericMode, qrECL)
except:
  overflowed = true
check(overflowed, "7090 digits overflow (DataSizeDefect raised)")

finish()
