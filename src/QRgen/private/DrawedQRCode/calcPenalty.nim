import
  "."/[type],
  ".."/[drawing]

func evaluateCondition1*(self: DrawedQRCode): uint16 =
  ## Evaluates the penalty of the applied mask using the condition 1 algorithm.
  result = 0
  var
    stateCol: bool
    countCol: uint16
    stateRow: bool
    countRow: uint16
  template mayAddPenalty(state: bool, count: uint16) =
    if   count == 5: result += 3
    elif count >= 5: result += count - 2
  template check(state: var bool, count: var uint16, getter: bool) =
    if not (state xor getter):
      count += 1
    else:
      mayAddPenalty state, count
      state = not state
      count = 1
  for i in 0'u8..<self.drawing.size:
    stateRow = self.drawing[0'u8, i]
    countRow = 1
    stateCol = self.drawing[i, 0'u8]
    countCol = 1
    for j in 1'u8..<self.drawing.size:
      check stateRow, countRow, self.drawing[j, i]
      check stateCol, countCol, self.drawing[i, j]
    mayAddPenalty stateRow, countRow
    mayAddPenalty stateCol, countCol

func evaluateCondition2*(self: DrawedQRCode): uint16 =
  ## Evaluates the penalty of the applied mask using the condition 2 algorithm.
  result = 0
  for i in 0'u8..<self.drawing.size-1:
    for j in 0'u8..<self.drawing.size-1:
      let actual = self.drawing[j, i]
      if not ((actual xor self.drawing[j+1, i]) or
              (actual xor self.drawing[j, i+1]) or
              (actual xor self.drawing[j+1, i+1])):
        result += 3

func evaluateCondition3*(self: DrawedQRCode): uint16 =
  ## Evaluates the penalty of the applied mask using the condition 3 algorithm.
  result = 0
  for i in 0'u8..<self.drawing.size:
    for j in 0'u8..<self.drawing.size-10:
      let hrun: uint16 = self.drawing[j..j+10'u8, i]
      if hrun == 0b10111010000'u16 or hrun == 0b00001011101'u16:
        result += 40
      let vrun: uint16 = self.drawing[i, j..j+10'u8]
      if vrun == 0b10111010000'u16 or vrun == 0b00001011101'u16:
        result += 40

func evaluateCondition4*(self: DrawedQRCode): uint16 =
  ## Evaluates the penalty of the applied mask using the condition 4 algorithm.
  var darkModules: int = 0
  for i in 0..<self.drawing.len:
    var b: uint8 = self.drawing[i]
    while b > 0'u8:
      darkModules += 1
      b = b and (b - 1'u8)
  let pct: int = (darkModules * 100) div (int(self.drawing.size) * int(self.drawing.size))
  case pct
  of 45..54: 0'u16
  of 40..44, 55..59: 10'u16
  of 35..39, 60..64: 20'u16
  of 30..34, 65..69: 30'u16
  of 25..29, 70..74: 40'u16
  of 20..24, 75..79: 50'u16
  of 15..19, 80..84: 60'u16
  of 10..14, 85..89: 70'u16
  of 5..9, 90..94: 80'u16
  of 0..4, 95..99: 90'u16
  else: 0'u16 # Should not be reached

template calcPenalty*(self: DrawedQRCode): uint16 =
  ## Helper template to sum the result of the 4 condition algorithms.
  self.evaluateCondition1 +
  self.evaluateCondition2 +
  self.evaluateCondition3 +
  self.evaluateCondition4
