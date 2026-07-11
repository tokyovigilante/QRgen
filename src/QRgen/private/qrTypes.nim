## # QR Types
##
## This module compromises of a collection of commonly used types across almost
## all modules.
##
## .. note:: Nimony port — `QRVersion` is a plain `uint8` rather than a
##    `range[1'u8..40'u8]`. Nimony's range prover rejects the pervasive
##    unsigned index arithmetic this library performs; the valid range
##    (1..40) is still enforced structurally by the capacity tables, which
##    are `array[1'u8..40'u8, T]`.

type
  QRMode* {.size: sizeof(uint8).} = enum
    ## Denotes the mode a QR code is to be encoded with.
    qrNumericMode      = 0b0001,
    qrAlphanumericMode = 0b0010,
    qrByteMode         = 0b0100,
    # qrECIMode   = 0b0111 (Extended Channel Interpretation) not supported
    # qrKanjiMode = 0b1000                                   not supported

  QRECLevel* {.size: sizeof(uint8).} = enum
    ## Denotes the Error Correction level which will be used to create
    ## the error correction codewords (ECCs) of the QR code.
    qrECL, #  7% data recovery
    qrECM, # 15% data recovery
    qrECQ, # 25% data recovery
    qrECH  # 30% data recovery

  QRVersion* = uint8
    ## Denotes the version of the QR code, which also indicates it's size.
    ## Valid values are 1..40.
