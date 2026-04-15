/*
 * Copyright (C) 2014-2017 Igalia S.L.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

enum GridTrackSizingDirection {
  case ForColumns
  case ForRows
}

private func contains_(_ indices: [UInt32]?, _ line: UInt32) -> Bool {
  return indices != nil && indices!.contains(line)
}

class NamedLineCollectionBase {
  init(
    initialGrid: RenderGridWrapper, name: StringWrapper, side: GridPositionSide,
    nameIsAreaName: Bool
  ) {
    let lineName = nameIsAreaName ? implicitNamedGridLineForSide(lineName: name, side: side) : name
    let direction = directionFromSide(side: side)
    let gridContainerStyle = initialGrid.style()
    let isRowAxis = direction == .ForColumns

    lastLine = explicitGridSizeForSide(gridContainer: initialGrid, side: side)

    let gridLineNames =
      isRowAxis ? gridContainerStyle.namedGridColumnLines() : gridContainerStyle.namedGridRowLines()
    let autoRepeatGridLineNames =
      isRowAxis
      ? gridContainerStyle.autoRepeatNamedGridColumnLines()
      : gridContainerStyle.autoRepeatNamedGridRowLines()
    let implicitGridLineNames =
      isRowAxis
      ? gridContainerStyle.implicitNamedGridColumnLines()
      : gridContainerStyle.implicitNamedGridRowLines()

    self.namedLinesIndices = gridLineNames[lineName]
    self.autoRepeatNamedLinesIndices = autoRepeatGridLineNames[lineName]
    self.implicitNamedLinesIndices = implicitGridLineNames[lineName]
    self.isSubgrid = initialGrid.isSubgrid(direction: direction)

    self.autoRepeatTotalTracks = initialGrid.autoRepeatCountForDirection(direction: direction)
    self.autoRepeatTrackListLength = UInt32(
      isRowAxis
        ? gridContainerStyle.gridAutoRepeatColumns().count
        : gridContainerStyle.gridAutoRepeatRows().count)
    self.autoRepeatLines = 0
    self.insertionPoint =
      isRowAxis
      ? gridContainerStyle.gridAutoRepeatColumnsInsertionPoint()
      : gridContainerStyle.gridAutoRepeatRowsInsertionPoint()

    if !isSubgrid {
      if isRowAxis ? gridContainerStyle.gridSubgridColumns() : gridContainerStyle.gridSubgridRows()
      {
        // If subgrid was specified, but the grid wasn't able to actually become a subgrid, the used
        // value of the style should be the initial 'none' value.
        self.namedLinesIndices = nil
        self.autoRepeatNamedLinesIndices = nil
      }
      return
    }

    if self.implicitNamedLinesIndices == nil {
      // The implicit lines list was created based on the areas specified for the grid areas property, but the
      // subgrid might have inherited fewer tracks than needed to cover the specified area. We want to clamp
      // the specified area down to explicit grid we actually have, and then generate implicit -start/-end
      // lines for the new area.
      assert(self.implicitNamedLinesIndices!.count == 1)
      self.implicitNamedLinesIndices = inheritedNamedLinesIndices

      // Find the area name that creates the implicit line we're looking for. If the input was an area name,
      // then we can use that, otherwise we need to choose the substring and infer which side the input specified.
      // It's possible for authors to manually name a *-start implicit line name for the end line search, and vice-versa,
      // so we need to remember which side we inferred from the name, separately from the side we're searching for.
      var areaName = name
      var startSide = isStartSide(side: side)
      if !nameIsAreaName {
        var suffix = name.find(literal: "-start")
        if suffix != nil {
          suffix = name.find(literal: "-end")
          assert(suffix != nil)
          startSide = false
        } else {
          startSide = true
        }
        areaName = name.left(length: UInt32(suffix!))
      }
      if let implicitLine = clampedImplicitLineForArea(
        style: gridContainerStyle, name: areaName, min: 0, max: Int32(self.lastLine),
        isRowAxis: isRowAxis,
        isStartSide: startSide)
      {
        self.inheritedNamedLinesIndices.append(UInt32(implicitLine))
      }
    }

    assert(self.autoRepeatTotalTracks == 0)
    self.autoRepeatTrackListLength =
      UInt32(
        (isRowAxis
          ? gridContainerStyle.autoRepeatOrderedNamedGridColumnLines()
          : gridContainerStyle.autoRepeatOrderedNamedGridRowLines()).count)
    if self.autoRepeatTrackListLength != 0 {
      let namedLines =
        UInt32(
          (isRowAxis
            ? gridContainerStyle.orderedNamedGridColumnLines()
            : gridContainerStyle.orderedNamedGridRowLines()).count)
      let totalLines = self.lastLine + 1
      if namedLines < totalLines {
        // auto repeat in a subgrid specifies the line names that should be repeated, not
        // the tracks.
        self.autoRepeatLines = (totalLines - namedLines) / self.autoRepeatTrackListLength
        self.autoRepeatLines *= self.autoRepeatTrackListLength
      }
    }
  }

  func hasNamedLines() -> Bool {
    return hasExplicitNamedLines()
      || (implicitNamedLinesIndices != nil && !implicitNamedLinesIndices!.isEmpty)
  }

  func hasExplicitNamedLines() -> Bool {
    if namedLinesIndices != nil {
      return true
    }
    return autoRepeatNamedLinesIndices != nil && (!isSubgrid || autoRepeatLines != 0)
  }

  func contains(line: UInt32) -> Bool {
    assert(hasNamedLines())

    if line > self.lastLine {
      return false
    }

    if contains_(self.implicitNamedLinesIndices, line) {
      return true
    }

    if self.autoRepeatTrackListLength == 0 || line < self.insertionPoint {
      return contains_(self.namedLinesIndices, line)
    }

    if self.isSubgrid {
      if line >= self.insertionPoint + self.autoRepeatLines {
        return contains_(self.namedLinesIndices, line - self.autoRepeatLines)
      }

      if self.autoRepeatLines == 0 {
        return contains_(self.namedLinesIndices, line)
      }

      let autoRepeatIndexInFirstRepetition =
        (line - self.insertionPoint) % self.autoRepeatTrackListLength
      return contains_(self.autoRepeatNamedLinesIndices, autoRepeatIndexInFirstRepetition)
    }

    assert(self.autoRepeatTotalTracks != 0)

    if line > self.insertionPoint + self.autoRepeatTotalTracks {
      return contains_(self.namedLinesIndices, line - (self.autoRepeatTotalTracks - 1))
    }

    if line == self.insertionPoint {
      return contains_(self.namedLinesIndices, line)
        || contains_(self.autoRepeatNamedLinesIndices, 0)
    }

    if line == self.insertionPoint + self.autoRepeatTotalTracks {
      return contains_(self.autoRepeatNamedLinesIndices, self.autoRepeatTrackListLength)
        || contains_(self.namedLinesIndices, self.insertionPoint + 1)
    }

    let autoRepeatIndexInFirstRepetition =
      (line - self.insertionPoint) % self.autoRepeatTrackListLength
    if autoRepeatIndexInFirstRepetition == 0
      && contains_(self.autoRepeatNamedLinesIndices, self.autoRepeatTrackListLength)
    {
      return true
    }
    return contains_(self.autoRepeatNamedLinesIndices, autoRepeatIndexInFirstRepetition)
  }

  func ensureInheritedNamedIndices() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var namedLinesIndices: [UInt32]? = nil
  private var autoRepeatNamedLinesIndices: [UInt32]? = nil
  private var implicitNamedLinesIndices: [UInt32]? = nil

  var inheritedNamedLinesIndices: [UInt32] = []

  private var insertionPoint: UInt32 = 0
  var lastLine: UInt32 = 0
  private var autoRepeatTotalTracks: UInt32 = 0
  private var autoRepeatLines: UInt32 = 0
  private var autoRepeatTrackListLength: UInt32 = 0
  private var isSubgrid = false
}

class NamedLineCollection: NamedLineCollectionBase {
  override init(
    initialGrid: RenderGridWrapper, name: StringWrapper, side: GridPositionSide,
    nameIsAreaName: Bool = false
  ) {
    super.init(initialGrid: initialGrid, name: name, side: side, nameIsAreaName: nameIsAreaName)
    if lastLine == 0 {
      return
    }
    var search = GridSpan.translatedDefiniteGridSpan(startLine: 0, endLine: lastLine)
    var currentSide = side
    var direction = directionFromSide(side: currentSide)
    let initialFlipped = GridLayoutFunctions.isFlippedDirection(
      grid: initialGrid, direction: direction)
    var isRowAxis = direction == .ForColumns

    if !initialGrid.isSubgrid(direction: direction) {
      return
    }

    // If we're a subgrid, we want to inherit the line names from any ancestor grids.
    for currentAncestorSubgrid in AncestorSubgridIterator(
      firstAncestorSubgrid: initialGrid, direction: direction)
    {
      let currentAncestorSubgridParent = currentAncestorSubgrid.parent() as! RenderGridWrapper

      // auto-placed subgrids inside a masonry grid do not inherit any line names
      if (currentAncestorSubgridParent.areMasonryRows()
        && (currentAncestorSubgrid.style().gridItemColumnStart().isAuto()
          || currentAncestorSubgrid.style().gridItemColumnStart().isSpan()))
        || (currentAncestorSubgridParent.areMasonryColumns()
          && (currentAncestorSubgrid.style().gridItemRowStart().isAuto()
            || currentAncestorSubgrid.style().gridItemRowStart().isSpan()))
      {
        return
      }
      // Translate our explicit grid set of lines into the coordinate space of the
      // parent grid, adjusting direction/side as needed.
      if currentAncestorSubgrid.isHorizontalWritingMode()
        != currentAncestorSubgridParent.isHorizontalWritingMode()
      {
        isRowAxis = !isRowAxis
        currentSide = transposedSide(side: currentSide)
      }
      direction = directionFromSide(side: currentSide)

      let span = currentAncestorSubgridParent.gridSpanForGridItem(
        gridItem: currentAncestorSubgrid, direction: direction)
      search.translateTo(
        parent: span,
        reverse: GridLayoutFunctions.isSubgridReversedDirection(
          grid: currentAncestorSubgridParent, outerDirection: direction,
          subgrid: currentAncestorSubgrid))

      let convertToInitialSpace = { [self] (_ i: UInt32) in
        assert(i >= search.startLine())
        var i = i
        i -= search.startLine()
        if GridLayoutFunctions.isFlippedDirection(
          grid: currentAncestorSubgridParent, direction: direction)
          != initialFlipped
        {
          assert(lastLine >= i)
          i = lastLine - i
        }
        return i
      }

      // Create a line collection for the parent grid, and check to see if any of our lines
      // are present. If we find any, add them to a locally stored line name list (with numbering
      // relative to our grid).
      var appended = false
      let parentCollection = NamedLineCollectionBase(
        initialGrid: currentAncestorSubgridParent, name: name, side: currentSide,
        nameIsAreaName: nameIsAreaName)
      if parentCollection.hasNamedLines() {
        for i in search.startLine()...search.endLine() {
          if parentCollection.contains(line: i) {
            ensureInheritedNamedIndices()
            appended = true
            inheritedNamedLinesIndices.append(convertToInitialSpace(i))
          }
        }
      }

      if nameIsAreaName,
        // We now need to look at the grid areas for the parent (not the implicit
        // lines for the parent!), and insert the ones that intersect as implicit
        // lines (but in our single combined list).
        let implicitLine = clampedImplicitLineForArea(
          style: currentAncestorSubgridParent.style(), name: name, min: Int32(search.startLine()),
          max: Int32(search.endLine()),
          isRowAxis: isRowAxis, isStartSide: isStartSide(side: side))
      {
        ensureInheritedNamedIndices()
        appended = true
        inheritedNamedLinesIndices.append(convertToInitialSpace(UInt32(implicitLine)))
      }

      if appended {
        // Re-sort inheritedNamedLinesIndices
        inheritedNamedLinesIndices.sort()
      }
    }
  }

  func firstPosition() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastLine() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

private func isColumnSide(side: GridPositionSide) -> Bool {
  return side == .ColumnStartSide || side == .ColumnEndSide
}

private func isStartSide(side: GridPositionSide) -> Bool {
  return side == .ColumnStartSide || side == .RowStartSide
}

private func directionFromSide(side: GridPositionSide) -> GridTrackSizingDirection {
  return side == .ColumnStartSide || side == .ColumnEndSide ? .ForColumns : .ForRows
}

private func implicitNamedGridLineForSide(lineName: StringWrapper, side: GridPositionSide)
  -> StringWrapper
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func explicitGridSizeForSide(gridContainer: RenderGridWrapper, side: GridPositionSide)
  -> UInt32
{
  return isColumnSide(side: side)
    ? GridPositionsResolver.explicitGridColumnCount(gridContainer: gridContainer)
    : GridPositionsResolver.explicitGridRowCount(gridContainer: gridContainer)
}

private func transposedSide(side: GridPositionSide) -> GridPositionSide {
  switch side {
  case .ColumnStartSide: return .RowStartSide
  case .ColumnEndSide: return .RowEndSide
  case .RowStartSide: return .ColumnStartSide
  case .RowEndSide: return .ColumnEndSide
  }
}

private func clampedImplicitLineForArea(
  style: RenderStyleWrapper, name: StringWrapper, min: Int32, max: Int32, isRowAxis: Bool,
  isStartSide: Bool
) -> Int32? {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

// https://drafts.csswg.org/css-grid-2/#indefinite-grid-span
private func isIndefiniteSpan(initialPosition: GridPosition, finalPosition: GridPosition) -> Bool {
  if initialPosition.isAuto() {
    return !finalPosition.isSpan()
  }
  if finalPosition.isAuto() {
    return !initialPosition.isSpan()
  }
  return false
}

private func adjustGridPositionsFromStyle(
  gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
) -> (GridPosition, GridPosition) {
  let isForColumns = direction == .ForColumns
  let initialPosition =
    isForColumns ? gridItem.style().gridItemColumnStart() : gridItem.style().gridItemRowStart()
  var finalPosition =
    isForColumns ? gridItem.style().gridItemColumnEnd() : gridItem.style().gridItemRowEnd()

  // We must handle the placement error handling code here instead of in the StyleAdjuster because we don't want to
  // overwrite the specified values.
  if initialPosition.isSpan() && finalPosition.isSpan() {
    finalPosition.setAutoPosition()
  }

  // If the grid item has an automatic position and a grid span for a named line in a given dimension, instead treat the grid span as one.
  if initialPosition.isAuto() && finalPosition.isSpan() && !finalPosition.namedGridLine().isNull() {
    finalPosition.setSpanPosition(position: 1, namedGridLine: StringWrapper())
  }
  if finalPosition.isAuto() && initialPosition.isSpan() && !initialPosition.namedGridLine().isNull()
  {
    initialPosition.setSpanPosition(position: 1, namedGridLine: StringWrapper())
  }

  if isIndefiniteSpan(initialPosition: initialPosition, finalPosition: finalPosition) {
    if let renderGrid = gridItem as? RenderGridWrapper, renderGrid.isSubgrid(direction: direction) {
      // Indefinite span for an item that is subgridded in this axis.
      let lineCount = Int32(
        (isForColumns
          ? gridItem.style().orderedNamedGridColumnLines()
          : gridItem.style().orderedNamedGridRowLines()).count)

      if initialPosition.isAuto() {
        // Set initial position to span <line names - 1>
        initialPosition.setSpanPosition(
          position: max(1, lineCount - 1), namedGridLine: StringWrapper())
      } else {
        // Set final position to span <line names - 1>
        finalPosition.setSpanPosition(
          position: max(1, lineCount - 1), namedGridLine: StringWrapper())
      }
    }
  }

  return (initialPosition, finalPosition)
}

private func lookAheadForNamedGridLine(
  start: Int32, numberOfLines: UInt32, linesCollection: NamedLineCollection
) -> Int32 {
  assert(numberOfLines != 0)

  // Only implicit lines on the search direction are assumed to have the given name, so we can start to look from first line.
  // See: https://drafts.csswg.org/css-grid/#grid-placement-span-int
  var end = max(start, 0)

  if !linesCollection.hasNamedLines() {
    return Int32(max(UInt32(end), linesCollection.lastLine() + 1) + numberOfLines - 1)
  }

  var numberOfLines = numberOfLines
  while numberOfLines != 0 {
    if end > linesCollection.lastLine() || linesCollection.contains(line: UInt32(end)) {
      numberOfLines -= 1
    }
    end += 1
  }

  assert(end != 0)
  return end - 1
}

private func lookBackForNamedGridLine(
  end: Int32, numberOfLines: UInt32, linesCollection: NamedLineCollection
) -> Int32 {
  assert(numberOfLines != 0)

  // Only implicit lines on the search direction are assumed to have the given name, so we can start to look from last line.
  // See: https://drafts.csswg.org/css-grid/#grid-placement-span-int
  var start = min(end, Int32(linesCollection.lastLine()))

  if !linesCollection.hasNamedLines() {
    return min(start, -1) - Int32(numberOfLines) + 1
  }

  var numberOfLines = numberOfLines
  while numberOfLines != 0 {
    if start < 0 || linesCollection.contains(line: UInt32(start)) {
      numberOfLines -= 1
    }
    start -= 1
  }

  return start + 1
}

private func resolveNamedGridLinePositionFromStyle(
  gridContainer: RenderGridWrapper, position: GridPosition, side: GridPositionSide
) -> Int32 {
  assert(!position.namedGridLine().isNull())

  let linesCollection = NamedLineCollection(
    initialGrid: gridContainer, name: position.namedGridLine(), side: side)

  if position.isPositive() {
    return lookAheadForNamedGridLine(
      start: 0, numberOfLines: UInt32(abs(position.integerPosition())),
      linesCollection: linesCollection)
  }
  return lookBackForNamedGridLine(
    end: Int32(linesCollection.lastLine()), numberOfLines: UInt32(abs(position.integerPosition())),
    linesCollection: linesCollection)
}

private func definiteGridSpanWithNamedLineSpanAgainstOpposite(
  oppositeLine: Int32, position: GridPosition, side: GridPositionSide,
  linesCollection: NamedLineCollection
) -> GridSpan {
  var start: Int32 = 0
  var end: Int32 = 0
  if side == .RowStartSide || side == .ColumnStartSide {
    start = lookBackForNamedGridLine(
      end: oppositeLine - 1, numberOfLines: UInt32(position.spanPosition()),
      linesCollection: linesCollection)
    end = oppositeLine
  } else {
    start = oppositeLine
    end = lookAheadForNamedGridLine(
      start: oppositeLine + 1, numberOfLines: UInt32(position.spanPosition()),
      linesCollection: linesCollection)
  }

  return GridSpan.untranslatedDefiniteGridSpan(startLine: start, endLine: end)
}

private func resolveNamedGridLinePositionAgainstOppositePosition(
  gridContainer: RenderGridWrapper, oppositeLine: Int32, position: GridPosition,
  side: GridPositionSide
) -> GridSpan {
  assert(position.isSpan())
  assert(!position.namedGridLine().isNull())
  // Negative positions are not allowed per the specification and should have been handled during parsing.
  assert(position.spanPosition() > 0)

  let linesCollection = NamedLineCollection(
    initialGrid: gridContainer, name: position.namedGridLine(), side: side)
  return definiteGridSpanWithNamedLineSpanAgainstOpposite(
    oppositeLine: oppositeLine, position: position, side: side, linesCollection: linesCollection)
}

private func resolveGridPositionAgainstOppositePosition(
  gridContainer: RenderGridWrapper, oppositeLine: Int32, position: GridPosition,
  side: GridPositionSide
) -> GridSpan {
  if position.isAuto() {
    if isStartSide(side: side) {
      return GridSpan.untranslatedDefiniteGridSpan(
        startLine: oppositeLine - 1, endLine: oppositeLine)
    }
    return GridSpan.untranslatedDefiniteGridSpan(startLine: oppositeLine, endLine: oppositeLine + 1)
  }

  assert(position.isSpan())
  assert(position.spanPosition() > 0)

  if !position.namedGridLine().isNull() {
    // span 2 'c' -> we need to find the appropriate grid line before / after our opposite position.
    return resolveNamedGridLinePositionAgainstOppositePosition(
      gridContainer: gridContainer, oppositeLine: oppositeLine, position: position, side: side)
  }

  // 'span 1' is contained inside a single grid track regardless of the direction.
  // That's why the CSS span value is one more than the offset we apply.
  let positionOffset = position.spanPosition()
  if isStartSide(side: side) {
    return GridSpan.untranslatedDefiniteGridSpan(
      startLine: oppositeLine - positionOffset, endLine: oppositeLine)
  }

  return GridSpan.untranslatedDefiniteGridSpan(
    startLine: oppositeLine, endLine: oppositeLine + positionOffset)
}

private func resolveGridPositionFromStyle(
  gridContainer: RenderGridWrapper, position: GridPosition, side: GridPositionSide
) -> Int32 {
  switch position.type {
  case .ExplicitPosition:
    assert(position.integerPosition() != 0)

    if !position.namedGridLine().isNull() {
      return resolveNamedGridLinePositionFromStyle(
        gridContainer: gridContainer, position: position, side: side)
    }

    // Handle <integer> explicit position.
    if position.isPositive() {
      return position.integerPosition() - 1
    }

    let resolvedPosition = abs(position.integerPosition()) - 1
    let endOfTrack = explicitGridSizeForSide(gridContainer: gridContainer, side: side)

    return Int32(endOfTrack) - resolvedPosition
  case .NamedGridAreaPosition:
    // First attempt to match the grid area's edge to a named grid area: if there is a named line with the name
    // ''<custom-ident>-start (for grid-*-start) / <custom-ident>-end'' (for grid-*-end), contributes the first such
    // line to the grid item's placement.
    let namedGridLine = position.namedGridLine()
    assert(!position.namedGridLine().isNull())

    let implicitLines = NamedLineCollection(
      initialGrid: gridContainer, name: namedGridLine, side: side, nameIsAreaName: true)
    if implicitLines.hasNamedLines() {
      return implicitLines.firstPosition()
    }

    // Otherwise, if there is a named line with the specified name, contributes the first such line to the grid
    // item's placement.
    let explicitLines = NamedLineCollection(
      initialGrid: gridContainer, name: namedGridLine, side: side)
    if explicitLines.hasNamedLines() {
      return explicitLines.firstPosition()
    }

    // If none of the above works specs mandate to assume that all the lines in the implicit grid have this name.
    return Int32(explicitGridSizeForSide(gridContainer: gridContainer, side: side) + 1)
  case .AutoPosition, .SpanPosition:
    fatalError("Not reached")
  }
}

// Class with all the code related to grid items positions resolution.
class GridPositionsResolver {
  private static func initialPositionSide(direction: GridTrackSizingDirection) -> GridPositionSide {
    return direction == .ForColumns ? .ColumnStartSide : .RowStartSide
  }

  private static func finalPositionSide(direction: GridTrackSizingDirection) -> GridPositionSide {
    return direction == .ForColumns ? .ColumnEndSide : .RowEndSide
  }

  static func spanSizeForAutoPlacedItem(
    gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
  ) -> UInt32 {
    let (initialPosition, finalPosition) = adjustGridPositionsFromStyle(
      gridItem: gridItem, direction: direction)

    // This method will only be used when both positions need to be resolved against the opposite one.
    assert(
      initialPosition.shouldBeResolvedAgainstOppositePosition()
        && finalPosition.shouldBeResolvedAgainstOppositePosition())

    if initialPosition.isAuto() && finalPosition.isAuto() {
      return 1
    }

    let position = initialPosition.isSpan() ? initialPosition : finalPosition
    assert(position.isSpan())

    assert(position.spanPosition() != 0)
    return UInt32(position.spanPosition())
  }

  static func resolveGridPositionsFromStyle(
    gridContainer: RenderGridWrapper, gridItem: RenderBoxWrapper,
    direction: GridTrackSizingDirection
  ) -> GridSpan {
    let (initialPosition, finalPosition) = adjustGridPositionsFromStyle(
      gridItem: gridItem, direction: direction)

    let initialSide = initialPositionSide(direction: direction)
    let finalSide = finalPositionSide(direction: direction)

    // We can't get our grid positions without running the auto placement algorithm.
    if initialPosition.shouldBeResolvedAgainstOppositePosition()
      && finalPosition.shouldBeResolvedAgainstOppositePosition()
    {
      return GridSpan.indefiniteGridSpan()
    }

    if initialPosition.shouldBeResolvedAgainstOppositePosition() {
      // Infer the position from the final position ('auto / 1' or 'span 2 / 3' case).
      let endLine = resolveGridPositionFromStyle(
        gridContainer: gridContainer, position: finalPosition, side: finalSide)
      return resolveGridPositionAgainstOppositePosition(
        gridContainer: gridContainer, oppositeLine: endLine, position: initialPosition,
        side: initialSide)
    }

    if finalPosition.shouldBeResolvedAgainstOppositePosition() {
      // Infer our position from the initial position ('1 / auto' or '3 / span 2' case).
      let startLine = resolveGridPositionFromStyle(
        gridContainer: gridContainer, position: initialPosition, side: initialSide)
      return resolveGridPositionAgainstOppositePosition(
        gridContainer: gridContainer, oppositeLine: startLine, position: finalPosition,
        side: finalSide)
    }

    var startLine = resolveGridPositionFromStyle(
      gridContainer: gridContainer, position: initialPosition, side: initialSide)
    var endLine = resolveGridPositionFromStyle(
      gridContainer: gridContainer, position: finalPosition, side: finalSide)

    if startLine > endLine {
      swap(&startLine, &endLine)
    } else if startLine == endLine {
      endLine = startLine + 1
    }

    return GridSpan.untranslatedDefiniteGridSpan(
      startLine: startLine, endLine: max(startLine, endLine))
  }

  static func explicitGridColumnCount(gridContainer: RenderGridWrapper) -> UInt32 {
    if gridContainer.isSubgridColumns() {
      let parent = gridContainer.parent() as! RenderGridWrapper
      let direction = GridLayoutFunctions.flowAwareDirectionForGridItem(
        grid: parent, gridItem: gridContainer, direction: .ForColumns)
      return parent.gridSpanForGridItem(gridItem: gridContainer, direction: direction).integerSpan()
    }
    return min(
      max(
        UInt32(gridContainer.style().gridColumnTrackSizes().count)
          + gridContainer.autoRepeatCountForDirection(direction: .ForColumns),
        UInt32(gridContainer.style().namedGridAreaColumnCount())), UInt32(GridPosition.max()))
  }

  static func explicitGridRowCount(gridContainer: RenderGridWrapper) -> UInt32 {
    if gridContainer.isSubgridRows() {
      let parent = gridContainer.parent() as! RenderGridWrapper
      let direction = GridLayoutFunctions.flowAwareDirectionForGridItem(
        grid: parent, gridItem: gridContainer, direction: .ForRows)
      return parent.gridSpanForGridItem(gridItem: gridContainer, direction: direction).integerSpan()
    }
    return min(
      max(
        UInt32(gridContainer.style().gridRowTrackSizes().count)
          + gridContainer.autoRepeatCountForDirection(direction: .ForRows),
        UInt32(gridContainer.style().namedGridAreaRowCount())), UInt32(GridPosition.max()))
  }
}
