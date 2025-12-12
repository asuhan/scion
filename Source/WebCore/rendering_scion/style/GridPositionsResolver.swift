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

class NamedLineCollectionBase {
  init(
    initialGrid: RenderGridWrapper, name: StringWrapper, side: GridPositionSide,
    nameIsAreaName: Bool
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasNamedLines() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func contains(line: UInt32) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

class NamedLineCollection: NamedLineCollectionBase {
  override init(
    initialGrid: RenderGridWrapper, name: StringWrapper, side: GridPositionSide,
    nameIsAreaName: Bool = false
  ) {
    super.init(initialGrid: initialGrid, name: name, side: side, nameIsAreaName: nameIsAreaName)
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastLine() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

private func isStartSide(side: GridPositionSide) -> Bool {
  return side == .ColumnStartSide || side == .RowStartSide
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
  let finalPosition =
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
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func explicitGridRowCount(gridContainer: RenderGridWrapper) -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
