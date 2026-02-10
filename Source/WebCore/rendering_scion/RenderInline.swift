/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2004, 2005, 2006, 2007, 2008, 2009 Apple Inc. All rights reserved.
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
 *
 */

private func inFlowPositionedInlineAncestor(_ p: RenderElementWrapper?) -> RenderElementWrapper? {
  var p = p
  while p != nil && p!.isRenderInline() {
    if p!.isInFlowPositioned() {
      return p
    }
    p = p!.parent()
  }
  return nil
}

private func updateStyleOfAnonymousBlockContinuations(
  _ block: RenderBlockWrapper, _ newStyle: RenderStyleWrapper, _ oldStyle: RenderStyleWrapper?
) {
  // If any descendant blocks exist then they will be in the next anonymous block and its siblings.
  var box = block.nextSiblingBox()
  while box != nil && box!.isAnonymousBlock() {
    if box!.style().position() == newStyle.position() {
      continue
    }

    guard let block = box as? RenderBlockWrapper else { continue }
    if !block.isContinuation() {
      continue
    }

    // If we are no longer in-flow positioned but our descendant block(s) still have an in-flow positioned ancestor then
    // their containing anonymous block should keep its in-flow positioning.
    let continuation = block.inlineContinuation()
    if oldStyle!.hasInFlowPosition() && inFlowPositionedInlineAncestor(continuation) != nil {
      continue
    }
    let blockStyle = RenderStyleWrapper.createAnonymousStyleWithDisplay(
      parentStyle: block.style(), display: .Block)
    blockStyle.setPosition(v: newStyle.position())
    block.setStyle(style: blockStyle)
    box = box!.nextSiblingBox()
  }
}

private func computeMargin(_ renderer: RenderInlineWrapper?, _ margin: LengthWrapper) -> LayoutUnit
{
  if margin.isAuto() {
    return LayoutUnit(value: 0)
  }
  if margin.isFixed() {
    return LayoutUnit(value: margin.value())
  }
  if margin.isPercentOrCalculated() {
    return minimumValueForLength(
      length: margin,
      maximumValue: max(LayoutUnit(value: 0), renderer!.containingBlock()!.availableLogicalWidth()))
  }
  return LayoutUnit(value: 0)
}

private class AbsoluteRectsGeneratorContext {
  init(_ rects: ArraySlice<LayoutRectWrapper>, _ accumulatedOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addRect(_ rect: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

private class AbsoluteRectsIgnoringEmptyGeneratorContext: AbsoluteRectsGeneratorContext {
  override init(_ rects: ArraySlice<LayoutRectWrapper>, _ accumulatedOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func addRect(_ rect: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

class RenderInlineWrapper: RenderBoxModelObjectWrapper {
  override init(p: UnsafeMutableRawPointer?) {
    if p != nil {
      super.init(p: p!)
    } else {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  init(type: `Type`, element: ElementWrapper, style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  init(type: `Type`, document: Document, style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func marginLeft() -> LayoutUnit {
    return computeMargin(self, style().marginLeft())
  }

  override func marginBottom() -> LayoutUnit {
    return computeMargin(self, style().marginBottom())
  }

  override func marginBefore(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    return computeMargin(self, style().marginBeforeUsing(otherStyle: otherStyle ?? style()))
  }

  override func marginAfter(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    return computeMargin(self, style().marginAfterUsing(otherStyle: otherStyle ?? style()))
  }

  override final func offsetFromContainer(
    _ enclosingContainer: RenderElementWrapper, _ physicalPoint: LayoutPointWrapper,
    _ offsetDependsOnPoint: inout Bool?
  ) -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func innerPaddingBoxWidth() -> LayoutUnit {
    var firstInlineBoxPaddingBoxLeft = LayoutUnit()
    var lastInlineBoxPaddingBoxRight = LayoutUnit()

    if LayoutIntegration.LineLayout.containing(renderer: self) != nil {
      let inlineBox = InlineIterator.firstInlineBoxFor(renderInline: self)
      if inlineBox.bool() {
        if style().isLeftToRightDirection() {
          firstInlineBoxPaddingBoxLeft =
            LayoutUnit(value: inlineBox.get().logicalLeftIgnoringInlineDirection() + borderStart())
          while inlineBox.get().nextInlineBox().bool() {
            inlineBox.traverseNextInlineBox()
          }
          assert(inlineBox.bool())
          lastInlineBoxPaddingBoxRight =
            LayoutUnit(value: inlineBox.get().logicalRightIgnoringInlineDirection() - borderEnd())
        } else {
          lastInlineBoxPaddingBoxRight = LayoutUnit(
            value: inlineBox.get().logicalRightIgnoringInlineDirection() - borderStart())
          while inlineBox.get().nextInlineBox().bool() {
            inlineBox.traverseNextInlineBox()
          }
          assert(inlineBox.bool())
          firstInlineBoxPaddingBoxLeft =
            LayoutUnit(value: inlineBox.get().logicalLeftIgnoringInlineDirection() + borderEnd())
        }
        return max(
          LayoutUnit(value: UInt64(0)), lastInlineBoxPaddingBoxRight - firstInlineBoxPaddingBoxLeft)
      }
      return LayoutUnit()
    }

    guard let firstInlineBox = firstLegacyInlineBox() else { return LayoutUnit() }
    guard let lastInlineBox = lastLegacyInlineBox() else { return LayoutUnit() }

    if style().isLeftToRightDirection() {
      firstInlineBoxPaddingBoxLeft = LayoutUnit(value: firstInlineBox.logicalLeft())
      lastInlineBoxPaddingBoxRight = LayoutUnit(value: lastInlineBox.logicalRight())
    } else {
      lastInlineBoxPaddingBoxRight = LayoutUnit(value: firstInlineBox.logicalRight())
      firstInlineBoxPaddingBoxLeft = LayoutUnit(value: lastInlineBox.logicalLeft())
    }
    return max(
      LayoutUnit(value: UInt64(0)), lastInlineBoxPaddingBoxRight - firstInlineBoxPaddingBoxLeft)
  }

  func innerPaddingBoxHeight() -> LayoutUnit {
    var innerPaddingBoxLogicalHeight = LayoutUnit(
      value: isHorizontalWritingMode() ? linesBoundingBox().height() : linesBoundingBox().width())
    innerPaddingBoxLogicalHeight -= (borderBefore() + borderAfter())
    return innerPaddingBoxLogicalHeight
  }

  private func linesBoundingBox() -> IntRect {
    if let layout = LayoutIntegration.LineLayout.containing(renderer: self) {
      if layoutBox() == nil || !layout.contains(renderer: self) {
        // Repaint may be issued on subtrees during content mutation with newly inserted renderers
        // (or we just forgot to initiate layout before querying geometry on stale content after moving inline boxes between blocks).
        assert(needsLayout())
        return IntRect()
      }
      return enclosingIntRect(rect: layout.enclosingBorderBoxRectFor(renderInline: self))
    }

    // See <rdar://problem/5289721>, for an unknown reason the linked list here is sometimes inconsistent, first is non-zero and last is zero.  We have been
    // unable to reproduce this at all (and consequently unable to figure ot why this is happening).  The assert will hopefully catch the problem in debug
    // builds and help us someday figure out why.  We also put in a redundant check of lastLineBox() to avoid the crash for now.
    assert((firstLegacyInlineBox() == nil) == (lastLegacyInlineBox() == nil))  // Either both are null or both exist.
    if firstLegacyInlineBox() == nil || lastLegacyInlineBox() == nil {
      return IntRect()
    }

    // Return the width of the minimal left side and the maximal right side.
    var logicalLeftSide: Float32 = 0
    var logicalRightSide: Float32 = 0
    var curr = firstLegacyInlineBox()
    while curr != nil {
      if curr === firstLegacyInlineBox() || curr!.logicalLeft() < logicalLeftSide {
        logicalLeftSide = curr!.logicalLeft()
      }
      if curr === firstLegacyInlineBox() || curr!.logicalRight() > logicalRightSide {
        logicalRightSide = curr!.logicalRight()
      }
      curr = curr!.nextLineBox()
    }

    let isHorizontal = style().isHorizontalWritingMode()

    let x = isHorizontal ? logicalLeftSide : firstLegacyInlineBox()!.x()
    let y = isHorizontal ? firstLegacyInlineBox()!.y() : logicalLeftSide
    let width =
      isHorizontal ? logicalRightSide - logicalLeftSide : lastLegacyInlineBox()!.logicalBottom() - x
    let height =
      isHorizontal ? lastLegacyInlineBox()!.logicalBottom() - y : logicalRightSide - logicalLeftSide
    return enclosingIntRect(rect: FloatRectWrapper(x: x, y: y, width: width, height: height))
  }

  func linesVisualOverflowBoundingBox() -> LayoutRectWrapper {
    if let layout = LayoutIntegration.LineLayout.containing(renderer: self) {
      if layoutBox() == nil {
        // Repaint may be issued on subtrees during content mutation with newly inserted renderers.
        assert(needsLayout())
        return LayoutRectWrapper()
      }
      return layout.visualOverflowBoundingBoxRectFor(renderInline: self)
    }

    if firstLegacyInlineBox() == nil || lastLegacyInlineBox() == nil {
      return LayoutRectWrapper()
    }

    // Return the width of the minimal left side and the maximal right side.
    var logicalLeftSide = LayoutUnit.max()
    var logicalRightSide = LayoutUnit.min()
    var curr = firstLegacyInlineBox()
    while curr != nil {
      logicalLeftSide = min(logicalLeftSide, curr!.logicalLeftVisualOverflow())
      logicalRightSide = max(logicalRightSide, curr!.logicalRightVisualOverflow())
      curr = curr!.nextLineBox()
    }

    let firstRootBox = firstLegacyInlineBox()!.root()
    let lastRootBox = lastLegacyInlineBox()!.root()

    let logicalTop = firstLegacyInlineBox()!.logicalTopVisualOverflow(lineTop: firstRootBox.lineTop)
    let logicalWidth = logicalRightSide - logicalLeftSide
    let logicalHeight =
      lastLegacyInlineBox()!.logicalBottomVisualOverflow(lineBottom: lastRootBox.lineBottom)
      - logicalTop

    var rect = LayoutRectWrapper(
      x: logicalLeftSide, y: logicalTop, width: logicalWidth, height: logicalHeight)
    if !style().isHorizontalWritingMode() {
      rect = rect.transposedRect()
    }
    return rect
  }

  func firstLegacyInlineBox() -> LegacyInlineFlowBox? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastLegacyInlineBox() -> LegacyInlineFlowBox? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func offsetForInFlowPositionedInline(_ child: RenderBoxWrapper?) -> LayoutSizeWrapper {
    // FIXME: This function isn't right with mixed writing modes.

    assert(isInFlowPositioned())
    if !isInFlowPositioned() {
      return LayoutSizeWrapper()
    }

    // When we have an enclosing relpositioned inline, we need to add in the offset of the first line
    // box from the rest of the content, but only in the cases where we know we're positioned
    // relative to the inline itself.
    var inlinePosition = layer()!.staticInlinePosition()
    var blockPosition = layer()!.staticBlockPosition()
    if let inlineBox = firstLegacyInlineBox() {
      inlinePosition = LayoutUnit.fromFloatRound(value: inlineBox.logicalLeft())
      blockPosition = LayoutUnit(value: inlineBox.logicalTop())
    } else if LayoutIntegration.LineLayout.containing(renderer: self) != nil {
      if layoutBox() == nil {
        // Repaint may be issued on subtrees during content mutation with newly inserted renderers.
        assert(needsLayout())
        return LayoutSizeWrapper()
      }
      let inlineBox = InlineIterator.firstInlineBoxFor(renderInline: self)
      if inlineBox.bool() {
        inlinePosition = LayoutUnit.fromFloatRound(
          value: inlineBox.get().logicalLeftIgnoringInlineDirection())
        blockPosition = LayoutUnit(value: inlineBox.get().logicalTop())
      }
    }

    // Per http://www.w3.org/TR/CSS2/visudet.html#abs-non-replaced-width an absolute positioned box with a static position
    // should locate itself as though it is a normal flow box in relation to its containing block.
    let logicalOffset = LayoutSizeWrapper()
    if !child!.style().hasStaticInlinePosition(horizontal: style().isHorizontalWritingMode()) {
      logicalOffset.setWidth(width: inlinePosition)
    }

    if !child!.style().hasStaticBlockPosition(horizontal: style().isHorizontalWritingMode()) {
      logicalOffset.setHeight(height: blockPosition)
    }

    return style().isHorizontalWritingMode() ? logicalOffset : logicalOffset.transposedSize()
  }

  override func addFocusRingRects(
    rects: inout [LayoutRectWrapper], additionalOffset: LayoutPointWrapper,
    paintContainer: RenderLayerModelObjectWrapper? = nil
  ) {
    let context = AbsoluteRectsIgnoringEmptyGeneratorContext(rects[...], additionalOffset)
    generateLineBoxRects(context)

    for child: RenderElementWrapper in childrenOfType(parent: self) {
      if child is RenderListMarkerWrapper {
        continue
      }
      var pos = additionalOffset.FloatPoint()
      // FIXME: This doesn't work correctly with transforms.
      if child.hasLayer() {
        pos = child.localToContainerPoint(localPoint: FloatPoint(), container: paintContainer)
      } else if let box = child as? RenderBoxWrapper {
        pos.move(box.locationOffset().FloatSize())
      }
      child.addFocusRingRects(
        rects: &rects, additionalOffset: LayoutPointWrapper(point: flooredIntPoint(pos)),
        paintContainer: paintContainer
      )
    }

    guard let continuation = continuation() else { return }
    if continuation.isInline() {
      continuation.addFocusRingRects(
        rects: &rects,
        additionalOffset: flooredLayoutPoint(
          p: LayoutPointWrapper(
            size: additionalOffset + continuation.containingBlock()!.location()
              - containingBlock()!.location()
          ).FloatPoint()), paintContainer: paintContainer)
    } else {
      continuation.addFocusRingRects(
        rects: &rects,
        additionalOffset: flooredLayoutPoint(
          p: LayoutPointWrapper(
            size: additionalOffset + (continuation as! RenderBoxWrapper).location()
              - containingBlock()!.location()
          ).FloatPoint()), paintContainer: paintContainer)
    }
  }

  func paintOutline(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if !hasOutline() {
      return
    }

    let styleToUse = style()
    // Only paint the focus ring by hand if the theme isn't able to draw it.
    if styleToUse.outlineStyleIsAuto() == .On && !theme().supportsFocusRing(style: styleToUse) {
      var focusRingRects: [LayoutRectWrapper] = []
      addFocusRingRects(
        rects: &focusRingRects, additionalOffset: paintOffset,
        paintContainer: paintInfo.paintContainer)
      paintFocusRing(paintInfo: paintInfo, style: styleToUse, focusRingRects: focusRingRects[...])
    }

    if hasOutlineAnnotation() && styleToUse.outlineStyleIsAuto() == .Off
      && !theme().supportsFocusRing(style: styleToUse)
    {
      addPDFURLRect(paintInfo: paintInfo, paintOffset: paintOffset)
    }

    let graphicsContext = paintInfo.context()
    if graphicsContext.paintingDisabled() {
      return
    }

    if styleToUse.outlineStyleIsAuto() == .On || !styleToUse.hasOutline() {
      return
    }

    if containingBlock() == nil {
      fatalError("Not reached")
    }

    let isHorizontalWritingMode = isHorizontalWritingMode()
    let containingBlock = containingBlock()!
    let isFlippedBlocksWritingMode = containingBlock.style().isFlippedBlocksWritingMode()
    var rects: [LayoutRectWrapper] = []
    let box = InlineIterator.firstInlineBoxFor(renderInline: self)
    while box.bool() {
      let lineBox = box.get().lineBox()
      let logicalTop = max(lineBox.get().contentLogicalTop(), box.get().logicalTop())
      box.traverseNextInlineBox()
      let logicalBottom = min(lineBox.get().contentLogicalBottom(), box.get().logicalBottom())
      var enclosingVisualRect = FloatRectWrapper(
        x: box.get().logicalLeftIgnoringInlineDirection(), y: logicalTop,
        width: box.get().logicalWidth(), height: logicalBottom - logicalTop)

      if !isHorizontalWritingMode {
        enclosingVisualRect = enclosingVisualRect.transposedRect()
      }

      if isFlippedBlocksWritingMode {
        containingBlock.flipForWritingMode(rect: &enclosingVisualRect)
      }

      rects.append(LayoutRectWrapper(r: enclosingVisualRect))
    }
    let painter = BorderPainter(renderer: self, paintInfo: paintInfo)
    painter.paintOutline(paintOffset, rects[...])
  }

  override func requiresLayer() -> Bool {
    return isInFlowPositioned() || createsGroup() || hasClipPath() || shouldApplyPaintContainment()
      || willChangeCreatesStackingContext() || hasRunningAcceleratedAnimations()
      || requiresRenderingConsolidationForViewTransition()
  }

  override func styleWillChange(diff: StyleDifference, newStyle: RenderStyleWrapper) {
    super.styleWillChange(diff: diff, newStyle: newStyle)
    // RenderInlines forward their absolute positioned descendants to their (non-anonymous) containing block.
    // Check if this non-anonymous containing block can hold the absolute positioned elements when the inline is no longer positioned.
    if canContainAbsolutelyPositionedObjects() && newStyle.position() == .Static,
      let container = RenderObjectWrapper.containingBlockForPositionType(
        positionType: .Absolute, renderer: self), !container.canContainAbsolutelyPositionedObjects()
    {
      container.removePositionedObjects(
        newContainingBlockCandidate: nil, containingBlockState: .NewContainingBlock)
    }
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)

    // Ensure that all of the split inlines pick up the new style. We
    // only do this if we're an inline, since we don't want to propagate
    // a block's style to the other inlines.
    // e.g., <font>foo <h4>goo</h4> moo</font>.  The <font> inlines before
    // and after the block share the same style, but the block doesn't
    // need to pass its style on to anyone else.
    let newStyle = style()
    if let continuation = inlineContinuation(), !isContinuation() {
      var currCont: RenderInlineWrapper? = continuation
      while currCont != nil {
        currCont!.setStyle(style: RenderStyleWrapper.clone(style: newStyle))
        currCont = currCont!.inlineContinuation()
      }
      // If an inline's in-flow positioning has changed and it is part of an active continuation as a descendant of an anonymous containing block,
      // then any descendant blocks will need to change their in-flow positioning accordingly.
      // Do this by updating the position of the descendant blocks' containing anonymous blocks - there may be more than one.
      if containingBlock()!.isAnonymousBlock() && oldStyle != nil
        && newStyle.position() != oldStyle!.position()
        && (newStyle.hasInFlowPosition() || oldStyle!.hasInFlowPosition())
      {
        updateStyleOfAnonymousBlockContinuations(containingBlock()!, newStyle, oldStyle)
      }
    }

    propagateStyleToAnonymousChildren(propagationType: .AllChildren)
  }

  override func updateFromStyle() {
    super.updateFromStyle()

    // FIXME: Support transforms and reflections on inline flows someday.
    setHasTransformRelatedProperty(false)
    setHasReflection(false)
  }

  private func generateLineBoxRects(_ context: AbsoluteRectsGeneratorContext) {
    if let lineLayout = LayoutIntegration.LineLayout.containing(renderer: self) {
      let inlineBoxRects = lineLayout.collectInlineBoxRects(renderInline: self)
      if inlineBoxRects.isEmpty {
        context.addRect(FloatRectWrapper())
        return
      }
      for inlineBoxRect in inlineBoxRects {
        context.addRect(inlineBoxRect)
      }
      return
    }
    var curr = firstLegacyInlineBox()
    if curr == nil {
      context.addRect(FloatRectWrapper())
      return
    }
    while curr != nil {
      context.addRect(FloatRectWrapper(location: curr!.topLeft(), size: curr!.size()))
      curr = curr!.nextLineBox()
    }
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if let lineLayout = LayoutIntegration.LineLayout.containing(renderer: self) {
      lineLayout.paint(paintInfo: paintInfo, paintOffset: paintOffset, layerRenderer: self)
      return
    }
    legacyLineBoxes!.paint(renderer: self, paintInfo: paintInfo, paintOffset: paintOffset)
  }

  override func clippedOverflowRect(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ context: VisibleRectContext
  ) -> LayoutRectWrapper {
    // Only first-letter renderers are allowed in here during layout. They mutate the tree triggering repaints.
    #if !NDEBUG
      let insideSelfPaintingInlineBox = { [self] () in
        if hasSelfPaintingLayer() {
          return true
        }
        let containingBlock = self.containingBlock()
        var ancestor = parent()
        while ancestor != nil && CPtrToInt(ancestor?.p) != CPtrToInt(containingBlock?.p) {
          if ancestor!.hasSelfPaintingLayer() {
            return true
          }
          ancestor = ancestor!.parent()
        }
        return false
      }
      assert(
        !view().frameView().layoutContext().isPaintOffsetCacheEnabled()
          || style().pseudoElementType() == .FirstLetter || insideSelfPaintingInlineBox())
    #endif

    let knownEmpty = { [self] () in
      if firstLegacyInlineBox() != nil {
        return false
      }
      if continuation() != nil {
        return false
      }
      if LayoutIntegration.LineLayout.containing(renderer: self) != nil {
        return false
      }
      return true
    }

    if knownEmpty() {
      return LayoutRectWrapper()
    }

    var repaintRect = linesVisualOverflowBoundingBox()
    var hitRepaintContainer = false

    // We need to add in the in-flow position offsets of any inlines (including us) up to our
    // containing block.
    let containingBlock = self.containingBlock()
    var inlineFlow: RenderElementWrapper? = self
    while inlineFlow != nil {
      guard let renderInline = inlineFlow as? RenderInlineWrapper else { break }
      if CPtrToInt(inlineFlow!.p) == CPtrToInt(containingBlock?.p) {
        break
      }
      if CPtrToInt(inlineFlow!.p) == CPtrToInt(repaintContainer?.p) {
        hitRepaintContainer = true
        break
      }
      if inlineFlow!.style().hasInFlowPosition() && inlineFlow!.hasLayer() {
        repaintRect.move(size: renderInline.layer()!.offsetForInFlowPosition())
      }
      inlineFlow = inlineFlow!.parent()
    }

    let outlineSize = LayoutUnit(value: style().outlineSize())
    repaintRect.inflate(d: outlineSize)

    if hitRepaintContainer || containingBlock == nil {
      return repaintRect
    }

    var rects = RepaintRects(rect: repaintRect)

    if containingBlock!.hasNonVisibleOverflow() {
      containingBlock!.applyCachedClipAndScrollPosition(&rects, repaintContainer, context)
    }

    rects = containingBlock!.computeRects(rects, repaintContainer, context)
    repaintRect = rects.clippedOverflowRect

    if outlineSize.bool() {
      for child: RenderElementWrapper in childrenOfType(parent: self) {
        repaintRect.unite(other: child.rectWithOutlineForRepaint(repaintContainer, outlineSize))
      }

      if let continuation = self.continuation(),
        !continuation.isInline() && continuation.parent() != nil
      {
        repaintRect.unite(
          other: continuation.rectWithOutlineForRepaint(repaintContainer, outlineSize))
      }
    }

    return repaintRect
  }

  override func rectsForRepaintingAfterLayout(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ repaintOutlineBounds: RepaintOutlineBounds
  ) -> RepaintRects {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func rectWithOutlineForRepaint(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ outlineWidth: LayoutUnit
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func computeVisibleRectsInContainer(
    _ rects: RepaintRects, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> RepaintRects? {
    // Repaint offset cache is only valid for root-relative repainting
    if view().frameView().layoutContext().isPaintOffsetCacheEnabled() && container == nil
      && !context.options.contains(.UseEdgeInclusiveIntersection)
    {
      return computeVisibleRectsUsingPaintOffset(rects)
    }

    if CPtrToInt(container?.p) == CPtrToInt(p) {
      return rects
    }

    let (localContainer, containerSkipped) = self.container(container)
    if localContainer == nil {
      return rects
    }

    var adjustedRects = rects
    if style().hasInFlowPosition() && layer() != nil {
      // Apply the in-flow position offset when invalidating a rectangle. The layer
      // is translated, but the render box isn't, so we need to do this to get the
      // right dirty rect. Since this is called from RenderObject::setStyle, the relative or sticky position
      // flag on the RenderObject has been cleared, so use the one on the style().
      let offsetForInFlowPosition = layer()!.offsetForInFlowPosition()
      adjustedRects.move(offsetForInFlowPosition)
    }

    var context = context
    if localContainer!.hasNonVisibleOverflow() {
      // FIXME: Respect the value of context.options.
      let _ = SetForScope(
        scopedVariable: &context.options,
        newValue: context.options.union(.ApplyCompositedContainerScrolls))
      let isEmpty = !(localContainer! as! RenderLayerModelObjectWrapper)
        .applyCachedClipAndScrollPosition(&adjustedRects, container, context)
      if isEmpty {
        if context.options.contains(.UseEdgeInclusiveIntersection) {
          return nil
        }
        return adjustedRects
      }
    }

    if containerSkipped {
      // If the repaintContainer is below o, then we need to map the rect into repaintContainer's coordinates.
      let containerOffset = container!.offsetFromAncestorContainer(localContainer!)
      adjustedRects.move(-containerOffset)
      return adjustedRects
    }

    return localContainer!.computeVisibleRectsInContainer(adjustedRects, container, context)
  }

  private func computeVisibleRectsUsingPaintOffset(_ rects: RepaintRects) -> RepaintRects? {
    var adjustedRects = rects
    let layoutState = view().frameView().layoutContext().layoutState()!
    if style().hasInFlowPosition() && layer() != nil {
      adjustedRects.move(layer()!.offsetForInFlowPosition())
    }
    adjustedRects.move(layoutState.paintOffset())
    if layoutState.isClipped() {
      adjustedRects.clippedOverflowRect.intersect(other: layoutState.clipRect())
    }
    return adjustedRects
  }

  override func mapLocalToContainer(
    _ ancestorContainer: RenderLayerModelObjectWrapper?, _ transformState: TransformState,
    _ mode: MapCoordinatesMode, _ wasFixed: inout Bool?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func pushMappingToContainer(
    _ ancestorToStopAt: RenderLayerModelObjectWrapper?, _ geometryMap: RenderGeometryMap
  ) -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func frameRectForStickyPositioning() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func lineHeight(
    firstLine: Bool, direction: LineDirectionMode,
    linePositionMode: LinePositionMode = .PositionOnContainingLine
  )
    -> LayoutUnit
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func willChangeCreatesStackingContext() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // All of the line boxes created for this svg inline.
  private let legacyLineBoxes: RenderLineBoxList? = nil
}
