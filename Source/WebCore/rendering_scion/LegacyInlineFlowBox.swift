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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextLineBox() -> LegacyInlineFlowBox? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func firstChild() -> LegacyInlineBox? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func adjustPosition(_ dx: Float32, _ dy: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    var childInfo = paintInfo
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

  override func selectionState() -> RenderObjectWrapper.HighlightState {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func visualOverflowRect(lineTop: LayoutUnit, lineBottom: LayoutUnit) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalLeftVisualOverflow() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalRightVisualOverflow() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private let overflow: RenderOverflow? = nil
}
