## Acceptance: the Nimony build must produce the *same* module matrix as the
## Nim-2 build for a realistic Keycloak RFC 8628 verification_uri_complete
## (byte mode) and an all-digit user_code (numeric mode, exercising BUG 1).
##
## The reference invariants (size, version, mask, dark-module count, an FNV-1a
## hash over the whole matrix, and the first/last rows) were captured from the
## Nim-2 build's text dump. A full row-by-row `diff` of both builds' dumps is
## also part of the acceptance and was confirmed IDENTICAL out of band.

import std/syncio
import QRgen
import QRgen/private/drawing
import testkit

proc matrixRows(qr: DrawedQRCode): seq[string] =
  result = @[]
  let n = int(qr.drawing.size)
  for y in 0 ..< n:
    var row = ""
    for x in 0 ..< n:
      if qr.drawing[uint8(x), uint8(y)]: row.add '1' else: row.add '0'
    result.add row

proc fnv1a(rows: seq[string]): uint32 =
  result = 2166136261'u32
  for r in rows:
    for c in r:
      result = (result xor uint32(uint8(c))) * 16777619'u32

proc darkCount(rows: seq[string]): int =
  result = 0
  for r in rows:
    for c in r:
      if c == '1': result = result + 1

const keycloak =
  "https://auth.testtoast.com/realms/kaitake/device?user_code=WDJB-MJHT&session_state=a1B2c3D4e5F6g7"
const userCode = "01234567890123456789012345678901"

echo "test_acceptance"
try:
  block:
    let qr = newQR(keycloak, qrECM)
    let rows = matrixRows(qr)
    check(int(qr.drawing.size) == 41, "keycloak size 41")
    check(int(qr.version) == 6, "keycloak version 6")
    check(int(qr.mask) == 7, "keycloak mask 7")
    check(darkCount(rows) == 862, "keycloak dark modules 862")
    check(fnv1a(rows) == 4110562161'u32, "keycloak matrix FNV matches Nim-2")
    check(rows[0] == "11111110011101110101000100000010001111111",
          "keycloak first row")
    check(rows[40] == "11111110111110111011011000000101111111010",
          "keycloak last row")

  block:
    let qr = newQR(userCode, qrECL)
    let rows = matrixRows(qr)
    check(int(qr.drawing.size) == 21, "usercode size 21")
    check(int(qr.version) == 1, "usercode version 1")
    check(int(qr.mask) == 3, "usercode mask 3")
    check(darkCount(rows) == 226, "usercode dark modules 226")
    check(fnv1a(rows) == 770895679'u32, "usercode matrix FNV matches Nim-2")
    check(rows[0] == "111111101100101111111", "usercode first row")
    check(rows[20] == "111111101011100010110", "usercode last row")

  # SVG nice-to-have: default output well-formed.
  let svg = newQR(userCode, qrECL).printSvg
  check(svg.len > 0 and svg[0] == '<', "printSvg returns non-empty SVG")
except:
  check(false, "unexpected DataSizeDefect")

finish()
