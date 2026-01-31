/*
 * Copyright (C) 2017 Igalia S.L.
 * Copyright (C) 2024 Apple Inc. All rights reserved.
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

private let infinity: Int32 = -1

enum SizingOperation {
  case TrackSizing
  case IntrinsicSizeComputation
}

private enum TrackSizeComputationVariant {
  case NotCrossingFlexibleTracks
  case CrossingFlexibleTracks
}

private enum TrackSizeComputationPhase {
  case ResolveIntrinsicMinimums
  case ResolveContentBasedMinimums
  case ResolveMaxContentMinimums
  case ResolveIntrinsicMaximums
  case ResolveMaxContentMaximums
  case MaximizeTracks
}

private enum SpaceDistributionLimit {
  case UpToGrowthLimit
  case BeyondGrowthLimit
}

class GridTrack {
  func baseSize() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func unclampedBaseSize() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setBaseSize(_ baseSize: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func growthLimit() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func growthLimitIsInfinite() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setGrowthLimit(growthLimit: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func infiniteGrowthPotential() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func growthLimitIfNotInfinite() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func plannedSize() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setPlannedSize(plannedSize: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func tempSize() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTempSize(tempSize: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func growTempSize(_ tempSize: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func infinitelyGrowable() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setInfinitelyGrowable(infinitelyGrowable: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func cachedTrackSize() -> GridTrackSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setCachedTrackSize(cachedTrackSize: GridTrackSize) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var growthLimitCap: LayoutUnit? = nil
}

// Private helper methods.

private func gridAxisForDirection(direction: GridTrackSizingDirection) -> GridAxis {
  return direction == .ForColumns ? .GridRowAxis : .GridColumnAxis
}

private func gridDirectionForAxis(axis: GridAxis) -> GridTrackSizingDirection {
  return axis == .GridRowAxis ? .ForColumns : .ForRows
}

private func hasRelativeMarginOrPaddingForGridItem(
  _ gridItem: RenderBoxWrapper, _ direction: GridTrackSizingDirection
) -> Bool {
  if direction == .ForColumns {
    return gridItem.style().marginStart().isPercentOrCalculated()
      || gridItem.style().marginEnd().isPercentOrCalculated()
      || gridItem.style().paddingStart().isPercentOrCalculated()
      || gridItem.style().paddingEnd().isPercentOrCalculated()
  }
  return gridItem.style().marginBefore().isPercentOrCalculated()
    || gridItem.style().marginAfter().isPercentOrCalculated()
    || gridItem.style().paddingBefore().isPercentOrCalculated()
    || gridItem.style().paddingAfter().isPercentOrCalculated()
}

private func hasRelativeOrIntrinsicSizeForGridItem(
  _ gridItem: RenderBoxWrapper, _ direction: GridTrackSizingDirection
) -> Bool {
  if direction == .ForColumns {
    return gridItem.hasRelativeLogicalWidth() || gridItem.style().logicalWidth().isIntrinsicOrAuto()
  }
  return gridItem.hasRelativeLogicalHeight() || gridItem.style().logicalHeight().isIntrinsicOrAuto()
}

private func shouldClearOverridingContainingBlockContentSizeForGridItem(
  _ gridItem: RenderBoxWrapper, _ direction: GridTrackSizingDirection
) -> Bool {
  return hasRelativeOrIntrinsicSizeForGridItem(gridItem, direction)
    || hasRelativeMarginOrPaddingForGridItem(gridItem, direction)
}

private func setOverridingContainingBlockContentSizeForGridItem(
  _ grid: RenderGridWrapper, _ gridItem: RenderBoxWrapper, _ direction: GridTrackSizingDirection,
  _ size: LayoutUnit?
) {
  var direction = direction
  // This function sets the dimension based on the writing mode of the containing block.
  // For subgrids, this might not be the outermost grid, but could be a subgrid. If the
  // writing mode of the CB and the grid for which we're doing sizing don't match, swap
  // the directions.
  direction = GridLayoutFunctions.flowAwareDirectionForGridItem(
    grid: grid, gridItem: gridItem.containingBlock()!, direction: direction)
  if direction == .ForColumns {
    gridItem.setOverridingContainingBlockContentLogicalWidth(logicalWidth: size)
  } else {
    gridItem.setOverridingContainingBlockContentLogicalHeight(logicalHeight: size)
  }
}

struct GridItemWithSpan: Comparable, Equatable {
  let gridItem: RenderBoxWrapper
  let span: GridSpan

  static func < (this: GridItemWithSpan, other: GridItemWithSpan) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func == (this: GridItemWithSpan, other: GridItemWithSpan) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

struct GridItemsSpanGroupRange {
  let rangeStart: Int
  let rangeEnd: Int
  let span: ArraySlice<GridItemWithSpan>
}

private enum TrackSizeRestriction {
  case AllowInfinity
  case ForbidInfinity
}

private func shouldProcessTrackForTrackSizeComputationPhase(
  phase: TrackSizeComputationPhase, trackSize: GridTrackSize
) -> Bool {
  switch phase {
  case .ResolveIntrinsicMinimums:
    return trackSize.hasIntrinsicMinTrackBreadth()
  case .ResolveContentBasedMinimums:
    return trackSize.hasMinOrMaxContentMinTrackBreadth()
  case .ResolveMaxContentMinimums:
    return trackSize.hasMaxContentMinTrackBreadth()
  case .ResolveIntrinsicMaximums:
    return trackSize.hasIntrinsicMaxTrackBreadth()
  case .ResolveMaxContentMaximums:
    return trackSize.hasMaxContentOrAutoMaxTrackBreadth()
  case .MaximizeTracks:
    fatalError("Not reached")
  }
}

private func trackSizeForTrackSizeComputationPhase(
  _ phase: TrackSizeComputationPhase, _ track: GridTrack, _ restriction: TrackSizeRestriction
) -> LayoutUnit {
  switch phase {
  case .ResolveIntrinsicMinimums, .ResolveContentBasedMinimums, .ResolveMaxContentMinimums,
    .MaximizeTracks:
    return track.baseSize()
  case .ResolveIntrinsicMaximums, .ResolveMaxContentMaximums:
    return restriction == .AllowInfinity ? track.growthLimit() : track.growthLimitIfNotInfinite()
  }
}

private func updateTrackSizeForTrackSizeComputationPhase(
  _ phase: TrackSizeComputationPhase, _ track: GridTrack
) {
  switch phase {
  case .ResolveIntrinsicMinimums, .ResolveContentBasedMinimums, .ResolveMaxContentMinimums:
    track.setBaseSize(track.plannedSize())
  case .ResolveIntrinsicMaximums, .ResolveMaxContentMaximums:
    track.setGrowthLimit(growthLimit: track.plannedSize())
  case .MaximizeTracks:
    fatalError("Not reached")
  }
}

private func trackShouldGrowBeyondGrowthLimitsForTrackSizeComputationPhase(
  phase: TrackSizeComputationPhase, trackSize: GridTrackSize
) -> Bool {
  switch phase {
  case .ResolveIntrinsicMinimums, .ResolveContentBasedMinimums:
    return trackSize.hasAutoOrMinContentMinTrackBreadthAndIntrinsicMaxTrackBreadth()
  case .ResolveMaxContentMinimums:
    return trackSize.hasMaxContentMinTrackBreadthAndMaxContentMaxTrackBreadth()
  case .ResolveIntrinsicMaximums, .ResolveMaxContentMaximums:
    return true
  case .MaximizeTracks:
    fatalError("Not reached")
  }
}

private func markAsInfinitelyGrowableForTrackSizeComputationPhase(
  _ phase: TrackSizeComputationPhase, _ track: GridTrack
) {
  switch phase {
  case .ResolveIntrinsicMinimums, .ResolveContentBasedMinimums, .ResolveMaxContentMinimums:
    return
  case .ResolveIntrinsicMaximums:
    if trackSizeForTrackSizeComputationPhase(phase, track, .AllowInfinity) == infinity
      && track.plannedSize() != infinity
    {
      track.setInfinitelyGrowable(infinitelyGrowable: true)
    }
  case .ResolveMaxContentMaximums:
    if track.infinitelyGrowable() {
      track.setInfinitelyGrowable(infinitelyGrowable: false)
    }
  case .MaximizeTracks:
    fatalError("Not reached")
  }
}

private func getSizeDistributionWeight(_ variant: TrackSizeComputationVariant, _ track: GridTrack)
  -> Float64
{
  if variant != .CrossingFlexibleTracks {
    return 0
  }
  assert(track.cachedTrackSize().maxTrackBreadth.isFlex())
  return track.cachedTrackSize().maxTrackBreadth.flex()
}

private func sortByGridTrackGrowthPotential(_ track1: GridTrack, _ track2: GridTrack) -> Bool {
  // This check ensures that we respect the irreflexivity property of the strict weak ordering required by std::sort
  // (forall x: NOT x < x).
  let track1HasInfiniteGrowthPotentialWithoutCap =
    track1.infiniteGrowthPotential() && track1.growthLimitCap == nil
  let track2HasInfiniteGrowthPotentialWithoutCap =
    track2.infiniteGrowthPotential() && track2.growthLimitCap == nil

  if track1HasInfiniteGrowthPotentialWithoutCap && track2HasInfiniteGrowthPotentialWithoutCap {
    return false
  }

  if track1HasInfiniteGrowthPotentialWithoutCap || track2HasInfiniteGrowthPotentialWithoutCap {
    return track2HasInfiniteGrowthPotentialWithoutCap
  }

  let track1Limit = track1.growthLimitCap ?? track1.growthLimit()
  let track2Limit = track2.growthLimitCap ?? track2.growthLimit()
  return (track1Limit - track1.baseSize()) < (track2Limit - track2.baseSize())
}

private class GridTrackArrayRef {
  var a: [GridTrack] = []
}

private func clampGrowthShareIfNeeded(
  _ phase: TrackSizeComputationPhase, _ track: GridTrack, _ growthShare: inout LayoutUnit
) {
  if phase != .ResolveMaxContentMaximums || track.growthLimitCap == nil {
    return
  }

  let distanceToCap = track.growthLimitCap! - track.tempSize()
  if distanceToCap <= Int32(0) {
    return
  }

  growthShare = min(growthShare, distanceToCap)
}

private func distributeItemIncurredIncreaseToTrack(
  _ phase: TrackSizeComputationPhase, _ limit: SpaceDistributionLimit, _ track: GridTrack,
  _ freeSpace: inout LayoutUnit, _ shareFraction: Float64
) {
  let freeSpaceShare = LayoutUnit(value: freeSpace / shareFraction)
  var growthShare =
    limit == .BeyondGrowthLimit || track.infiniteGrowthPotential()
    ? freeSpaceShare
    : min(
      freeSpaceShare,
      track.growthLimit() - trackSizeForTrackSizeComputationPhase(phase, track, .ForbidInfinity))
  clampGrowthShareIfNeeded(phase, track, &growthShare)
  assert(
    growthShare >= Int32(0),
    "We must never shrink any grid track or else we can't guarantee we abide by our min-sizing function."
  )
  track.growTempSize(growthShare)
  freeSpace -= growthShare
}

private func distributeItemIncurredIncreases(
  variant: TrackSizeComputationVariant, phase: TrackSizeComputationPhase,
  limit: SpaceDistributionLimit, tracks: GridTrackArrayRef, freeSpace: inout LayoutUnit
) {
  let tracksSize = tracks.a.count
  if tracksSize == 0 {
    return
  }
  if variant == .NotCrossingFlexibleTracks {
    // We have to sort tracks according to their growth potential. This is necessary even when distributing beyond growth limits,
    // because there might be tracks with growth limit caps (like the ones with fit-content()) which cannot indefinitely grow over the limits.
    tracks.a.sort(by: sortByGridTrackGrowthPotential)
    for (i, track) in tracks.a.enumerated() {
      assert(getSizeDistributionWeight(variant, track) == 0)
      distributeItemIncurredIncreaseToTrack(
        phase, limit, track, &freeSpace, Float64(tracksSize - i))
    }
    return
  }
  // We never grow flex tracks beyond growth limits, since they are infinite.
  assert(limit != .BeyondGrowthLimit)
  // For TrackSizeComputationVariant::CrossingFlexibleTracks we don't distribute equally, we need to take the weights into account.
  var fractionsOfRemainingSpace = [Float64](repeating: 0, count: tracksSize)
  var weightSum: Float64 = 0
  for i in (0..<tracksSize).reversed() {
    let weight = getSizeDistributionWeight(variant, tracks.a[i])
    weightSum += weight
    fractionsOfRemainingSpace[i] = weightSum > 0 ? weightSum / weight : Float64(tracksSize - i)
  }
  for (track, fractionOfRemainingSpace) in zip(tracks.a, fractionsOfRemainingSpace) {
    // Sorting is not needed for TrackSizeComputationVariant::CrossingFlexibleTracks, since all tracks have an infinite growth potential.
    assert(track.growthLimitIsInfinite())
    distributeItemIncurredIncreaseToTrack(phase, limit, track, &freeSpace, fractionOfRemainingSpace)
  }
}

private func computeGridSpanSize(
  tracks: ArraySlice<GridTrack>, gridSpan: GridSpan, gridItemOffset: LayoutUnit?,
  totalGuttersSize: LayoutUnit
) -> LayoutUnit {
  var totalTracksSize = LayoutUnit()
  for trackPosition in gridSpan {
    totalTracksSize += tracks[Int(trackPosition)].baseSize()
  }
  return totalTracksSize + totalGuttersSize
    + (gridSpan.integerSpan() - 1) * (gridItemOffset ?? LayoutUnit(value: UInt64(0)))
}

private final class IndefiniteSizeStrategy: GridTrackSizingAlgorithmStrategy {
  override init(algorithm: GridTrackSizingAlgorithm) { super.init(algorithm: algorithm) }
}

private final class DefiniteSizeStrategy: GridTrackSizingAlgorithmStrategy {
  override init(algorithm: GridTrackSizingAlgorithm) { super.init(algorithm: algorithm) }
}

private func marginAndBorderAndPaddingForEdge(
  _ grid: RenderGridWrapper, _ direction: GridTrackSizingDirection, _ startEdge: Bool
) -> LayoutUnit {
  if direction == .ForColumns {
    return startEdge ? grid.marginAndBorderAndPaddingStart() : grid.marginAndBorderAndPaddingEnd()
  }
  return startEdge ? grid.marginAndBorderAndPaddingBefore() : grid.marginAndBorderAndPaddingAfter()
}

// https://drafts.csswg.org/css-grid-2/#subgrid-edge-placeholders
// FIXME: This is a simplification of the specified behaviour, where we add the hypothetical
// items directly to the edge tracks as if they had a span of 1. This matches the current Gecko
// behavior.
private func computeSubgridMarginBorderPadding(
  _ outermost: RenderGridWrapper, _ outermostDirection: GridTrackSizingDirection,
  _ track: GridTrack, _ trackIndex: UInt32, _ span: GridSpan, _ subgrid: RenderGridWrapper
) -> LayoutUnit {
  // Convert the direction into the coordinate space of subgrid (which may not be a direct child
  // of the outermost grid for which we're running the track sizing algorithm).
  let direction = GridLayoutFunctions.flowAwareDirectionForGridItem(
    grid: outermost, gridItem: subgrid, direction: outermostDirection)
  let reversed = GridLayoutFunctions.isSubgridReversedDirection(
    grid: outermost, outerDirection: outermostDirection, subgrid: subgrid)

  var subgridMbp = LayoutUnit()
  if trackIndex == span.startLine() && track.cachedTrackSize().hasIntrinsicMinTrackBreadth() {
    // If the subgrid has a reversed flow direction relative to the outermost grid, then
    // we want the MBP from the end edge in its local coordinate space.
    subgridMbp = marginAndBorderAndPaddingForEdge(subgrid, direction, !reversed)
  }
  if trackIndex == span.endLine() - 1 && track.cachedTrackSize().hasIntrinsicMinTrackBreadth() {
    subgridMbp += marginAndBorderAndPaddingForEdge(subgrid, direction, reversed)
  }
  return subgridMbp
}

private func extraMarginFromSubgridAncestorGutters(
  _ gridItem: RenderBoxWrapper, _ itemSpan: GridSpan, _ trackIndex: UInt32,
  _ direction: GridTrackSizingDirection
) -> LayoutUnit? {
  if itemSpan.startLine() != trackIndex && itemSpan.endLine() - 1 != trackIndex {
    return nil
  }

  var gutterTotal = LayoutUnit(value: UInt64(0))

  var direction = direction
  for currentAncestorSubgrid in ancestorSubgridsOfGridItem(gridItem: gridItem, direction: direction)
  {
    let gridItemSpanInAncestor = currentAncestorSubgrid.gridSpanForGridItem(
      gridItem: gridItem, direction: direction)
    let numTracksForCurrentAncestor = currentAncestorSubgrid.numTracks(direction: direction)

    let currentAncestorSubgridParent = currentAncestorSubgrid.parent() as! RenderGridWrapper

    if gridItemSpanInAncestor.startLine() != 0 {
      gutterTotal +=
        (currentAncestorSubgrid.gridGap(direction: direction)
          - currentAncestorSubgridParent.gridGap(direction: direction))
        / 2
    }
    if itemSpan.endLine() != numTracksForCurrentAncestor {
      gutterTotal +=
        (currentAncestorSubgrid.gridGap(direction: direction)
          - currentAncestorSubgridParent.gridGap(direction: direction))
        / 2
    }
    direction = GridLayoutFunctions.flowAwareDirectionForParent(
      grid: currentAncestorSubgrid, parent: currentAncestorSubgridParent, direction: direction)
  }
  return gutterTotal
}

private func removeSubgridMarginBorderPaddingFromTracks(
  tracks: inout ArraySlice<GridTrack>, mbp: LayoutUnit, forwards: Bool
) {
  let numTracks = tracks.count
  var i = forwards ? 0 : numTracks - 1
  var mbp = mbp
  while mbp > 0 && (forwards ? i < numTracks : i >= 0) {
    var size = tracks[i].baseSize()
    if size > mbp {
      size -= mbp
      mbp = LayoutUnit(value: 0)
    } else {
      mbp -= size
      size = LayoutUnit(value: 0)
    }
    tracks[i].setBaseSize(size)

    if forwards {
      i += 1
    } else {
      i -= 1
    }
  }
}

final class GridTrackSizingAlgorithm {
  init(renderGrid: RenderGridWrapper, grid: Grid) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func run(
    direction: GridTrackSizingDirection, numTracks: UInt32, sizingOperation: SizingOperation,
    availableSpace: LayoutUnit?, gridLayoutState: inout GridLayoutState
  ) {
    setup(
      direction: direction, numTracks: numTracks, sizingOperation: sizingOperation,
      availableSpace: availableSpace)

    let _ = StateMachine(algorithm: self)

    if renderGrid!.isMasonry(direction: direction) {
      return
    }

    if renderGrid!.isSubgrid(direction: direction) && copyUsedTrackSizesForSubgrid() {
      return
    }

    // Step 1.
    let initialFreeSpace = freeSpace(direction: direction)
    initializeTrackSizes()

    // Step 2.
    if !contentSizedTracksIndex.isEmpty {
      (!renderGrid!.isMasonry())
        ? resolveIntrinsicTrackSizes(gridLayoutState: &gridLayoutState)
        : resolveIntrinsicTrackSizesMasonry(gridLayoutState: &gridLayoutState)
    }

    // This is not exactly a step of the track sizing algorithm, but we use the track sizes computed
    // up to this moment (before maximization) to calculate the grid container intrinsic sizes.
    computeGridContainerIntrinsicSizes()

    if let freeSpace = freeSpace(direction: direction) {
      let updatedFreeSpace = freeSpace - minContentSize
      setFreeSpace(direction: direction, freeSpace: updatedFreeSpace)
      if updatedFreeSpace <= Int32(0) {
        return
      }
    }

    // Step 3.
    strategy!.maximizeTracks(
      tracks: tracks(direction: direction),
      freeSpace: direction == .ForColumns ? freeSpaceColumns : freeSpaceRows)

    // Step 4.
    stretchFlexibleTracks(freeSpace: initialFreeSpace, gridLayoutState: &gridLayoutState)

    // Step 5.
    stretchAutoTracks()
  }

  func reset() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func baselineOffsetForGridItem(gridItem: RenderBoxWrapper, baselineAxis: GridAxis) -> LayoutUnit {
    // If we haven't yet initialized this axis (which can be the case if we're doing
    // prelayout of a subgrid), then we can't know the baseline offset.
    if tracks(direction: gridDirectionForAxis(axis: baselineAxis)).isEmpty {
      return LayoutUnit()
    }

    if !participateInBaselineAlignment(gridItem: gridItem, baselineAxis: baselineAxis) {
      return LayoutUnit()
    }

    if baselineAxis == .GridColumnAxis {
      assert(!renderGrid!.isSubgridRows())
    }
    let align = renderGrid!.selfAlignmentForGridItem(axis: baselineAxis, gridItem: gridItem)
      .position
    let span = renderGrid!.gridSpanForGridItem(
      gridItem: gridItem, direction: gridDirectionForAxis(axis: baselineAxis))
    let alignmentContext = GridLayoutFunctions.alignmentContextForBaselineAlignment(
      span: span, alignment: align)
    return baselineAlignment.baselineOffsetForGridItem(
      preference: align, sharedContext: alignmentContext, gridItem: gridItem,
      alignmentAxis: baselineAxis)
  }

  // The estimated grid area should be use pre-layout versus the grid area, which should be used once
  // layout is complete.
  func gridAreaBreadthForGridItem(gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection)
    -> LayoutUnit?
  {
    if renderGrid!.areMasonryColumns() {
      return renderGrid!.contentLogicalWidth()
    }

    var addContentAlignmentOffset =
      direction == .ForColumns
      && (sizingState == .RowSizingFirstIteration
        || sizingState == .RowSizingExtraIterationForSizeContainment)
    // To determine the column track's size based on an orthogonal grid item we need it's logical
    // height, which may depend on the row track's size. It's possible that the row tracks sizing
    // logic has not been performed yet, so we will need to do an estimation.
    if direction == .ForRows
      && (sizingState == .ColumnSizingFirstIteration || sizingState == .ColumnSizingSecondIteration)
      && !renderGrid!.areMasonryColumns()
    {
      assert(GridLayoutFunctions.isOrthogonalGridItem(grid: renderGrid!, gridItem: gridItem))
      // FIXME (jfernandez) Content Alignment should account for this heuristic.
      // https://github.com/w3c/csswg-drafts/issues/2697
      if sizingState == .ColumnSizingFirstIteration {
        return estimatedGridAreaBreadthForGridItem(gridItem: gridItem, direction: .ForRows)
      }
      addContentAlignmentOffset = true
    }

    let span = renderGrid!.gridSpanForGridItem(gridItem: gridItem, direction: direction)
    return computeGridSpanSize(
      tracks: tracks(direction: direction), gridSpan: span,
      gridItemOffset: addContentAlignmentOffset
        ? renderGrid!.gridItemOffset(direction: direction) : nil,
      totalGuttersSize: renderGrid!.guttersSize(
        direction: direction, startLine: span.startLine(), span: span.integerSpan(),
        availableSize: availableSpace(direction: direction)))
  }

  func estimatedGridAreaBreadthForGridItem(
    gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
  ) -> LayoutUnit? {
    let span = renderGrid!.gridSpanForGridItem(gridItem: gridItem, direction: direction)
    var gridAreaSize = LayoutUnit()
    var gridAreaIsIndefinite = false
    let availableSize = availableSpace(direction: direction)
    for trackPosition in span {
      // We may need to estimate the grid area size before running the track sizing algorithm in order to perform the pre-layout of orthogonal items.
      // We cannot use tracks(direction)[trackPosition].cachedTrackSize() because tracks(direction) is empty, since we are either performing pre-layout
      // or are running the track sizing algorithm in the opposite direction and haven't run it in the desired direction yet.
      let trackSize =
        wasSetup()
        ? calculateGridTrackSize(direction: direction, translatedIndex: trackPosition)
        : rawGridTrackSize(direction: direction, translatedIndex: trackPosition)
      let maxTrackSize = trackSize.maxTrackBreadth
      if maxTrackSize.isContentSized() || maxTrackSize.isFlex()
        || isRelativeGridLengthAsAuto(length: maxTrackSize, direction: direction)
      {
        gridAreaIsIndefinite = true
      } else {
        gridAreaSize += valueForLength(
          length: maxTrackSize.length(), maximumValue: availableSize ?? LayoutUnit(value: UInt64(0))
        )
      }
    }

    gridAreaSize += renderGrid!.guttersSize(
      direction: direction, startLine: span.startLine(), span: span.integerSpan(),
      availableSize: availableSize)

    let gridItemInlineDirection = GridLayoutFunctions.flowAwareDirectionForGridItem(
      grid: renderGrid!, gridItem: gridItem, direction: .ForColumns)
    if gridAreaIsIndefinite {
      return direction == gridItemInlineDirection
        ? max(gridItem.maxPreferredLogicalWidth(), gridAreaSize) : nil
    }
    return gridAreaSize
  }

  func cacheBaselineAlignedItem(
    item: RenderBoxWrapper, axis: GridAxis, cachingRowSubgridsForRootGrid: Bool
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func copyBaselineItemsCache(source: GridTrackSizingAlgorithm, axis: GridAxis) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearBaselineItemsCache() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func tracks(direction: GridTrackSizingDirection) -> ArraySlice<GridTrack> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func freeSpace(direction: GridTrackSizingDirection) -> LayoutUnit? {
    return direction == .ForColumns ? freeSpaceColumns : freeSpaceRows
  }

  func setFreeSpace(direction: GridTrackSizingDirection, freeSpace: LayoutUnit?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func availableSpace(direction: GridTrackSizingDirection) -> LayoutUnit? {
    return direction == .ForColumns ? availableSpaceColumns : availableSpaceRows
  }

  func setAvailableSpace(direction: GridTrackSizingDirection, availableSpace: LayoutUnit?) {
    if direction == .ForColumns {
      availableSpaceColumns = availableSpace
    } else {
      availableSpaceRows = availableSpace
    }
  }

  func computeTrackBasedSize() -> LayoutUnit {
    if isDirectionInMasonryDirection() {
      return renderGrid!.masonryContentSize()
    }

    var size = LayoutUnit()
    let allTracks = tracks(direction: direction)
    for track in allTracks {
      size += track.baseSize()
    }

    size += renderGrid!.guttersSize(
      direction: direction, startLine: 0, span: UInt32(allTracks.count),
      availableSize: availableSpace())

    return size
  }

  func hasAnyPercentSizedRowsIndefiniteHeight() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAnyFlexibleMaxTrackBreadth() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAnyBaselineAlignmentItem() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func tracksAreWiderThanMinTrackBreadth() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private typealias SpanLength = UInt32

  // GridTrackSizingAlgorithm API.

  private func setup(
    direction: GridTrackSizingDirection, numTracks: UInt32, sizingOperation: SizingOperation,
    availableSpace: LayoutUnit?
  ) {
    assert(needsSetup)
    self.direction = direction
    setAvailableSpace(
      direction: direction,
      availableSpace: availableSpace != nil
        ? max(LayoutUnit(value: UInt64(0)), availableSpace!) : availableSpace)

    self.sizingOperation = sizingOperation
    switch self.sizingOperation {
    case .IntrinsicSizeComputation:
      strategy = IndefiniteSizeStrategy(algorithm: self)
    case .TrackSizing:
      strategy = DefiniteSizeStrategy(algorithm: self)
    }

    contentSizedTracksIndex.removeAll()
    flexibleSizedTracksIndex.removeAll()
    autoSizedTracksForStretchIndex.removeAll()

    if availableSpace != nil {
      let guttersSize = renderGrid!.guttersSize(
        direction: direction, startLine: 0, span: grid.numTracks(direction: direction),
        availableSize: self.availableSpace(direction: direction))
      setFreeSpace(direction: direction, freeSpace: availableSpace! - guttersSize)
    } else {
      setFreeSpace(direction: direction, freeSpace: nil)
    }
    resizeTracks(direction: direction, numTracks: numTracks)

    needsSetup = false
    hasPercentSizedRowsIndefiniteHeight = false
    hasFlexibleMaxTrackBreadth = false

    if direction == .ForRows
      && (sizingState == .RowSizingFirstIteration || sizingState == .RowSizingSecondIteration)
    {
      for subgrid in rowSubgridsWithBaselineAlignedItems {
        let subgridSpan = renderGrid!.gridSpanForGridItem(gridItem: subgrid, direction: .ForColumns)
        let subgridRowStartMargin = subgrid.style().marginBeforeUsing(
          otherStyle: renderGrid!.style())
        if !subgridRowStartMargin.isAuto() {
          renderGrid!.setMarginBeforeForChild(
            child: subgrid,
            value: minimumValueForLength(
              length: subgridRowStartMargin,
              maximumValue: computeGridSpanSize(
                tracks: tracks(direction: .ForColumns), gridSpan: subgridSpan,
                gridItemOffset: renderGrid!.gridItemOffset(direction: direction),
                totalGuttersSize: renderGrid!.guttersSize(
                  direction: .ForColumns, startLine: subgridSpan.startLine(),
                  span: subgridSpan.integerSpan(),
                  availableSize: self.availableSpace(direction: .ForColumns)))))
        }
      }
    }

    computeBaselineAlignmentContext()
  }

  struct MasonryMinMaxTrackSize {
    let minContentSize: LayoutUnit
    let maxContentSize: LayoutUnit
    let minSize: LayoutUnit
  }

  struct MasonryMinMaxTrackSizeWithGridSpan {
    let trackSize: MasonryMinMaxTrackSize
    let gridSpan: GridSpan
  }

  private func resizeTracks(direction: GridTrackSizingDirection, numTracks: UInt32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func availableSpace() -> LayoutUnit? {
    assert(wasSetup())
    return availableSpace(direction: direction)
  }

  private func isRelativeGridLengthAsAuto(length: GridLength, direction: GridTrackSizingDirection)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func calculateGridTrackSize(direction: GridTrackSizingDirection, translatedIndex: UInt32)
    -> GridTrackSize
  {
    assert(wasSetup())
    // Collapse empty auto repeat tracks if auto-fit.
    if grid.hasAutoRepeatEmptyTracks(direction: direction)
      && grid.isEmptyAutoRepeatTrack(direction: direction, line: translatedIndex)
    {
      return GridTrackSize(
        length: GridLength(length: LengthWrapper(type: .Fixed)), trackSizeType: .LengthTrackSizing)
    }

    let trackSize = rawGridTrackSize(direction: direction, translatedIndex: translatedIndex)
    if trackSize.isFitContent() {
      return isRelativeGridLengthAsAuto(
        length: trackSize.fitContentTrackBreadth(), direction: direction)
        ? GridTrackSize(
          minTrackBreadth: GridLength(length: LengthWrapper(type: .Auto)),
          maxTrackBreadth: GridLength(length: LengthWrapper(type: .MaxContent))) : trackSize
    }

    var minTrackBreadth = trackSize.minTrackBreadth
    var maxTrackBreadth = trackSize.maxTrackBreadth
    // If the logical width/height of the grid container is indefinite, percentage
    // values are treated as <auto>.
    if isRelativeGridLengthAsAuto(length: trackSize.minTrackBreadth, direction: direction) {
      minTrackBreadth = GridLength(length: LengthWrapper(type: .Auto))
    }
    if isRelativeGridLengthAsAuto(length: trackSize.maxTrackBreadth, direction: direction) {
      maxTrackBreadth = GridLength(length: LengthWrapper(type: .Auto))
    }

    // Flex sizes are invalid as a min sizing function. However we still can have a flexible |minTrackBreadth|
    // if the track size is just a flex size (e.g. "1fr"), the spec says that in this case it implies an automatic minimum.
    if minTrackBreadth.isFlex() {
      minTrackBreadth = GridLength(length: LengthWrapper(type: .Auto))
    }

    return GridTrackSize(minTrackBreadth: minTrackBreadth, maxTrackBreadth: maxTrackBreadth)
  }

  private func rawGridTrackSize(direction: GridTrackSizingDirection, translatedIndex: UInt32)
    -> GridTrackSize
  {
    let isRowAxis = direction == .ForColumns
    let renderStyle = renderGrid!.style()
    let trackStyles =
      isRowAxis ? renderStyle.gridColumnTrackSizes() : renderStyle.gridRowTrackSizes()
    let autoRepeatTrackStyles =
      isRowAxis ? renderStyle.gridAutoRepeatColumns() : renderStyle.gridAutoRepeatRows()
    let autoTrackStyles = isRowAxis ? renderStyle.gridAutoColumns() : renderStyle.gridAutoRows()
    let insertionPoint =
      isRowAxis
      ? renderStyle.gridAutoRepeatColumnsInsertionPoint()
      : renderStyle.gridAutoRepeatRowsInsertionPoint()
    let autoRepeatTracksCount = grid.autoRepeatTracks(direction: direction)

    // We should not use GridPositionsResolver::explicitGridXXXCount() for this because the
    // explicit grid might be larger than the number of tracks in grid-template-rows|columns (if
    // grid-template-areas is specified for example).
    let explicitTracksCount = UInt32(trackStyles.count) + autoRepeatTracksCount

    let untranslatedIndex = translatedIndex - grid.explicitGridStart(direction: direction)
    let untranslatedIndexAsInt = Int(untranslatedIndex)
    let autoTrackStylesSize = UInt32(autoTrackStyles.count)
    if untranslatedIndexAsInt < 0 {
      var index = untranslatedIndexAsInt % Int(autoTrackStylesSize)
      // We need to transpose the index because the first negative implicit line will get the last defined auto track and so on.
      index += index != 0 ? Int(autoTrackStylesSize) : 0
      assert(index >= 0)
      return autoTrackStyles[index]
    }

    if untranslatedIndex >= explicitTracksCount {
      return autoTrackStyles[Int((untranslatedIndex - explicitTracksCount) % autoTrackStylesSize)]
    }

    if autoRepeatTracksCount == 0 || untranslatedIndex < insertionPoint {
      return trackStyles[Int(untranslatedIndex)]
    }

    if untranslatedIndex < (insertionPoint + autoRepeatTracksCount) {
      let autoRepeatLocalIndex = untranslatedIndexAsInt - Int(insertionPoint)
      return autoRepeatTrackStyles[autoRepeatLocalIndex % autoRepeatTrackStyles.count]
    }

    return trackStyles[Int(untranslatedIndex - autoRepeatTracksCount)]
  }

  // Helper methods for step 1. initializeTrackSizes().
  private func initialBaseSize(trackSize: GridTrackSize) -> LayoutUnit {
    let zero = LayoutUnit(value: 0)
    let gridLength = trackSize.minTrackBreadth
    if gridLength.isFlex() {
      return zero
    }

    let trackLength = gridLength.length()
    if trackLength.isSpecified() {
      return valueForLength(length: trackLength, maximumValue: max(availableSpace() ?? zero, zero))
    }

    assert(trackLength.isMinContent() || trackLength.isAuto() || trackLength.isMaxContent())
    return zero
  }

  private func initialGrowthLimit(trackSize: GridTrackSize, baseSize: LayoutUnit) -> LayoutUnit {
    let gridLength = trackSize.maxTrackBreadth
    if gridLength.isFlex() {
      return trackSize.minTrackBreadth.isContentSized() ? LayoutUnit(value: infinity) : baseSize
    }

    let trackLength = gridLength.length()
    if trackLength.isSpecified() {
      let zero = LayoutUnit(value: 0)
      return valueForLength(length: trackLength, maximumValue: max(availableSpace() ?? zero, zero))
    }

    assert(trackLength.isMinContent() || trackLength.isAuto() || trackLength.isMaxContent())
    return LayoutUnit(value: infinity)
  }

  // Helper methods for step 2. resolveIntrinsicTrackSizes().
  private func sizeTrackToFitNonSpanningItem(
    _ span: GridSpan, _ gridItem: RenderBoxWrapper, _ track: GridTrack,
    _ gridLayoutState: inout GridLayoutState
  ) {
    let trackPosition = Int(span.startLine())
    let trackSize = tracks(direction: direction)[trackPosition].cachedTrackSize()

    if trackSize.hasMinContentMinTrackBreadth() {
      track.setBaseSize(
        max(
          track.baseSize(), strategy!.minContentContributionForGridItem(gridItem, &gridLayoutState))
      )
    } else if trackSize.hasMaxContentMinTrackBreadth() {
      track.setBaseSize(
        max(
          track.baseSize(), strategy!.maxContentContributionForGridItem(gridItem, &gridLayoutState))
      )
    } else if trackSize.hasAutoMinTrackBreadth() {
      track.setBaseSize(
        max(track.baseSize(), strategy!.minContributionForGridItem(gridItem, &gridLayoutState)))
    }

    if trackSize.hasMinContentMaxTrackBreadth() {
      track.setGrowthLimit(
        growthLimit:
          max(
            track.growthLimit(),
            strategy!.minContentContributionForGridItem(gridItem, &gridLayoutState)))
    } else if trackSize.hasMaxContentOrAutoMaxTrackBreadth() {
      var growthLimit = strategy!.maxContentContributionForGridItem(gridItem, &gridLayoutState)
      if trackSize.isFitContent() {
        growthLimit = min(
          growthLimit,
          valueForLength(
            length: trackSize.fitContentTrackBreadth().length(),
            maximumValue: availableSpace() ?? LayoutUnit(value: 0)))
      }
      track.setGrowthLimit(growthLimit: max(track.growthLimit(), growthLimit))
    }
  }

  private func sizeTrackToFitSingleSpanMasonryGroup(
    span: GridSpan, masonryIndefiniteItems: MasonryMinMaxTrackSize, track: GridTrack
  ) {
    let trackPosition = Int(span.startLine())
    let trackSize = tracks(direction: direction)[trackPosition].cachedTrackSize()

    if trackSize.hasMinContentMinTrackBreadth() {
      track.setBaseSize(max(track.baseSize(), masonryIndefiniteItems.minContentSize))
    } else if trackSize.hasMaxContentMinTrackBreadth() {
      track.setBaseSize(max(track.baseSize(), masonryIndefiniteItems.maxContentSize))
    } else if trackSize.hasAutoMinTrackBreadth() {
      track.setBaseSize(max(track.baseSize(), masonryIndefiniteItems.minSize))
    }

    if trackSize.hasMinContentMaxTrackBreadth() {
      track.setGrowthLimit(
        growthLimit: max(track.growthLimit(), masonryIndefiniteItems.minContentSize))
    } else if trackSize.hasMaxContentOrAutoMaxTrackBreadth() {
      var growthLimit = masonryIndefiniteItems.maxContentSize
      if trackSize.isFitContent() {
        growthLimit = min(
          growthLimit,
          valueForLength(
            length: trackSize.fitContentTrackBreadth().length(),
            maximumValue: availableSpace() ?? LayoutUnit(value: 0)))
      }
      track.setGrowthLimit(growthLimit: max(track.growthLimit(), growthLimit))
    }
  }

  private func spanningItemCrossesFlexibleSizedTracks(itemSpan: GridSpan) -> Bool {
    let trackList = tracks(direction: direction)
    for trackPosition in itemSpan {
      let trackSize = trackList[Int(trackPosition)].cachedTrackSize()
      if trackSize.minTrackBreadth.isFlex() || trackSize.maxTrackBreadth.isFlex() {
        return true
      }
    }

    return false
  }

  private func increaseSizesToAccommodateSpanningItems(
    _ variant: TrackSizeComputationVariant, _ phase: TrackSizeComputationPhase,
    _ gridItemsWithSpan: GridItemsSpanGroupRange, _ gridLayoutState: inout GridLayoutState
  ) {
    let allTracks = tracks(direction: direction)
    for trackIndex in contentSizedTracksIndex {
      let track = allTracks[Int(trackIndex)]
      track.setPlannedSize(
        plannedSize: trackSizeForTrackSizeComputationPhase(phase, track, .AllowInfinity))
    }

    let growBeyondGrowthLimitsTracks = GridTrackArrayRef()
    let filteredTracks = GridTrackArrayRef()
    for gridItemWithSpan in gridItemsWithSpan.span[
      gridItemsWithSpan.rangeStart..<gridItemsWithSpan.rangeEnd]
    {
      let itemSpan = gridItemWithSpan.span
      assert(variant == .CrossingFlexibleTracks || itemSpan.integerSpan() > 1)

      filteredTracks.a.removeAll()
      growBeyondGrowthLimitsTracks.a.removeAll()
      var spanningTracksSize = LayoutUnit()
      for trackPosition in itemSpan {
        let track = allTracks[Int(trackPosition)]
        let trackSize = track.cachedTrackSize()
        spanningTracksSize += trackSizeForTrackSizeComputationPhase(phase, track, .ForbidInfinity)
        if variant == .CrossingFlexibleTracks && !trackSize.maxTrackBreadth.isFlex() {
          continue
        }
        if !shouldProcessTrackForTrackSizeComputationPhase(phase: phase, trackSize: trackSize) {
          continue
        }

        filteredTracks.a.append(track)

        if trackShouldGrowBeyondGrowthLimitsForTrackSizeComputationPhase(
          phase: phase, trackSize: trackSize)
        {
          growBeyondGrowthLimitsTracks.a.append(track)
        }
      }

      if filteredTracks.a.isEmpty {
        continue
      }

      spanningTracksSize += renderGrid!.guttersSize(
        direction: direction, startLine: itemSpan.startLine(), span: itemSpan.integerSpan(),
        availableSize: availableSpace())

      var extraSpace =
        itemSizeForTrackSizeComputationPhase(phase, gridItemWithSpan.gridItem, &gridLayoutState)
        - spanningTracksSize
      extraSpace = max(extraSpace, LayoutUnit(value: 0))
      let tracksToGrowBeyondGrowthLimits =
        growBeyondGrowthLimitsTracks.a.isEmpty ? filteredTracks : growBeyondGrowthLimitsTracks
      distributeSpaceToTracks(
        variant, phase, filteredTracks, tracksToGrowBeyondGrowthLimits, &extraSpace)
    }

    for trackIndex in contentSizedTracksIndex {
      let track = allTracks[Int(trackIndex)]
      markAsInfinitelyGrowableForTrackSizeComputationPhase(phase, track)
      updateTrackSizeForTrackSizeComputationPhase(phase, track)
    }
  }

  private func increaseSizesToAccommodateSpanningItems(
    _ variant: TrackSizeComputationVariant, _ gridItemsWithSpan: GridItemsSpanGroupRange,
    _ gridLayoutState: inout GridLayoutState
  ) {
    increaseSizesToAccommodateSpanningItems(
      variant, .ResolveIntrinsicMinimums, gridItemsWithSpan, &gridLayoutState)
    increaseSizesToAccommodateSpanningItems(
      variant, .ResolveContentBasedMinimums, gridItemsWithSpan, &gridLayoutState)
    increaseSizesToAccommodateSpanningItems(
      variant, .ResolveMaxContentMinimums, gridItemsWithSpan, &gridLayoutState)
    increaseSizesToAccommodateSpanningItems(
      variant, .ResolveIntrinsicMaximums, gridItemsWithSpan, &gridLayoutState)
    increaseSizesToAccommodateSpanningItems(
      variant, .ResolveMaxContentMaximums, gridItemsWithSpan, &gridLayoutState)
  }

  // 12.5 Resolve Intrinsic Track Sizing : Step 3
  // https://drafts.csswg.org/css-grid-2/#algo-spanning-items
  //
  // Take all grid items (definite and indefinite) that span 2 or more tracks, and distribute space to intrinsic tracks (non-flex).
  // The implementation diverges from increaseSizesToAccommodateSpanningItems(), because we are grouping items together that are the same span length.
  // This function is divided into two main sections:
  //
  // 1. Constructing the track items
  // This step takes the definite and indefinite items, and merges them into one large map to send over to the second step.
  // Since the indefinite items are grouped together from a prior computation, this step also need to create "fake" grid items that
  // will be considered in each track.
  //
  // 2. Distribute space to intrinsic tracks
  // This step behaves similar to increaseSizesToAccommodateSpanningItems() where we start at the lowest span length and distribute space to the tracks.
  // Then look at the next smallest span length, and repeat step 2 until we exhaust all grid items.
  private func increaseSizesToAccommodateSpanningItemsMasonry(
    definiteItemSizes: [SpanLength: [MasonryMinMaxTrackSizeWithGridSpan]]
  ) {
    for definiteItemSpanGroupValue in definiteItemSizes.values {
      increaseSizesToAccommodateSpanningItemsMasonryForPhase(
        phase: .ResolveIntrinsicMinimums, definiteItemSizes: definiteItemSpanGroupValue[...])
      increaseSizesToAccommodateSpanningItemsMasonryForPhase(
        phase: .ResolveContentBasedMinimums, definiteItemSizes: definiteItemSpanGroupValue[...])
      increaseSizesToAccommodateSpanningItemsMasonryForPhase(
        phase: .ResolveMaxContentMinimums, definiteItemSizes: definiteItemSpanGroupValue[...])
      increaseSizesToAccommodateSpanningItemsMasonryForPhase(
        phase: .ResolveIntrinsicMaximums, definiteItemSizes: definiteItemSpanGroupValue[...])
      increaseSizesToAccommodateSpanningItemsMasonryForPhase(
        phase: .ResolveMaxContentMaximums, definiteItemSizes: definiteItemSpanGroupValue[...])
    }
  }

  private func increaseSizesToAccommodateSpanningItemsMasonryForPhase(
    phase: TrackSizeComputationPhase,
    definiteItemSizes: ArraySlice<MasonryMinMaxTrackSizeWithGridSpan>
  ) {
    let allTracks = tracks(direction: direction)
    for trackIndex in contentSizedTracksIndex {
      let track = allTracks[Int(trackIndex)]
      track.setPlannedSize(
        plannedSize: trackSizeForTrackSizeComputationPhase(phase, track, .AllowInfinity))
    }

    let growBeyondGrowthLimitsTracks = GridTrackArrayRef()
    let filteredTracks = GridTrackArrayRef()

    for definiteItem in definiteItemSizes {
      let itemSpan = definiteItem.gridSpan
      assert(itemSpan.integerSpan() > 1)

      filteredTracks.a.removeAll()
      growBeyondGrowthLimitsTracks.a.removeAll()
      var spanningTracksSize = LayoutUnit()
      for trackPosition in itemSpan {
        let track = allTracks[Int(trackPosition)]
        let trackSize = track.cachedTrackSize()
        spanningTracksSize += trackSizeForTrackSizeComputationPhase(phase, track, .ForbidInfinity)

        if !shouldProcessTrackForTrackSizeComputationPhase(phase: phase, trackSize: trackSize) {
          continue
        }

        filteredTracks.a.append(track)

        if trackShouldGrowBeyondGrowthLimitsForTrackSizeComputationPhase(
          phase: phase, trackSize: trackSize)
        {
          growBeyondGrowthLimitsTracks.a.append(track)
        }
      }

      if filteredTracks.a.isEmpty {
        continue
      }

      spanningTracksSize += renderGrid!.guttersSize(
        direction: direction, startLine: itemSpan.startLine(), span: itemSpan.integerSpan(),
        availableSize: availableSpace())

      var extraSpace =
        GridTrackSizingAlgorithm.itemSizeForTrackSizeComputationPhaseMasonry(
          phase: phase, trackSize: definiteItem.trackSize) - spanningTracksSize
      extraSpace = max(extraSpace, LayoutUnit(value: 0))
      let tracksToGrowBeyondGrowthLimits =
        growBeyondGrowthLimitsTracks.a.isEmpty ? filteredTracks : growBeyondGrowthLimitsTracks
      distributeSpaceToTracks(
        .NotCrossingFlexibleTracks, phase, filteredTracks, tracksToGrowBeyondGrowthLimits,
        &extraSpace)
    }

    for trackIndex in contentSizedTracksIndex {
      let track = allTracks[Int(trackIndex)]
      markAsInfinitelyGrowableForTrackSizeComputationPhase(phase, track)
      updateTrackSizeForTrackSizeComputationPhase(phase, track)
    }
  }

  // 12.5 Resolve Intrinsic Track Sizing : Step 4
  // https://drafts.csswg.org/css-grid-2/#algo-spanning-items
  //
  // Take all grid items (definite and indefinite) that span 1 or tracks, and distribute space to only flex tracks.
  // The implementation diverges from increaseSizesToAccommodateSpanningItems(), because we are grouping items together that are the same span length.
  // This function is divided into two main sections:
  //
  // 1. Constructing the track items
  // This step takes the definite and indefinite items, and merges them into one large map to send over to the second step.
  // Since the indefinite items are grouped together from a prior computation, this step also need to create "fake" grid items that
  // will be considered in each track.
  //
  // 2. Distribute space to intrinsic tracks
  // This step behaves similar to increaseSizesToAccommodateSpanningItems() where we consider all track items at once instead of per span length.
  private func increaseSizesToAccommodateSpanningItemsMasonryWithFlex(
    definiteItemSizesSpanFlexTracks: ArraySlice<MasonryMinMaxTrackSizeWithGridSpan>
  ) {
    increaseSizesToAccommodateSpanningItemsMasonryWithFlexForPhase(
      phase: .ResolveIntrinsicMinimums,
      definiteItemSizesSpanFlexTracks: definiteItemSizesSpanFlexTracks[...])
    increaseSizesToAccommodateSpanningItemsMasonryWithFlexForPhase(
      phase: .ResolveContentBasedMinimums,
      definiteItemSizesSpanFlexTracks: definiteItemSizesSpanFlexTracks[...])
    increaseSizesToAccommodateSpanningItemsMasonryWithFlexForPhase(
      phase: .ResolveMaxContentMinimums,
      definiteItemSizesSpanFlexTracks: definiteItemSizesSpanFlexTracks[...])
    increaseSizesToAccommodateSpanningItemsMasonryWithFlexForPhase(
      phase: .ResolveIntrinsicMaximums,
      definiteItemSizesSpanFlexTracks: definiteItemSizesSpanFlexTracks[...])
    increaseSizesToAccommodateSpanningItemsMasonryWithFlexForPhase(
      phase: .ResolveMaxContentMaximums,
      definiteItemSizesSpanFlexTracks: definiteItemSizesSpanFlexTracks[...])
  }

  private func increaseSizesToAccommodateSpanningItemsMasonryWithFlexForPhase(
    phase: TrackSizeComputationPhase,
    definiteItemSizesSpanFlexTracks: ArraySlice<MasonryMinMaxTrackSizeWithGridSpan>
  ) {
    let allTracks = tracks(direction: direction)
    for trackIndex in contentSizedTracksIndex {
      let track = allTracks[Int(trackIndex)]
      track.setPlannedSize(
        plannedSize: trackSizeForTrackSizeComputationPhase(phase, track, .AllowInfinity))
    }

    let growBeyondGrowthLimitsTracks = GridTrackArrayRef()
    let filteredTracks = GridTrackArrayRef()

    for item in definiteItemSizesSpanFlexTracks {
      let itemSpan = item.gridSpan

      filteredTracks.a.removeAll()
      growBeyondGrowthLimitsTracks.a.removeAll()
      var spanningTracksSize = LayoutUnit()
      for trackPosition in itemSpan {
        let track = allTracks[Int(trackPosition)]
        let trackSize = track.cachedTrackSize()
        spanningTracksSize += trackSizeForTrackSizeComputationPhase(phase, track, .ForbidInfinity)
        if !trackSize.maxTrackBreadth.isFlex() {
          continue
        }
        if !shouldProcessTrackForTrackSizeComputationPhase(phase: phase, trackSize: trackSize) {
          continue
        }

        filteredTracks.a.append(track)

        if trackShouldGrowBeyondGrowthLimitsForTrackSizeComputationPhase(
          phase: phase, trackSize: trackSize)
        {
          growBeyondGrowthLimitsTracks.a.append(track)
        }
      }

      if filteredTracks.a.isEmpty {
        continue
      }

      spanningTracksSize += renderGrid!.guttersSize(
        direction: direction, startLine: itemSpan.startLine(), span: itemSpan.integerSpan(),
        availableSize: availableSpace())

      var extraSpace =
        GridTrackSizingAlgorithm.itemSizeForTrackSizeComputationPhaseMasonry(
          phase: phase, trackSize: item.trackSize) - spanningTracksSize
      extraSpace = max(extraSpace, LayoutUnit(value: 0))
      let tracksToGrowBeyondGrowthLimits =
        growBeyondGrowthLimitsTracks.a.isEmpty ? filteredTracks : growBeyondGrowthLimitsTracks
      distributeSpaceToTracks(
        .CrossingFlexibleTracks, phase, filteredTracks, tracksToGrowBeyondGrowthLimits, &extraSpace)
    }

    for trackIndex in contentSizedTracksIndex {
      let track = allTracks[Int(trackIndex)]
      markAsInfinitelyGrowableForTrackSizeComputationPhase(phase, track)
      updateTrackSizeForTrackSizeComputationPhase(phase, track)
    }
  }

  private func convertIndefiniteItemsToDefiniteMasonry(
    indefiniteSpanSizes: [SpanLength: MasonryMinMaxTrackSize],
    definiteItemSizes: inout [SpanLength: [MasonryMinMaxTrackSizeWithGridSpan]],
    definiteItemSizesSpanFlexTracks: inout [MasonryMinMaxTrackSizeWithGridSpan]
  ) {
    let allTracks = tracks(direction: direction)

    for (indefiniteItemKey, indefiniteItemVal) in indefiniteSpanSizes {
      for trackIndex in 0..<allTracks.count {
        let endLine = trackIndex + Int(indefiniteItemKey)
        let itemSpan = GridSpan.translatedDefiniteGridSpan(
          startLine: Int32(trackIndex), endLine: Int32(endLine))

        if endLine > allTracks.count {
          continue
        }

        // The spec requires items with a span of 1 to be handled earlier.
        if itemSpan.integerSpan() != 1
          && !spanningItemCrossesFlexibleSizedTracks(itemSpan: itemSpan)
        {
          definiteItemSizes[itemSpan.integerSpan()]!.append(
            MasonryMinMaxTrackSizeWithGridSpan(trackSize: indefiniteItemVal, gridSpan: itemSpan)
          )
        }

        if spanningItemCrossesFlexibleSizedTracks(itemSpan: itemSpan) {
          definiteItemSizesSpanFlexTracks.append(
            MasonryMinMaxTrackSizeWithGridSpan(trackSize: indefiniteItemVal, gridSpan: itemSpan))
        }
      }
    }
  }

  private func itemSizeForTrackSizeComputationPhase(
    _ phase: TrackSizeComputationPhase, _ gridItem: RenderBoxWrapper,
    _ gridLayoutState: inout GridLayoutState
  ) -> LayoutUnit {
    switch phase {
    case .ResolveIntrinsicMinimums:
      return strategy!.minContributionForGridItem(gridItem, &gridLayoutState)
    case .ResolveContentBasedMinimums, .ResolveIntrinsicMaximums:
      return strategy!.minContentContributionForGridItem(gridItem, &gridLayoutState)
    case .ResolveMaxContentMinimums, .ResolveMaxContentMaximums:
      return strategy!.maxContentContributionForGridItem(gridItem, &gridLayoutState)
    case .MaximizeTracks:
      fatalError("Not reached")
    }
  }

  private static func itemSizeForTrackSizeComputationPhaseMasonry(
    phase: TrackSizeComputationPhase, trackSize: MasonryMinMaxTrackSize
  ) -> LayoutUnit {
    switch phase {
    case .ResolveIntrinsicMinimums:
      return trackSize.minSize
    case .ResolveContentBasedMinimums, .ResolveIntrinsicMaximums:
      return trackSize.minContentSize
    case .ResolveMaxContentMinimums, .ResolveMaxContentMaximums:
      return trackSize.maxContentSize
    case .MaximizeTracks:
      fatalError("Not reached")
    }
  }

  private func distributeSpaceToTracks(
    _ variant: TrackSizeComputationVariant, _ phase: TrackSizeComputationPhase,
    _ tracks: GridTrackArrayRef, _ growBeyondGrowthLimitsTracks: GridTrackArrayRef,
    _ freeSpace: inout LayoutUnit
  ) {
    assert(freeSpace >= Int32(0))

    for track in tracks.a {
      track.setTempSize(
        tempSize: trackSizeForTrackSizeComputationPhase(phase, track, .ForbidInfinity))
    }

    if freeSpace > Int32(0) {
      distributeItemIncurredIncreases(
        variant: variant, phase: phase, limit: .UpToGrowthLimit, tracks: tracks,
        freeSpace: &freeSpace)
    }

    if freeSpace > Int32(0) {
      distributeItemIncurredIncreases(
        variant: variant, phase: phase, limit: .BeyondGrowthLimit,
        tracks: growBeyondGrowthLimitsTracks, freeSpace: &freeSpace)
    }

    for track in tracks.a {
      track.setPlannedSize(
        plannedSize: track.plannedSize() == infinity
          ? track.tempSize() : max(track.plannedSize(), track.tempSize()))
    }
  }

  private func computeBaselineAlignmentContext() {
    let axis = gridAxisForDirection(direction: direction)
    baselineAlignment.clear(alignmentAxis: axis)
    baselineAlignment.setWritingMode(writingMode: renderGrid!.style().writingMode())
    let baselineItemsCache = axis == .GridColumnAxis ? columnBaselineItemsMap : rowBaselineItemsMap
    let tmpBaselineItemsCache = baselineItemsCache.deepCopy()
    for gridItem in tmpBaselineItemsCache.keys() {
      // FIXME (jfernandez): We may have to get rid of the baseline participation
      // flag (hence just using a HashSet) depending on the CSS WG resolution on
      // https://github.com/w3c/csswg-drafts/issues/3046
      if canParticipateInBaselineAlignment(gridItem: gridItem, baselineAxis: axis) {
        updateBaselineAlignmentContext(gridItem: gridItem, baselineAxis: axis)
        baselineItemsCache.set(gridItem, true)
      } else {
        baselineItemsCache.set(gridItem, false)
      }
    }
  }

  private func updateBaselineAlignmentContext(gridItem: RenderBoxWrapper, baselineAxis: GridAxis) {
    assert(wasSetup())
    assert(canParticipateInBaselineAlignment(gridItem: gridItem, baselineAxis: baselineAxis))

    let align = renderGrid!.selfAlignmentForGridItem(axis: baselineAxis, gridItem: gridItem)
      .position
    let span = renderGrid!.gridSpanForGridItem(
      gridItem: gridItem, direction: gridDirectionForAxis(axis: baselineAxis))
    let alignmentContext = GridLayoutFunctions.alignmentContextForBaselineAlignment(
      span: span, alignment: align)
    baselineAlignment.updateBaselineAlignmentContext(
      align, alignmentContext, gridItem, baselineAxis)
  }

  private func canParticipateInBaselineAlignment(gridItem: RenderBoxWrapper, baselineAxis: GridAxis)
    -> Bool
  {
    assert(
      baselineAxis == .GridColumnAxis
        ? columnBaselineItemsMap.contains(gridItem) : rowBaselineItemsMap.contains(gridItem))

    // Baseline cyclic dependencies only happen with synthesized
    // baselines. These cases include orthogonal or empty grid items
    // and replaced elements.
    let isParallelToBaselineAxis =
      baselineAxis == .GridColumnAxis
      ? !GridLayoutFunctions.isOrthogonalGridItem(grid: renderGrid!, gridItem: gridItem)
      : GridLayoutFunctions.isOrthogonalGridItem(grid: renderGrid!, gridItem: gridItem)
    if isParallelToBaselineAxis && gridItem.firstLineBaseline() != nil {
      return true
    }

    // FIXME: We don't currently allow items within subgrids that need to
    // synthesize a baseline, since we need a layout to have been completed
    // and performPreLayoutForGridItems on the outer grid doesn't layout subgrid
    // items.
    if CPtrToInt(gridItem.parent()?.p) != CPtrToInt(renderGrid!.p) {
      return false
    }

    // Baseline cyclic dependencies only happen in grid areas with
    // intrinsically-sized tracks.
    if !isIntrinsicSizedGridArea(gridItem: gridItem, axis: baselineAxis) {
      return true
    }

    return isParallelToBaselineAxis
      ? !gridItem.hasRelativeLogicalHeight()
      : !gridItem.hasRelativeLogicalWidth() && !gridItem.style().logicalWidth().isAuto()
  }

  private func participateInBaselineAlignment(gridItem: RenderBoxWrapper, baselineAxis: GridAxis)
    -> Bool
  {
    return baselineAxis == .GridColumnAxis
      ? columnBaselineItemsMap.contains(gridItem) : rowBaselineItemsMap.contains(gridItem)
  }

  private func isIntrinsicSizedGridArea(gridItem: RenderBoxWrapper, axis: GridAxis) -> Bool {
    assert(wasSetup())
    let direction = gridDirectionForAxis(axis: axis)
    let span = renderGrid!.gridSpanForGridItem(gridItem: gridItem, direction: direction)
    for trackPosition in span {
      let trackSize = rawGridTrackSize(direction: direction, translatedIndex: trackPosition)
      // We consider fr units as 'auto' for the min sizing function.
      // FIXME(jfernandez): https://github.com/w3c/csswg-drafts/issues/2611
      //
      // The use of AvailableSize function may imply different results
      // for the same item when assuming indefinite or definite size
      // constraints depending on the phase we evaluate the item's
      // baseline participation.
      // FIXME(jfernandez): https://github.com/w3c/csswg-drafts/issues/3046
      if trackSize.isContentSized() || trackSize.isFitContent()
        || trackSize.minTrackBreadth.isFlex()
        || (trackSize.maxTrackBreadth.isFlex() && availableSpace(direction: direction) == nil)
      {
        return true
      }
    }
    return false
  }

  private func computeGridContainerIntrinsicSizes() {
    if direction == .ForColumns && strategy!.isComputingSizeOrInlineSizeContainment(),
      let size = renderGrid!.explicitIntrinsicInnerLogicalSize(direction: direction)
    {
      minContentSize = size
      maxContentSize = size
      return
    }

    minContentSize = LayoutUnit(value: UInt64(0))
    maxContentSize = LayoutUnit(value: UInt64(0))

    let allTracks = tracks(direction: direction)
    for track in allTracks {
      assert(strategy!.isComputingSizeOrInlineSizeContainment() || !track.infiniteGrowthPotential())
      minContentSize += track.baseSize()
      maxContentSize += track.growthLimitIsInfinite() ? track.baseSize() : track.growthLimit()
      // The growth limit caps must be cleared now in order to properly sort
      // tracks by growth potential on an eventual "Maximize Tracks".
      track.growthLimitCap = nil
    }
  }

  private func computeFlexSizedTracksGrowth(
    flexFraction: Float64, increments: inout [LayoutUnit], totalGrowth: inout LayoutUnit
  ) {
    let numFlexTracks = flexibleSizedTracksIndex.count
    assert(increments.count == numFlexTracks)
    let allTracks = tracks(direction: direction)
    // The flexFraction multiplied by the flex factor can result in a non-integer size. Since we floor the stretched size to fit in a LayoutUnit,
    // we may lose the fractional part of the computation which can cause the entire free space not being distributed evenly. The leftover
    // fractional part from every flexible track are accumulated here to avoid this issue.
    var leftOverSize: Float64 = 0
    for i in 0..<numFlexTracks {
      let trackIndex = Int(flexibleSizedTracksIndex[i])
      let trackSize = allTracks[trackIndex].cachedTrackSize()
      assert(trackSize.maxTrackBreadth.isFlex())
      let oldBaseSize = allTracks[trackIndex].baseSize()
      let frShare = flexFraction * trackSize.maxTrackBreadth.flex() + leftOverSize
      let stretchedSize = LayoutUnit(value: frShare)
      let newBaseSize = max(oldBaseSize, stretchedSize)
      increments[i] = newBaseSize - oldBaseSize
      totalGrowth += increments[i]
      // In the case that stretchedSize is greater than frShare, we floor it to 0 to avoid a negative leftover.
      leftOverSize = max(frShare - stretchedSize.toDouble(), 0)
    }
  }

  private func handleInfinityGrowthLimit() {
    let allTracks = tracks(direction: direction)
    for trackIndex in contentSizedTracksIndex {
      let track = allTracks[Int(trackIndex)]
      if track.growthLimit() == infinity {
        track.setGrowthLimit(growthLimit: track.baseSize())
      }
    }
  }

  private struct DefiniteAndIndefiniteItemsForMasonry {
    let indefiniteSpanSizes: [SpanLength: MasonryMinMaxTrackSize]
    var definiteItemSizes: [SpanLength: [MasonryMinMaxTrackSizeWithGridSpan]]
    var definiteItemSizesSpanFlexTrack: [MasonryMinMaxTrackSizeWithGridSpan]
  }

  // Build up a map of min/max sizes for each span length for use during resolving intrinsic track sizes.
  // We also need to keep track of definite items separately, since they do not contribute to every track like indefinite items do.
  private func computeDefiniteAndIndefiniteItemsForMasonry(gridLayoutState: inout GridLayoutState)
    -> DefiniteAndIndefiniteItemsForMasonry
  {
    var indefiniteSpanSizes: [SpanLength: MasonryMinMaxTrackSize] = [:]
    var definiteItemSizes: [SpanLength: [MasonryMinMaxTrackSizeWithGridSpan]] = [:]
    var definiteItemSizesSpanFlexTrack: [MasonryMinMaxTrackSizeWithGridSpan] = []

    let allTracks = tracks(direction: direction)
    let trackLength = UInt32(allTracks.count)
    for trackIndex in 0..<trackLength {
      let iterator = GridIterator(grid: grid, direction: direction, fixedTrackIndex: trackIndex)

      while true {
        guard let gridItem = iterator.nextGridItem() else { break }
        let gridSpan = renderGrid!.gridSpanForGridItem(gridItem: gridItem, direction: direction)
        let spanLength = gridSpan.integerSpan()

        if !GridPositionsResolver.resolveGridPositionsFromStyle(
          gridContainer: renderGrid!, gridItem: gridItem, direction: direction
        )
        .isIndefinite() {
          populateDefiniteItems(
            trackIndex, gridSpan, spanLength, gridItem, allTracks, &definiteItemSizes,
            &definiteItemSizesSpanFlexTrack, &gridLayoutState)
          continue
        }

        let endLine = trackIndex + spanLength
        if endLine > trackLength {
          continue
        }

        populateIndefiniteItems(gridItem, spanLength, &indefiniteSpanSizes, &gridLayoutState)
      }
    }
    return DefiniteAndIndefiniteItemsForMasonry(
      indefiniteSpanSizes: indefiniteSpanSizes, definiteItemSizes: definiteItemSizes,
      definiteItemSizesSpanFlexTrack: definiteItemSizesSpanFlexTrack)
  }

  private func populateDefiniteItems(
    _ trackIndex: UInt32, _ gridSpan: GridSpan, _ spanLength: UInt32, _ gridItem: RenderBoxWrapper?,
    _ allTracks: ArraySlice<GridTrack>,
    _ definiteItemSizes: inout [SpanLength: [MasonryMinMaxTrackSizeWithGridSpan]],
    _ definiteItemSizesSpanFlexTrack: inout [MasonryMinMaxTrackSizeWithGridSpan],
    _ gridLayoutState: inout GridLayoutState
  ) {
    if gridSpan.startLine() != trackIndex {
      return
    }

    let minContentContributionForGridItem = strategy!.minContentContributionForGridItem(
      gridItem!, &gridLayoutState)
    let maxContentContributionForGridItem = strategy!.maxContentContributionForGridItem(
      gridItem!, &gridLayoutState)
    let minContributionForGridItem = strategy!.minContributionForGridItem(
      gridItem!, &gridLayoutState)

    let spansFlexTracks = spanningItemCrossesFlexibleSizedTracks(itemSpan: gridSpan)

    if spanLength == 1 && !spansFlexTracks {
      sizeTrackToFitNonSpanningItem(
        gridSpan, gridItem!, allTracks[Int(trackIndex)], &gridLayoutState)
    } else {
      let minMaxTrackSizeWithGridSpan = MasonryMinMaxTrackSizeWithGridSpan(
        trackSize: MasonryMinMaxTrackSize(
          minContentSize: minContentContributionForGridItem,
          maxContentSize: maxContentContributionForGridItem, minSize: minContributionForGridItem),
        gridSpan: gridSpan)

      if spansFlexTracks {
        definiteItemSizesSpanFlexTrack.append(minMaxTrackSizeWithGridSpan)
      } else {
        definiteItemSizes[spanLength]!.append(minMaxTrackSizeWithGridSpan)
      }
    }
  }

  private func populateIndefiniteItems(
    _ gridItem: RenderBoxWrapper, _ spanLength: UInt32,
    _ indefiniteSpanSizes: inout [SpanLength: MasonryMinMaxTrackSize],
    _ gridLayoutState: inout GridLayoutState
  ) {
    let minContentContributionForGridItem = strategy!.minContentContributionForGridItem(
      gridItem, &gridLayoutState)
    let maxContentContributionForGridItem = strategy!.maxContentContributionForGridItem(
      gridItem, &gridLayoutState)
    let minContributionForGridItem = strategy!.minContributionForGridItem(
      gridItem, &gridLayoutState)

    let trackSize =
      indefiniteSpanSizes[spanLength]
      ?? MasonryMinMaxTrackSize(
        minContentSize: LayoutUnit(value: 0), maxContentSize: LayoutUnit(value: 0),
        minSize: LayoutUnit(value: 0))
    let minContentSize = max(trackSize.minContentSize, minContentContributionForGridItem)
    let maxContentSize = max(trackSize.maxContentSize, maxContentContributionForGridItem)
    let minSize = max(trackSize.minSize, minContributionForGridItem)
    indefiniteSpanSizes[spanLength] = MasonryMinMaxTrackSize(
      minContentSize: minContentSize, maxContentSize: maxContentSize, minSize: minSize)
  }

  // Track sizing algorithm steps. Note that the "Maximize Tracks" step is done
  // entirely inside the strategies, that's why we don't need an additional
  // method at this level.
  private func initializeTrackSizes() {
    assert(contentSizedTracksIndex.isEmpty)
    assert(flexibleSizedTracksIndex.isEmpty)
    assert(autoSizedTracksForStretchIndex.isEmpty)
    assert(!hasPercentSizedRowsIndefiniteHeight)
    assert(!hasFlexibleMaxTrackBreadth)

    let allTracks = tracks(direction: direction)
    let indefiniteHeight = direction == .ForRows && !renderGrid!.hasDefiniteLogicalHeight()
    let zero = LayoutUnit(value: UInt64(0))
    let maxSize = max(zero, availableSpace() ?? zero)
    // 1. Initialize per Grid track variables.
    for (i, track) in allTracks.enumerated() {
      let trackSize = calculateGridTrackSize(direction: direction, translatedIndex: UInt32(i))
      track.setCachedTrackSize(cachedTrackSize: trackSize)
      track.setBaseSize(initialBaseSize(trackSize: trackSize))
      track.setGrowthLimit(
        growthLimit: initialGrowthLimit(trackSize: trackSize, baseSize: track.baseSize()))
      track.setInfinitelyGrowable(infinitelyGrowable: false)

      if trackSize.isFitContent() {
        track.growthLimitCap = valueForLength(
          length: trackSize.fitContentTrackBreadth().length(), maximumValue: maxSize)
      }
      if trackSize.isContentSized() {
        contentSizedTracksIndex.append(UInt32(i))
      }
      if trackSize.maxTrackBreadth.isFlex() {
        flexibleSizedTracksIndex.append(UInt32(i))
      }
      if trackSize.hasAutoMaxTrackBreadth() && !trackSize.isFitContent() {
        autoSizedTracksForStretchIndex.append(UInt32(i))
      }

      if indefiniteHeight {
        let rawTrackSize = rawGridTrackSize(direction: direction, translatedIndex: UInt32(i))
        // Set the flag for repeating the track sizing algorithm. For flexible tracks, as per spec https://drafts.csswg.org/css-grid/#algo-flex-tracks,
        // in clause "if the free space is an indefinite length:", it states that "If using this flex fraction would cause the grid to be smaller than
        // the grid container’s min-width/height (or larger than the grid container’s max-width/height), then redo this step".
        if !hasFlexibleMaxTrackBreadth && rawTrackSize.maxTrackBreadth.isFlex() {
          hasFlexibleMaxTrackBreadth = true
        }
        if !hasPercentSizedRowsIndefiniteHeight
          && (rawTrackSize.minTrackBreadth.isPercentage()
            || rawTrackSize.maxTrackBreadth.isPercentage())
        {
          hasPercentSizedRowsIndefiniteHeight = true
        }
      }
    }
  }

  private func resolveIntrinsicTrackSizes(gridLayoutState: inout GridLayoutState) {
    if strategy!.isComputingSizeContainment() {
      handleInfinityGrowthLimit()
      return
    }

    let allTracks = tracks(direction: direction)
    var itemsSortedByIncreasingSpan: [GridItemWithSpan] = []
    var itemsCrossingFlexibleTracks: [GridItemWithSpan] = []
    let itemsSet = HashSet<RenderBoxWrapper>()

    if grid.hasGridItems() {
      for trackIndex in contentSizedTracksIndex {
        let iterator = GridIterator(grid: grid, direction: direction, fixedTrackIndex: trackIndex)
        let track = allTracks[Int(trackIndex)]

        accumulateIntrinsicSizesForTrack(
          track, trackIndex, iterator, &itemsSortedByIncreasingSpan,
          &itemsCrossingFlexibleTracks,
          itemsSet, LayoutUnit(value: UInt64(0)), &gridLayoutState)
      }
      itemsSortedByIncreasingSpan.sort()
    }

    var it = 0
    let end = itemsSortedByIncreasingSpan.count
    while it != end {
      let spanGroupRange = GridItemsSpanGroupRange(
        rangeStart: it,
        rangeEnd: itemsSortedByIncreasingSpan[it...].partitioningIndex(where: { itemWithSpan in
          itemsSortedByIncreasingSpan[it] < itemWithSpan
        }), span: itemsSortedByIncreasingSpan[...])
      increaseSizesToAccommodateSpanningItems(
        .NotCrossingFlexibleTracks, spanGroupRange, &gridLayoutState)
      it = spanGroupRange.rangeEnd
    }
    let tracksGroupRange = GridItemsSpanGroupRange(
      rangeStart: 0, rangeEnd: itemsCrossingFlexibleTracks.count,
      span: itemsCrossingFlexibleTracks[...])
    increaseSizesToAccommodateSpanningItems(
      .CrossingFlexibleTracks, tracksGroupRange, &gridLayoutState)
    handleInfinityGrowthLimit()
  }

  // Masonry Implementation of https://drafts.csswg.org/css-grid-2/#algo-content.
  // To implement Masonry performanently, we need to abandon the traditional Grid approach of treating
  // each item individually and start grouping items based on their span. A grid item has 3 major values we care about
  // the minContentSize, maxContentSize, and minSize. These values can be aggregated together and then the max will be chosen.
  // The main three scenarios we need to focus on are items that only span 1 track, items that span multiple tracks without crossing a flex track,
  // and items that span multiple tracks with crossing a flex track.
  //
  // Further details on the optimization can be found at https://fantasai.inkedblade.net/style/specs/masonry/performance.
  private func resolveIntrinsicTrackSizesMasonry(gridLayoutState: inout GridLayoutState) {
    if strategy!.isComputingSizeContainment() || !grid.hasGridItems() {
      handleInfinityGrowthLimit()
      return
    }
    var definiteAndIndefiniteItemsForMasonry = computeDefiniteAndIndefiniteItemsForMasonry(
      gridLayoutState: &gridLayoutState)

    // Update intrinsic tracks with single span items that do not cross flex tracks.
    let allTracks = tracks(direction: direction)

    if let singleTrackSpanSize = definiteAndIndefiniteItemsForMasonry.indefiniteSpanSizes[1] {
      for trackIndex in contentSizedTracksIndex {
        let track = allTracks[Int(trackIndex)]

        let itemSpan = GridSpan.translatedDefiniteGridSpan(
          startLine: Int32(trackIndex), endLine: Int32(trackIndex + 1))
        if spanningItemCrossesFlexibleSizedTracks(itemSpan: itemSpan) {
          continue
        }

        sizeTrackToFitSingleSpanMasonryGroup(
          span: itemSpan, masonryIndefiniteItems: singleTrackSpanSize, track: track)
      }
    }

    convertIndefiniteItemsToDefiniteMasonry(
      indefiniteSpanSizes: definiteAndIndefiniteItemsForMasonry.indefiniteSpanSizes,
      definiteItemSizes: &definiteAndIndefiniteItemsForMasonry.definiteItemSizes,
      definiteItemSizesSpanFlexTracks: &definiteAndIndefiniteItemsForMasonry
        .definiteItemSizesSpanFlexTrack)

    increaseSizesToAccommodateSpanningItemsMasonry(
      definiteItemSizes: definiteAndIndefiniteItemsForMasonry.definiteItemSizes)

    increaseSizesToAccommodateSpanningItemsMasonryWithFlex(
      definiteItemSizesSpanFlexTracks:
        definiteAndIndefiniteItemsForMasonry.definiteItemSizesSpanFlexTrack[...])

    handleInfinityGrowthLimit()
  }

  private func stretchFlexibleTracks(freeSpace: LayoutUnit?, gridLayoutState: inout GridLayoutState)
  {
    if flexibleSizedTracksIndex.isEmpty {
      return
    }

    var flexFraction = strategy!.findUsedFlexFraction(
      flexibleSizedTracksIndex: flexibleSizedTracksIndex[...], direction: direction,
      freeSpace: freeSpace, gridLayoutState: &gridLayoutState)

    var totalGrowth = LayoutUnit()
    var increments = [LayoutUnit](repeating: LayoutUnit(), count: flexibleSizedTracksIndex.count)
    computeFlexSizedTracksGrowth(
      flexFraction: flexFraction, increments: &increments, totalGrowth: &totalGrowth)

    if strategy!.recomputeUsedFlexFractionIfNeeded(
      flexFraction: &flexFraction, totalGrowth: &totalGrowth)
    {
      totalGrowth = LayoutUnit(value: UInt64(0))
      computeFlexSizedTracksGrowth(
        flexFraction: flexFraction, increments: &increments, totalGrowth: &totalGrowth)
    }

    var i = 0
    let allTracks = tracks(direction: direction)
    for trackIndex in flexibleSizedTracksIndex {
      let track = allTracks[Int(trackIndex)]
      let increment = increments[i]
      if increment.bool() {
        track.setBaseSize(track.baseSize() + increment)
      }
      i += 1
    }
    if let freeSpace = self.freeSpace(direction: direction) {
      setFreeSpace(direction: direction, freeSpace: freeSpace - totalGrowth)
    }
    maxContentSize += totalGrowth
  }

  private func stretchAutoTracks() {
    let currentFreeSpace = strategy!.freeSpaceForStretchAutoTracksStep()
    if autoSizedTracksForStretchIndex.isEmpty || currentFreeSpace <= Int32(0)
      || (renderGrid!.contentAlignment(direction: direction).distribution != .Stretch)
    {
      return
    }

    let allTracks = tracks(direction: direction)
    let numberOfAutoSizedTracks = UInt32(autoSizedTracksForStretchIndex.count)
    let sizeToIncrease = currentFreeSpace / numberOfAutoSizedTracks
    for trackIndex in autoSizedTracksForStretchIndex {
      let track = allTracks[Int(trackIndex)]
      track.setBaseSize(track.baseSize() + sizeToIncrease)
    }
    setFreeSpace(direction: direction, freeSpace: LayoutUnit(value: UInt64(0)))
  }

  private func accumulateIntrinsicSizesForTrack(
    _ track: GridTrack, _ trackIndex: UInt32, _ iterator: GridIterator,
    _ itemsSortedByIncreasingSpan: inout [GridItemWithSpan],
    _ itemsCrossingFlexibleTracks: inout [GridItemWithSpan],
    _ itemsSet: HashSet<RenderBoxWrapper>, _ currentAccumulatedMbp: LayoutUnit,
    _ gridLayoutState: inout GridLayoutState
  ) {
    var gridItem = iterator.nextGridItem()
    while gridItem != nil {
      accumulateIntrinsicSizes(
        gridItem!, track, trackIndex, iterator, &itemsSortedByIncreasingSpan,
        &itemsCrossingFlexibleTracks, itemsSet, currentAccumulatedMbp, &gridLayoutState)
      gridItem = iterator.nextGridItem()
    }
  }

  private func accumulateIntrinsicSizes(
    _ gridItem: RenderBoxWrapper, _ track: GridTrack, _ trackIndex: UInt32,
    _ iterator: GridIterator, _ itemsSortedByIncreasingSpan: inout [GridItemWithSpan],
    _ itemsCrossingFlexibleTracks: inout [GridItemWithSpan], _ itemsSet: HashSet<RenderBoxWrapper>,
    _ currentAccumulatedMbp: LayoutUnit, _ gridLayoutState: inout GridLayoutState
  ) {
    let isNewEntry = itemsSet.add(gridItem).isNewEntry
    let span = renderGrid!.gridSpanForGridItem(gridItem: gridItem, direction: direction)

    if let inner = gridItem as? RenderGridWrapper,
      inner.isSubgridInParentDirection(parentDirection: iterator.direction)
    {
      // Contribute the mbp of wrapper to the first and last tracks that we span.
      let subgridSpan = (inner.parent() as! RenderGridWrapper).gridSpanForGridItem(
        gridItem: inner, direction: iterator.direction)
      let accumulatedMbpWithSubgrid =
        currentAccumulatedMbp
        + computeSubgridMarginBorderPadding(
          renderGrid!, direction, track, trackIndex, span, inner)
      track.setBaseSize(
        max(
          track.baseSize(),
          accumulatedMbpWithSubgrid
            + (extraMarginFromSubgridAncestorGutters(
              gridItem, span, trackIndex, iterator.direction) ?? LayoutUnit(value: UInt64(0)))))

      let subgridIterator = GridIterator.createForSubgrid(inner, iterator, subgridSpan)

      accumulateIntrinsicSizesForTrack(
        track, trackIndex, subgridIterator, &itemsSortedByIncreasingSpan,
        &itemsCrossingFlexibleTracks, itemsSet, accumulatedMbpWithSubgrid, &gridLayoutState)
      return
    }

    if !isNewEntry {
      return
    }

    if spanningItemCrossesFlexibleSizedTracks(itemSpan: span) {
      itemsCrossingFlexibleTracks.append(GridItemWithSpan(gridItem: gridItem, span: span))
    } else if span.integerSpan() == 1 {
      sizeTrackToFitNonSpanningItem(span, gridItem, track, &gridLayoutState)
    } else {
      itemsSortedByIncreasingSpan.append(GridItemWithSpan(gridItem: gridItem, span: span))
    }
  }

  private func copyUsedTrackSizesForSubgrid() -> Bool {
    let outer = renderGrid!.parent() as! RenderGridWrapper
    let parentAlgo = outer.trackSizingAlgorithm!
    let direction = GridLayoutFunctions.flowAwareDirectionForParent(
      grid: renderGrid!, parent: outer, direction: direction)
    let parentTracks = parentAlgo.tracks(direction: direction)

    if parentTracks.isEmpty {
      return false
    }

    let span = outer.gridSpanForGridItem(gridItem: renderGrid!, direction: direction)
    var allTracks = tracks(direction: direction)
    let numTracks = allTracks.count
    assert((parentTracks.count - 1) >= (numTracks - 1 + Int(span.startLine())))
    for i in 0..<numTracks {
      allTracks[i] = parentTracks[i + Int(span.startLine())]
    }

    if GridLayoutFunctions.isSubgridReversedDirection(
      grid: outer, outerDirection: direction, subgrid: renderGrid!)
    {
      allTracks.reverse()
    }

    let startMBP =
      (direction == .ForColumns)
      ? renderGrid!.marginAndBorderAndPaddingStart() : renderGrid!.marginAndBorderAndPaddingBefore()
    removeSubgridMarginBorderPaddingFromTracks(tracks: &allTracks, mbp: startMBP, forwards: true)
    let endMBP =
      (direction == .ForColumns)
      ? renderGrid!.marginAndBorderAndPaddingEnd() : renderGrid!.marginAndBorderAndPaddingAfter()
    removeSubgridMarginBorderPaddingFromTracks(tracks: &allTracks, mbp: endMBP, forwards: false)

    let gapDifference =
      (renderGrid!.gridGap(
        direction: direction, availableSize: availableSpace(direction: direction))
        - outer.gridGap(direction: direction)) / 2
    for i in 0..<numTracks {
      var size = allTracks[i].baseSize()
      if i != 0 {
        size -= gapDifference
      }
      if i != numTracks - 1 {
        size -= gapDifference
      }
      allTracks[i].setBaseSize(size)
    }
    return true
  }

  // State machine.
  private func advanceNextState() {
    switch sizingState {
    case .ColumnSizingFirstIteration:
      sizingState = .RowSizingFirstIteration
    case .RowSizingFirstIteration:
      sizingState =
        strategy!.isComputingSizeContainment()
        ? .RowSizingExtraIterationForSizeContainment : .ColumnSizingSecondIteration
    case .RowSizingExtraIterationForSizeContainment:
      sizingState = .ColumnSizingSecondIteration
    case .ColumnSizingSecondIteration:
      sizingState = .RowSizingSecondIteration
    case .RowSizingSecondIteration:
      sizingState = .ColumnSizingFirstIteration
    }
  }

  private func isValidTransition() -> Bool {
    switch sizingState {
    case .ColumnSizingFirstIteration, .ColumnSizingSecondIteration:
      return direction == .ForColumns
    case .RowSizingFirstIteration, .RowSizingExtraIterationForSizeContainment,
      .RowSizingSecondIteration:
      return direction == .ForRows
    }
  }

  private func isDirectionInMasonryDirection() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Data.
  private func wasSetup() -> Bool { return strategy != nil }

  private var needsSetup = true
  private var hasPercentSizedRowsIndefiniteHeight = false
  private var hasFlexibleMaxTrackBreadth = false
  private var availableSpaceRows: LayoutUnit? = nil
  private var availableSpaceColumns: LayoutUnit? = nil

  private let freeSpaceColumns: LayoutUnit? = nil
  private let freeSpaceRows: LayoutUnit? = nil

  private var contentSizedTracksIndex: [UInt32] = []
  private var flexibleSizedTracksIndex: [UInt32] = []
  private var autoSizedTracksForStretchIndex: [UInt32] = []

  var direction: GridTrackSizingDirection
  private var sizingOperation: SizingOperation

  // Required to be public by RenderGrid. Try to minimize the exposed surface.
  let grid: Grid

  let renderGrid: RenderGridWrapper?
  private var strategy: GridTrackSizingAlgorithmStrategy?

  // The track sizing algorithm is used for both layout and intrinsic size
  // computation. We're normally just interested in intrinsic inline sizes
  // (a.k.a widths in most of the cases) for the computeIntrinsicLogicalWidths()
  // computations. That's why we don't need to keep around different values for
  // rows/columns.
  var minContentSize: LayoutUnit
  var maxContentSize: LayoutUnit

  enum SizingState {
    case ColumnSizingFirstIteration
    case RowSizingFirstIteration
    case RowSizingExtraIterationForSizeContainment
    case ColumnSizingSecondIteration
    case RowSizingSecondIteration
  }
  var sizingState: SizingState

  private var baselineAlignment: GridBaselineAlignment

  private class BaselineItemsCache {
    func set(_ key: RenderBoxWrapper, _ value: Bool) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func contains(_ key: RenderBoxWrapper) -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func keys() -> ArraySlice<RenderBoxWrapper> {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func deepCopy() -> BaselineItemsCache {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  private let columnBaselineItemsMap: BaselineItemsCache
  private let rowBaselineItemsMap: BaselineItemsCache

  private let rowSubgridsWithBaselineAlignedItems: WeakHashSet<RenderGridWrapper>

  // This is a RAII class used to ensure that the track sizing algorithm is
  // executed as it is supposed to be, i.e., first resolve columns and then
  // rows. Only if required a second iteration is run following the same order,
  // first columns and then rows.
  private class StateMachine {
    init(algorithm: GridTrackSizingAlgorithm) {
      self.algorithm = algorithm
      assert(self.algorithm.isValidTransition())
      assert(!self.algorithm.needsSetup)
    }

    deinit {
      algorithm.advanceNextState()
      algorithm.needsSetup = true
    }

    private var algorithm: GridTrackSizingAlgorithm
  }
}

private class GridTrackSizingAlgorithmStrategy {
  func minContentContributionForGridItem(
    _ gridItem: RenderBoxWrapper, _ gridLayoutState: inout GridLayoutState
  ) -> LayoutUnit {
    let gridItemInlineDirection = GridLayoutFunctions.flowAwareDirectionForGridItem(
      grid: renderGrid()!, gridItem: gridItem, direction: .ForColumns)
    if direction() == gridItemInlineDirection {
      if isComputingInlineSizeContainment() {
        return LayoutUnit()
      }

      let needsGridItemMinContentContributionForSecondColumnPass =
        sizingState() == .ColumnSizingSecondIteration
        && gridLayoutState.containsLayoutRequirementForGridItem(
          gridItem: gridItem, layoutRequirement: .MinContentContributionForSecondColumnPass)

      // FIXME: It's unclear if we should return the intrinsic width or the preferred width.
      // See http://lists.w3.org/Archives/Public/www-style/2013Jan/0245.html
      if gridItem.needsPreferredWidthsRecalculation()
        || needsGridItemMinContentContributionForSecondColumnPass
      {
        gridItem.setPreferredLogicalWidthsDirty(shouldBeDirty: true)
      }

      if needsGridItemMinContentContributionForSecondColumnPass {
        let rowSize = renderGrid()!.gridAreaBreadthForGridItemIncludingAlignmentOffsets(
          gridItem: gridItem, direction: .ForRows)
        let stretchedSize =
          !GridLayoutFunctions.isOrthogonalGridItem(grid: renderGrid()!, gridItem: gridItem)
          ? gridItem.constrainLogicalHeightByMinMax(
            logicalHeight: rowSize, intrinsicContentHeight: nil)
          : gridItem.constrainLogicalWidthInFragmentByMinMax(
            logicalWidth: rowSize, availableWidth: renderGrid()!.contentWidth(), cb: renderGrid()!,
            fragment: nil)
        GridLayoutFunctions.setOverridingContentSizeForGridItem(
          renderGrid()!, gridItem, stretchedSize, .ForRows)
      }

      let minContentLogicalWidth = gridItem.minPreferredLogicalWidth()

      if needsGridItemMinContentContributionForSecondColumnPass {
        GridLayoutFunctions.clearOverridingContentSizeForGridItem(renderGrid()!, gridItem, .ForRows)
      }

      let minLogicalWidth = { () in
        let gridItemLogicalMinWidth = gridItem.style().logicalMinWidth()

        if gridItemLogicalMinWidth.isFixed() {
          return LayoutUnit(value: gridItemLogicalMinWidth.value())
        }
        if gridItemLogicalMinWidth.isMaxContent() {
          return gridItem.maxPreferredLogicalWidth()
        }

        // FIXME: We should be able to handle other values for the logical min width.
        return LayoutUnit(value: UInt64(0))
      }()

      return max(minContentLogicalWidth, minLogicalWidth)
        + GridLayoutFunctions.marginLogicalSizeForGridItem(
          grid: renderGrid()!, direction: gridItemInlineDirection, gridItem: gridItem)
        + algorithm.baselineOffsetForGridItem(
          gridItem: gridItem, baselineAxis: gridAxisForDirection(direction: direction()))
    }

    if updateOverridingContainingBlockContentSizeForGridItem(gridItem, gridItemInlineDirection) {
      gridItem.setNeedsLayout(markParents: .MarkOnlyThis)
      // For a grid item with relative width constraints to the grid area, such as percentaged paddings, we reset the overridingContainingBlockContentSizeForGridItem value for columns when we are executing a definite strategy
      // for columns. Since we have updated the overridingContainingBlockContentSizeForGridItem inline-axis/width value here, we might need to recompute the grid item's relative width. For some cases, we probably will not
      // be able to do it during the RenderGrid::layoutGridItems() function as the grid area does't change there any more. Also, as we are doing a layout inside GridTrackSizingAlgorithmStrategy::logicalHeightForGridItem()
      // function, let's take the advantage and set it here.
      if shouldClearOverridingContainingBlockContentSizeForGridItem(
        gridItem, gridItemInlineDirection)
      {
        gridItem.setPreferredLogicalWidthsDirty(shouldBeDirty: true)
      }
    }
    return logicalHeightForGridItem(gridItem, &gridLayoutState)
  }

  func maxContentContributionForGridItem(
    _ gridItem: RenderBoxWrapper, _ gridLayoutState: inout GridLayoutState
  ) -> LayoutUnit {
    let gridItemInlineDirection = GridLayoutFunctions.flowAwareDirectionForGridItem(
      grid: renderGrid()!, gridItem: gridItem, direction: .ForColumns)
    if direction() == gridItemInlineDirection {
      if isComputingInlineSizeContainment() {
        return LayoutUnit()
      }
      // FIXME: It's unclear if we should return the intrinsic width or the preferred width.
      // See http://lists.w3.org/Archives/Public/www-style/2013Jan/0245.html
      if gridItem.needsPreferredWidthsRecalculation() {
        gridItem.setPreferredLogicalWidthsDirty(shouldBeDirty: true)
      }
      return gridItem.maxPreferredLogicalWidth()
        + GridLayoutFunctions.marginLogicalSizeForGridItem(
          grid: renderGrid()!, direction: gridItemInlineDirection, gridItem: gridItem)
        + algorithm.baselineOffsetForGridItem(
          gridItem: gridItem, baselineAxis: gridAxisForDirection(direction: direction()))
    }

    if updateOverridingContainingBlockContentSizeForGridItem(gridItem, gridItemInlineDirection) {
      gridItem.setNeedsLayout(markParents: .MarkOnlyThis)
    }
    return logicalHeightForGridItem(gridItem, &gridLayoutState)
  }

  func minContributionForGridItem(
    _ gridItem: RenderBoxWrapper, _ gridLayoutState: inout GridLayoutState
  ) -> LayoutUnit {
    let gridItemInlineDirection = GridLayoutFunctions.flowAwareDirectionForGridItem(
      grid: renderGrid()!, gridItem: gridItem, direction: .ForColumns)
    let isRowAxis = direction() == gridItemInlineDirection
    if isRowAxis && isComputingInlineSizeContainment() {
      return LayoutUnit()
    }
    let gridItemSize =
      isRowAxis ? gridItem.style().logicalWidth() : gridItem.style().logicalHeight()
    if !gridItemSize.isAuto() && !gridItemSize.isPercentOrCalculated() {
      return minContentContributionForGridItem(gridItem, &gridLayoutState)
    }

    let gridItemMinSize =
      isRowAxis ? gridItem.style().logicalMinWidth() : gridItem.style().logicalMinHeight()
    let overflowIsVisible =
      isRowAxis
      ? gridItem.effectiveOverflowInlineDirection() == .Visible
      : gridItem.effectiveOverflowBlockDirection() == .Visible
    let baselineShim = algorithm.baselineOffsetForGridItem(
      gridItem: gridItem, baselineAxis: gridAxisForDirection(direction: direction()))

    if gridItemMinSize.isAuto() && overflowIsVisible {
      var minSize = minContentContributionForGridItem(gridItem, &gridLayoutState)
      let span = algorithm.renderGrid!.gridSpanForGridItem(
        gridItem: gridItem, direction: direction())

      var maxBreadth = LayoutUnit()
      let allTracks = algorithm.tracks(direction: direction())
      var allFixed = true
      for trackPosition in span {
        let trackSize = allTracks[Int(trackPosition)].cachedTrackSize()
        if trackSize.maxTrackBreadth.isFlex() && span.integerSpan() > 1 {
          return LayoutUnit()
        }
        if !trackSize.hasFixedMaxTrackBreadth() {
          allFixed = false
        } else if allFixed {
          maxBreadth += valueForLength(
            length: trackSize.maxTrackBreadth.length(),
            maximumValue: availableSpace() ?? LayoutUnit(value: UInt64(0)))
        }
      }
      if !allFixed {
        return minSize
      }
      if minSize > maxBreadth {
        var marginAndBorderAndPadding = GridLayoutFunctions.marginLogicalSizeForGridItem(
          grid: renderGrid()!, direction: direction(), gridItem: gridItem)
        marginAndBorderAndPadding +=
          isRowAxis
          ? gridItem.borderAndPaddingLogicalWidth() : gridItem.borderAndPaddingLogicalHeight()
        minSize = max(maxBreadth, marginAndBorderAndPadding + baselineShim)
      }
      return minSize
    }

    let gridAreaSize = algorithm.gridAreaBreadthForGridItem(
      gridItem: gridItem, direction: gridItemInlineDirection)
    return minLogicalSizeForGridItem(gridItem, gridItemMinSize, gridAreaSize) + baselineShim
  }

  func maximizeTracks(tracks: ArraySlice<GridTrack>, freeSpace: LayoutUnit?) {
    fatalError("Not reached")
  }

  func findUsedFlexFraction(
    flexibleSizedTracksIndex: ArraySlice<UInt32>, direction: GridTrackSizingDirection,
    freeSpace: LayoutUnit?, gridLayoutState: inout GridLayoutState
  ) -> Float64 {
    fatalError("Not reached")
  }

  func recomputeUsedFlexFractionIfNeeded(flexFraction: inout Float64, totalGrowth: inout LayoutUnit)
    -> Bool
  {
    fatalError("Not reached")
  }

  func freeSpaceForStretchAutoTracksStep() -> LayoutUnit { fatalError("Not reached") }

  func isComputingSizeContainment() -> Bool { fatalError("Not reached") }

  func isComputingInlineSizeContainment() -> Bool { fatalError("Not reached") }

  func isComputingSizeOrInlineSizeContainment() -> Bool { fatalError("Not reached") }

  init(algorithm: GridTrackSizingAlgorithm) { self.algorithm = algorithm }

  private func minLogicalSizeForGridItem(
    _ gridItem: RenderBoxWrapper, _ gridItemMinSize: LengthWrapper, _ availableSize: LayoutUnit?
  ) -> LayoutUnit {
    let gridItemInlineDirection = GridLayoutFunctions.flowAwareDirectionForGridItem(
      grid: renderGrid()!, gridItem: gridItem, direction: .ForColumns)
    let isRowAxis = direction() == gridItemInlineDirection
    if isRowAxis {
      return isComputingInlineSizeContainment()
        ? LayoutUnit(value: UInt64(0))
        : gridItem.computeLogicalWidthInFragmentUsing(
          widthType: .MinSize, logicalWidth: gridItemMinSize,
          availableLogicalWidth: availableSize ?? LayoutUnit(value: 0), cb: renderGrid()!,
          fragment: nil)
          + GridLayoutFunctions.marginLogicalSizeForGridItem(
            grid: renderGrid()!, direction: gridItemInlineDirection, gridItem: gridItem)
    }
    let overrideSizeHasChanged = updateOverridingContainingBlockContentSizeForGridItem(
      gridItem, gridItemInlineDirection, availableSize)
    layoutGridItemForMinSizeComputation(gridItem, overrideSizeHasChanged)
    let gridItemBlockDirection = GridLayoutFunctions.flowAwareDirectionForGridItem(
      grid: renderGrid()!, gridItem: gridItem, direction: .ForRows)
    return
      (gridItem.computeLogicalHeightUsing(
        heightType: .MinSize, height: gridItemMinSize, intrinsicContentHeight: nil)
      ?? LayoutUnit(value: 0))
      + GridLayoutFunctions.marginLogicalSizeForGridItem(
        grid: renderGrid()!, direction: gridItemBlockDirection, gridItem: gridItem)
  }

  private func layoutGridItemForMinSizeComputation(
    _ gridItem: RenderBoxWrapper, _ overrideSizeHasChanged: Bool
  ) { fatalError("Not reached") }

  // GridTrackSizingAlgorithmStrategy.
  private func logicalHeightForGridItem(
    _ gridItem: RenderBoxWrapper, _ gridLayoutState: inout GridLayoutState
  ) -> LayoutUnit {
    let gridItemBlockDirection = GridLayoutFunctions.flowAwareDirectionForGridItem(
      grid: renderGrid()!, gridItem: gridItem, direction: .ForRows)
    // If |gridItem| has a relative logical height, we shouldn't let it override its intrinsic height, which is
    // what we are interested in here. Thus we need to set the block-axis override size to nullopt (no possible resolution).
    let hasOverridingContainingBlockContentSizeForGridItem = { () in
      if let overridingContainingBlockContentSizeForGridItem =
        GridLayoutFunctions.overridingContainingBlockContentSizeForGridItem(
          gridItem: gridItem, direction: .ForRows),
        overridingContainingBlockContentSizeForGridItem != nil
      {
        return true
      }
      return false
    }
    if hasOverridingContainingBlockContentSizeForGridItem()
      && shouldClearOverridingContainingBlockContentSizeForGridItem(gridItem, .ForRows)
    {
      setOverridingContainingBlockContentSizeForGridItem(
        renderGrid()!, gridItem, gridItemBlockDirection, nil)
      gridItem.setNeedsLayout(markParents: .MarkOnlyThis)

      if renderGrid()!.canSetColumnAxisStretchRequirementForItem(gridItem: gridItem) {
        gridLayoutState.setLayoutRequirementForGridItem(
          gridItem: gridItem, layoutRequirement: .NeedsColumnAxisStretchAlignment)
      }
    }

    // We need to clear the stretched content size to properly compute logical height during layout.
    if gridItem.needsLayout() {
      gridItem.clearOverridingContentSize()
    }

    gridItem.layoutIfNeeded()
    return gridItem.logicalHeight()
      + GridLayoutFunctions.marginLogicalSizeForGridItem(
        grid: renderGrid()!, direction: gridItemBlockDirection, gridItem: gridItem)
      + algorithm.baselineOffsetForGridItem(
        gridItem: gridItem, baselineAxis: gridAxisForDirection(direction: direction()))
  }

  private func updateOverridingContainingBlockContentSizeForGridItem(
    _ gridItem: RenderBoxWrapper, _ direction: GridTrackSizingDirection,
    _ overrideSize: LayoutUnit? = nil
  ) -> Bool {
    var overrideSize = overrideSize
    if overrideSize == nil {
      overrideSize = algorithm.gridAreaBreadthForGridItem(gridItem: gridItem, direction: direction)
    }

    if CPtrToInt(renderGrid()?.p) != CPtrToInt(gridItem.parent()?.p) {
      // If |gridItem| is part of a subgrid, find the nearest ancestor this is directly part of this grid
      // (either by being a child of the grid, or via being subgridded in this dimension.
      var grid = gridItem.parent() as! RenderGridWrapper
      var subgridDirection = GridLayoutFunctions.flowAwareDirectionForGridItem(
        grid: renderGrid()!, gridItem: grid, direction: direction)
      while CPtrToInt(grid.parent()?.p) != CPtrToInt(renderGrid()?.p)
        && !grid.isSubgridOf(direction: subgridDirection, ancestor: renderGrid()!)
      {
        grid = grid.parent() as! RenderGridWrapper
        subgridDirection = GridLayoutFunctions.flowAwareDirectionForGridItem(
          grid: renderGrid()!, gridItem: grid, direction: direction)
      }

      if CPtrToInt(grid.p) == CPtrToInt(gridItem.parent()?.p)
        && grid.isSubgrid(direction: subgridDirection)
      {
        // If the item is subgridded in this direction (and thus the tracks it covers are tracks
        // owned by this sizing algorithm), then we want to take the breadth of the tracks we occupy,
        // and subtract any space occupied by the subgrid itself (and any ancestor subgrids).
        overrideSize! -= GridLayoutFunctions.extraMarginForSubgridAncestors(
          direction: subgridDirection, gridItem: gridItem
        ).extraTotalMargin()
      } else {
        // Otherwise the tracks that this grid item covers (in this non-subgridded axis) are owned
        // by one of the intermediate RenderGrids (which are subgrids in the other axis), which may
        // be |grid| or a descendent.
        // Set the override size for |grid| (which is part of the outer grid), and force a layout
        // so that it computes the track sizes for the non-subgridded dimension and makes the size
        // of |gridItem| available.
        let overrideSizeHasChanged = updateOverridingContainingBlockContentSizeForGridItem(
          grid, direction)
        layoutGridItemForMinSizeComputation(grid, overrideSizeHasChanged)
        return overrideSizeHasChanged
      }
    }

    if let overridingContainingBlockContentSizeForGridItem =
      GridLayoutFunctions.overridingContainingBlockContentSizeForGridItem(
        gridItem: gridItem, direction: direction),
      overridingContainingBlockContentSizeForGridItem! == overrideSize
    {
      return false
    }

    setOverridingContainingBlockContentSizeForGridItem(
      renderGrid()!, gridItem, direction, overrideSize)
    return true
  }

  private func direction() -> GridTrackSizingDirection { return algorithm.direction }

  private func sizingState() -> GridTrackSizingAlgorithm.SizingState {
    return algorithm.sizingState
  }

  private func renderGrid() -> RenderGridWrapper? { return algorithm.renderGrid }

  private func availableSpace() -> LayoutUnit? { return algorithm.availableSpace() }

  private let algorithm: GridTrackSizingAlgorithm
}
