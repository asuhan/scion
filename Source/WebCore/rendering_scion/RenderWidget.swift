/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2022 Apple Inc. All rights reserved.
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

// TODO(asuhan): inherit from OverlapTestRequestClient as well
class RenderWidgetWrapper: RenderReplacedWrapper, OverlapTestRequestClient {
  init(
    _ type: RenderObjectWrapper.`Type`, _ element: HTMLFrameOwnerElementWrapper,
    _ style: RenderStyleWrapper
  ) {
    super.init(type, element, style, .IsWidget)
    setInline(false)
  }

  override init(p: UnsafeMutableRawPointer) { super.init(p: p) }

  func frameOwnerElement() -> HTMLFrameOwnerElementWrapper {
    assert(isNativeImpl())
    return nodeForNonAnonymous() as! HTMLFrameOwnerElementWrapper
  }

  func widget() -> Widget? {
    assert(isNativeImpl())
    return m_widget
  }

  func setWidget(_ widget: Widget?) {
    assert(isNativeImpl())
    if widget.map(widgetRaw) == m_widget.map(widgetRaw) {
      return
    }

    if (m_widget is RemoteFrameViewWrapper) != (widget is RemoteFrameViewWrapper) {
      frameOwnerElement().scheduleInvalidateStyleAndLayerComposition()
    }

    if let oldWidget = m_widget {
      let oldWidgetRaw = widgetRaw(oldWidget)
      wk_interop.RenderWidget_moveWidgetToParentSoon(oldWidgetRaw, nil)
      wk_interop.LocalFrameView_willRemoveWidgetFromRenderTree(
        view().frameView().pInterop, oldWidgetRaw)
      wk_interop.RenderWidget_widgetRendererMapRemove(oldWidgetRaw)
      m_widget = nil
      wk_interop.Widget_deref(oldWidgetRaw)
    }
    m_widget = widget
    if let newWidget = m_widget {
      let newWidgetRaw = widgetRaw(newWidget)
      wk_interop.Widget_ref(newWidgetRaw)
      wk_interop.RenderWidget_widgetRendererMapAdd(newWidgetRaw, getWk())
      wk_interop.LocalFrameView_didAddWidgetToRenderTree(view().frameView().pInterop, newWidgetRaw)
      // If we've already received a layout, apply the calculated space to the
      // widget immediately, but we have to have really been fully constructed.
      if hasInitializedStyle {
        if !needsLayout() {
          // TODO(asuhan): updateWidgetGeometry may destroy this renderer, upstream checks a weak
          // pointer here.
          _ = updateWidgetGeometry()
        }

        if style().usedVisibility() != .Visible {
          newWidget.hide()
        } else {
          newWidget.show()
          repaint()
        }
        if let cache = document().existingAXObjectCache() {
          cache.onWidgetVisibilityChanged(self)
        }
      }
      wk_interop.RenderWidget_moveWidgetToParentSoon(newWidgetRaw, view().frameView().pInterop)
    }

    if let cache = document().existingAXObjectCache() {
      cache.childrenChanged(renderer: self)
    }
  }

  enum ChildWidgetState: UInt8 {
    case Valid
    case Destroyed
  }

  func updateWidgetPosition() -> ChildWidgetState {
    assert(isNativeImpl())
    guard let widget = m_widget else {
      return .Destroyed
    }

    // TODO(asuhan): updateWidgetGeometry may destroy this renderer, upstream checks a weak
    // pointer here.
    let widgetSizeChanged = updateWidgetGeometry()
    if m_widget == nil {
      return .Destroyed
    }

    // if the frame size got changed, or if view needs layout (possibly indicating
    // content size is wrong) we have to do a layout to set the right widget size.
    if let frameView = widget as? LocalFrameViewWrapper {
      // Check the frame's page to make sure that the frame isn't in the process of being destroyed.
      let localFrame = frameView.frame()
      if (widgetSizeChanged || frameView.needsLayout()) && localFrame.page() != nil
        && localFrame.document() != nil
      {
        frameView.layoutContext().layout()
      }
    }
    return .Valid
  }

  private func setWidgetGeometry(_ frame: LayoutRectWrapper) -> Bool {
    assert(isNativeImpl())
    let clipRect = roundedIntRect(enclosingLayer()!.childrenClipRect())
    let newFrameRect = roundedIntRect(frame)
    let oldFrameRect = m_widget!.frameRect()
    let clipChanged = m_clipRect != clipRect
    let boundsChanged = oldFrameRect != newFrameRect

    if !boundsChanged && !clipChanged {
      return false
    }

    m_clipRect = clipRect

    // TODO(asuhan): these calls *may* cause this renderer to disappear from underneath, upstream
    // follows up with a weak pointer check.
    if boundsChanged {
      m_widget!.setFrameRect(newFrameRect)
    } else if clipChanged {
      wk_interop.Widget_clipRectChanged(widgetRaw(m_widget!))
    }

    if boundsChanged {
      view().compositor().widgetDidChangeSize(self)
    }

    return oldFrameRect.size != newFrameRect.size
  }

  private func updateWidgetGeometry() -> Bool {
    assert(isNativeImpl())
    if !wk_interop.Widget_transformsAffectFrameRect(widgetRaw(m_widget!)) {
      return setWidgetGeometry(LayoutRectWrapper(rect: absoluteContentBox()))
    }

    var contentBox = contentBoxRect()
    var wasFixed: Bool? = nil
    let absoluteContentBox = LayoutRectWrapper(
      r: localToAbsoluteQuad(FloatQuad(inRect: contentBox.FloatRect()), .UseTransforms, &wasFixed)
        .boundingBox())
    if m_widget is LocalFrameViewWrapper {
      contentBox.setLocation(location: absoluteContentBox.location())
      return setWidgetGeometry(contentBox)
    }

    return setWidgetGeometry(absoluteContentBox)
  }

  func requiresAcceleratedCompositing() -> Bool {
    assert(isNativeImpl())
    // If this is a renderer with a contentDocument and that document needs a layer, then we need a layer.
    if let contentDocument = frameOwnerElement().contentDocument(),
      let view = contentDocument.renderView()
    {
      return view.usesCompositing()
    }

    if widget() is RemoteFrameViewWrapper {
      return true
    }

    return false
  }

  func remoteFrame() -> RemoteFrameWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    assert(isNativeImpl())
    super.styleDidChange(diff: diff, oldStyle: oldStyle)
    if m_widget != nil {
      if style().usedVisibility() != .Visible {
        m_widget!.hide()
      } else {
        m_widget!.show()
      }

      if let cache = document().existingAXObjectCache() {
        cache.onWidgetVisibilityChanged(self)
      }
    }
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    assert(isNativeImpl())
    if !shouldPaint(&paintInfo, paintOffset) {
      return
    }

    if paintInfo.context().detectingContentfulPaint() {
      return
    }

    let adjustedPaintOffset = paintOffset + location()

    if hasVisibleBoxDecorations()
      && (paintInfo.phase == .Foreground || paintInfo.phase == .Selection)
    {
      paintBoxDecorations(paintInfo: paintInfo, paintOffset: adjustedPaintOffset)
    }

    if paintInfo.phase == .Mask {
      paintMask(paintInfo: paintInfo, paintOffset: adjustedPaintOffset)
      return
    }

    if (paintInfo.phase == .Outline || paintInfo.phase == .SelfOutline) && hasOutline() {
      paintOutline(
        paintInfo: paintInfo,
        paintRect: LayoutRectWrapper(location: adjustedPaintOffset, size: size()))
    }

    // FIXME: Shouldn't check if the frame view needs layout during event region painting. This is a workaround
    // for the fact that non-composited frames depend on their enclosing compositing layer to perform an event
    // region update on their behalf. See <https://webkit.org/b/210311> for more details.
    let frameView = m_widget as? LocalFrameViewWrapper
    let needsEventRegionContentPaint =
      paintInfo.phase == .EventRegion && frameView != nil && !frameView!.needsLayout()
    if paintInfo.phase != .Foreground && !needsEventRegionContentPaint {
      return
    }

    if style().hasBorderRadius() {
      let borderRect = LayoutRectWrapper(location: adjustedPaintOffset, size: size())

      if borderRect.isEmpty() {
        return
      }

      // Push a clip if we have a border radius, since we want to round the foreground content that gets painted.
      paintInfo.context().save()
      clipToContentBoxShape(
        paintInfo.context(), adjustedPaintOffset, document().deviceScaleFactor())
    }

    if m_widget != nil && !isSkippedContentRootForRenderElement() {
      paintContents(paintInfo, paintOffset)
    }

    if style().hasBorderRadius() {
      paintInfo.context().restore()
    }

    if paintInfo.phase == .EventRegion || paintInfo.phase == .Accessibility {
      return
    }

    // Paint a partially transparent wash over selected widgets.
    if isSelected() && !document().printing() {
      var rect = localSelectionRect()
      rect.moveBy(offset: adjustedPaintOffset)
      paintInfo.context().fillRect(
        rect: FloatRectWrapper(r: snappedIntRect(rect: rect)), color: selectionBackgroundColor())
    }

    if hasLayer() && layer()!.canResize() {
      assert(layer()!.scrollableArea() != nil)
      layer()!.scrollableArea()!.paintResizer(
        context: paintInfo.context(),
        paintOffset: LayoutPointWrapper(point: roundedIntPoint(point: adjustedPaintOffset)),
        damageRect: paintInfo.rect)
    }
  }

  override func nodeAtPoint(
    _ request: HitTestRequestWrapper, _ result: inout HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ action: HitTestAction
  ) -> Bool {
    assert(isNativeImpl())
    let shouldHitTestChildFrameContent =
      request.allowsChildFrameContent()
      || (request.allowsVisibleChildFrameContent() && visibleToHitTesting(request: request))
    if let childFrameView = widget() as? LocalFrameViewWrapper,
      shouldHitTestChildFrameContent && childFrameView.renderView() != nil
    {
      let adjustedLocation = accumulatedOffset + location()
      let contentOffset =
        LayoutPointWrapper(x: borderLeft() + paddingLeft(), y: borderTop() + paddingTop())
        - LayoutSizeWrapper(size: toIntSize(childFrameView.scrollPosition()))
      let newHitTestLocation = HitTestLocationWrapper(
        locationInContainer, -adjustedLocation - contentOffset)
      let newHitTestRequest = HitTestRequestWrapper(type: request.type.union(.ChildFrameHitTest))
      var childFrameResult = HitTestResultWrapper(newHitTestLocation)

      guard let document = childFrameView.frame().document() else { return false }
      let isInsideChildFrame = document.hitTest(
        newHitTestRequest, newHitTestLocation, &childFrameResult)

      if request.resultIsElementList() {
        result.append(childFrameResult, request)
      } else if isInsideChildFrame {
        result = childFrameResult
      }

      if isInsideChildFrame {
        return true
      }
    }

    let hadResult = result.innerNode()
    let inside = super.nodeAtPoint(request, &result, locationInContainer, accumulatedOffset, action)

    // Check to see if we are really over the widget itself (and not just in the border/padding area).
    if (inside || result.isRectBasedTest()) && hadResult == nil
      && optEq(result.innerNode(), frameOwnerElement())
    {
      result.setIsOverWidget(contentBoxRect().contains(point: result.localPoint))
    }
    return inside
  }

  override func requiresLayer() -> Bool {
    assert(isNativeImpl())
    return super.requiresLayer() || requiresAcceleratedCompositing()
  }

  override func needsPreferredWidthsRecalculation() -> Bool {
    assert(isNativeImpl())
    if super.needsPreferredWidthsRecalculation() {
      return true
    }
    return embeddedContentBox() != nil
  }

  override final func embeddedContentBox() -> RenderBoxWrapper? {
    assert(isNativeImpl())
    if !(self is RenderEmbeddedObjectWrapper) {
      return nil
    }
    let frameView = widget() as? LocalFrameViewWrapper
    return frameView?.embeddedContentBox()
  }

  final func setOverlapTestResult(_ isOverlapped: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintContents(_ paintInfo: PaintInfoWrapper, _ paintOffset: LayoutPointWrapper) {
    assert(isNativeImpl())
    if paintInfo.requireSecurityOriginAccessForWidgets {
      if let contentDocument = frameOwnerElement().contentDocument() {
        if !document().protectedSecurityOrigin().isSameOriginDomain(
          contentDocument.securityOrigin())
        {
          return
        }
      }
    }

    let contentPaintOffset = roundedIntPoint(
      point: paintOffset + location() + contentBoxRect().location())
    // Tell the widget to paint now. This is the only time the widget is allowed
    // to paint itself. That way it will composite properly with z-indexed layers.
    var paintRect = paintInfo.rect

    var oldBehavior: PaintBehavior = .Normal
    if paintInfo.paintBehavior.contains(.DefaultAsynchronousImageDecode),
      let frameView = m_widget as? LocalFrameViewWrapper
    {
      oldBehavior = frameView.paintBehavior()
      frameView.setPaintBehavior(oldBehavior.union(.DefaultAsynchronousImageDecode))
    }

    let widgetLocation = m_widget!.frameRect().location
    let widgetPaintOffset = contentPaintOffset - widgetLocation
    // When painting widgets into compositing layers, tx and ty are relative to the enclosing compositing layer,
    // not the root. In this case, shift the CTM and adjust the paintRect to be root-relative to fix plug-in drawing.
    if !widgetPaintOffset.isZero() {
      paintInfo.context().translate(size: FloatSize(size: widgetPaintOffset))
      paintRect.move(size: LayoutSizeWrapper(size: -widgetPaintOffset))
    }

    if paintInfo.regionContext != nil {
      let transform = AffineTransform()
      transform.translate(FloatPoint(p: contentPaintOffset))
      paintInfo.regionContext!.pushTransform(transform: transform)
    }

    // FIXME: Remove repaintrect enclosing/integral snapping when RenderWidget becomes device pixel snapped.
    m_widget!.paint(
      paintInfo.context(), snappedIntRect(rect: paintRect),
      paintInfo.requireSecurityOriginAccessForWidgets ? .AccessibleOriginOnly : .AnyOrigin,
      paintInfo.regionContext)

    paintInfo.regionContext?.popTransform()

    if !widgetPaintOffset.isZero() {
      paintInfo.context().translate(size: FloatSize(size: -widgetPaintOffset))
    }

    if let frameView = m_widget as? LocalFrameViewWrapper {
      let runOverlapTests = !frameView.useSlowRepaintsIfNotOverlapped()
      if paintInfo.overlapTestRequests != nil && runOverlapTests {
        assert(
          !paintInfo.overlapTestRequests!.contains(self)
            || (paintInfo.overlapTestRequests!.get(self) == m_widget!.frameRect()))
        paintInfo.overlapTestRequests!.set(self, m_widget!.frameRect())
      }
      if paintInfo.paintBehavior.contains(.DefaultAsynchronousImageDecode) {
        frameView.setPaintBehavior(oldBehavior)
      }
    }
  }

  private var m_widget: Widget? = nil
  // The rectangle needs to remain correct after scrolling, so it is stored in content view coordinates, and not clipped to window.
  private var m_clipRect = IntRect()
}

private func roundedIntRect(_ rect: LayoutRectWrapper) -> IntRect {
  return IntRect(
    location: roundedIntPoint(point: rect.location()), size: roundedIntSize(s: rect.size()))
}

// Returns the C++ Widget pointer behind a Swift widget wrapper.
private func widgetRaw(_ widget: Widget) -> UnsafeMutableRawPointer {
  guard let scrollView = widget as? ScrollViewWrapper else {
    // TODO(asuhan): implement this for plugins and scrollbars
    fatalError("Not implemented")
  }
  return wk_interop.ScrollView_asWidget(scrollView.pInterop!)
}

func createWidgetWrapper(_ widgetRaw: UnsafeMutableRawPointer) -> Widget {
  if wk_interop.Widget_isLocalFrameView(widgetRaw) {
    return LocalFrameViewWrapper(wk_interop.Widget_toLocalFrameView(widgetRaw)!)
  }
  if wk_interop.Widget_isRemoteFrameView(widgetRaw) {
    return RemoteFrameViewWrapper(wk_interop.Widget_toRemoteFrameView(widgetRaw)!)
  }
  // TODO(asuhan): implement this for plugins
  fatalError("Not implemented")
}
