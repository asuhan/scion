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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
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
