/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 * Copyright (C) 2006, 2015-2016 Apple Inc.
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

import Foundation
import wk_interop

private func rendererObscuresBackground(_ rootElement: RenderElementWrapper) -> Bool {
  let style = rootElement.style()
  if style.usedVisibility() != .Visible || style.opacity() != 1 || style.hasTransform() {
    return false
  }

  if style.hasBorderRadius() {
    return false
  }

  if rootElement.isComposited() {
    return false
  }

  if rootElement.hasClipPath() && rootElement.isRenderOrLegacyRenderSVGRoot() {
    return false
  }

  if let rendererForBackground = rootElement.view().rendererForRootBackground() {
    return rendererForBackground.style().backgroundClip() != .Text
  }

  return false
}

class RenderViewWrapper: RenderBlockFlowWrapper {
  init(_ document: Document, _ style: RenderStyleWrapper) {
    super.init(type: .View, document: document, style: style)
    m_frameView = document.view()
    m_initialContainingBlock = InitialContainingBlock(style: RenderStyleWrapper.clone(style: style))
    m_layoutState = LayoutStateWrapper(
      document, m_initialContainingBlock!, .Primary,
      LayoutIntegration.layoutWithFormattingContextForBox,
      LayoutIntegration.formattingContextRootLogicalWidthForType)
    m_selection = RenderSelection(self)

    // FIXME: We should find a way to enforce this at compile time.
    assert(document.view() != nil)

    // init RenderObject attributes
    setInline(false)

    m_minPreferredLogicalWidth = LayoutUnit(value: 0)
    m_maxPreferredLogicalWidth = LayoutUnit(value: 0)

    setPreferredLogicalWidthsDirty(shouldBeDirty: true, markParents: .MarkOnlyThis)

    setPositionState(.Absolute)  // to 0,0 :)

    assert(isRenderView())
  }

  override init(p: UnsafeMutableRawPointer) { super.init(p: p) }

  override func requiresLayer() -> Bool { return true }

  override final func isChildAllowed(_ child: RenderObjectWrapper, _ style: RenderStyleWrapper)
    -> Bool
  {
    assert(isNativeImpl())
    return child.isRenderBox()
  }

  override func layout() {
    // TODO(asuhan): add stack stats
    if !document().paginated() {
      pageLogicalSize = nil
    }

    if shouldUsePrintingLayout() {
      if pageLogicalSize == nil {
        pageLogicalSize = LayoutSizeWrapper(
          width: logicalWidth(), height: LayoutUnit(value: UInt64(0)))
      }
      m_minPreferredLogicalWidth = pageLogicalSize!.width()
      m_maxPreferredLogicalWidth = m_minPreferredLogicalWidth
    }

    // Use calcWidth/Height to get the new width/height, since this will take the full page zoom factor into account.
    let relayoutChildren =
      !shouldUsePrintingLayout() && (width() != viewWidth() || height() != viewHeight())
    if relayoutChildren {
      setChildNeedsLayout(markParents: .MarkOnlyThis)

      for box: RenderBoxWrapper in childrenOfType(parent: self) {
        if box.hasRelativeLogicalHeight()
          || box.style().logicalHeight().isPercentOrCalculated()
          || box.style().logicalMinHeight().isPercentOrCalculated()
          || box.style().logicalMaxHeight().isPercentOrCalculated()
          || box.isRenderOrLegacyRenderSVGRoot()
        {
          box.setChildNeedsLayout(markParents: .MarkOnlyThis)
        }
      }
    }

    assert(frameView().layoutContext().layoutState() == nil)
    if !needsLayout() {
      return
    }

    let _ = LayoutStateMaintainer(
      root: self, offset: LayoutSizeWrapper(), disablePaintOffsetCache: false,
      pageHeight: (pageLogicalSize ?? LayoutSizeWrapper()).height(),
      pageHeightChanged: pageLogicalHeightChanged)

    pageLogicalHeightChanged = false

    // FIXME: This should be called only when frame view (or the canvas we render onto) size changes.
    updateInitialContainingBlockSize()
    super.layout()

    #if !NDEBUG
      frameView().layoutContext().checkLayoutState()
    #endif
  }

  override func updateLogicalWidth() {
    assert(isNativeImpl())
    setLogicalWidth(
      size: shouldUsePrintingLayout()
        ? pageLogicalSize!.width() : LayoutUnit(value: viewLogicalWidth()))
  }

  override func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    return LogicalExtentComputedValues(
      extent: !shouldUsePrintingLayout() ? LayoutUnit(value: viewLogicalHeight()) : logicalHeight,
      position: LayoutUnit(value: UInt64(0)), margins: ComputedMarginValues())
  }

  override func availableLogicalHeight(heightType: AvailableLogicalHeightType) -> LayoutUnit {
    // Make sure block progression pagination for percentages uses the column extent and
    // not the view's extent. See https://bugs.webkit.org/show_bug.cgi?id=135204.
    if multiColumnFlowForBlockFlow() != nil
      && multiColumnFlowForBlockFlow()!.firstMultiColumnSet() != nil
    {
      return multiColumnFlowForBlockFlow()!.firstMultiColumnSet()!.computedColumnHeight
    }

    let frameView = frameView()
    // TODO(asuhan): add iOS support
    return LayoutUnit(
      value: isHorizontalWritingMode()
        ? frameView.layoutSize().height : frameView.layoutSize().width)
  }

  // The same as the FrameView's layoutHeight/layoutWidth but with null check guards.
  func viewHeight() -> Int32 {
    var height: Int32 = 0
    if !shouldUsePrintingLayout() {
      let frameView = frameView()
      height = frameView.layoutHeight()
      height = Int32(
        frameView.useFixedLayout() ? ceilf(style().usedZoom() * Float32(height)) : Float32(height))
    }
    return height
  }

  func viewWidth() -> Int32 {
    var width: Int32 = 0
    if !shouldUsePrintingLayout() {
      let frameView = frameView()
      width = frameView.layoutWidth()
      width = Int32(
        frameView.useFixedLayout() ? ceilf(style().usedZoom() * Float32(width)) : Float32(width))
    }
    return width
  }

  private func viewLogicalWidth() -> Int32 {
    assert(isNativeImpl())
    return style().isHorizontalWritingMode() ? viewWidth() : viewHeight()
  }

  private func viewLogicalHeight() -> Int32 {
    let height = style().isHorizontalWritingMode() ? viewHeight() : viewWidth()
    return height
  }

  func clientLogicalWidthForFixedPosition() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clientLogicalHeightForFixedPosition() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func frameView() -> LocalFrameViewWrapper {
    if !isNativeImpl() {
      return LocalFrameViewWrapper(p: wk_interop.RenderView_frameView(id()))
    }
    return m_frameView!
  }

  func protectedFrameView() -> LocalFrameViewWrapper {
    return frameView()  // TODO(asuhan): just remove this wrapper, not needed in Swift
  }

  func layoutState() -> LayoutStateWrapper {
    assert(!isNativeImpl())
    return LayoutStateWrapper(p: wk_interop.RenderView_layoutState(id()))
  }

  func updateQuirksMode() {
    assert(isNativeImpl())
    m_layoutState!.updateQuirksMode(document())
  }

  func needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly() -> Bool {
    return m_needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly
  }

  func setNeedsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly(_ value: Bool = true) {
    m_needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly = value
  }

  func needsEventRegionUpdateForNonCompositedFrame() -> Bool {
    return m_needsEventRegionUpdateForNonCompositedFrame
  }

  override func computeVisibleRectsInContainer(
    _ rects: RepaintRects, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> RepaintRects? {
    // If a container was specified, and was not nullptr or the RenderView,
    // then we should have found it by now.
    assert(container == nil || CPtrToInt(container!.id()) == CPtrToInt(id()))

    if printing() {
      return rects
    }

    var adjustedRects = rects
    if style().isFlippedBlocksWritingMode() {
      // We have to flip by hand since the view's logical height has not been determined.  We
      // can use the viewport width and height.
      adjustedRects.flipForWritingMode(
        LayoutSizeWrapper(width: viewWidth(), height: viewHeight()),
        style().isHorizontalWritingMode())
    }

    if context.hasPositionFixedDescendant {
      adjustedRects.moveBy(protectedFrameView().scrollPositionRespectingCustomFixedPosition())
    }

    // Apply our transform if we have one (because of full page zooming).
    if container == nil && hasLayer() && layer()!.transform != nil {
      adjustedRects.transform(layer()!.transform!, document().deviceScaleFactor())
    }

    return adjustedRects
  }

  func repaintRootContents() {
    if layer()!.isComposited() {
      layer()!.setBackingNeedsRepaint(shouldClip: .DoNotClipToLayer)
      return
    }

    // Always use layoutOverflowRect() to fix rdar://problem/27182267.
    // This should be cleaned up via webkit.org/b/159913 and webkit.org/b/159914.
    let repaintContainer = containerForRepaint().renderer
    repaintUsingContainer(
      repaintContainer,
      computeRectForRepaint(rect: layoutOverflowRect(), repaintContainer: repaintContainer))
  }

  func repaintViewRectangle(_ repaintRect: LayoutRectWrapper) {
    if !shouldRepaint(repaintRect) {
      return
    }

    // FIXME: enclosingRect is needed as long as we integral snap ScrollView/FrameView/RenderWidget size/position.
    let enclosingRect = enclosingIntRect(rect: repaintRect)
    if let ownerElement = document().ownerElement() {
      guard let ownerBox = ownerElement.renderBox() else { return }
      let viewRect = self.viewRect()
      // TODO(asuhan): add iOS support
      var adjustedRect = intersection(a: LayoutRectWrapper(rect: enclosingRect), b: viewRect)
      if adjustedRect.isEmpty() {
        return
      }

      adjustedRect.moveBy(offset: -viewRect.location())
      adjustedRect.moveBy(offset: ownerBox.contentBoxRect().location())

      // A dirty rect in an iframe is relative to the contents of that iframe.
      // When we traverse between parent frames and child frames, we need to make sure
      // that the coordinate system is mapped appropriately between the iframe's contents
      // and the Renderer that contains the iframe. This transformation must account for a
      // left scrollbar (if one exists).
      let frameView = frameView()
      if frameView.shouldPlaceVerticalScrollbarOnLeft() && frameView.verticalScrollbar() != nil {
        adjustedRect.move(
          size: LayoutSizeWrapper(width: frameView.verticalScrollbar()!.occupiedWidth(), height: 0))
      }

      ownerBox.repaintRectangle(repaintRect: adjustedRect)
      return
    }

    protectedFrameView().addTrackedRepaintRect(
      snapRectToDevicePixels(rect: repaintRect, pixelSnappingFactor: document().deviceScaleFactor())
    )
    if accumulatedRepaintRegion == nil {
      protectedFrameView().repaintContentRectangle(enclosingRect)
      return
    }
    accumulatedRepaintRegion!.unite(Region(enclosingRect))

    // Region will get slow if it gets too complex. Merge all rects so far to bounds if this happens.
    // FIXME: Maybe there should be a region type that does this automatically.
    let maximumRepaintRegionGridSize = 16 * 16
    if accumulatedRepaintRegion!.gridSize() > maximumRepaintRegionGridSize {
      accumulatedRepaintRegion = Region(accumulatedRepaintRegion!.bounds)
    }
  }

  func repaintViewAndCompositedLayers() {
    repaintRootContents()

    let compositor = compositor()
    if compositor.usesCompositing() {
      compositor.repaintCompositedLayers()
    }
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // If we ever require layout but receive a paint anyway, something has gone horribly wrong.
    assert(!needsLayout())
    // RenderViews should never be called to paint with an offset not on device pixels.
    assert(
      LayoutPointWrapper(point: IntPoint(x: paintOffset.x.int(), y: paintOffset.y.int()))
        == paintOffset)

    // This avoids painting garbage between columns if there is a column gap.
    let frameView = frameView()
    if frameView.pagination().mode != .Unpaginated
      && paintInfo.shouldPaintWithinRoot(renderer: self)
    {
      paintInfo.context().fillRect(
        rect: paintInfo.rect.FloatRect(), color: frameView.baseBackgroundColor())
    }

    paintObject(paintInfo: &paintInfo, paintOffset: paintOffset)
  }

  override final func paintBoxDecorations(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper
  ) {
    if !paintInfo.shouldPaintWithinRoot(renderer: self) {
      return
    }

    // Check to see if we are enclosed by a layer that requires complex painting rules.  If so, we cannot blit
    // when scrolling, and we need to use slow repaints.  Examples of layers that require this are transparent layers,
    // layers with reflections, or transformed layers.
    // FIXME: This needs to be dynamic.  We should be able to go back to blitting if we ever stop being inside
    // a transform, transparency layer, etc.
    var element = document().ownerElement()
    while element != nil && element!.renderer() != nil {
      let layer = element!.renderer()!.enclosingLayer()!
      if layer.cannotBlitToWindow() {
        protectedFrameView().setCannotBlitToWindow()
        break
      }

      if let compositingLayer = layer.enclosingCompositingLayerForRepaint().layer {
        if !compositingLayer.backing!.paintsIntoWindow() {
          protectedFrameView().setCannotBlitToWindow()
          break
        }
      }

      element = element!.document().ownerElement()
    }

    if !shouldPaintBaseBackground() {
      return
    }

    if paintInfo.skipRootBackground() {
      return
    }

    var rootFillsViewport = false
    var rootObscuresBackground = false
    var shouldPropagateBackgroundPaintingToInitialContainingBlock = true
    let documentElement = document().documentElement()
    if let rootRenderer = documentElement?.containerRenderer() {
      // The document element's renderer is currently forced to be a block, but may not always be.
      let rootBox = rootRenderer as? RenderBoxWrapper
      rootFillsViewport =
        rootBox != nil && !rootBox!.x().bool() && !rootBox!.y().bool()
        && rootBox!.width() >= width()
        && rootBox!.height() >= height()
      rootObscuresBackground = rendererObscuresBackground(rootRenderer)
      shouldPropagateBackgroundPaintingToInitialContainingBlock =
        (rendererForRootBackground() != nil)
    }

    compositor().rootBackgroundColorOrTransparencyChanged()

    let page = document().page()
    let pageScaleFactor = page?.pageScaleFactor() ?? 1

    // If painting will entirely fill the view, no need to fill the background.
    if rootFillsViewport && rootObscuresBackground && pageScaleFactor >= 1
      && rootElementShouldPaintBaseBackground()
    {
      return
    }

    // This code typically only executes if the root element's visibility has been set to hidden,
    // if there is a transform on the <html>, or if there is a page scale factor less than 1.
    // Only fill with a background color (typically white) if we're the root document,
    // since iframes/frames with no background in the child document should show the parent's background.
    // We use the base background color unless the backgroundShouldExtendBeyondPage setting is set,
    // in which case we use the document's background color.
    let frameView = frameView()
    if frameView.isTransparent() {  // FIXME: This needs to be dynamic. We should be able to go back to blitting if we ever stop being transparent.
      frameView.setCannotBlitToWindow()  // The parent must show behind the child.
    } else {
      let documentBackgroundColor = frameView.documentBackgroundColor()
      let backgroundColor =
        (shouldPropagateBackgroundPaintingToInitialContainingBlock
          && settings().backgroundShouldExtendBeyondPage() && documentBackgroundColor.isValid())
        ? documentBackgroundColor : frameView.baseBackgroundColor()
      if backgroundColor.isVisible() {
        let previousOperator = paintInfo.context().compositeOperation()
        paintInfo.context().setCompositeOperation(operation: .Copy)
        paintInfo.context().fillRect(rect: paintInfo.rect.FloatRect(), color: backgroundColor)
        paintInfo.context().setCompositeOperation(operation: previousOperator)
      } else {
        paintInfo.context().clearRect(rect: paintInfo.rect.FloatRect())
      }
    }
  }

  // Return the renderer whose background style is used to paint the root background.
  func rendererForRootBackground() -> RenderElementWrapper? {
    guard let firstChild = firstChild() else { return nil }

    let documentRenderer = firstChild as! RenderElementWrapper
    if documentRenderer.hasBackground() {
      return documentRenderer
    }

    // We propagate the background only for HTML content.
    if !(documentRenderer.element() is HTMLHtmlElement) {
      return documentRenderer
    }

    if documentRenderer.shouldApplyAnyContainment() {
      return nil
    }

    if let body = document().body(), let renderer = body.containerRenderer() {
      if !renderer.shouldApplyAnyContainment() {
        return renderer
      }
    }
    return documentRenderer
  }

  func selection() -> RenderSelection {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func printing() -> Bool {
    return document().printing()
  }

  private func viewRect() -> LayoutRectWrapper {
    if shouldUsePrintingLayout() {
      return LayoutRectWrapper(location: LayoutPointWrapper(), size: size())
    }
    return LayoutRectWrapper(
      rect: protectedFrameView().visibleContentRect(.LegacyIOSDocumentVisibleRect))
  }

  func pageOrViewLogicalHeight() -> LayoutUnit {
    if shouldUsePrintingLayout() {
      return pageLogicalSize!.height()
    }

    if multiColumnFlowForBlockFlow() != nil && !style().hasInlineColumnAxis() {
      let pageLength = protectedFrameView().pagination().pageLength
      if pageLength != 0 {
        return LayoutUnit(value: pageLength)
      }
    }

    return LayoutUnit(value: viewLogicalHeight())
  }

  func setBestTruncatedAt(
    y: Int32, forRenderer: RenderBoxModelObjectWrapper, forcedBreak: Bool = false
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func truncatedAt() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func printRect() -> IntRect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setIsInWindow(_ isInWindow: Bool) {
    m_compositor?.setIsInWindow(isInWindow)
  }

  func compositor() -> RenderLayerCompositorWrapper {
    if m_compositor == nil {
      print("TODO: switch to Scion compositor")
      m_compositor = RenderLayerCompositorWrapper(self)
    }

    return m_compositor!
  }

  func usesCompositing() -> Bool {
    return m_compositor?.usesCompositing() ?? false
  }

  func unscaledDocumentRect() -> IntRect {
    var overflowRect = layoutOverflowRect()
    flipForWritingMode(rect: &overflowRect)
    return snappedIntRect(rect: overflowRect)
  }

  func unextendedBackgroundRect() -> LayoutRectWrapper {
    // FIXME: What is this? Need to patch for new columns?
    return LayoutRectWrapper(rect: unscaledDocumentRect())
  }

  func backgroundRect() -> LayoutRectWrapper {
    // FIXME: New columns care about this?
    let frameView = frameView()
    if frameView.hasExtendedBackgroundRectForPainting() {
      return LayoutRectWrapper(rect: frameView.extendedBackgroundRectForPainting())
    }

    return unextendedBackgroundRect()
  }

  func documentRect() -> IntRect {
    var overflowRect = FloatRectWrapper(r: unscaledDocumentRect())
    if isTransformed() {
      overflowRect = layer()!.currentTransform().mapRect(overflowRect)
    }
    return IntRect(overflowRect)
  }

  func rootElementShouldPaintBaseBackground() -> Bool {
    let documentElement = document().documentElement()
    if let rootRenderer = documentElement != nil ? documentElement!.renderer() : nil {
      // The document element's renderer is currently forced to be a block, but may not always be.
      if let rootBox = rootRenderer as? RenderBoxWrapper, rootBox.hasLayer() {
        let layer = rootBox.layer()!
        if layer.isolatesBlending() || layer.isBackdropRoot() {
          return false
        }
      }
    }
    return shouldPaintBaseBackground()
  }

  private func shouldPaintBaseBackground() -> Bool {
    let document = document()
    let frameView = frameView()
    let ownerElement = document.ownerElement()

    // Fill with a base color if we're the root document.
    if frameView.frame().isMainFrame() {
      return !frameView.isTransparent()
    }

    if ownerElement?.hasFrameTag() ?? false {
      return true
    }

    // Locate the <body> element using the DOM. This is easier than trying
    // to crawl around a render tree with potential :before/:after content and
    // anonymous blocks created by inline <body> tags etc. We can locate the <body>
    // render object very easily via the DOM.
    guard let body = document.bodyOrFrameset() else {
      // SVG documents and XML documents with SVG root nodes are transparent.
      return !document.hasSVGRootNode()
    }

    // Can't scroll a frameset document anyway.
    if body is HTMLFrameSetElementWrapper {
      return true
    }

    guard let frameRenderer = ownerElement?.renderer() else { return false }

    // iframes should fill with a base color if the used color scheme of the
    // element and the used color scheme of the embedded document’s root
    // element do not match.
    if frameView.useDarkAppearance() != frameRenderer.useDarkAppearance() {
      return !frameView.isTransparent()
    }

    return false
  }

  func hasQuotesNeedingUpdate() -> Bool { return m_hasQuotesNeedingUpdate }

  func incrementRendersWithOutline() {
    assert(isNativeImpl())
    m_renderersWithOutlineCount += 1
  }

  func decrementRendersWithOutline() {
    assert(isNativeImpl())
    assert(m_renderersWithOutlineCount > 0)
    m_renderersWithOutlineCount -= 1
  }

  func hasRenderersWithOutline() -> Bool {
    assert(isNativeImpl())
    return m_renderersWithOutlineCount != 0
  }

  func hasSoftwareFilters() -> Bool { return m_hasSoftwareFilters }

  func rendererCount() -> UInt64 { return m_rendererCount }

  func didCreateRenderer() {
    m_rendererCount += 1
  }

  func updateVisibleViewportRect(_ visibleRect: IntRect) {
    assert(isNativeImpl())
    resumePausedImageAnimationsIfNeeded(visibleRect)

    for rendererRaw in m_visibleInViewportRenderers {
      let renderer = Unmanaged<RenderElementWrapper>.fromOpaque(
        UnsafeRawPointer(bitPattern: rendererRaw)!
      ).takeUnretainedValue()
      let state: VisibleInViewportState =
        visibleRect.intersects(
          other: enclosingIntRect(rect: renderer.absoluteClippedOverflowRectForRepaint()))
        ? .Yes : .No
      renderer.setVisibleInViewportState(state)
    }
  }

  private func resumePausedImageAnimationsIfNeeded(_ visibleRect: IntRect) {
    assert(isNativeImpl())
    // TODO(asuhan): use array with inline storage
    var toRemove: [(RenderElementWrapper, WeakNullableRef<CachedImageWrapper>)] = []
    for (rendererRaw, cachedImages) in m_renderersWithPausedImageAnimation {
      for image in cachedImages {
        let renderer = Unmanaged<RenderElementWrapper>.fromOpaque(
          UnsafeRawPointer(bitPattern: rendererRaw)!
        ).takeUnretainedValue()
        if renderer.repaintForPausedImageAnimationsIfNeeded(visibleRect, *image) {
          toRemove.append((renderer, image))
        }
      }
    }
    for (renderer, image) in toRemove {
      removeRendererWithPausedImageAnimations(renderer, *image)
    }

    var svgSvgElementsToRemove: [SVGSVGElementWrapper] = []
    for svgSvgElementRaw in m_SVGSVGElementsWithPausedImageAnimation {
      let svgSvgElement = Unmanaged<SVGSVGElementWrapper>.fromOpaque(
        UnsafeRawPointer(bitPattern: svgSvgElementRaw)!
      ).takeUnretainedValue()
      if svgSvgElement.resumePausedAnimationsIfNeeded(visibleRect) {
        svgSvgElementsToRemove.append(svgSvgElement)
      }
    }
    for svgSvgElement in svgSvgElementsToRemove {
      m_SVGSVGElementsWithPausedImageAnimation.remove(
        UInt(bitPattern: ObjectIdentifier(svgSvgElement)))
    }
  }

  private func removeRendererWithPausedImageAnimations(
    _ renderer: RenderElementWrapper, _ image: CachedImageWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  class RepaintRegionAccumulator {
    init(_ view: RenderViewWrapper?) {
      guard let rootRenderView = view?.document().topDocument().renderView() else {
        m_rootView = nil
        return
      }

      m_wasAccumulatingRepaintRegion = rootRenderView.accumulatedRepaintRegion != nil
      if !m_wasAccumulatingRepaintRegion {
        rootRenderView.accumulatedRepaintRegion = Region()
      }
      m_rootView = rootRenderView
    }

    func destroy() {
      if m_wasAccumulatingRepaintRegion || m_rootView == nil {
        return
      }
      m_rootView!.flushAccumulatedRepaintRegion()
    }

    private let m_rootView: RenderViewWrapper?
    private var m_wasAccumulatingRepaintRegion = false
  }

  func layerChildrenChangedDuringStyleChange(_ layer: RenderLayerWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func takeStyleChangeLayerTreeMutationRoot() -> RenderLayerWrapper? {
    assert(isNativeImpl())
    let result = m_styleChangeLayerMutationRoot
    m_styleChangeLayerMutationRoot = nil
    return result
  }

  func registerBoxWithScrollSnapPositions(_ box: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func unregisterBoxWithScrollSnapPositions(_ box: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func registerContainerQueryBox(_ box: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func unregisterContainerQueryBox(_ box: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func viewTransitionRoot() -> RenderElementWrapper? {
    assert(isNativeImpl())
    return m_viewTransitionRoot
  }

  func setViewTransitionRoot(renderer: RenderElementWrapper) {
    assert(isNativeImpl())
    m_viewTransitionRoot = renderer
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)

    let writingModeChanged = oldStyle != nil && style().writingMode() != oldStyle!.writingMode()
    let directionChanged = oldStyle != nil && style().direction() != oldStyle!.direction()

    if (writingModeChanged || directionChanged) && multiColumnFlowForBlockFlow() != nil {
      if protectedFrameView().pagination().mode != .Unpaginated {
        updateColumnProgressionFromStyle(style())
      }
      updateStylesForColumnChildren(oldStyle)
    }

    if directionChanged {
      frameView().topContentDirectionDidChange()
    }
  }

  override func mapLocalToContainer(
    _ ancestorContainer: RenderLayerModelObjectWrapper?, _ transformState: TransformState,
    _ mode: MapCoordinatesMode, _ wasFixed: inout Bool?
  ) {
    // If a container was specified, and was not nullptr or the RenderView,
    // then we should have found it by now.
    assert(ancestorContainer == nil || CPtrToInt(ancestorContainer!.id()) == CPtrToInt(id()))
    assert(wasFixed == nil || wasFixed! == mode.contains(.IsFixed))

    if mode.contains(.IsFixed) {
      transformState.move(
        toLayoutSize(point: protectedFrameView().scrollPositionRespectingCustomFixedPosition()))
    }

    if ancestorContainer == nil && mode.contains(.UseTransforms)
      && shouldUseTransformFromContainer(nil)
    {
      let t = getTransformFromContainer(LayoutSizeWrapper())
      transformState.applyTransform(t)
    }
  }

  override func pushMappingToContainer(
    _ ancestorToStopAt: RenderLayerModelObjectWrapper?, _ geometryMap: RenderGeometryMap
  ) -> RenderObjectWrapper? {
    // If a container was specified, and was not nullptr or the RenderView,
    // then we should have found it by now.
    assert(ancestorToStopAt == nil || CPtrToInt(ancestorToStopAt!.id()) == CPtrToInt(id()))

    let scrollPosition = protectedFrameView().scrollPositionRespectingCustomFixedPosition()

    if ancestorToStopAt == nil && shouldUseTransformFromContainer(nil) {
      let t = getTransformFromContainer(LayoutSizeWrapper())
      geometryMap.pushView(self, toLayoutSize(point: scrollPosition), t)
    } else {
      geometryMap.pushView(self, toLayoutSize(point: scrollPosition))
    }

    return nil
  }

  override func mapAbsoluteToLocalPoint(
    _ mode: MapCoordinatesMode, _ transformState: inout TransformState
  ) {
    if mode.contains(.UseTransforms) && shouldUseTransformFromContainer(nil) {
      let t = getTransformFromContainer(LayoutSizeWrapper())
      transformState.applyTransform(t)
    }

    if mode.contains(.IsFixed) {
      transformState.move(
        toLayoutSize(point: protectedFrameView().scrollPositionRespectingCustomFixedPosition()))
    }
  }

  override func requiresColumns(desiredColumnCount: Int32) -> Bool {
    assert(isNativeImpl())
    return protectedFrameView().pagination().mode != .Unpaginated
  }

  override func computeColumnCountAndWidth() {
    var columnWidth = contentLogicalWidth().int()
    if style().hasInlineColumnAxis() {
      let pageLength = protectedFrameView().pagination().pageLength
      if pageLength != 0 {
        columnWidth = Int32(pageLength)
      }
    }
    setComputedColumnCountAndWidth(count: 1, width: LayoutUnit(value: columnWidth))
  }

  private func shouldRepaint(_ rect: LayoutRectWrapper) -> Bool {
    assert(isNativeImpl())
    return !printing() && !rect.isEmpty()
  }

  func flushAccumulatedRepaintRegion() {
    let repaintRects = accumulatedRepaintRegion!.rects()
    for rect in repaintRects {
      protectedFrameView().repaintContentRectangle(rect)
    }
    accumulatedRepaintRegion = nil
  }

  private func updateInitialContainingBlockSize() {
    assert(isNativeImpl())
    // Initial containing block has no margin/padding/border.
    m_layoutState!.ensureGeometryForBox(layoutBox: m_initialContainingBlock!).setContentBoxSize(
      size: LayoutSizeWrapper(size: frameView().size()))
  }

  private func shouldUsePrintingLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // TODO(asuhan): remove
  func setWk(_ wk: UnsafeMutableRawPointer) { self.wk = wk }

  func getWk() -> UnsafeMutableRawPointer { return wk! }

  private var m_frameView: LocalFrameViewWrapper? = nil

  private var m_compositor: RenderLayerCompositorWrapper? = nil

  private let m_hasQuotesNeedingUpdate = false

  // Include this RenderView.
  private var m_rendererCount: UInt64 = 1

  private var m_renderersWithOutlineCount: UInt32 = 0

  private let m_hasSoftwareFilters = false
  private var m_needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly = false
  private let m_needsEventRegionUpdateForNonCompositedFrame = false

  // Note that currently RenderView::layoutBox(), if it exists, is a child of m_initialContainingBlock.
  private var m_initialContainingBlock: InitialContainingBlock? = nil
  private var m_layoutState: LayoutStateWrapper? = nil

  private var accumulatedRepaintRegion: Region? = nil
  private var m_selection: RenderSelection? = nil

  private var m_styleChangeLayerMutationRoot: RenderLayerWrapper? = nil

  private var pageLogicalSize: LayoutSizeWrapper? = nil
  private var pageLogicalHeightChanged = false

  private let m_renderersWithPausedImageAnimation: [UInt: [WeakNullableRef<CachedImageWrapper>]] =
    [:]
  private var m_SVGSVGElementsWithPausedImageAnimation: Set<UInt> = []
  private let m_visibleInViewportRenderers: Set<UInt> = []

  private var m_viewTransitionRoot: RenderElementWrapper? = nil

  private var wk: UnsafeMutableRawPointer? = nil
}
