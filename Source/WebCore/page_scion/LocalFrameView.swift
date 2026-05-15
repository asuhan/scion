/*
   Copyright (C) 1997 Martin Jones (mjones@kde.org)
             (C) 1998 Waldo Bastian (bastian@kde.org)
             (C) 1998, 1999 Torben Weis (weis@kde.org)
             (C) 1999 Lars Knoll (knoll@kde.org)
             (C) 1999 Antti Koivisto (koivisto@kde.org)
   Copyright (C) 2004-2019 Apple Inc. All rights reserved.

   This library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Library General Public
   License as published by the Free Software Foundation; either
   version 2 of the License, or (at your option) any later version.

   This library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Library General Public License for more details.

   You should have received a copy of the GNU Library General Public License
   along with this library; see the file COPYING.LIB.  If not, write to
   the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
   Boston, MA 02110-1301, USA.
*/

import wk_interop

class LocalFrameViewWrapper: FrameViewWrapper {
  func frame() -> LocalFrameWrapper {
    return LocalFrameWrapper(wk_interop.LocalFrameView_frame(pInterop))
  }

  func renderView() -> RenderViewWrapper? {
    guard let p = wk_interop.LocalFrameView_renderView(pInterop) else { return nil }
    assert(wk_interop.RenderObject_isRenderView(p))
    return Unmanaged<RenderViewWrapper>.fromOpaque(wk_interop.RenderView_scion(p)!)
      .takeUnretainedValue()
  }

  func layoutContext() -> LocalFrameViewLayoutContextWrapper {
    return LocalFrameViewLayoutContextWrapper(p: wk_interop.LocalFrameView_layoutContext(pInterop))
  }

  // TODO(asuhan): remove this, it's not needed in Swift
  func checkedLayoutContext() -> LocalFrameViewLayoutContextWrapper { return layoutContext() }

  func needsLayout() -> Bool { return wk_interop.LocalFrameView_needsLayout(pInterop) }

  // Called when changes to the GraphicsLayer hierarchy have to be synchronized with
  // content rendered via the normal painting path.
  func setNeedsOneShotDrawingSynchronization() {
    wk_interop.LocalFrameView_setNeedsOneShotDrawingSynchronization(pInterop)
  }

  func recalculateScrollbarOverlayStyle() {
    wk_interop.LocalFrameView_recalculateScrollbarOverlayStyle(pInterop)
  }

  func isTransparent() -> Bool { return wk_interop.LocalFrameView_isTransparent(pInterop) }

  func baseBackgroundColor() -> ColorWrapper {
    let c = wk_interop.LocalFrameView_baseBackgroundColor(pInterop)
    return ColorWrapper(SRGBA(red: c.red, green: c.green, blue: c.blue, alpha: c.alpha))
  }

  func updateExtendBackgroundIfNecessary() {
    wk_interop.LocalFrameView_updateExtendBackgroundIfNecessary(pInterop)
  }

  func hasExtendedBackgroundRectForPainting() -> Bool {
    return wk_interop.LocalFrameView_hasExtendedBackgroundRectForPainting(pInterop)
  }

  func extendedBackgroundRectForPainting() -> IntRect {
    return convertIntRect(wk_interop.LocalFrameView_extendedBackgroundRectForPainting(pInterop))
  }

  override func windowClipRect() -> IntRect {
    return convertIntRect(wk_interop.LocalFrameView_windowClipRect(pInterop))
  }

  func visualViewportOverrideRect() -> LayoutRectWrapper? {
    let r = wk_interop.LocalFrameView_visualViewportOverrideRect(pInterop)
    return r.is_valid ? convertLayoutRect(r.rect) : nil
  }

  // These are in document coordinates, unaffected by page scale (but affected by zooming).
  func layoutViewportRect() -> LayoutRectWrapper {
    return convertLayoutRect(wk_interop.LocalFrameView_layoutViewportRect(pInterop))
  }

  func rectForFixedPositionLayout() -> LayoutRectWrapper {
    return convertLayoutRect(wk_interop.LocalFrameView_rectForFixedPositionLayout(pInterop))
  }

  func setCannotBlitToWindow() { wk_interop.LocalFrameView_setCannotBlitToWindow(pInterop) }

  func setContentIsOpaque(contentIsOpaque: Bool) {
    wk_interop.LocalFrameView_setContentIsOpaque(pInterop, contentIsOpaque)
  }

  func addSlowRepaintObject(_ renderer: RenderElementWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removeSlowRepaintObject(_ renderer: RenderElementWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasSlowRepaintObject(_ renderer: RenderElementWrapper) -> Bool {
    assert(renderer.isNativeImpl())
    return wk_interop.LocalFrameView_hasSlowRepaintObject(
      pInterop, (renderer as! RenderViewWrapper).getWk())
  }

  func slowRepaintObjects() -> WeakHashSet<RenderElementWrapper>? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Includes fixed- and sticky-position objects.
  func addViewportConstrainedObject(_ object: RenderLayerModelObjectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removeViewportConstrainedObject(_ object: RenderLayerModelObjectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func viewportConstrainedObjects() -> WeakHashSet<RenderLayerModelObjectWrapper>? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func frameScaleFactor() -> Float32 { return wk_interop.LocalFrameView_frameScaleFactor(pInterop) }

  // Functions for querying the current scrolled position, negating the effects of overhang
  // and adjusting for page scale.
  func scrollPositionForFixedPosition() -> LayoutPointWrapper {
    return convertLayoutPointRaw(wk_interop.LocalFrameView_scrollPositionForFixedPosition(pInterop))
  }

  func positionForRootContentLayer() -> FloatPoint {
    let p = wk_interop.LocalFrameView_positionForRootContentLayer(pInterop)
    return FloatPoint(x: p.x, y: p.y)
  }

  func fixedElementsLayoutRelativeToFrame() -> Bool {
    return wk_interop.LocalFrameView_fixedElementsLayoutRelativeToFrame(pInterop)
  }

  func speculativeTilingEnabled() -> Bool {
    return wk_interop.LocalFrameView_speculativeTilingEnabled(pInterop)
  }

  func addEmbeddedObjectToUpdate(_ embeddedObject: RenderEmbeddedObjectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setPaintBehavior(_ behavior: PaintBehavior) {
    wk_interop.LocalFrameView_setPaintBehavior(pInterop, behavior.rawValue)
  }

  func paintBehavior() -> PaintBehavior {
    return PaintBehavior(rawValue: wk_interop.LocalFrameView_paintBehavior(pInterop))
  }

  func documentBackgroundColor() -> ColorWrapper {
    // TODO(asuhan): handle all color types, flags.
    let c = wk_interop.LocalFrameView_documentBackgroundColor(pInterop)
    return ColorWrapper(SRGBA(red: c.red, green: c.green, blue: c.blue, alpha: c.alpha))
  }

  func incrementVisuallyNonEmptyCharacterCount(inlineText: StringWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func incrementVisuallyNonEmptyPixelCount(size: IntSize) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasEnoughContentForVisualMilestones() -> Bool {
    return wk_interop.LocalFrameView_hasEnoughContentForVisualMilestones(pInterop)
  }

  // isScrollable() takes an optional Scrollability parameter that allows the caller to define what they mean by 'scrollable.'
  // Most callers are interested in the default value, Scrollability::Scrollable, which means that there is actually content
  // to scroll to, and a scrollbar that will allow you to access it. In some cases, callers want to know if the FrameView is allowed
  // to rubber-band, which the main frame might be allowed to do even if there is no content to scroll to. In that case,
  // callers use Scrollability::ScrollableOrRubberbandable.
  enum Scrollability {
    case Scrollable
    case ScrollableOrRubberbandable
  }

  func isScrollable(definitionOfScrollable: Scrollability = .Scrollable) -> Bool {
    return wk_interop.LocalFrameView_isScrollable(
      pInterop, definitionOfScrollable == .ScrollableOrRubberbandable)
  }

  func embeddedContentBox() -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isTrackingRepaints() -> Bool {
    return wk_interop.LocalFrameView_isTrackingRepaints(pInterop)
  }

  // Page and LocalFrameView both store a Pagination value. Page::pagination() is set only by API,
  // and LocalFrameView::pagination() is set only by CSS. Page::pagination() will affect all
  // FrameViews in the back/forward cache, but LocalFrameView::pagination() only affects the current
  // LocalFrameView. LocalFrameView::pagination() will return m_pagination if it has been set. Otherwise,
  // it will return Page::pagination() since currently there are no callers that need to
  // distinguish between the two.
  func pagination() -> Pagination {
    let raw = wk_interop.LocalFrameView_pagination(pInterop)
    return Pagination(
      mode: Pagination.Mode(rawValue: raw.mode)!, behavesLikeColumns: raw.behavesLikeColumns,
      pageLength: raw.pageLength, gap: raw.gap)
  }

  // This function "smears" the "position:fixed" uninflatedBounds for scrolling, returning a rect that is the union of
  // all possible locations of the given rect under page scrolling.
  func fixedScrollableAreaBoundsInflatedForScrolling(uninflatedBounds: LayoutRectWrapper)
    -> LayoutRectWrapper
  {
    return convertLayoutRect(
      wk_interop.LocalFrameView_fixedScrollableAreaBoundsInflatedForScrolling(
        pInterop, convertLayoutRect(uninflatedBounds)))
  }

  func scrollPositionRespectingCustomFixedPosition() -> LayoutPointWrapper {
    let rawLayoutPoint = wk_interop.LocalFrameView_scrollPositionRespectingCustomFixedPosition(
      pInterop)
    return LayoutPointWrapper(
      x: LayoutUnit.fromRawValue(value: rawLayoutPoint.x),
      y: LayoutUnit.fromRawValue(value: rawLayoutPoint.y))
  }

  func topContentDirectionDidChange() {
    wk_interop.LocalFrameView_topContentDirectionDidChange(pInterop)
  }

  func hasFlippedBlockRenderers() -> Bool {
    return wk_interop.LocalFrameView_hasFlippedBlockRenderers(pInterop)
  }

  func setHasFlippedBlockRenderers(_ b: Bool) {
    wk_interop.LocalFrameView_setHasFlippedBlockRenderers(pInterop, b)
  }

  func addTrackedRepaintRect(_ r: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func viewExposedRect() -> FloatRectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layerForHorizontalScrollbar() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layerForVerticalScrollbar() -> GraphicsLayer? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // ScrollView
  override func updateScrollbarSteps() { wk_interop.LocalFrameView_updateScrollbarSteps(pInterop) }

  override func scrollbarWidthChanged(_ width: ScrollbarWidth) {
    wk_interop.LocalFrameView_scrollbarWidthChanged(pInterop, width.rawValue)
  }

  func layerAccessPrevented() -> Bool {
    return wk_interop.LocalFrameView_layerAccessPrevented(pInterop)
  }

  func useSlowRepaintsIfNotOverlapped() -> Bool {
    return wk_interop.LocalFrameView_useSlowRepaintsIfNotOverlapped(pInterop)
  }

  override final func repaintContentRectangle(_ r: IntRect) {
    wk_interop.LocalFrameView_repaintContentRectangle(pInterop, convertIntRect(r))
  }
}
