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
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func needsAppleMailPaginationQuirk(renderer: RenderBlockFlowWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func clearShouldBreakAtLineToAvoidWidowIfNeeded(blockFlow: RenderBlockFlowWrapper) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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

  func setBreakAtLineToAvoidWidow(lineToBreak: Int) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lineBreakToAvoidWidow() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func multiColumnFlowForBlockFlow() -> RenderMultiColumnFlowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearDidBreakAtLineToAvoidWidow() {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func markSiblingsWithFloatsForLayout(floatToRemove: RenderBoxWrapper? = nil) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func floatingObjectSet() -> FloatingObjectSet? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func insertFloatingObjectForIFC(floatBox: RenderBoxWrapper) -> FloatingObjectWrapper {
    return FloatingObjectWrapper(
      p: wk_interop.RenderBlockFlow_insertFloatingObjectForIFC(p, floatBox.p))
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

  func pageLogicalHeightForOffset(offset: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func pageRemainingLogicalHeightForOffsetFromBlockFlow(
    offset: LayoutUnit, pageBoundaryRule: PageBoundaryRule = .IncludePageBoundary
  ) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasNextPage(
    logicalOffset: LayoutUnit, pageBoundaryRule: PageBoundaryRule = .ExcludePageBoundary
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    adjustment: LayoutUnit, logicalOffset: LayoutUnit, minimumLogicalHeight: LayoutUnit
  ) -> Bool {
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
      if floatHeight > pageLogicalHeightForOffset(offset: floatMinimumBottom) {
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

    var pageLogicalHeight = pageLogicalHeightForOffset(offset: logicalOffset)

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
      pageLogicalHeight = pageLogicalHeightForOffset(offset: logicalOffset)
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
          adjustment: remainingLogicalHeight, logicalOffset: logicalOffset,
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
        : pageLogicalHeightForOffset(offset: logicalOffset + remainingLogicalHeight)

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

  enum LineLayout {
    case None
    case Integration(LayoutIntegration.LineLayout)
    case Legacy(LegacyLineLayout)
  }

  var lineLayout: LineLayout = .None
}
