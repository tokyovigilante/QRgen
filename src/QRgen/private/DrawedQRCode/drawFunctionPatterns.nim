import
  "."/[type],
  ".."/[drawing, qrCapacities, qrTypes]

func drawFinderPatterns*(self: var DrawedQRCode) =
  ## Draws the finder patterns in the upper left, upper right and lower left
  ## corners of the drawing.
  template drawFinderPattern(x, y: uint8) =
    self.drawing.fillRectangle x..x+6'u8,      y
    self.drawing.fillRectangle x..x+6'u8,      y+6'u8
    self.drawing.fillRectangle x,              y+1'u8..y+5'u8
    self.drawing.fillRectangle x+6'u8,         y+1'u8..y+5'u8
    self.drawing.fillRectangle x+2'u8..x+4'u8, y+2'u8..y+4'u8
  drawFinderPattern 0'u8, 0'u8
  drawFinderPattern self.drawing.size - 7'u8, 0'u8
  drawFinderPattern 0'u8, self.drawing.size - 7'u8

iterator alignmentPatternCoords(version: QRVersion): tuple[x, y: uint8] =
  ## Iterates over the positions of all alignment patterns.
  ##
  ## .. note:: The coordinate returned is the center of the alignment pattern.
  let locations = alignmentPatternLocations[version]
  for i, pos in locations:
    if i < locations.len - 1:
      yield (x: 6'u8, y: pos)
      yield (x: pos, y: 6'u8)
    for pos2 in locations[i..^1]:
      yield (x: pos, y: pos2)
      if pos != pos2:
        yield (x: pos2, y: pos)

proc drawAlignmentPatterns*(self: var DrawedQRCode) =
  ## Draws all the alignment patterns of the drawing.
  if self.version == 1'u8:
    return
  for x, y in alignmentPatternCoords(self.version):
    self.drawing.fillPoint     x,              y
    self.drawing.fillRectangle x-2'u8..x+2'u8, y-2'u8
    self.drawing.fillRectangle x-2'u8..x+2'u8, y+2'u8
    self.drawing.fillRectangle x-2'u8,         y-1'u8..y+1'u8
    self.drawing.fillRectangle x+2'u8,         y-1'u8..y+1'u8

func drawTimingPatterns*(self: var DrawedQRCode) =
  ## Draws all dark modules corresponding to the timing pattern of the drawing.
  iterator step(start, stop, step: uint8): uint8 =
    var x = start
    while x <= stop:
      yield x
      x = x + step
  const margin: uint8 = 8
  for pos in step(margin, self.drawing.size - margin, 2'u8):
    self.drawing.fillPoint pos, 6'u8
    self.drawing.fillPoint 6'u8, pos

func drawDarkModule*(self: var DrawedQRCode) =
  ## Draws the dark module of the drawing.
  self.drawing.fillPoint 8'u8, self.drawing.size - 8'u8
