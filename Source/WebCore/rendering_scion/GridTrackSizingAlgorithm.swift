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

final class GridTrackSizingAlgorithm {
  init(renderGrid: RenderGridWrapper, grid: Grid) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func run(
    direction: GridTrackSizingDirection, numTracks: UInt32, sizingOperation: SizingOperation,
    availableSpace: LayoutUnit?, gridLayoutState: inout GridLayoutState
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func reset() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func baselineOffsetForGridItem(gridItem: RenderBoxWrapper, baselineAxis: GridAxis) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func estimatedGridAreaBreadthForGridItem(
    gridItem: RenderBoxWrapper, direction: GridTrackSizingDirection
  ) -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private let freeSpaceColumns: LayoutUnit? = nil
  private let freeSpaceRows: LayoutUnit? = nil

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
}
