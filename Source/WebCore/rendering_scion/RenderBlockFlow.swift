/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

import wk_interop

private func calculateMinimumPageHeight(
  renderStyle: RenderStyleWrapper, lastLine: InlineIterator.LineBoxIterator, lineTop: LayoutUnit,
  lineBottom: LayoutUnit
) -> LayoutUnit {
  // We may require a certain minimum number of lines per page in order to satisfy
  // orphans and widows, and that may affect the minimum page height.
  let lineCount = max(
    renderStyle.hasAutoOrphans() ? 1 : renderStyle.orphans(),
    renderStyle.hasAutoWidows() ? 1 : renderStyle.widows())
  var lineTop = lineTop
  if lineCount > 1 {
    var line = lastLine
    for _ in 1..<lineCount {
      if !line.get().previous().bool() {
        break
      }
      line = line.get().previous()
    }

    // FIXME: Paginating using line overflow isn't all fine. See FIXME in
    // adjustLinePositionForPagination() for more details.
    lineTop = LayoutUnit(value: min(line.get().logicalTop(), line.get().inkOverflowLogicalTop()))
  }
  return lineBottom - lineTop
}

private func needsAppleMailPaginationQuirk(renderer: RenderBlockFlowWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func clearShouldBreakAtLineToAvoidWidowIfNeeded(blockFlow: RenderBlockFlowWrapper) {
  if !blockFlow.shouldBreakAtLineToAvoidWidow() {
    return
  }
  blockFlow.clearShouldBreakAtLineToAvoidWidow()
  blockFlow.setDidBreakAtLineToAvoidWidow()
}

class RenderBlockFlowWrapper: RenderBlockWrapper {
  convenience init(
    type: `Type`, document: Document, style: RenderStyleWrapper, flags: BlockFlowFlag = []
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func collapsedMarginAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paintColumnRules(paintInfo: PaintInfoWrapper, point: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setStaticInlinePositionForChild(
    child: RenderBoxWrapper, blockOffset: LayoutUnit, inlinePosition: LayoutUnit
  ) {
    wk_interop.RenderBlockFlow_setStaticInlinePositionForChild(
      p, child.p, blockOffset.rawValue(), inlinePosition.rawValue())
  }

  func shouldBreakAtLineToAvoidWidow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearShouldBreakAtLineToAvoidWidow() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lineBreakToAvoidWidow() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setBreakAtLineToAvoidWidow(lineToBreak: Int) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearDidBreakAtLineToAvoidWidow() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setDidBreakAtLineToAvoidWidow() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func multiColumnFlowForBlockFlow() -> RenderMultiColumnFlowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMultiColumnFlow(fragmentedFlow: RenderMultiColumnFlowWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearMultiColumnFlow() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func willCreateColumns(desiredColumnCount: UInt32? = nil) -> Bool {
    // The following types are not supposed to create multicol context.
    if isRenderFileUploadControl() || isRenderTextControl() || isRenderListBox() {
      return false
    }
    if isRenderSVGBlock() {
      return false
    }
    if style().display() == .RubyBlock || style().display() == .RubyAnnotation {
      return false
    }

    if firstChild() == nil {
      return false
    }

    if style().pseudoElementType() != .None {
      return false
    }

    // If overflow-y is set to paged-x or paged-y on the body or html element, we'll handle the paginating in the RenderView instead.
    if (style().overflowY() == .PagedX || style().overflowY() == .PagedY)
      && !(isDocumentElementRenderer() || isBody())
    {
      return true
    }

    if !style().specifiesColumns() {
      return false
    }

    // column-axis with opposite writing direction initiates MultiColumnFlow.
    if !style().hasInlineColumnAxis() {
      return true
    }

    // Non-auto column-width always initiates MultiColumnFlow.
    if !style().hasAutoColumnWidth() {
      return true
    }

    if desiredColumnCount != nil {
      return desiredColumnCount! > 1
    }

    // column-count > 1 always initiates MultiColumnFlow.
    if !style().hasAutoColumnCount() {
      return style().columnCount() > 1
    }

    fatalError("Not reached")
  }

  func requiresColumns(desiredColumnCount: Int32) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func containsFloats() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func containsFloat(renderer: RenderBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func subtreeContainsFloats() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func subtreeContainsFloat(renderer: RenderBoxWrapper) -> Bool {
    if containsFloat(renderer: renderer) {
      return true
    }

    for block: RenderBlockWrapper in descendantsOfType(root: self) {
      if let blockFlow = block as? RenderBlockFlowWrapper,
        blockFlow.containsFloat(renderer: renderer)
      {
        return true
      }
    }

    return false
  }

  override func deleteLines() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removeFloatingObjects() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func markAllDescendantsWithFloatsForLayout(
    floatToRemove: RenderBoxWrapper? = nil, inLayout: Bool = true
  ) {
    if !everHadLayout() && !containsFloats() {
      return
    }

    let markParents: MarkingBehavior = inLayout ? .MarkOnlyThis : .MarkContainingBlockChain
    setChildNeedsLayout(markParents: markParents)

    if floatToRemove != nil {
      removeFloatingObject(floatBox: floatToRemove!)
    } else if childrenInline() {
      return
    }

    // Iterate over our block children and mark them as needed.
    for block: RenderBlockWrapper in childrenOfType(parent: self) {
      if floatToRemove == nil && block.isFloatingOrOutOfFlowPositioned() {
        continue
      }
      if let blockFlow = block as? RenderBlockFlowWrapper {
        if (floatToRemove != nil
          ? blockFlow.subtreeContainsFloat(renderer: floatToRemove!)
          : blockFlow.subtreeContainsFloats())
          || blockFlow.shrinkToAvoidFloats()
        {
          blockFlow.markAllDescendantsWithFloatsForLayout(
            floatToRemove: floatToRemove, inLayout: inLayout)
        }
      } else if block.shrinkToAvoidFloats() && block.everHadLayout() {
        block.setChildNeedsLayout(markParents: markParents)
      }
    }
  }

  func markSiblingsWithFloatsForLayout(floatToRemove: RenderBoxWrapper? = nil) {
    if floatingObjects == nil {
      return
    }

    let floatingObjectSet = floatingObjects!.set()

    var next = nextSibling()
    while next != nil {
      let nextBlock = next as? RenderBlockFlowWrapper
      if nextBlock == nil
        || (floatToRemove == nil
          && (next!.isFloatingOrOutOfFlowPositioned() || nextBlock!.avoidsFloats()))
      {
        next = next!.nextSibling()
        continue
      }

      for floatingObject in floatingObjectSet {
        let floatingBox = floatingObject.renderer!
        if floatToRemove == nil && CPtrToInt(floatingBox.p) != CPtrToInt(floatToRemove!.p) {
          continue
        }
        if nextBlock!.containsFloat(renderer: floatingBox) {
          nextBlock!.markAllDescendantsWithFloatsForLayout(floatToRemove: floatingBox)
        }
      }

      next = next!.nextSibling()
    }
  }

  func floatingObjectSet() -> FloatingObjectSet? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func insertFloatingObjectForIFC(floatBox: RenderBoxWrapper) -> FloatingObjectWrapper {
    return FloatingObjectWrapper(
      p: wk_interop.RenderBlockFlow_insertFloatingObjectForIFC(p, floatBox.p))
  }

  func flipFloatForWritingModeForChild(child: FloatingObjectWrapper, point: LayoutPointWrapper)
    -> LayoutPointWrapper
  {
    if !style().isFlippedBlocksWritingMode() {
      return point
    }

    // This is similar to RenderBox::flipForWritingModeForChild. We have to subtract out our left/top offsets twice, since
    // it's going to get added back in. We hide this complication here so that the calling code looks normal for the unflipped
    // case.
    if isHorizontalWritingMode() {
      return LayoutPointWrapper(
        x: point.x,
        y: point.y + height() - child.renderer!.height() - 2
          * child.locationOffsetOfBorderBox().height())
    }
    return LayoutPointWrapper(
      x: point.x + width() - child.renderer!.width() - 2
        * child.locationOffsetOfBorderBox().width(), y: point.y)
  }

  override func setChildrenInline(b: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum InvalidationReason {
    case StyleChange
    case InsertionOrRemoval  // renderer gets constructed/goes away
    case ContentChange  // existing renderer gets changed (text content only atm)
  }

  func invalidateLineLayoutPath(invalidationReason: InvalidationReason) {
    switch lineLayoutPath() {
    case .UndeterminedPath:
      return
    case .SvgTextPath:
      setLineLayoutPath(path: .UndeterminedPath)
      return
    case .InlinePath:
      // FIXME: Implement partial invalidation.
      if inlineLayout() != nil {
        previousInlineLayoutContentBoxLogicalHeight = inlineLayout()!.contentBoxLogicalHeight()
        if invalidationReason != .InsertionOrRemoval {
          // Repaint and set needs layout, including out of flow boxes.
          // Since we eagerly remove the display content here, repaints issued between this invalidation (triggered by style change/content mutation) and the subsequent layout would produce empty rects.
          repaint()
          let walker = InlineWalker(root: self)
          while !walker.atEnd() {
            let renderer = walker.current()!
            if !renderer.everHadLayout() {
              walker.advance()
              continue
            }
            if !renderer.isInFlow()
              && inlineLayout()!.contains(renderer: renderer as! RenderElementWrapper)
            {
              renderer.repaint()
            }
            renderer.setPreferredLogicalWidthsDirty(shouldBeDirty: true)
            walker.advance()
          }
        }
      }
      lineLayout = .None
      if invalidationReason == .InsertionOrRemoval {
        setLineLayoutPath(path: .UndeterminedPath)
      }
      if selfNeedsLayout() || normalChildNeedsLayout() {
        return
      }
      // FIXME: We should just kick off a subtree layout here (if needed at all) see webkit.org/b/172947.
      setNeedsLayout()
      return
    }
  }

  enum LineLayoutPath {
    case UndeterminedPath
    case InlinePath
    case SvgTextPath
  }

  func lineLayoutPath() -> LineLayoutPath {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLineLayoutPath(path: LineLayoutPath) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func svgTextLayout() -> LegacyLineLayout? {
    switch lineLayout {
    case .Legacy(let layout):
      return layout
    default:
      return nil
    }
  }

  func inlineLayout() -> LayoutIntegration.LineLayout? {
    switch lineLayout {
    case .Integration(let layout):
      return layout
    default:
      return nil
    }
  }

  enum PageBoundaryRule {
    case ExcludePageBoundary
    case IncludePageBoundary
  }

  func pageLogicalHeightForOffsetFromBlockFlow(offset: LayoutUnit) -> LayoutUnit {
    // Unsplittable objects clear out the pageLogicalHeight in the layout state as a way of signaling that no
    // pagination should occur. Therefore we have to check this first and bail if the value has been set to 0.
    let pageLogicalHeight = view().frameView().layoutContext().layoutState()!.pageLogicalHeight()
    if !pageLogicalHeight.bool() {
      return LayoutUnit(value: 0)
    }

    // Now check for a flow thread.
    if let fragmentedFlow = enclosingFragmentedFlow() {
      return fragmentedFlow.pageLogicalHeightForOffsetFromFragmentedFlow(
        offset: offset + offsetFromLogicalTopOfFirstPage())
    }

    return pageLogicalHeight
  }

  private func pageRemainingLogicalHeightForOffsetFromBlockFlow(
    offset: LayoutUnit, pageBoundaryRule: PageBoundaryRule = .IncludePageBoundary
  ) -> LayoutUnit {
    var offset = offset
    offset += offsetFromLogicalTopOfFirstPage()

    if let fragmentedFlow = enclosingFragmentedFlow() {
      return fragmentedFlow.pageRemainingLogicalHeightForOffsetFromFragmentedFlow(
        offset: offset, pageBoundaryRule: pageBoundaryRule)
    }

    let pageLogicalHeight = view().frameView().layoutContext().layoutState()!.pageLogicalHeight()
    var remainingHeight = pageLogicalHeight - LayoutUnit.intMod(a: offset, b: pageLogicalHeight)
    if pageBoundaryRule == .IncludePageBoundary {
      // If includeBoundaryPoint is true the line exactly on the top edge of a
      // column will act as being part of the previous column.
      remainingHeight = LayoutUnit.intMod(a: remainingHeight, b: pageLogicalHeight)
    }
    return remainingHeight
  }

  func hasNextPage(
    logicalOffset: LayoutUnit, pageBoundaryRule: PageBoundaryRule = .ExcludePageBoundary
  ) -> Bool {
    assert(
      view().frameView().layoutContext().layoutState() != nil
        && view().frameView().layoutContext().layoutState()!.isPaginated())

    let fragmentedFlow = enclosingFragmentedFlow()
    if fragmentedFlow == nil {
      return true  // Printing and multi-column both make new pages to accommodate content.
    }

    // See if we're in the last fragment.
    let pageOffset = offsetFromLogicalTopOfFirstPage() + logicalOffset
    let fragment = fragmentedFlow!.fragmentAtBlockOffset(
      clampBox: self, offset: pageOffset, extendLastFragment: true)
    if fragment == nil {
      return false
    }

    if fragment!.isLastFragment() {
      return fragment!.isRenderFragmentContainerSet()
        || (pageBoundaryRule == .IncludePageBoundary
          && pageOffset == fragment!.logicalTopForFragmentedFlowContent())
    }

    if let (_, endFragment) = fragmentedFlow!.getFragmentRangeForBox(box: self) {
      return CPtrToInt(fragment!.p) != CPtrToInt(endFragment.p)
    }
    return false
  }

  // A page break is required at some offset due to space shortage in the current fragmentainer.
  func setPageBreak(offset: LayoutUnit, spaceShortage: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Update minimum page height required to avoid fragmentation where it shouldn't occur (inside
  // unbreakable content, between orphans and widows, etc.). This will be used as a hint to the
  // column balancer to help set a good minimum column height.
  func updateMinimumPageHeight(offset: LayoutUnit, minHeight: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addFloatsToNewParent(toBlockFlow: RenderBlockFlowWrapper) {
    // When a portion of the render tree is being detached, anonymous blocks
    // will be combined as their children are deleted. In this process, the
    // anonymous block later in the tree is merged into the one preceeding it.
    // It can happen that the later block (this) contains floats that the
    // previous block (toBlockFlow) did not contain, and thus are not in the
    // floating objects list for toBlockFlow. This can result in toBlockFlow
    // containing floats that are not in it's floating objects list, but are in
    // the floating objects lists of siblings and parents. This can cause
    // problems when the float itself is deleted, since the deletion code
    // assumes that if a float is not in it's containing block's floating
    // objects list, it isn't in any floating objects list. In order to
    // preserve this condition (removing it has serious performance
    // implications), we need to copy the floating objects from the old block
    // (this) to the new block (toBlockFlow). The float's metrics will likely
    // all be wrong, but since toBlockFlow is already marked for layout, this
    // will get fixed before anything gets displayed.
    // See bug https://bugs.webkit.org/show_bug.cgi?id=115566
    if floatingObjects == nil {
      return
    }

    if toBlockFlow.floatingObjects == nil {
      toBlockFlow.createFloatingObjects()
    }

    for floatingObject in floatingObjects!.set() {
      if toBlockFlow.containsFloat(renderer: floatingObject.renderer!) {
        continue
      }
      toBlockFlow.floatingObjects!.add(floatingObject: floatingObject.cloneForNewParent())
    }
  }

  func endPaddingWidthForCaret() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBlockFlow_endPaddingWidthForCaret(p))
  }

  func lowestInitialLetterLogicalBottom() -> LayoutUnit? {
    let raw = wk_interop.RenderBlockFlow_lowestInitialLetterLogicalBottom(p)
    if !raw.is_valid {
      return nil
    }
    return LayoutUnit.fromRawValue(value: raw.value)
  }

  private func pushToNextPageWithMinimumLogicalHeight(
    adjustment: inout LayoutUnit, logicalOffset: LayoutUnit, minimumLogicalHeight: LayoutUnit
  ) -> Bool {
    var checkFragment = false
    let fragmentedFlow = enclosingFragmentedFlow()
    var currentFragmentContainer: RenderFragmentContainerWrapper? = nil
    var pageLogicalHeight = pageLogicalHeightForOffsetFromBlockFlow(
      offset: logicalOffset + adjustment)
    while pageLogicalHeight.bool() {
      if minimumLogicalHeight <= pageLogicalHeight {
        return true
      }
      let adjustedOffset = logicalOffset + adjustment
      if !hasNextPage(logicalOffset: adjustedOffset) {
        return false
      }
      if fragmentedFlow != nil {
        // While in layout and the columnsets are not balanced yet, we keep finding the same (infinite tall) column over and over again.
        let nextFragmentContainer = fragmentedFlow!.fragmentAtBlockOffset(
          clampBox: self, offset: adjustedOffset, extendLastFragment: true)!
        if CPtrToInt(nextFragmentContainer.p) == CPtrToInt(currentFragmentContainer?.p) {
          return false
        }
        currentFragmentContainer = nextFragmentContainer
      }
      adjustment += pageLogicalHeight
      checkFragment = true
      pageLogicalHeight = pageLogicalHeightForOffsetFromBlockFlow(
        offset: logicalOffset + adjustment)
    }
    return !checkFragment
  }

  private func createFloatingObjects() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct LinePaginationAdjustment {
    var strut = LayoutUnit(value: 0)
    var isFirstAfterPageBreak = false
  }

  override func paintInlineChildren(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(childrenInline())

    if let inlineLayout = inlineLayout() {
      inlineLayout.paint(paintInfo: paintInfo, paintOffset: paintOffset)
      return
    }

    if let svgTextLayout = svgTextLayout() {
      svgTextLayout.lineBoxes.paint(
        renderer: self, paintInfo: paintInfo, paintOffset: paintOffset)
    }
  }

  override func paintFloats(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, preservePhase: Bool = false
  ) {
    if floatingObjects == nil {
      return
    }

    let floatingObjectSet = floatingObjects!.set()
    for floatingObject in floatingObjectSet {
      let renderer = floatingObject.renderer!
      if floatingObject.shouldPaint() {
        var currentPaintInfo = paintInfo
        currentPaintInfo.phase = preservePhase ? paintInfo.phase : .BlockBackground
        let childPoint = flipFloatForWritingModeForChild(
          child: floatingObject, point: paintOffset + floatingObject.translationOffsetToAncestor())
        renderer.paint(paintInfo: &currentPaintInfo, paintOffset: childPoint)
        if !preservePhase {
          currentPaintInfo.phase = .ChildBlockBackgrounds
          renderer.paint(paintInfo: &currentPaintInfo, paintOffset: childPoint)
          currentPaintInfo.phase = .Float
          renderer.paint(paintInfo: &currentPaintInfo, paintOffset: childPoint)
          currentPaintInfo.phase = .Foreground
          renderer.paint(paintInfo: &currentPaintInfo, paintOffset: childPoint)
          currentPaintInfo.phase = .Outline
          renderer.paint(paintInfo: &currentPaintInfo, paintOffset: childPoint)
        }
      }
    }
  }

  private func removeFloatingObject(floatBox: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func hasInlineLayout() -> Bool {
    switch lineLayout {
    case .Integration:
      return true
    default:
      return false
    }
  }

  func computeLineAdjustmentForPagination(
    lineBox: InlineIterator.LineBoxIterator, delta: LayoutUnit, floatMinimumBottom: LayoutUnit
  ) -> LinePaginationAdjustment {
    let logicalOverflowTop = LayoutUnit(value: lineBox.get().inkOverflowLogicalTop())
    let logicalOverflowBottom = LayoutUnit(value: lineBox.get().inkOverflowLogicalBottom())
    let logicalOverflowHeight = logicalOverflowBottom - logicalOverflowTop
    let logicalTop = LayoutUnit(value: lineBox.get().logicalTop())
    let logicalOffset = min(logicalTop, logicalOverflowTop)

    var floatMinimumBottom = floatMinimumBottom
    if floatMinimumBottom.bool() {
      // Don't push a float to the next page if it is taller than the page.
      let floatHeight = floatMinimumBottom - logicalTop
      if floatHeight > pageLogicalHeightForOffsetFromBlockFlow(offset: floatMinimumBottom) {
        floatMinimumBottom = LayoutUnit(value: UInt64(0))
      }
    }

    let logicalBottom = max(
      LayoutUnit(value: lineBox.get().logicalBottom()), logicalOverflowBottom, floatMinimumBottom)
    var lineHeight = logicalBottom - logicalOffset

    updateMinimumPageHeight(
      offset: logicalOffset,
      minHeight: calculateMinimumPageHeight(
        renderStyle: style(), lastLine: lineBox, lineTop: logicalOffset, lineBottom: logicalBottom))

    var pageLogicalHeight = pageLogicalHeightForOffsetFromBlockFlow(offset: logicalOffset)

    let fragmentedFlow = enclosingFragmentedFlow()
    let hasUniformPageLogicalHeight =
      fragmentedFlow == nil || fragmentedFlow!.fragmentsHaveUniformLogicalHeight()
    // If lineHeight is greater than pageLogicalHeight, but logicalVisualOverflow.height() still fits, we are
    // still going to add a strut, so that the visible overflow fits on a single page.
    if !pageLogicalHeight.bool() || !hasNextPage(logicalOffset: logicalOffset) {
      // FIXME: In case the line aligns with the top of the page (or it's slightly shifted downwards) it will not be marked as the first line in the page.
      // From here, the fix is not straightforward because it's not easy to always determine when the current line is the first in the page.
      // With no valid page height, we can't possibly accommodate the widow rules.
      clearShouldBreakAtLineToAvoidWidowIfNeeded(blockFlow: self)
      return LinePaginationAdjustment()
    }

    if hasUniformPageLogicalHeight && logicalOverflowHeight > pageLogicalHeight {
      // We are so tall that we are bigger than a page. Before we give up and just leave the line where it is, try drilling into the
      // line and computing a new height that excludes anything we consider "blank space". We will discard margins, descent, and even overflow. If we are
      // able to fit with the blank space and overflow excluded, we will give the line its own page with the highest non-blank element being aligned with the
      // top of the page.
      let (logicalOffset, logicalBottom) = RenderBlockFlowWrapper.computeLeafBoxTopAndBottom(
        lineBox: lineBox)
      lineHeight = logicalBottom - logicalOffset
      if logicalOffset == LayoutUnit.max() || lineHeight > pageLogicalHeight {
        // Give up. We're genuinely too big even after excluding blank space and overflow.
        clearShouldBreakAtLineToAvoidWidowIfNeeded(blockFlow: self)
        return LinePaginationAdjustment()
      }
      pageLogicalHeight = pageLogicalHeightForOffsetFromBlockFlow(offset: logicalOffset)
    }

    var remainingLogicalHeight = pageRemainingLogicalHeightForOffsetFromBlockFlow(
      offset: logicalOffset, pageBoundaryRule: .ExcludePageBoundary)

    let lineNumber = Int32(lineBox.get().lineIndex() + 1)
    if remainingLogicalHeight < lineHeight
      || (shouldBreakAtLineToAvoidWidow() && lineBreakToAvoidWidow() == lineNumber)
    {
      if lineBreakToAvoidWidow() == lineNumber {
        clearShouldBreakAtLineToAvoidWidowIfNeeded(blockFlow: self)
      }
      // If we have a non-uniform page height, then we have to shift further possibly.
      if !hasUniformPageLogicalHeight
        && !pushToNextPageWithMinimumLogicalHeight(
          adjustment: &remainingLogicalHeight, logicalOffset: logicalOffset,
          minimumLogicalHeight: lineHeight)
      {
        return LinePaginationAdjustment()
      }
      if lineHeight > pageLogicalHeight {
        // Split the top margin in order to avoid splitting the visible part of the line.
        remainingLogicalHeight -= min(
          lineHeight - pageLogicalHeight,
          max(LayoutUnit(value: UInt64(0)), logicalOverflowTop - logicalTop))
      }
      let totalLogicalHeight = lineHeight + max(LayoutUnit(value: 0), logicalOffset)
      let pageLogicalHeightAtNewOffset =
        hasUniformPageLogicalHeight
        ? pageLogicalHeight
        : pageLogicalHeightForOffsetFromBlockFlow(offset: logicalOffset + remainingLogicalHeight)

      setPageBreak(offset: logicalOffset, spaceShortage: lineHeight - remainingLogicalHeight)

      let avoidFirstLinePageBreak =
        lineBox.get().isFirst() && totalLogicalHeight < pageLogicalHeightAtNewOffset
        && !floatMinimumBottom.bool()
      let affectedByOrphans = !style().hasAutoOrphans() && style().orphans() >= lineNumber

      if (avoidFirstLinePageBreak || affectedByOrphans) && !isOutOfFlowPositioned()
        && !isRenderTableCell()
      {
        if needsAppleMailPaginationQuirk(renderer: self) {
          return LinePaginationAdjustment()
        }

        let firstLineBox = InlineIterator.firstLineBoxFor(flow: self)
        let firstLineBoxOverflowTop = LayoutUnit(
          value: firstLineBox.bool() ? firstLineBox.get().inkOverflowLogicalTop() : 0)
        let firstLineUpperOverhang = max(-firstLineBoxOverflowTop, LayoutUnit(value: UInt64(0)))
        setPaginationStrut(strut: remainingLogicalHeight + logicalOffset + firstLineUpperOverhang)

        return LinePaginationAdjustment()
      }

      return LinePaginationAdjustment(strut: remainingLogicalHeight, isFirstAfterPageBreak: true)
    }

    if remainingLogicalHeight == pageLogicalHeight {
      // We're at the very top of a page or column.
      let isFirstLine = lineBox.get().isFirst()
      if !isFirstLine || offsetFromLogicalTopOfFirstPage().bool() {
        setPageBreak(offset: logicalOffset, spaceShortage: lineHeight)
      }

      return LinePaginationAdjustment(
        strut: LayoutUnit(value: UInt64(0)), isFirstAfterPageBreak: !isFirstLine)
    }

    return LinePaginationAdjustment()
  }

  // FIXME: We are still honoring gigantic margins, which does leave open the possibility of blank pages caused by this heuristic. It remains to be seen whether or not
  // this will be a real-world issue. For now we don't try to deal with this problem.
  private static func computeLeafBoxTopAndBottom(lineBox: InlineIterator.LineBoxIterator) -> (
    LayoutUnit, LayoutUnit
  ) {
    var lineTop = LayoutUnit.max()
    var lineBottom = LayoutUnit.min()
    let box = lineBox.get().firstLeafBox()
    while box.bool() {
      if box.get().logicalTop() < lineTop {
        lineTop = LayoutUnit(value: box.get().logicalTop())
      }
      if box.get().logicalBottom() > lineBottom {
        lineBottom = LayoutUnit(value: box.get().logicalBottom())
      }
      box.traverseNextOnLine()
    }
    return (lineTop, lineBottom)
  }

  // FIXME: This is temporary until after we remove the forced "line layout codepath" invalidation.
  private var previousInlineLayoutContentBoxLogicalHeight: LayoutUnit?

  private let floatingObjects: FloatingObjects? = nil

  enum LineLayout {
    case None
    case Integration(LayoutIntegration.LineLayout)
    case Legacy(LegacyLineLayout)
  }

  var lineLayout: LineLayout = .None
}
