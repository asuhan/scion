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

enum SizingOperation {
  case TrackSizing
  case IntrinsicSizeComputation
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
}

private func gridDirectionForAxis(axis: GridAxis) -> GridTrackSizingDirection {
  return axis == .GridRowAxis ? .ForColumns : .ForRows
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func calculateGridTrackSize(direction: GridTrackSizingDirection, translatedIndex: UInt32)
    -> GridTrackSize
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func rawGridTrackSize(direction: GridTrackSizingDirection, translatedIndex: UInt32)
    -> GridTrackSize
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setAvailableSpace(direction: GridTrackSizingDirection, availableSpace: LayoutUnit?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeTrackBasedSize() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func setup(
    direction: GridTrackSizingDirection, numTracks: UInt32, sizingOperation: SizingOperation,
    availableSpace: LayoutUnit?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isRelativeGridLengthAsAuto(length: GridLength, direction: GridTrackSizingDirection)
    -> Bool
  {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Track sizing algorithm steps. Note that the "Maximize Tracks" step is done
  // entirely inside the strategies, that's why we don't need an additional
  // method at this level.
  private func initializeTrackSizes() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func stretchFlexibleTracks(freeSpace: LayoutUnit?, gridLayoutState: inout GridLayoutState)
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func stretchAutoTracks() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func copyUsedTrackSizesForSubgrid() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // State machine.
  private func advanceNextState() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isValidTransition() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Data.
  private func wasSetup() -> Bool { return strategy != nil }

  private var needsSetup = true

  private let freeSpaceColumns: LayoutUnit? = nil
  private let freeSpaceRows: LayoutUnit? = nil

  private let contentSizedTracksIndex: [UInt32] = []

  // The track sizing algorithm is used for both layout and intrinsic size
  // computation. We're normally just interested in intrinsic inline sizes
  // (a.k.a widths in most of the cases) for the computeIntrinsicLogicalWidths()
  // computations. That's why we don't need to keep around different values for
  // rows/columns.
  let minContentSize: LayoutUnit
  let maxContentSize: LayoutUnit

  // Required to be public by RenderGrid. Try to minimize the exposed surface.
  let grid: Grid

  let renderGrid: RenderGridWrapper?
  private let strategy: GridTrackSizingAlgorithmStrategy?

  private let baselineAlignment: GridBaselineAlignment

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
}
