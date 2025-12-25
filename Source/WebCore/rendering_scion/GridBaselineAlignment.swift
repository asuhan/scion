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
  func clear(alignmentAxis: GridAxis) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func baselineGroupForGridItem(
    preference: ItemPosition, sharedContext: UInt32, gridItem: RenderBoxWrapper,
    alignmentAxis: GridAxis
  ) -> BaselineGroup {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func ascentForGridItem(
    _ gridItem: RenderBoxWrapper, _ alignmentAxis: GridAxis, _ position: ItemPosition
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func descentForGridItem(
    _ gridItem: RenderBoxWrapper, _ ascent: LayoutUnit, _ alignmentAxis: GridAxis,
    _ extraMarginsFromAncestorSubgrids: ExtraMarginsFromSubgrids
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isDescentBaselineForGridItem(_ gridItem: RenderBoxWrapper, _ alignmentAxis: GridAxis)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Grid Container's WritingMode, used to determine grid item's orthogonality.
  private var writingMode: WritingMode = .HorizontalTb
}
