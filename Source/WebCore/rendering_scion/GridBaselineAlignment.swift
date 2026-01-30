/*
 * Copyright (C) 2018 Igalia S.L. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

// This is the class that implements the Baseline Alignment logic, using internally the BaselineAlignmentState and
// BaselineGroup classes.
//
// The first phase is to collect the items that will participate in baseline alignment together. During this
// phase the required baseline-sharing groups will be created for each Baseline alignment-context shared by
// the items participating in the baseline alignment.
//
// Additionally, the baseline-sharing groups' offsets, max-ascend and max-descent will be computed and stored.
// This class also computes the baseline offset for a particular item, based on the max-ascent for its associated
// baseline-sharing group.
struct GridBaselineAlignment {
  // Collects the items participating in baseline alignment and updates the corresponding baseline-sharing
  // group of the Baseline Context the items belongs to.
  // All the baseline offsets are updated accordingly based on the added item.
  func updateBaselineAlignmentContext(
    _ preference: ItemPosition, _ sharedContext: UInt32, _ gridItem: RenderBoxWrapper,
    _ alignmentAxis: GridAxis
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns the baseline offset of a particular item, based on the max-ascent for its associated
  // baseline-sharing group
  func baselineOffsetForGridItem(
    preference: ItemPosition, sharedContext: UInt32, gridItem: RenderBoxWrapper,
    alignmentAxis: GridAxis
  ) -> LayoutUnit {
    assert(isBaselinePosition(position: preference))
    let group = baselineGroupForGridItem(
      preference: preference, sharedContext: sharedContext, gridItem: gridItem,
      alignmentAxis: alignmentAxis)
    if group.computeSize() > 1 {
      return group.maxAscent
        - logicalAscentForGridItem(
          gridItem: gridItem, alignmentAxis: alignmentAxis, position: preference)
    }
    return LayoutUnit()
  }

  // Sets the Grid Container's writing-mode so that we can avoid the dependecy of the LayoutGrid class for
  // determining whether a grid item is orthogonal or not.
  mutating func setWritingMode(writingMode: WritingMode) { self.writingMode = writingMode }

  // Clearing the Baseline Alignment context and their internal classes and data structures.
  mutating func clear(alignmentAxis: GridAxis) {
    if alignmentAxis == .GridColumnAxis {
      rowAxisBaselineAlignmentStates.removeAll()
    } else {
      colAxisBaselineAlignmentStates.removeAll()
    }
  }

  private func baselineGroupForGridItem(
    preference: ItemPosition, sharedContext: UInt32, gridItem: RenderBoxWrapper,
    alignmentAxis: GridAxis
  ) -> BaselineGroup {
    assert(isBaselinePosition(position: preference))
    let isRowAxisContext = alignmentAxis == .GridColumnAxis
    let baselineAlignmentState =
      isRowAxisContext
      ? rowAxisBaselineAlignmentStates[sharedContext]!
      : colAxisBaselineAlignmentStates[sharedContext]!
    return baselineAlignmentState.sharedGroup(child: gridItem, preference: preference)
  }

  private func logicalAscentForGridItem(
    gridItem: RenderBoxWrapper, alignmentAxis: GridAxis, position: ItemPosition
  ) -> LayoutUnit {
    let hasOrthogonalAncestorSubgrids = { () -> Bool in
      for currentAncestorSubgrid in ancestorSubgridsOfGridItem(
        gridItem: gridItem, direction: .ForRows)
      {
        if currentAncestorSubgrid.isHorizontalWritingMode()
          != currentAncestorSubgrid.parent()!.isHorizontalWritingMode()
        {
          return true
        }
      }
      return false
    }

    var extraMarginsFromAncestorSubgrids = ExtraMarginsFromSubgrids()
    if alignmentAxis == .GridColumnAxis && !hasOrthogonalAncestorSubgrids() {
      extraMarginsFromAncestorSubgrids = GridLayoutFunctions.extraMarginForSubgridAncestors(
        direction: .ForRows, gridItem: gridItem)
    }

    let ascent =
      ascentForGridItem(gridItem, alignmentAxis, position)
      + extraMarginsFromAncestorSubgrids.extraTrackStartMargin()
    return (isDescentBaselineForGridItem(gridItem, alignmentAxis) || position == .LastBaseline)
      ? descentForGridItem(gridItem, ascent, alignmentAxis, extraMarginsFromAncestorSubgrids)
      : ascent
  }

  private static let noValidBaseline = LayoutUnit(value: -1)

  private func ascentForGridItem(
    _ gridItem: RenderBoxWrapper, _ alignmentAxis: GridAxis, _ position: ItemPosition
  ) -> LayoutUnit {
    assert(position == .Baseline || position == .LastBaseline)
    var baseline = LayoutUnit(value: UInt64(0))
    let gridItemMargin =
      alignmentAxis == .GridColumnAxis
      ? gridItem.marginBlockStart(writingMode: writingMode)
      : gridItem.marginInlineStart(writingMode: writingMode)
    let parentStyle = gridItem.parent()!.style()

    if alignmentAxis == .GridColumnAxis {
      let alignmentContextDirection: LineDirectionMode =
        parentStyle.isHorizontalWritingMode() ? .HorizontalLine : .VerticalLine

      if !isParallelToAlignmentAxisForGridItem(gridItem, alignmentAxis) {
        return gridItemMargin
          + synthesizedBaseline(
            box: gridItem, parentStyle: parentStyle, direction: alignmentContextDirection,
            edge: .BorderBox)
      }
      if let ascent = position == .Baseline
        ? gridItem.firstLineBaseline() : gridItem.lastLineBaseline()
      {
        baseline = ascent
      } else {
        return gridItemMargin
          + synthesizedBaseline(
            box: gridItem, parentStyle: parentStyle, direction: alignmentContextDirection,
            edge: .BorderBox)
      }
    } else {
      let computedBaselineValue =
        position == .Baseline ? gridItem.firstLineBaseline() : gridItem.lastLineBaseline()
      baseline =
        isParallelToAlignmentAxisForGridItem(gridItem, alignmentAxis)
        ? (computedBaselineValue ?? GridBaselineAlignment.noValidBaseline)
        : GridBaselineAlignment.noValidBaseline
      // We take border-box's under edge if no valid baseline.
      if baseline == GridBaselineAlignment.noValidBaseline {
        assert(!gridItem.needsLayout())
        if isVerticalAlignmentContext(alignmentAxis) {
          return isFlippedWritingMode(writingMode: writingMode)
            ? gridItemMargin + gridItem.size().width().toInt() : gridItemMargin
        }
        return gridItemMargin
          + synthesizedBaseline(
            box: gridItem, parentStyle: parentStyle, direction: .HorizontalLine, edge: .BorderBox)
      }
    }

    return gridItemMargin + baseline
  }

  private func descentForGridItem(
    _ gridItem: RenderBoxWrapper, _ ascent: LayoutUnit, _ alignmentAxis: GridAxis,
    _ extraMarginsFromAncestorSubgrids: ExtraMarginsFromSubgrids
  ) -> LayoutUnit {
    assert(!gridItem.needsLayout())
    if isParallelToAlignmentAxisForGridItem(gridItem, alignmentAxis) {
      return extraMarginsFromAncestorSubgrids.extraTotalMargin() + gridItem.marginLogicalHeight()
        + gridItem.logicalHeight() - ascent
    }
    return gridItem.marginLogicalWidth() + gridItem.logicalWidth() - ascent
  }

  private func isDescentBaselineForGridItem(_ gridItem: RenderBoxWrapper, _ alignmentAxis: GridAxis)
    -> Bool
  {
    return isVerticalAlignmentContext(alignmentAxis)
      && ((gridItem.style().isFlippedBlocksWritingMode()
        && !isFlippedWritingMode(writingMode: writingMode))
        || (gridItem.style().isFlippedLinesWritingMode()
          && isFlippedWritingMode(writingMode: writingMode)))
  }

  private func isVerticalAlignmentContext(_ alignmentAxis: GridAxis) -> Bool {
    return alignmentAxis == .GridRowAxis
      ? isHorizontalWritingMode(writingMode: writingMode)
      : !isHorizontalWritingMode(writingMode: writingMode)
  }

  private func isOrthogonalGridItemForBaseline(gridItem: RenderBoxWrapper) -> Bool {
    return isHorizontalWritingMode(writingMode: writingMode) != gridItem.isHorizontalWritingMode()
  }

  private func isParallelToAlignmentAxisForGridItem(
    _ gridItem: RenderBoxWrapper, _ alignmentAxis: GridAxis
  ) -> Bool {
    return alignmentAxis == .GridColumnAxis
      ? !isOrthogonalGridItemForBaseline(gridItem: gridItem)
      : isOrthogonalGridItemForBaseline(gridItem: gridItem)
  }

  // TODO(asuhan): disallow 0 and UInt32.max
  private typealias BaselineAlignmentStateMap = [UInt32: BaselineAlignmentState]

  // Grid Container's WritingMode, used to determine grid item's orthogonality.
  private var writingMode: WritingMode = .HorizontalTb
  private var rowAxisBaselineAlignmentStates = BaselineAlignmentStateMap()
  private var colAxisBaselineAlignmentStates = BaselineAlignmentStateMap()
}
