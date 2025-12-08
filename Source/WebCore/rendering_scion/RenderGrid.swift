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

private func max(_ a: LayoutUnit?, _ b: LayoutUnit?) -> LayoutUnit? { return a < b ? b : a }

private func < (a: LayoutUnit?, b: LayoutUnit?) -> Bool { return b != nil && (a == nil || a! < b!) }

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

@discardableResult
private func insertIntoGrid(grid: Grid, gridItem: RenderBoxWrapper, area: GridArea) -> GridArea {
  let clamped = grid.insert(gridItem: gridItem, area: area)

  if let renderGrid = gridItem as? RenderGridWrapper {
    if renderGrid.isSubgridRows() || renderGrid.isSubgridColumns() {
      renderGrid.placeItems()
    }
    return clamped
  }

  return clamped
}

private let contentAlignmentNormalBehaviorGrid = StyleContentAlignmentData(
  position: .Normal, distribution: .Stretch)

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

private func computeOverflowAlignmentOffset(
  overflow: OverflowAlignment, trackSize: LayoutUnit, gridItemSize: LayoutUnit
) -> LayoutUnit {
  let offset = trackSize - gridItemSize
  switch overflow {
  case .Safe:
    // If overflow is 'safe', we have to make sure we don't overflow the 'start'
    // edge (potentially cause some data loss as the overflow is unreachable).
    return max(LayoutUnit(value: 0), offset)
  case .Unsafe, .Default:
    // If we overflow our alignment container and overflow is 'true' (default), we
    // ignore the overflow and just return the value regardless (which may cause data
    // loss as we overflow the 'start' edge).
    return offset
  }
}

private struct ContentAlignmentData {
  init(positionOffset: LayoutUnit = LayoutUnit(), distributionOffset: LayoutUnit = LayoutUnit()) {
    self.positionOffset = positionOffset
    self.distributionOffset = distributionOffset
  }

  let positionOffset: LayoutUnit
  let distributionOffset: LayoutUnit
}

private enum GridAxisPosition {
  case GridAxisStart
  case GridAxisEnd
  case GridAxisCenter
}

private func resolveContentDistributionFallback(distribution: ContentDistribution) -> (
  OverflowAlignment, ContentPosition
) {
  switch distribution {
  case .SpaceBetween:
    return (.Default, .Start)
  case .SpaceAround:
    return (.Safe, .Center)
  case .SpaceEvenly:
    return (.Safe, .Center)
  case .Stretch:
    return (.Default, .Start)
  case .Default:
    return (.Default, .Normal)
  }
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

  private func gridItemOffset(direction: GridTrackSizingDirection) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func contentAlignment(direction: GridTrackSizingDirection) -> StyleContentAlignmentData {
    return direction == .ForColumns
      ? style().resolvedJustifyContent(normalValueBehavior: contentAlignmentNormalBehaviorGrid)
      : style().resolvedAlignContent(normalValueBehavior: contentAlignmentNormalBehaviorGrid)
  }

  // These functions handle the actual implementation of layoutBlock based on if
  // the grid is a standard grid or a masonry one. While masonry is an extension of grid,
  // keeping the logic in the same function was leading to a messy amount of if statements being added to handle
  // specific masonry cases.
  func layoutGrid(relayoutChildren: Bool) {
    let repainter = LayoutRepainter(renderer: self)
    do {
      let _ = LayoutStateMaintainer(
        root: self, offset: locationOffset(),
        disablePaintOffsetCache: isTransformed() || hasReflection()
          || style().isFlippedBlocksWritingMode())

      var gridLayoutState = computeLayoutRequirementsForItemsBeforeLayout()

      var relayoutChildren = relayoutChildren
      preparePaginationBeforeBlockLayout(relayoutChildren: &relayoutChildren)
      beginUpdateScrollInfoAfterLayoutTransaction()

      let previousSize = size()

      // FIXME: We should use RenderBlock::hasDefiniteLogicalHeight() only but it does not work for positioned stuff.
      // FIXME: Consider caching the hasDefiniteLogicalHeight value throughout the layout.
      // FIXME: We might need to cache the hasDefiniteLogicalHeight if the call of RenderBlock::hasDefiniteLogicalHeight() causes a relevant performance regression.
      let hasDefiniteLogicalHeight =
        renderBlockHasDefiniteLogicalHeight() || overridingLogicalHeight() != nil
        || computeContentLogicalHeight(
          heightType: .MainOrPreferredSize, height: style().logicalHeight(),
          intrinsicContentHeight: nil) != nil

      let aspectRatioBlockSizeDependentGridItems = computeAspectRatioDependentAndBaselineItems()

      resetLogicalHeightBeforeLayoutIfNeeded()

      updateLogicalWidth()

      // Fieldsets need to find their legend and position it inside the border of the object.
      // The legend then gets skipped during normal layout. The same is true for ruby text.
      // It doesn't get included in the normal layout process but is instead skipped.
      layoutExcludedChildren(relayoutChildren: relayoutChildren)

      let availableSpaceForColumns = availableLogicalWidth()
      placeItemsOnGrid(availableLogicalWidth: availableSpaceForColumns)

      trackSizingAlgorithm!.setAvailableSpace(
        direction: .ForColumns, availableSpace: availableSpaceForColumns)
      performPreLayoutForGridItems(
        algorithm: trackSizingAlgorithm!, shouldUpdateGridAreaLogicalSize: .Yes)

      // 1. First, the track sizing algorithm is used to resolve the sizes of the grid columns. At this point the
      // logical width is always definite as the above call to updateLogicalWidth() properly resolves intrinsic
      // sizes. We cannot do the same for heights though because many code paths inside updateLogicalHeight() require
      // a previous call to setLogicalHeight() to resolve heights properly (like for positioned items for example).
      computeTrackSizesForDefiniteSize(
        direction: .ForColumns, availableSpace: availableSpaceForColumns,
        gridLayoutState: &gridLayoutState)

      // 1.5. Compute Content Distribution offsets for column tracks
      offsetBetweenColumns = computeContentPositionAndDistributionOffset(
        direction: .ForColumns,
        availableFreeSpace: trackSizingAlgorithm!.freeSpace(direction: .ForColumns)!,
        numberOfGridTracks: nonCollapsedTracks(direction: .ForColumns))

      // 2. Next, the track sizing algorithm resolves the sizes of the grid rows,
      // using the grid column sizes calculated in the previous step.
      var shouldRecomputeHeight = false
      if !hasDefiniteLogicalHeight {
        computeTrackSizesForIndefiniteSize(
          algorithm: trackSizingAlgorithm!, direction: .ForRows, gridLayoutState: &gridLayoutState)
        if shouldApplySizeContainment() {
          shouldRecomputeHeight = true
        }
      } else {
        computeTrackSizesForDefiniteSize(
          direction: .ForRows, availableSpace: availableLogicalHeightForContentBox(),
          gridLayoutState: &gridLayoutState)
      }

      var trackBasedLogicalHeight = borderAndPaddingLogicalHeight() + scrollbarLogicalHeight()
      if let size = explicitIntrinsicInnerLogicalSize(direction: .ForRows) {
        trackBasedLogicalHeight += size
      } else {
        trackBasedLogicalHeight += trackSizingAlgorithm!.computeTrackBasedSize()
      }

      if shouldRecomputeHeight {
        computeTrackSizesForDefiniteSize(
          direction: .ForRows, availableSpace: trackBasedLogicalHeight,
          gridLayoutState: &gridLayoutState)
      }

      setLogicalHeight(size: trackBasedLogicalHeight)

      updateLogicalHeight()

      // Once grid's indefinite height is resolved, we can compute the
      // available free space for Content Alignment.
      if !hasDefiniteLogicalHeight {
        trackSizingAlgorithm!.setFreeSpace(
          direction: .ForRows, freeSpace: logicalHeight() - trackBasedLogicalHeight)
      }

      // 2.5. Compute Content Distribution offsets for rows tracks
      offsetBetweenRows = computeContentPositionAndDistributionOffset(
        direction: .ForRows,
        availableFreeSpace: trackSizingAlgorithm!.freeSpace(direction: .ForRows)!,
        numberOfGridTracks: nonCollapsedTracks(direction: .ForRows))

      if !aspectRatioBlockSizeDependentGridItems.isEmpty {
        updateGridAreaForAspectRatioItems(
          autoGridItems: aspectRatioBlockSizeDependentGridItems, gridLayoutState: &gridLayoutState)
        updateLogicalWidth()
      }

      // 3. If the min-content contribution of any grid items have changed based on the row
      // sizes calculated in step 2, steps 1 and 2 are repeated with the new min-content
      // contribution (once only).
      repeatTracksSizingIfNeeded(
        availableSpaceForColumns: availableSpaceForColumns,
        availableSpaceForRows: contentLogicalHeight(), gridLayoutState: &gridLayoutState)

      // Grid container should have the minimum height of a line if it's editable. That does not affect track sizing though.
      if hasLineIfEmpty() {
        let minHeightForEmptyLine =
          borderAndPaddingLogicalHeight()
          + lineHeight(
            firstLine: true, direction: isHorizontalWritingMode() ? .HorizontalLine : .VerticalLine,
            linePositionMode: .PositionOfInteriorLineBoxes)
          + scrollbarLogicalHeight()
        setLogicalHeight(size: max(logicalHeight(), minHeightForEmptyLine))
      }

      layoutGridItems(gridLayoutState: &gridLayoutState)

      endAndCommitUpdateScrollInfoAfterLayoutTransaction()

      if size() != previousSize {
        relayoutChildren = true
      }

      outOfFlowItemColumn.removeAll()
      outOfFlowItemRow.removeAll()

      layoutPositionedObjects(relayoutChildren: relayoutChildren || isDocumentElementRenderer())
      trackSizingAlgorithm!.reset()

      computeOverflow(
        oldClientAfterEdge: RenderGridWrapper.layoutOverflowLogicalBottom(renderer: self))

      updateDescendantTransformsAfterLayout()
    }

    updateLayerTransform()

    // Update our scroll information if we're overflow:auto/scroll/hidden now that we know if
    // we overflow or not.
    updateScrollInfoAfterLayout()

    repainter.repaintAfterLayout()

    clearNeedsLayout()

    trackSizingAlgorithm!.clearBaselineItemsCache()
    baselineItemsCached = false
  }

  private func availableLogicalHeightForContentBox() -> LayoutUnit {
    if let overridingLogicalHeight = overridingLogicalHeight() {
      return constrainContentBoxLogicalHeightByMinMax(
        logicalHeight: overridingLogicalHeight - borderAndPaddingLogicalHeight(),
        intrinsicContentHeight: nil)
    }
    return availableLogicalHeight(heightType: .ExcludeMarginBorderPadding)
  }

  func layoutMasonry(relayoutChildren: Bool) {
    let repainter = LayoutRepainter(renderer: self)
    do {
      let _ = LayoutStateMaintainer(
        root: self, offset: locationOffset(),
        disablePaintOffsetCache: isTransformed() || hasReflection()
          || style().isFlippedBlocksWritingMode())
      var gridLayoutState = GridLayoutState()

      var relayoutChildren = relayoutChildren
      preparePaginationBeforeBlockLayout(relayoutChildren: &relayoutChildren)
      beginUpdateScrollInfoAfterLayoutTransaction()

      let previousSize = size()

      // FIXME: We should use RenderBlock::hasDefiniteLogicalHeight() only but it does not work for positioned stuff.
      // FIXME: Consider caching the hasDefiniteLogicalHeight value throughout the layout.
      // FIXME: We might need to cache the hasDefiniteLogicalHeight if the call of RenderBlock::hasDefiniteLogicalHeight() causes a relevant performance regression.
      let hasDefiniteLogicalHeight =
        renderBlockHasDefiniteLogicalHeight() || overridingLogicalHeight() != nil
        || computeContentLogicalHeight(
          heightType: .MainOrPreferredSize, height: style().logicalHeight(),
          intrinsicContentHeight: nil) != nil

      let aspectRatioBlockSizeDependentGridItems = computeAspectRatioDependentAndBaselineItems()

      resetLogicalHeightBeforeLayoutIfNeeded()

      // Fieldsets need to find their legend and position it inside the border of the object.
      // The legend then gets skipped during normal layout. The same is true for ruby text.
      // It doesn't get included in the normal layout process but is instead skipped.
      layoutExcludedChildren(relayoutChildren: relayoutChildren)

      updateLogicalWidth()

      let availableSpaceForColumns = availableLogicalWidth()
      placeItemsOnGrid(availableLogicalWidth: availableSpaceForColumns)

      trackSizingAlgorithm!.setAvailableSpace(
        direction: .ForColumns, availableSpace: availableSpaceForColumns)
      performPreLayoutForGridItems(
        algorithm: trackSizingAlgorithm!, shouldUpdateGridAreaLogicalSize: .Yes)

      // 1. First, the track sizing algorithm is used to resolve the sizes of the grid columns. At this point the
      // logical width is always definite as the above call to updateLogicalWidth() properly resolves intrinsic
      // sizes. We cannot do the same for heights though because many code paths inside updateLogicalHeight() require
      // a previous call to setLogicalHeight() to resolve heights properly (like for positioned items for example).
      computeTrackSizesForDefiniteSize(
        direction: .ForColumns, availableSpace: availableSpaceForColumns,
        gridLayoutState: &gridLayoutState)

      // 1.5. Compute Content Distribution offsets for column tracks
      offsetBetweenColumns = computeContentPositionAndDistributionOffset(
        direction: .ForColumns,
        availableFreeSpace: trackSizingAlgorithm!.freeSpace(direction: .ForColumns)!,
        numberOfGridTracks: nonCollapsedTracks(direction: .ForColumns))

      // 2. Next, the track sizing algorithm resolves the sizes of the grid rows,
      // using the grid column sizes calculated in the previous step.
      var shouldRecomputeHeight = false
      if !hasDefiniteLogicalHeight {
        computeTrackSizesForIndefiniteSize(
          algorithm: trackSizingAlgorithm!, direction: .ForRows, gridLayoutState: &gridLayoutState)
        if shouldApplySizeContainment() {
          shouldRecomputeHeight = true
        }
      } else {
        computeTrackSizesForDefiniteSize(
          direction: .ForRows,
          availableSpace: availableLogicalHeight(heightType: .ExcludeMarginBorderPadding),
          gridLayoutState: &gridLayoutState)
      }

      if areMasonryRows() {
        performMasonryPlacement(masonryAxisDirection: .ForRows)
      } else if areMasonryColumns() {
        performMasonryPlacement(masonryAxisDirection: .ForColumns)
      }

      var trackBasedLogicalHeight = borderAndPaddingLogicalHeight() + scrollbarLogicalHeight()
      if let size = explicitIntrinsicInnerLogicalSize(direction: .ForRows) {
        trackBasedLogicalHeight += size
      } else {
        if areMasonryRows() {
          trackBasedLogicalHeight += masonryLayout!.gridContentSize
        } else {
          trackBasedLogicalHeight += trackSizingAlgorithm!.computeTrackBasedSize()
        }
      }
      if shouldRecomputeHeight {
        computeTrackSizesForDefiniteSize(
          direction: .ForRows, availableSpace: trackBasedLogicalHeight,
          gridLayoutState: &gridLayoutState)
      }

      setLogicalHeight(size: trackBasedLogicalHeight)

      updateLogicalHeight()

      // Once grid's indefinite height is resolved, we can compute the
      // available free space for Content Alignment.
      if !hasDefiniteLogicalHeight || areMasonryRows() {
        trackSizingAlgorithm!.setFreeSpace(
          direction: .ForRows, freeSpace: logicalHeight() - trackBasedLogicalHeight)
      }

      // 2.5. Compute Content Distribution offsets for rows tracks
      offsetBetweenRows = computeContentPositionAndDistributionOffset(
        direction: .ForRows,
        availableFreeSpace: trackSizingAlgorithm!.freeSpace(direction: .ForRows)!,
        numberOfGridTracks: nonCollapsedTracks(direction: .ForRows))

      if !aspectRatioBlockSizeDependentGridItems.isEmpty {
        updateGridAreaForAspectRatioItems(
          autoGridItems: aspectRatioBlockSizeDependentGridItems, gridLayoutState: &gridLayoutState)
        updateLogicalWidth()
      }

      // Grid container should have the minimum height of a line if it's editable. That does not affect track sizing though.
      if hasLineIfEmpty() {
        let minHeightForEmptyLine =
          borderAndPaddingLogicalHeight()
          + lineHeight(
            firstLine: true, direction: isHorizontalWritingMode() ? .HorizontalLine : .VerticalLine,
            linePositionMode: .PositionOfInteriorLineBoxes)
          + scrollbarLogicalHeight()
        setLogicalHeight(size: max(logicalHeight(), minHeightForEmptyLine))
      }

      layoutMasonryItems(gridLayoutState: &gridLayoutState)

      endAndCommitUpdateScrollInfoAfterLayoutTransaction()

      if size() != previousSize {
        relayoutChildren = true
      }

      outOfFlowItemColumn.removeAll()
      outOfFlowItemRow.removeAll()

      layoutPositionedObjects(relayoutChildren: relayoutChildren || isDocumentElementRenderer())
      trackSizingAlgorithm!.reset()

      computeOverflow(
        oldClientAfterEdge: RenderGridWrapper.layoutOverflowLogicalBottom(renderer: self))

      updateDescendantTransformsAfterLayout()
    }

    updateLayerTransform()

    // Update our scroll information if we're overflow:auto/scroll/hidden now that we know if
    // we overflow or not.
    updateScrollInfoAfterLayout()

    repainter.repaintAfterLayout()

    clearNeedsLayout()

    trackSizingAlgorithm!.clearBaselineItemsCache()
    baselineItemsCached = false
  }

  private func performMasonryPlacement(masonryAxisDirection: GridTrackSizingDirection) {
    let gridAxisDirection: GridTrackSizingDirection =
      masonryAxisDirection == .ForRows ? .ForColumns : .ForRows
    let gridAxisTracksBeforeAutoPlacement = currentGrid().numTracks(direction: gridAxisDirection)

    masonryLayout!.performMasonryPlacement(
      gridAxisTracks: gridAxisTracksBeforeAutoPlacement, masonryAxisDirection: masonryAxisDirection)
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

  func placeItems() {
    updateLogicalWidth()

    let availableSpaceForColumns = availableLogicalWidth()
    placeItemsOnGrid(availableLogicalWidth: availableSpaceForColumns)
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

  private func computeLayoutRequirementsForItemsBeforeLayout() -> GridLayoutState {
    var gridLayoutState = GridLayoutState()

    for gridItem: RenderBoxWrapper in childrenOfType(parent: self) {
      let gridItemAlignSelf = alignSelfForGridItem(gridItem: gridItem).position
      if GridLayoutFunctions.isGridItemInlineSizeDependentOnBlockConstraints(
        gridItem: gridItem, parentGrid: self, gridItemAlignSelf: gridItemAlignSelf)
      {
        gridLayoutState.setNeedsSecondTrackSizingPass()
        gridLayoutState.setLayoutRequirementForGridItem(
          gridItem: gridItem, layoutRequirement: .MinContentContributionForSecondColumnPass)
      }

      if !gridItem.needsLayout() || gridItem.isOutOfFlowPositioned()
        || gridItem.isExcludedFromNormalLayout()
      {
        continue
      }

      if canSetColumnAxisStretchRequirementForItem(gridItem: gridItem) {
        gridLayoutState.setLayoutRequirementForGridItem(
          gridItem: gridItem, layoutRequirement: .NeedsColumnAxisStretchAlignment)
      }
    }

    return gridLayoutState
  }

  private func canSetColumnAxisStretchRequirementForItem(gridItem: RenderBoxWrapper) -> Bool {
    let gridItemBlockFlowDirection = GridLayoutFunctions.flowAwareDirectionForGridItem(
      grid: self, gridItem: gridItem, direction: .ForRows)
    return gridItemBlockFlowDirection == .ForRows
      && allowedToStretchGridItemAlongColumnAxis(gridItem: gridItem)
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

  private func computeAutoRepeatTracksCount(
    direction: GridTrackSizingDirection, availableSize: LayoutUnit?
  ) -> UInt32 {
    assert(availableSize == nil || availableSize! != -1)
    let isRowAxis = direction == .ForColumns
    if isSubgrid(direction: direction) {
      return 0
    }

    let autoRepeatTracks =
      isRowAxis ? style().gridAutoRepeatColumns() : style().gridAutoRepeatRows()
    let autoRepeatTrackListLength = UInt32(autoRepeatTracks.count)

    if autoRepeatTrackListLength == 0 {
      return 0
    }

    var needsToFulfillMinimumSize = false
    if availableSize == nil {
      let maxSize = isRowAxis ? style().logicalMaxWidth() : style().logicalMaxHeight()
      var containingBlockAvailableSize: LayoutUnit? = nil
      var availableMaxSize: LayoutUnit? = nil
      if maxSize.isSpecified() {
        if maxSize.isPercentOrCalculated() {
          containingBlockAvailableSize =
            isRowAxis
            ? containingBlockLogicalWidthForContent()
            : containingBlockLogicalHeightForContent(heightType: .ExcludeMarginBorderPadding)
        }
        let maxSizeValue = valueForLength(
          length: maxSize, maximumValue: containingBlockAvailableSize ?? LayoutUnit())
        availableMaxSize =
          isRowAxis
          ? adjustContentBoxLogicalWidthForBoxSizing(
            computedLogicalWidth: maxSizeValue, originalType: maxSize.type())
          : adjustContentBoxLogicalHeightForBoxSizing(height: maxSizeValue)
      }

      let minSize = isRowAxis ? style().logicalMinWidth() : style().logicalMinHeight()
      let minSizeForOrthogonalAxis =
        isRowAxis ? style().logicalMinHeight() : style().logicalMinWidth()
      let shouldComputeMinSizeFromAspectRatio =
        minSizeForOrthogonalAxis.isSpecified() && !shouldIgnoreAspectRatio()
      let explicitIntrinsicInnerSize = explicitIntrinsicInnerLogicalSize(direction: direction)

      if availableMaxSize == nil && !minSize.isSpecified() && !shouldComputeMinSizeFromAspectRatio
        && explicitIntrinsicInnerSize == nil
      {
        return autoRepeatTrackListLength
      }

      var availableMinSize: LayoutUnit? = nil
      if minSize.isSpecified() {
        if containingBlockAvailableSize == nil && minSize.isPercentOrCalculated() {
          containingBlockAvailableSize =
            isRowAxis
            ? containingBlockLogicalWidthForContent()
            : containingBlockLogicalHeightForContent(heightType: .ExcludeMarginBorderPadding)
        }
        let minSizeValue = valueForLength(
          length: minSize, maximumValue: containingBlockAvailableSize ?? LayoutUnit())
        availableMinSize =
          isRowAxis
          ? adjustContentBoxLogicalWidthForBoxSizing(
            computedLogicalWidth: minSizeValue, originalType: minSize.type())
          : adjustContentBoxLogicalHeightForBoxSizing(height: minSizeValue)
      } else if shouldComputeMinSizeFromAspectRatio {
        let (logicalMinWidth, _) = computeMinMaxLogicalWidthFromAspectRatio()
        availableMinSize = logicalMinWidth
      }
      if !maxSize.isSpecified() || explicitIntrinsicInnerSize != nil {
        needsToFulfillMinimumSize = true
      }

      var availableSize: LayoutUnit? = max(
        availableMinSize ?? LayoutUnit(), availableMaxSize ?? LayoutUnit(),
        explicitIntrinsicInnerSize ?? LayoutUnit())
      if maxSize.isSpecified() && availableMaxSize < availableSize {
        availableSize = max(availableMinSize, availableMaxSize)
      }
    }

    var autoRepeatTracksSize = LayoutUnit()
    for autoTrackSize in autoRepeatTracks {
      assert(autoTrackSize.minTrackBreadth.isLength())
      assert(!autoTrackSize.minTrackBreadth.isFlex())
      let hasDefiniteMaxTrackSizingFunction =
        autoTrackSize.maxTrackBreadth.isLength()
        && !autoTrackSize.maxTrackBreadth.isContentSized()
      var trackLength =
        hasDefiniteMaxTrackSizingFunction
        ? autoTrackSize.maxTrackBreadth.length() : autoTrackSize.minTrackBreadth.length()
      let hasDefiniteMinTrackSizingFunction =
        autoTrackSize.minTrackBreadth.isLength()
        && !autoTrackSize.minTrackBreadth.isContentSized()
      if hasDefiniteMinTrackSizingFunction
        && (trackLength.value() < autoTrackSize.minTrackBreadth.length().value())
      {
        trackLength = autoTrackSize.minTrackBreadth.length()
      }
      autoRepeatTracksSize += valueForLength(
        length: trackLength, maximumValue: availableSize!)
    }
    // For the purpose of finding the number of auto-repeated tracks, the UA must floor the track size to a UA-specified
    // value to avoid division by zero. It is suggested that this floor be 1px.
    autoRepeatTracksSize = max(LayoutUnit(value: UInt64(1)), autoRepeatTracksSize)

    // There will be always at least 1 auto-repeat track, so take it already into account when computing the total track size.
    var tracksSize = autoRepeatTracksSize
    let trackSizes = isRowAxis ? style().gridColumnTrackSizes() : style().gridRowTrackSizes()

    for track in trackSizes {
      let hasDefiniteMaxTrackBreadth =
        track.maxTrackBreadth.isLength() && !track.maxTrackBreadth.isContentSized()
      assert(
        hasDefiniteMaxTrackBreadth
          || (track.minTrackBreadth.isLength() && !track.minTrackBreadth.isContentSized()))
      tracksSize += valueForLength(
        length: hasDefiniteMaxTrackBreadth
          ? track.maxTrackBreadth.length() : track.minTrackBreadth.length(),
        maximumValue: availableSize!)
    }

    // Add gutters as if auto repeat tracks were only repeated once. Gaps between different repetitions will be added later when
    // computing the number of repetitions of the auto repeat().
    let gapSize = gridGap(direction: direction, availableSize: availableSize)
    tracksSize += gapSize * (UInt64(trackSizes.count) + UInt64(autoRepeatTrackListLength) - 1)

    var freeSpace = availableSize! - tracksSize
    if freeSpace <= Int32(0) {
      return autoRepeatTrackListLength
    }

    let autoRepeatSizeWithGap = autoRepeatTracksSize + gapSize * autoRepeatTrackListLength
    var repetitions = 1 + (freeSpace / autoRepeatSizeWithGap).toUnsigned()
    freeSpace -= autoRepeatSizeWithGap * (repetitions - 1)
    assert(freeSpace >= Int32(0))

    // Provided the grid container does not have a definite size or max-size in the relevant axis,
    // if the min size is definite then the number of repetitions is the largest possible positive
    // integer that fulfills that minimum requirement.
    if needsToFulfillMinimumSize && freeSpace != 0 {
      repetitions += 1
    }

    return repetitions * autoRepeatTrackListLength
  }

  private func clampAutoRepeatTracks(direction: GridTrackSizingDirection, autoRepeatTracks: UInt32)
    -> UInt32
  {
    if autoRepeatTracks == 0 {
      return 0
    }

    let insertionPoint =
      direction == .ForColumns
      ? style().gridAutoRepeatColumnsInsertionPoint() : style().gridAutoRepeatRowsInsertionPoint()
    let maxTracks = UInt32(GridPosition.max())

    if insertionPoint == 0 {
      return min(autoRepeatTracks, maxTracks)
    }

    if insertionPoint >= maxTracks {
      return 0
    }

    return min(autoRepeatTracks, maxTracks - insertionPoint)
  }

  private func computeEmptyTracksForAutoRepeat(direction: GridTrackSizingDirection)
    -> OrderedTrackIndexSet?
  {
    let isRowAxis = direction == .ForColumns
    if (isRowAxis && autoRepeatColumnsType() != .Fit)
      || (!isRowAxis && autoRepeatRowsType() != .Fit)
    {
      return nil
    }

    var emptyTrackIndexes: OrderedTrackIndexSet? = nil
    let insertionPoint =
      isRowAxis
      ? style().gridAutoRepeatColumnsInsertionPoint() : style().gridAutoRepeatRowsInsertionPoint()
    let firstAutoRepeatTrack =
      insertionPoint + currentGrid().explicitGridStart(direction: direction)
    let lastAutoRepeatTrack =
      firstAutoRepeatTrack + currentGrid().autoRepeatTracks(direction: direction)

    if !currentGrid().hasGridItems()
      || (shouldCheckExplicitIntrinsicInnerLogicalSize(direction: direction)
        && explicitIntrinsicInnerLogicalSize(direction: direction) == nil)
    {
      emptyTrackIndexes = OrderedTrackIndexSet()
      for trackIndex in firstAutoRepeatTrack..<lastAutoRepeatTrack {
        emptyTrackIndexes!.add(value: UInt64(trackIndex))
      }
    } else {
      for trackIndex in firstAutoRepeatTrack..<lastAutoRepeatTrack {
        let iterator = GridIterator(
          grid: currentGrid(), direction: direction, fixedTrackIndex: trackIndex)
        if iterator.nextGridItem() == nil {
          if emptyTrackIndexes == nil {
            emptyTrackIndexes = OrderedTrackIndexSet()
          }
          emptyTrackIndexes!.add(value: UInt64(trackIndex))
        }
      }
    }
    return emptyTrackIndexes
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

  // FIXME: We shouldn't have to pass the available logical width as argument. The problem is that
  // availableLogicalWidth() does always return a value even if we cannot resolve it like when
  // computing the intrinsic size (preferred widths). That's why we pass the responsibility to the
  // caller who does know whether the available logical width is indefinite or not.
  private func placeItemsOnGrid(availableLogicalWidth: LayoutUnit?) {
    var autoRepeatColumns = computeAutoRepeatTracksCount(
      direction: .ForColumns, availableSize: availableLogicalWidth)
    var autoRepeatRows = computeAutoRepeatTracksCount(
      direction: .ForRows, availableSize: availableLogicalHeightForPercentageComputation())
    autoRepeatRows = clampAutoRepeatTracks(direction: .ForRows, autoRepeatTracks: autoRepeatRows)
    autoRepeatColumns = clampAutoRepeatTracks(
      direction: .ForColumns, autoRepeatTracks: autoRepeatColumns)

    if isSubgridInParentDirection(parentDirection: .ForColumns)
      || isSubgridInParentDirection(parentDirection: .ForRows),
      let parent = parent() as? RenderGridWrapper, parent.currentGrid().needsItemsPlacement()
    {
      currentGrid().setNeedsItemsPlacement(needsItemsPlacement: true)
    }

    if autoRepeatColumns != currentGrid().autoRepeatTracks(direction: .ForColumns)
      || autoRepeatRows != currentGrid().autoRepeatTracks(direction: .ForRows)
      || isMasonry()
    {
      currentGrid().setNeedsItemsPlacement(needsItemsPlacement: true)
      currentGrid().setAutoRepeatTracks(
        autoRepeatRows: autoRepeatRows, autoRepeatColumns: autoRepeatColumns)
    }

    if !currentGrid().needsItemsPlacement() {
      return
    }

    assert(!currentGrid().hasGridItems())
    populateExplicitGridAndOrderIterator()

    var autoMajorAxisAutoGridItems: [RenderBoxWrapper] = []
    var specifiedMajorAxisAutoGridItems: [RenderBoxWrapper] = []
    var gridItem = currentGrid().orderIterator.first()
    while gridItem != nil {
      if currentGrid().orderIterator.shouldSkipChild(child: gridItem!) {
        gridItem = currentGrid().orderIterator.next()
        continue
      }

      // Grid items should use the grid area sizes instead of the containing block (grid container)
      // sizes, we initialize the overrides here if needed to ensure it.
      if gridItem!.overridingContainingBlockContentLogicalWidth() == nil && !areMasonryColumns() {
        gridItem!.setOverridingContainingBlockContentLogicalWidth(
          logicalWidth: LayoutUnit(value: UInt64(0)))
      }
      if gridItem!.overridingContainingBlockContentLogicalHeight() == nil && !areMasonryRows() {
        gridItem!.setOverridingContainingBlockContentLogicalHeight(logicalHeight: nil)
      }

      let area = currentGrid().gridItemArea(item: gridItem!)
      currentGrid().clampAreaToSubgridIfNeeded(area: area)
      if !area.rows.isIndefinite() {
        area.rows.translate(offset: currentGrid().explicitGridStart(direction: .ForRows))
      }
      if !area.columns.isIndefinite() {
        area.columns.translate(offset: currentGrid().explicitGridStart(direction: .ForColumns))
      }

      if area.rows.isIndefinite() || area.columns.isIndefinite() {
        currentGrid().setGridItemArea(item: gridItem!, area: area)
        let majorAxisDirectionIsForColumns = autoPlacementMajorAxisDirection() == .ForColumns
        if (majorAxisDirectionIsForColumns && area.columns.isIndefinite())
          || (!majorAxisDirectionIsForColumns && area.rows.isIndefinite())
        {
          autoMajorAxisAutoGridItems.append(gridItem!)
        } else {
          specifiedMajorAxisAutoGridItems.append(gridItem!)
        }
        gridItem = currentGrid().orderIterator.next()
        continue
      }
      insertIntoGrid(
        grid: currentGrid(), gridItem: gridItem!, area: GridArea(r: area.rows, c: area.columns))
      gridItem = currentGrid().orderIterator.next()
    }

    #if ASSERT_ENABLED
      if currentGrid().hasGridItems() {
        assert(
          currentGrid().numTracks(direction: .ForRows)
            >= GridPositionsResolver.explicitGridRowCount(gridContainer: self))
        assert(
          currentGrid().numTracks(direction: .ForColumns)
            >= GridPositionsResolver.explicitGridColumnCount(gridContainer: self))
      }
    #endif

    // Perform auto placement.
    placeSpecifiedMajorAxisItemsOnGrid(autoGridItems: &specifiedMajorAxisAutoGridItems)
    placeAutoMajorAxisItemsOnGrid(autoGridItems: &autoMajorAxisAutoGridItems)
    // Compute collapsible tracks for auto-fit.
    currentGrid().setAutoRepeatEmptyColumns(
      autoRepeatEmptyColumns: computeEmptyTracksForAutoRepeat(direction: .ForColumns))
    currentGrid().setAutoRepeatEmptyRows(
      autoRepeatEmptyRows: computeEmptyTracksForAutoRepeat(direction: .ForRows))

    currentGrid().setNeedsItemsPlacement(needsItemsPlacement: false)

    #if ASSERT_ENABLED
      do {
        var gridItem = currentGrid().orderIterator.first()
        while gridItem != nil {
          if currentGrid().orderIterator.shouldSkipChild(child: gridItem!) {
            gridItem = currentGrid().orderIterator.next()
            continue
          }

          let area = currentGrid().gridItemArea(item: gridItem!)
          assert(area.rows.isTranslatedDefinite() && area.columns.isTranslatedDefinite())
          gridItem = currentGrid().orderIterator.next()
        }
      }
    #endif
  }

  private func populateExplicitGridAndOrderIterator() {
    let populator = OrderIteratorPopulator(iterator: currentGrid().orderIterator)
    var explicitRowStart = 0
    var explicitColumnStart = 0
    var maximumRowIndex = GridPositionsResolver.explicitGridRowCount(gridContainer: self)
    var maximumColumnIndex = GridPositionsResolver.explicitGridColumnCount(gridContainer: self)

    var gridItem = firstChildBox()
    while gridItem != nil {
      if !populator.collectChild(child: gridItem!) {
        gridItem = gridItem!.nextSiblingBox()
        continue
      }

      let rowPositions = GridPositionsResolver.resolveGridPositionsFromStyle(
        gridContainer: self, gridItem: gridItem!, direction: .ForRows)
      if !isSubgridRows() {
        if !rowPositions.isIndefinite() {
          explicitRowStart = max(explicitRowStart, Int(-rowPositions.untranslatedStartLine()))
          maximumRowIndex = max(maximumRowIndex, UInt32(rowPositions.untranslatedEndLine()))
        } else {
          // Grow the grid for items with a definite row span, getting the largest such span.
          let spanSize = GridPositionsResolver.spanSizeForAutoPlacedItem(
            gridItem: gridItem!, direction: .ForRows)
          maximumRowIndex = max(maximumRowIndex, spanSize)
        }
      }

      let columnPositions = GridPositionsResolver.resolveGridPositionsFromStyle(
        gridContainer: self, gridItem: gridItem!, direction: .ForColumns)
      if !isSubgridColumns() {
        if !columnPositions.isIndefinite() {
          explicitColumnStart = max(
            explicitColumnStart, Int(-columnPositions.untranslatedStartLine()))
          maximumColumnIndex = max(
            maximumColumnIndex, UInt32(columnPositions.untranslatedEndLine()))
        } else {
          // Grow the grid for items with a definite column span, getting the largest such span.
          let spanSize = GridPositionsResolver.spanSizeForAutoPlacedItem(
            gridItem: gridItem!, direction: .ForColumns)
          maximumColumnIndex = max(maximumColumnIndex, spanSize)
        }
      }

      currentGrid().setGridItemArea(
        item: gridItem!, area: GridArea(r: rowPositions, c: columnPositions))
      gridItem = gridItem!.nextSiblingBox()
    }

    currentGrid().setExplicitGridStart(
      rowStart: UInt32(explicitRowStart), columnStart: UInt32(explicitColumnStart))
    currentGrid().ensureGridSize(
      maximumRowSize: maximumRowIndex + UInt32(explicitRowStart),
      maximumColumnSize: maximumColumnIndex + UInt32(explicitColumnStart))
    currentGrid().setClampingForSubgrid(
      maxRows: isSubgridRows() ? maximumRowIndex : 0,
      maxColumns: isSubgridColumns() ? maximumColumnIndex : 0)
  }

  private func createEmptyGridAreaAtSpecifiedPositionsOutsideGrid(
    gridItem: RenderBoxWrapper, specifiedDirection: GridTrackSizingDirection,
    specifiedPositions: GridSpan
  ) -> GridArea {
    let crossDirection: GridTrackSizingDirection =
      specifiedDirection == .ForColumns ? .ForRows : .ForColumns
    let endOfCrossDirection = currentGrid().numTracks(direction: crossDirection)
    let crossDirectionSpanSize = GridPositionsResolver.spanSizeForAutoPlacedItem(
      gridItem: gridItem, direction: crossDirection)
    let crossDirectionPositions = GridSpan.translatedDefiniteGridSpan(
      startLine: Int32(endOfCrossDirection),
      endLine: Int32(endOfCrossDirection + crossDirectionSpanSize))
    return GridArea(
      r: specifiedDirection == .ForColumns ? crossDirectionPositions : specifiedPositions,
      c: specifiedDirection == .ForColumns ? specifiedPositions : crossDirectionPositions)
  }

  private func placeSpecifiedMajorAxisItemsOnGrid(autoGridItems: inout [RenderBoxWrapper]) {
    let isForColumns = autoPlacementMajorAxisDirection() == .ForColumns
    let isGridAutoFlowDense = style().isGridAutoFlowAlgorithmDense()

    // Mapping between the major axis tracks (rows or columns) and the last auto-placed item's position inserted on
    // that track. This is needed to implement "sparse" packing for items locked to a given track.
    // See https://drafts.csswg.org/css-grid-2/#auto-placement-algo
    var minorAxisCursors: [UInt32: UInt32] = [:]

    for autoGridItem in autoGridItems {
      let majorAxisPositions = currentGrid().gridItemSpan(
        gridItem: autoGridItem, direction: autoPlacementMajorAxisDirection())
      assert(majorAxisPositions.isTranslatedDefinite())
      assert(
        currentGrid().gridItemSpan(
          gridItem: autoGridItem, direction: autoPlacementMinorAxisDirection()
        ).isIndefinite())
      let minorAxisSpanSize = GridPositionsResolver.spanSizeForAutoPlacedItem(
        gridItem: autoGridItem, direction: autoPlacementMinorAxisDirection())
      let majorAxisInitialPosition = majorAxisPositions.startLine()

      let iterator = GridIterator(
        grid: currentGrid(), direction: autoPlacementMajorAxisDirection(),
        fixedTrackIndex: majorAxisPositions.startLine(),
        varyingTrackIndex: isGridAutoFlowDense ? 0 : minorAxisCursors[majorAxisInitialPosition]!)
      var emptyGridArea = iterator.nextEmptyGridArea(
        fixedTrackSpan: majorAxisPositions.integerSpan(), varyingTrackSpan: minorAxisSpanSize)
      if emptyGridArea == nil {
        emptyGridArea = createEmptyGridAreaAtSpecifiedPositionsOutsideGrid(
          gridItem: autoGridItem, specifiedDirection: autoPlacementMajorAxisDirection(),
          specifiedPositions: majorAxisPositions)
      }

      emptyGridArea = insertIntoGrid(
        grid: currentGrid(), gridItem: autoGridItem, area: emptyGridArea!)

      if !isGridAutoFlowDense {
        minorAxisCursors.updateValue(
          isForColumns ? emptyGridArea!.rows.startLine() : emptyGridArea!.columns.startLine(),
          forKey: majorAxisInitialPosition)
      }
    }
  }

  private func placeAutoMajorAxisItemsOnGrid(autoGridItems: inout [RenderBoxWrapper]) {
    var autoPlacementCursor = (UInt32(0), UInt32(0))
    let isGridAutoFlowDense = style().isGridAutoFlowAlgorithmDense()

    for autoGridItem in autoGridItems {
      placeAutoMajorAxisItemOnGrid(
        gridItem: autoGridItem, autoPlacementCursor: &autoPlacementCursor)

      if isGridAutoFlowDense {
        autoPlacementCursor = (UInt32(0), UInt32(0))
      }
    }
  }

  private typealias AutoPlacementCursor = (UInt32, UInt32)

  private func placeAutoMajorAxisItemOnGrid(
    gridItem: RenderBoxWrapper, autoPlacementCursor: inout AutoPlacementCursor
  ) {
    assert(
      currentGrid().gridItemSpan(gridItem: gridItem, direction: autoPlacementMajorAxisDirection())
        .isIndefinite())
    let majorAxisSpanSize = GridPositionsResolver.spanSizeForAutoPlacedItem(
      gridItem: gridItem, direction: autoPlacementMajorAxisDirection())

    let endOfMajorAxis = currentGrid().numTracks(direction: autoPlacementMajorAxisDirection())
    var (majorAxisAutoPlacementCursor, minorAxisAutoPlacementCursor) = autoPlacementCursor
    if autoPlacementMajorAxisDirection() == .ForColumns {
      swap(&majorAxisAutoPlacementCursor, &minorAxisAutoPlacementCursor)
    }

    var emptyGridArea: GridArea? = nil
    let minorAxisPositions = currentGrid().gridItemSpan(
      gridItem: gridItem, direction: autoPlacementMinorAxisDirection())
    if minorAxisPositions.isTranslatedDefinite() {
      // Move to the next track in major axis if initial position in minor axis is before auto-placement cursor.
      if minorAxisPositions.startLine() < minorAxisAutoPlacementCursor {
        majorAxisAutoPlacementCursor += 1
      }

      if majorAxisAutoPlacementCursor < endOfMajorAxis {
        let iterator = GridIterator(
          grid: currentGrid(), direction: autoPlacementMinorAxisDirection(),
          fixedTrackIndex: minorAxisPositions.startLine(),
          varyingTrackIndex: majorAxisAutoPlacementCursor)
        emptyGridArea = iterator.nextEmptyGridArea(
          fixedTrackSpan: minorAxisPositions.integerSpan(), varyingTrackSpan: majorAxisSpanSize)
      }

      if emptyGridArea == nil {
        emptyGridArea = createEmptyGridAreaAtSpecifiedPositionsOutsideGrid(
          gridItem: gridItem, specifiedDirection: autoPlacementMinorAxisDirection(),
          specifiedPositions: minorAxisPositions)
      }
    } else {
      let minorAxisSpanSize = GridPositionsResolver.spanSizeForAutoPlacedItem(
        gridItem: gridItem, direction: autoPlacementMinorAxisDirection())

      for majorAxisIndex in majorAxisAutoPlacementCursor..<endOfMajorAxis {
        let iterator = GridIterator(
          grid: currentGrid(), direction: autoPlacementMajorAxisDirection(),
          fixedTrackIndex: majorAxisIndex, varyingTrackIndex: minorAxisAutoPlacementCursor)
        emptyGridArea = iterator.nextEmptyGridArea(
          fixedTrackSpan: majorAxisSpanSize, varyingTrackSpan: minorAxisSpanSize)

        if emptyGridArea != nil {
          // Check that it fits in the minor axis direction, as we shouldn't grow in that direction here (it was already managed in populateExplicitGridAndOrderIterator()).
          let minorAxisFinalPositionIndex =
            autoPlacementMinorAxisDirection() == .ForColumns
            ? emptyGridArea!.columns.endLine() : emptyGridArea!.rows.endLine()
          let endOfMinorAxis = currentGrid().numTracks(direction: autoPlacementMinorAxisDirection())
          if minorAxisFinalPositionIndex <= endOfMinorAxis {
            break
          }

          // Discard empty grid area as it does not fit in the minor axis direction.
          // We don't need to create a new empty grid area yet as we might find a valid one in the next iteration.
          emptyGridArea = nil
        }

        // As we're moving to the next track in the major axis we should reset the auto-placement cursor in the minor axis.
        minorAxisAutoPlacementCursor = 0
      }

      if emptyGridArea == nil {
        emptyGridArea = createEmptyGridAreaAtSpecifiedPositionsOutsideGrid(
          gridItem: gridItem, specifiedDirection: autoPlacementMinorAxisDirection(),
          specifiedPositions: GridSpan.translatedDefiniteGridSpan(
            startLine: 0, endLine: Int32(minorAxisSpanSize)))
      }
    }

    emptyGridArea = insertIntoGrid(grid: currentGrid(), gridItem: gridItem, area: emptyGridArea!)
    autoPlacementCursor = (emptyGridArea!.rows.startLine(), emptyGridArea!.columns.startLine())
  }

  private func autoPlacementMajorAxisDirection() -> GridTrackSizingDirection {
    if areMasonryColumns() {
      return .ForColumns
    }
    if areMasonryRows() {
      return .ForRows
    }

    return style().isGridAutoFlowDirectionColumn() ? .ForColumns : .ForRows
  }

  private func autoPlacementMinorAxisDirection() -> GridTrackSizingDirection {
    return (autoPlacementMajorAxisDirection() == .ForColumns) ? .ForRows : .ForColumns
  }

  override func canPerformSimplifiedLayout() -> Bool {
    // We cannot perform a simplified layout if we need to position the items and we have some
    // positioned items to be laid out.
    if currentGrid().needsItemsPlacement() && posChildNeedsLayout() {
      return false
    }

    return renderBlockCanPerformSimplifiedLayout()
  }

  private func prepareGridItemForPositionedLayout(gridItem: RenderBoxWrapper) {
    assert(gridItem.isOutOfFlowPositioned())
    gridItem.containingBlock()!.insertPositionedObject(positioned: gridItem)

    let gridItemLayer = gridItem.layer()
    // Static position of a positioned grid item should use the content-box (https://drafts.csswg.org/css-grid/#static-position).
    gridItemLayer!.setStaticInlinePosition(position: borderAndPaddingStart())
    gridItemLayer!.setStaticBlockPosition(position: borderAndPaddingBefore())
  }

  private func hasStaticPositionForGridItem(
    gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func computeTrackSizesForDefiniteSize(
    direction: GridTrackSizingDirection, availableSpace: LayoutUnit,
    gridLayoutState: inout GridLayoutState
  ) {
    trackSizingAlgorithm!.run(
      direction: direction, numTracks: numTracks(direction: direction),
      sizingOperation: .TrackSizing,
      availableSpace: availableSpace, gridLayoutState: &gridLayoutState)
    assert(trackSizingAlgorithm!.tracksAreWiderThanMinTrackBreadth())
  }

  @discardableResult
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

  private func repeatTracksSizingIfNeeded(
    availableSpaceForColumns: LayoutUnit, availableSpaceForRows: LayoutUnit,
    gridLayoutState: inout GridLayoutState
  ) {
    // In orthogonal flow cases column track's size is determined by using the computed
    // row track's size, which it was estimated during the first cycle of the sizing
    // algorithm. Hence we need to repeat computeUsedBreadthOfGridTracks for both,
    // columns and rows, to determine the final values.
    // TODO (lajava): orthogonal flows is just one of the cases which may require
    // a new cycle of the sizing algorithm; there may be more. In addition, not all the
    // cases with orthogonal flows require this extra cycle; we need a more specific
    // condition to detect whether grid item's min-content contribution has changed or not.
    // The complication with repeating the track sizing algorithm for flex max-sizing is that
    // it might change a grid item's status of participating in Baseline Alignment for
    // a cyclic sizing dependency case, which should be definitively excluded. See
    // https://github.com/w3c/csswg-drafts/issues/3046 for details.
    // FIXME: we are avoiding repeating the track sizing algorithm for grid item with baseline alignment
    // here in the case of using flex max-sizing functions. We probably also need to investigate whether
    // it is applicable for the case of percent-sized rows with indefinite height as well.
    if gridLayoutState.needsSecondTrackSizingPass
      || trackSizingAlgorithm!.hasAnyPercentSizedRowsIndefiniteHeight()
      || (trackSizingAlgorithm!.hasAnyFlexibleMaxTrackBreadth()
        && !trackSizingAlgorithm!.hasAnyBaselineAlignmentItem())
      || hasAspectRatioBlockSizeDependentItem
    {

      populateGridPositionsForDirection(direction: .ForRows)
      computeTrackSizesForDefiniteSize(
        direction: .ForColumns, availableSpace: availableSpaceForColumns,
        gridLayoutState: &gridLayoutState)
      offsetBetweenColumns = computeContentPositionAndDistributionOffset(
        direction: .ForColumns,
        availableFreeSpace: trackSizingAlgorithm!.freeSpace(direction: .ForColumns)!,
        numberOfGridTracks: nonCollapsedTracks(direction: .ForColumns))

      computeTrackSizesForDefiniteSize(
        direction: .ForRows, availableSpace: availableSpaceForRows,
        gridLayoutState: &gridLayoutState)
      offsetBetweenRows = computeContentPositionAndDistributionOffset(
        direction: .ForRows,
        availableFreeSpace: trackSizingAlgorithm!.freeSpace(direction: .ForRows)!,
        numberOfGridTracks: nonCollapsedTracks(direction: .ForRows))
    }
  }

  private func updateGridAreaForAspectRatioItems(
    autoGridItems: [RenderBoxWrapper], gridLayoutState: inout GridLayoutState
  ) {
    populateGridPositionsForDirection(direction: .ForColumns)
    populateGridPositionsForDirection(direction: .ForRows)

    for autoGridItem in autoGridItems {
      updateGridAreaLogicalSize(
        gridItem: autoGridItem,
        width: gridAreaBreadthForGridItemIncludingAlignmentOffsets(
          gridItem: autoGridItem, direction: .ForColumns),
        height: gridAreaBreadthForGridItemIncludingAlignmentOffsets(
          gridItem: autoGridItem, direction: .ForRows))
      // For an item with aspect-ratio, if it has stretch alignment that stretches to the definite row, we also need to transfer the size before laying out the grid item.
      if autoGridItem.hasStretchedLogicalHeight() {
        applyStretchAlignmentToGridItemIfNeeded(
          gridItem: autoGridItem, gridLayoutState: &gridLayoutState)
      }
    }
  }

  private func layoutGridItems(gridLayoutState: inout GridLayoutState) {
    populateGridPositionsForDirection(direction: .ForColumns)
    populateGridPositionsForDirection(direction: .ForRows)

    var gridItem = firstChildBox()
    while gridItem != nil {
      if currentGrid().orderIterator.shouldSkipChild(child: gridItem!) {
        if gridItem!.isOutOfFlowPositioned() {
          prepareGridItemForPositionedLayout(gridItem: gridItem!)
        }
        gridItem = gridItem!.nextSiblingBox()
        continue
      }

      if let renderGrid = gridItem as? RenderGridWrapper,
        renderGrid.isSubgridColumns() || renderGrid.isSubgridRows()
      {
        gridItem!.setNeedsLayout(markParents: .MarkOnlyThis)
      }

      // Setting the definite grid area's sizes. It may imply that the
      // item must perform a layout if its area differs from the one
      // used during the track sizing algorithm.
      updateGridAreaLogicalSize(
        gridItem: gridItem!,
        width: gridAreaBreadthForGridItemIncludingAlignmentOffsets(
          gridItem: gridItem!, direction: .ForColumns),
        height: gridAreaBreadthForGridItemIncludingAlignmentOffsets(
          gridItem: gridItem!, direction: .ForRows))

      let oldGridItemRect = gridItem!.frameRect()

      // Stretching logic might force a grid item layout, so we need to run it before the layoutIfNeeded
      // call to avoid unnecessary relayouts. This might imply that grid item margins, needed to correctly
      // determine the available space before stretching, are not set yet.
      applyStretchAlignmentToGridItemIfNeeded(
        gridItem: gridItem!, gridLayoutState: &gridLayoutState)
      applySubgridStretchAlignmentToGridItemIfNeeded(gridItem: gridItem!)

      gridItem!.layoutIfNeeded()

      // We need pending layouts to be done in order to compute auto-margins properly.
      updateAutoMarginsInColumnAxisIfNeeded(gridItem: gridItem!)
      updateAutoMarginsInRowAxisIfNeeded(gridItem: gridItem!)

      setLogicalPositionForGridItem(gridItem: gridItem!)

      // If the grid item moved, we have to repaint it as well as any floating/positioned
      // descendants. An exception is if we need a layout. In this case, we know we're going to
      // repaint ourselves (and the grid item) anyway.
      if !selfNeedsLayout() && gridItem!.checkForRepaintDuringLayout() {
        gridItem!.repaintDuringLayoutIfMoved(oldRect: oldGridItemRect)
      }
      gridItem = gridItem!.nextSiblingBox()
    }
  }

  private func layoutMasonryItems(gridLayoutState: inout GridLayoutState) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func populateGridPositionsForDirection(direction: GridTrackSizingDirection) {
    // Since we add alignment offsets and track gutters, grid lines are not always adjacent. Hence, we will have to
    // assume from now on that we just store positions of the initial grid lines of each track,
    // except the last one, which is the only one considered as a final grid line of a track.

    // The grid container's frame elements (border, padding and <content-position> offset) are sensible to the
    // inline-axis flow direction. However, column lines positions are 'direction' unaware. This simplification
    // allows us to use the same indexes to identify the columns independently on the inline-axis direction.
    let isRowAxis = direction == .ForColumns
    let tracks = trackSizingAlgorithm!.tracks(direction: direction)
    let numberOfTracks = tracks.count
    let numberOfLines = numberOfTracks + 1
    let lastLine = numberOfLines - 1
    let hasCollapsedTracks = currentGrid().hasAutoRepeatEmptyTracks(direction: direction)
    let numberOfCollapsedTracks =
      hasCollapsedTracks ? currentGrid().autoRepeatEmptyTracks(direction: direction).size() : 0
    let offset = direction == .ForColumns ? offsetBetweenColumns : offsetBetweenRows
    var positions = isRowAxis ? ArraySlice(columnPositions) : ArraySlice(rowPositions)
    assert(positions.count <= numberOfLines)
    for _ in positions.count..<numberOfLines {
      positions.append(LayoutUnit())
    }

    let borderAndPadding = isRowAxis ? borderAndPaddingStart() : borderAndPaddingBefore()

    positions[0] = borderAndPadding + offset.positionOffset
    if numberOfLines > 1 {
      // If we have collapsed tracks we just ignore gaps here and add them later as we might not
      // compute the gap between two consecutive tracks without examining the surrounding ones.
      var gap = !hasCollapsedTracks ? gridGap(direction: direction) : LayoutUnit(value: UInt64(0))
      let nextToLastLine = numberOfLines - 2

      for i in 0..<nextToLastLine {
        positions[i + 1] =
          positions[i] + offset.distributionOffset + tracks[i].unclampedBaseSize() + gap
      }
      positions[lastLine] = positions[nextToLastLine] + tracks[nextToLastLine].unclampedBaseSize()

      // Adjust collapsed gaps. Collapsed tracks cause the surrounding gutters to collapse (they
      // coincide exactly) except on the edges of the grid where they become 0.
      if hasCollapsedTracks {
        gap = gridGap(direction: direction)
        var remainingEmptyTracks = numberOfCollapsedTracks
        var offsetAccumulator = LayoutUnit()
        var gapAccumulator = LayoutUnit()
        for i in 1..<lastLine {
          if currentGrid().isEmptyAutoRepeatTrack(direction: direction, line: UInt32(i - 1)) {
            remainingEmptyTracks -= 1
            offsetAccumulator += offset.distributionOffset
          } else {
            // Add gap between consecutive non empty tracks. Add it also just once for an
            // arbitrary number of empty tracks between two non empty ones.
            let allRemainingTracksAreEmpty = remainingEmptyTracks == (lastLine - i)
            if !allRemainingTracksAreEmpty
              || !currentGrid().isEmptyAutoRepeatTrack(direction: direction, line: UInt32(i))
            {
              gapAccumulator += gap
            }
          }
          positions[i] += gapAccumulator - offsetAccumulator
        }
        positions[lastLine] += gapAccumulator - offsetAccumulator
      }
    }
  }

  private func logicalOffsetForOutOfFlowGridItem(
    gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection, trackBreadth: LayoutUnit
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func gridAreaPositionForOutOfFlowGridItem(
    gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
  ) -> (LayoutUnit, LayoutUnit) {
    assert(gridItem.isOutOfFlowPositioned())
    let trackBreadth = GridLayoutFunctions.overridingContainingBlockContentSizeForGridItem(
      gridItem: gridItem, direction: direction)!!
    let isRowAxis = direction == .ForColumns
    let outOfFlowItemLine = isRowAxis ? outOfFlowItemColumn : outOfFlowItemRow
    var start = isRowAxis ? borderStart() : borderBefore()
    if let line = outOfFlowItemLine[CPtrToInt(gridItem.p)] {
      let positions = isRowAxis ? ArraySlice(columnPositions) : ArraySlice(rowPositions)
      start = positions[Int(line)]
    }
    start += logicalOffsetForOutOfFlowGridItem(
      gridItem: gridItem, direction: direction, trackBreadth: trackBreadth)
    return (start, start + trackBreadth)
  }

  private func gridAreaPositionForInFlowGridItem(
    gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
  ) -> (LayoutUnit, LayoutUnit) {
    assert(!gridItem.isOutOfFlowPositioned())
    let span = currentGrid().gridItemSpan(gridItem: gridItem, direction: direction)
    // FIXME (lajava): This is a common pattern, why not defining a function like
    // positions(direction) ?
    let positions =
      direction == .ForColumns ? ArraySlice(columnPositions) : ArraySlice(rowPositions)
    let start = positions[Int(span.startLine())]
    var end = positions[Int(span.endLine())]
    // The 'positions' vector includes distribution offset (because of content
    // alignment) and gutters, so we need to subtract them to get the actual
    // end position for a given track (this does not have to be done for the
    // last track as there are no more positions' elements after it, nor for
    // collapsed tracks).
    if span.endLine() < positions.count - 1
      && !(currentGrid().hasAutoRepeatEmptyTracks(direction: direction)
        && currentGrid().isEmptyAutoRepeatTrack(direction: direction, line: span.endLine()))
    {
      end -= gridGap(direction: direction) + gridItemOffset(direction: direction)
    }
    return (start, end)
  }

  private func gridAreaPositionForGridItem(
    gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
  ) -> (LayoutUnit, LayoutUnit) {
    if gridItem.isOutOfFlowPositioned() {
      return gridAreaPositionForOutOfFlowGridItem(gridItem: gridItem, direction: direction)
    }
    return gridAreaPositionForInFlowGridItem(gridItem: gridItem, direction: direction)
  }

  private func columnAxisPositionForGridItem(gridItem: RenderBoxWrapper) -> GridAxisPosition {
    let hasSameWritingMode = gridItem.style().writingMode() == style().writingMode()
    let gridItemIsLTR = gridItem.style().isLeftToRightDirection()
    if gridItem.isOutOfFlowPositioned()
      && !hasStaticPositionForGridItem(gridItem: gridItem, direction: .ForRows)
    {
      return .GridAxisStart
    }

    let gridItemAlignSelf = alignSelfForGridItem(gridItem: gridItem).position
    switch gridItemAlignSelf {
    case .SelfStart:
      // FIXME: Should we implement this logic in a generic utility function ?
      // Aligns the alignment subject to be flush with the edge of the alignment container
      // corresponding to the alignment subject's 'start' side in the column axis.
      if GridLayoutFunctions.isOrthogonalGridItem(grid: self, gridItem: gridItem) {
        // If orthogonal writing-modes, self-start will be based on the grid item's inline-axis
        // direction (inline-start), because it's the one parallel to the column axis.
        if style().isFlippedBlocksWritingMode() {
          return gridItemIsLTR ? .GridAxisEnd : .GridAxisStart
        }
        return gridItemIsLTR ? .GridAxisStart : .GridAxisEnd
      }
      // self-start is based on the grid item's block-flow direction. That's why we need to check against the grid container's block-flow direction.
      return hasSameWritingMode ? .GridAxisStart : .GridAxisEnd
    case .SelfEnd:
      // FIXME: Should we implement this logic in a generic utility function ?
      // Aligns the alignment subject to be flush with the edge of the alignment container
      // corresponding to the alignment subject's 'end' side in the column axis.
      if GridLayoutFunctions.isOrthogonalGridItem(grid: self, gridItem: gridItem) {
        // If orthogonal writing-modes, self-end will be based on the grid item's inline-axis
        // direction, (inline-end) because it's the one parallel to the column axis.
        if style().isFlippedBlocksWritingMode() {
          return gridItemIsLTR ? .GridAxisStart : .GridAxisEnd
        }
        return gridItemIsLTR ? .GridAxisEnd : .GridAxisStart
      }
      // self-end is based on the grid item's block-flow direction. That's why we need to check against the grid container's block-flow direction.
      return hasSameWritingMode ? .GridAxisEnd : .GridAxisStart
    case .Left:
      // Aligns the alignment subject to be flush with the alignment container's 'line-left' edge.
      // The alignment axis (column axis) is always orthogonal to the inline axis, hence this value behaves as 'start'.
      return .GridAxisStart
    case .Right:
      // Aligns the alignment subject to be flush with the alignment container's 'line-right' edge.
      // The alignment axis (column axis) is always orthogonal to the inline axis, hence this value behaves as 'start'.
      return .GridAxisStart
    case .Center:
      return .GridAxisCenter
    case .FlexStart,  // Only used in flex layout, otherwise equivalent to 'start'.
      // Aligns the alignment subject to be flush with the alignment container's 'start' edge (block-start) in the column axis.
      .Start:
      return .GridAxisStart
    case .FlexEnd,  // Only used in flex layout, otherwise equivalent to 'start'.
      // Aligns the alignment subject to be flush with the alignment container's 'start' edge (block-start) in the column axis.
      .End:
      return .GridAxisEnd
    case .Stretch:
      return .GridAxisStart
    case .Baseline, .LastBaseline:
      if GridLayoutFunctions.isOrthogonalGridItem(grid: self, gridItem: gridItem) {
        return gridItemAlignSelf == .Baseline ? .GridAxisStart : .GridAxisEnd
      }
      return RenderGridWrapper.fallbackAlignment(
        gridItemAlignSelf: gridItemAlignSelf, hasSameWritingMode: hasSameWritingMode)
    case .Legacy, .Auto, .Normal:
      break
    }

    fatalError("Not reached")
  }

  private static func fallbackAlignment(gridItemAlignSelf: ItemPosition, hasSameWritingMode: Bool)
    -> GridAxisPosition
  {
    if gridItemAlignSelf == .Baseline {
      return hasSameWritingMode ? .GridAxisStart : .GridAxisEnd
    }
    return hasSameWritingMode ? .GridAxisEnd : .GridAxisStart
  }

  private func rowAxisPositionForGridItem(gridItem: RenderBoxWrapper) -> GridAxisPosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func columnAxisOffsetForGridItem(gridItem: RenderBoxWrapper) -> LayoutUnit {
    let (startOfRow, endOfRow) = gridAreaPositionForGridItem(
      gridItem: gridItem, direction: .ForRows)
    let startPosition = startOfRow + marginBeforeForChild(child: gridItem)
    let columnAxisGridItemSize =
      GridLayoutFunctions.isOrthogonalGridItem(grid: self, gridItem: gridItem)
      ? gridItem.logicalWidth() + gridItem.marginLogicalWidth()
      : gridItem.logicalHeight() + gridItem.marginLogicalHeight()
    let masonryOffset =
      areMasonryRows()
      ? masonryLayout!.offsetForGridItem(gridItem: gridItem) : LayoutUnit(value: UInt64(0))
    let overflow = alignSelfForGridItem(gridItem: gridItem).overflow
    let offsetFromStartPosition = computeOverflowAlignmentOffset(
      overflow: overflow, trackSize: endOfRow - startOfRow, gridItemSize: columnAxisGridItemSize)
    if hasAutoMarginsInColumnAxis(gridItem: gridItem) {
      return startPosition
    }
    let axisPosition = columnAxisPositionForGridItem(gridItem: gridItem)
    switch axisPosition {
    case .GridAxisStart:
      return startPosition + columnAxisBaselineOffsetForGridItem(gridItem: gridItem) + masonryOffset
    case .GridAxisEnd:
      return (startPosition + offsetFromStartPosition)
        - columnAxisBaselineOffsetForGridItem(gridItem: gridItem)
    case .GridAxisCenter:
      return startPosition + (offsetFromStartPosition / 2)
    }
  }

  private func rowAxisOffsetForGridItem(gridItem: RenderBoxWrapper) -> LayoutUnit {
    let (startOfColumn, endOfColumn) = gridAreaPositionForGridItem(
      gridItem: gridItem, direction: .ForColumns)
    let startPosition = startOfColumn + marginStartForChild(child: gridItem)
    let masonryOffset =
      areMasonryColumns()
      ? masonryLayout!.offsetForGridItem(gridItem: gridItem) : LayoutUnit(value: UInt64(0))
    if hasAutoMarginsInRowAxis(gridItem: gridItem) {
      return startPosition
    }
    let axisPosition = rowAxisPositionForGridItem(gridItem: gridItem)
    switch axisPosition {
    case .GridAxisStart:
      return startPosition + rowAxisBaselineOffsetForGridItem(gridItem: gridItem) + masonryOffset
    case .GridAxisEnd, .GridAxisCenter:
      let rowAxisGridItemSize =
        GridLayoutFunctions.isOrthogonalGridItem(grid: self, gridItem: gridItem)
        ? gridItem.logicalHeight() + gridItem.marginLogicalHeight()
        : gridItem.logicalWidth() + gridItem.marginLogicalWidth()
      let overflow = justifySelfForGridItem(gridItem: gridItem).overflow
      let offsetFromStartPosition = computeOverflowAlignmentOffset(
        overflow: overflow, trackSize: endOfColumn - startOfColumn,
        gridItemSize: rowAxisGridItemSize)
      return startPosition
        + (axisPosition == .GridAxisEnd ? offsetFromStartPosition : offsetFromStartPosition / 2)
    }
  }

  private func computeContentPositionAndDistributionOffset(
    direction: GridTrackSizingDirection, availableFreeSpace: LayoutUnit, numberOfGridTracks: UInt32
  ) -> ContentAlignmentData {
    let isRowAxis = direction == .ForColumns
    if isRowAxis ? isSubgridColumns() : isSubgridRows() {
      return ContentAlignmentData()
    }

    let contentAlignmentData = contentAlignment(direction: direction)
    let contentAlignmentDistribution = contentAlignmentData.distribution
    let zero = LayoutUnit(value: UInt64(0))

    // Apply <content-distribution> and return, or continue to fallback positioning if we can't distribute.
    if contentAlignmentDistribution != .Default && availableFreeSpace > 0 {
      switch contentAlignmentDistribution {
      case .SpaceBetween:
        if numberOfGridTracks < 2 {
          break
        }
        return ContentAlignmentData(
          positionOffset: zero, distributionOffset: availableFreeSpace / (numberOfGridTracks - 1))
      case .SpaceAround:
        if numberOfGridTracks < 1 {
          break
        }
        let spaceBetweenTracks = availableFreeSpace / numberOfGridTracks
        return ContentAlignmentData(
          positionOffset: spaceBetweenTracks / 2, distributionOffset: spaceBetweenTracks)
      case .SpaceEvenly:
        let spaceEvenlyDistribution = availableFreeSpace / (numberOfGridTracks + 1)
        return ContentAlignmentData(
          positionOffset: spaceEvenlyDistribution, distributionOffset: spaceEvenlyDistribution)
      case .Stretch:
        break
      case .Default:
        fatalError("Not reached")
      }
    }

    let (fallbackOverflow, fallbackContentPosition) = resolveContentDistributionFallback(
      distribution: contentAlignmentDistribution)
    let contentAlignmentOverflow = contentAlignmentData.overflow

    // Apply alignment safety.
    if availableFreeSpace <= Int32(0)
      && (contentAlignmentOverflow == .Safe || fallbackOverflow == .Safe)
    {
      return ContentAlignmentData()
    }

    let usedContentPosition =
      contentAlignmentDistribution == .Default
      ? contentAlignmentData.position : fallbackContentPosition
    // Apply <content-position> / fallback positioning.
    switch usedContentPosition {
    case .Left:
      assert(isRowAxis)
      if !style().isLeftToRightDirection() {
        return ContentAlignmentData(positionOffset: availableFreeSpace, distributionOffset: zero)
      }
      return ContentAlignmentData()
    case .Right:
      assert(isRowAxis)
      if style().isLeftToRightDirection() {
        return ContentAlignmentData(positionOffset: availableFreeSpace, distributionOffset: zero)
      }
      return ContentAlignmentData()
    case .Center:
      return ContentAlignmentData(positionOffset: availableFreeSpace / 2, distributionOffset: zero)
    case .FlexEnd,  // Only used in flex layout, for other layout, it's equivalent to 'end'.
      .End:
      return ContentAlignmentData(positionOffset: availableFreeSpace, distributionOffset: zero)
    case .FlexStart,  // Only used in flex layout, for other layout, it's equivalent to 'start'.
      .Start, .Baseline, .LastBaseline:
      // FIXME: Implement the baseline values. For now, we always 'start' align.
      // http://webkit.org/b/145566
      return ContentAlignmentData()
    case .Normal:
      fatalError("Not reached")
    }
  }

  // FIXME: SetLogicalPositionForGridItem has only one caller, consider its refactoring in the future.
  private func setLogicalPositionForGridItem(gridItem: RenderBoxWrapper) {
    // "In the positioning phase [...] calculations are performed according to the writing mode of the containing block of the box establishing the
    // orthogonal flow." However, 'setLogicalLocation' will only take into account the grid item's writing-mode, so the position may need to be transposed.
    let gridItemLocation = LayoutPointWrapper(
      x: logicalOffsetForGridItem(gridItem: gridItem, direction: .ForColumns),
      y: logicalOffsetForGridItem(gridItem: gridItem, direction: .ForRows))
    gridItem.setLogicalLocation(
      location: GridLayoutFunctions.isOrthogonalGridItem(grid: self, gridItem: gridItem)
        ? gridItemLocation.transposedPoint() : gridItemLocation)
  }

  private func logicalOffsetForGridItem(
    gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
  ) -> LayoutUnit {
    if direction == .ForRows {
      return columnAxisOffsetForGridItem(gridItem: gridItem)
    }
    var rowAxisOffset = rowAxisOffsetForGridItem(gridItem: gridItem)
    // We stored m_columnPositions's data ignoring the direction, hence we might need now
    // to translate positions from RTL to LTR, as it's more convenient for painting.
    if !style().isLeftToRightDirection() {
      rowAxisOffset =
        translateRTLCoordinate(coordinate: rowAxisOffset)
        - (GridLayoutFunctions.isOrthogonalGridItem(grid: self, gridItem: gridItem)
          ? gridItem.logicalHeight() : gridItem.logicalWidth())
    }
    return rowAxisOffset
  }

  private func gridAreaBreadthForGridItemIncludingAlignmentOffsets(
    gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
  ) -> LayoutUnit {
    if direction == .ForRows {
      if areMasonryRows() {
        return isHorizontalWritingMode()
          ? gridItem.height() + gridItem.verticalMarginExtent()
          : gridItem.width() + gridItem.horizontalMarginExtent()
      }
    } else if areMasonryColumns() {
      return isHorizontalWritingMode()
        ? gridItem.width() + gridItem.horizontalMarginExtent()
        : gridItem.height() + gridItem.verticalMarginExtent()
    }

    // We need the cached value when available because Content Distribution alignment properties
    // may have some influence in the final grid area breadth.
    let tracks = trackSizingAlgorithm!.tracks(direction: direction)
    let span = currentGrid().gridItemSpan(gridItem: gridItem, direction: direction)
    let linePositions =
      (direction == .ForColumns) ? ArraySlice(columnPositions) : ArraySlice(rowPositions)

    let initialTrackPosition = linePositions[Int(span.startLine())]
    let finalTrackPosition = linePositions[Int(span.endLine() - 1)]

    // Track Positions vector stores the 'start' grid line of each track, so we have to add last track's baseSize.
    return finalTrackPosition - initialTrackPosition + tracks[Int(span.endLine() - 1)].baseSize()
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

  private func availableAlignmentSpaceForGridItemBeforeStretching(
    gridAreaBreadthForGridItem: LayoutUnit, gridItem: RenderBoxWrapper,
    direction: GridTrackSizingDirection
  ) -> LayoutUnit {
    // Because we want to avoid multiple layouts, stretching logic might be performed before
    // grid items are laid out, so we can't use the grid item cached values. Hence, we need to
    // compute margins in order to determine the available height before stretching.
    let gridItemFlowDirection = GridLayoutFunctions.flowAwareDirectionForGridItem(
      grid: self, gridItem: gridItem, direction: direction)
    return max(
      LayoutUnit(value: UInt64(0)),
      gridAreaBreadthForGridItem
        - GridLayoutFunctions.marginLogicalSizeForGridItem(
          grid: self, direction: gridItemFlowDirection, gridItem: gridItem))
  }

  private func justifySelfForGridItem(
    gridItem: RenderBoxWrapper, stretchingMode: StretchingMode = .Any,
    gridStyle: RenderStyleWrapper? = nil
  ) -> StyleSelfAlignmentData {
    if let renderGrid = gridItem as? RenderGridWrapper,
      renderGrid.isSubgridInParentDirection(parentDirection: .ForColumns)
    {
      return StyleSelfAlignmentData(position: .Stretch, overflow: .Default)
    }
    let gridStyle = gridStyle ?? style()
    let normalBehavior =
      stretchingMode == .Any ? selfAlignmentNormalBehavior(gridItem: gridItem) : .Normal
    return gridItem.style().resolvedJustifySelf(
      parentStyle: gridStyle, normalValueBehaviour: normalBehavior)
  }

  private func alignSelfForGridItem(
    gridItem: RenderBoxWrapper, stretchingMode: StretchingMode = .Any,
    gridStyle: RenderStyleWrapper? = nil
  ) -> StyleSelfAlignmentData {
    if let renderGrid = gridItem as? RenderGridWrapper,
      renderGrid.isSubgridInParentDirection(parentDirection: .ForRows)
    {
      return StyleSelfAlignmentData(position: .Stretch, overflow: .Default)
    }
    let gridStyle = gridStyle ?? style()
    let normalBehavior =
      stretchingMode == .Any ? selfAlignmentNormalBehavior(gridItem: gridItem) : .Normal
    return gridItem.style().resolvedAlignSelf(
      parentStyle: gridStyle, normalValueBehaviour: normalBehavior)
  }

  // FIXME: This logic is shared by RenderFlexibleBox, so it should be moved to RenderBox.
  private func applyStretchAlignmentToGridItemIfNeeded(
    gridItem: RenderBoxWrapper, gridLayoutState: inout GridLayoutState
  ) {
    assert(gridItem.overridingContainingBlockContentLogicalHeight() != nil)
    assert(gridItem.overridingContainingBlockContentLogicalWidth() != nil)

    // We clear height and width override values because we will decide now whether it's allowed or
    // not, evaluating the conditions which might have changed since the old values were set.
    gridItem.clearOverridingLogicalHeight()
    gridItem.clearOverridingLogicalWidth()

    let gridItemBlockDirection = GridLayoutFunctions.flowAwareDirectionForGridItem(
      grid: self, gridItem: gridItem, direction: .ForRows)
    let gridItemInlineDirection = GridLayoutFunctions.flowAwareDirectionForGridItem(
      grid: self, gridItem: gridItem, direction: .ForColumns)
    let blockFlowIsColumnAxis = gridItemBlockDirection == .ForRows
    let allowedToStretchgridItemBlockSize =
      blockFlowIsColumnAxis
      ? allowedToStretchGridItemAlongColumnAxis(gridItem: gridItem)
      : allowedToStretchGridItemAlongRowAxis(gridItem: gridItem)
    if allowedToStretchgridItemBlockSize
      && !aspectRatioPrefersInline(gridItem: gridItem, blockFlowIsColumnAxis: blockFlowIsColumnAxis)
    {
      let overridingContainingBlockContentSizeForGridItem =
        GridLayoutFunctions.overridingContainingBlockContentSizeForGridItem(
          gridItem: gridItem, direction: gridItemBlockDirection)
      assert(
        overridingContainingBlockContentSizeForGridItem != nil
          && overridingContainingBlockContentSizeForGridItem! != nil)
      let stretchedLogicalHeight = availableAlignmentSpaceForGridItemBeforeStretching(
        gridAreaBreadthForGridItem: overridingContainingBlockContentSizeForGridItem!!,
        gridItem: gridItem, direction: .ForRows)
      let desiredLogicalHeight = gridItem.constrainLogicalHeightByMinMax(
        logicalHeight: stretchedLogicalHeight, intrinsicContentHeight: nil)
      gridItem.setOverridingLogicalHeight(height: desiredLogicalHeight)

      let itemNeedsRelayoutForStretchAlignment = itemNeedsRelayoutForStretchAlignment(
        desiredLogicalHeight: desiredLogicalHeight, gridItem: gridItem,
        gridLayoutState: gridLayoutState)
      // Checking the logical-height of a grid item isn't enough. Setting an override logical-height
      // changes the definiteness, resulting in percentages to resolve differently.
      //
      // FIXME: Can avoid laying out here in some cases. See https://webkit.org/b/87905.
      if itemNeedsRelayoutForStretchAlignment {
        gridItem.setLogicalHeight(size: LayoutUnit(value: UInt64(0)))
        gridItem.setNeedsLayout(markParents: .MarkOnlyThis)
      }
    } else if !allowedToStretchgridItemBlockSize
      && allowedToStretchGridItemAlongRowAxis(gridItem: gridItem)
    {
      let overridingContainingBlockContentSizeForGridItem =
        GridLayoutFunctions.overridingContainingBlockContentSizeForGridItem(
          gridItem: gridItem, direction: gridItemInlineDirection)
      assert(
        overridingContainingBlockContentSizeForGridItem != nil
          && overridingContainingBlockContentSizeForGridItem != nil)
      let stretchedLogicalWidth = availableAlignmentSpaceForGridItemBeforeStretching(
        gridAreaBreadthForGridItem: overridingContainingBlockContentSizeForGridItem!!,
        gridItem: gridItem, direction: .ForColumns)
      let desiredLogicalWidth = gridItem.constrainLogicalWidthInFragmentByMinMax(
        logicalWidth: stretchedLogicalWidth, availableWidth: contentWidth(), cb: self, fragment: nil
      )
      gridItem.setOverridingLogicalWidth(width: desiredLogicalWidth)
      if desiredLogicalWidth != gridItem.logicalWidth() {
        gridItem.setNeedsLayout(markParents: .MarkOnlyThis)
      }
    }
  }

  private func itemNeedsRelayoutForStretchAlignment(
    desiredLogicalHeight: LayoutUnit, gridItem: RenderBoxWrapper, gridLayoutState: GridLayoutState
  ) -> Bool {
    if desiredLogicalHeight != gridItem.logicalHeight() {
      return true
    }

    if canSetColumnAxisStretchRequirementForItem(gridItem: gridItem) {
      return gridLayoutState.containsLayoutRequirementForGridItem(
        gridItem: gridItem, layoutRequirement: .NeedsColumnAxisStretchAlignment)
    }

    return gridItem is RenderBlockWrapper
      && (gridItem as! RenderBlockWrapper).hasPercentHeightDescendants()
  }

  private func applySubgridStretchAlignmentToGridItemIfNeeded(gridItem: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func hasAutoSizeInColumnAxis(gridItem: RenderBoxWrapper) -> Bool {
    if gridItem.style().hasAspectRatio() {
      // FIXME: should align-items + align-self: auto/justify-items + justify-self: auto be taken into account?
      if isHorizontalWritingMode() == gridItem.isHorizontalWritingMode()
        && gridItem.style().alignSelf().position != .Stretch
      {
        // A non-auto inline size means the same for block size (column axis size) because of the aspect ratio.
        if !gridItem.style().logicalWidth().isAuto() {
          return false
        }
      } else if gridItem.style().justifySelf().position != .Stretch {
        let logicalHeight = gridItem.style().logicalHeight()
        if logicalHeight.isFixed()
          || (logicalHeight.isPercentOrCalculated()
            && gridItem.percentageLogicalHeightIsResolvable())
        {
          return false
        }
      }
    }
    return isHorizontalWritingMode()
      ? gridItem.style().height().isAuto() : gridItem.style().width().isAuto()
  }

  private func hasAutoSizeInRowAxis(gridItem: RenderBoxWrapper) -> Bool {
    if gridItem.style().hasAspectRatio() {
      // FIXME: should align-items + align-self: auto/justify-items + justify-self: auto be taken into account?
      if isHorizontalWritingMode() == gridItem.isHorizontalWritingMode()
        && gridItem.style().justifySelf().position != .Stretch
      {
        // A non-auto block size means the same for inline size (row axis size) because of the aspect ratio.
        let logicalHeight = gridItem.style().logicalHeight()
        if logicalHeight.isFixed()
          || (logicalHeight.isPercentOrCalculated()
            && gridItem.percentageLogicalHeightIsResolvable())
        {
          return false
        }
      } else if gridItem.style().alignSelf().position != .Stretch {
        if !gridItem.style().logicalWidth().isAuto() {
          return false
        }
      }
    }
    return isHorizontalWritingMode()
      ? gridItem.style().width().isAuto() : gridItem.style().height().isAuto()
  }

  private func allowedToStretchGridItemAlongColumnAxis(gridItem: RenderBoxWrapper) -> Bool {
    return alignSelfForGridItem(gridItem: gridItem).position == .Stretch
      && hasAutoSizeInColumnAxis(gridItem: gridItem)
      && !hasAutoMarginsInColumnAxis(gridItem: gridItem)
  }

  private func allowedToStretchGridItemAlongRowAxis(gridItem: RenderBoxWrapper) -> Bool {
    return justifySelfForGridItem(gridItem: gridItem).position == .Stretch
      && hasAutoSizeInRowAxis(gridItem: gridItem) && !hasAutoMarginsInRowAxis(gridItem: gridItem)
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

  // FIXME: This logic is shared by RenderFlexibleBox, so it should be moved to RenderBox.
  private func updateAutoMarginsInColumnAxisIfNeeded(gridItem: RenderBoxWrapper) {
    assert(!gridItem.isOutOfFlowPositioned())

    let parentStyle = style()
    let marginBefore = gridItem.style().marginBeforeUsing(otherStyle: parentStyle)
    let marginAfter = gridItem.style().marginAfterUsing(otherStyle: parentStyle)
    var marginLogicalHeight = LayoutUnit()
    // We should only consider computed margins if their specified value isn't
    // 'auto', since such computed value may come from a previous layout and may
    // be incorrect now.
    if !marginBefore.isAuto() {
      marginLogicalHeight += gridItem.marginBefore()
    }
    if !marginAfter.isAuto() {
      marginLogicalHeight += gridItem.marginAfter()
    }

    let availableAlignmentSpace =
      gridItem.overridingContainingBlockContentLogicalHeight()!! - gridItem.logicalHeight()
      - marginLogicalHeight
    if availableAlignmentSpace <= Int32(0) {
      return
    }

    if marginBefore.isAuto() && marginAfter.isAuto() {
      gridItem.setMarginBefore(value: availableAlignmentSpace / 2, overrideStyle: parentStyle)
      gridItem.setMarginAfter(value: availableAlignmentSpace / 2, overrideStyle: parentStyle)
    } else if marginBefore.isAuto() {
      gridItem.setMarginBefore(value: availableAlignmentSpace, overrideStyle: parentStyle)
    } else if marginAfter.isAuto() {
      gridItem.setMarginAfter(value: availableAlignmentSpace, overrideStyle: parentStyle)
    }
  }

  // FIXME: This logic is shared by RenderFlexibleBox, so it should be moved to RenderBox.
  private func updateAutoMarginsInRowAxisIfNeeded(gridItem: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func columnAxisBaselineOffsetForGridItem(gridItem: RenderBoxWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func rowAxisBaselineOffsetForGridItem(gridItem: RenderBoxWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func nonCollapsedTracks(direction: GridTrackSizingDirection) -> UInt32 {
    let tracks = trackSizingAlgorithm!.tracks(direction: direction)
    let numberOfTracks = UInt32(tracks.count)
    let hasCollapsedTracks = currentGrid().hasAutoRepeatEmptyTracks(direction: direction)
    let numberOfCollapsedTracks =
      hasCollapsedTracks ? currentGrid().autoRepeatEmptyTracks(direction: direction).size() : 0
    return numberOfTracks - numberOfCollapsedTracks
  }

  private func translateRTLCoordinate(coordinate: LayoutUnit) -> LayoutUnit {
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

  private func aspectRatioPrefersInline(gridItem: RenderBoxWrapper, blockFlowIsColumnAxis: Bool)
    -> Bool
  {
    if !gridItem.style().hasAspectRatio() {
      return false
    }
    var hasExplicitInlineStretch =
      justifySelfForGridItem(gridItem: gridItem, stretchingMode: .Explicit).position == .Stretch
    var hasExplicitBlockStretch =
      alignSelfForGridItem(gridItem: gridItem, stretchingMode: .Explicit).position == .Stretch
    if !blockFlowIsColumnAxis {
      swap(&hasExplicitInlineStretch, &hasExplicitBlockStretch)
    }
    return !hasExplicitBlockStretch
  }

  private func computeAspectRatioDependentAndBaselineItems() -> [RenderBoxWrapper] {
    var dependentGridItems: [RenderBoxWrapper] = []

    baselineItemsCached = true
    hasAspectRatioBlockSizeDependentItem = false

    let computeOrthogonalAndDependentItems = { [self] (gridItem: RenderBoxWrapper) in
      // Grid's layout logic controls the grid item's override content size, hence we need to
      // clear any override set previously, so it doesn't interfere in current layout
      // execution.
      gridItem.clearOverridingContentSize()

      // For a grid item that has an aspect-ratio and block-constraints such as the relative logical height,
      // when the grid width is auto, we may need get the real grid width before laying out the item.
      if GridLayoutFunctions.isAspectRatioBlockSizeDependentGridItem(gridItem: gridItem)
        && (style().logicalWidth().isAuto() || style().logicalWidth().isMinContent()
          || style().logicalWidth().isMaxContent())
      {
        dependentGridItems.append(gridItem)
        hasAspectRatioBlockSizeDependentItem = true
      }
    }

    cacheBaselineAlignedGridItems(
      grid: self, algorithm: trackSizingAlgorithm!, axes: [.GridRowAxis, .GridColumnAxis],
      callback: computeOrthogonalAndDependentItems, cachingRowSubgridsForRootGrid: !isSubgridRows())
    return dependentGridItems
  }

  // Masonry Spec Section 2.3.1 repeat(auto-fit)
  // "repeat(auto-fit) behaves as repeat(auto-fill) when the other axis is a masonry axis."
  // We need to lie here that we are really an auto-fill instead of an auto-fit.
  func autoRepeatColumnsType() -> AutoRepeatType {
    let autoRepeatColumns = style().gridAutoRepeatColumnsType()

    if areMasonryRows() && autoRepeatColumns == .Fit {
      return .Fill
    }

    return autoRepeatColumns
  }

  func autoRepeatRowsType() -> AutoRepeatType {
    let autoRepeatRow = style().gridAutoRepeatRowsType()

    if areMasonryColumns() && autoRepeatRow == .Fit {
      return .Fill
    }

    return autoRepeatRow
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

  private var offsetBetweenColumns = ContentAlignmentData()
  private var offsetBetweenRows = ContentAlignmentData()

  private let masonryLayout: GridMasonryLayout? = nil

  private typealias OutOfFlowPositionsMap = [UInt: UInt64]
  private var outOfFlowItemColumn = OutOfFlowPositionsMap()
  private var outOfFlowItemRow = OutOfFlowPositionsMap()

  private var hasAspectRatioBlockSizeDependentItem = false
  private var baselineItemsCached = false
}
