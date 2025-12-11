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

class GridTrack {
  func baseSize() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func unclampedBaseSize() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setBaseSize(baseSize: LayoutUnit) {
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

  func setInfinitelyGrowable(infinitelyGrowable: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setGrowthLimitCap(growthLimitCap: LayoutUnit?) {
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
}

private func gridDirectionForAxis(axis: GridAxis) -> GridTrackSizingDirection {
  return axis == .GridRowAxis ? .ForColumns : .ForRows
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
  phase: TrackSizeComputationPhase, track: GridTrack, restriction: TrackSizeRestriction
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
  phase: TrackSizeComputationPhase, track: GridTrack
) {
  switch phase {
  case .ResolveIntrinsicMinimums, .ResolveContentBasedMinimums, .ResolveMaxContentMinimums:
    track.setBaseSize(baseSize: track.plannedSize())
  case .ResolveIntrinsicMaximums, .ResolveMaxContentMaximums:
    track.setGrowthLimit(growthLimit: track.plannedSize())
  case .MaximizeTracks:
    fatalError("Not reached")
  }
}

private func trackShouldGrowBeyondGrowthLimitsForTrackSizeComputationPhase(
  phase: TrackSizeComputationPhase, trackSize: GridTrackSize
) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func markAsInfinitelyGrowableForTrackSizeComputationPhase(
  phase: TrackSizeComputationPhase, track: GridTrack
) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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
    tracks[i].setBaseSize(baseSize: size)

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

  private func availableSpace() -> LayoutUnit? {
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

  private func sizeTrackToFitSingleSpanMasonryGroup(
    span: GridSpan, masonryIndefiniteItems: MasonryMinMaxTrackSize, track: GridTrack
  ) {
    let trackPosition = Int(span.startLine())
    let trackSize = tracks(direction: direction)[trackPosition].cachedTrackSize()

    if trackSize.hasMinContentMinTrackBreadth() {
      track.setBaseSize(baseSize: max(track.baseSize(), masonryIndefiniteItems.minContentSize))
    } else if trackSize.hasMaxContentMinTrackBreadth() {
      track.setBaseSize(baseSize: max(track.baseSize(), masonryIndefiniteItems.maxContentSize))
    } else if trackSize.hasAutoMinTrackBreadth() {
      track.setBaseSize(baseSize: max(track.baseSize(), masonryIndefiniteItems.minSize))
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
        plannedSize: trackSizeForTrackSizeComputationPhase(
          phase: phase, track: track, restriction: .AllowInfinity))
    }

    var growBeyondGrowthLimitsTracks: [GridTrack] = []
    var filteredTracks: [GridTrack] = []

    for definiteItem in definiteItemSizes {
      let itemSpan = definiteItem.gridSpan
      assert(itemSpan.integerSpan() > 1)

      filteredTracks.removeAll()
      growBeyondGrowthLimitsTracks.removeAll()
      var spanningTracksSize = LayoutUnit()
      for trackPosition in itemSpan {
        let track = allTracks[Int(trackPosition)]
        let trackSize = track.cachedTrackSize()
        spanningTracksSize += trackSizeForTrackSizeComputationPhase(
          phase: phase, track: track, restriction: .ForbidInfinity)

        if !shouldProcessTrackForTrackSizeComputationPhase(phase: phase, trackSize: trackSize) {
          continue
        }

        filteredTracks.append(track)

        if trackShouldGrowBeyondGrowthLimitsForTrackSizeComputationPhase(
          phase: phase, trackSize: trackSize)
        {
          growBeyondGrowthLimitsTracks.append(track)
        }
      }

      if filteredTracks.isEmpty {
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
        growBeyondGrowthLimitsTracks.isEmpty
        ? filteredTracks[...] : growBeyondGrowthLimitsTracks[...]
      distributeSpaceToTracks(
        variant: .NotCrossingFlexibleTracks, phase: phase, tracks: filteredTracks[...],
        growBeyondGrowthLimitsTracks: tracksToGrowBeyondGrowthLimits[...],
        freeSpace: &extraSpace)
    }

    for trackIndex in contentSizedTracksIndex {
      let track = allTracks[Int(trackIndex)]
      markAsInfinitelyGrowableForTrackSizeComputationPhase(phase: phase, track: track)
      updateTrackSizeForTrackSizeComputationPhase(phase: phase, track: track)
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
        plannedSize: trackSizeForTrackSizeComputationPhase(
          phase: phase, track: track, restriction: .AllowInfinity))
    }

    var growBeyondGrowthLimitsTracks: [GridTrack] = []
    var filteredTracks: [GridTrack] = []

    for item in definiteItemSizesSpanFlexTracks {
      let itemSpan = item.gridSpan

      filteredTracks.removeAll()
      growBeyondGrowthLimitsTracks.removeAll()
      var spanningTracksSize = LayoutUnit()
      for trackPosition in itemSpan {
        let track = allTracks[Int(trackPosition)]
        let trackSize = track.cachedTrackSize()
        spanningTracksSize += trackSizeForTrackSizeComputationPhase(
          phase: phase, track: track, restriction: .ForbidInfinity)
        if !trackSize.maxTrackBreadth.isFlex() {
          continue
        }
        if !shouldProcessTrackForTrackSizeComputationPhase(phase: phase, trackSize: trackSize) {
          continue
        }

        filteredTracks.append(track)

        if trackShouldGrowBeyondGrowthLimitsForTrackSizeComputationPhase(
          phase: phase, trackSize: trackSize)
        {
          growBeyondGrowthLimitsTracks.append(track)
        }
      }

      if filteredTracks.isEmpty {
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
        growBeyondGrowthLimitsTracks.isEmpty
        ? filteredTracks[...] : growBeyondGrowthLimitsTracks[...]
      distributeSpaceToTracks(
        variant: .CrossingFlexibleTracks, phase: phase, tracks: filteredTracks[...],
        growBeyondGrowthLimitsTracks: tracksToGrowBeyondGrowthLimits[...], freeSpace: &extraSpace)
    }

    for trackIndex in contentSizedTracksIndex {
      let track = allTracks[Int(trackIndex)]
      markAsInfinitelyGrowableForTrackSizeComputationPhase(phase: phase, track: track)
      updateTrackSizeForTrackSizeComputationPhase(phase: phase, track: track)
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
    variant: TrackSizeComputationVariant, phase: TrackSizeComputationPhase,
    tracks: ArraySlice<GridTrack>, growBeyondGrowthLimitsTracks: ArraySlice<GridTrack>,
    freeSpace: inout LayoutUnit
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func computeBaselineAlignmentContext() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func participateInBaselineAlignment(gridItem: RenderBoxWrapper, baselineAxis: GridAxis)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
      track.setGrowthLimitCap(growthLimitCap: nil)
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
      track.setBaseSize(baseSize: initialBaseSize(trackSize: trackSize))
      track.setGrowthLimit(
        growthLimit: initialGrowthLimit(trackSize: trackSize, baseSize: track.baseSize()))
      track.setInfinitelyGrowable(infinitelyGrowable: false)

      if trackSize.isFitContent() {
        track.setGrowthLimitCap(
          growthLimitCap: valueForLength(
            length: trackSize.fitContentTrackBreadth().length(), maximumValue: maxSize))
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
        track.setBaseSize(baseSize: track.baseSize() + increment)
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
      track.setBaseSize(baseSize: track.baseSize() + sizeToIncrease)
    }
    setFreeSpace(direction: direction, freeSpace: LayoutUnit(value: UInt64(0)))
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
      allTracks[i].setBaseSize(baseSize: size)
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

  private var direction: GridTrackSizingDirection
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
  private var sizingState: SizingState

  private let baselineAlignment: GridBaselineAlignment

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

  func isComputingSizeOrInlineSizeContainment() -> Bool { fatalError("Not reached") }

  init(algorithm: GridTrackSizingAlgorithm) { self.algorithm = algorithm }

  private let algorithm: GridTrackSizingAlgorithm
}
