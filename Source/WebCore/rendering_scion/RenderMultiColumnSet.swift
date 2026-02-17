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
    let multicolBlock = parent()! as! RenderBlockFlowWrapper
    let contentLogicalTop = logicalTop() - multicolBlock.borderAndPaddingBefore()

    let height = height - contentLogicalTop
    return max(height, LayoutUnit(value: UInt64(1)))  // Let's avoid zero height, as that would probably cause an infinite amount of columns to be created.
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
    if !multiColumnFlowForMultiColumnSet()!.progressionIsInline() {
      return false
    }

    if let next = RenderMultiColumnFlowWrapper.nextColumnSetOrSpannerSiblingOf(child: self) {
      if !next.isRenderMultiColumnSet() && !next.isLegend() {
        // If we're followed by a spanner, we need to balance.
        assert(
          multiColumnFlowForMultiColumnSet()!.findColumnSpannerPlaceholder(spanner: next) != nil)
        return true
      }
    }
    let container = multiColumnBlockFlow()!
    if container.style().columnFill() == .Balance {
      return true
    }
    return !multiColumnFlowForMultiColumnSet()!.columnHeightAvailable.bool()
  }

  override func paintColumnRules(_ paintInfo: PaintInfoWrapper, _ paintOffset: LayoutPointWrapper) {
    if paintInfo.context().paintingDisabled() {
      return
    }

    let fragmentedFlow = multiColumnFlowForMultiColumnSet()
    let blockStyle = parent()!.style()
    let ruleColor = blockStyle.visitedDependentColorWithColorFilter(
      colorProperty: .CSSPropertyColumnRuleColor)
    let ruleTransparent = blockStyle.columnRuleIsTransparent()
    let ruleStyle = collapsedBorderStyle(style: blockStyle.columnRuleStyle())
    let ruleThickness = LayoutUnit(value: blockStyle.columnRuleWidth())
    let colGap = columnGap()
    let renderRule = ruleStyle != .None && ruleStyle != .Hidden && !ruleTransparent
    if !renderRule {
      return
    }

    let colCount = columnCount()
    if colCount <= 1 {
      return
    }

    let antialias = BorderPainter.shouldAntialiasLines(context: paintInfo.context())

    if fragmentedFlow!.progressionIsInline() {
      let leftToRight = style().isLeftToRightDirection() != fragmentedFlow!.progressionIsReversed()
      var currLogicalLeftOffset = leftToRight ? LayoutUnit(value: UInt64(0)) : contentLogicalWidth()
      let ruleAdd = logicalLeftOffsetForContent()
      var ruleLogicalLeft = leftToRight ? LayoutUnit(value: UInt64(0)) : contentLogicalWidth()
      let inlineDirectionSize = computedColumnWidth
      let boxSide: BoxSide =
        isHorizontalWritingMode() ? leftToRight ? .Left : .Right : leftToRight ? .Top : .Bottom

      for i in 0..<colCount {
        // Move to the next position.
        if leftToRight {
          ruleLogicalLeft += inlineDirectionSize + colGap / 2
          currLogicalLeftOffset += inlineDirectionSize + colGap
        } else {
          ruleLogicalLeft -= (inlineDirectionSize + colGap / 2)
          currLogicalLeftOffset -= (inlineDirectionSize + colGap)
        }

        // Now paint the column rule.
        if i < colCount - 1 {
          let ruleLeft =
            isHorizontalWritingMode()
            ? paintOffset.x + ruleLogicalLeft - ruleThickness / 2 + ruleAdd
            : paintOffset.x + borderLeft() + paddingLeft()
          let ruleRight =
            isHorizontalWritingMode() ? ruleLeft + ruleThickness : ruleLeft + contentWidth()
          let ruleTop =
            isHorizontalWritingMode()
            ? paintOffset.y + borderTop() + paddingTop()
            : paintOffset.y + ruleLogicalLeft - ruleThickness / 2 + ruleAdd
          let ruleBottom =
            isHorizontalWritingMode() ? ruleTop + contentHeight() : ruleTop + ruleThickness
          let pixelSnappedRuleRect = snappedIntRect(
            left: ruleLeft, top: ruleTop, width: ruleRight - ruleLeft, height: ruleBottom - ruleTop)
          BorderPainter.drawLineForBoxSide(
            graphicsContext: paintInfo.context(), document: document(),
            rect: FloatRectWrapper(r: pixelSnappedRuleRect),
            side: boxSide, color: ruleColor, borderStyle: ruleStyle, adjacentWidth1: 0,
            adjacentWidth2: 0, antialias: antialias)
        }

        ruleLogicalLeft = currLogicalLeftOffset
      }
    } else {
      let topToBottom =
        !style().isFlippedBlocksWritingMode() != fragmentedFlow!.progressionIsReversed()
      let ruleLeft =
        isHorizontalWritingMode()
        ? LayoutUnit(value: UInt64(0)) : colGap / 2 - colGap - ruleThickness / 2
      let ruleWidth = isHorizontalWritingMode() ? contentWidth() : ruleThickness
      let ruleTop =
        isHorizontalWritingMode()
        ? colGap / 2 - colGap - ruleThickness / 2 : LayoutUnit(value: UInt64(0))
      let ruleHeight = isHorizontalWritingMode() ? ruleThickness : contentHeight()
      var ruleRect = LayoutRectWrapper(
        x: ruleLeft, y: ruleTop, width: ruleWidth, height: ruleHeight)

      if !topToBottom {
        if isHorizontalWritingMode() {
          ruleRect.setY(y: height() - ruleRect.maxY())
        } else {
          ruleRect.setX(x: width() - ruleRect.maxX())
        }
      }

      ruleRect.moveBy(offset: paintOffset)

      let boxSide: BoxSide =
        isHorizontalWritingMode() ? topToBottom ? .Top : .Bottom : topToBottom ? .Left : .Right

      var step = LayoutSizeWrapper(
        width: LayoutUnit(value: UInt64(0)),
        height: topToBottom ? computedColumnHeight + colGap : -(computedColumnHeight + colGap))
      if !isHorizontalWritingMode() {
        step = step.transposedSize()
      }

      for _ in 1..<colCount {
        ruleRect.move(size: step)
        let pixelSnappedRuleRect = snappedIntRect(rect: ruleRect)
        BorderPainter.drawLineForBoxSide(
          graphicsContext: paintInfo.context(), document: document(),
          rect: FloatRectWrapper(r: pixelSnappedRuleRect), side: boxSide, color: ruleColor,
          borderStyle: ruleStyle, adjacentWidth1: 0, adjacentWidth2: 0, antialias: antialias)
      }
    }
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
    // FIXME: Eventually we will cache the column gap when the widths of columns start varying, but for now we just
    // go to the parent block to get the gap.
    let parentBlock = parent()! as! RenderBlockFlowWrapper
    if parentBlock.style().columnGap().isNormal {
      return LayoutUnit(value: parentBlock.style().fontDescription().computedSize())  // "1em" is recommended as the normal gap setting. Matches <p> margins.
    }
    return valueForLength(
      length: parentBlock.style().columnGap().length,
      maximumValue: parentBlock.availableLogicalWidth())
  }

  override func addOverflowFromChildren() {
    // FIXME: Need to do much better here.
    let colCount = columnCount()
    if colCount == 0 {
      return
    }

    let lastRect = columnRectAt(colCount - 1)
    addLayoutOverflow(rect: lastRect)
    if !hasNonVisibleOverflow() {
      addVisualOverflow(rect: lastRect)
    }
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

  private static let maximumNumberOfFragments = 2_500_000

  override func collectLayerFragments(
    _ fragments: inout LayerFragments, layerBoundingBox: LayoutRectWrapper,
    dirtyRect: LayoutRectWrapper
  ) {
    // Let's start by introducing the different coordinate systems involved here. They are different
    // in how they deal with writing modes and columns. RenderLayer rectangles tend to be more
    // physical than the rectangles used in RenderObject & co.
    //
    // The two rectangles passed to this method are physical, except that we pretend that there's
    // only one long column (that's the flow thread). They are relative to the top left corner of
    // the flow thread. All rectangles being compared to the dirty rect also need to be in this
    // coordinate system.
    //
    // Then there's the output from this method - the stuff we put into the list of fragments. The
    // translationOffset point is the actual physical translation required to get from a location in
    // the flow thread to a location in some column. The paginationClip rectangle is in the same
    // coordinate system as the two rectangles passed to this method (i.e. physical, in flow thread
    // coordinates, pretending that there's only one long column).
    //
    // All other rectangles in this method are slightly less physical, when it comes to how they are
    // used with different writing modes, but they aren't really logical either. They are just like
    // RenderBox::frameRect(). More precisely, the sizes are physical, and the inline direction
    // coordinate is too, but the block direction coordinate is always "logical top". These
    // rectangles also pretend that there's only one long column, i.e. they are for the flow thread.
    //
    // To sum up: input and output from this method are "physical" RenderLayer-style rectangles and
    // points, while inside this method we mostly use the RenderObject-style rectangles (with the
    // block direction coordinate always being logical top).

    // Put the layer bounds into flow thread-local coordinates by flipping it first. Since we're in
    // a renderer, most rectangles are represented this way.
    var layerBoundsInFragmentedFlow = layerBoundingBox
    fragmentedFlow!.flipForWritingMode(rect: &layerBoundsInFragmentedFlow)

    // Now we can compare with the flow thread portions owned by each column. First let's
    // see if the rect intersects our flow thread portion at all.
    var clippedRect = layerBoundsInFragmentedFlow
    clippedRect.intersect(other: super.fragmentedFlowPortionOverflowRect())
    if clippedRect.isEmpty() {
      return
    }

    // Now we know we intersect at least one column. Let's figure out the logical top and logical
    // bottom of the area we're checking.
    let layerLogicalTop =
      isHorizontalWritingMode() ? layerBoundsInFragmentedFlow.y() : layerBoundsInFragmentedFlow.x()
    let layerLogicalBottom =
      (isHorizontalWritingMode()
        ? layerBoundsInFragmentedFlow.maxY() : layerBoundsInFragmentedFlow.maxX()) - 1

    // Figure out the start and end columns and only check within that range so that we don't walk the
    // entire column set.
    // FIXME: this should use firstAndLastColumnsFromOffsets.
    let startColumn = columnIndexAtOffset(layerLogicalTop)
    let endColumn = columnIndexAtOffset(layerLogicalBottom)

    let colLogicalWidth = computedColumnWidth
    let colGap = columnGap()
    let colCount = columnCount()

    let progressionReversed = multiColumnFlowForMultiColumnSet()!.progressionIsReversed()
    let progressionIsInline = multiColumnFlowForMultiColumnSet()!.progressionIsInline()

    let initialBlockOffset = initialBlockOffsetForPainting()

    for i in startColumn...endColumn {
      // Get the portion of the flow thread that corresponds to this column.
      let fragmentedFlowPortion = fragmentedFlowPortionRectAt(i)

      // Now get the overflow rect that corresponds to the column.
      let fragmentedFlowOverflowPortion = fragmentedFlowPortionOverflowRect(
        fragmentedFlowPortion, i, colCount, colGap)

      // In order to create a fragment we must intersect the portion painted by this column.
      var clippedRect = layerBoundsInFragmentedFlow
      clippedRect.intersect(other: fragmentedFlowOverflowPortion)
      if clippedRect.isEmpty() {
        continue
      }

      // We also need to intersect the dirty rect. We have to apply a translation and shift based off
      // our column index.
      var translationOffset = LayoutSizeWrapper()
      var inlineOffset =
        progressionIsInline ? i * (colLogicalWidth + colGap) : LayoutUnit(value: UInt64(0))

      let leftToRight = style().isLeftToRightDirection() != progressionReversed
      if !leftToRight {
        inlineOffset = -inlineOffset
        if progressionReversed {
          inlineOffset += contentLogicalWidth() - colLogicalWidth
        }
      }
      translationOffset.setWidth(width: inlineOffset)

      var blockOffset =
        initialBlockOffset + logicalTop() - fragmentedFlow!.logicalTop()
        + (isHorizontalWritingMode() ? -fragmentedFlowPortion.y() : -fragmentedFlowPortion.x())
      if !progressionIsInline {
        if !progressionReversed {
          blockOffset = i * colGap
        } else {
          blockOffset -= i * (computedColumnHeight + colGap)
        }
      }
      if isFlippedWritingMode(writingMode: style().writingMode()) {
        blockOffset = -blockOffset
      }
      translationOffset.setHeight(height: blockOffset)
      if !isHorizontalWritingMode() {
        translationOffset = translationOffset.transposedSize()
      }

      // Shift the dirty rect to be in flow thread coordinates with this translation applied.
      var translatedDirtyRect = dirtyRect
      translatedDirtyRect.move(size: -translationOffset)

      // See if we intersect the dirty rect.
      clippedRect = layerBoundingBox
      clippedRect.intersect(other: translatedDirtyRect)
      if clippedRect.isEmpty() {
        continue
      }

      // Something does need to paint in this column. Make a fragment now and supply the physical translation
      // offset and the clip rect for the column with that offset applied.
      let fragment = LayerFragment()
      fragment.paginationOffset = translationOffset

      var flippedFragmentedFlowOverflowPortion = fragmentedFlowOverflowPortion
      // Flip it into more a physical (RenderLayer-style) rectangle.
      fragmentedFlow!.flipForWritingMode(rect: &flippedFragmentedFlowOverflowPortion)
      fragment.paginationClip = flippedFragmentedFlowOverflowPortion
      if fragments.count < RenderMultiColumnSetWrapper.maximumNumberOfFragments {
        fragments.append(fragment)
      } else {
        break
      }
    }
  }

  override func positionForPoint(
    _ point: LayoutPointWrapper, _ source: HitTestSource,
    _ fragment: RenderFragmentContainerWrapper?
  ) -> VisiblePosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func calculateMaxColumnHeight() -> LayoutUnit {
    let multicolBlock = multiColumnBlockFlow()!
    let multicolStyle = multicolBlock.style()
    let availableHeight = multiColumnFlowForMultiColumnSet()!.columnHeightAvailable
    var maxColumnHeight =
      availableHeight.bool() ? availableHeight : RenderFragmentedFlowWrapper.maxLogicalHeight()
    if !multicolStyle.logicalMaxHeight().isUndefined() {
      maxColumnHeight = min(
        maxColumnHeight,
        multicolBlock.computeContentLogicalHeight(
          heightType: .MaxSize, height: multicolStyle.logicalMaxHeight(),
          intrinsicContentHeight: nil)
          ?? maxColumnHeight)
    }
    return heightAdjustedForSetOffset(maxColumnHeight)
  }

  private func columnLogicalLeft(_ index: UInt32) -> LayoutUnit {
    let colLogicalWidth = computedColumnWidth
    var colLogicalLeft = borderAndPaddingLogicalLeft()
    let colGap = columnGap()

    let progressionReversed = multiColumnFlowForMultiColumnSet()!.progressionIsReversed()
    let progressionInline = multiColumnFlowForMultiColumnSet()!.progressionIsInline()

    if progressionInline {
      if style().isLeftToRightDirection() != progressionReversed {
        colLogicalLeft += index * (colLogicalWidth + colGap)
      } else {
        colLogicalLeft +=
          contentLogicalWidth() - colLogicalWidth - index * (colLogicalWidth + colGap)
      }
    }

    return colLogicalLeft
  }

  private func columnLogicalTop(_ index: UInt32) -> LayoutUnit {
    let colLogicalHeight = computedColumnHeight
    var colLogicalTop = borderAndPaddingBefore()
    let colGap = columnGap()

    let progressionReversed = multiColumnFlowForMultiColumnSet()!.progressionIsReversed()
    let progressionInline = multiColumnFlowForMultiColumnSet()!.progressionIsInline()

    if !progressionInline {
      if !progressionReversed {
        colLogicalTop += index * (colLogicalHeight + colGap)
      } else {
        colLogicalTop +=
          contentLogicalHeight() - colLogicalHeight - index * (colLogicalHeight + colGap)
      }
    }

    return colLogicalTop
  }

  private func fragmentedFlowPortionRectAt(_ index: UInt32) -> LayoutRectWrapper {
    var portionRect = fragmentedFlowPortionRect()
    if isHorizontalWritingMode() {
      portionRect = LayoutRectWrapper(
        x: portionRect.x(), y: portionRect.y() + index * computedColumnHeight,
        width: portionRect.width(),
        height: computedColumnHeight)
    } else {
      portionRect = LayoutRectWrapper(
        x: portionRect.x() + index * computedColumnHeight, y: portionRect.y(),
        width: computedColumnHeight,
        height: portionRect.height())
    }
    return portionRect
  }

  private func fragmentedFlowPortionOverflowRect(
    _ portionRect: LayoutRectWrapper, _ index: UInt32, _ colCount: UInt32, _ colGap: LayoutUnit
  ) -> LayoutRectWrapper {
    // This function determines the portion of the flow thread that paints for the column. Along the inline axis, columns are
    // unclipped at outside edges (i.e., the first and last column in the set), and they clip to half the column
    // gap along interior edges.
    //
    // In the block direction, we will not clip overflow out of the top of the first column, or out of the bottom of
    // the last column. This applies only to the true first column and last column across all column sets.
    //
    // FIXME: Eventually we will know overflow on a per-column basis, but we can't do this until we have a painting
    // mode that understands not to paint contents from a previous column in the overflow area of a following column.
    // This problem applies to fragments and pages as well and is not unique to columns.

    let progressionReversed = multiColumnFlowForMultiColumnSet()!.progressionIsReversed()

    let isFirstColumn = index == 0
    let isLastColumn = index == colCount - 1
    let isLeftmostColumn =
      style().isLeftToRightDirection() != progressionReversed ? isFirstColumn : isLastColumn
    let isRightmostColumn =
      style().isLeftToRightDirection() != progressionReversed ? isLastColumn : isFirstColumn

    // Calculate the overflow rectangle, based on the flow thread's, clipped at column logical
    // top/bottom unless it's the first/last column.
    var overflowRect = overflowRectForFragmentedFlowPortion(
      portionRect, isFirstPortion: isFirstColumn && isFirstFragment(),
      isLastPortion: isLastColumn && isLastFragment())

    // For RenderViews only (i.e., iBooks), avoid overflowing into neighboring columns, by clipping in the middle of adjacent column gaps. Also make sure that we avoid rounding errors.
    if CPtrToInt(view().p) == CPtrToInt(parent()?.p) {
      if isHorizontalWritingMode() {
        if !isLeftmostColumn {
          overflowRect.shiftXEdgeTo(edge: portionRect.x() - colGap / 2)
        }
        if !isRightmostColumn {
          overflowRect.shiftMaxXEdgeTo(edge: portionRect.maxX() + colGap - colGap / 2)
        }
      } else {
        if !isLeftmostColumn {
          overflowRect.shiftYEdgeTo(edge: portionRect.y() - colGap / 2)
        }
        if !isRightmostColumn {
          overflowRect.shiftMaxYEdgeTo(edge: portionRect.maxY() + colGap - colGap / 2)
        }
      }
    }
    return overflowRect
  }

  private func initialBlockOffsetForPainting() -> LayoutUnit {
    let progressionReversed = multiColumnFlowForMultiColumnSet()!.progressionIsReversed()
    let progressionIsInline = multiColumnFlowForMultiColumnSet()!.progressionIsInline()

    var result = LayoutUnit()
    if !progressionIsInline && progressionReversed {
      let colRect = columnRectAt(0)
      result = isHorizontalWritingMode() ? colRect.y() : colRect.x()
    }
    return result
  }

  enum ColumnIndexCalculationMode {
    case ClampToExistingColumns  // Stay within the range of already existing columns.
    case AssumeNewColumns  // Allow column indices outside the range of already existing columns.
  }

  private func columnIndexAtOffset(
    _ offset: LayoutUnit, _ mode: ColumnIndexCalculationMode = .ClampToExistingColumns
  ) -> UInt32 {
    let portionRect = fragmentedFlowPortionRect()

    // Handle the offset being out of range.
    let fragmentedFlowLogicalTop = isHorizontalWritingMode() ? portionRect.y() : portionRect.x()
    if offset < fragmentedFlowLogicalTop {
      return 0
    }
    // If we're laying out right now, we cannot constrain against some logical bottom, since it
    // isn't known yet. Otherwise, just return the last column if we're past the logical bottom.
    if mode == .ClampToExistingColumns {
      let fragmentedFlowLogicalBottom =
        isHorizontalWritingMode() ? portionRect.maxY() : portionRect.maxX()
      if offset >= fragmentedFlowLogicalBottom {
        return columnCount() - 1
      }
    }

    // Sometimes computedColumnHeight() is 0 here: see https://bugs.webkit.org/show_bug.cgi?id=132884
    if !computedColumnHeight.bool() {
      return 0
    }

    // Just divide by the column height to determine the correct column.
    return UInt32((offset - fragmentedFlowLogicalTop).float() / computedColumnHeight)
  }

  private func setAndConstrainColumnHeight(_ newHeight: LayoutUnit) {
    computedColumnHeight = newHeight
    if computedColumnHeight > maxColumnHeight {
      computedColumnHeight = maxColumnHeight
    }

    // FIXME: The available column height is not the same as the constrained height specified
    // by the pagination API. The column set in this case is allowed to be bigger than the
    // height of a single column. We cache available column height in order to use it
    // in computeLogicalHeight later. This is pretty gross, and maybe there's a better way
    // to formalize the idea of clamped column heights without having a view dependency
    // here.
    availableColumnHeight = computedColumnHeight
    if multiColumnFlowForMultiColumnSet() != nil
      && !multiColumnFlowForMultiColumnSet()!.progressionIsInline()
      && parent()!.isRenderView()
    {
      let pageLength = UInt32(view().frameView().pagination().pageLength)
      if pageLength != 0 {
        computedColumnHeight = LayoutUnit(value: pageLength)
      }
    }

    columnHeightComputed = true

    // FIXME: the height may also be affected by the enclosing pagination context, if any.
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
