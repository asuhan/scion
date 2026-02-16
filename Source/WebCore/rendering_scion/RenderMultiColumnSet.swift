/*
 * Copyright (C) 2012-2023 Apple Inc.  All rights reserved.
 * Copyright (C) 2015 Google Inc.  All rights reserved.
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

// RenderMultiColumnSet represents a set of columns that all have the same width and height. By combining runs of same-size columns into a single
// object, we significantly reduce the number of unique RenderObjects required to represent columns.
//
// A simple multi-column block will have exactly one RenderMultiColumnSet child. A simple paginated multi-column block will have three
// RenderMultiColumnSet children: one for the content at the bottom of the first page (whose columns will have a shorter height), one
// for the 2nd to n-1 pages, and then one last column set that will hold the shorter columns on the final page (that may have to be balanced
// as well).
//
// Column spans result in the creation of new column sets as well, since a spanning fragment has to be placed in between the column sets that
// come before and after the span.
final class RenderMultiColumnSetWrapper: RenderFragmentContainerSetWrapper {
  init(fragmentedFlow: RenderFragmentedFlowWrapper, style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func multiColumnFlowForMultiColumnSet() -> RenderMultiColumnFlowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextSiblingMultiColumnSet() -> RenderMultiColumnSetWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Return true if the specified renderer (descendant of the flow thread) is inside this column set.
  func containsRendererInFragmentedFlow(renderer: RenderObjectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computedColumnHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // (Re-)calculate the column height. This is first and foremost needed by sets that are to
  // balance the column height, but even when it isn't to be balanced, this is necessary if the
  // multicol container's height is constrained. If |initial| is set, and we are to balance, guess
  // an initial column height; otherwise, stretch the column height a tad. Return true if column
  // height changed and another layout pass is required.
  func recalculateColumnHeight(initial: Bool) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func updateLogicalWidth() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func prepareForLayout(initial: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paintColumnRules(paintInfo: PaintInfoWrapper, point: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum ColumnHitTestTranslationMode {
    case ClampHitTestTranslationToColumns
    case DoNotClampHitTestTranslationToColumns
  }

  func translateFragmentPointToFragmentedFlow(
    _ logicalPoint: LayoutPointWrapper,
    _ clampMode: ColumnHitTestTranslationMode = .DoNotClampHitTestTranslationToColumns
  ) -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func columnRectAt(_ index: UInt32) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func columnCount() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func columnGap() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func addOverflowFromChildren() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paintObject(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func pageLogicalWidth() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func pageLogicalHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func pageLogicalTopForOffset(offset: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // This method represents the logical height of the entire flow thread portion used by the fragment or set.
  // For RenderFragmentContainers it matches logicalPaginationHeight(), but for sets it is the height of all the pages
  // or columns added together.
  override func logicalHeightOfAllFragmentedFlowContent() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func repaintFragmentedFlowContent(_ repaintRect: LayoutRectWrapper) {
    // Figure out the start and end columns and only check within that range so that we don't walk the
    // entire column set. Put the repaint rect into flow thread coordinates by flipping it first.
    var fragmentedFlowRepaintRect = repaintRect
    fragmentedFlow!.flipForWritingMode(rect: &fragmentedFlowRepaintRect)

    // Now we can compare this rect with the flow thread portions owned by each column. First let's
    // just see if the repaint rect intersects our flow thread portion at all.
    var clippedRect = fragmentedFlowRepaintRect
    clippedRect.intersect(other: fragmentedFlowPortionOverflowRect())
    if clippedRect.isEmpty() {
      return
    }

    // Now we know we intersect at least one column. Let's figure out the logical top and logical
    // bottom of the area we're repainting.
    let repaintLogicalTop =
      isHorizontalWritingMode() ? fragmentedFlowRepaintRect.y() : fragmentedFlowRepaintRect.x()
    let repaintLogicalBottom =
      (isHorizontalWritingMode()
        ? fragmentedFlowRepaintRect.maxY() : fragmentedFlowRepaintRect.maxX()) - 1

    // FIXME: this should use firstAndLastColumnsFromOffsets.
    let startColumn = columnIndexAtOffset(repaintLogicalTop)
    let endColumn = columnIndexAtOffset(repaintLogicalBottom)

    let colGap = columnGap()
    let colCount = columnCount()
    for i in startColumn...endColumn {
      var colRect = columnRectAt(i)

      // Get the portion of the flow thread that corresponds to this column.
      let fragmentedFlowPortion = fragmentedFlowPortionRectAt(i)

      // Now get the overflow rect that corresponds to the column.
      let fragmentedFlowOverflowPortion = fragmentedFlowPortionOverflowRect(
        fragmentedFlowPortion, i, colCount, colGap)

      // Do a repaint for this specific column.
      flipForWritingMode(rect: &colRect)
      repaintFragmentedFlowContentRectangle(
        repaintRect, fragmentedFlowPortion, colRect.location(), fragmentedFlowOverflowPortion)
    }
  }

  override func collectLayerFragments(
    layerFragments: inout LayerFragments, layerBoundingBox: LayoutRectWrapper,
    dirtyRect: LayoutRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func positionForPoint(
    _ point: LayoutPointWrapper, _ source: HitTestSource,
    _ fragment: RenderFragmentContainerWrapper?
  ) -> VisiblePosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func fragmentedFlowPortionRectAt(_ index: UInt32) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func fragmentedFlowPortionOverflowRect(
    _ portionRect: LayoutRectWrapper, _ index: UInt32, _ colCount: UInt32, _ colGap: LayoutUnit
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum ColumnIndexCalculationMode {
    case ClampToExistingColumns  // Stay within the range of already existing columns.
    case AssumeNewColumns  // Allow column indices outside the range of already existing columns.
  }

  private func columnIndexAtOffset(
    _ offset: LayoutUnit, _ mode: ColumnIndexCalculationMode = .ClampToExistingColumns
  ) -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
