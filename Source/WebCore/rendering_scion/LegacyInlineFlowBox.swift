/*
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
 */

class LegacyInlineFlowBox: LegacyInlineBox {
  init(_ renderer: RenderBoxModelObjectWrapper) {
    super.init(renderer)
  }

  func renderer() -> RenderBoxModelObjectWrapper {
    return rendererObject() as! RenderBoxModelObjectWrapper
  }

  func prevLineBox() -> LegacyInlineFlowBox? { return m_prevLineBox }

  func nextLineBox() -> LegacyInlineFlowBox? { return m_nextLineBox }

  func firstChild() -> LegacyInlineBox? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func lastChild() -> LegacyInlineBox? {
    // TODO(asuhan): add consistency check
    return m_lastChild
  }

  override func adjustPosition(_ dx: Float32, _ dy: Float32) {
    super.adjustPosition(dx, dy)
    var child = firstChild()
    while child != nil {
      child!.adjustPosition(dx, dy)
      child = child!.nextOnLine()
    }
    overflow?.move(LayoutUnit(value: dx), LayoutUnit(value: dy))
  }

  override func paint(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, lineTop: LayoutUnit,
    lineBottom: LayoutUnit
  ) {
    if paintInfo.phase != .Foreground && paintInfo.phase != .Selection
      && paintInfo.phase != .Outline && paintInfo.phase != .SelfOutline
      && paintInfo.phase != .ChildOutlines && paintInfo.phase != .TextClip
      && paintInfo.phase != .Mask && paintInfo.phase != .EventRegion
      && paintInfo.phase != .Accessibility
    {
      return
    }

    var overflowRect = visualOverflowRect(lineTop: lineTop, lineBottom: lineBottom)
    flipForWritingMode(rect: &overflowRect)
    overflowRect.moveBy(offset: paintOffset)

    if !paintInfo.rect.intersects(
      other: LayoutRectWrapper(rect: snappedIntRect(rect: overflowRect)))
    {
      return
    }

    if paintInfo.phase != .ChildOutlines {
      let painter = InlineBoxPainter(
        inlineBox: self, paintInfo: paintInfo, paintOffset: paintOffset)
      painter.paint()
    }

    if paintInfo.phase == .Mask {
      return
    }

    let paintPhase = paintInfo.phase == .ChildOutlines ? .Outline : paintInfo.phase
    let childInfo = paintInfo.deepCopy()
    childInfo.phase = paintPhase
    childInfo.updateSubtreePaintRootForChildren(renderer: renderer())

    // Paint our children.
    if paintPhase != .SelfOutline {
      var curr = firstChild()
      while curr != nil {
        if curr!.rendererObject().isRenderText() || !curr!.boxModelObject()!.hasSelfPaintingLayer()
        {
          curr!.paint(
            paintInfo: childInfo, paintOffset: paintOffset, lineTop: lineTop, lineBottom: lineBottom
          )
        }
        curr = curr!.nextOnLine()
      }
    }
  }

  override func nodeAtPoint(
    _ request: HitTestRequestWrapper, _ result: inout HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ lineTop: LayoutUnit, _ lineBottom: LayoutUnit, _ hitTestAction: HitTestAction
  ) -> Bool {
    if hitTestAction != .HitTestForeground {
      return false
    }

    var overflowRect: LayoutRectWrapper = visualOverflowRect(
      lineTop: lineTop, lineBottom: lineBottom)
    overflowRect.moveBy(offset: accumulatedOffset)
    if !locationInContainer.intersects(rect: overflowRect) {
      return false
    }

    // Check children first.
    var child = lastChild()
    while child != nil {
      if child!.renderer is RenderTextWrapper || !child!.boxModelObject()!.hasSelfPaintingLayer() {
        if child!.nodeAtPoint(
          request, &result, locationInContainer, accumulatedOffset, lineTop, lineBottom,
          hitTestAction)
        {
          renderer().updateHitTestResult(
            result: &result,
            point: locationInContainer.point() - toLayoutSize(point: accumulatedOffset))
          return true
        }
      }
      child = child!.previousOnLine()
    }

    // Now check ourselves. Pixel snap hit testing.
    if !renderer().visibleToHitTesting(request: request) {
      return false
    }

    // Move x/y to our coordinates.
    var rect = frameRect()
    flipForWritingMode(rect: &rect)
    rect.moveBy(delta: accumulatedOffset.FloatPoint())

    if locationInContainer.intersects(rect) {
      renderer().updateHitTestResult(
        result: &result,
        point: flipForWritingMode(
          locationInContainer.point() - toLayoutSize(point: accumulatedOffset)))  // Don't add in m_x or m_y here, we want coords in the containing block's space.
      if result.addNodeToListBasedTestResult(
        node: renderer().protectedNodeForHitTest(), request: request,
        locationInContainer: locationInContainer, rect: rect) == .Stop
      {
        return true
      }
    }

    return false
  }

  override func selectionState() -> RenderObjectWrapper.HighlightState { return .None }

  func visualOverflowRect(lineTop: LayoutUnit, lineBottom: LayoutUnit) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalLeftVisualOverflow() -> LayoutUnit {
    return overflow != nil
      ? (isHorizontal() ? overflow!.visualOverflowRect().x() : overflow!.visualOverflowRect().y())
      : LayoutUnit(value: logicalLeft())
  }

  func logicalRightVisualOverflow() -> LayoutUnit {
    return overflow != nil
      ? (isHorizontal()
        ? overflow!.visualOverflowRect().maxX() : overflow!.visualOverflowRect().maxY())
      : LayoutUnit(value: logicalRight().rounded(.up))
  }

  func logicalTopVisualOverflow(lineTop: LayoutUnit) -> LayoutUnit {
    if let overflow = overflow {
      return isHorizontal() ? overflow.visualOverflowRect().y() : overflow.visualOverflowRect().x()
    }
    return lineTop
  }

  func logicalBottomVisualOverflow(lineBottom: LayoutUnit) -> LayoutUnit {
    if let overflow = overflow {
      return isHorizontal()
        ? overflow.visualOverflowRect().maxY() : overflow.visualOverflowRect().maxX()
    }
    return lineBottom
  }

  override final func isInlineFlowBox() -> Bool { return true }

  // Whether or not this line uses alphabetic or ideographic baselines by default.
  let m_baselineType: FontBaseline = .AlphabeticBaseline

  private let overflow: RenderOverflow? = nil

  private let m_lastChild: LegacyInlineBox? = nil

  let m_prevLineBox: LegacyInlineFlowBox? = nil  // The previous box that also uses our RenderObject
  let m_nextLineBox: LegacyInlineFlowBox? = nil  // The next box that also uses our RenderObject
}
