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
  grid: RenderGridWrapper, algorithm: GridTrackSizingAlgorithm, axes: GridAxis,
  callback: (_: RenderBoxWrapper) -> Void,
  cachingRowSubgridsForRootGrid: Bool
) {
  if cachingRowSubgridsForRootGrid {
    assert(
      !algorithm.renderGrid!.isSubgridRows()
        && (CPtrToInt(algorithm.renderGrid?.p) == CPtrToInt(grid.p)
          || grid.isSubgridOf(
            direction: GridLayoutFunctions.flowAwareDirectionForGridItem(
              grid: algorithm.renderGrid!, gridItem: grid, direction: .ForRows),
            ancestor: algorithm.renderGrid!))
    )
  }

  var gridItem = grid.firstChildBox()
  while gridItem != nil {
    if gridItem!.isOutOfFlowPositioned() || gridItem!.isLegend() {
      gridItem = gridItem!.nextSiblingBox()
      continue
    }

    callback(gridItem!)

    // We keep a cache of items with baseline as alignment values so that we only compute the baseline shims for
    // such items. This cache is needed for performance related reasons due to the cost of evaluating the item's
    // participation in a baseline context during the track sizing algorithm.
    var innerAxes: GridAxis = []
    let inner = gridItem as? RenderGridWrapper

    if axes.contains(.GridColumnAxis) {
      if inner != nil && inner!.isSubgridInParentDirection(parentDirection: .ForRows) {
        innerAxes.update(
          with: GridLayoutFunctions.isOrthogonalGridItem(grid: grid, gridItem: gridItem!)
            ? .GridRowAxis : .GridColumnAxis)
      } else if grid.isBaselineAlignmentForGridItem(
        gridItem: gridItem!, baselineAxis: .GridColumnAxis)
      {
        algorithm.cacheBaselineAlignedItem(
          item: gridItem!, axis: .GridColumnAxis,
          cachingRowSubgridsForRootGrid: cachingRowSubgridsForRootGrid)
      }
    }

    if axes.contains(.GridRowAxis) {
      if inner != nil && inner!.isSubgridInParentDirection(parentDirection: .ForColumns) {
        innerAxes.update(
          with: GridLayoutFunctions.isOrthogonalGridItem(grid: grid, gridItem: gridItem!)
            ? .GridColumnAxis : .GridRowAxis)
      } else if grid.isBaselineAlignmentForGridItem(
        gridItem: gridItem!, baselineAxis: .GridRowAxis)
      {
        algorithm.cacheBaselineAlignedItem(
          item: gridItem!, axis: .GridRowAxis,
          cachingRowSubgridsForRootGrid: cachingRowSubgridsForRootGrid)
      }
    }

    var cachingRowSubgridsForRootGrid = cachingRowSubgridsForRootGrid
    if inner != nil && cachingRowSubgridsForRootGrid {
      cachingRowSubgridsForRootGrid =
        GridLayoutFunctions.isOrthogonalGridItem(grid: algorithm.renderGrid!, gridItem: inner!)
        ? inner!.isSubgridColumns() : inner!.isSubgridRows()
    }

    if !innerAxes.isEmpty {
      cacheBaselineAlignedGridItems(
        grid: inner!, algorithm: algorithm, axes: innerAxes, callback: callback,
        cachingRowSubgridsForRootGrid: cachingRowSubgridsForRootGrid)
    }

    gridItem = gridItem!.nextSiblingBox()
  }
}

private func overrideSizeChanged(
  gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection, width: LayoutUnit?,
  height: LayoutUnit?
) -> Bool {
  if direction == .ForColumns {
    if let overridingContainingBlockContentLogicalWidth =
      gridItem.overridingContainingBlockContentLogicalWidth()
    {
      return overridingContainingBlockContentLogicalWidth != width
    }
    return true
  }
  if let overridingContainingBlockContentLogicalHeight =
    gridItem.overridingContainingBlockContentLogicalHeight()
  {
    return overridingContainingBlockContentLogicalHeight != height
  }
  return true
}

private func hasRelativeBlockAxisSize(grid: RenderGridWrapper, gridItem: RenderBoxWrapper) -> Bool {
  return GridLayoutFunctions.isOrthogonalGridItem(grid: grid, gridItem: gridItem)
    ? gridItem.hasRelativeLogicalWidth() || gridItem.style().logicalWidth().isAuto()
    : gridItem.hasRelativeLogicalHeight()
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

  override func avoidsFloats() -> Bool { return true }

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
    if span <= 1 {
      return LayoutUnit()
    }

    let gap = gridGap(direction: direction, availableSize: availableSize)

    // Fast path, no collapsing tracks.
    if !currentGrid().hasAutoRepeatEmptyTracks(direction: direction) {
      return gap * (span - 1)
    }

    // If there are collapsing tracks we need to be sure that gutters are properly collapsed. Apart
    // from that, if we have a collapsed track in the edges of the span we're considering, we need
    // to move forward (or backwards) in order to know whether the collapsed tracks reach the end of
    // the grid (so the gap becomes 0) or there is a non empty track before that.

    var gapAccumulator = LayoutUnit()
    let endLine = startLine + span

    for line in startLine..<endLine - 1 {
      if !currentGrid().isEmptyAutoRepeatTrack(direction: direction, line: line) {
        gapAccumulator += gap
      }
    }

    // The above loop adds one extra gap for trailing collapsed tracks.
    if gapAccumulator.bool()
      && currentGrid().isEmptyAutoRepeatTrack(direction: direction, line: endLine - 1)
    {
      assert(gapAccumulator >= gap)
      gapAccumulator -= gap
    }

    // If the startLine is the start line of a collapsed track we need to go backwards till we reach
    // a non collapsed track. If we find a non collapsed track we need to add that gap.
    var nonEmptyTracksBeforeStartLine: UInt32 = 0
    if startLine != 0 && currentGrid().isEmptyAutoRepeatTrack(direction: direction, line: startLine)
    {
      nonEmptyTracksBeforeStartLine = startLine
      let emptyTracksIndices = currentGrid().autoRepeatEmptyTracks(direction: direction)
      for trackIndex in emptyTracksIndices {
        if trackIndex == startLine {
          break
        }
        assert(nonEmptyTracksBeforeStartLine != 0)
        nonEmptyTracksBeforeStartLine -= 1
      }
      if nonEmptyTracksBeforeStartLine != 0 {
        gapAccumulator += gap
      }
    }

    // If the endLine is the end line of a collapsed track we need to go forward till we reach a non
    // collapsed track. If we find a non collapsed track we need to add that gap.
    if currentGrid().isEmptyAutoRepeatTrack(direction: direction, line: endLine - 1) {
      var nonEmptyTracksAfterEndLine = currentGrid().numTracks(direction: direction) - endLine
      let currentEmptyTrack = currentGrid().autoRepeatEmptyTracks(direction: direction).find(
        value: UInt64(endLine - 1))
      let endEmptyTrack = currentGrid().autoRepeatEmptyTracks(direction: direction).end()
      // Hash set iterators do not implement operator- so we have to manually iterate to know the number of remaining empty tracks.
      let it = ++currentEmptyTrack
      while it != endEmptyTrack {
        assert(nonEmptyTracksAfterEndLine >= 1)
        nonEmptyTracksAfterEndLine -= 1
        ++it
      }
      if nonEmptyTracksAfterEndLine != 0 {
        // We shouldn't count the gap twice if the span starts and ends in a collapsed track between two non-empty tracks.
        if nonEmptyTracksBeforeStartLine == 0 {
          gapAccumulator += gap
        }
      } else if nonEmptyTracksBeforeStartLine != 0 {
        // We shouldn't count the gap if the span starts and ends in a collapsed but there isn't non-empty tracks afterwards (it's at the end of the grid).
        gapAccumulator -= gap
      }
    }

    return gapAccumulator
  }

  private func explicitIntrinsicInnerLogicalSize(direction: GridTrackSizingDirection) -> LayoutUnit?
  {
    if !shouldCheckExplicitIntrinsicInnerLogicalSize(direction: direction) {
      return nil
    }
    if direction == .ForColumns {
      return explicitIntrinsicInnerLogicalWidth()
    }
    return explicitIntrinsicInnerLogicalHeight()
  }

  private func updateGridAreaLogicalSize(
    gridItem: RenderBoxWrapper, width: LayoutUnit?, height: LayoutUnit?
  ) {
    // Because the grid area cannot be styled, we don't need to adjust
    // the grid breadth to account for 'box-sizing'.
    let gridAreaWidthChanged = overrideSizeChanged(
      gridItem: gridItem, direction: .ForColumns, width: width, height: height)
    let gridAreaHeightChanged = overrideSizeChanged(
      gridItem: gridItem, direction: .ForRows, width: width, height: height)
    if gridAreaWidthChanged
      || (gridAreaHeightChanged && hasRelativeBlockAxisSize(grid: self, gridItem: gridItem))
    {
      gridItem.setNeedsLayout(markParents: .MarkOnlyThis)
    }

    gridItem.setOverridingContainingBlockContentLogicalWidth(logicalWidth: width)
    gridItem.setOverridingContainingBlockContentLogicalHeight(logicalHeight: height)
  }

  func isBaselineAlignmentForGridItem(gridItem: RenderBoxWrapper) -> Bool {
    return isBaselineAlignmentForGridItem(gridItem: gridItem, baselineAxis: .GridRowAxis)
      || isBaselineAlignmentForGridItem(gridItem: gridItem, baselineAxis: .GridColumnAxis)
  }

  func isBaselineAlignmentForGridItem(
    gridItem: RenderBoxWrapper, baselineAxis: GridAxis, allowed: AllowedBaseLine = .BothLines
  ) -> Bool {
    if gridItem.isOutOfFlowPositioned() {
      return false
    }
    let align = selfAlignmentForGridItem(axis: baselineAxis, gridItem: gridItem).position
    let hasAutoMargins =
      baselineAxis == .GridColumnAxis
      ? hasAutoMarginsInColumnAxis(gridItem: gridItem) : hasAutoMarginsInRowAxis(gridItem: gridItem)
    let isBaseline =
      allowed == .FirstLine
      ? isFirstBaselinePosition(position: align) : isBaselinePosition(position: align)
    return isBaseline && !hasAutoMargins
  }

  private func selfAlignmentForGridItem(
    axis: GridAxis, gridItem: RenderBoxWrapper, gridStyle: RenderStyleWrapper? = nil
  ) -> StyleSelfAlignmentData {
    return axis == .GridRowAxis
      ? justifySelfForGridItem(gridItem: gridItem, stretchingMode: .Any, gridStyle: gridStyle)
      : alignSelfForGridItem(gridItem: gridItem, stretchingMode: .Any, gridStyle: gridStyle)
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

  // Returns true if this grid is inheriting subgridded tracks for
  // the given direction from the specified ancestor. This handles
  // nested subgrids, where ancestor may not be our direct parent.
  func isSubgridOf(direction: GridTrackSizingDirection, ancestor: RenderGridWrapper) -> Bool {
    if !isSubgrid(direction: direction) {
      return false
    }
    if CPtrToInt(parent()?.p) == CPtrToInt(ancestor.p) {
      return true
    }

    let parentGrid = parent() as! RenderGridWrapper
    let parentDirection = GridLayoutFunctions.flowAwareDirectionForParent(
      grid: parentGrid, parent: self, direction: direction)
    return parentGrid.isSubgridOf(direction: parentDirection, ancestor: ancestor)
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
    // Due to limitations in our internal representation, we cannot know the number of columns from
    // currentGrid *if* there is no row (because currentGrid would be empty). That's why in that case we need
    // to get it from the style. Note that we know for sure that there aren't any implicit tracks,
    // because not having rows implies that there are no "normal" grid items (out-of-flow grid items are
    // not stored in currentGrid).
    assert(!currentGrid().needsItemsPlacement())
    if direction == .ForRows {
      return currentGrid().numTracks(direction: .ForRows)
    }

    // FIXME: This still requires knowledge about currentGrid internals.
    return currentGrid().numTracks(direction: .ForRows) != 0
      ? currentGrid().numTracks(direction: .ForColumns)
      : GridPositionsResolver.explicitGridColumnCount(gridContainer: self)
  }

  // This method optimizes the gutters computation by skipping the available size
  // call if gaps are fixed size (it's only needed for percentages).
  private func availableSpaceForGutters(direction: GridTrackSizingDirection) -> LayoutUnit? {
    let isRowAxis = direction == .ForColumns
    let gapLength = isRowAxis ? style().columnGap() : style().rowGap()
    if gapLength.isNormal || !gapLength.length.isPercentOrCalculated() {
      return nil
    }

    return isRowAxis ? availableLogicalWidth() : contentLogicalHeight()
  }

  private func gridGap(direction: GridTrackSizingDirection) -> LayoutUnit {
    return gridGap(
      direction: direction, availableSize: availableSpaceForGutters(direction: direction))
  }

  private func gridGap(direction: GridTrackSizingDirection, availableSize: LayoutUnit?)
    -> LayoutUnit
  {
    assert(availableSize != nil || availableSize! >= Int32(0))
    let gapLength = direction == .ForColumns ? style().columnGap() : style().rowGap()
    if gapLength.isNormal {
      if !isSubgrid(direction: direction) {
        return LayoutUnit(value: UInt64(0))
      }

      let parentDirection = GridLayoutFunctions.flowAwareDirectionForParent(
        grid: self, parent: parent()!, direction: direction)
      if availableSize == nil {
        return (parent() as! RenderGridWrapper).gridGap(
          direction: parentDirection, availableSize: nil)
      }
      return (parent() as! RenderGridWrapper).gridGap(direction: parentDirection)
    }

    return valueForLength(
      length: gapLength.length, maximumValue: availableSize ?? LayoutUnit(value: 0))
  }

  private func shouldCheckExplicitIntrinsicInnerLogicalSize(direction: GridTrackSizingDirection)
    -> Bool
  {
    return direction == .ForColumns
      ? shouldApplySizeOrInlineSizeContainment() : shouldApplySizeContainment()
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
        grid: self, algorithm: algorithm, axes: .GridRowAxis,
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

  private func justifySelfForGridItem(
    gridItem: RenderBoxWrapper, stretchingMode: StretchingMode = .Any,
    gridStyle: RenderStyleWrapper? = nil
  ) -> StyleSelfAlignmentData {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func alignSelfForGridItem(
    gridItem: RenderBoxWrapper, stretchingMode: StretchingMode = .Any,
    gridStyle: RenderStyleWrapper? = nil
  ) -> StyleSelfAlignmentData {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME: This logic is shared by RenderFlexibleBox, so it should be moved to RenderBox.
  private func hasAutoMarginsInColumnAxis(gridItem: RenderBoxWrapper) -> Bool {
    if isHorizontalWritingMode() {
      return gridItem.style().marginTop().isAuto() || gridItem.style().marginBottom().isAuto()
    }
    return gridItem.style().marginLeft().isAuto() || gridItem.style().marginRight().isAuto()
  }

  // FIXME: This logic is shared by RenderFlexibleBox, so it should be moved to RenderBox.
  private func hasAutoMarginsInRowAxis(gridItem: RenderBoxWrapper) -> Bool {
    if isHorizontalWritingMode() {
      return gridItem.style().marginLeft().isAuto() || gridItem.style().marginRight().isAuto()
    }
    return gridItem.style().marginTop().isAuto() || gridItem.style().marginBottom().isAuto()
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
