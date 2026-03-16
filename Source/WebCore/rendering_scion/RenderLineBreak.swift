/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2013 Apple Inc. All rights reserved.
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

class RenderLineBreakWrapper: RenderBoxModelObjectWrapper {
  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(isNativeImpl())
  }

  override final func positionForPoint(
    _ point: LayoutPointWrapper, _ source: HitTestSource,
    _ fragment: RenderFragmentContainerWrapper?
  ) -> VisiblePosition {
    assert(isNativeImpl())
    return createVisiblePosition(0, .Downstream)
  }

  override final func caretMinOffset() -> Int32 {
    assert(isNativeImpl())
    return 0
  }

  override final func caretMaxOffset() -> Int32 {
    assert(isNativeImpl())
    return 1
  }

  override final func canBeSelectionLeaf() -> Bool {
    assert(isNativeImpl())
    return true
  }

  override func lineHeight(
    firstLine: Bool, direction: LineDirectionMode,
    linePositionMode: LinePositionMode = .PositionOnContainingLine
  )
    -> LayoutUnit
  {
    assert(isNativeImpl())
    if firstLine {
      let firstLineStyle = firstLineStyle()
      if CPtrToInt(firstLineStyle.p) != CPtrToInt(style().p) {
        return LayoutUnit.fromFloatCeil(value: firstLineStyle.computedLineHeight())
      }
    }

    if cachedLineHeight == nil {
      cachedLineHeight = LayoutUnit.fromFloatCeil(value: style().computedLineHeight())
    }
    return cachedLineHeight!
  }

  override func marginBottom() -> LayoutUnit {
    assert(isNativeImpl())
    return LayoutUnit(value: 0)
  }

  override func marginLeft() -> LayoutUnit {
    assert(isNativeImpl())
    return LayoutUnit(value: 0)
  }

  override func marginBefore(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    assert(isNativeImpl())
    return LayoutUnit(value: 0)
  }

  override func marginAfter(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    assert(isNativeImpl())
    return LayoutUnit(value: 0)
  }

  override func frameRectForStickyPositioning() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func localRectsForRepaint(_ repaintOutlineBounds: RepaintOutlineBounds) -> RepaintRects {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func updateFromStyle() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var cachedLineHeight: LayoutUnit? = nil
}
