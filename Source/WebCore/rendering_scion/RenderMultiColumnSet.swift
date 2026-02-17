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

private func precedesRenderer(renderer: RenderObjectWrapper?, boundary: RenderObjectWrapper?)
  -> Bool
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

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

  private func multiColumnBlockFlow() -> RenderBlockFlowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func multiColumnFlowForMultiColumnSet() -> RenderMultiColumnFlowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextSiblingMultiColumnSet() -> RenderMultiColumnSetWrapper? {
    var sibling = nextSibling()
    while sibling != nil {
      if let multiColumnSet = sibling as? RenderMultiColumnSetWrapper {
        return multiColumnSet
      }
      sibling = sibling!.nextSibling()
    }
    return nil
  }

  private func previousSiblingMultiColumnSet() -> RenderMultiColumnSetWrapper? {
    var sibling = previousSibling()
    while sibling != nil {
      if let multiColumnSet = sibling as? RenderMultiColumnSetWrapper {
        return multiColumnSet
      }
      sibling = sibling!.previousSibling()
    }
    return nil
  }

  // Return the first object in the flow thread that's rendered inside this set.
  func firstRendererInFragmentedFlow() -> RenderObjectWrapper? {
    if let sibling = RenderMultiColumnFlowWrapper.previousColumnSetOrSpannerSiblingOf(child: self) {
      // Adjacent sets should not occur. Currently we would have no way of figuring out what each
      // of them contains then.
      assert(!sibling.isRenderMultiColumnSet())
      if let placeholder = multiColumnFlowForMultiColumnSet()!.findColumnSpannerPlaceholder(
        spanner: sibling)
      {
        return placeholder.nextInPreOrderAfterChildren()
      }
      fatalError("Not reached")
    }
    return fragmentedFlow!.firstChild()
  }

  // Return the last object in the flow thread that's rendered inside this set.
  func lastRendererInFragmentedFlow() -> RenderObjectWrapper? {
    if let sibling = RenderMultiColumnFlowWrapper.nextColumnSetOrSpannerSiblingOf(child: self) {
      // Adjacent sets should not occur. Currently we would have no way of figuring out what each
      // of them contains then.
      assert(!sibling.isRenderMultiColumnSet())
      if let placeholder = multiColumnFlowForMultiColumnSet()!.findColumnSpannerPlaceholder(
        spanner: sibling)
      {
        return placeholder.previousInPreOrder()
      }
      fatalError("Not reached")
    }
    return fragmentedFlow!.lastLeafChild()
  }

  // Return true if the specified renderer (descendant of the flow thread) is inside this column set.
  func containsRendererInFragmentedFlow(renderer: RenderObjectWrapper) -> Bool {
    if previousSiblingMultiColumnSet() == nil && nextSiblingMultiColumnSet() == nil {
      // There is only one set. This is easy, then.
      return renderer.isDescendantOf(ancestor: fragmentedFlow)
    }

    let firstRenderer = firstRendererInFragmentedFlow()!
    let lastRenderer = lastRendererInFragmentedFlow()!

    // This is SLOW! But luckily very uncommon.
    return precedesRenderer(renderer: firstRenderer, boundary: renderer)
      && precedesRenderer(renderer: renderer, boundary: lastRenderer)
  }

  private func setLogicalBottomInFragmentedFlow(_ logicalBottom: LayoutUnit) {
    var rect = fragmentedFlowPortionRect()
    if isHorizontalWritingMode() {
      rect.shiftMaxYEdgeTo(edge: logicalBottom)
    } else {
      rect.shiftMaxXEdgeTo(edge: logicalBottom)
    }
    setFragmentedFlowPortionRect(rect)
  }

  private func setComputedColumnWidthAndCount(_ width: LayoutUnit, _ count: UInt32) {
    computedColumnWidth = width
    computedColumnCount = count
  }

  private func heightAdjustedForSetOffset(_ height: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func clearForcedBreaks() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // (Re-)calculate the column height. This is first and foremost needed by sets that are to
  // balance the column height, but even when it isn't to be balanced, this is necessary if the
  // multicol container's height is constrained. If |initial| is set, and we are to balance, guess
  // an initial column height; otherwise, stretch the column height a tad. Return true if column
  // height changed and another layout pass is required.
  func recalculateColumnHeight(initial: Bool) -> Bool {
    let oldColumnHeight = computedColumnHeight
    if requiresBalancing() {
      if initial {
        distributeImplicitBreaks()
      }
      let newColumnHeight = calculateBalancedHeight(initial)
      setAndConstrainColumnHeight(newColumnHeight)
      // After having calculated an initial column height, the multicol container typically needs at
      // least one more layout pass with a new column height, but if a height was specified, we only
      // need to do this if we think that we need less space than specified. Conversely, if we
      // determined that the columns need to be as tall as the specified height of the container, we
      // have already laid it out correctly, and there's no need for another pass.
    } else {
      // The position of the column set may have changed, in which case height available for
      // columns may have changed as well.
      setAndConstrainColumnHeight(computedColumnHeight)
    }
    if computedColumnHeight == oldColumnHeight {
      return false  // No change. We're done.
    }

    minSpaceShortage = RenderFragmentedFlowWrapper.maxLogicalHeight()
    return true  // Need another pass.
  }

  override func updateLogicalWidth() {
    setComputedColumnWidthAndCount(
      multiColumnFlowForMultiColumnSet()!.columnWidth(),
      multiColumnFlowForMultiColumnSet()!.columnCount())  // FIXME: This will eventually vary if we are contained inside fragments.

    // FIXME: When we add fragments support, we'll start it off at the width of the multi-column
    // block in that particular fragment.
    setLogicalWidth(size: multiColumnBlockFlow()!.contentLogicalWidth())
  }

  func prepareForLayout(initial: Bool) {
    // Guess box logical top. This might eliminate the need for another layout pass.
    if let previous = RenderMultiColumnFlowWrapper.previousColumnSetOrSpannerSiblingOf(child: self)
    {
      setLogicalTop(top: previous.logicalBottom() + previous.marginAfter())
    } else {
      setLogicalTop(top: multiColumnBlockFlow()!.borderAndPaddingBefore())
    }

    if initial {
      maxColumnHeight = calculateMaxColumnHeight()
    }
    if requiresBalancing() {
      if initial {
        computedColumnHeight = LayoutUnit(value: 0)
        availableColumnHeight = LayoutUnit(value: 0)
        columnHeightComputed = false
      }
    } else {
      setAndConstrainColumnHeight(
        heightAdjustedForSetOffset(multiColumnFlowForMultiColumnSet()!.columnHeightAvailable))
    }

    // Set box width.
    updateLogicalWidth()

    // Any breaks will be re-inserted during layout, so get rid of what we already have.
    clearForcedBreaks()

    // Nuke previously stored minimum column height. Contents may have changed for all we know.
    minimumColumnHeight = LayoutUnit(value: 0)

    spaceShortageForSizeContainment = LayoutUnit(value: 0)

    // Start with "infinite" flow thread portion height until height is known.
    setLogicalBottomInFragmentedFlow(RenderFragmentedFlowWrapper.maxLogicalHeight())

    setNeedsLayout(markParents: .MarkOnlyThis)
  }

  func requiresBalancing() -> Bool {
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
    // Determine which columns we intersect.
    let colGap = columnGap()
    let halfColGap = colGap / 2

    let progressionIsInline = multiColumnFlowForMultiColumnSet()!.progressionIsInline()

    var point = logicalPoint

    for i in 0..<columnCount() {
      // Add in half the column gap to the left and right of the rect.
      let colRect = columnRectAt(i)
      if isHorizontalWritingMode() == progressionIsInline {
        let gapAndColumnRect = LayoutRectWrapper(
          x: colRect.x() - halfColGap, y: colRect.y(), width: colRect.width() + colGap,
          height: colRect.height())
        if point.x >= gapAndColumnRect.x() && point.x < gapAndColumnRect.maxX() {
          if clampMode == .ClampHitTestTranslationToColumns {
            if progressionIsInline {
              // FIXME: The clamping that follows is not completely right for right-to-left
              // content.
              // Clamp everything above the column to its top left.
              if point.y < gapAndColumnRect.y() {
                point = gapAndColumnRect.location()
              }
              // Clamp everything below the column to the next column's top left. If there is
              // no next column, this still maps to just after this column.
              else if point.y >= gapAndColumnRect.maxY() {
                point = gapAndColumnRect.location()
                point.move(dx: LayoutUnit(value: UInt64(0)), dy: gapAndColumnRect.height())
              }
            } else {
              if point.x < colRect.x() {
                point.setX(x: colRect.x())
              } else if point.x >= colRect.maxX() {
                point.setX(x: colRect.maxX() - 1)
              }
            }
          }

          let offsetInColumn = point - colRect.location()
          let fragmentedFlowPortion = fragmentedFlowPortionRectAt(i)

          return fragmentedFlowPortion.location() + offsetInColumn
        }
      } else {
        let gapAndColumnRect = LayoutRectWrapper(
          x: colRect.x(), y: colRect.y() - halfColGap, width: colRect.width(),
          height: colRect.height() + colGap)
        if point.y >= gapAndColumnRect.y() && point.y < gapAndColumnRect.maxY() {
          if clampMode == .ClampHitTestTranslationToColumns {
            if progressionIsInline {
              // FIXME: The clamping that follows is not completely right for right-to-left
              // content.
              // Clamp everything above the column to its top left.
              if point.x < gapAndColumnRect.x() {
                point = gapAndColumnRect.location()
              }
              // Clamp everything below the column to the next column's top left. If there is
              // no next column, this still maps to just after this column.
              else if point.x >= gapAndColumnRect.maxX() {
                point = gapAndColumnRect.location()
                point.move(dx: gapAndColumnRect.width(), dy: LayoutUnit(value: UInt64(0)))
              }
            } else {
              if point.y < colRect.y() {
                point.setY(y: colRect.y())
              } else if point.y >= colRect.maxY() {
                point.setY(y: colRect.maxY() - 1)
              }
            }
          }

          let offsetInColumn = point - colRect.location()
          let fragmentedFlowPortion = fragmentedFlowPortionRectAt(i)
          return fragmentedFlowPortion.location() + offsetInColumn
        }
      }
    }

    return logicalPoint
  }

  private func columnRectAt(_ index: UInt32) -> LayoutRectWrapper {
    if isHorizontalWritingMode() {
      return LayoutRectWrapper(
        x: columnLogicalLeft(index), y: columnLogicalTop(index), width: computedColumnWidth,
        height: computedColumnHeight)
    }
    return LayoutRectWrapper(
      x: columnLogicalTop(index), y: columnLogicalLeft(index), width: computedColumnHeight,
      height: computedColumnWidth)
  }

  private func columnCount() -> UInt32 {
    // We must always return a value of 1 or greater. Column count = 0 is a meaningless situation,
    // and will confuse and cause problems in other parts of the code.
    if computedColumnHeight <= Int32(0) {
      return 1
    }

    // Our portion rect determines our column count. We have as many columns as needed to fit all the content.
    let logicalHeightInColumns =
      fragmentedFlow!.isHorizontalWritingMode()
      ? fragmentedFlowPortionRect().height() : fragmentedFlowPortionRect().width()
    if logicalHeightInColumns <= Int32(0) {
      return 1
    }

    var count = UInt32((logicalHeightInColumns / computedColumnHeight).floor())
    // logicalHeightInColumns may be saturated, so detect the remainder manually.
    if count * computedColumnHeight < logicalHeightInColumns {
      count += 1
    }
    assert(count >= 1)
    return count
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

  private func calculateMaxColumnHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func columnLogicalLeft(_ index: UInt32) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func columnLogicalTop(_ index: UInt32) -> LayoutUnit {
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

  private func setAndConstrainColumnHeight(_ newHeight: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Given the current list of content runs, make assumptions about where we need to insert
  // implicit breaks (if there's room for any at all; depending on the number of explicit breaks),
  // and store the results. This is needed in order to balance the columns.
  private func distributeImplicitBreaks() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func calculateBalancedHeight(_ initial: Bool) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var computedColumnCount: UInt32 = 1  // Used column count (the resulting 'N' from the pseudo-algorithm in the multicol spec)
  private var computedColumnWidth = LayoutUnit()  // Used column width (the resulting 'W' from the pseudo-algorithm in the multicol spec)
  var computedColumnHeight = LayoutUnit()
  private var availableColumnHeight = LayoutUnit()
  private var columnHeightComputed = false

  // The following variables are used when balancing the column set.
  private var maxColumnHeight = LayoutUnit()  // Maximum column height allowed.
  private var minSpaceShortage = LayoutUnit()  // The smallest amout of space shortage that caused a column break.
  private var minimumColumnHeight = LayoutUnit()
  private var spaceShortageForSizeContainment = LayoutUnit()  // The shortage space that keeps size containment monolithic.
}
