/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003-2024 Apple Inc. All rights reserved.
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

import wk_interop

class RenderBoxWrapper: RenderBoxModelObjectWrapper {
  func y() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func width() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func height() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalLeft() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_logicalLeft(p))
  }

  func logicalHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func location() -> LayoutPointWrapper {
    let rawLocation = wk_interop.RenderBox_location(p)
    return LayoutPointWrapper(
      x: LayoutUnit.fromRawValue(value: rawLocation.x),
      y: LayoutUnit.fromRawValue(value: rawLocation.y))
  }

  func locationOffset() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func size() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLocation(p: LayoutPointWrapper) {
    wk_interop.RenderBox_setLocation(self.p, p.x.rawValue(), p.y.rawValue())
  }

  func move(dx: LayoutUnit, dy: LayoutUnit) {
    wk_interop.RenderBox_move(p, dx.rawValue(), dy.rawValue())
  }

  func frameRect() -> LayoutRectWrapper {
    let raw = wk_interop.RenderBox_frameRect(p)
    return LayoutRectWrapper(
      x: LayoutUnit.fromRawValue(value: raw.x),
      y: LayoutUnit.fromRawValue(value: raw.y),
      width: LayoutUnit.fromRawValue(value: raw.width),
      height: LayoutUnit.fromRawValue(value: raw.height))
  }

  func visualOverflowRect() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addLayoutOverflow(rect: LayoutRectWrapper) {
    wk_interop.RenderBox_addLayoutOverflow(
      p,
      LayoutRectRaw(
        x: rect.x().rawValue(),
        y: rect.y().rawValue(),
        width: rect.width().rawValue(),
        height: rect.height().rawValue()))
  }

  func addVisualOverflow(rect: LayoutRectWrapper) {
    wk_interop.RenderBox_addVisualOverflow(
      p,
      LayoutRectRaw(
        x: rect.x().rawValue(),
        y: rect.y().rawValue(),
        width: rect.width().rawValue(),
        height: rect.height().rawValue()))
  }

  func contentWidth() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_contentWidth(p))
  }

  func contentHeight() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_contentHeight(p))
  }

  func contentLogicalSize() -> LayoutSizeWrapper {
    let width = LayoutUnit.fromRawValue(value: wk_interop.RenderBox_contentLogicalSize_width(p))
    let height = LayoutUnit.fromRawValue(value: wk_interop.RenderBox_contentLogicalSize_height(p))
    return LayoutSizeWrapper(width: width, height: height)
  }

  func paddingBoxWidth() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_paddingBoxWidth(p))
  }

  func paddingBoxHeight() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_paddingBoxHeight(p))
  }

  func paddingBoxRectIncludingScrollbar() -> LayoutRectWrapper {
    return LayoutRectWrapper(
      x: LayoutUnit.fromRawValue(value: wk_interop.RenderBox_paddingBoxRectIncludingScrollbar_x(p)),
      y: LayoutUnit.fromRawValue(value: wk_interop.RenderBox_paddingBoxRectIncludingScrollbar_y(p)),
      width: LayoutUnit.fromRawValue(
        value: wk_interop.RenderBox_paddingBoxRectIncludingScrollbar_width(p)),
      height: LayoutUnit.fromRawValue(
        value: wk_interop.RenderBox_paddingBoxRectIncludingScrollbar_height(p))
    )
  }

  func collapsedMarginAfter() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setOverridingLogicalWidthLength(height: LengthWrapper) {
    wk_interop.RenderBox_setOverridingLogicalWidthLength(p, height.p)
  }

  func clearOverridingLogicalWidthLength() {
    wk_interop.RenderBox_clearOverridingLogicalWidthLength(p)
  }

  func repaintDuringLayoutIfMoved(oldRect: LayoutRectWrapper) {
    wk_interop.RenderBox_repaintDuringLayoutIfMoved(
      p,
      LayoutRectRaw(
        x: oldRect.x().rawValue(),
        y: oldRect.y().rawValue(),
        width: oldRect.width().rawValue(),
        height: oldRect.height().rawValue()))
  }

  func availableLogicalWidth() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBox_availableLogicalWidth(p))
  }

  func isUnsplittableForPagination() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overflowClipRect(
    location: LayoutPointWrapper, fragment: RenderFragmentContainerWrapper? = nil
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pushContentsClip(paintInfo: PaintInfoWrapper, accumulatedOffset: LayoutPointWrapper) -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func popContentsClip(
    paintInfo: PaintInfoWrapper, originalPhase: PaintPhase, accumulatedOffset: LayoutPointWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintBoxDecorations(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintMask(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintClippingMask(paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func markForPaginationRelayoutIfNeeded() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func flipForWritingModeForChild(child: RenderBoxWrapper, point: LayoutPointWrapper)
    -> LayoutPointWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func flipForWritingMode(position: LayoutPointWrapper) -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func flipForWritingMode(rect: LayoutRectWrapper) {
    wk_interop.RenderBox_flipForWritingMode(
      p, LayoutPointRaw(x: rect.x().rawValue(), y: rect.y().rawValue()))
  }

  func flipForWritingMode(rect: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalVisualOverflowRectForPropagation(style: RenderStyleWrapper) -> LayoutRectWrapper {
    if style.p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    let raw = wk_interop.RenderBox_logicalVisualOverflowRectForPropagation(p, style.p)
    return LayoutRectWrapper(
      x: LayoutUnit.fromRawValue(value: raw.x),
      y: LayoutUnit.fromRawValue(value: raw.y),
      width: LayoutUnit.fromRawValue(value: raw.width),
      height: LayoutUnit.fromRawValue(value: raw.height))
  }

  func layoutOverflowRectForPropagation(style: RenderStyleWrapper) -> LayoutRectWrapper {
    if style.p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    let raw = wk_interop.RenderBox_layoutOverflowRectForPropagation(p, style.p)
    return LayoutRectWrapper(
      x: LayoutUnit.fromRawValue(value: raw.x),
      y: LayoutUnit.fromRawValue(value: raw.y),
      width: LayoutUnit.fromRawValue(value: raw.width),
      height: LayoutUnit.fromRawValue(value: raw.height))
  }

  func hasVisualOverflow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollPosition() -> ScrollPosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasRelativeDimensions() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFlexItem() -> Bool { return wk_interop.RenderBox_isFlexItem(p) }

  func shapeOutsideInfo() -> ShapeOutsideInfoWrapper? {
    if let unwrapped = wk_interop.RenderBox_shapeOutsideInfo(p) {
      return ShapeOutsideInfoWrapper(p: unwrapped)
    }
    return nil
  }
}
