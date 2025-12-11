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

private func resolveGridPositionAgainstOppositePosition(
  gridContainer: RenderGridWrapper, oppositeLine: Int32, position: GridPosition,
  side: GridPositionSide
) -> GridSpan {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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
