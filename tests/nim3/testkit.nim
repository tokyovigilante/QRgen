## Minimal test kit for the Nimony (Nim 3) QRgen port.
##
## Nimony has no Testament/unittest, so each tests/nim3/test_*.nim is a plain
## program that imports this kit, calls `check`, and ends with `finish()` so a
## non-zero exit marks failure for the `run` script. `check` continues on
## failure and reports every case plus a tally.

import std/syncio

var failures*: int = 0

proc check*(cond: bool, msg: string) =
  if cond:
    echo "  ok    ", msg
  else:
    echo "  FAIL  ", msg
    failures = failures + 1

proc finish*() =
  if failures > 0:
    echo failures, " check(s) FAILED"
    quit(1)
  echo "all checks passed"

proc rep*(ch: char, n: int): string =
  ## Small helper: a string of `n` copies of `ch` (no std/strutils dependency).
  result = ""
  for _ in 0 ..< n:
    result.add ch
