/*
 * Copyright (C) 2017 Igalia S.L.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

typealias GridCell = [RenderBoxWrapper]
private typealias GridAsMatrix = [[GridCell]]
typealias OrderedTrackIndexSet = ListSet<UInt64, UInt64>

final class Grid {
  init(grid: RenderGridWrapper) {
    orderIterator = OrderIterator(containerBox: grid)
  }

  func numTracks(direction: GridTrackSizingDirection) -> UInt32 {
    if direction == .ForRows {
      return UInt32(grid.count)
    }
    return grid.isEmpty ? 0 : UInt32(grid[0].count)
  }

  func ensureGridSize(maximumRowSize: UInt32, maximumColumnSize: UInt32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func insert(gridItem: RenderBoxWrapper, area: GridArea) -> GridArea {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Note that each in flow child of a grid container becomes a grid item. This means that
  // this method will return false for a grid container with only out of flow children.
  func hasGridItems() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridItemArea(item: RenderBoxWrapper) -> GridArea {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setGridItemArea(item: RenderBoxWrapper, area: GridArea) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridItemSpan(gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection) -> GridSpan {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func cell(row: UInt32, column: UInt32) -> GridCell {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func explicitGridStart(direction: GridTrackSizingDirection) -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func autoRepeatTracks(direction: GridTrackSizingDirection) -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setAutoRepeatTracks(autoRepeatRows: UInt32, autoRepeatColumns: UInt32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setClampingForSubgrid(maxRows: UInt32, maxColumns: UInt32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setExplicitGridStart(rowStart: UInt32, columnStart: UInt32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clampAreaToSubgridIfNeeded(area: GridArea) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setAutoRepeatEmptyColumns(autoRepeatEmptyColumns: OrderedTrackIndexSet?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setAutoRepeatEmptyRows(autoRepeatEmptyRows: OrderedTrackIndexSet?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAutoRepeatEmptyTracks(direction: GridTrackSizingDirection) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isEmptyAutoRepeatTrack(direction: GridTrackSizingDirection, line: UInt32) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func autoRepeatEmptyTracks(direction: GridTrackSizingDirection) -> OrderedTrackIndexSet {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNeedsItemsPlacement(needsItemsPlacement: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func needsItemsPlacement() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setupGridForMasonryLayout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let orderIterator: OrderIterator

  private let grid: GridAsMatrix = []
}

class GridIterator {
  // |direction| is the direction that is fixed to |fixedTrackIndex| so e.g
  // GridIterator(m_grid, ForColumns, 1) will walk over the rows of the 2nd column.
  init(
    grid: Grid, direction: GridTrackSizingDirection, fixedTrackIndex: UInt32,
    varyingTrackIndex: UInt32 = 0
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextGridItem() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextEmptyGridArea(fixedTrackSpan: UInt32, varyingTrackSpan: UInt32) -> GridArea? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
