/*
 * Copyright (C) 2022 Apple Inc.
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

class GridMasonryLayout {
  init(renderGrid: RenderGridWrapper) {
    self.renderGrid = renderGrid
  }

  private func initializeMasonry(
    gridAxisTracks: UInt32, masonryAxisDirection: GridTrackSizingDirection
  ) {
    // Reset global variables as they may contain state from previous runs of Masonry.
    self.masonryAxisDirection = masonryAxisDirection
    self.masonryAxisGridGap = renderGrid.gridGap(direction: masonryAxisDirection)
    self.gridAxisTracksCount = gridAxisTracks
    self.gridContentSize = LayoutUnit(value: 0)

    allocateCapacityForMasonryVectors()
    collectMasonryItems()
    renderGrid.currentGrid().setupGridForMasonryLayout()
    renderGrid.populateExplicitGridAndOrderIterator()

    resizeAndResetRunningPositions()
  }

  func performMasonryPlacement(
    gridAxisTracks: UInt32, masonryAxisDirection: GridTrackSizingDirection
  ) {
    initializeMasonry(gridAxisTracks: gridAxisTracks, masonryAxisDirection: masonryAxisDirection)

    renderGrid.populateGridPositionsForDirection(direction: .ForColumns)
    renderGrid.populateGridPositionsForDirection(direction: .ForRows)

    // 2.3 Masonry Layout Algorithm
    // https://drafts.csswg.org/css-grid-3/#masonry-layout-algorithm

    // the insertIntoGridAndLayoutItem() will modify the m_autoFlowNextCursor, so m_autoFlowNextCursor needs to be reset.
    autoFlowNextCursor = 0

    if renderGrid.style().masonryAutoFlow().placementOrder == .Ordered {
      placeItemsUsingOrderModifiedDocumentOrder()
    } else {
      placeItemsWithDefiniteGridAxisPosition()
      placeItemsWithIndefiniteGridAxisPosition()
    }
  }

  func offsetForGridItem(gridItem: RenderBoxWrapper) -> LayoutUnit {
    if let offsetIter = itemOffsets[CPtrToInt(gridItem.p)] {
      return offsetIter
    }
    return LayoutUnit(value: UInt64(0))
  }

  private func gridAxisPositionUsingPackAutoFlow(item: RenderBoxWrapper) -> GridSpan {
    let itemSpanLength = GridPositionsResolver.spanSizeForAutoPlacedItem(
      gridItem: item, direction: gridAxisDirection())
    var smallestMaxPos = LayoutUnit.max()
    var smallestMaxPosLine: UInt32 = 0
    let gridAxisLines = gridAxisTracksCount + 1
    for startingLine in 0..<gridAxisLines - itemSpanLength {
      var maxPosForCurrentStartingLine = LayoutUnit()
      for lineOffset in 0..<itemSpanLength {
        maxPosForCurrentStartingLine = max(
          maxPosForCurrentStartingLine, runningPositions[Int(startingLine + lineOffset)])
      }
      if maxPosForCurrentStartingLine < smallestMaxPos {
        smallestMaxPos = maxPosForCurrentStartingLine
        smallestMaxPosLine = startingLine
      }
    }
    return GridSpan.translatedDefiniteGridSpan(
      startLine: Int32(smallestMaxPosLine), endLine: Int32(smallestMaxPosLine + itemSpanLength))
  }

  private func gridAxisPositionUsingNextAutoFlow(item: RenderBoxWrapper) -> GridSpan {
    let itemSpanLength = GridPositionsResolver.spanSizeForAutoPlacedItem(
      gridItem: item, direction: gridAxisDirection())
    if !hasEnoughSpaceAtPosition(startingPosition: autoFlowNextCursor, spanLength: itemSpanLength) {
      autoFlowNextCursor = 0
    }
    return GridSpan.translatedDefiniteGridSpan(
      startLine: Int32(autoFlowNextCursor), endLine: Int32(autoFlowNextCursor + itemSpanLength))
  }

  private func gridAreaForIndefiniteGridAxisItem(item: RenderBoxWrapper) -> GridArea {
    // Determine the logic to use for positioning based on the value of masonry-auto-flow
    let gridAxisPosition =
      renderGrid.style().masonryAutoFlow().placementAlgorithm == .Pack
      ? gridAxisPositionUsingPackAutoFlow(item: item)
      : gridAxisPositionUsingNextAutoFlow(item: item)
    return masonryGridAreaFromGridAxisSpan(gridAxisSpan: gridAxisPosition)
  }

  private func gridAreaForDefiniteGridAxisItem(gridItem: RenderBoxWrapper) -> GridArea {
    let itemSpan = renderGrid.currentGrid().gridItemSpan(
      gridItem: gridItem, direction: gridAxisDirection())
    assert(!itemSpan.isIndefinite())
    itemSpan.translate(
      offset: renderGrid.currentGrid().explicitGridStart(direction: gridAxisDirection()))
    return masonryGridAreaFromGridAxisSpan(gridAxisSpan: itemSpan)
  }

  private func collectMasonryItems() {
    assert(gridAxisTracksCount != 0)

    itemsWithDefiniteGridAxisPosition.removeAll()
    itemsWithIndefiniteGridAxisPosition.removeAll()

    let grid = renderGrid.currentGrid()
    var gridItem = grid.orderIterator.first()
    while gridItem != nil {
      if grid.orderIterator.shouldSkipChild(child: gridItem!) {
        gridItem = grid.orderIterator.next()
        continue
      }

      if renderGrid.style().masonryAutoFlow().placementOrder == .Ordered {
        itemsWithDefiniteGridAxisPosition.append(gridItem!)
      } else if renderGrid.style().masonryAutoFlow().placementOrder == .DefiniteFirst {
        if hasDefiniteGridAxisPosition(gridItem: gridItem!, gridAxisDirection: gridAxisDirection())
        {
          itemsWithDefiniteGridAxisPosition.append(gridItem!)
        } else {
          itemsWithIndefiniteGridAxisPosition.append(gridItem!)
        }
      }
      gridItem = grid.orderIterator.next()
    }
  }

  private func placeItemsUsingOrderModifiedDocumentOrder() {
    for gridItem in itemsWithDefiniteGridAxisPosition {
      if hasDefiniteGridAxisPosition(gridItem: gridItem, gridAxisDirection: gridAxisDirection()) {
        insertIntoGridAndLayoutItem(
          gridItem: gridItem, area: gridAreaForDefiniteGridAxisItem(gridItem: gridItem))
      } else {
        insertIntoGridAndLayoutItem(
          gridItem: gridItem, area: gridAreaForIndefiniteGridAxisItem(item: gridItem))
      }
    }
  }

  private func placeItemsWithDefiniteGridAxisPosition() {
    for item in itemsWithDefiniteGridAxisPosition {
      let itemSpan = renderGrid.currentGrid().gridItemSpan(
        gridItem: item, direction: gridAxisDirection())

      assert(!itemSpan.isIndefinite())

      itemSpan.translate(
        offset: renderGrid.currentGrid().explicitGridStart(direction: gridAxisDirection()))
      let gridArea = gridAreaForDefiniteGridAxisItem(gridItem: item)
      renderGrid.currentGrid().clampAreaToSubgridIfNeeded(area: gridArea)
      insertIntoGridAndLayoutItem(gridItem: item, area: gridArea)
    }
  }

  private func placeItemsWithIndefiniteGridAxisPosition() {
    for item in itemsWithIndefiniteGridAxisPosition {
      insertIntoGridAndLayoutItem(
        gridItem: item, area: gridAreaForIndefiniteGridAxisItem(item: item))
    }
  }

  private func setItemGridAxisContainingBlockToGridArea(gridItem: RenderBoxWrapper) {
    if gridAxisDirection() == .ForColumns {
      gridItem.setOverridingContainingBlockContentLogicalWidth(
        logicalWidth: renderGrid.trackSizingAlgorithm!.gridAreaBreadthForGridItem(
          gridItem: gridItem, direction: .ForColumns))
    } else {
      gridItem.setOverridingContainingBlockContentLogicalHeight(
        logicalHeight: renderGrid.trackSizingAlgorithm!.gridAreaBreadthForGridItem(
          gridItem: gridItem, direction: .ForRows))
    }

    // FIXME(249230): Try to cache masonry layout sizes
    gridItem.setChildNeedsLayout(markParents: .MarkOnlyThis)
  }

  private func insertIntoGridAndLayoutItem(gridItem: RenderBoxWrapper, area: GridArea) {
    renderGrid.currentGrid().insert(gridItem: gridItem, area: area)
    setItemGridAxisContainingBlockToGridArea(gridItem: gridItem)
    gridItem.layoutIfNeeded()
    updateRunningPositions(gridItem: gridItem, area: area)
    autoFlowNextCursor = gridAxisSpanFromArea(gridArea: area).endLine() % gridAxisTracksCount
  }

  private func resizeAndResetRunningPositions() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func allocateCapacityForMasonryVectors() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func masonryAxisMarginBoxForItem(gridItem: RenderBoxWrapper) -> LayoutUnit {
    var marginBoxSize = LayoutUnit()
    if masonryAxisDirection == .ForRows {
      if GridLayoutFunctions.isOrthogonalGridItem(grid: renderGrid, gridItem: gridItem) {
        marginBoxSize =
          gridItem.isHorizontalWritingMode()
          ? gridItem.width() + gridItem.horizontalMarginExtent()
          : gridItem.height() + gridItem.verticalMarginExtent()
      } else {
        marginBoxSize = gridItem.logicalHeight() + gridItem.marginLogicalHeight()
      }
    } else {
      if GridLayoutFunctions.isOrthogonalGridItem(grid: renderGrid, gridItem: gridItem) {
        marginBoxSize =
          gridItem.isHorizontalWritingMode()
          ? gridItem.height() + gridItem.verticalMarginExtent()
          : gridItem.width() + gridItem.horizontalMarginExtent()
      } else {
        marginBoxSize = gridItem.logicalWidth() + gridItem.marginLogicalWidth()
      }
    }
    return marginBoxSize
  }

  private func updateRunningPositions(gridItem: RenderBoxWrapper, area: GridArea) {
    let gridAxisSpan = gridAxisSpanFromArea(gridArea: area)
    assert(
      gridAxisSpan.startLine() < runningPositions.count
        && gridAxisSpan.endLine() <= runningPositions.count)
    gridAxisSpan.clamp(max: Int32(runningPositions.count))

    var previousRunningPosition = LayoutUnit()
    for line in gridAxisSpan {
      previousRunningPosition = max(previousRunningPosition, runningPositions[Int(line)])
    }

    let newRunningPosition =
      masonryAxisMarginBoxForItem(gridItem: gridItem) + previousRunningPosition + masonryAxisGridGap
    gridContentSize = max(gridContentSize, newRunningPosition - masonryAxisGridGap)

    for span in gridAxisSpan {
      runningPositions[Int(span)] = max(runningPositions[Int(span)], newRunningPosition)
    }

    updateItemOffset(gridItem: gridItem, offset: previousRunningPosition)
  }

  private func updateItemOffset(gridItem: RenderBoxWrapper, offset: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func gridAxisDirection() -> GridTrackSizingDirection {
    // The masonry axis and grid axis can never be the same.
    // They are always perpendicular to each other.
    return masonryAxisDirection == .ForRows ? .ForColumns : .ForRows
  }

  private func hasDefiniteGridAxisPosition(
    gridItem: RenderBoxWrapper, gridAxisDirection: GridTrackSizingDirection
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func masonryGridAreaFromGridAxisSpan(gridAxisSpan: GridSpan) -> GridArea {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func gridAxisSpanFromArea(gridArea: GridArea) -> GridSpan {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func hasEnoughSpaceAtPosition(startingPosition: UInt32, spanLength: UInt32) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var gridAxisTracksCount: UInt32 = 0

  private var itemsWithDefiniteGridAxisPosition: [RenderBoxWrapper] = []
  private var itemsWithIndefiniteGridAxisPosition: [RenderBoxWrapper] = []

  private var runningPositions: [LayoutUnit] = []
  private let itemOffsets: [UInt: LayoutUnit] = [:]
  private let renderGrid: RenderGridWrapper
  private var masonryAxisGridGap = LayoutUnit()
  var gridContentSize = LayoutUnit()

  private var masonryAxisDirection: GridTrackSizingDirection = .ForColumns

  private var autoFlowNextCursor: UInt32 = 0
}
