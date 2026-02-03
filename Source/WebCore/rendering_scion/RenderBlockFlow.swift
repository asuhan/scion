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

private func inNormalFlow(child: RenderBoxWrapper) -> Bool {
  var curr = child.containingBlock()
  while curr != nil && CPtrToInt(curr?.p) != CPtrToInt(child.view().p) {
    if curr!.isRenderFragmentedFlow() {
      return true
    }
    if curr!.isFloatingOrOutOfFlowPositioned() {
      return false
    }
    curr = curr!.containingBlock()
  }
  return true
}

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

struct MarginValues {
  init(beforePos: LayoutUnit, beforeNeg: LayoutUnit, afterPos: LayoutUnit, afterNeg: LayoutUnit) {
    positiveMarginBefore = beforePos
    negativeMarginBefore = beforeNeg
    positiveMarginAfter = afterPos
    negativeMarginAfter = afterNeg
  }

  let positiveMarginBefore: LayoutUnit
  let negativeMarginBefore: LayoutUnit
  let positiveMarginAfter: LayoutUnit
  let negativeMarginAfter: LayoutUnit
}

// Allocated only when some of these fields have non-default values
class RenderBlockFlowRareData {
  var alignContentShift = LayoutUnit()  // Caches negative shifts for overflow calculation.
}

private func hasSimpleStaticPositionForInlineLevelOutOfFlowChildrenByStyle(
  rootStyle: RenderStyleWrapper
) -> Bool {
  if rootStyle.textAlign() != .Start {
    return false
  }
  if rootStyle.textIndent() != RenderStyleWrapper.zeroLength() {
    return false
  }
  return true
}

private func setFullRepaintOnParentInlineBoxLayerIfNeeded(renderer: RenderTextWrapper) {
  // Repaints (on self) are normally issued either during layout using LayoutRepainter inside ::layout() functions (#1)
  // or after layout, while recursing the layer tree (#2).
  // Additionally, repaint at the block level (#3) takes care of regular in-flow content.
  // However in case of text content, we don't have (#1), (#2) is primarily a geometry diff type of repaint meaning
  // no repaint happens unless content size changes (or full repaint bit is set on the layer)
  // and (#3) only works when the block container and the text content share the same layer.
  // Here we mark the parent inline box's layer dirty to trigger repaint at (#2).
  if !renderer.needsLayout() {
    return
  }
  if let parent = renderer.parent() {
    if !parent.isInline() || !parent.hasLayer() {
      return
    }
    (parent as! RenderLayerModelObjectWrapper).checkedLayer()!.repaintStatus = .NeedsFullRepaint
  }
  fatalError("Not reached")
}

private struct InlineMinMaxIterator {
  /* InlineMinMaxIterator is a class that will iterate over all render objects that contribute to
   inline min/max width calculations.  Note the following about the way it walks:
   (1) Positioned content is skipped (since it does not contribute to min/max width of a block)
   (2) We do not drill into the children of floats or replaced elements, since you can't break
       in the middle of such an element.
   (3) Inline flows (e.g., <a>, <span>, <i>) are walked twice, since each side can have
       distinct borders/margin/padding that contribute to the min/max width.
*/

  init(p: RenderBlockFlowWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func next() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let endOfInline: Bool
}

private func borderPaddingAndMarginWidth(childValue: LayoutUnit, cssUnit: LengthWrapper)
  -> LayoutUnit
{
  if cssUnit.isFixed() {
    return LayoutUnit(value: cssUnit.value())
  }
  if cssUnit.isAuto() {
    return LayoutUnit()
  }
  return childValue
}

private func getBorderPaddingMargin(child: RenderBoxModelObjectWrapper, endOfInline: Bool)
  -> LayoutUnit
{
  let childStyle = child.style()
  if endOfInline {
    return borderPaddingAndMarginWidth(
      childValue: child.marginEnd(), cssUnit: childStyle.marginEnd())
      + borderPaddingAndMarginWidth(
        childValue: child.paddingEnd(), cssUnit: childStyle.paddingEnd()) + child.borderEnd()
  }
  return borderPaddingAndMarginWidth(
    childValue: child.marginStart(), cssUnit: childStyle.marginStart())
    + borderPaddingAndMarginWidth(
      childValue: child.paddingStart(), cssUnit: childStyle.paddingStart()) + child.borderStart()
}

private func stripTrailingSpace(
  inlineMax: inout Float32, inlineMin: inout Float32, trailingSpaceChild: RenderObjectWrapper?
) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func preferredWidth(preferredWidth: LayoutUnit, result: Float32) -> LayoutUnit {
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

  override func layoutBlock(
    relayoutChildren: Bool, pageLogicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) {
    assert(needsLayout())

    if !relayoutChildren && simplifiedLayout() {
      return
    }

    let repainter = LayoutRepainter(renderer: self)

    var relayoutChildren = relayoutChildren
    if recomputeLogicalWidthAndColumnWidth() {
      relayoutChildren = true
    }

    if let layoutState = view().frameView().layoutContext().layoutState(),
      layoutState.legacyLineClamp() != nil
    {
      relayoutChildren = relayoutChildren || !isFieldset()
    }

    rebuildFloatingObjectSetFromIntrudingFloats()

    let previousHeight = logicalHeight()
    // FIXME: should this start out as borderAndPaddingLogicalHeight() + scrollbarLogicalHeight(),
    // for consistency with other render classes?
    resetLogicalHeightBeforeLayoutIfNeeded()

    var pageLogicalHeightChanged = false
    var pageLogicalHeight = pageLogicalHeight
    checkForPaginationLogicalHeightChange(
      relayoutChildren: &relayoutChildren, pageLogicalHeight: &pageLogicalHeight,
      pageLogicalHeightChanged: &pageLogicalHeightChanged)

    var repaintLogicalTop = LayoutUnit()
    var repaintLogicalBottom = LayoutUnit()
    var maxFloatLogicalBottom = LayoutUnit()
    var pageRemaining = LayoutUnit()
    let isPaginated = isPaginated()
    let styleToUse = style()
    repeat {
      let _ = LayoutStateMaintainer(
        root: self, offset: locationOffset(),
        disablePaintOffsetCache: isTransformed() || hasReflection()
          || styleToUse.isFlippedBlocksWritingMode(),
        pageHeight: pageLogicalHeight, pageHeightChanged: pageLogicalHeightChanged)

      preparePaginationBeforeBlockLayout(relayoutChildren: &relayoutChildren)
      if isPaginated {
        pageRemaining = pageLogicalHeightForOffsetFromBlockFlow(
          offset: LayoutUnit(value: UInt64(0)))
      }

      // We use four values, maxTopPos, maxTopNeg, maxBottomPos, and maxBottomNeg, to track
      // our current maximal positive and negative margins. These values are used when we
      // are collapsed with adjacent blocks, so for example, if you have block A and B
      // collapsing together, then you'd take the maximal positive margin from both A and B
      // and subtract it from the maximal negative margin from both A and B to get the
      // true collapsed margin. This algorithm is recursive, so when we finish layout()
      // our block knows its current maximal positive/negative values.
      //
      // Start out by setting our margin values to our current margins. Table cells have
      // no margins, so we don't fill in the values for table cells.
      let isCell = isRenderTableCell()
      if !isCell {
        initMaxMarginValues()

        setHasMarginBeforeQuirk(b: styleToUse.marginBefore().hasQuirk())
        setHasMarginAfterQuirk(b: styleToUse.marginAfter().hasQuirk())
        setPaginationStrut(strut: LayoutUnit(value: 0))
      }
      if firstChild() == nil && !isAnonymousBlock() {
        setChildrenInline(b: true)
      }
      dirtyForLayoutFromPercentageHeightDescendants()
      layoutInFlowChildren(
        relayoutChildren: relayoutChildren, repaintLogicalTop: &repaintLogicalTop,
        repaintLogicalBottom: &repaintLogicalBottom, maxFloatLogicalBottom: &maxFloatLogicalBottom)
      // Expand our intrinsic height to encompass floats.
      let toAdd = borderAndPaddingAfter() + scrollbarLogicalHeight()
      if lowestFloatLogicalBottom() > (logicalHeight() - toAdd) && createsNewFormattingContext() {
        setLogicalHeight(size: lowestFloatLogicalBottom() + toAdd)
      }
      if shouldBreakAtLineToAvoidWidow() {
        setEverHadLayout()
        continue
      }
      break
    } while true

    if relayoutForPagination() {
      assert(!shouldBreakAtLineToAvoidWidow())
      return
    }

    // Calculate our new height.
    let oldHeight = logicalHeight()
    var oldClientAfterEdge = clientLogicalBottom()

    // Before updating the final size of the flow thread make sure a forced break is applied after the content.
    // This ensures the size information is correctly computed for the last auto-height fragment receiving content.
    if let fragmentedFlow = self as? RenderFragmentedFlowWrapper {
      fragmentedFlow.applyBreakAfterContent(offsetBreak: oldClientAfterEdge)
    }

    updateLogicalHeight()
    let newHeight = logicalHeight()

    var alignContentShift = LayoutUnit(value: UInt64(0))
    // Alignment isn't supported when fragmenting.
    // Table cell alignment is handled in RenderTableCell::computeIntrinsicPadding.
    if (!isPaginated || pageRemaining > newHeight) && (settings().alignContentOnBlocksEnabled())
      && !isRenderTableCell()
    {
      alignContentShift = shiftForAlignContent(
        intrinsicLogicalHeight: oldHeight, repaintLogicalTop: &repaintLogicalTop,
        repaintLogicalBottom: &repaintLogicalBottom)
      oldClientAfterEdge += alignContentShift
      if alignContentShift < Int32(0) {
        ensureRareBlockFlowData().alignContentShift = alignContentShift
      }
    } else if hasRareBlockFlowData() {
      rareBlockFlowData().alignContentShift = LayoutUnit(value: UInt64(0))
    }

    do {
      // FIXME: This could be removed once relayoutForPagination() either stop recursing or we manage to
      // re-order them.
      let _ = LayoutStateMaintainer(
        root: self, offset: locationOffset(),
        disablePaintOffsetCache: isTransformed() || hasReflection()
          || styleToUse.isFlippedBlocksWritingMode(),
        pageHeight: pageLogicalHeight, pageHeightChanged: pageLogicalHeightChanged)

      if oldHeight != newHeight && oldHeight > newHeight && maxFloatLogicalBottom > newHeight
        && !childrenInline()
      {
        // One of our children's floats may have become an overhanging float for us. We need to look for it.
        for blockFlow: RenderBlockFlowWrapper in childrenOfType(parent: self) {
          if blockFlow.isFloatingOrOutOfFlowPositioned() {
            continue
          }
          if blockFlow.lowestFloatLogicalBottom() + blockFlow.logicalTop() > newHeight {
            addOverhangingFloats(child: blockFlow, makeChildPaintOtherFloats: false)
          }
        }
      }

      let heightChanged = (previousHeight != newHeight)
      if heightChanged || alignContentShift != LayoutUnit(value: UInt64(0)) {
        relayoutChildren = true
      }
      layoutPositionedObjects(relayoutChildren: relayoutChildren || isDocumentElementRenderer())
    }

    updateDescendantTransformsAfterLayout()

    // Add overflow from children (unless we're multi-column, since in that case all our child overflow is clipped anyway).
    computeOverflow(oldClientAfterEdge: oldClientAfterEdge)

    if let state = view().frameView().layoutContext().layoutState(),
      state.pageLogicalHeight().bool()
    {
      setPageLogicalOffset(
        logicalOffset: state.pageLogicalOffset(child: self, childLogicalOffset: logicalTop()))
    }

    updateLayerTransform()

    // Update our scroll information if we're overflow:auto/scroll/hidden now that we know if
    // we overflow or not.
    updateScrollInfoAfterLayout()

    // FIXME: This repaint logic should be moved into a separate helper function!
    // Repaint with our new bounds if they are different from our old bounds.
    let didFullRepaint = repainter.repaintAfterLayout()
    if !didFullRepaint && repaintLogicalTop != repaintLogicalBottom
      && (styleToUse.usedVisibility() == .Visible || enclosingLayer()!.hasVisibleContent)
    {
      // FIXME: We could tighten up the left and right invalidation points if we let layoutInlineChildren fill them in based off the particular lines
      // it had to lay out. We wouldn't need the hasNonVisibleOverflow() hack in that case either.
      var repaintLogicalLeft = logicalLeftVisualOverflow()
      var repaintLogicalRight = logicalRightVisualOverflow()
      if hasNonVisibleOverflow() {
        // If we have clipped overflow, we should use layout overflow as well, since visual overflow from lines didn't propagate to our block's overflow.
        // Note the old code did this as well but even for overflow:visible. The addition of hasNonVisibleOverflow() at least tightens up the hack a bit.
        // layoutInlineChildren should be patched to compute the entire repaint rect.
        repaintLogicalLeft = min(repaintLogicalLeft, logicalLeftLayoutOverflow())
        repaintLogicalRight = max(repaintLogicalRight, logicalRightLayoutOverflow())
      }

      var repaintRect = LayoutRectWrapper()
      if isHorizontalWritingMode() {
        repaintRect = LayoutRectWrapper(
          x: repaintLogicalLeft, y: repaintLogicalTop,
          width: repaintLogicalRight - repaintLogicalLeft,
          height: repaintLogicalBottom - repaintLogicalTop)
      } else {
        repaintRect = LayoutRectWrapper(
          x: repaintLogicalTop, y: repaintLogicalLeft,
          width: repaintLogicalBottom - repaintLogicalTop,
          height: repaintLogicalRight - repaintLogicalLeft)
      }

      if hasNonVisibleOverflow() {
        // Adjust repaint rect for scroll offset
        repaintRect.moveBy(offset: LayoutPointWrapper(point: -scrollPosition()))

        // Don't allow this rect to spill out of our overflow box.
        repaintRect.intersect(
          other: LayoutRectWrapper(location: LayoutPointWrapper(), size: size()))
      }

      // Make sure the rect is still non-empty after intersecting for overflow above
      if !repaintRect.isEmpty() {
        repaintRectangle(repaintRect: repaintRect)  // We need to do a partial repaint of our content.
        if hasReflection() {
          repaintRectangle(repaintRect: reflectedRect(r: repaintRect))
        }
      }
    }

    clearNeedsLayout()
  }

  private func isPaginated() -> Bool {
    // FIXME: Grid calls into layout outside of regular layout phase (during preferred width computation).
    if let layoutState = view().frameView().layoutContext().layoutState() {
      return layoutState.isPaginated()
    }
    return false
  }

  // This method is called at the start of layout to wipe away all of the floats in our floating objects list. It also
  // repopulates the list with any floats that intrude from previous siblings or parents. Floats that were added by
  // descendants are gone when this call completes and will get added back later on after the children have gotten
  // a relayout.
  func rebuildFloatingObjectSetFromIntrudingFloats() {
    if floatingObjects != nil {
      floatingObjects!.setHorizontalWritingMode(b: isHorizontalWritingMode())
    }

    var oldIntrudingFloatSet: Set<UInt> = []
    if !childrenInline() && floatingObjects != nil {
      let floatingObjectSet = floatingObjects!.set()
      for floatingObject in floatingObjectSet {
        if !floatingObject.isDescendant() {
          oldIntrudingFloatSet.update(with: CPtrToInt(floatingObject.renderer?.p))
        }
      }
    }

    // Inline blocks are covered by the isReplacedOrInlineBlock() check in the avoidFloats method.
    if avoidsFloats() || isDocumentElementRenderer() || isRenderView()
      || isFloatingOrOutOfFlowPositioned() || isRenderTableCell()
    {
      if floatingObjects != nil {
        floatingObjects!.clear()
      }
      if !oldIntrudingFloatSet.isEmpty {
        markAllDescendantsWithFloatsForLayout()
      }
      return
    }

    if floatingObjects != nil {
      floatingObjects!.clear()
    }

    // We should not process floats if the parent node is not a RenderBlock. Otherwise, we will add
    // floats in an invalid context. This will cause a crash arising from a bad cast on the parent.
    // See <rdar://problem/8049753>, where float property is applied on a text node in a SVG.
    let parentBlock = parent() as? RenderBlockFlowWrapper
    if parentBlock == nil {
      return
    }

    // First add in floats from the parent. Self-collapsing blocks let their parent track any floats that intrude into
    // them (as opposed to floats they contain themselves) so check for those here too.
    let (previousBlock, parentHasFloats) = previousSiblingWithOverhangingFloats()
    var logicalTopOffset = logicalTop()
    let parentHasIntrudingFloats =
      !parentHasFloats
      && (previousBlock == nil
        || (previousBlock!.isSelfCollapsingBlock()
          && parentBlock!.lowestFloatLogicalBottom() > logicalTopOffset))
    if parentHasFloats || parentHasIntrudingFloats {
      addIntrudingFloats(
        prev: parentBlock, container: parentBlock,
        logicalLeftOffset: parentBlock!.logicalLeftOffsetForContent(),
        logicalTopOffset: logicalTopOffset)
    }

    // Add overhanging floats from the previous RenderBlock, but only if it has a float that intrudes into our space.
    if previousBlock != nil {
      logicalTopOffset -= previousBlock!.logicalTop()
      if previousBlock!.lowestFloatLogicalBottom() > logicalTopOffset {
        addIntrudingFloats(
          prev: previousBlock, container: parentBlock, logicalLeftOffset: LayoutUnit(value: 0),
          logicalTopOffset: logicalTopOffset)
      }
    }

    if !childrenInline() && !oldIntrudingFloatSet.isEmpty {
      // If there are previously intruding floats that no longer intrude, then children with floats
      // should also get layout because they might need their floating object lists cleared.
      if floatingObjects!.set().size() < oldIntrudingFloatSet.count {
        markAllDescendantsWithFloatsForLayout()
      } else {
        let floatingObjectSet = floatingObjects!.set()
        for floatingObject in floatingObjectSet {
          if oldIntrudingFloatSet.isEmpty {
            break
          }
          oldIntrudingFloatSet.remove(CPtrToInt(floatingObject.renderer?.p))
          if !oldIntrudingFloatSet.isEmpty {
            markAllDescendantsWithFloatsForLayout()
          }
        }
      }
    }
  }

  // RenderBlockFlow always contains either lines or paragraphs. When the children are all blocks (e.g. paragraphs), we call layoutBlockChildren.
  // When the children are all inline (e.g., lines), we call layoutInlineChildren.
  func layoutInFlowChildren(
    relayoutChildren: Bool, repaintLogicalTop: inout LayoutUnit,
    repaintLogicalBottom: inout LayoutUnit, maxFloatLogicalBottom: inout LayoutUnit
  ) {
    if firstChild() == nil {
      // Empty block containers produce empty formatting lines which may affect trim-start/end.
      let _ = TextBoxTrimmer(blockContainer: self)

      var logicalHeight = borderAndPaddingLogicalHeight() + scrollbarLogicalHeight()
      if hasLineIfEmpty() {
        logicalHeight += lineHeight(
          firstLine: true, direction: isHorizontalWritingMode() ? .HorizontalLine : .VerticalLine,
          linePositionMode: .PositionOfInteriorLineBoxes)
      }
      setLogicalHeight(size: logicalHeight)

      repaintLogicalTop = LayoutUnit()
      repaintLogicalBottom = LayoutUnit()
      maxFloatLogicalBottom = LayoutUnit()
      return
    }

    if childrenInline() {
      let _ = TextBoxTrimmer(blockContainer: self)
      let _ = LineClampUpdater(blockContainer: self)
      return layoutInlineChildren(
        relayoutChildren: relayoutChildren, repaintLogicalTop: &repaintLogicalTop,
        repaintLogicalBottom: &repaintLogicalBottom)
    }

    do {
      do {
        // With block children, there's no way to tell what the last formatted line is until after we finished laying out the subtree.
        let _ = TextBoxTrimmer(blockContainer: self)
        let _ = LineClampUpdater(blockContainer: self)
        layoutBlockChildren(
          relayoutChildren: relayoutChildren, maxFloatLogicalBottom: &maxFloatLogicalBottom)
      }

      // Dirty the last formatted line (in the last IFC) and issue relayout with forcing trimming the last line if applicable.
      if let rootForLastFormattedLine = TextBoxTrimmer.lastInlineFormattingContextRootForTrimEnd(
        blockContainer: self)
      {
        assert(CPtrToInt(rootForLastFormattedLine.p) != CPtrToInt(p))
        // FIXME: We should be able to damage the last line only.
        var ancestor: RenderBlockWrapper? = rootForLastFormattedLine
        while ancestor != nil && CPtrToInt(ancestor!.p) != CPtrToInt(p) {
          ancestor!.setNeedsLayout(markParents: .MarkOnlyThis)
          ancestor = ancestor!.containingBlock()
        }

        let _ = TextBoxTrimmer(
          blockContainer: self, lastFormattedLineRoot: rootForLastFormattedLine)
        layoutBlockChildren(relayoutChildren: false, maxFloatLogicalBottom: &maxFloatLogicalBottom)
      }
    }
  }

  private func layoutBlockChildren(relayoutChildren: Bool, maxFloatLogicalBottom: inout LayoutUnit)
  {
    assert(firstChild() != nil)

    let beforeEdge = borderAndPaddingBefore()
    let afterEdge = borderAndPaddingAfter() + scrollbarLogicalHeight()

    setLogicalHeight(size: beforeEdge)
    let layoutState = view().frameView().layoutContext().layoutState()

    // The margin struct caches all our current margin collapsing state.
    var marginInfo = MarginInfo(
      block: self, beforeBorderPadding: beforeEdge, afterBorderPadding: afterEdge)

    let hasMarginTrimState = updateMarginTrimStateIfNeeded(
      layoutState: layoutState!, marginInfo: marginInfo)

    // Fieldsets need to find their legend and position it inside the border of the object.
    // The legend then gets skipped during normal layout. The same is true for ruby text.
    // It doesn't get included in the normal layout process but is instead skipped.
    layoutExcludedChildren(relayoutChildren: relayoutChildren)

    var previousFloatLogicalBottom = LayoutUnit()
    maxFloatLogicalBottom = LayoutUnit(value: 0)

    var next = firstChildBox()

    while next != nil {
      let child = next!
      next = child.nextSiblingBox()

      if child.isExcludedFromNormalLayout() {
        continue  // Skip this child, since it will be positioned by the specialized subclass (fieldsets and ruby runs).
      }

      if child.isSkippedContentForLayout() {
        child.clearNeedsLayoutForSkippedContent()
        continue
      }

      updateBlockChildDirtyBitsBeforeLayout(relayoutChildren: relayoutChildren, child: child)

      if child.isOutOfFlowPositioned() {
        child.containingBlock()!.insertPositionedObject(positioned: child)
        adjustPositionedBlock(child: child, marginInfo: marginInfo)
        continue
      }
      if child.isFloating() {
        RenderBlockFlowWrapper.markSiblingsIfIntrudingForLayout(child: child)
        insertFloatingObject(floatBox: child)
        adjustFloatingBlock(marginInfo: marginInfo)
        continue
      }

      // Lay out the child.
      layoutBlockChild(
        child: child, marginInfo: &marginInfo,
        previousFloatLogicalBottom: &previousFloatLogicalBottom,
        maxFloatLogicalBottom: &maxFloatLogicalBottom)
    }

    if style().marginTrim().contains(.BlockEnd) {
      trimBlockEndChildrenMargins()
    }
    // Now do the handling of the bottom of the block, adding in our bottom border/padding and
    // determining the correct collapsed bottom margin information.
    handleAfterSideOfBlock(beforeSide: beforeEdge, afterSide: afterEdge, marginInfo: &marginInfo)
    if hasMarginTrimState {
      layoutState!.popBlockStartTrimming()
    }
  }

  private static func markSiblingsIfIntrudingForLayout(child: RenderBoxWrapper) {
    // Let's find out if this float box is (was) intruding to sibling boxes and mark them for layout accordingly.
    if !child.selfNeedsLayout() || !child.everHadLayout() {
      // At this point floatingObjectSet() is purged, we can't check whether
      // this is a new or an existing float in this block container.
      return
    }
    var nextSibling = child.nextSibling()
    while nextSibling != nil {
      let block = nextSibling as? RenderBlockFlowWrapper
      if block == nil {
        nextSibling = nextSibling!.nextSibling()
        continue
      }
      if block!.avoidsFloats() && !block!.shrinkToAvoidFloats() {
        nextSibling = nextSibling!.nextSibling()
        continue
      }
      if block!.containsFloat(renderer: child) {
        block!.markAllDescendantsWithFloatsForLayout()
      }
      nextSibling = nextSibling!.nextSibling()
    }
  }

  private func updateMarginTrimStateIfNeeded(
    layoutState: RenderLayoutStateWrapper, marginInfo: MarginInfo
  ) -> Bool {
    let containingBlockTrimmingState = layoutState.blockStartTrimming()
    if style().marginTrim().contains(.BlockStart) {
      layoutState.pushBlockStartTrimming(blockStartTrimming: true)
    } else if !marginInfo.canCollapseMarginBeforeWithChildren()
      && containingBlockTrimmingState != nil
    {
      layoutState.pushBlockStartTrimming(blockStartTrimming: false)
    } else if marginInfo.canCollapseMarginBeforeWithChildren(),
      let containingBlockTrimmingState = containingBlockTrimmingState
    {
      layoutState.pushBlockStartTrimming(blockStartTrimming: containingBlockTrimmingState)
    } else {
      return false
    }
    return true
  }

  func layoutInlineChildren(
    relayoutChildren: Bool, repaintLogicalTop: inout LayoutUnit,
    repaintLogicalBottom: inout LayoutUnit
  ) {
    computeAndSetLineLayoutPath()

    if lineLayoutPath() == .InlinePath {
      (repaintLogicalTop, repaintLogicalBottom) = layoutInlineContent(
        relayoutChildren: relayoutChildren)
      return
    }

    if svgTextLayout() == nil {
      lineLayout = LineLayout.Legacy(LegacyLineLayout(flow: self))
    }

    svgTextLayout()!.layoutLineBoxes()
    previousInlineLayoutContentBoxLogicalHeight = nil
  }

  override func simplifiedNormalFlowLayout() {
    if !childrenInline() {
      super.simplifiedNormalFlowLayout()
      return
    }

    var shouldUpdateOverflow = false
    let walker = InlineWalker(root: self)
    while !walker.atEnd() {
      let renderer = walker.current()!
      if !renderer.isOutOfFlowPositioned()
        && (renderer.isReplacedOrInlineBlock() || renderer.isFloating())
      {
        let box = renderer as! RenderBoxWrapper
        box.layoutIfNeeded()
        shouldUpdateOverflow = true
      } else if renderer is RenderTextWrapper || renderer is RenderInlineWrapper {
        renderer.clearNeedsLayout()
      }
      walker.advance()
    }

    if !shouldUpdateOverflow {
      return
    }

    if let lineLayout = inlineLayout() {
      lineLayout.updateOverflow()
    }
  }

  private func shiftForAlignContent(
    intrinsicLogicalHeight: LayoutUnit, repaintLogicalTop: inout LayoutUnit,
    repaintLogicalBottom: inout LayoutUnit
  ) -> LayoutUnit {
    let alignment = style().alignContent()

    // Exit if no alignment necessary.
    if alignment.isNormal() || alignment.isStartward() {
      return LayoutUnit(value: UInt64(0))
    }

    // Calculate alignment shift.
    let computedLogicalHeight = logicalHeight()
    var space = computedLogicalHeight - intrinsicLogicalHeight
    if space <= Int32(0) {
      let overflowIsSafe =
        (alignment.overflow == .Default && !isScrollContainerY())
        || alignment.overflow == .Safe
        || alignment.position == .Normal
      if overflowIsSafe {
        return LayoutUnit(value: UInt64(0))  // Floored at zero; we're done
      }
    }
    if alignment.isCentered() {
      space = space / 2
    }

    // Alright, now shift all our content.
    if !childrenInline() {
      var child = firstChildBox()
      while child != nil {
        setLogicalTopForChild(child: child!, logicalTop: logicalTopForChild(child: child!) + space)
        if child!.isOutOfFlowPositioned() {
          if child!.style().hasStaticBlockPosition(horizontal: isHorizontalWritingMode()) {
            assert(child!.layer() != nil)
            child!.layer()!.setStaticBlockPosition(
              position: child!.layer()!.staticBlockPosition() + space)
            child!.setChildNeedsLayout(markParents: .MarkOnlyThis)
          }
        }
        child = child!.nextSiblingBox()
      }
    } else if svgTextLayout() != nil {
      if isHorizontalWritingMode() {
        svgTextLayout()!.lineBoxes.shiftLinesBy(shiftX: LayoutUnit(value: 0), shiftY: space)
      } else {
        svgTextLayout()!.lineBoxes.shiftLinesBy(shiftX: -space, shiftY: LayoutUnit(value: 0))
      }
    } else if inlineLayout() != nil {
      inlineLayout()!.shiftLinesBy(blockShift: space)
    }
    if floatingObjects != nil {
      floatingObjects!.shiftFloatsBy(blockShift: space)
    }

    // Update repaint region.
    if space < LayoutUnit(value: UInt64(0)) {
      repaintLogicalTop += space
    } else {
      repaintLogicalBottom += space
    }

    return space
  }

  override func collapsedMarginAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paintColumnRules(paintInfo: PaintInfoWrapper, point: LayoutPointWrapper) {
    super.paintColumnRules(paintInfo: paintInfo, point: point)

    if multiColumnFlowForBlockFlow() == nil || paintInfo.context().paintingDisabled() {
      return
    }

    // Iterate over our children and paint the column rules as needed.
    for columnSet: RenderMultiColumnSetWrapper in childrenOfType(parent: self) {
      let childPoint =
        columnSet.location() + flipForWritingModeForChild(child: columnSet, point: point)
      columnSet.paintColumnRules(paintInfo: paintInfo, point: childPoint)
    }
  }

  private func marginValuesForChild(child: RenderBoxWrapper) -> MarginValues {
    var childBeforePositive = LayoutUnit()
    var childBeforeNegative = LayoutUnit()
    var childAfterPositive = LayoutUnit()
    var childAfterNegative = LayoutUnit()

    var beforeMargin = LayoutUnit()
    var afterMargin = LayoutUnit()

    let childRenderBlock = child as? RenderBlockFlowWrapper

    // If the child has the same directionality as we do, then we can just return its
    // margins in the same direction.
    if !child.isWritingModeRoot() {
      if childRenderBlock != nil {
        childBeforePositive = childRenderBlock!.maxPositiveMarginBefore()
        childBeforeNegative = childRenderBlock!.maxNegativeMarginBefore()
        childAfterPositive = childRenderBlock!.maxPositiveMarginAfter()
        childAfterNegative = childRenderBlock!.maxNegativeMarginAfter()
      } else {
        beforeMargin = child.marginBefore()
        afterMargin = child.marginAfter()
      }
    } else if child.isHorizontalWritingMode() == isHorizontalWritingMode() {
      // The child has a different directionality. If the child is parallel, then it's just
      // flipped relative to us. We can use the margins for the opposite edges.
      if childRenderBlock != nil {
        childBeforePositive = childRenderBlock!.maxPositiveMarginAfter()
        childBeforeNegative = childRenderBlock!.maxNegativeMarginAfter()
        childAfterPositive = childRenderBlock!.maxPositiveMarginBefore()
        childAfterNegative = childRenderBlock!.maxNegativeMarginBefore()
      } else {
        beforeMargin = child.marginAfter()
        afterMargin = child.marginBefore()
      }
    } else {
      // The child is perpendicular to us, which means its margins don't collapse but are on the
      // "logical left/right" sides of the child box. We can just return the raw margin in this case.
      beforeMargin = marginBeforeForChild(child: child)
      afterMargin = marginAfterForChild(child: child)
    }

    // Resolve uncollapsing margins into their positive/negative buckets.
    if beforeMargin.bool() {
      if beforeMargin > 0 {
        childBeforePositive = beforeMargin
      } else {
        childBeforeNegative = -beforeMargin
      }
    }
    if afterMargin.bool() {
      if afterMargin > 0 {
        childAfterPositive = afterMargin
      } else {
        childAfterNegative = -afterMargin
      }
    }

    return MarginValues(
      beforePos: childBeforePositive, beforeNeg: childBeforeNegative, afterPos: childAfterPositive,
      afterNeg: childAfterNegative)
  }

  struct MarginInfo {
    // Our MarginInfo state used when laying out block children.
    init(
      block: RenderBlockFlowWrapper, beforeBorderPadding: LayoutUnit, afterBorderPadding: LayoutUnit
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    mutating func clearMargin() {
      positiveMargin = LayoutUnit(value: 0)
      negativeMargin = LayoutUnit(value: 0)
    }

    mutating func setPositiveMarginIfLarger(p: LayoutUnit) {
      if p > positiveMargin {
        positiveMargin = p
      }
    }

    mutating func setNegativeMarginIfLarger(n: LayoutUnit) {
      if n > negativeMargin {
        negativeMargin = n
      }
    }

    mutating func setMargin(p: LayoutUnit, n: LayoutUnit) {
      positiveMargin = p
      negativeMargin = n
    }

    func canCollapseWithMarginBefore() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func canCollapseWithMarginAfter() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func canCollapseMarginBeforeWithChildren() -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func margin() -> LayoutUnit { return positiveMargin - negativeMargin }

    // Collapsing flags for whether we can collapse our margins with our children's margins.
    var canCollapseMarginAfterWithChildren = false

    // Whether or not we are a quirky container, i.e., do we collapse away top and bottom
    // margins in our container. Table cells and the body are the common examples. We
    // also have a custom style property for Safari RSS to deal with TypePad blog articles.
    let quirkContainer = false

    // This flag tracks whether we are still looking at child margins that can all collapse together at the beginning of a block.
    // They may or may not collapse with the top margin of the block (|m_canCollapseTopWithChildren| tells us that), but they will
    // always be collapsing with one another. This variable can remain set to true through multiple iterations
    // as long as we keep encountering self-collapsing blocks.
    var atBeforeSideOfBlock = false

    // This flag is set when we know we're examining bottom margins and we know we're at the bottom of the block.
    var atAfterSideOfBlock = false

    // These variables are used to detect quirky margins that we need to collapse away (in table cells
    // and in the body element).
    var determinedMarginBeforeQuirk = false

    // These variables are used to detect quirky margins that we need to collapse away (in table cells
    // and in the body element).
    var hasMarginBeforeQuirk = false
    var hasMarginAfterQuirk = false

    // These flags track the previous maximal positive and negative margins.
    var positiveMargin: LayoutUnit
    var negativeMargin: LayoutUnit
  }

  private func layoutBlockChild(
    child: RenderBoxWrapper, marginInfo: inout MarginInfo,
    previousFloatLogicalBottom: inout LayoutUnit, maxFloatLogicalBottom: inout LayoutUnit
  ) {
    let oldPosMarginBefore = maxPositiveMarginBefore()
    let oldNegMarginBefore = maxNegativeMarginBefore()

    // The child is a normal flow object. Compute the margins we will use for collapsing now.
    child.computeAndSetBlockDirectionMargins(containingBlock: self)

    // Try to guess our correct logical top position. In most cases this guess will
    // be correct. Only if we're wrong (when we compute the real logical top position)
    // will we have to potentially relayout.
    let estimatedLogicalTopPosition = estimateLogicalTopPosition(
      child: child, marginInfo: marginInfo)
    let logicalTopEstimate = estimatedLogicalTopPosition.logicalTopEstimate
    let estimateWithoutPagination = estimatedLogicalTopPosition.estimateWithoutPagination

    // Cache our old rect so that we can dirty the proper repaint rects if the child moves.
    let oldRect = child.frameRect()
    let oldLogicalTop = logicalTopForChild(child: child)
    #if ASSERT_ENABLED
      let oldLayoutDelta = view().frameView().layoutContext().layoutDelta()
    #endif
    // Position the child as though it didn't collapse with the top.
    setLogicalTopForChild(
      child: child, logicalTop: logicalTopEstimate, applyDelta: .ApplyLayoutDelta)
    estimateFragmentRangeForBoxChild(box: child)

    let childBlockFlow = child as? RenderBlockFlowWrapper
    var markDescendantsWithFloats = false
    if logicalTopEstimate != oldLogicalTop && !child.avoidsFloats() && childBlockFlow != nil
      && childBlockFlow!.containsFloats()
    {
      markDescendantsWithFloats = true
    } else if logicalTopEstimate.mightBeSaturated() {
      // logicalTopEstimate, returned by estimateLogicalTopPosition, might be saturated for
      // very large elements. If it does the comparison with oldLogicalTop might yield a
      // false negative as adding and removing margins, borders etc from a saturated number
      // might yield incorrect results. If this is the case always mark for layout.
      markDescendantsWithFloats = true
    } else if !child.avoidsFloats() || child.shrinkToAvoidFloats() {
      // If an element might be affected by the presence of floats, then always mark it for
      // layout.
      let fb = max(previousFloatLogicalBottom, lowestFloatLogicalBottom())
      if fb > logicalTopEstimate {
        markDescendantsWithFloats = true
      }
    }

    if let childBlockFlow = childBlockFlow {
      if markDescendantsWithFloats {
        childBlockFlow.markAllDescendantsWithFloatsForLayout()
      }
      if !child.isWritingModeRoot() {
        previousFloatLogicalBottom = max(
          previousFloatLogicalBottom, oldLogicalTop + childBlockFlow.lowestFloatLogicalBottom())
      }
    }

    child.markForPaginationRelayoutIfNeeded()

    let childHadLayout = child.everHadLayout()
    let childNeededLayout = child.needsLayout()
    if childNeededLayout {
      child.layout()
    }

    // Cache if we are at the top of the block right now.
    let atBeforeSideOfBlock = marginInfo.atBeforeSideOfBlock

    // Now determine the correct ypos based off examination of collapsing margin
    // values.
    let logicalTopBeforeClear = collapseMargins(child: child, marginInfo: &marginInfo)

    // Now check for clear.
    var logicalTopAfterClear = clearFloatsIfNeeded(
      child: child, marginInfo: &marginInfo, oldTopPosMargin: oldPosMarginBefore,
      oldTopNegMargin: oldNegMarginBefore, yPos: logicalTopBeforeClear)

    let paginated = view().frameView().layoutContext().layoutState()!.isPaginated()
    if paginated {
      logicalTopAfterClear = adjustBlockChildForPagination(
        logicalTopAfterClear: logicalTopAfterClear,
        estimateWithoutPagination: estimateWithoutPagination, child: child,
        atBeforeSideOfBlock: atBeforeSideOfBlock && logicalTopBeforeClear == logicalTopAfterClear)
    }

    setLogicalTopForChild(
      child: child, logicalTop: logicalTopAfterClear, applyDelta: .ApplyLayoutDelta)

    // Now we have a final top position. See if it really does end up being different from our estimate.
    // clearFloatsIfNeeded can also mark the child as needing a layout even though we didn't move. This happens
    // when collapseMargins dynamically adds overhanging floats because of a child with negative margins.
    if logicalTopAfterClear != logicalTopEstimate || child.needsLayout()
      || (paginated && childBlockFlow != nil && childBlockFlow!.shouldBreakAtLineToAvoidWidow())
    {
      if child.shrinkToAvoidFloats() {
        // The child's width depends on the line width. When the child shifts to clear an item, its width can
        // change (because it has more available line width). So mark the item as dirty.
        child.setChildNeedsLayout(markParents: .MarkOnlyThis)
      }

      if let childBlockFlow = childBlockFlow {
        if !child.avoidsFloats() && childBlockFlow.containsFloats() {
          childBlockFlow.markAllDescendantsWithFloatsForLayout()
        }
        child.markForPaginationRelayoutIfNeeded()
      }
    }

    if updateFragmentRangeForBoxChild(box: child) {
      child.setNeedsLayout(markParents: .MarkOnlyThis)
    }

    // In case our guess was wrong, relayout the child.
    child.layoutIfNeeded()

    // We are no longer at the top of the block if we encounter a non-empty child.
    // This has to be done after checking for clear, so that margins can be reset if a clear occurred.
    if marginInfo.atBeforeSideOfBlock && !child.isSelfCollapsingBlock() {
      marginInfo.atBeforeSideOfBlock = false

      if let layoutState = frame().view()!.layoutContext().layoutState(),
        layoutState.blockStartTrimming() != nil
      {
        layoutState.popBlockStartTrimming()
        layoutState.pushBlockStartTrimming(blockStartTrimming: false)
      }
    }
    // Now place the child in the correct left position
    determineLogicalLeftPositionForChild(child: child, applyDelta: .ApplyLayoutDelta)

    // Update our height now that the child has been placed in the correct position.
    setLogicalHeight(size: logicalHeight() + logicalHeightForChildForFragmentation(child: child))

    // If the child has overhanging floats that intrude into following siblings (or possibly out
    // of this block), then the parent gets notified of the floats now.
    if let childBlockFlow = childBlockFlow, childBlockFlow.containsFloats() {
      maxFloatLogicalBottom = max(
        maxFloatLogicalBottom,
        addOverhangingFloats(child: childBlockFlow, makeChildPaintOtherFloats: !childNeededLayout))
    }

    let childOffset = child.location() - oldRect.location()
    if childOffset.width().bool() || childOffset.height().bool() {
      view().frameView().layoutContext().addLayoutDelta(delta: childOffset)

      // If the child moved, we have to repaint it as well as any floating/positioned
      // descendants. An exception is if we need a layout. In this case, we know we're going to
      // repaint ourselves (and the child) anyway.
      if childHadLayout && !selfNeedsLayout() && child.checkForRepaintDuringLayout() {
        child.repaintDuringLayoutIfMoved(oldRect: oldRect)
      }
    }

    if !childHadLayout && child.checkForRepaintDuringLayout() {
      child.repaint()
      child.repaintOverhangingFloats(paintAllDescendants: true)
    }

    if paginated {
      if let fragmentedFlow = enclosingFragmentedFlow() {
        fragmentedFlow.fragmentedFlowDescendantBoxLaidOut(descendant: child)
      }
      // Check for an after page/column break.
      let newHeight = applyAfterBreak(
        child: child, logicalOffset: logicalHeight(), marginInfo: &marginInfo)
      if newHeight != height() {
        setLogicalHeight(size: newHeight)
      }
    }

    #if ASSERT_ENABLED
      assert(view().frameView().layoutContext().layoutDeltaMatches(delta: oldLayoutDelta))
    #endif
  }

  private func adjustPositionedBlock(child: RenderBoxWrapper, marginInfo: MarginInfo) {
    let isHorizontal = isHorizontalWritingMode()
    let hasStaticBlockPosition = child.style().hasStaticBlockPosition(horizontal: isHorizontal)

    var logicalTop = logicalHeight()
    updateStaticInlinePositionForChild(child: child, logicalTop: logicalTop)

    if !marginInfo.canCollapseWithMarginBefore() {
      // Positioned blocks don't collapse margins, so add the margin provided by
      // the container now. The child's own margin is added later when calculating its logical top.
      let collapsedBeforePos = marginInfo.positiveMargin
      let collapsedBeforeNeg = marginInfo.negativeMargin
      logicalTop += collapsedBeforePos - collapsedBeforeNeg
    }

    let childLayer = child.layer()!
    if childLayer.staticBlockPosition() != logicalTop {
      childLayer.setStaticBlockPosition(position: logicalTop)
      if hasStaticBlockPosition {
        child.setChildNeedsLayout(markParents: .MarkOnlyThis)
      }
    }
  }

  private func adjustFloatingBlock(marginInfo: MarginInfo) {
    // The float should be positioned taking into account the bottom margin
    // of the previous flow. We add that margin into the height, get the
    // float positioned properly, and then subtract the margin out of the
    // height again. In the case of self-collapsing blocks, we always just
    // use the top margins, since the self-collapsing block collapsed its
    // own bottom margin into its top margin.
    //
    // Note also that the previous flow may collapse its margin into the top of
    // our block. If this is the case, then we do not add the margin in to our
    // height when computing the position of the float. This condition can be tested
    // for by simply calling canCollapseWithMarginBefore. See
    // http://www.hixie.ch/tests/adhoc/css/box/block/margin-collapse/046.html for
    // an example of this scenario.
    let marginOffset =
      marginInfo.canCollapseWithMarginBefore() ? LayoutUnit(value: UInt64(0)) : marginInfo.margin()
    setLogicalHeight(size: logicalHeight() + marginOffset)
    positionNewFloats()
    setLogicalHeight(size: logicalHeight() - marginOffset)
  }

  private func trimBlockEndChildrenMargins() {
    assert(style().marginTrim().contains(.BlockEnd))
    // If we are trimming the block end margin, we need to make sure we trim the margin of the children
    // at the end of the block by walking back up the container. Any self collapsing children will also need to
    // have their position adjusted to below the last non self-collapsing child in its containing block
    var child = lastChildBox()
    while child != nil {
      if child!.isExcludedFromNormalLayout() || !child!.isInFlow() {
        child = child!.previousSiblingBox()
        continue
      }

      let childContainingBlock = child!.containingBlock()
      setTrimmedMarginForChild(child: child!, marginTrimType: .BlockEnd)
      if child!.isSelfCollapsingBlock() {
        setTrimmedMarginForChild(child: child!, marginTrimType: .BlockStart)
        childContainingBlock!.setLogicalTopForChild(
          child: child!, logicalTop: childContainingBlock!.logicalHeight())

        // If this self-collapsing child has any other children, which must also be
        // self-collapsing, we should trim the margins of all its descendants
        if child!.firstChildBox() != nil && !child!.childrenInline() {
          trimSelfCollapsingChildDescendants(child: child!)
        }

        child = child!.previousSiblingBox()
      } else if let nestedBlock = child as? RenderBlockFlowWrapper,
        nestedBlock.isBlockContainer() && !nestedBlock.childrenInline()
          && !nestedBlock.style().marginTrim().contains(.BlockEnd)
      {
        let nestedBlockMarginInfo = MarginInfo(
          block: nestedBlock, beforeBorderPadding: nestedBlock.borderAndPaddingBefore(),
          afterBorderPadding: nestedBlock.borderAndPaddingAfter())
        // The margins *inside* this nested block are protected so we should not introspect and try to
        // trim any of them.
        if !nestedBlockMarginInfo.canCollapseMarginAfterWithChildren {
          break
        }

        child = child!.lastChildBox()
      } else {
        // We hit another type of block child that doesn't apply to our search. We can just
        // end the search since nothing before this block can affect the bottom margin of the outer one we are trimming for.
        break
      }
    }
  }

  private func trimSelfCollapsingChildDescendants(child: RenderBoxWrapper) {
    assert(child.isSelfCollapsingBlock())
    var itr = RenderIterator<RenderBoxWrapper>(root: child, current: child.firstChildBox())
    while itr.bool() {
      setTrimmedMarginForChild(child: *itr, marginTrimType: .BlockStart)
      setTrimmedMarginForChild(child: *itr, marginTrimType: .BlockEnd)
      itr = itr.traverseNext()
    }
  }

  func setStaticInlinePositionForChild(
    child: RenderBoxWrapper, blockOffset: LayoutUnit, inlinePosition: LayoutUnit
  ) {
    wk_interop.RenderBlockFlow_setStaticInlinePositionForChild(
      p, child.p, blockOffset.rawValue(), inlinePosition.rawValue())
  }

  private func updateStaticInlinePositionForChild(child: RenderBoxWrapper, logicalTop: LayoutUnit) {
    if child.style().isOriginalDisplayInlineType() {
      setStaticInlinePositionForChild(
        child: child, blockOffset: logicalTop,
        inlinePosition: staticInlinePositionForOriginalDisplayInline(logicalTop: logicalTop))
    } else {
      setStaticInlinePositionForChild(
        child: child, blockOffset: logicalTop,
        inlinePosition: startOffsetForContent(blockOffset: logicalTop))
    }
  }

  private func staticInlinePositionForOriginalDisplayInline(logicalTop: LayoutUnit) -> LayoutUnit {
    let textAlign = style().textAlign()
    let isLeftToRightDirection = style().isLeftToRightDirection()

    var logicalLeft = logicalLeftOffsetForLine(position: logicalTop).float()
    let logicalRight = logicalRightOffsetForLine(position: logicalTop).float()

    switch textAlign {
    case .Left, .WebKitLeft:
      break
    case .Right, .WebKitRight:
      logicalLeft = logicalRight
    case .Center, .WebKitCenter:
      logicalLeft += (logicalRight - logicalLeft) / 2
    case .Justify, .Start:
      if isLeftToRightDirection {
        logicalLeft = logicalRight
      }
    case .End:
      if isLeftToRightDirection {
        logicalLeft = logicalRight
      }
    }

    if !isLeftToRightDirection {
      return LayoutUnit(value: logicalWidth() - logicalLeft)
    }

    return LayoutUnit(value: logicalLeft)
  }

  func collapseMargins(child: RenderBoxWrapper, marginInfo: inout MarginInfo) -> LayoutUnit {
    return collapseMarginsWithChildInfo(
      child: child, prevSibling: child.previousSibling(), marginInfo: &marginInfo)
  }

  func collapseMarginsWithChildInfo(
    child: RenderBoxWrapper?, prevSibling: RenderObjectWrapper?, marginInfo: inout MarginInfo
  ) -> LayoutUnit {
    let childIsSelfCollapsing = child?.isSelfCollapsingBlock() ?? false
    let beforeQuirk = child != nil ? hasMarginBeforeQuirk(child: child!) : false
    let afterQuirk = child != nil ? hasMarginAfterQuirk(child: child!) : false
    if frame().view()!.layoutContext().layoutState()!.blockStartTrimming() ?? false {
      assert(marginInfo.atBeforeSideOfBlock)
      trimChildBlockMargins(child: child!, childIsSelfCollapsing: childIsSelfCollapsing)
    }

    // Get the four margin values for the child and cache them.
    let zero = LayoutUnit(value: 0)
    let childMargins =
      child != nil
      ? marginValuesForChild(child: child!)
      : MarginValues(beforePos: zero, beforeNeg: zero, afterPos: zero, afterNeg: zero)
    // Get our max pos and neg top margins.
    var posTop = childMargins.positiveMarginBefore
    var negTop = childMargins.negativeMarginBefore

    // For self-collapsing blocks, collapse our bottom margins into our
    // top to get new posTop and negTop values.
    if childIsSelfCollapsing {
      posTop = max(posTop, childMargins.positiveMarginAfter)
      negTop = max(negTop, childMargins.negativeMarginAfter)
    }

    if marginInfo.canCollapseWithMarginBefore() {
      // This child is collapsing with the top of the
      // block. If it has larger margin values, then we need to update
      // our own maximal values.
      if !document().inQuirksMode() || !marginInfo.quirkContainer || !beforeQuirk {
        setMaxMarginBeforeValues(
          pos: max(posTop, maxPositiveMarginBefore()), neg: max(negTop, maxNegativeMarginBefore()))
      }

      // The minute any of the margins involved isn't a quirk, don't
      // collapse it away, even if the margin is smaller (www.webreference.com
      // has an example of this, a <dt> with 0.8em author-specified inside
      // a <dl> inside a <td>.
      if !marginInfo.determinedMarginBeforeQuirk && !beforeQuirk && (posTop - negTop).bool() {
        setHasMarginBeforeQuirk(b: false)
        marginInfo.determinedMarginBeforeQuirk = true
      }

      if !marginInfo.determinedMarginBeforeQuirk && beforeQuirk && !marginBefore().bool() {
        // We have no top margin and our top child has a quirky margin.
        // We will pick up this quirky margin and pass it through.
        // This deals with the <td><div><p> case.
        // Don't do this for a block that split two inlines though. You do
        // still apply margins in this case.
        setHasMarginBeforeQuirk(b: true)
      }
    }

    if marginInfo.quirkContainer && marginInfo.atBeforeSideOfBlock && (posTop - negTop).bool() {
      marginInfo.hasMarginBeforeQuirk = beforeQuirk
    }

    let beforeCollapseLogicalTop = logicalHeight()
    var logicalTop = beforeCollapseLogicalTop
    // If the child's previous sibling is a self-collapsing block that cleared a float then its top border edge has been set at the bottom border edge
    // of the float. Since we want to collapse the child's top margin with the self-collapsing block's top and bottom margins we need to adjust our parent's height to match the
    // margin top of the self-collapsing block. If the resulting collapsed margin leaves the child still intruding into the float then we will want to clear it.
    if !marginInfo.canCollapseWithMarginBefore() {
      if let value = selfCollapsingMarginBeforeWithClear(candidate: child!.previousSibling()) {
        setLogicalHeight(size: logicalHeight() - value)
      }
    }

    if childIsSelfCollapsing {
      // This child has no height. We need to compute our
      // position before we collapse the child's margins together,
      // so that we can get an accurate position for the zero-height block.
      let collapsedBeforePos = max(marginInfo.positiveMargin, childMargins.positiveMarginBefore)
      let collapsedBeforeNeg = max(marginInfo.negativeMargin, childMargins.negativeMarginBefore)
      marginInfo.setMargin(p: collapsedBeforePos, n: collapsedBeforeNeg)

      // Now collapse the child's margins together, which means examining our
      // bottom margin values as well.
      marginInfo.setPositiveMarginIfLarger(p: childMargins.positiveMarginAfter)
      marginInfo.setNegativeMarginIfLarger(n: childMargins.negativeMarginAfter)

      if !marginInfo.canCollapseWithMarginBefore() {
        // We need to make sure that the position of the self-collapsing block
        // is correct, since it could have overflowing content
        // that needs to be positioned correctly (e.g., a block that
        // had a specified height of 0 but that actually had subcontent).
        logicalTop = logicalHeight() + collapsedBeforePos - collapsedBeforeNeg
      }
    } else {
      if !marginInfo.atBeforeSideOfBlock
        || (!marginInfo.canCollapseMarginBeforeWithChildren()
          && (!document().inQuirksMode() || !marginInfo.quirkContainer
            || !marginInfo.hasMarginBeforeQuirk))
      {
        // We're collapsing with a previous sibling's margins and not
        // with the top of the block.
        setLogicalHeight(
          size: logicalHeight() + max(marginInfo.positiveMargin, posTop)
            - max(marginInfo.negativeMargin, negTop))
        logicalTop = logicalHeight()
      }

      marginInfo.positiveMargin = childMargins.positiveMarginAfter
      marginInfo.negativeMargin = childMargins.negativeMarginAfter

      if marginInfo.margin().bool() {
        marginInfo.hasMarginAfterQuirk = afterQuirk
      }
    }

    // If margins would pull us past the top of the next page, then we need to pull back and pretend like the margins
    // collapsed into the page edge.
    let layoutState = view().frameView().layoutContext().layoutState()!
    if layoutState.isPaginated() && layoutState.pageLogicalHeight().bool()
      && logicalTop > beforeCollapseLogicalTop
      && hasNextPage(logicalOffset: beforeCollapseLogicalTop)
    {
      let oldLogicalTop = logicalTop
      logicalTop = min(logicalTop, nextPageLogicalTop(logicalOffset: beforeCollapseLogicalTop))
      setLogicalHeight(size: logicalHeight() + (logicalTop - oldLogicalTop))
    }

    if let block = prevSibling as? RenderBlockFlowWrapper,
      !prevSibling!.isFloatingOrOutOfFlowPositioned()
    {
      // If |child| is a self-collapsing block it may have collapsed into a previous sibling and although it hasn't reduced the height of the parent yet
      // any floats from the parent will now overhang.
      let oldLogicalHeight = logicalHeight()
      setLogicalHeight(size: logicalTop)
      if block.containsFloats() && !block.avoidsFloats()
        && (block.logicalTop() + block.lowestFloatLogicalBottom()) > logicalTop
      {
        addOverhangingFloats(child: block, makeChildPaintOtherFloats: false)
      }
      setLogicalHeight(size: oldLogicalHeight)

      // If |child|'s previous sibling is or contains a self-collapsing block that cleared a float and margin collapsing resulted in |child| moving up
      // into the margin area of the self-collapsing block then the float it clears is now intruding into |child|. Layout again so that we can look for
      // floats in the parent that overhang |child|'s new logical top.
      let logicalTopIntrudesIntoFloat = logicalTop < beforeCollapseLogicalTop
      if child != nil && logicalTopIntrudesIntoFloat && containsFloats() && !child!.avoidsFloats()
        && lowestFloatLogicalBottom() > logicalTop
      {
        child!.setNeedsLayout()
      }
    }

    return logicalTop
  }

  private func trimChildBlockMargins(child: RenderBoxWrapper, childIsSelfCollapsing: Bool) {
    let childBlockFlow = child as? RenderBlockFlowWrapper
    let zero = LayoutUnit(value: UInt64(0))
    if childBlockFlow != nil {
      childBlockFlow!.setMaxMarginBeforeValues(pos: zero, neg: zero)
    }
    setTrimmedMarginForChild(child: child, marginTrimType: .BlockStart)

    // The margin after for a self collapsing child should also be trimmed so it does not
    // influence the margins of the first non collapsing child
    if childIsSelfCollapsing {
      if childBlockFlow != nil {
        childBlockFlow!.setMaxMarginAfterValues(pos: zero, neg: zero)
      }
      setTrimmedMarginForChild(child: child, marginTrimType: .BlockEnd)
    }
  }

  func clearFloatsIfNeeded(
    child: RenderBoxWrapper, marginInfo: inout MarginInfo, oldTopPosMargin: LayoutUnit,
    oldTopNegMargin: LayoutUnit, yPos: LayoutUnit
  ) -> LayoutUnit {
    let heightIncrease = getClearDelta(child: child, logicalTop: yPos)
    if !heightIncrease.bool() {
      return yPos
    }

    if child.isSelfCollapsingBlock() {
      // For self-collapsing blocks that clear, they can still collapse their
      // margins with following siblings. Reset the current margins to represent
      // the self-collapsing block's margins only.
      let childMargins = marginValuesForChild(child: child)
      marginInfo.positiveMargin = max(
        childMargins.positiveMarginBefore, childMargins.positiveMarginAfter)
      marginInfo.negativeMargin = max(
        childMargins.negativeMarginBefore, childMargins.negativeMarginAfter)

      // CSS2.1 states:
      // "If the top and bottom margins of an element with clearance are adjoining, its margins collapse with
      // the adjoining margins of following siblings but that resulting margin does not collapse with the bottom margin of the parent block."
      // So the parent's bottom margin cannot collapse through this block or any subsequent self-collapsing blocks. Check subsequent siblings
      // for a block with height - if none is found then don't allow the margins to collapse with the parent.
      var wouldCollapseMarginsWithParent = marginInfo.canCollapseMarginAfterWithChildren
      var curr = child.nextSiblingBox()
      while curr != nil && wouldCollapseMarginsWithParent {
        if !curr!.isFloatingOrOutOfFlowPositioned() && !curr!.isSelfCollapsingBlock() {
          wouldCollapseMarginsWithParent = false
        }
        curr = curr!.nextSiblingBox()
      }
      if wouldCollapseMarginsWithParent {
        marginInfo.canCollapseMarginAfterWithChildren = false
      }

      // For now set the border-top of |child| flush with the bottom border-edge of the float so it can layout any floating or positioned children of
      // its own at the correct vertical position. If subsequent siblings attempt to collapse with |child|'s margins in |collapseMargins| we will
      // adjust the height of the parent to |child|'s margin top (which if it is positive sits up 'inside' the float it's clearing) so that all three
      // margins can collapse at the correct vertical position.
      // Per CSS2.1 we need to ensure that any negative margin-top clears |child| beyond the bottom border-edge of the float so that the top border edge of the child
      // (i.e. its clearance)  is at a position that satisfies the equation: "the amount of clearance is set so that clearance + margin-top = [height of float],
      // i.e., clearance = [height of float] - margin-top".
      setLogicalHeight(size: child.logicalTop() + childMargins.negativeMarginBefore)
    } else {
      // Increase our height by the amount we had to clear.
      setLogicalHeight(size: logicalHeight() + heightIncrease)
    }

    if marginInfo.canCollapseWithMarginBefore() {
      // We can no longer collapse with the top of the block since a clear
      // occurred. The empty blocks collapse into the cleared block.
      // https://www.w3.org/TR/CSS2/visuren.html#clearance
      // "CSS2.1 - Computing the clearance of an element on which 'clear' is set is done..."
      setMaxMarginBeforeValues(pos: oldTopPosMargin, neg: oldTopNegMargin)
      marginInfo.atBeforeSideOfBlock = false
    }

    return yPos + heightIncrease
  }

  private struct EstimatedLogicalTopPosition {
    let logicalTopEstimate: LayoutUnit
    let estimateWithoutPagination: LayoutUnit
  }

  private func estimateLogicalTopPosition(child: RenderBoxWrapper, marginInfo: MarginInfo)
    -> EstimatedLogicalTopPosition
  {
    // FIXME: We need to eliminate the estimation of vertical position, because when it's wrong we sometimes trigger a pathological
    // relayout if there are intruding floats.
    var logicalTopEstimate = logicalHeight()
    if !marginInfo.canCollapseWithMarginBefore() {
      var positiveMarginBefore = LayoutUnit()
      var negativeMarginBefore = LayoutUnit()
      if child.selfNeedsLayout() {
        // Try to do a basic estimation of how the collapse is going to go.
        marginBeforeEstimateForChild(
          child: child, positiveMarginBefore: &positiveMarginBefore,
          negativeMarginBefore: &negativeMarginBefore)
      } else {
        // Use the cached collapsed margin values from a previous layout. Most of the time they
        // will be right.
        let marginValues = marginValuesForChild(child: child)
        positiveMarginBefore = max(positiveMarginBefore, marginValues.positiveMarginBefore)
        negativeMarginBefore = max(negativeMarginBefore, marginValues.negativeMarginBefore)
      }

      // Collapse the result with our current margins.
      logicalTopEstimate +=
        max(marginInfo.positiveMargin, positiveMarginBefore)
        - max(marginInfo.negativeMargin, negativeMarginBefore)
    }

    // Adjust logicalTopEstimate down to the next page if the margins are so large that we don't fit on the current
    // page.
    let layoutState = view().frameView().layoutContext().layoutState()!
    if layoutState.isPaginated() && layoutState.pageLogicalHeight().bool()
      && logicalTopEstimate > logicalHeight()
      && hasNextPage(logicalOffset: logicalHeight())
    {
      logicalTopEstimate = min(
        logicalTopEstimate, nextPageLogicalTop(logicalOffset: logicalHeight()))
    }

    logicalTopEstimate += getClearDelta(child: child, logicalTop: logicalTopEstimate)

    let estimateWithoutPagination = logicalTopEstimate

    if layoutState.isPaginated() {
      // If the object has a page or column break value of "before", then we should shift to the top of the next page.
      logicalTopEstimate = applyBeforeBreak(child: child, logicalOffset: logicalTopEstimate)

      // For replaced elements and scrolled elements, we want to shift them to the next page if they don't fit on the current one.
      logicalTopEstimate = adjustForUnsplittableChild(
        child: child, logicalOffset: logicalTopEstimate)

      if !child.selfNeedsLayout(), let block = child as? RenderBlockWrapper {
        logicalTopEstimate += block.paginationStrut()
      }
    }

    return EstimatedLogicalTopPosition(
      logicalTopEstimate: logicalTopEstimate, estimateWithoutPagination: estimateWithoutPagination)
  }

  private func marginBeforeEstimateForChild(
    child: RenderBoxWrapper, positiveMarginBefore: inout LayoutUnit,
    negativeMarginBefore: inout LayoutUnit
  ) {
    // Give up if in quirks mode and we're a body/table cell and the top margin of the child box is quirky.
    // Give up if the child specified -webkit-margin-collapse: separate that prevents collapsing.
    if document().inQuirksMode() && hasMarginBeforeQuirk(child: child)
      && (isRenderTableCell() || isBody())
    {
      return
    }

    let beforeChildMargin = marginBeforeForChild(child: child)
    positiveMarginBefore = max(positiveMarginBefore, beforeChildMargin)
    negativeMarginBefore = max(negativeMarginBefore, -beforeChildMargin)

    let childBlock = child as? RenderBlockFlowWrapper
    if childBlock == nil {
      return
    }

    if childBlock!.childrenInline() || childBlock!.isWritingModeRoot() {
      return
    }

    let childMarginInfo = MarginInfo(
      block: childBlock!, beforeBorderPadding: childBlock!.borderAndPaddingBefore(),
      afterBorderPadding: childBlock!.borderAndPaddingAfter())
    if !childMarginInfo.canCollapseMarginBeforeWithChildren() {
      return
    }

    var grandchildBox = childBlock!.firstChildBox()
    while grandchildBox != nil {
      if !grandchildBox!.isFloatingOrOutOfFlowPositioned() {
        break
      }
      grandchildBox = grandchildBox!.nextSiblingBox()
    }

    if grandchildBox == nil {
      return
    }

    // Make sure to update the block margins now for the grandchild box so that we're looking at current values.
    if grandchildBox!.needsLayout() {
      grandchildBox!.computeAndSetBlockDirectionMargins(containingBlock: self)
      if let grandchildBlock = grandchildBox as? RenderBlockWrapper {
        grandchildBlock.setHasMarginBeforeQuirk(b: grandchildBox!.style().marginBefore().hasQuirk())
        grandchildBlock.setHasMarginAfterQuirk(b: grandchildBox!.style().marginAfter().hasQuirk())
      }
    }

    // If we have a 'clear' value but also have a margin we may not actually require clearance to move past any floats.
    // If that's the case we want to be sure we estimate the correct position including margins after any floats rather
    // than use 'clearance' later which could give us the wrong position.
    if RenderStyleWrapper.usedClear(renderer: grandchildBox!) != .None
      && !childBlock!.marginBeforeForChild(child: grandchildBox!).bool()
    {
      return
    }

    // Collapse the margin of the grandchild box with our own to produce an estimate.
    childBlock!.marginBeforeEstimateForChild(
      child: grandchildBox!, positiveMarginBefore: &positiveMarginBefore,
      negativeMarginBefore: &negativeMarginBefore)
  }

  private func handleAfterSideOfBlock(
    beforeSide: LayoutUnit, afterSide: LayoutUnit, marginInfo: inout MarginInfo
  ) {
    marginInfo.atAfterSideOfBlock = true

    // If our last child was a self-collapsing block with clearance then our logical height is flush with the
    // bottom edge of the float that the child clears. The correct vertical position for the margin-collapsing we want
    // to perform now is at the child's margin-top - so adjust our height to that position.
    if let value = selfCollapsingMarginBeforeWithClear(candidate: lastChild()) {
      setLogicalHeight(size: logicalHeight() - value)
    }

    // If we can't collapse with children then add in the bottom margin.
    if !marginInfo.canCollapseWithMarginAfter() && !marginInfo.canCollapseWithMarginBefore()
      && (!document().inQuirksMode() || !marginInfo.quirkContainer
        || !marginInfo.hasMarginAfterQuirk)
    {
      setLogicalHeight(size: logicalHeight() + marginInfo.margin())
    }

    // Now add in our bottom border/padding.
    setLogicalHeight(size: logicalHeight() + afterSide)

    // Negative margins can cause our height to shrink below our minimal height (border/padding).
    // If this happens, ensure that the computed height is increased to the minimal height.
    setLogicalHeight(size: max(logicalHeight(), beforeSide + afterSide))

    // Update our bottom collapsed margin info.
    setCollapsedBottomMargin(marginInfo: marginInfo)
  }

  private func setCollapsedBottomMargin(marginInfo: MarginInfo) {
    if !marginInfo.canCollapseWithMarginAfter() || marginInfo.canCollapseWithMarginBefore() {
      return
    }
    // Update our max pos/neg bottom margins, since we collapsed our bottom margins
    // with our children.
    let shouldTrimBlockEndMargin = style().marginTrim().contains(.BlockEnd)
    let zero = LayoutUnit(value: UInt64(0))
    let propagatedPositiveMargin = shouldTrimBlockEndMargin ? zero : marginInfo.positiveMargin
    let propagatedNegativeMargin = shouldTrimBlockEndMargin ? zero : marginInfo.negativeMargin
    setMaxMarginAfterValues(
      pos: max(maxPositiveMarginAfter(), propagatedPositiveMargin),
      neg: max(maxNegativeMarginAfter(), propagatedNegativeMargin))

    if !marginInfo.hasMarginAfterQuirk {
      setHasMarginAfterQuirk(b: false)
    }

    if marginInfo.hasMarginAfterQuirk && !marginAfter().bool() {
      // We have no bottom margin and our last child has a quirky margin.
      // We will pick up this quirky margin and pass it through.
      // This deals with the <td><div><p> case.
      setHasMarginAfterQuirk(b: true)
    }
  }

  override func childrenPreventSelfCollapsing() -> Bool {
    if !childrenInline() {
      return super.childrenPreventSelfCollapsing()
    }

    return hasLines()
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
    if containsFloats() {
      return true
    }

    for block: RenderBlockWrapper in descendantsOfType(root: self) {
      if let blockFlow = block as? RenderBlockFlowWrapper, blockFlow.containsFloats() {
        return true
      }
    }

    return false
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

  override func computeOverflow(oldClientAfterEdge: LayoutUnit, recomputeFloats: Bool = false) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func lowestFloatLogicalBottom(floatType: FloatingObjectWrapper.`Type` = .FloatLeftRight)
    -> LayoutUnit
  {
    if floatingObjects == nil {
      return LayoutUnit(value: 0)
    }
    var lowestFloatBottom = LayoutUnit()
    let floatingObjectSet = floatingObjects!.set()
    for floatingObject in floatingObjectSet {
      if floatingObject.isPlaced && floatingObject.type.rawValue & floatType.rawValue != 0 {
        lowestFloatBottom = max(
          lowestFloatBottom, logicalBottomForFloat(floatingObject: floatingObject))
      }
    }
    return lowestFloatBottom
  }

  func removeFloatingObjects() {
    if floatingObjects == nil {
      return
    }

    markSiblingsWithFloatsForLayout()

    floatingObjects!.clear()
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

  private func logicalTopForFloat(floatingObject: FloatingObjectWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func logicalBottomForFloat(floatingObject: FloatingObjectWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalWidthForFloat(_ floatingObject: FloatingObjectWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func setLogicalTopForFloat(
    _ floatingObject: FloatingObjectWrapper, logicalTop: LayoutUnit
  ) {
    if isHorizontalWritingMode() {
      floatingObject.setY(y: logicalTop)
    } else {
      floatingObject.setX(x: logicalTop)
    }
  }

  private func setLogicalLeftForFloat(
    _ floatingObject: FloatingObjectWrapper, logicalLeft: LayoutUnit
  ) {
    if isHorizontalWritingMode() {
      floatingObject.setX(x: logicalLeft)
    } else {
      floatingObject.setY(y: logicalLeft)
    }
  }

  private func setLogicalHeightForFloat(
    _ floatingObject: FloatingObjectWrapper, logicalHeight: LayoutUnit
  ) {
    if isHorizontalWritingMode() {
      floatingObject.setHeight(height: logicalHeight)
    } else {
      floatingObject.setWidth(width: logicalHeight)
    }
  }

  private func setLogicalMarginsForFloat(
    _ floatingObject: FloatingObjectWrapper, logicalLeftMargin: LayoutUnit,
    logicalBeforeMargin: LayoutUnit
  ) {
    if isHorizontalWritingMode() {
      floatingObject.setMarginOffset(
        offset: LayoutSizeWrapper(width: logicalLeftMargin, height: logicalBeforeMargin))
    } else {
      floatingObject.setMarginOffset(
        offset: LayoutSizeWrapper(width: logicalBeforeMargin, height: logicalLeftMargin))
    }
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
    if childrenInline() && !b {
      setLineLayoutPath(path: .UndeterminedPath)
      lineLayout = .None
    }

    super.setChildrenInline(b: b)
  }

  private func hasLines() -> Bool {
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

  func computeAndSetLineLayoutPath() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func lineCount() -> Int32 {
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

  private func nextPageLogicalTop(
    logicalOffset: LayoutUnit, pageBoundaryRule: PageBoundaryRule = .ExcludePageBoundary
  ) -> LayoutUnit {
    let pageLogicalHeight = pageLogicalHeightForOffsetFromBlockFlow(offset: logicalOffset)
    if !pageLogicalHeight.bool() {
      return logicalOffset
    }

    // The logicalOffset is in our coordinate space.  We can add in our pushed offset.
    let remainingLogicalHeight = pageRemainingLogicalHeightForOffsetFromBlockFlow(
      offset: logicalOffset)
    if pageBoundaryRule == .ExcludePageBoundary {
      return logicalOffset
        + (remainingLogicalHeight.bool() ? remainingLogicalHeight : pageLogicalHeight)
    }
    return logicalOffset + remainingLogicalHeight
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

  private func logicalHeightForChildForFragmentation(child: RenderBoxWrapper) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func updateColumnProgressionFromStyle(_ style: RenderStyleWrapper) {
    if multiColumnFlowForBlockFlow() == nil {
      return
    }

    var needsLayout = false
    let oldProgressionIsInline = multiColumnFlowForBlockFlow()!.progressionIsInline()
    let newProgressionIsInline = style.hasInlineColumnAxis()
    if oldProgressionIsInline != newProgressionIsInline {
      multiColumnFlowForBlockFlow()!.setProgressionIsInline(
        progressionIsInline: newProgressionIsInline)
      needsLayout = true
    }

    let oldProgressionIsReversed = multiColumnFlowForBlockFlow()!.progressionIsReversed()
    let newProgressionIsReversed = style.columnProgression() == .Reverse
    if oldProgressionIsReversed != newProgressionIsReversed {
      multiColumnFlowForBlockFlow()!.setProgressionIsReversed(reversed: newProgressionIsReversed)
      needsLayout = true
    }

    if needsLayout {
      setNeedsLayoutAndPrefWidthsRecalc()
    }
  }

  func updateStylesForColumnChildren(_ oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateStylesForColumnChildren(oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func needsLayoutAfterFragmentRangeChange() -> Bool {
    // A block without floats or that expands to enclose them won't need a relayout
    // after a fragment range change. There is no overflow content needing relayout
    // in the fragment chain because the fragment range can only shrink after the estimation.
    if !containsFloats() || createsNewFormattingContext() {
      return false
    }

    return true
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

  func adjustSizeContainmentChildForPagination(child: RenderBoxWrapper, offset: LayoutUnit) {
    if !child.shouldApplySizeContainment() {
      return
    }

    let childOverflowHeight =
      child.isHorizontalWritingMode()
      ? child.layoutOverflowRect().maxY() : child.layoutOverflowRect().maxX()
    let childLogicalHeight = max(child.logicalHeight(), childOverflowHeight)

    let remainingLogicalHeight = pageRemainingLogicalHeightForOffsetFromBlockFlow(
      offset: offset, pageBoundaryRule: .ExcludePageBoundary)

    let spaceShortage = childLogicalHeight - remainingLogicalHeight
    if spaceShortage <= Int32(0) {
      return
    }

    if let fragmentedFlow = enclosingFragmentedFlow() {
      fragmentedFlow.updateSpaceShortageForSizeContainment(
        block: self, offset: offsetFromLogicalTopOfFirstPage() + offset, shortage: spaceShortage)
    }
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

  override func shouldResetLogicalHeightBeforeLayout() -> Bool { return true }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    var needAdjustIntrinsicLogicalWidthsForColumns = true
    if shouldApplySizeOrInlineSizeContainment() {
      if let width = explicitIntrinsicInnerLogicalWidth() {
        minLogicalWidth = width
        maxLogicalWidth = width
        needAdjustIntrinsicLogicalWidthsForColumns = false
      }
    } else if childrenInline() {
      (minLogicalWidth, maxLogicalWidth) = computeInlinePreferredLogicalWidths()
    } else {
      computeBlockPreferredLogicalWidths(
        minLogicalWidth: &minLogicalWidth, maxLogicalWidth: &maxLogicalWidth)
    }

    maxLogicalWidth = max(minLogicalWidth, maxLogicalWidth)

    if needAdjustIntrinsicLogicalWidthsForColumns {
      adjustIntrinsicLogicalWidthsForColumns(
        minLogicalWidth: &minLogicalWidth, maxLogicalWidth: &maxLogicalWidth)
    }

    if !style().autoWrap() && childrenInline() {
      // A horizontal marquee with inline children has no minimum width.
      if let scrollableArea = layer()?.scrollableArea(),
        scrollableArea.marquee() != nil && scrollableArea.marquee()!.isHorizontal()
      {
        minLogicalWidth = LayoutUnit(value: 0)
      }
    }

    if let cell = self as? RenderTableCellWrapper {
      let tableCellWidth = cell.styleOrColLogicalWidth()
      if tableCellWidth.isFixed() && tableCellWidth.value() > 0 {
        maxLogicalWidth = max(
          minLogicalWidth, adjustContentBoxLogicalWidthForBoxSizing(logicalWidth: tableCellWidth))
      }
    }

    let scrollbarWidth = intrinsicScrollbarLogicalWidthIncludingGutter()
    maxLogicalWidth += scrollbarWidth
    minLogicalWidth += scrollbarWidth
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

  // If the child is unsplittable and can't fit on the current page, return the top of the next page/column.
  private func adjustForUnsplittableChild(
    child: RenderBoxWrapper, logicalOffset: LayoutUnit,
    childBeforeMargin: LayoutUnit = LayoutUnit(value: UInt64(0)),
    childAfterMargin: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) -> LayoutUnit {
    // When flexboxes are embedded inside a block flow, they don't perform any adjustments for unsplittable
    // children. We'll treat flexboxes themselves as unsplittable just to get them to paginate properly inside
    // a block flow.
    let isUnsplittable = childBoxIsUnsplittableForFragmentation(child: child)
    if !isUnsplittable {
      if let flexibleBox = child as? RenderFlexibleBoxWrapper, flexibleBox.isFlexibleBoxImpl() {
        return logicalOffset
      } else if !(child is RenderFlexibleBoxWrapper) {
        return logicalOffset
      }
    }

    let fragmentedFlow = enclosingFragmentedFlow()
    let childLogicalHeight =
      logicalHeightForChild(child: child) + childBeforeMargin + childAfterMargin
    let pageLogicalHeight = pageLogicalHeightForOffsetFromBlockFlow(offset: logicalOffset)
    let hasUniformPageLogicalHeight =
      fragmentedFlow == nil || fragmentedFlow!.fragmentsHaveUniformLogicalHeight()
    if isUnsplittable {
      updateMinimumPageHeight(offset: logicalOffset, minHeight: childLogicalHeight)
    }
    if !pageLogicalHeight.bool()
      || (hasUniformPageLogicalHeight && childLogicalHeight > pageLogicalHeight)
      || !hasNextPage(logicalOffset: logicalOffset)
    {
      return logicalOffset
    }
    var remainingLogicalHeight = pageRemainingLogicalHeightForOffsetFromBlockFlow(
      offset: logicalOffset, pageBoundaryRule: .ExcludePageBoundary)
    if remainingLogicalHeight < childLogicalHeight {
      if !hasUniformPageLogicalHeight
        && !pushToNextPageWithMinimumLogicalHeight(
          adjustment: &remainingLogicalHeight, logicalOffset: logicalOffset,
          minimumLogicalHeight: childLogicalHeight)
      {
        return logicalOffset
      }
      let result = logicalOffset + remainingLogicalHeight
      let isInitialLetter =
        child.isFloating() && child.style().pseudoElementType() == .FirstLetter
        && child.style().initialLetterDrop() > 0
      if isInitialLetter {
        // Increase our logical height to ensure that lines all get pushed along with the letter.
        setLogicalHeight(size: logicalOffset + remainingLogicalHeight)
      }
      return result
    }

    return logicalOffset
  }

  private func adjustBlockChildForPagination(
    logicalTopAfterClear: LayoutUnit, estimateWithoutPagination: LayoutUnit,
    child: RenderBoxWrapper, atBeforeSideOfBlock: Bool
  ) -> LayoutUnit {
    let childRenderBlock = child as? RenderBlockWrapper

    if estimateWithoutPagination != logicalTopAfterClear {
      // Our guess prior to pagination movement was wrong. Before we attempt to paginate, let's try again at the new
      // position.
      setLogicalHeight(size: logicalTopAfterClear)
      setLogicalTopForChild(
        child: child, logicalTop: logicalTopAfterClear, applyDelta: .ApplyLayoutDelta)

      if child.shrinkToAvoidFloats() {
        // The child's width depends on the line width. When the child shifts to clear an item, its width can
        // change (because it has more available line width). So mark the item as dirty.
        child.setChildNeedsLayout(markParents: .MarkOnlyThis)
      }

      if childRenderBlock != nil {
        if !child.avoidsFloats() && childRenderBlock!.containsFloats() {
          (childRenderBlock as! RenderBlockFlowWrapper).markAllDescendantsWithFloatsForLayout()
        }
        child.markForPaginationRelayoutIfNeeded()
      }

      // Our guess was wrong. Make the child lay itself out again.
      child.layoutIfNeeded()
    }

    let oldTop = logicalTopAfterClear

    // If the object has a page or column break value of "before", then we should shift to the top of the next page.
    var result = applyBeforeBreak(child: child, logicalOffset: logicalTopAfterClear)

    if child.shouldApplySizeContainment() {
      adjustSizeContainmentChildForPagination(child: child, offset: result)
    }

    // For replaced elements and scrolled elements, we want to shift them to the next page if they don't fit on the current one.
    let logicalTopBeforeUnsplittableAdjustment = result
    let logicalTopAfterUnsplittableAdjustment = adjustForUnsplittableChild(
      child: child, logicalOffset: result)

    var paginationStrut = LayoutUnit()
    let unsplittableAdjustmentDelta =
      logicalTopAfterUnsplittableAdjustment - logicalTopBeforeUnsplittableAdjustment
    let childLogicalHeight = child.logicalHeight()
    if unsplittableAdjustmentDelta.bool() {
      setPageBreak(offset: result, spaceShortage: childLogicalHeight - unsplittableAdjustmentDelta)
      paginationStrut = unsplittableAdjustmentDelta
    } else if childRenderBlock != nil && childRenderBlock!.paginationStrut().bool() {
      paginationStrut = childRenderBlock!.paginationStrut()
    }

    if paginationStrut.bool() {
      // We are willing to propagate out to our parent block as long as we were at the top of the block prior
      // to collapsing our margins, and as long as we didn't clear or move as a result of other pagination.
      if atBeforeSideOfBlock && oldTop == result && !isOutOfFlowPositioned() && !isRenderTableCell()
      {
        // FIXME: Should really check if we're exceeding the page height before propagating the strut, but we don't
        // have all the information to do so (the strut only has the remaining amount to push). Gecko gets this wrong too
        // and pushes to the next page anyway, so not too concerned about it.
        setPaginationStrut(strut: result + paginationStrut)
        if childRenderBlock != nil {
          childRenderBlock!.setPaginationStrut(strut: LayoutUnit(value: 0))
        }
      } else {
        result += paginationStrut
      }
    }

    if !unsplittableAdjustmentDelta.bool() {
      let pageLogicalHeight = pageLogicalHeightForOffsetFromBlockFlow(offset: result)
      if pageLogicalHeight.bool() {
        let remainingLogicalHeight = pageRemainingLogicalHeightForOffsetFromBlockFlow(
          offset: result, pageBoundaryRule: .ExcludePageBoundary)
        let spaceShortage = child.logicalHeight() - remainingLogicalHeight
        if spaceShortage > 0 {
          // If the child crosses a column boundary, report a break, in case nothing inside it
          // has already done so. The column balancer needs to know how much it has to stretch
          // the columns to make more content fit. If no breaks are reported (but do occur),
          // the balancer will have no clue. Only measure the space after the last column
          // boundary, in case it crosses more than one.
          let spaceShortageInLastColumn = LayoutUnit.intMod(a: spaceShortage, b: pageLogicalHeight)
          setPageBreak(
            offset: result,
            spaceShortage: spaceShortageInLastColumn.bool()
              ? spaceShortageInLastColumn : spaceShortage)
        } else if remainingLogicalHeight == pageLogicalHeight
          && (offsetFromLogicalTopOfFirstPage() + child.logicalTop()).bool()
        {
          // We're at the very top of a page or column, and it's not the first one. This child
          // may turn out to be the smallest piece of content that causes a page break, so we
          // need to report it.
          setPageBreak(offset: result, spaceShortage: childLogicalHeight)
        }
      }
    }

    // Similar to how we apply clearance. Boost height() to be the place where we're going to position the child.
    setLogicalHeight(size: logicalHeight() + (result - oldTop))

    // Return the final adjusted logical top.
    return result
  }

  private func applyBeforeBreak(child: RenderBoxWrapper, logicalOffset: LayoutUnit) -> LayoutUnit {
    // FIXME: Add page break checking here when we support printing.
    let fragmentedFlow = enclosingFragmentedFlow()
    let isInsideMulticolFlow = fragmentedFlow != nil
    let checkColumnBreaks =
      fragmentedFlow != nil && fragmentedFlow!.shouldCheckColumnBreaks()
      && (!shouldApplyLayoutContainment() || child.previousSibling() != nil)
    let checkPageBreaks =
      !checkColumnBreaks
      && view().frameView().layoutContext().layoutState()!.pageLogicalHeight().bool()  // FIXME: Once columns can print we have to check this.
    var checkFragmentBreaks = false
    let checkBeforeAlways =
      (checkColumnBreaks && child.style().breakBefore() == .Column)
      || (checkPageBreaks && alwaysPageBreak(between: child.style().breakBefore()))
    if checkBeforeAlways && inNormalFlow(child: child)
      && hasNextPage(logicalOffset: logicalOffset, pageBoundaryRule: .IncludePageBoundary)
    {
      if checkColumnBreaks && isInsideMulticolFlow {
        checkFragmentBreaks = true
      }
      if checkFragmentBreaks {
        var offsetBreakAdjustment: LayoutUnit? = LayoutUnit()
        if fragmentedFlow!.addForcedFragmentBreak(
          block: self, offset: offsetFromLogicalTopOfFirstPage() + logicalOffset, breakChild: child,
          isBefore: true,
          offsetBreakAdjustment: &offsetBreakAdjustment)
        {
          return logicalOffset + offsetBreakAdjustment!
        }
      }
      return nextPageLogicalTop(
        logicalOffset: logicalOffset, pageBoundaryRule: .IncludePageBoundary)
    }
    return logicalOffset
  }

  // If the child has an after break, then return a new offset that shifts to the top of the next page/column.
  private func applyAfterBreak(
    child: RenderBoxWrapper, logicalOffset: LayoutUnit, marginInfo: inout MarginInfo
  ) -> LayoutUnit {
    // FIXME: Add page break checking here when we support printing.
    let fragmentedFlow = enclosingFragmentedFlow()
    let isInsideMulticolFlow = fragmentedFlow != nil
    let checkColumnBreaks = fragmentedFlow != nil && fragmentedFlow!.shouldCheckColumnBreaks()
    let checkPageBreaks =
      !checkColumnBreaks
      && view().frameView().layoutContext().layoutState()!.pageLogicalHeight().bool()  // FIXME: Once columns can print we have to check this.
    var checkFragmentBreaks = false
    let checkAfterAlways =
      (checkColumnBreaks && child.style().breakAfter() == .Column)
      || (checkPageBreaks && alwaysPageBreak(between: child.style().breakAfter()))
    if checkAfterAlways && inNormalFlow(child: child)
      && hasNextPage(logicalOffset: logicalOffset, pageBoundaryRule: .IncludePageBoundary)
    {

      // So our margin doesn't participate in the next collapsing steps.
      marginInfo.clearMargin()

      if checkColumnBreaks && isInsideMulticolFlow {
        checkFragmentBreaks = true
      }
      if checkFragmentBreaks {
        var offsetBreakAdjustment: LayoutUnit? = LayoutUnit()
        if fragmentedFlow!.addForcedFragmentBreak(
          block: self, offset: offsetFromLogicalTopOfFirstPage() + logicalOffset, breakChild: child,
          isBefore: false,
          offsetBreakAdjustment: &offsetBreakAdjustment)
        {
          return logicalOffset + offsetBreakAdjustment!
        }
      }
      return nextPageLogicalTop(
        logicalOffset: logicalOffset, pageBoundaryRule: .IncludePageBoundary)
    }
    return logicalOffset
  }

  private func maxPositiveMarginBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func maxNegativeMarginBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func maxPositiveMarginAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func maxNegativeMarginAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func initMaxMarginValues() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func setMaxMarginBeforeValues(pos: LayoutUnit, neg: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func setMaxMarginAfterValues(pos: LayoutUnit, neg: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleWillChange(diff: StyleDifference, newStyle: RenderStyleWrapper) {
    let oldStyle = hasInitializedStyle ? style() : nil
    RenderBlockWrapper.canPropagateFloatIntoSibling =
      oldStyle != nil ? !isFloatingOrOutOfFlowPositioned() && !avoidsFloats() : false

    if oldStyle != nil {
      let oldPosition = oldStyle!.position()
      let newPosition = newStyle.position()

      if parent() != nil && diff == .Layout && oldPosition != newPosition {
        if containsFloats() && !isFloating() && !isOutOfFlowPositioned()
          && newStyle.hasOutOfFlowPosition()
        {
          markAllDescendantsWithFloatsForLayout()
        }
      }
    }

    super.styleWillChange(diff: diff, newStyle: newStyle)
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)

    // After our style changed, if we lose our ability to propagate floats into next sibling
    // blocks, then we need to find the top most parent containing that overhanging float and
    // then mark its descendants with floats for layout and clear all floats from its next
    // sibling blocks that exist in our floating objects list. See bug 56299 and 62875.
    let canPropagateFloatIntoSibling = !isFloatingOrOutOfFlowPositioned() && !avoidsFloats()
    if diff == .Layout && RenderBlockWrapper.canPropagateFloatIntoSibling
      && !canPropagateFloatIntoSibling && hasOverhangingFloats()
    {
      var parentBlock: RenderBlockFlowWrapper = self
      let floatingObjectSet = floatingObjects!.set()

      for ancestor: RenderBlockFlowWrapper in ancestorsOfType(descendant: self) {
        if ancestor.isRenderView() {
          break
        }
        if ancestor.hasOverhangingFloats() {
          for floatingObject in floatingObjectSet {
            if ancestor.hasOverhangingFloat(floatingObject.renderer!) {
              parentBlock = ancestor
              break
            }
          }
        }
      }

      parentBlock.markAllDescendantsWithFloatsForLayout()
      parentBlock.markSiblingsWithFloatsForLayout()
    }

    if diff == .Layout && selfNeedsLayout() && childrenInline() {
      let walker = InlineWalker(root: self)
      while !walker.atEnd() {
        walker.current()!.setPreferredLogicalWidthsDirty(shouldBeDirty: true)
        walker.advance()
      }
    }

    if multiColumnFlowForBlockFlow() == nil {
      updateStylesForColumnChildren(oldStyle: oldStyle)
    }
  }

  private func createFloatingObjects() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func firstLineBaseline() -> LayoutUnit? {
    if isWritingModeRoot() && !isGridItem() && !isFlexItem() {
      return nil
    }

    if shouldApplyLayoutContainment() {
      return nil
    }

    if !childrenInline() {
      return super.firstLineBaseline()
    }

    if !hasLines() {
      return nil
    }

    if let lineLayout = inlineLayout() {
      return LayoutUnit(value: floorToInt(value: lineLayout.firstLinePhysicalBaseline()))
    }

    fatalError("Not reached")
  }

  override func lastLineBaseline() -> LayoutUnit? {
    if isWritingModeRoot() && !isGridItem() && !isFlexItem() {
      return nil
    }

    if shouldApplyLayoutContainment() {
      return nil
    }

    if !childrenInline() {
      return super.lastLineBaseline()
    }

    if !hasLines() {
      return nil
    }

    if let lineLayout = inlineLayout() {
      return LayoutUnit(value: floorToInt(value: lineLayout.lastLinePhysicalBaseline()))
    }

    fatalError("Not reached")
  }

  func setComputedColumnCountAndWidth(count: Int32, width: LayoutUnit) {
    assert((multiColumnFlowForBlockFlow() != nil) == requiresColumns(desiredColumnCount: count))
    if let multiColumnFlow = multiColumnFlowForBlockFlow() {
      multiColumnFlow.setColumnCountAndWidth(count: UInt32(count), width: width)
      multiColumnFlow.setProgressionIsInline(progressionIsInline: style().hasInlineColumnAxis())
      multiColumnFlow.setProgressionIsReversed(reversed: style().columnProgression() == .Reverse)
    }
  }

  private func computedColumnWidthForBlockFlow() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func allowedLayoutOverflow() -> LayoutOptionalOutsets {
    var allowance = allowedLayoutOverflowForBox()

    if style().alignContent().position != .Normal {
      if hasRareBlockFlowData() {
        if isHorizontalWritingMode() {
          allowance.top = -rareBlockFlowData().alignContentShift
        } else {
          allowance.left = -rareBlockFlowData().alignContentShift
        }
      }
    }

    if multiColumnFlowForBlockFlow() != nil && style().columnProgression() != .Normal {
      if isHorizontalWritingMode() != !style().hasInlineColumnAxis() {
        allowance = allowance.xFlippedCopy()
      } else {
        allowance = allowance.yFlippedCopy()
      }
    }

    return allowance
  }

  func computeColumnCountAndWidth() {
    // Calculate our column width and column count.
    // FIXME: Can overflow on fast/block/float/float-not-removed-from-next-sibling4.html, see https://bugs.webkit.org/show_bug.cgi?id=68744
    var desiredColumnCount: UInt32 = 1
    var desiredColumnWidth = contentLogicalWidth()

    // For now, we don't support multi-column layouts when printing, since we have to do a lot of work for proper pagination.
    if document().paginated() || (style().hasAutoColumnCount() && style().hasAutoColumnWidth())
      || !style().hasInlineColumnAxis()
    {
      setComputedColumnCountAndWidth(count: Int32(desiredColumnCount), width: desiredColumnWidth)
      return
    }

    let availWidth = desiredColumnWidth
    let colGap = columnGap()
    let colWidth = max(LayoutUnit(value: UInt64(1)), LayoutUnit(value: style().columnWidth()))
    let colCount = UInt32(max(1, style().columnCount()))

    if style().hasAutoColumnWidth() && !style().hasAutoColumnCount() {
      desiredColumnCount = UInt32(colCount)
      desiredColumnWidth = max(
        LayoutUnit(value: 0),
        (availWidth - ((desiredColumnCount - UInt32(1)) * colGap)) / desiredColumnCount)
    } else if !style().hasAutoColumnWidth() && style().hasAutoColumnCount() {
      desiredColumnCount = max(1, ((availWidth + colGap) / (colWidth + colGap)).toUnsigned())
      desiredColumnWidth = ((availWidth + colGap) / desiredColumnCount) - colGap
    } else {
      desiredColumnCount = max(
        min(colCount, ((availWidth + colGap) / (colWidth + colGap)).toUnsigned()), 1)
      desiredColumnWidth = ((availWidth + colGap) / desiredColumnCount) - colGap
    }
    setComputedColumnCountAndWidth(count: Int32(desiredColumnCount), width: desiredColumnWidth)
  }

  // Called to lay out the legend for a fieldset or the ruby text of a ruby run. Also used by multi-column layout to handle
  // the flow thread child.
  override func layoutExcludedChildren(relayoutChildren: Bool) {
    super.layoutExcludedChildren(relayoutChildren: relayoutChildren)

    let fragmentedFlow = multiColumnFlowForBlockFlow()
    if fragmentedFlow == nil {
      return
    }

    fragmentedFlow!.setIsExcludedFromNormalLayout(excluded: true)

    setLogicalTopForChild(child: fragmentedFlow!, logicalTop: borderAndPaddingBefore())

    if relayoutChildren {
      fragmentedFlow!.setChildNeedsLayout(markParents: .MarkOnlyThis)
    }

    if fragmentedFlow!.needsLayout() {
      var columnSet = fragmentedFlow!.firstMultiColumnSet()
      while columnSet != nil {
        columnSet!.prepareForLayout(initial: !fragmentedFlow!.inBalancingPass)
        columnSet = columnSet!.nextSiblingMultiColumnSet()
      }

      fragmentedFlow!.invalidateFragments(markingParents: .MarkOnlyThis)
      fragmentedFlow!.setNeedsHeightsRecalculation(recalculate: true)
      fragmentedFlow!.layout()
    } else {
      // At the end of multicol layout, relayoutForPagination() is called unconditionally, but if
      // no children are to be laid out (e.g. fixed width with layout already being up-to-date),
      // we want to prevent it from doing any work, so that the column balancing machinery doesn't
      // kick in and trigger additional unnecessary layout passes. Actually, it's not just a good
      // idea in general to not waste time on balancing content that hasn't been re-laid out; we
      // are actually required to guarantee this. The calculation of implicit breaks needs to be
      // preceded by a proper layout pass, since it's layout that sets up content runs, and the
      // runs get deleted right after every pass.
      fragmentedFlow!.setNeedsHeightsRecalculation(recalculate: false)
    }
    determineLogicalLeftPositionForChild(child: fragmentedFlow!)
  }

  private func recomputeLogicalWidthAndColumnWidth() -> Bool {
    let changed = recomputeLogicalWidth()

    let oldColumnWidth = computedColumnWidthForBlockFlow()
    computeColumnCountAndWidth()

    return changed || oldColumnWidth != computedColumnWidthForBlockFlow()
  }

  private func columnGap() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func previousSiblingWithOverhangingFloats() -> (RenderBlockFlowWrapper?, Bool) {
    // Attempt to locate a previous sibling with overhanging floats. We skip any elements that are
    // out of flow (like floating/positioned elements), and we also skip over any objects that may have shifted
    // to avoid floats.
    var parentHasFloats = false
    var sibling = previousSibling()
    while sibling != nil {
      if let siblingBlock = sibling as? RenderBlockFlowWrapper, !siblingBlock.avoidsFloats() {
        return (siblingBlock, parentHasFloats)
      }
      if sibling!.isFloating() {
        parentHasFloats = true
      }
      sibling = sibling!.previousSibling()
    }
    return (nil, parentHasFloats)
  }

  private func checkForPaginationLogicalHeightChange(
    relayoutChildren: inout Bool, pageLogicalHeight: inout LayoutUnit,
    pageLogicalHeightChanged: inout Bool
  ) {
    // If we don't use columns or flow threads, then bail.
    if !isRenderFragmentedFlow() && multiColumnFlowForBlockFlow() == nil {
      return
    }

    // We don't actually update any of the variables. We just subclassed to adjust our column height.
    if let fragmentedFlow = multiColumnFlowForBlockFlow() {
      var newColumnHeight = LayoutUnit()
      if hasDefiniteLogicalHeight() || view().frameView().pagination().mode != .Unpaginated {
        let computedValues = computeLogicalHeight(
          logicalHeight: LayoutUnit(value: 0), logicalTop: logicalTop())
        newColumnHeight = max(
          computedValues.extent - borderAndPaddingLogicalHeight() - scrollbarLogicalHeight(),
          LayoutUnit(value: 0))
        if fragmentedFlow.columnHeightAvailable != newColumnHeight {
          relayoutChildren = true
        }
      }
      fragmentedFlow.setColumnHeightAvailable(available: newColumnHeight)
    } else if let fragmentedFlow = self as? RenderFragmentedFlowWrapper {
      // FIXME: This is a hack to always make sure we have a page logical height, if said height
      // is known. The page logical height thing in RenderLayoutState is meaningless for flow
      // thread-based pagination (page height isn't necessarily uniform throughout the flow
      // thread), but as long as it is used universally as a means to determine whether page
      // height is known or not, we need this. Page height is unknown when column balancing is
      // enabled and flow thread height is still unknown (i.e. during the first layout pass). When
      // it's unknown, we need to prevent the pagination code from assuming page breaks everywhere
      // and thereby eating every top margin. It should be trivial to clean up and get rid of this
      // hack once the old multicol implementation is gone (see also RenderView::pushLayoutStateForPagination).
      pageLogicalHeight =
        fragmentedFlow.isPageLogicalHeightKnown()
        ? LayoutUnit(value: UInt64(1)) : LayoutUnit(value: UInt64(0))

      pageLogicalHeightChanged = fragmentedFlow.pageLogicalSizeChanged
    }
  }

  private func determineLogicalLeftPositionForChild(
    child: RenderBoxWrapper, applyDelta: ApplyLayoutDeltaMode = .DoNotApplyLayoutDelta
  ) {
    var startPosition = borderAndPaddingStart()
    let initialStartPosition = startPosition
    if (shouldPlaceVerticalScrollbarOnLeftForLayerModelObject()
      || style().scrollbarGutter().bothEdges)
      && isHorizontalWritingMode()
    {
      startPosition += (style().isLeftToRightDirection() ? 1 : -1) * verticalScrollbarWidth()
    }
    if style().scrollbarGutter().bothEdges && !isHorizontalWritingMode() {
      startPosition += (style().isLeftToRightDirection() ? 1 : -1) * horizontalScrollbarHeight()
    }
    let totalAvailableLogicalWidth = borderAndPaddingLogicalWidth() + availableLogicalWidth()

    let childMarginStart = marginStartForChild(child: child)
    var newPosition = startPosition + childMarginStart

    var positionToAvoidFloats = LayoutUnit()

    if child.avoidsFloats() && containsFloats() {
      positionToAvoidFloats = startOffsetForLine(
        position: logicalTopForChild(child: child),
        logicalHeight: logicalHeightForChild(child: child))
    }

    // If the child has an offset from the content edge to avoid floats then use that, otherwise let any negative
    // margin pull it back over the content edge or any positive margin push it out.
    // If the child is being centred then the margin calculated to do that has factored in any offset required to
    // avoid floats, so use it if necessary.

    if style().textAlign() == .WebKitCenter
      || child.style().marginStartUsing(otherStyle: style()).isAuto()
    {
      newPosition = max(newPosition, positionToAvoidFloats + childMarginStart)
    } else if positionToAvoidFloats > initialStartPosition {
      newPosition = max(newPosition, positionToAvoidFloats)
    }

    setLogicalLeftForChild(
      child: child,
      logicalLeft: style().isLeftToRightDirection()
        ? newPosition
        : totalAvailableLogicalWidth - newPosition - logicalWidthForChild(child: child),
      applyDelta: applyDelta)
  }

  struct LinePaginationAdjustment {
    var strut = LayoutUnit(value: 0)
    var isFirstAfterPageBreak = false
  }

  func relayoutForPagination() -> Bool {
    if multiColumnFlowForBlockFlow() == nil
      || !multiColumnFlowForBlockFlow()!.shouldRelayoutForPagination()
    {
      return false
    }

    multiColumnFlowForBlockFlow()!.setNeedsHeightsRecalculation(recalculate: false)
    multiColumnFlowForBlockFlow()!.setInBalancingPass(balancing: true)  // Prevent re-entering this method (and recursion into layout).

    var needsRelayout = false
    var neededRelayout = false
    var firstPass = true
    repeat {
      // Column heights may change here because of balancing. We may have to do multiple layout
      // passes, depending on how the contents is fitted to the changed column heights. In most
      // cases, laying out again twice or even just once will suffice. Sometimes we need more
      // passes than that, though, but the number of retries should not exceed the number of
      // columns, unless we have a bug.
      needsRelayout = false
      var multicolSet = multiColumnFlowForBlockFlow()!.firstMultiColumnSet()
      while multicolSet != nil {
        if multicolSet!.recalculateColumnHeight(initial: firstPass) {
          needsRelayout = true
        }
        if needsRelayout {
          // Once a column set gets a new column height, that column set and all successive column
          // sets need to be laid out over again, since their logical top will be affected by
          // this, and therefore their column heights may change as well, at least if the multicol
          // height is constrained.
          multicolSet!.setChildNeedsLayout(markParents: .MarkOnlyThis)
        }
        multicolSet = multicolSet!.nextSiblingMultiColumnSet()
      }
      if needsRelayout {
        // Layout again. Column balancing resulted in a new height.
        neededRelayout = true
        multiColumnFlowForBlockFlow()!.setChildNeedsLayout(markParents: .MarkOnlyThis)
        setChildNeedsLayout(markParents: .MarkOnlyThis)
        layoutBlock(relayoutChildren: false)
      }
      firstPass = false
    } while needsRelayout

    multiColumnFlowForBlockFlow()!.setInBalancingPass(balancing: false)

    return neededRelayout
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

  override func repaintOverhangingFloats(paintAllDescendants: Bool) {
    // Repaint any overhanging floats (if we know we're the one to paint them).
    // Otherwise, bail out.
    if !hasOverhangingFloats() {
      return
    }

    // FIXME: Avoid disabling LayoutState. At the very least, don't disable it for floats originating
    // in this block. Better yet would be to push extra state for the containers of other floats.
    let _ = LayoutStateDisabler(context: view().frameView().layoutContext())
    let floatingObjectSet = floatingObjects!.set()
    for floatingObject in floatingObjectSet {
      // Only repaint the object if it is overhanging, is not in its own layer, and
      // is our responsibility to paint (m_shouldPaint is set). When paintAllDescendants is true, the latter
      // condition is replaced with being a descendant of us.
      let renderer = floatingObject.renderer!
      if logicalBottomForFloat(floatingObject: floatingObject) > logicalHeight()
        && !renderer.hasSelfPaintingLayer()
        && (floatingObject.paintsFloat()
          || (paintAllDescendants && renderer.isDescendantOf(ancestor: self)))
      {
        renderer.repaint()
        renderer.repaintOverhangingFloats(paintAllDescendants: false)
      }
    }
  }

  @discardableResult
  private func insertFloatingObject(floatBox: RenderBoxWrapper) -> FloatingObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func removeFloatingObject(floatBox: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func computeLogicalLocationForFloat(
    floatingObject: FloatingObjectWrapper, logicalTopOffset: LayoutUnit
  ) {
    let childBox = floatingObject.renderer!
    var logicalLeftOffset = logicalLeftOffsetForContent(blockOffset: logicalTopOffset)  // Constant part of left offset.
    var logicalRightOffset = logicalRightOffsetForContent(blockOffset: logicalTopOffset)  // Constant part of right offset.

    var floatLogicalWidth = min(
      logicalWidthForFloat(floatingObject), logicalRightOffset - logicalLeftOffset)  // The width we look for.

    var floatLogicalLeft = LayoutUnit()

    let insideFragmentedFlow = enclosingFragmentedFlow() != nil
    let isInitialLetter =
      childBox.style().pseudoElementType() == .FirstLetter
      && childBox.style().initialLetterDrop() > 0

    var logicalTopOffset = logicalTopOffset
    if isInitialLetter, let lowestInitialLetterLogicalBottom = lowestInitialLetterLogicalBottom() {
      let letterClearance = lowestInitialLetterLogicalBottom - logicalTopOffset
      if letterClearance > 0 {
        logicalTopOffset += letterClearance
        setLogicalHeight(size: logicalHeight() + letterClearance)
      }
    }

    if RenderStyleWrapper.usedFloat(renderer: childBox) == .Left {
      var heightRemainingLeft = LayoutUnit(value: UInt64(1))
      var heightRemainingRight = LayoutUnit(value: UInt64(1))
      floatLogicalLeft = logicalLeftOffsetForPositioningFloat(
        logicalTop: logicalTopOffset, fixedOffset: logicalLeftOffset,
        heightRemaining: &heightRemainingLeft)
      while logicalRightOffsetForPositioningFloat(
        logicalTop: logicalTopOffset, fixedOffset: logicalRightOffset,
        heightRemaining: &heightRemainingRight) - floatLogicalLeft
        < floatLogicalWidth
      {
        logicalTopOffset += min(heightRemainingLeft, heightRemainingRight)
        floatLogicalLeft = logicalLeftOffsetForPositioningFloat(
          logicalTop: logicalTopOffset, fixedOffset: logicalLeftOffset,
          heightRemaining: &heightRemainingLeft)
        if insideFragmentedFlow {
          // Have to re-evaluate all of our offsets, since they may have changed.
          logicalRightOffset = logicalRightOffsetForContent(blockOffset: logicalTopOffset)  // Constant part of right offset.
          logicalLeftOffset = logicalLeftOffsetForContent(blockOffset: logicalTopOffset)  // Constant part of left offset.
          floatLogicalWidth = min(
            logicalWidthForFloat(floatingObject), logicalRightOffset - logicalLeftOffset)
        }
      }
      floatLogicalLeft = max(logicalLeftOffset - borderAndPaddingLogicalLeft(), floatLogicalLeft)
    } else {
      var heightRemainingLeft = LayoutUnit(value: UInt64(1))
      var heightRemainingRight = LayoutUnit(value: UInt64(1))
      floatLogicalLeft = logicalRightOffsetForPositioningFloat(
        logicalTop: logicalTopOffset, fixedOffset: logicalRightOffset,
        heightRemaining: &heightRemainingRight)
      while floatLogicalLeft
        - logicalLeftOffsetForPositioningFloat(
          logicalTop: logicalTopOffset, fixedOffset: logicalLeftOffset,
          heightRemaining: &heightRemainingLeft) < floatLogicalWidth
      {
        logicalTopOffset += min(heightRemainingLeft, heightRemainingRight)
        floatLogicalLeft = logicalRightOffsetForPositioningFloat(
          logicalTop: logicalTopOffset, fixedOffset: logicalRightOffset,
          heightRemaining: &heightRemainingRight)
        if insideFragmentedFlow {
          // Have to re-evaluate all of our offsets, since they may have changed.
          logicalRightOffset = logicalRightOffsetForContent(blockOffset: logicalTopOffset)  // Constant part of right offset.
          logicalLeftOffset = logicalLeftOffsetForContent(blockOffset: logicalTopOffset)  // Constant part of left offset.
          floatLogicalWidth = min(
            logicalWidthForFloat(floatingObject), logicalRightOffset - logicalLeftOffset)
        }
      }
      // Use the original width of the float here, since the local variable
      // |floatLogicalWidth| was capped to the available line width. See
      // fast/block/float/clamped-right-float.html.
      floatLogicalLeft -= logicalWidthForFloat(floatingObject)
    }

    let childLogicalLeftMargin =
      style().isLeftToRightDirection()
      ? marginStartForChild(child: childBox) : marginEndForChild(child: childBox)
    var childBeforeMargin = marginBeforeForChild(child: childBox)

    if isInitialLetter {
      adjustInitialLetterPosition(
        childBox: childBox, logicalTopOffset: &logicalTopOffset,
        marginBeforeOffset: &childBeforeMargin)
    }

    setLogicalLeftForFloat(floatingObject, logicalLeft: floatLogicalLeft)
    setLogicalLeftForChild(child: childBox, logicalLeft: floatLogicalLeft + childLogicalLeftMargin)

    setLogicalTopForFloat(floatingObject, logicalTop: logicalTopOffset)
    setLogicalTopForChild(child: childBox, logicalTop: logicalTopOffset + childBeforeMargin)

    setLogicalMarginsForFloat(
      floatingObject, logicalLeftMargin: childLogicalLeftMargin,
      logicalBeforeMargin: childBeforeMargin)
  }

  // Called from lineWidth, to position the floats added in the last line.
  // Returns true if and only if it has positioned any floats.
  @discardableResult
  private func positionNewFloats() -> Bool {
    if floatingObjects == nil {
      return false
    }

    let floatingObjectSet = floatingObjects!.set()
    if floatingObjectSet.isEmpty() {
      return false
    }

    // If all floats have already been positioned, then we have no work to do.
    if floatingObjectSet.last().isPlaced {
      return false
    }

    // Move backwards through our floating object list until we find a float that has
    // already been positioned. Then we'll be able to move forward, positioning all of
    // the new floats that need it.
    let it = floatingObjectSet.end()
    --it  // Go to last item.
    let begin = floatingObjectSet.begin()
    var lastPlacedFloatingObject: FloatingObjectWrapper? = nil
    while it != begin {
      --it
      if (*it).isPlaced {
        lastPlacedFloatingObject = *it
        ++it
        break
      }
    }

    var logicalTop = logicalHeight()

    // The float cannot start above the top position of the last positioned float.
    if lastPlacedFloatingObject != nil {
      logicalTop = max(logicalTopForFloat(floatingObject: lastPlacedFloatingObject!), logicalTop)
    }

    let end = floatingObjectSet.end()
    // Now walk through the set of unpositioned floats and place them.
    while it != end {
      let floatingObject = *it
      // The containing block is responsible for positioning floats, so if we have floats in our
      // list that come from somewhere else, do not attempt to position them.
      let childBox = floatingObject.renderer!
      if CPtrToInt(childBox.containingBlock()!.p) != CPtrToInt(p) {
        ++it
        continue
      }

      let oldRect = childBox.frameRect()
      let childBoxUsedClear = RenderStyleWrapper.usedClear(renderer: childBox)
      if childBoxUsedClear == .Left || childBoxUsedClear == .Both {
        logicalTop = max(lowestFloatLogicalBottom(floatType: .FloatLeft), logicalTop)
      }
      if childBoxUsedClear == .Right || childBoxUsedClear == .Both {
        logicalTop = max(lowestFloatLogicalBottom(floatType: .FloatRight), logicalTop)
      }

      computeLogicalLocationForFloat(floatingObject: floatingObject, logicalTopOffset: logicalTop)
      let childLogicalTop = logicalTopForChild(child: childBox)

      estimateFragmentRangeForBoxChild(box: childBox)

      childBox.markForPaginationRelayoutIfNeeded()
      childBox.layoutIfNeeded()

      let layoutState = view().frameView().layoutContext().layoutState()!
      let isPaginated = layoutState.isPaginated()
      if isPaginated {
        // If we are unsplittable and don't fit, then we need to move down.
        // We include our margins as part of the unsplittable area.
        var newLogicalTop = adjustForUnsplittableChild(
          child: childBox, logicalOffset: logicalTop,
          childBeforeMargin: childLogicalTop - logicalTop,
          childAfterMargin: marginAfterForChild(child: childBox))

        // See if we have a pagination strut that is making us move down further.
        // Note that an unsplittable child can't also have a pagination strut, so this
        // is exclusive with the case above.
        let childBlock = childBox as? RenderBlockWrapper
        if childBlock != nil && childBlock!.paginationStrut().bool() {
          newLogicalTop += childBlock!.paginationStrut()
          childBlock!.setPaginationStrut(strut: LayoutUnit(value: 0))
        }

        if newLogicalTop != logicalTop {
          floatingObject.setPaginationStrut(strut: newLogicalTop - logicalTop)
          computeLogicalLocationForFloat(
            floatingObject: floatingObject, logicalTopOffset: newLogicalTop)
          if childBlock != nil {
            childBlock!.setChildNeedsLayout(markParents: .MarkOnlyThis)
          }
          childBox.layoutIfNeeded()
          logicalTop = newLogicalTop
        }

        if updateFragmentRangeForBoxChild(box: childBox) {
          childBox.setNeedsLayout(markParents: .MarkOnlyThis)
          childBox.layoutIfNeeded()
        }
      }

      setLogicalHeightForFloat(
        floatingObject,
        logicalHeight: logicalHeightForChildForFragmentation(child: childBox)
          + (logicalTopForChild(child: childBox) - logicalTop)
          + marginAfterForChild(child: childBox))

      floatingObjects!.addPlacedObject(floatingObject)

      if let shapeOutside = childBox.shapeOutsideInfo() {
        shapeOutside.invalidateForSizeChangeIfNeeded()
      }
      // If the child moved, we have to repaint it.
      if childBox.checkForRepaintDuringLayout() {
        childBox.repaintDuringLayoutIfMoved(oldRect: oldRect)
      }
      ++it
    }
    return true
  }

  private func logicalRightOffsetForPositioningFloat(
    logicalTop: LayoutUnit, fixedOffset: LayoutUnit, heightRemaining: inout LayoutUnit
  ) -> LayoutUnit {
    var offset = fixedOffset
    if floatingObjects != nil && floatingObjects!.hasRightObjects() {
      offset = floatingObjects!.logicalRightOffsetForPositioningFloat(
        fixedOffset: fixedOffset, logicalTop: logicalTop, heightRemaining: &heightRemaining)
    }
    return adjustLogicalRightOffsetForLine(offset)
  }

  private func logicalLeftOffsetForPositioningFloat(
    logicalTop: LayoutUnit, fixedOffset: LayoutUnit, heightRemaining: inout LayoutUnit
  ) -> LayoutUnit {
    var offset = fixedOffset
    if floatingObjects != nil && floatingObjects!.hasLeftObjects() {
      offset = floatingObjects!.logicalLeftOffsetForPositioningFloat(
        fixedOffset: fixedOffset, logicalTop: logicalTop, heightRemaining: &heightRemaining)
    }
    return adjustLogicalLeftOffsetForLine(offset)
  }

  private func nextFloatLogicalBottomBelowForBlock(logicalHeight: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  private func addOverhangingFloats(child: RenderBlockFlowWrapper, makeChildPaintOtherFloats: Bool)
    -> LayoutUnit
  {
    // Prevent floats from being added to the canvas by the root element, e.g., <html>.
    if !child.containsFloats() || child.createsNewFormattingContext() {
      return LayoutUnit(value: 0)
    }

    let childLogicalTop = child.logicalTop()
    let childLogicalLeft = child.logicalLeft()
    var lowestFloatLogicalBottom = LayoutUnit()

    // Floats that will remain the child's responsibility to paint should factor into its
    // overflow.
    let blockHasOverflowClip = effectiveOverflowX() == .Clip || effectiveOverflowY() == .Clip
    for floatingObject in child.floatingObjects!.set() {
      let floatLogicalBottom = min(
        logicalBottomForFloat(floatingObject: floatingObject), LayoutUnit.max() - childLogicalTop)
      let logicalBottom = childLogicalTop + floatLogicalBottom
      lowestFloatLogicalBottom = max(lowestFloatLogicalBottom, logicalBottom)

      if logicalBottom > logicalHeight() {
        // If the object is not in the list, we add it now.
        if !containsFloat(renderer: floatingObject.renderer!) {
          let offset =
            isHorizontalWritingMode()
            ? LayoutSizeWrapper(width: -childLogicalLeft, height: -childLogicalTop)
            : LayoutSizeWrapper(width: -childLogicalTop, height: -childLogicalLeft)
          var shouldPaint = false

          // The nearest enclosing layer always paints the float (so that zindex and stacking
          // behaves properly). We always want to propagate the desire to paint the float as
          // far out as we can, to the outermost block that overlaps the float, stopping only
          // if we hit a self-painting layer boundary.
          if !floatingObject.hasAncestorWithOverflowClip()
            && CPtrToInt(floatingObject.renderer!.enclosingFloatPaintingLayer()?.p)
              == CPtrToInt(enclosingFloatPaintingLayer()?.p)
          {
            floatingObject.setPaintsFloat(paintsFloat: false)
            shouldPaint = true
          }
          // We create the floating object list lazily.
          if floatingObjects == nil {
            createFloatingObjects()
          }

          floatingObjects!.add(
            floatingObject: floatingObject.copyToNewContainer(
              offset: offset, shouldPaint: shouldPaint, isDescendant: true,
              overflowClipped: floatingObject.hasAncestorWithOverflowClip() || blockHasOverflowClip)
          )
        }
      } else {
        let renderer = floatingObject.renderer!
        if makeChildPaintOtherFloats && !floatingObject.paintsFloat()
          && !renderer.hasSelfPaintingLayer()
          && renderer.isDescendantOf(ancestor: child)
          && CPtrToInt(renderer.enclosingFloatPaintingLayer()?.p)
            == CPtrToInt(child.enclosingFloatPaintingLayer()?.p)
        {
          // The float is not overhanging from this block, so if it is a descendant of the child, the child should
          // paint it (the other case is that it is intruding into the child), unless it has its own layer or enclosing
          // layer.
          // If makeChildPaintOtherFloats is false, it means that the child must already know about all the floats
          // it should paint.
          floatingObject.setPaintsFloat(paintsFloat: true)
        }

        // Since the float doesn't overhang, it didn't get put into our list. We need to add its overflow in to the child now.
        if floatingObject.isDescendant() {
          child.addOverflowFromChild(
            child: renderer, delta: floatingObject.locationOffsetOfBorderBox())
        }
      }
    }
    return lowestFloatLogicalBottom
  }

  private func hasOverhangingFloat(_ renderer: RenderBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func addIntrudingFloats(
    prev: RenderBlockFlowWrapper?, container: RenderBlockFlowWrapper?,
    logicalLeftOffset: LayoutUnit, logicalTopOffset: LayoutUnit
  ) {
    assert(!avoidsFloats())

    // If we create our own block formatting context then our contents don't interact with floats outside it, even those from our parent.
    if createsNewFormattingContext() {
      return
    }

    // If the parent or previous sibling doesn't have any floats to add, don't bother.
    if prev!.floatingObjects == nil {
      return
    }

    var logicalLeftOffset = logicalLeftOffset
    logicalLeftOffset += marginLogicalLeft()

    let prevSet = prev!.floatingObjects!.set()
    for floatingObject in prevSet {
      if logicalBottomForFloat(floatingObject: floatingObject) > logicalTopOffset
        && (floatingObjects == nil || !floatingObjects!.set().contains(floatingObject))
      {
        // We create the floating object list lazily.
        if floatingObjects == nil {
          createFloatingObjects()
        }

        let zero = LayoutUnit(value: UInt64(0))
        // Applying the child's margin makes no sense in the case where the child was passed in.
        // since this margin was added already through the modification of the |logicalLeftOffset| variable
        // above. |logicalLeftOffset| will equal the margin in this case, so it's already been taken
        // into account. Only apply this code if prev is the parent, since otherwise the left margin
        // will get applied twice.
        let offset =
          isHorizontalWritingMode()
          ? LayoutSizeWrapper(
            width: logicalLeftOffset
              - (CPtrToInt(prev?.p) != CPtrToInt(container?.p) ? prev!.marginLeft() : zero),
            height: logicalTopOffset)
          : LayoutSizeWrapper(
            width: logicalTopOffset,
            height: logicalLeftOffset
              - (CPtrToInt(prev?.p) != CPtrToInt(container?.p) ? prev!.marginTop() : zero))

        floatingObjects!.add(floatingObject: floatingObject.copyToNewContainer(offset: offset))
      }
    }
  }

  private func hasOverhangingFloats() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func getClearDelta(child: RenderBoxWrapper, logicalTop: LayoutUnit) -> LayoutUnit {
    // There is no need to compute clearance if we have no floats.
    if !containsFloats() {
      return LayoutUnit(value: 0)
    }

    // At least one float is present. We need to perform the clearance computation.
    let usedClear = RenderStyleWrapper.usedClear(renderer: child)
    let clearSet = usedClear != .None
    var logicalBottom = LayoutUnit()
    switch usedClear {
    case .None:
      break
    case .Left:
      logicalBottom = lowestFloatLogicalBottom(floatType: .FloatLeft)
    case .Right:
      logicalBottom = lowestFloatLogicalBottom(floatType: .FloatRight)
    case .Both:
      logicalBottom = lowestFloatLogicalBottom()
    }

    // We also clear floats if we are too big to sit on the same line as a float (and wish to avoid floats by default).
    let result =
      clearSet
      ? max(LayoutUnit(value: 0), logicalBottom - logicalTop) : LayoutUnit(value: UInt64(0))
    if !result.bool() && child.avoidsFloats() {
      var newLogicalTop = logicalTop
      while true {
        let availableLogicalWidthAtNewLogicalTopOffset = availableLogicalWidthForLine(
          position: newLogicalTop, logicalHeight: logicalHeightForChild(child: child))
        if availableLogicalWidthAtNewLogicalTopOffset
          == availableLogicalWidthForContent(blockOffset: newLogicalTop)
        {
          return newLogicalTop - logicalTop
        }

        var fragment = fragmentAtBlockOffset(blockOffset: logicalTopForChild(child: child))
        var borderBox = child.borderBoxRectInFragment(
          fragment: fragment, flags: .DoNotCacheRenderBoxFragmentInfo)
        let childLogicalWidthAtOldLogicalTopOffset =
          isHorizontalWritingMode() ? borderBox.width() : borderBox.height()

        // FIXME: None of this is right for perpendicular writing-mode children.
        let childOldLogicalWidth = child.logicalWidth()
        let childOldMarginLeft = child.marginLeft()
        let childOldMarginRight = child.marginRight()
        let childOldLogicalTop = child.logicalTop()

        child.setLogicalTop(top: newLogicalTop)
        child.updateLogicalWidth()
        fragment = fragmentAtBlockOffset(blockOffset: logicalTopForChild(child: child))
        borderBox = child.borderBoxRectInFragment(
          fragment: fragment, flags: .DoNotCacheRenderBoxFragmentInfo)
        let childLogicalWidthAtNewLogicalTopOffset =
          isHorizontalWritingMode() ? borderBox.width() : borderBox.height()

        child.setLogicalTop(top: childOldLogicalTop)
        child.setLogicalWidth(size: childOldLogicalWidth)
        child.setMarginLeft(margin: childOldMarginLeft)
        child.setMarginRight(margin: childOldMarginRight)

        if childLogicalWidthAtNewLogicalTopOffset <= availableLogicalWidthAtNewLogicalTopOffset {
          // Even though we may not be moving, if the logical width did shrink because of the presence of new floats, then
          // we need to force a relayout as though we shifted. This happens because of the dynamic addition of overhanging floats
          // from previous siblings when negative margins exist on a child (see the addOverhangingFloats call at the end of collapseMargins).
          if childLogicalWidthAtOldLogicalTopOffset != childLogicalWidthAtNewLogicalTopOffset {
            child.setChildNeedsLayout(markParents: .MarkOnlyThis)
          }
          return newLogicalTop - logicalTop
        }

        newLogicalTop = nextFloatLogicalBottomBelowForBlock(logicalHeight: newLogicalTop)
        assert(newLogicalTop >= logicalTop)
        if newLogicalTop < logicalTop {
          break
        }
      }
      fatalError("Not reached")
    }
    return result
  }

  override func addOverflowFromInlineChildren() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func addFocusRingRectsForInlineChildren(
    rects: inout ArraySlice<LayoutRectWrapper>, additionalOffset: LayoutPointWrapper,
    paintContainer: RenderLayerModelObjectWrapper?
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

  private func layoutInlineContent(relayoutChildren: Bool) -> (LayoutUnit, LayoutUnit) {
    let layoutState = view().frameView().layoutContext().layoutState()!

    var hasSimpleOutOfFlowContentOnly = !hasLineIfEmpty()
    let hasSimpleStaticPositionForInlineLevelOutOfFlowContentByStyle =
      hasSimpleStaticPositionForInlineLevelOutOfFlowChildrenByStyle(rootStyle: style())

    let walker = InlineWalker(root: self)
    while !walker.atEnd() {
      let renderer = walker.current()!
      let box = renderer as? RenderBoxWrapper
      let childNeedsLayout = relayoutChildren || (box != nil && box!.hasRelativeDimensions())
      let childNeedsPreferredWidthComputation =
        relayoutChildren && box != nil && box!.needsPreferredWidthsRecalculation()
      if childNeedsLayout {
        renderer.setNeedsLayout(markParents: .MarkOnlyThis)
      }
      if childNeedsPreferredWidthComputation {
        renderer.setPreferredLogicalWidthsDirty(shouldBeDirty: true, markParents: .MarkOnlyThis)
      }

      if renderer.isOutOfFlowPositioned() {
        renderer.containingBlock()!.insertPositionedObject(positioned: box!)
        // FIXME: This is only needed because of the synchronous layout call in setStaticPositionsForSimpleOutOfFlowContent
        // which itself appears to be a workaround for a bad subtree layout shown by
        // fast/block/positioning/static_out_of_flow_inside_layout_boundary.html
        let hasParentRelativeHeightOrTop = RenderBlockFlowWrapper.hasParentRelativeHeightOrTop(
          renderer: renderer)
        if hasParentRelativeHeightOrTop {
          hasSimpleOutOfFlowContentOnly = false
        }

        if hasSimpleOutOfFlowContentOnly && renderer.style().isOriginalDisplayInlineType() {
          hasSimpleOutOfFlowContentOnly =
            hasSimpleStaticPositionForInlineLevelOutOfFlowContentByStyle
        }
      } else {
        hasSimpleOutOfFlowContentOnly = false
      }

      if !renderer.needsLayout() && !renderer.preferredLogicalWidthsDirty() {
        walker.advance()
        continue
      }

      if let renderText = renderer as? RenderTextWrapper {
        setFullRepaintOnParentInlineBoxLayerIfNeeded(renderer: renderText)
      }

      if let inlineLevelBox = renderer as? RenderBoxWrapper {
        // FIXME: Move this to where the actual content change happens and call it on the parent IFC.
        let shouldTriggerFullLayout =
          inlineLevelBox.isInline()
          && (inlineLevelBox.normalChildNeedsLayout() || inlineLevelBox.posChildNeedsLayout())
          && inlineLayout() != nil
        if shouldTriggerFullLayout {
          inlineLayout()!.boxContentWillChange(renderer: inlineLevelBox)
        }
      }

      if renderer is RenderLineBreakWrapper || renderer is RenderInlineWrapper
        || renderer is RenderTextWrapper
      {
        renderer.clearNeedsLayout()
      }

      if let renderCombineText = renderer as? RenderCombineTextWrapper {
        renderCombineText.combineTextIfNeeded()
      }
      walker.advance()
    }

    if hasSimpleOutOfFlowContentOnly {
      // Shortcut the layout.
      lineLayout = .None

      setStaticPositionsForSimpleOutOfFlowContent()
      setLogicalHeight(size: borderAndPaddingLogicalHeight() + scrollbarLogicalHeight())
      return (LayoutUnit(), LayoutUnit())
    }

    if inlineLayout() == nil {
      lineLayout = LineLayout.Integration(LayoutIntegration.LineLayout(flow: self))
    }

    let layoutFormattingContextLineLayout = inlineLayout()!

    assert(containingBlock() != nil || self is RenderViewWrapper)
    layoutFormattingContextLineLayout.updateFormattingContexGeometries(
      availableLogicalWidth: containingBlock() != nil
        ? containingBlock()!.availableLogicalWidth() : LayoutUnit())

    let contentBoxTop = borderAndPaddingBefore()

    let oldBorderBoxBottom = computeBorderBoxBottom(
      contentBoxTop: contentBoxTop,
      layoutFormattingContextLineLayout: layoutFormattingContextLineLayout)
    previousInlineLayoutContentBoxLogicalHeight = nil

    let partialRepaintRect = layoutFormattingContextLineLayout.layout()

    let newBorderBoxBottom = computeBorderBoxBottom(
      contentBoxTop: contentBoxTop,
      layoutFormattingContextLineLayout: layoutFormattingContextLineLayout)

    let repaintLogicalTopBottom = updateRepaintTopAndBottomIfNeeded(
      layoutFormattingContextLineLayout: layoutFormattingContextLineLayout,
      contentBoxTop: contentBoxTop, newBorderBoxBottom: newBorderBoxBottom,
      oldBorderBoxBottom: oldBorderBoxBottom, partialRepaintRect: partialRepaintRect,
      relayoutChildren: relayoutChildren)

    setLogicalHeight(size: newBorderBoxBottom)
    updateLineClampStateAndLogicalHeightIfApplicable(
      layoutState: layoutState, layoutFormattingContextLineLayout: layoutFormattingContextLineLayout
    )

    return repaintLogicalTopBottom
  }

  private func updateLineClampStateAndLogicalHeightIfApplicable(
    layoutState: RenderLayoutStateWrapper,
    layoutFormattingContextLineLayout: LayoutIntegration.LineLayout
  ) {
    var legacyLineClamp = layoutState.legacyLineClamp()
    if legacyLineClamp == nil || isFloatingOrOutOfFlowPositioned() {
      return
    }
    legacyLineClamp!.currentLineCount += layoutFormattingContextLineLayout.lineCount()
    if legacyLineClamp!.clampedRenderer != nil {
      // We've already clamped this flex container at a previous flex item.
      layoutState.setLegacyLineClamp(legacyLineClamp: legacyLineClamp)
      return
    }
    if let logicalHeight = clampedContentHeight(
      layoutFormattingContextLineLayout: layoutFormattingContextLineLayout,
      legacyLineClamp: legacyLineClamp)
    {
      legacyLineClamp!.clampedContentLogicalHeight = logicalHeight
      legacyLineClamp!.clampedRenderer = self
      setLogicalHeight(
        size: borderAndPaddingBefore() + logicalHeight + borderAndPaddingAfter()
          + scrollbarLogicalHeight())
    }
    layoutState.setLegacyLineClamp(legacyLineClamp: legacyLineClamp)
  }

  private func clampedContentHeight(
    layoutFormattingContextLineLayout: LayoutIntegration.LineLayout,
    legacyLineClamp: RenderLayoutStateWrapper.LegacyLineClamp?
  ) -> LayoutUnit? {
    if let clampedHeight = layoutFormattingContextLineLayout.clampedContentLogicalHeight() {
      return clampedHeight
    }
    if legacyLineClamp!.currentLineCount == legacyLineClamp!.maximumLineCount {
      // Even if we did not truncate the content, this might be our clamping position.
      return computeContentHeight(
        layoutFormattingContextLineLayout: layoutFormattingContextLineLayout)
    }
    return nil
  }

  private func updateRepaintTopAndBottomIfNeeded(
    layoutFormattingContextLineLayout: LayoutIntegration.LineLayout, contentBoxTop: LayoutUnit,
    newBorderBoxBottom: LayoutUnit, oldBorderBoxBottom: LayoutUnit,
    partialRepaintRect: LayoutRectWrapper?, relayoutChildren: Bool
  ) -> (LayoutUnit, LayoutUnit) {
    let isFullLayout = selfNeedsLayout() || relayoutChildren
    if isFullLayout {
      if !selfNeedsLayout() {
        // In order to really trigger full repaint, the block container has to have the self layout flag set (see LegacyLineLayout::layoutRunsAndFloats).
        // Without having it set, repaint after layout logic (see RenderElement::repaintAfterLayoutIfNeeded) only issues repaint on the diff of
        // before/after repaint bounds. It results in incorrect repaint when the inline content changes (new text) and expands the same time.
        // (it only affects shrink-to-fit type of containers).
        // FIXME: We have the exact damaged rect here, should be able to issue repaint on both inline and block directions.
        setNeedsLayout(markParents: .MarkOnlyThis)
      }
      // Let's trigger full repaint instead for now (matching legacy line layout).
      // FIXME: We should revisit this behavior and run repaints strictly on visual overflow.
      return (LayoutUnit(), LayoutUnit())
    }

    if partialRepaintRect != nil {
      return (partialRepaintRect!.y(), partialRepaintRect!.maxY())
    }

    let firstLineBox = InlineIterator.firstLineBoxFor(flow: self)
    let lastLineBox = InlineIterator.lastLineBoxFor(flow: self)
    if !firstLineBox.bool() {
      return (LayoutUnit(), LayoutUnit())
    }

    var repaintLogicalTop = min(
      contentBoxTop, LayoutUnit(value: firstLineBox.get().contentLogicalTop()))
    var repaintLogicalBottom = max(
      oldBorderBoxBottom, newBorderBoxBottom,
      LayoutUnit(value: lastLineBox.get().contentLogicalBottom()))
    if layoutFormattingContextLineLayout.hasVisualOverflow() {
      let lineBox = firstLineBox
      while lineBox.bool() {
        repaintLogicalTop = min(
          repaintLogicalTop, LayoutUnit(value: lineBox.get().inkOverflowLogicalTop()))
        repaintLogicalBottom = max(
          repaintLogicalBottom, LayoutUnit(value: lineBox.get().inkOverflowLogicalBottom()))
        lineBox.traverseNext()
      }
    }
    return (repaintLogicalTop, repaintLogicalBottom)
  }

  private func computeBorderBoxBottom(
    contentBoxTop: LayoutUnit, layoutFormattingContextLineLayout: LayoutIntegration.LineLayout
  ) -> LayoutUnit {
    let contentBoxBottom =
      contentBoxTop
      + computeContentHeight(layoutFormattingContextLineLayout: layoutFormattingContextLineLayout)
    let withBorderAndPadding = contentBoxBottom + borderAndPaddingAfter()
    return withBorderAndPadding + scrollbarLogicalHeight()
  }

  private func computeContentHeight(layoutFormattingContextLineLayout: LayoutIntegration.LineLayout)
    -> LayoutUnit
  {
    if !hasLines() && hasLineIfEmpty() {
      if previousInlineLayoutContentBoxLogicalHeight != nil {
        return previousInlineLayoutContentBoxLogicalHeight!
      }
      return lineHeight(
        firstLine: true, direction: isHorizontalWritingMode() ? .HorizontalLine : .VerticalLine,
        linePositionMode: .PositionOfInteriorLineBoxes)
    }

    return layoutFormattingContextLineLayout.contentBoxLogicalHeight()
  }

  private static func hasParentRelativeHeightOrTop(renderer: RenderObjectWrapper) -> Bool {
    let style = renderer.style()
    if style.logicalHeight().isPercentOrCalculated() || style.logicalTop().isPercentOrCalculated() {
      return true
    }
    return !renderer.style().logicalBottom().isAuto()
  }

  private func tryComputePreferredWidthsUsingInlinePath() -> (LayoutUnit, LayoutUnit)? {
    if firstInFlowChild() == nil {
      return nil
    }

    computeAndSetLineLayoutPath()

    if lineLayoutPath() != .InlinePath {
      return nil
    }

    if !LayoutIntegration.LineLayout.canUseForPreferredWidthComputation(flow: self) {
      return nil
    }

    if inlineLayout() == nil {
      lineLayout = LineLayout.Integration(LayoutIntegration.LineLayout(flow: self))
    }

    let intrinsicWidthConstraints = inlineLayout()!.computeIntrinsicWidthConstraints()
    let walker = InlineWalker(root: self)
    while !walker.atEnd() {
      let renderer = walker.current()
      renderer!.setPreferredLogicalWidthsDirty(shouldBeDirty: false)
      if let renderText = renderer as? RenderTextWrapper {
        renderText.resetMinMaxWidth()
      }
      walker.advance()
    }
    return intrinsicWidthConstraints
  }

  private func setStaticPositionsForSimpleOutOfFlowContent() {
    assert(childrenInline())
    #if !NDEBUG
      assert(!hasLineIfEmpty())
      let walker_ = InlineWalker(root: self)
      while !walker_.atEnd() {
        if walker_.current()!.style().isDisplayInlineType() {
          assert(hasSimpleStaticPositionForInlineLevelOutOfFlowChildrenByStyle(rootStyle: style()))
          break
        }
        walker_.advance()
      }
    #endif
    // We have nothing but out-of-flow boxes so we don't need to run the actual line layout.
    // Instead, we can just set the static positions to the point where all these boxes would end up.
    // This is a common case when using transforms to animate positioned boxes.
    let staticPosition = LayoutPointWrapper(x: borderAndPaddingStart(), y: borderAndPaddingBefore())

    let walker = InlineWalker(root: self)
    while !walker.atEnd() {
      let renderer = walker.current() as! RenderBoxWrapper
      let layer = renderer.layer()!

      assert(renderer.isOutOfFlowPositioned())

      let previousStaticPosition = LayoutPointWrapper(
        x: layer.staticInlinePosition(), y: layer.staticBlockPosition())
      let delta = staticPosition - previousStaticPosition
      let hasStaticInlinePositioning = renderer.style().hasStaticInlinePosition(
        horizontal: isHorizontalWritingMode())

      layer.setStaticInlinePosition(position: staticPosition.x)
      layer.setStaticBlockPosition(position: staticPosition.y)

      if !delta.isZero() && hasStaticInlinePositioning {
        renderer.setChildNeedsLayout(markParents: .MarkOnlyThis)
        renderer.layoutIfNeeded()
      }

      walker.advance()
    }
  }

  private func adjustIntrinsicLogicalWidthsForColumns(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    if style().hasAutoColumnCount() && style().hasAutoColumnWidth() {
      return
    }
    // The min/max intrinsic widths calculated really tell how much space elements need when
    // laid out inside the columns. In order to eventually end up with the desired column width,
    // we need to convert them to values pertaining to the multicol container.
    let columnCount = style().hasAutoColumnCount() ? 1 : Int32(style().columnCount())
    var columnWidth = LayoutUnit()
    let colGap = columnGap()
    let gapExtra = (columnCount - Int32(1)) * colGap
    if style().hasAutoColumnWidth() {
      minLogicalWidth = minLogicalWidth * columnCount + gapExtra
    } else {
      columnWidth = LayoutUnit(value: style().columnWidth())
      minLogicalWidth = min(minLogicalWidth, columnWidth)
    }
    // FIXME: If column-count is auto here, we should resolve it to calculate the maximum
    // intrinsic width, instead of pretending that it's 1. The only way to do that is by
    // performing a layout pass, but this is not an appropriate time or place for layout. The
    // good news is that if height is unconstrained and there are no explicit breaks, the
    // resolved column-count really should be 1.
    maxLogicalWidth = max(maxLogicalWidth, columnWidth) * columnCount + gapExtra
  }

  private func computeInlinePreferredLogicalWidths() -> (LayoutUnit, LayoutUnit) {
    assert(!shouldApplyInlineSizeContainment())

    if let (minLogicalWidth, maxLogicalWidth) = tryComputePreferredWidthsUsingInlinePath() {
      return (minLogicalWidth, maxLogicalWidth)
    }

    var inlineMax: Float32 = 0
    var inlineMin: Float32 = 0

    let styleToUse = style()
    // If we are at the start of a line, we want to ignore all white-space.
    // Also strip spaces if we previously had text that ended in a trailing space.
    var stripFrontSpaces = true
    var trailingSpaceChild: RenderObjectWrapper? = nil

    // Firefox and Opera will allow a table cell to grow to fit an image inside it under
    // very specific cirucumstances (in order to match common WinIE renderings).
    // Not supporting the quirk has caused us to mis-render some real sites. (See Bugzilla 10517.)
    let allowImagesToBreak =
      !document().inQuirksMode() || !isRenderTableCell()
      || !styleToUse.logicalWidth().isIntrinsicOrAuto()

    var oldAutoWrap = styleToUse.autoWrap()

    let childIterator = InlineMinMaxIterator(p: self)

    // Only gets added to the max preffered width once.
    var addedTextIndent = false
    // Signals the text indent was more negative than the min preferred width
    var hasRemainingNegativeTextIndent = false

    var textIndent = LayoutUnit()
    if styleToUse.textIndent().isFixed() {
      textIndent = LayoutUnit(value: styleToUse.textIndent().value())
    } else if let containingBlock = containingBlock(),
      containingBlock.style().logicalWidth().isFixed()
    {
      // At this point of the shrink-to-fit computatation, we don't have a used value for the containing block width
      // (that's exactly to what we try to contribute here) unless the computed value is fixed.
      textIndent = minimumValueForLength(
        length: styleToUse.textIndent(),
        maximumValue: containingBlock.style().logicalWidth().value())
    }
    var previousFloat: RenderObjectWrapper? = nil
    var isPrevChildInlineFlow = false
    var shouldBreakLineAfterText = false
    let canHangPunctuationAtStart = styleToUse.hangingPunctuation().contains(.First)
    let canHangPunctuationAtEnd = styleToUse.hangingPunctuation().contains(.Last)
    var lastText: RenderTextWrapper? = nil
    var rubyBaseMinimumMaximumWidthStack: [(LayoutUnit, LayoutUnit)] = []

    var addedStartPunctuationHang = false

    var minLogicalWidth = LayoutUnit()
    var maxLogicalWidth = LayoutUnit()

    while true {
      let child = childIterator.next()
      if child == nil {
        break
      }
      let autoWrap =
        child!.isReplacedOrInlineBlock()
        ? child!.parent()!.style().autoWrap() : child!.style().autoWrap()

      // Interlinear annotations don't participate in inline layout, but they put a minimum width requirement on the associated ruby base.
      let isInterlinearTypeAnnotation =
        child is RenderBlockWrapper && child!.style().display() == .RubyAnnotation
        && (!child!.style().isInterCharacterRubyPosition() || !styleToUse.isHorizontalWritingMode())
      if isInterlinearTypeAnnotation {
        let (annotationMinimumIntrinsicWidth, annotationMaximumIntrinsicWidth) =
          computeChildPreferredLogicalWidths(child: child!)

        if !rubyBaseMinimumMaximumWidthStack.isEmpty {
          // Annotation box is always preceded by the associated ruby base.
          let (baseMinimumWidth, baseMaximumWidth) = rubyBaseMinimumMaximumWidthStack.removeLast()
          inlineMin += max(
            0, annotationMinimumIntrinsicWidth.ceilToFloat() - baseMinimumWidth)
          inlineMax += max(
            0, annotationMaximumIntrinsicWidth.ceilToFloat() - baseMaximumWidth)
        } else {
          fatalError("Not reached")
        }
        continue
      }
      if !child!.isBR() {
        // Step One: determine whether or not we need to terminate our current line.
        // Each discrete chunk can become the new min-width, if it is the widest chunk
        // seen so far, and it can also become the max-width.

        // Children fall into three categories:
        // (1) An inline flow object. These objects always have a min/max of 0,
        // and are included in the iteration solely so that their margins can
        // be added in.
        //
        // (2) An inline non-text non-flow object, e.g., an inline replaced element.
        // These objects can always be on a line by themselves, so in this situation
        // we need to break the current line, and then add in our own margins and min/max
        // width on its own line, and then terminate the line.
        //
        // (3) A text object. Text runs can have breakable characters at the start,
        // the middle or the end. They may also lose whitespace off the front if
        // we're already ignoring whitespace. In order to compute accurate min-width
        // information, we need three pieces of information.
        // (a) the min-width of the first non-breakable run. Should be 0 if the text string
        // starts with whitespace.
        // (b) the min-width of the last non-breakable run. Should be 0 if the text string
        // ends with whitespace.
        // (c) the min/max width of the string (trimmed for whitespace).
        //
        // If the text string starts with whitespace, then we need to terminate our current line
        // (unless we're already in a whitespace stripping mode.
        //
        // If the text string has a breakable character in the middle, but didn't start
        // with whitespace, then we add the width of the first non-breakable run and
        // then end the current line. We then need to use the intermediate min/max width
        // values (if any of them are larger than our current min/max). We then look at
        // the width of the last non-breakable run and use that to start a new line
        // (unless we end in whitespace).
        let childStyle = child!.style()
        var childMin: Float32 = 0
        var childMax: Float32 = 0

        if !child!.isRenderText() {
          if child!.isLineBreakOpportunity() {
            minLogicalWidth = preferredWidth(preferredWidth: minLogicalWidth, result: inlineMin)
            inlineMin = 0
            continue
          }
          // Case (1) and (2). Inline replaced and inline flow elements.
          if let renderInline = child as? RenderInlineWrapper {
            // Add in padding/border/margin from the appropriate side of
            // the element.
            let bpm = getBorderPaddingMargin(
              child: renderInline, endOfInline: childIterator.endOfInline)
            childMin += bpm
            childMax += bpm

            if childStyle.display() == .RubyBase && !childIterator.endOfInline {
              rubyBaseMinimumMaximumWidthStack.append(
                (LayoutUnit(value: inlineMin), LayoutUnit(value: inlineMax)))
            }

            inlineMin += childMin
            inlineMax += childMax

            if childStyle.display() == .RubyBase && childIterator.endOfInline {
              if !rubyBaseMinimumMaximumWidthStack.isEmpty {
                let (rubyBaseStartMin, rubyBaseStartMax) = rubyBaseMinimumMaximumWidthStack.last!
                rubyBaseMinimumMaximumWidthStack[rubyBaseMinimumMaximumWidthStack.count - 1] = (
                  LayoutUnit(value: inlineMin - rubyBaseStartMin),
                  LayoutUnit(value: inlineMax - rubyBaseStartMax)
                )
              } else {
                fatalError("Not reached")
              }
            }

            child!.setPreferredLogicalWidthsDirty(shouldBeDirty: false)
          } else {
            // Inline replaced elts add in their margins to their min/max values.
            if !child!.isFloating() {
              lastText = nil
            }
            var margins = LayoutUnit()
            let startMargin = childStyle.marginStartUsing(otherStyle: style())
            let endMargin = childStyle.marginEndUsing(otherStyle: style())
            if startMargin.isFixed() {
              margins += LayoutUnit.fromFloatCeil(value: startMargin.value())
            }
            if endMargin.isFixed() {
              margins += LayoutUnit.fromFloatCeil(value: endMargin.value())
            }
            childMin += margins.ceilToFloat()
            childMax += margins.ceilToFloat()
          }
        }

        if !(child is RenderInlineWrapper) && !(child is RenderTextWrapper) {
          // Case (2). Inline replaced elements and floats.
          // Terminate the current line as far as minwidth is concerned.
          var childMinPreferredLogicalWidth = LayoutUnit()
          var childMaxPreferredLogicalWidth = LayoutUnit()
          if let box = child as? RenderBoxWrapper,
            child!.isHorizontalWritingMode() != isHorizontalWritingMode()
          {
            let extent = box.computeLogicalHeight(
              logicalHeight: box.borderAndPaddingLogicalHeight(), logicalTop: LayoutUnit(value: 0)
            ).extent
            childMinPreferredLogicalWidth = extent
            childMaxPreferredLogicalWidth = extent
          } else {
            (childMinPreferredLogicalWidth, childMaxPreferredLogicalWidth) =
              computeChildPreferredLogicalWidths(child: child!)
          }

          childMin += childMinPreferredLogicalWidth.ceilToFloat()
          childMax += childMaxPreferredLogicalWidth.ceilToFloat()

          var clearPreviousFloat = false
          if child!.isFloating() {
            let childClearValue = RenderStyleWrapper.usedClear(renderer: child!)
            if previousFloat != nil {
              let previousFloatValue = RenderStyleWrapper.usedFloat(renderer: previousFloat!)
              clearPreviousFloat =
                (previousFloatValue == .Left
                  && (childClearValue == .Left || childClearValue == .Both))
                || (previousFloatValue == .Right
                  && (childClearValue == .Right || childClearValue == .Both))
            }
            previousFloat = child
          }

          let canBreakReplacedElement = !child!.isImage() || allowImagesToBreak
          if (canBreakReplacedElement && (autoWrap || oldAutoWrap)
            && (!isPrevChildInlineFlow || shouldBreakLineAfterText)) || clearPreviousFloat
          {
            minLogicalWidth = preferredWidth(preferredWidth: minLogicalWidth, result: inlineMin)
            inlineMin = 0
          }

          // If we're supposed to clear the previous float, then terminate maxwidth as well.
          if clearPreviousFloat {
            maxLogicalWidth = preferredWidth(preferredWidth: maxLogicalWidth, result: inlineMax)
            inlineMax = 0
          }

          // Add in text-indent. This is added in only once.
          if !addedTextIndent && !child!.isFloating() {
            let ceiledIndent = LayoutUnit(value: textIndent.ceilToFloat())
            childMin += ceiledIndent
            childMax += ceiledIndent

            if childMin < 0 {
              textIndent = LayoutUnit.fromFloatCeil(value: childMin)
            } else {
              addedTextIndent = true
            }
          }

          if canHangPunctuationAtStart && !addedStartPunctuationHang && !child!.isFloating() {
            addedStartPunctuationHang = true
          }

          // Add our width to the max.
          inlineMax += max(0, childMax)

          if !autoWrap || !canBreakReplacedElement
            || (isPrevChildInlineFlow && !shouldBreakLineAfterText)
          {
            if child!.isFloating() {
              minLogicalWidth = preferredWidth(preferredWidth: minLogicalWidth, result: childMin)
            } else {
              inlineMin += childMin
            }
          } else {
            // Now check our line.
            minLogicalWidth = preferredWidth(preferredWidth: minLogicalWidth, result: childMin)

            // Now start a new line.
            inlineMin = 0
          }

          if autoWrap && canBreakReplacedElement && isPrevChildInlineFlow {
            minLogicalWidth = preferredWidth(preferredWidth: minLogicalWidth, result: inlineMin)
            inlineMin = 0
          }

          // We are no longer stripping whitespace at the start of a line.
          if !child!.isFloating() {
            stripFrontSpaces = false
            trailingSpaceChild = nil
            lastText = nil
          }
        } else if let renderText = child as? RenderTextWrapper {
          if renderText.style().hasTextCombine(),
            let renderCombineText = renderText as? RenderCombineTextWrapper
          {
            renderCombineText.combineTextIfNeeded()
          }

          // Determine if we have a breakable character. Pass in
          // whether or not we should ignore any spaces at the front
          // of the string. If those are going to be stripped out,
          // then they shouldn't be considered in the breakable char
          // check.
          let strippingBeginWS = stripFrontSpaces
          var widths = renderText.trimmedPreferredWidths(
            leadWidth: inlineMax, stripFrontSpaces: &stripFrontSpaces)

          childMin = widths.min
          childMax = widths.max

          // This text object will not be rendered, but it may still provide a breaking opportunity.
          if !widths.hasBreak && childMax == 0 {
            if autoWrap && (widths.beginWS || widths.endWS || widths.endZeroSpace) {
              minLogicalWidth = preferredWidth(preferredWidth: minLogicalWidth, result: inlineMin)
              inlineMin = 0
            }
            continue
          }

          lastText = renderText

          if stripFrontSpaces {
            trailingSpaceChild = child
          } else {
            trailingSpaceChild = nil
          }

          // Add in text-indent. This is added in only once.
          var ti: Float32 = 0
          if !addedTextIndent || hasRemainingNegativeTextIndent {
            ti = textIndent.ceilToFloat()
            childMin += ti
            widths.beginMin += ti

            // It the text indent negative and larger than the child minimum, we re-use the remainder
            // in future minimum calculations, but using the negative value again on the maximum
            // will lead to under-counting the max pref width.
            if !addedTextIndent {
              childMax += ti
              widths.beginMax += ti
              addedTextIndent = true
            }

            if childMin < 0 {
              textIndent = LayoutUnit(value: childMin)
              hasRemainingNegativeTextIndent = true
            }
          }

          // See if we have a hanging punctuation situation at the start.
          if canHangPunctuationAtStart && !addedStartPunctuationHang {
            let startIndex = strippingBeginWS ? renderText.firstCharacterIndexStrippingSpaces() : 0
            let hangStartWidth = renderText.hangablePunctuationStartWidth(index: startIndex)
            childMin -= hangStartWidth
            widths.beginMin -= hangStartWidth
            childMax -= hangStartWidth
            widths.beginMax -= hangStartWidth
            addedStartPunctuationHang = true
          }

          // If we have no breakable characters at all,
          // then this is the easy case. We add ourselves to the current
          // min and max and continue.
          if !widths.hasBreakableChar {
            inlineMin += childMin
          } else {
            // We have a breakable character. Now we need to know if
            // we start and end with whitespace.
            if widths.beginWS {
              // End the current line.
              minLogicalWidth = preferredWidth(preferredWidth: minLogicalWidth, result: inlineMin)
            } else {
              inlineMin += widths.beginMin
              minLogicalWidth = preferredWidth(preferredWidth: minLogicalWidth, result: inlineMin)
              childMin -= ti
            }

            inlineMin = childMin

            if widths.endWS || widths.endZeroSpace {
              // We end in breakable space, which means we can end our current line.
              minLogicalWidth = preferredWidth(preferredWidth: minLogicalWidth, result: inlineMin)
              inlineMin = 0
              shouldBreakLineAfterText = false
            } else {
              minLogicalWidth = preferredWidth(preferredWidth: minLogicalWidth, result: inlineMin)
              inlineMin = widths.endMin
              shouldBreakLineAfterText = true
            }
          }

          if widths.hasBreak {
            inlineMax += widths.beginMax
            maxLogicalWidth = preferredWidth(preferredWidth: maxLogicalWidth, result: inlineMax)
            maxLogicalWidth = preferredWidth(preferredWidth: maxLogicalWidth, result: childMax)
            inlineMax = widths.endMax
            addedTextIndent = true
            addedStartPunctuationHang = true
            if widths.endsWithBreak {
              stripFrontSpaces = true
            }
          } else {
            inlineMax += max(0, childMax)
          }
        }

        // Ignore spaces after a list marker.
        if child!.isRenderListMarker() {
          stripFrontSpaces = true
        }
      } else {
        if styleToUse.collapseWhiteSpace() {
          stripTrailingSpace(
            inlineMax: &inlineMax, inlineMin: &inlineMin, trailingSpaceChild: trailingSpaceChild)
        }
        minLogicalWidth = preferredWidth(preferredWidth: minLogicalWidth, result: inlineMin)
        maxLogicalWidth = preferredWidth(preferredWidth: maxLogicalWidth, result: inlineMax)
        inlineMin = 0
        inlineMax = 0
        stripFrontSpaces = true
        trailingSpaceChild = nil
        addedTextIndent = true
        addedStartPunctuationHang = true
      }

      if !child!.isRenderText() && child!.isRenderInline() {
        isPrevChildInlineFlow = true
      } else {
        isPrevChildInlineFlow = false
      }

      oldAutoWrap = autoWrap
    }

    if styleToUse.collapseWhiteSpace() {
      stripTrailingSpace(
        inlineMax: &inlineMax, inlineMin: &inlineMin, trailingSpaceChild: trailingSpaceChild)
    }

    if canHangPunctuationAtEnd && lastText != nil && lastText!.text().length() > 0 {
      let endIndex =
        CPtrToInt(trailingSpaceChild?.p) == CPtrToInt(lastText?.p)
        ? lastText!.lastCharacterIndexStrippingSpaces() : lastText!.text().length() - 1
      let endHangWidth = lastText!.hangablePunctuationEndWidth(index: endIndex)
      inlineMin -= endHangWidth
      inlineMax -= endHangWidth
    }

    return (
      preferredWidth(preferredWidth: minLogicalWidth, result: inlineMin),
      preferredWidth(preferredWidth: maxLogicalWidth, result: inlineMax)
    )
  }

  private func adjustInitialLetterPosition(
    childBox: RenderBoxWrapper, logicalTopOffset: inout LayoutUnit,
    marginBeforeOffset: inout LayoutUnit
  ) {
    let style = firstLineStyle()
    let fontMetrics = style.metricsOfPrimaryFont()
    if fontMetrics.capHeight() == nil {
      return
    }

    let heightOfLine = lineHeight(
      firstLine: true, direction: isHorizontalWritingMode() ? .HorizontalLine : .VerticalLine,
      linePositionMode: .PositionOfInteriorLineBoxes)
    let beforeMarginBorderPadding = childBox.borderAndPaddingBefore() + childBox.marginBefore()

    // Make an adjustment to align with the cap height of a theoretical block line.
    let adjustment =
      fontMetrics.intAscent() + (heightOfLine - fontMetrics.intHeight()) / 2
      - fontMetrics.intCapHeight() - beforeMarginBorderPadding
    logicalTopOffset += adjustment

    // For sunken and raised caps, we have to make some adjustments. Test if we're sunken or raised (dropHeightDelta will be
    // positive for raised and negative for sunken).
    let dropHeightDelta =
      childBox.style().initialLetterHeight() - childBox.style().initialLetterDrop()

    // If we're sunken, the float needs to shift down but lines still need to avoid it. In order to do that we increase the float's margin.
    if dropHeightDelta < 0 {
      marginBeforeOffset += -dropHeightDelta * heightOfLine
    }

    // If we're raised, then we actually have to grow the height of the block, since the lines have to be pushed down as though we're placing
    // empty lines beside the first letter.
    if dropHeightDelta > 0 {
      setLogicalHeight(size: logicalHeight() + dropHeightDelta * heightOfLine)
    }
  }

  private func selfCollapsingMarginBeforeWithClear(candidate: RenderObjectWrapper?) -> LayoutUnit? {
    let candidateBlockFlow = candidate as? RenderBlockFlowWrapper
    if candidateBlockFlow == nil {
      return nil
    }

    if !candidateBlockFlow!.isSelfCollapsingBlock() {
      return nil
    }

    if RenderStyleWrapper.usedClear(renderer: candidateBlockFlow!) == .None || !containsFloats() {
      return nil
    }

    let clear = getClearDelta(
      child: candidateBlockFlow!, logicalTop: candidateBlockFlow!.logicalHeight())
    // Just because a block box has the clear property set, it does not mean we always get clearance (e.g. when the box is below the cleared floats)
    if clear < candidateBlockFlow!.logicalBottom() {
      return nil
    }

    return marginValuesForChild(child: candidateBlockFlow!).positiveMarginBefore
  }

  func computeLineAdjustmentForPagination(
    lineBox: InlineIterator.LineBoxIterator, delta: LayoutUnit, floatMinimumBottom: LayoutUnit
  ) -> LinePaginationAdjustment {
    // FIXME: For now we paginate using line overflow. This ensures that lines don't overlap at all when we
    // put a strut between them for pagination purposes. However, this really isn't the desired rendering, since
    // the line on the top of the next page will appear too far down relative to the same kind of line at the top
    // of the first column.
    //
    // The rendering we would like to see is one where the lineTopWithLeading is at the top of the column, and any line overflow
    // simply spills out above the top of the column. This effect would match what happens at the top of the first column.
    // We can't achieve this rendering, however, until we stop columns from clipping to the column bounds (thus allowing
    // for overflow to occur), and then cache visible overflow for each column rect.
    //
    // Furthermore, the paint we have to do when a column has overflow has to be special. We need to exclude
    // content that paints in a previous column (and content that paints in the following column).
    //
    // For now we'll at least honor the lineTopWithLeading when paginating if it is above the logical top overflow. This will
    // at least make positive leading work in typical cases.
    //
    // FIXME: Another problem with simply moving lines is that the available line width may change (because of floats).
    // Technically if the location we move the line to has a different line width than our old position, then we need to dirty the
    // line and all following lines.
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
      // FIXME: We are still honoring gigantic margins, which does leave open the possibility of blank pages caused by this heuristic. It remains to be seen whether or not
      // this will be a real-world issue. For now we don't try to deal with this problem.
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

  func hasRareBlockFlowData() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rareBlockFlowData() -> RenderBlockFlowRareData {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func ensureRareBlockFlowData() -> RenderBlockFlowRareData {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
