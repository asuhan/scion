/*
 * Copyright (C) 2006-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2019 Adobe. All rights reserved.
 * Copyright (C) 2014 Google. All rights reserved.
 * Copyright (C) 2020 Igalia S.L.
 *
 * Portions are Copyright (C) 1998 Netscape Communications Corporation.
 *
 * Other contributors:
 *   Robert O'Callahan <roc+@cs.cmu.edu>
 *   David Baron <dbaron@fas.harvard.edu>
 *   Christian Biesinger <cbiesinger@web.de>
 *   Randall Jesup <rjesup@wgate.com>
 *   Roland Mainz <roland.mainz@informatik.med.uni-giessen.de>
 *   Josh Soref <timeless@mac.com>
 *   Boris Zbarsky <bzbarsky@mit.edu>
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA
 *
 * Alternatively, the contents of this file may be used under the terms
 * of either the Mozilla Public License Version 1.1, found at
 * http://www.mozilla.org/MPL/ (the "MPL") or the GNU General Public
 * License Version 2.0, found at http://www.fsf.org/copyleft/gpl.html
 * (the "GPL"), in which case the provisions of the MPL or the GPL are
 * applicable instead of those above.  If you wish to allow use of your
 * version of this file only under the terms of one of those two
 * licenses (the MPL or the GPL) and not to allow others to use your
 * version of this file under the LGPL, indicate your decision by
 * deletingthe provisions above and replace them with the notice and
 * other provisions required by the MPL or the GPL, as the case may be.
 * If you do not delete the provisions above, a recipient may use your
 * version of this file under any of the LGPL, the MPL or the GPL.
 */

final class RenderLayerScrollableArea: ScrollableAreaWrapper {
  init(layer: RenderLayerWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clear() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marquee() -> RenderMarqueeWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func createOrDestroyMarquee() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func restoreScrollPosition() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollWidth() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scrollHeight() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasScrollableHorizontalOverflow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasScrollableVerticalOverflow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasScrollbars() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasVerticalScrollbar() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func scrollbarGutterStyle() -> ScrollbarGutter {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func scrollbarWidthStyle() -> ScrollbarWidth {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns true when the layer could do touch scrolling, but doesn't look at whether there is actually scrollable overflow.
  func canUseCompositedScrolling() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func verticalScrollbarWidth(
    relevancy: OverlayScrollbarSizeRelevancy = .IgnoreOverlayScrollbarSize,
    isHorizontalWritingMode: Bool = true
  ) -> Int32 {
    if vBar != nil && vBar!.isOverlayScrollbar()
      && (relevancy == .IgnoreOverlayScrollbarSize || !vBar!.shouldParticipateInHitTesting())
    {
      return 0
    }

    if vBar == nil && isHorizontalWritingMode
      && !(scrollbarGutterStyle().isAuto || ScrollbarTheme.theme().usesOverlayScrollbars())
    {
      return ScrollbarTheme.theme().scrollbarThickness(scrollbarWidth: scrollbarWidthStyle())
    }

    if vBar == nil || !showsOverflowControls() {
      return 0
    }

    return vBar!.width()
  }

  func horizontalScrollbarHeight(
    relevancy: OverlayScrollbarSizeRelevancy = .IgnoreOverlayScrollbarSize,
    isHorizontalWritingMode: Bool = true
  ) -> Int32 {
    if hBar != nil && hBar!.isOverlayScrollbar()
      && (relevancy == .IgnoreOverlayScrollbarSize || !hBar!.shouldParticipateInHitTesting())
    {
      return 0
    }

    if hBar == nil && !isHorizontalWritingMode
      && !(scrollbarGutterStyle().isAuto || ScrollbarTheme.theme().usesOverlayScrollbars())
    {
      return ScrollbarTheme.theme().scrollbarThickness(scrollbarWidth: scrollbarWidthStyle())
    }

    if hBar == nil || !showsOverflowControls() {
      return 0
    }

    return hBar!.height()
  }

  func paintOverflowControls(
    context: GraphicsContextWrapper, paintOffset: IntPoint, damageRect: IntRect,
    paintingOverlayControls: Bool = false
  ) {
    // Don't do anything if we have no overflow.
    let renderer = m_layer.renderer()
    if !renderer.hasNonVisibleOverflow() {
      return
    }

    if !showsOverflowControls() {
      return
    }

    // Overlay scrollbars paint in a second pass through the layer tree so that they will paint
    // on top of everything else. If this is the normal painting pass, paintingOverlayControls
    // will be false, and we should just tell the root layer that there are overlay scrollbars
    // that need to be painted. That will cause the second pass through the layer tree to run,
    // and we'll paint the scrollbars then. In the meantime, cache tx and ty so that the
    // second pass doesn't need to re-enter the RenderTree to get it right.
    if hasOverlayScrollbars() && !paintingOverlayControls {
      cachedOverlayScrollbarOffset = paintOffset

      // It's not necessary to do the second pass if the scrollbars paint into layers.
      if (hBar != nil && layerForHorizontalScrollbar() != nil)
        || (vBar != nil && layerForVerticalScrollbar() != nil)
      {
        return
      }
      var localDamageRect = damageRect
      localDamageRect.moveBy(offset: -paintOffset)
      if !overflowControlsIntersectRect(localRect: localDamageRect) {
        return
      }

      var paintingRoot = m_layer.enclosingCompositingLayer()
      if paintingRoot == nil {
        paintingRoot = renderer.view().layer()
      }

      if let scrollableArea = paintingRoot!.scrollableArea() {
        scrollableArea.containsDirtyOverlayScrollbars = true
      }
      return
    }

    // This check is required to avoid painting custom CSS scrollbars twice.
    if paintingOverlayControls && !hasOverlayScrollbars() {
      return
    }

    var adjustedPaintOffset = paintOffset
    if paintingOverlayControls {
      adjustedPaintOffset = cachedOverlayScrollbarOffset
    }

    // Move the scrollbar widgets if necessary. We normally move and resize widgets during layout, but sometimes
    // widgets can move without layout occurring (most notably when you scroll a document that
    // contains fixed positioned elements).
    positionOverflowControls(offsetFromRoot: toIntSize(adjustedPaintOffset))

    // Now that we're sure the scrollbars are in the right place, paint them.
    if hBar != nil && layerForHorizontalScrollbar() == nil {
      hBar!.paint(context, damageRect)
    }
    if vBar != nil && layerForVerticalScrollbar() == nil {
      vBar!.paint(context, damageRect)
    }

    if layerForScrollCorner() != nil {
      return
    }

    // We fill our scroll corner with white if we have a scrollbar that doesn't run all the way up to the
    // edge of the box.
    paintScrollCorner(context: context, paintOffset: adjustedPaintOffset, damageRect: damageRect)

    // Paint our resizer last, since it sits on top of the scroll corner.
    paintResizer(
      context: context, paintOffset: LayoutPointWrapper(point: adjustedPaintOffset),
      damageRect: LayoutRectWrapper(rect: damageRect))
  }

  private func paintScrollCorner(
    context: GraphicsContextWrapper, paintOffset: IntPoint, damageRect: IntRect
  ) {
    var absRect = scrollCornerRect()
    absRect.moveBy(offset: paintOffset)
    if !absRect.intersects(other: damageRect) {
      return
    }

    if context.invalidatingControlTints() {
      updateScrollCornerStyle()
      return
    }

    if scrollCorner != nil {
      scrollCorner!.paintIntoRect(
        graphicsContext: context, paintOffset: LayoutPointWrapper(point: paintOffset),
        rect: LayoutRectWrapper(rect: absRect))
      return
    }

    // We don't want to paint a corner if we have overlay scrollbars, since we need
    // to see what is behind it.
    if !hasOverlayScrollbars() {
      ScrollbarTheme.theme().paintScrollCorner(self, context, absRect)
    }
  }

  private func paintResizer(
    context: GraphicsContextWrapper, paintOffset: LayoutPointWrapper, damageRect: LayoutRectWrapper
  ) {
    let renderer = m_layer.renderer()
    if renderer.style().resize() == .None {
      return
    }

    let rects = overflowControlsRects()

    var resizerAbsRect = LayoutRectWrapper(rect: rects.resizer)
    resizerAbsRect.moveBy(offset: paintOffset)
    if !resizerAbsRect.intersects(other: damageRect) {
      return
    }

    if context.invalidatingControlTints() {
      updateResizerStyle()
      return
    }

    if resizer != nil {
      resizer!.paintIntoRect(
        graphicsContext: context, paintOffset: paintOffset, rect: resizerAbsRect)
      return
    }

    drawPlatformResizerImage(context: context, resizerCornerRect: resizerAbsRect)

    // Draw a frame around the resizer (1px grey line) if there are any scrollbars present.
    // Clipping will exclude the right and bottom edges of this frame.
    if !hasOverlayScrollbars() && (vBar != nil || hBar != nil)
      && renderer.style().scrollbarWidth() != .None
    {
      let _ = GraphicsContextStateSaver(context: context)
      context.clip(rect: resizerAbsRect.FloatRect())
      var largerCorner = resizerAbsRect
      let one = LayoutUnit(value: UInt64(1))
      largerCorner.setSize(
        size: LayoutSizeWrapper(
          width: largerCorner.width() + one, height: largerCorner.height() + one))
      context.setStrokeColor(
        color: ColorWrapper(SRGBA(red: UInt8(217), green: UInt8(217), blue: UInt8(217))))
      context.setStrokeThickness(thickness: 1.0)
      context.setFillColor(color: .transparentBlack)
      context.drawRect(rect: FloatRectWrapper(r: snappedIntRect(rect: largerCorner)))
    }
  }

  override func layerForHorizontalScrollbar() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layerForVerticalScrollbar() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func usesCompositedScrolling() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private final func shouldPlaceVerticalScrollbarOnLeft() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateScrollbarsAfterStyleChange(oldStyle: RenderStyleWrapper?) {
    // Overflow is a box concept.
    let box = m_layer.renderBox()
    if box == nil {
      return
    }

    // List box parts handle the scrollbars by themselves so we have nothing to do.
    if box!.style().usedAppearance() == .Listbox {
      return
    }

    let hadVerticalScrollbar = hasVerticalScrollbar()
    updateScrollbarPresenceAndState()
    let hasVerticalScrollbar = hasVerticalScrollbar()

    if hadVerticalScrollbar != hasVerticalScrollbar
      || (hasVerticalScrollbar && oldStyle != nil
        && oldStyle!.shouldPlaceVerticalScrollbarOnLeft()
          != box!.style().shouldPlaceVerticalScrollbarOnLeft())
    {
      computeScrollOrigin()
    }

    if !scrollDimensionsDirty {
      updateScrollableAreaSet(hasScrollableHorizontalOverflow() || hasScrollableVerticalOverflow())
    }
  }

  private func positionOverflowControls(offsetFromRoot: IntSize) {
    if hBar == nil && vBar == nil && !m_layer.canResize() {
      return
    }

    if m_layer.renderBox() == nil {
      return
    }

    var rects = overflowControlsRects()

    if vBar != nil {
      rects.verticalScrollbar.move(offsetFromRoot)
      vBar!.setFrameRect(rects.verticalScrollbar)
    }

    if hBar != nil {
      rects.horizontalScrollbar.move(offsetFromRoot)
      hBar!.setFrameRect(rects.horizontalScrollbar)
    }

    if scrollCorner != nil {
      scrollCorner!.setFrameRect(rect: LayoutRectWrapper(rect: rects.scrollCorner))
    }

    if resizer != nil {
      resizer!.setFrameRect(rect: LayoutRectWrapper(rect: rects.resizer))
    }
  }

  func updateAllScrollbarRelatedStyle() {
    if hBar != nil {
      hBar!.styleChanged()
    }
    if vBar != nil {
      vBar!.styleChanged()
    }
    updateScrollCornerStyle()
    updateResizerStyle()
  }

  private func overflowControlsRects() -> RenderLayerWrapper.OverflowControlRects {
    let renderBox = m_layer.renderer() as! RenderBoxWrapper
    // Scrollbars sit inside the border box.
    let overflowControlsPositioningRect = snappedIntRect(
      rect: renderBox.paddingBoxRectIncludingScrollbar())

    let horizontalScrollbarHeight = hBar?.height() ?? 0
    let verticalScrollbarWidth = vBar?.width() ?? 0

    let isNonOverlayScrollbar = { (scrollbar: Scrollbar?) in
      return scrollbar != nil && !scrollbar!.isOverlayScrollbar()
    }

    let haveNonOverlayHorizontalScrollbar = isNonOverlayScrollbar(hBar)
    let haveNonOverlayVerticalScrollbar = isNonOverlayScrollbar(vBar)
    let placeVerticalScrollbarOnTheLeft = shouldPlaceVerticalScrollbarOnLeft()
    let haveResizer = renderBox.style().resize() != .None
    let scrollbarsAvoidCorner =
      ((haveNonOverlayHorizontalScrollbar && haveNonOverlayVerticalScrollbar)
        || (haveResizer && (haveNonOverlayHorizontalScrollbar || haveNonOverlayVerticalScrollbar)))
      && renderBox.style().scrollbarWidth() != .None

    // If only one scrollbar is present, the corner is square.
    let cornerSize =
      scrollbarsAvoidCorner
      ? IntSize(
        width: verticalScrollbarWidth != 0 ? verticalScrollbarWidth : horizontalScrollbarHeight,
        height: horizontalScrollbarHeight != 0 ? horizontalScrollbarHeight : verticalScrollbarWidth)
      : IntSize()

    var result = RenderLayerWrapper.OverflowControlRects()

    if hBar != nil {
      var barRect = overflowControlsPositioningRect
      barRect.shiftYEdgeTo(barRect.maxY() - horizontalScrollbarHeight)
      if scrollbarsAvoidCorner {
        if placeVerticalScrollbarOnTheLeft {
          barRect.shiftXEdgeTo(barRect.x() + cornerSize.width)
        } else {
          barRect.contract(dw: cornerSize.width, dh: 0)
        }
      }

      result.horizontalScrollbar = barRect
    }

    if vBar != nil {
      var barRect = overflowControlsPositioningRect
      if placeVerticalScrollbarOnTheLeft {
        barRect.setWidth(width: verticalScrollbarWidth)
      } else {
        barRect.shiftXEdgeTo(barRect.maxX() - verticalScrollbarWidth)
      }

      if scrollbarsAvoidCorner {
        barRect.contract(dw: 0, dh: cornerSize.height)
      }

      result.verticalScrollbar = barRect
    }

    let cornerRect = { (cornerSize: IntSize) in
      if placeVerticalScrollbarOnTheLeft {
        let bottomLeftCorner = overflowControlsPositioningRect.minXMaxYCorner()
        return IntRect(
          location: IntPoint(x: bottomLeftCorner.x, y: bottomLeftCorner.y - cornerSize.height),
          size: cornerSize)
      }
      return IntRect(
        location: overflowControlsPositioningRect.maxXMaxYCorner() - cornerSize, size: cornerSize)
    }

    if scrollbarsAvoidCorner {
      result.scrollCorner = cornerRect(cornerSize)
    }

    if haveResizer {
      if scrollbarsAvoidCorner {
        result.resizer = result.scrollCorner
      } else {
        let scrollbarThickness = ScrollbarTheme.theme().scrollbarThickness()
        result.resizer = cornerRect(IntSize(width: scrollbarThickness, height: scrollbarThickness))
      }
    }

    return result
  }

  private func overflowControlsIntersectRect(localRect: IntRect) -> Bool {
    let rects = overflowControlsRects()

    if rects.horizontalScrollbar.intersects(other: localRect) {
      return true
    }

    if rects.verticalScrollbar.intersects(other: localRect) {
      return true
    }

    if rects.scrollCorner.intersects(other: localRect) {
      return true
    }

    if rects.resizer.intersects(other: localRect) {
      return true
    }

    return false
  }

  func computeHasCompositedScrollableOverflow(layoutUpToDate: LayoutUpToDate) {
    var hasCompositedScrollableOverflow = m_hasCompositedScrollableOverflow

    switch layoutUpToDate {
    case .No:
      // If layout is not up to date, the only thing we can reliably know is that style prevents overflow scrolling.
      if !canUseCompositedScrolling() {
        hasCompositedScrollableOverflow = false
      }
    case .Yes:
      hasCompositedScrollableOverflow =
        canUseCompositedScrolling()
        && (hasScrollableHorizontalOverflow() || hasScrollableVerticalOverflow())
    }

    if hasCompositedScrollableOverflow == m_hasCompositedScrollableOverflow {
      return
    }

    // Whether this layer does composited scrolling affects the configuration of descendant sticky layers. We have to
    // dirty from the enclosing stacking context because overflow scroll doesn't create stacking context so those
    // containing block descendants may not be paint-order descendants, and the compositing dirty bits on RenderLayer act in paint order.
    if let paintParent = m_layer.stackingContext() {
      paintParent.setDescendantsNeedUpdateBackingAndHierarchyTraversal()
    }

    m_hasCompositedScrollableOverflow = hasCompositedScrollableOverflow
    if m_hasCompositedScrollableOverflow {
      m_layer.compositor().layerGainedCompositedScrollableOverflow(layer: m_layer)
    }
  }

  private func showsOverflowControls() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func computeScrollOrigin() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateScrollableAreaSet(_ hasOverflow: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateScrollCornerStyle() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateResizerStyle() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func drawPlatformResizerImage(
    context: GraphicsContextWrapper, resizerCornerRect: LayoutRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateScrollbarPresenceAndState(
    hasHorizontalOverflow: Bool? = nil, hasVerticalOverflow: Bool? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let scrollDimensionsDirty = false
  private var m_hasCompositedScrollableOverflow = false

  private var containsDirtyOverlayScrollbars = false

  private let m_layer: RenderLayerWrapper

  // For layers with overflow, we have a pair of scrollbars.
  private let hBar: Scrollbar? = nil
  private let vBar: Scrollbar? = nil

  private var cachedOverlayScrollbarOffset = IntPoint()

  // Renderers to hold our custom scroll corner and resizer.
  private let scrollCorner: RenderScrollbarPartWrapper? = nil
  private let resizer: RenderScrollbarPartWrapper? = nil
}
