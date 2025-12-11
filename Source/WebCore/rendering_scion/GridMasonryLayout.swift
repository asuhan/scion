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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func placeItemsWithIndefiniteGridAxisPosition() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func insertIntoGridAndLayoutItem(gridItem: RenderBoxWrapper, area: GridArea) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func resizeAndResetRunningPositions() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func allocateCapacityForMasonryVectors() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func gridAxisDirection() -> GridTrackSizingDirection {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
