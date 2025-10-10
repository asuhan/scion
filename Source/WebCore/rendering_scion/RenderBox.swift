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

enum OverlayScrollbarSizeRelevancy {
  case IgnoreOverlayScrollbarSize
  case IncludeOverlayScrollbarSize
}

class RenderBoxWrapper: RenderBoxModelObjectWrapper {
  func requiresLayerWithScrollableArea() -> Bool {
    // FIXME: This is wrong; these boxes' layers should not need ScrollableAreas via RenderLayer.
    if isRenderView() || isDocumentElementRenderer() {
      return true
    }

    if hasPotentiallyScrollableOverflow() {
      return true
    }

    if style().resize() != .None {
      return true
    }

    if isHTMLMarquee() && style().marqueeBehavior() != .None {
      return true
    }

    return false
  }

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

  func borderBoxRect() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The content area of the box (excludes padding - and intrinsic padding for table cells, etc... - and border).
  func contentBoxRect() -> LayoutRectWrapper {
    var verticalScrollbarWidth = LayoutUnit(value: UInt64(0))
    var horizontalScrollbarHeight = LayoutUnit(value: UInt64(0))
    var leftScrollbarSpace = LayoutUnit(value: UInt64(0))
    var topScrollbarSpace = LayoutUnit(value: UInt64(0))

    if hasNonVisibleOverflow() {
      verticalScrollbarWidth = LayoutUnit(value: self.verticalScrollbarWidth())
      horizontalScrollbarHeight = LayoutUnit(value: self.horizontalScrollbarHeight())

      let bothEdgeScrollbarGutters = style().scrollbarGutter().bothEdges

      if shouldPlaceVerticalScrollbarOnLeft() || bothEdgeScrollbarGutters {
        leftScrollbarSpace = verticalScrollbarWidth
      }
      // FIXME: It's wrong that scrollbar-gutter: both-edges affects height: webkit.org/b/266938
      if bothEdgeScrollbarGutters {
        topScrollbarSpace = horizontalScrollbarHeight
      }
    }

    let padding = self.padding()
    let borderWidths = self.borderWidths()
    let location = LayoutPointWrapper(
      x: borderWidths.left + padding.left + leftScrollbarSpace,
      y: borderWidths.top + padding.top + topScrollbarSpace)

    let zero = LayoutUnit(value: UInt64(0))
    let paddingBoxWidth = max(
      zero, width() - borderWidths.left - borderWidths.right - verticalScrollbarWidth)
    let paddingBoxHeight = max(
      zero, height() - borderWidths.top - borderWidths.bottom - horizontalScrollbarHeight)

    let width = max(zero, paddingBoxWidth - padding.left - padding.right - leftScrollbarSpace)
    let height = max(zero, paddingBoxHeight - padding.top - padding.bottom - topScrollbarSpace)

    let size = LayoutSizeWrapper(width: width, height: height)

    return LayoutRectWrapper(location: location, size: size)
  }

  func firstChildBox() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextSiblingBox() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layoutOverflowRect() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func reflectionOffset() -> Int32 {
    if style().boxReflect() == nil {
      return 0
    }
    if style().boxReflect()!.direction() == .Left || style().boxReflect()!.direction() == .Right {
      return valueForLength(
        length: style().boxReflect()!.offset(), maximumValue: borderBoxRect().width()
      ).int()
    }
    return valueForLength(
      length: style().boxReflect()!.offset(), maximumValue: borderBoxRect().height()
    ).int()
  }

  // Given a rect in the object's coordinate space, returns the corresponding rect in the reflection.
  func reflectedRect(r: LayoutRectWrapper) -> LayoutRectWrapper {
    if style().boxReflect() == nil {
      return LayoutRectWrapper()
    }

    let box = borderBoxRect()
    var result = r
    switch style().boxReflect()!.direction() {
    case .Below:
      result.setY(y: box.maxY() + reflectionOffset() + (box.maxY() - r.maxY()))
    case .Above:
      result.setY(y: box.y() - reflectionOffset() - box.height() + (box.maxY() - r.maxY()))
    case .Left:
      result.setX(x: box.x() - reflectionOffset() - box.width() + (box.maxX() - r.maxX()))
    case .Right:
      result.setX(x: box.maxX() + reflectionOffset() + (box.maxX() - r.maxX()))
      break
    }
    return result
  }

  func setOverridingLogicalWidthLength(height: LengthWrapper) {
    wk_interop.RenderBox_setOverridingLogicalWidthLength(p, height.p)
  }

  func clearOverridingLogicalWidthLength() {
    wk_interop.RenderBox_clearOverridingLogicalWidthLength(p)
  }

  enum RenderBoxFragmentInfoFlags {
    case CacheRenderBoxFragmentInfo
    case DoNotCacheRenderBoxFragmentInfo
  }

  func borderBoxRectInFragment(
    fragment: RenderFragmentContainerWrapper?,
    flags: RenderBoxWrapper.RenderBoxFragmentInfoFlags = .CacheRenderBoxFragmentInfo
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func verticalScrollbarWidth() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func horizontalScrollbarHeight() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isUnsplittableForPagination() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overflowClipRect(
    location: LayoutPointWrapper, fragment: RenderFragmentContainerWrapper? = nil,
    relevancy: OverlayScrollbarSizeRelevancy = .IgnoreOverlayScrollbarSize,
    phase: PaintPhase = .BlockBackground
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overflowClipRectForChildLayers(
    location: LayoutPointWrapper, fragment: RenderFragmentContainerWrapper?,
    relevancy: OverlayScrollbarSizeRelevancy
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pushContentsClip(paintInfo: PaintInfoWrapper, accumulatedOffset: LayoutPointWrapper) -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipRect(location: LayoutPointWrapper, fragment: RenderFragmentContainerWrapper?)
    -> LayoutRectWrapper
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

  func maskClipRect(paintOffset: LayoutPointWrapper) -> LayoutRectWrapper {
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

  func flipForWritingMode(position: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func flipForWritingMode(position: LayoutPointWrapper) -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func flipForWritingMode(rect: inout LayoutRectWrapper) {
    wk_interop.RenderBox_flipForWritingMode(
      p, LayoutPointRaw(x: rect.x().rawValue(), y: rect.y().rawValue()))
  }

  func flipForWritingMode(rect: inout FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // These represent your location relative to your container as a physical offset.
  // In layout related methods you almost always want the logical location (e.g. x() and y()).
  func topLeftLocation() -> LayoutPointWrapper {
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

  func updateFloatPainterAfterSelfPaintingLayerChange() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shapeOutsideInfo() -> ShapeOutsideInfoWrapper? {
    if let unwrapped = wk_interop.RenderBox_shapeOutsideInfo(p) {
      return ShapeOutsideInfoWrapper(p: unwrapped)
    }
    return nil
  }
}
