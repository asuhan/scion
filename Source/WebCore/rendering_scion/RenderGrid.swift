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

private func cacheBaselineAlignedGridItems(
  grid: RenderGridWrapper, algorithm: GridTrackSizingAlgorithm, axes: UInt8,
  callback: (_: RenderBoxWrapper) -> Void,
  cachingRowSubgridsForRootGrid: Bool
) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private struct ContentAlignmentData {
  let positionOffset = LayoutUnit()
  let distributionOffset = LayoutUnit()
}

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

  // Required by GridTrackSizingAlgorithm. Keep them under control.
  private func guttersSize(
    direction: GridTrackSizingDirection, startLine: UInt32, span: UInt32, availableSize: LayoutUnit?
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func explicitIntrinsicInnerLogicalSize(direction: GridTrackSizingDirection) -> LayoutUnit?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateGridAreaLogicalSize(
    gridItem: RenderBoxWrapper, width: LayoutUnit?, height: LayoutUnit?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isBaselineAlignmentForGridItem(gridItem: RenderBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    return areMasonryRows() || areMasonryColumns()
  }

  func areMasonryRows() -> Bool {
    // isSubgridRows will return false if the masonry axis is rows. Need to check style if we are a subgrid
    if let parentGrid = parent() as? RenderGridWrapper, style().gridSubgridRows() {
      return parentGrid.areMasonryRows()
    }
    return style().gridMasonryRows()
  }

  // Masonry Spec Section 2
  // "If masonry is specified for both grid-template-columns and grid-template-rows, then the used value for grid-template-columns is none,
  // and thus the inline axis will be the grid axis."
  func areMasonryColumns() -> Bool {
    // isSubgridColumns will return false if the masonry axis is columns. Need to check style if we are a subgrid
    if let parentGrid = parent() as? RenderGridWrapper, style().gridSubgridColumns() {
      return parentGrid.areMasonryColumns()
    }
    return !areMasonryRows() && style().gridMasonryColumns()
  }

  func currentGrid() -> Grid {
    return grid!.currentGrid
  }

  private func numTracks(direction: GridTrackSizingDirection) -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func selfAlignmentNormalBehavior(gridItem: RenderBoxWrapper? = nil) -> ItemPosition {
    assert(gridItem != nil)
    return gridItem!.isRenderReplaced() ? .Start : .Stretch
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    var gridLayoutState = GridLayoutState()

    var gridItemMinWidth = LayoutUnit()
    var gridItemMaxWidth = LayoutUnit()
    var hadExcludedChildren = false
    if let (minWidth, maxWidth) = computePreferredWidthsForExcludedChildren() {
      gridItemMinWidth = minWidth
      gridItemMaxWidth = maxWidth
      hadExcludedChildren = true
    }

    let grid = Grid(grid: self)
    self.grid!.currentGrid = grid
    let algorithm = GridTrackSizingAlgorithm(renderGrid: self, grid: grid)
    placeItemsOnGrid(availableLogicalWidth: nil)

    performPreLayoutForGridItems(algorithm: algorithm, shouldUpdateGridAreaLogicalSize: .No)

    if baselineItemsCached {
      algorithm.copyBaselineItemsCache(source: trackSizingAlgorithm!, axis: .GridRowAxis)
    } else {
      cacheBaselineAlignedGridItems(
        grid: self, algorithm: algorithm, axes: GridAxis.GridRowAxis.rawValue,
        callback: { (_: RenderBoxWrapper) in return },
        cachingRowSubgridsForRootGrid: !isSubgridRows())
    }

    (minLogicalWidth, maxLogicalWidth) = computeTrackSizesForIndefiniteSize(
      algorithm: algorithm, direction: .ForColumns, gridLayoutState: &gridLayoutState,
      computeIntrinsicSizes: true)!

    self.grid!.resetCurrentGrid()

    if hadExcludedChildren {
      minLogicalWidth = max(minLogicalWidth, gridItemMinWidth)
      maxLogicalWidth = max(maxLogicalWidth, gridItemMaxWidth)
    }

    let scrollbarWidth = intrinsicScrollbarLogicalWidthIncludingGutter()
    minLogicalWidth += scrollbarWidth
    maxLogicalWidth += scrollbarWidth
  }

  private enum ShouldUpdateGridAreaLogicalSize {
    case No
    case Yes
  }

  private func performPreLayoutForGridItems(
    algorithm: GridTrackSizingAlgorithm,
    shouldUpdateGridAreaLogicalSize: ShouldUpdateGridAreaLogicalSize
  ) {
    assert(!algorithm.grid.needsItemsPlacement())
    // FIXME: We need a way when we are calling this during intrinsic size computation before performing
    // the layout. Maybe using the PreLayout phase?
    var gridItem = firstChildBox()
    while gridItem != nil {
      if gridItem!.isOutOfFlowPositioned() {
        gridItem = gridItem!.nextSiblingBox()
        continue
      }
      // Orthogonal items should be laid out in order to properly compute content-sized tracks that may depend on item's intrinsic size.
      // We also need to properly estimate its grid area size, since it may affect to the baseline shims if such item participates in baseline alignment.
      if GridLayoutFunctions.isOrthogonalGridItem(grid: self, gridItem: gridItem!) {
        updateGridAreaLogicalSize(
          gridItem: gridItem!,
          width: algorithm.estimatedGridAreaBreadthForGridItem(
            gridItem: gridItem!, direction: .ForColumns),
          height: algorithm.estimatedGridAreaBreadthForGridItem(
            gridItem: gridItem!, direction: .ForRows))
        gridItem!.layoutIfNeeded()
        gridItem = gridItem!.nextSiblingBox()
        continue
      }
      // We need to layout the item to know whether it must synthesize its
      // baseline or not, which may imply a cyclic sizing dependency.
      // FIXME: Can we avoid it ?
      // FIXME: We also want to layout baseline aligned items within subgrids, but
      // we don't currently have a way to do that here.
      if isBaselineAlignmentForGridItem(gridItem: gridItem!) {
        // FIXME: Hack to fix nested grid text size overflow during re-layouts.
        if shouldUpdateGridAreaLogicalSize == .Yes {
          updateGridAreaLogicalSize(
            gridItem: gridItem!,
            width: algorithm.estimatedGridAreaBreadthForGridItem(
              gridItem: gridItem!, direction: .ForColumns),
            height: algorithm.estimatedGridAreaBreadthForGridItem(
              gridItem: gridItem!, direction: .ForRows))
        }
        gridItem!.layoutIfNeeded()
      }
      gridItem = gridItem!.nextSiblingBox()
    }
  }

  private func placeItemsOnGrid(availableLogicalWidth: LayoutUnit?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func canPerformSimplifiedLayout() -> Bool {
    // We cannot perform a simplified layout if we need to position the items and we have some
    // positioned items to be laid out.
    if currentGrid().needsItemsPlacement() && posChildNeedsLayout() {
      return false
    }

    return renderBlockCanPerformSimplifiedLayout()
  }

  private func computeTrackSizesForIndefiniteSize(
    algorithm: GridTrackSizingAlgorithm, direction: GridTrackSizingDirection,
    gridLayoutState: inout GridLayoutState, computeIntrinsicSizes: Bool = false
  ) -> (LayoutUnit, LayoutUnit)? {
    algorithm.run(
      direction: direction, numTracks: numTracks(direction: direction),
      sizingOperation: .IntrinsicSizeComputation, availableSpace: nil,
      gridLayoutState: &gridLayoutState)

    let numberOfTracks = UInt32(algorithm.tracks(direction: direction).count)
    let totalGuttersSize =
      direction == .ForColumns && explicitIntrinsicInnerLogicalSize(direction: direction) != nil
      ? LayoutUnit(value: UInt64(0))
      : guttersSize(direction: direction, startLine: 0, span: numberOfTracks, availableSize: nil)

    assert(algorithm.tracksAreWiderThanMinTrackBreadth())

    return computeIntrinsicSizes
      ? (
        algorithm.minContentSize + totalGuttersSize, algorithm.maxContentSize + totalGuttersSize
      ) : nil
  }

  override func allowedLayoutOverflow() -> LayoutOptionalOutsets {
    var allowance = allowedLayoutOverflowForBox()
    if offsetBetweenColumns.positionOffset < Int32(0) {
      allowance.setStart(
        start: -offsetBetweenColumns.positionOffset, writingMode: style().writingMode(),
        direction: style().direction())
    }

    if offsetBetweenRows.positionOffset < Int32(0) {
      if isHorizontalWritingMode() {
        allowance.top = -offsetBetweenRows.positionOffset
      } else {
        allowance.left = -offsetBetweenRows.positionOffset
      }
    }

    return allowance
  }

  override func computeOverflow(oldClientAfterEdge: LayoutUnit, recomputeFloats: Bool = false) {
    renderBlockComputeOverflow(
      oldClientAfterEdge: oldClientAfterEdge, recomputeFloats: recomputeFloats)

    if !hasPotentiallyScrollableOverflow() || isMasonry() || isSubgridRows() || isSubgridColumns() {
      return
    }

    // FIXME: We should handle RTL and other writing modes also.
    if style().direction() == .LTR && isHorizontalWritingMode() {
      var gridAreaSize = LayoutSizeWrapper(width: columnPositions.last!, height: rowPositions.last!)
      gridAreaSize += LayoutSizeWrapper(width: paddingEnd(), height: paddingAfter())
      addLayoutOverflow(rect: LayoutRectWrapper(location: LayoutPointWrapper(), size: gridAreaSize))
    }
  }

  override func firstLineBaseline() -> LayoutUnit? {
    if (isWritingModeRoot() && !isFlexItem()) || !currentGrid().hasGridItems()
      || shouldApplyLayoutContainment()
    {
      return nil
    }

    // Finding the first grid item in grid order.
    let baselineGridItem = getBaselineGridItem(alignment: .Baseline)

    if baselineGridItem == nil {
      return nil
    }

    if let baseline =
      GridLayoutFunctions.isOrthogonalGridItem(grid: self, gridItem: baselineGridItem!)
      ? nil : baselineGridItem!.firstLineBaseline()
    {
      return baseline + baselineGridItem!.logicalTop().toInt()
    }

    // We take border-box's bottom if no valid baseline.
    // FIXME: We should pass |direction| into firstLineBaseline and stop bailing out if we're a writing
    // mode root. This would also fix some cases where the grid is orthogonal to its container.
    let direction: LineDirectionMode = isHorizontalWritingMode() ? .HorizontalLine : .VerticalLine
    return synthesizedBaseline(
      box: baselineGridItem!, parentStyle: style(), direction: direction, edge: .BorderBox)
      + logicalTopForChild(child: baselineGridItem!)
  }

  override func lastLineBaseline() -> LayoutUnit? {
    if isWritingModeRoot() || !currentGrid().hasGridItems() || shouldApplyLayoutContainment() {
      return nil
    }

    let baselineGridItem = getBaselineGridItem(alignment: .LastBaseline)
    if baselineGridItem == nil {
      return nil
    }

    if let baseline =
      GridLayoutFunctions.isOrthogonalGridItem(grid: self, gridItem: baselineGridItem!)
      ? nil : baselineGridItem!.lastLineBaseline()
    {
      return baseline + baselineGridItem!.logicalTop().toInt()
    }

    let direction: LineDirectionMode = isHorizontalWritingMode() ? .HorizontalLine : .VerticalLine
    return synthesizedBaseline(
      box: baselineGridItem!, parentStyle: style(), direction: direction, edge: .BorderBox)
      + logicalTopForChild(child: baselineGridItem!)
  }

  private func getBaselineGridItem(alignment: ItemPosition) -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func establishesIndependentFormattingContext() -> Bool {
    // Grid items establish a new independent formatting context, unless
    // they're a subgrid
    // https://drafts.csswg.org/css-grid-2/#grid-item-display
    if isGridItem() {
      if !isSubgridRows() && !isSubgridColumns() {
        return true
      }
    }
    return renderElementEstablishesIndependentFormattingContext()
  }

  private class GridWrapper {
    init(renderGrid: RenderGridWrapper) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func resetCurrentGrid() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private let layoutGrid: Grid
    var currentGrid: Grid
  }

  private var grid: GridWrapper? = nil

  // FIXME: Refactor m_trackSizingAlgorithm to be inside of layoutGrid and layoutMasonry.
  // https://bugs.webkit.org/show_bug.cgi?id=277496
  private let trackSizingAlgorithm: GridTrackSizingAlgorithm? = nil

  private let columnPositions: [LayoutUnit] = []
  private let rowPositions: [LayoutUnit] = []

  private let offsetBetweenColumns = ContentAlignmentData()
  private let offsetBetweenRows = ContentAlignmentData()

  private var baselineItemsCached = false
}
