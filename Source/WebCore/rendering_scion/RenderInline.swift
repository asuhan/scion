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

  override func clippedOverflowRect(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ context: VisibleRectContext
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func rectsForRepaintingAfterLayout(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ repaintOutlineBounds: RepaintOutlineBounds
  ) -> RepaintRects {
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
}
