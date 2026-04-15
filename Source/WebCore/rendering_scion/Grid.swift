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
    assert(maximumRowSize < GridPosition.max() * 2)
    assert(maximumColumnSize < GridPosition.max() * 2)
    let oldColumnSize = numTracks(direction: GridTrackSizingDirection.ForColumns)
    let oldRowSize = numTracks(direction: GridTrackSizingDirection.ForRows)
    if maximumRowSize > oldRowSize {
      grid.append(contentsOf: [[GridCell]](repeating: [], count: Int(maximumRowSize) - grid.count))
    }

    // Just grow the first row for now so that we know the requested size,
    // and we'll lazily allocate the others when they get used.
    if maximumColumnSize > oldColumnSize && maximumRowSize != 0 {
      grid[0].append(
        contentsOf: [GridCell](repeating: GridCell(), count: Int(maximumColumnSize) - grid[0].count)
      )
    }
  }

  @discardableResult
  func insert(gridItem: RenderBoxWrapper, area: GridArea) -> GridArea {
    var clampedArea = area
    if maxRows != 0 {
      clampedArea.rows.clamp(max: maxRows)
    }
    if maxColumns != 0 {
      clampedArea.columns.clamp(max: maxColumns)
    }

    assert(clampedArea.rows.isTranslatedDefinite() && clampedArea.columns.isTranslatedDefinite())
    ensureGridSize(
      maximumRowSize: clampedArea.rows.endLine(), maximumColumnSize: clampedArea.columns.endLine())

    for row in clampedArea.rows {
      ensureStorageForRow(row: row)
      for column in clampedArea.columns {
        grid[Int(row)][Int(column)].append(gridItem)
      }
    }

    setGridItemArea(item: gridItem, area: clampedArea)
    return clampedArea
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

  func gridItemSpanIgnoringCollapsedTracks(
    _ gridItem: RenderBoxWrapper, _ direction: GridTrackSizingDirection
  ) -> GridSpan {
    let span = gridItemSpan(gridItem: gridItem, direction: direction)
    if span.startLine() == 0 || !hasAutoRepeatEmptyTracks(direction: direction) {
      return span
    }
    var currentLine = span.startLine() - 1

    while currentLine > 0 && isEmptyAutoRepeatTrack(direction: direction, line: currentLine) {
      currentLine -= 1
    }
    if currentLine > 0 {
      return GridSpan.translatedDefiniteGridSpan(
        startLine: currentLine + 1, endLine: span.integerSpan())
    }

    // Still need to check if the first track is empty
    return isEmptyAutoRepeatTrack(direction: direction, line: currentLine)
      ? GridSpan.translatedDefiniteGridSpan(startLine: currentLine, endLine: span.integerSpan())
      : GridSpan.translatedDefiniteGridSpan(startLine: currentLine + 1, endLine: span.integerSpan())
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

  func clampAreaToSubgridIfNeeded(area: inout GridArea) {
    if !area.rows.isIndefinite() {
      if maxRows != 0 {
        area.rows.clamp(max: maxRows)
      }
    }
    if !area.columns.isIndefinite() {
      if maxColumns != 0 {
        area.columns.clamp(max: maxColumns)
      }
    }
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
    m_needsItemsPlacement = needsItemsPlacement

    if !needsItemsPlacement {
      // TODO(asuhan): shrink grid array to capacity.
      return
    }

    grid.removeAll()
    m_gridItemArea.removeAll()
    m_explicitRowStart = 0
    m_explicitColumnStart = 0
    m_autoRepeatEmptyColumns = nil
    m_autoRepeatEmptyRows = nil
    m_autoRepeatColumns = 0
    m_autoRepeatRows = 0
    maxColumns = 0
    maxRows = 0
  }

  func needsItemsPlacement() -> Bool { return m_needsItemsPlacement }

  func setupGridForMasonryLayout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func ensureStorageForRow(row: UInt32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let orderIterator: OrderIterator

  private var m_explicitColumnStart: UInt32 = 0
  private var m_explicitRowStart: UInt32 = 0

  private var m_autoRepeatColumns: UInt32 = 0
  private var m_autoRepeatRows: UInt32 = 0

  private var maxColumns: Int32 = 0
  private var maxRows: Int32 = 0

  private var m_needsItemsPlacement = true

  private var grid: GridAsMatrix = []

  private var m_gridItemArea: [UInt: GridArea] = [:]

  private var m_autoRepeatEmptyColumns: OrderedTrackIndexSet? = nil
  private var m_autoRepeatEmptyRows: OrderedTrackIndexSet? = nil
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

  static func createForSubgrid(
    _ subgrid: RenderGridWrapper, _ outer: GridIterator, _ subgridSpanInOuter: GridSpan
  ) -> GridIterator {
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

  let direction: GridTrackSizingDirection
}
