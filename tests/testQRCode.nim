import
  "."/[myTestSuite],
  std/strutils,
  QRgen/private/[QRCode, qrTypes]

benchmarkTest "getSmallestVersion() exact-capacity boundary":
  # A payload whose length exactly equals a version's capacity must fit in
  # that version, not be bumped to the next one (and, at v40's capacity, must
  # not be rejected). Regression for an off-by-one that used `<` where the
  # spec's capacity table is inclusive, so `<=` is required.

  # byte mode, v1-L capacity = 17
  check getSmallestVersion(repeat("a", 17), qrByteMode, qrECL) == 1
  check getSmallestVersion(repeat("a", 18), qrByteMode, qrECL) == 2
  # numeric mode, v1-L capacity = 41
  check getSmallestVersion(repeat("7", 41), qrNumericMode, qrECL) == 1
  check getSmallestVersion(repeat("7", 42), qrNumericMode, qrECL) == 2

  # v40-L numeric capacity = 7089: exact max must be accepted at v40.
  check getSmallestVersion(repeat("0123456789", 709)[0 ..< 7089],
                           qrNumericMode, qrECL) == 40
  let maxNumeric = newQRCode(repeat("0123456789", 709)[0 ..< 7089])
  check maxNumeric.version == 40
  check maxNumeric.mode == qrNumericMode

  # One digit past the absolute maximum must still overflow.
  expect DataSizeDefect:
    discard getSmallestVersion(repeat("7", 7090), qrNumericMode, qrECL)

benchmarkTest "newQRCode()":
  let qr1 = newQRCode("0123456789")
  check qr1.mode == qrNumericMode

  let qr2 = newQRCode("0 TEST ALPHANUMERIC 9")
  check qr2.mode == qrAlphanumericMode

  let qr3 = newQRCode("Tésting byté modé")
  check qr3.mode == qrByteMode

  let qr4 = newQRCode("0123", ecLevel = qrECH)
  check qr4.version == 1

  let qr5 = newQRCode("0 TEST ALPHANUMERIC 9", ecLevel = qrECQ)
  check qr5.version == 2

  let qr6 = newQRCode("012 Tésting byté modé 789", ecLevel = qrECH)
  check qr6.version == 4 # The accented characters count by 2
