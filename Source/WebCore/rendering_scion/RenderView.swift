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

class RenderViewWrapper: RenderBlockFlowWrapper {
  override func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
      minPreferredLogicalWidth = pageLogicalSize!.width()
      maxPreferredLogicalWidth = minPreferredLogicalWidth
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func availableLogicalHeight(heightType: AvailableLogicalHeightType) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The same as the FrameView's layoutHeight/layoutWidth but with null check guards.
  private func viewHeight() -> Int32 {
    var height: Int32 = 0
    if !shouldUsePrintingLayout() {
      let frameView = frameView()
      height = frameView.layoutHeight()
      height = Int32(
        frameView.useFixedLayout() ? ceilf(style().usedZoom() * Float32(height)) : Float32(height))
    }
    return height
  }

  private func viewWidth() -> Int32 {
    var width: Int32 = 0
    if !shouldUsePrintingLayout() {
      let frameView = frameView()
      width = frameView.layoutWidth()
      width = Int32(
        frameView.useFixedLayout() ? ceilf(style().usedZoom() * Float32(width)) : Float32(width))
    }
    return width
  }

  private func viewLogicalHeight() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    return LocalFrameViewWrapper(p: wk_interop.RenderView_frameView(p))
  }

  func protectedFrameView() -> LocalFrameViewWrapper {
    return frameView()  // TODO(asuhan): just remove this wrapper, not needed in Swift
  }

  func layoutState() -> LayoutStateWrapper {
    return LayoutStateWrapper(p: wk_interop.RenderView_layoutState(p))
  }

  func needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNeedsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly(_ value: Bool = true) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func needsEventRegionUpdateForNonCompositedFrame() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func compositor() -> RenderLayerCompositorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func usesCompositing() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func hasQuotesNeedingUpdate() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func incrementRendersWithOutline() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func decrementRendersWithOutline() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasRenderersWithOutline() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setViewTransitionRoot(renderer: RenderElementWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  override func requiresColumns(desiredColumnCount: Int32) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateInitialContainingBlockSize() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func shouldUsePrintingLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var accumulatedRepaintRegion: Region? = nil
  private var pageLogicalSize: LayoutSizeWrapper? = nil
  private var pageLogicalHeightChanged = false
}
