/*
 * Copyright (C) 2011, 2022 Apple Inc. All rights reserved.
 * Copyright (C) 2013-2017 Igalia S.L.
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

final class RenderGridWrapper: RenderBlockWrapper {
  override func layoutBlock(
    relayoutChildren: Bool, pageLogicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) {
    assert(needsLayout())

    if !relayoutChildren && simplifiedLayout() {
      return
    }

    // The layoutBlock was handling the layout of both the grid and masonry implementations.
    // This caused a huge amount of branching code to handle masonry specific cases. Splitting up the code
    // to layout will simplify both implementations.
    if !isMasonry() {
      layoutGrid(relayoutChildren: relayoutChildren)
    } else {
      layoutMasonry(relayoutChildren: relayoutChildren)
    }
  }

  override func avoidsFloats() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func dirtyGrid(subgridChanged: Bool = false) {
    if currentGrid().needsItemsPlacement() {
      return
    }

    currentGrid().setNeedsItemsPlacement(needsItemsPlacement: true)

    var subgridChanged = subgridChanged
    var currentChild: RenderGridWrapper? = self
    while currentChild != nil
      && (subgridChanged || currentChild!.isSubgridRows() || currentChild!.isSubgridColumns())
    {
      currentChild = currentChild!.parent() as? RenderGridWrapper
      if currentChild != nil {
        currentChild!.currentGrid().setNeedsItemsPlacement(needsItemsPlacement: true)
      }
      subgridChanged = false
    }
  }

  // These functions handle the actual implementation of layoutBlock based on if
  // the grid is a standard grid or a masonry one. While masonry is an extension of grid,
  // keeping the logic in the same function was leading to a messy amount of if statements being added to handle
  // specific masonry cases.
  func layoutGrid(relayoutChildren: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layoutMasonry(relayoutChildren: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isSubgrid(direction: GridTrackSizingDirection) -> Bool {
    // If the grid container is forced to establish an independent formatting
    // context (like contain layout, or position:absolute), then the used value
    // of grid-template-rows/columns is 'none' and the container is not a subgrid.
    // https://drafts.csswg.org/css-grid-2/#subgrid-listing
    if renderElementEstablishesIndependentFormattingContext() {
      return false
    }
    if direction == .ForColumns ? !style().gridSubgridColumns() : !style().gridSubgridRows() {
      return false
    }
    if let renderGrid = parent() as? RenderGridWrapper {
      return direction == .ForRows ? !renderGrid.areMasonryRows() : !renderGrid.areMasonryColumns()
    }
    return false
  }

  func isSubgridRows() -> Bool {
    return isSubgrid(direction: .ForRows)
  }

  func isSubgridColumns() -> Bool {
    return isSubgrid(direction: .ForColumns)
  }

  func isSubgridInParentDirection(parentDirection: GridTrackSizingDirection) -> Bool {
    if let renderGrid = parent() as? RenderGridWrapper {
      let direction = GridLayoutFunctions.flowAwareDirectionForGridItem(
        grid: renderGrid, gridItem: self, direction: parentDirection)
      return isSubgrid(direction: direction)
    }
    return false
  }

  func isMasonry() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func areMasonryRows() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func areMasonryColumns() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func currentGrid() -> Grid {
    return grid!.currentGrid
  }

  override func selfAlignmentNormalBehavior(gridItem: RenderBoxWrapper? = nil) -> ItemPosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func canPerformSimplifiedLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func allowedLayoutOverflow() -> LayoutOptionalOutsets {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeOverflow(oldClientAfterEdge: LayoutUnit, recomputeFloats: Bool = false) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func firstLineBaseline() -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func lastLineBaseline() -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func establishesIndependentFormattingContext() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private class GridWrapper {
    init(renderGrid: RenderGridWrapper) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private let layoutGrid: Grid
    let currentGrid: Grid
  }

  private let grid: GridWrapper? = nil
}
