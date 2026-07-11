## # QR Characters
##
## This module contains some utilities to deal with encoding and QR mode
## detection.
##
## .. note:: The "alphanumeric table" is mentioned some times in this document,
##    for reference you can find it in thonky's website,
##    `here<https://www.thonky.com/qr-code-tutorial/alphanumeric-table>`_.

const
  numericValues*      = {'0'..'9'}
  alphaValues*        = {'A'..'Z'}
  specialValues*      = {' ', '$', '%', '*', '+', '-', '.', '/', ':'}
  alphaNumericValues* = specialValues + numericValues + alphaValues

proc getSpecialValue(c: char): uint8 =
  ## Returns the value of the special character `c` according to the
  ## alphanumeric table. Sets iterate in ascending char-code order, which is
  ## exactly the order the alphanumeric table numbers the special characters
  ## (space=36 .. ':'=44).
  result = 0xFF'u8
  var i = 0'u8
  for val in specialValues:
    if val == c:
      return i + 36'u8
    i = i + 1'u8

proc getAlphanumericValue*(c: char): uint8 =
  ## Returns the value of the alphanumeric character `c` according to the
  ## alphanumeric table, else returns `0xFF` (`uint8.high`).
  const
    firstNumericPos: uint8 = cast[uint8]('0')
    firstAlphaPos: uint8 = cast[uint8]('A') - 10'u8
  case c
  of numericValues: cast[uint8](c) - firstNumericPos
  of alphaValues: cast[uint8](c) - firstAlphaPos
  of specialValues: getSpecialValue c
  else: 0xFF'u8
