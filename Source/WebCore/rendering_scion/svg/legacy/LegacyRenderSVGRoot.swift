/*
 * Copyright (C) 2004, 2005, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2007, 2008, 2009 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009-2023 Google, Inc.
 * Copyright (C) 2009 Apple Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
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

final class LegacyRenderSVGRootWrapper: RenderReplacedWrapper {
  private func svgSVGElement() -> SVGSVGElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isEmbeddedThroughFrameContainingSVGDocument() -> Bool {
    // If our frame has an owner renderer, we're embedded through eg. object/embed/iframe,
    // but we only negotiate if we're in an SVG document inside object/embed, not iframe.
    if frame().ownerRenderer() == nil || frame().ownerRenderer()!.isRenderEmbeddedObject()
      || !isDocumentElementRenderer()
    {
      return false
    }
    return frame().document()!.isSVGDocument()
  }

  override func computeIntrinsicRatioInformation() -> (FloatSize, FloatSize) {
    assert(!shouldApplySizeContainment())

    // https://www.w3.org/TR/SVG/coords.html#IntrinsicSizing
    let intrinsicSize = calculateIntrinsicSize()

    if style().aspectRatioType() == .Ratio {
      let intrinsicRatio = FloatSize.narrowPrecision(
        width: style().aspectRatioLogicalWidth(), height: style().aspectRatioLogicalHeight())
      return (intrinsicSize, intrinsicRatio)
    }

    var intrinsicRatioValue: FloatSize? = nil
    var intrinsicRatio = FloatSize()
    if !intrinsicSize.isEmpty() {
      intrinsicRatio = FloatSize(width: intrinsicSize.width, height: intrinsicSize.height)
    } else {
      let viewBoxSize = svgSVGElement().viewBox().size()
      if !viewBoxSize.isEmpty() {
        // The viewBox can only yield an intrinsic ratio, not an intrinsic size.
        intrinsicRatioValue = FloatSize(width: viewBoxSize.width, height: viewBoxSize.height)
      }
    }

    if intrinsicRatioValue != nil {
      intrinsicRatio = intrinsicRatioValue!
    } else if style().aspectRatioType() == .AutoAndRatio {
      intrinsicRatio = FloatSize.narrowPrecision(
        width: style().aspectRatioLogicalWidth(), height: style().aspectRatioLogicalHeight())
    }
    return (intrinsicSize, intrinsicRatio)
  }

  override final func hasIntrinsicAspectRatio() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func setNeedsTransformUpdate() { needsBoundariesOrTransformUpdate = true }

  override final func computeReplacedLogicalWidth(
    shouldComputePreferred: ShouldComputePreferred = .ComputeActual
  )
    -> LayoutUnit
  {
    // When we're embedded through SVGImage (border-image/background-image/<html:img>/...) we're forced to resize to a specific size.
    if !m_containerSize.isEmpty() {
      return LayoutUnit(value: m_containerSize.width)
    }

    if isEmbeddedThroughFrameContainingSVGDocument() {
      return containingBlock()!.availableLogicalWidth()
    }

    // SVG embedded via SVGImage (background-image/border-image/etc) / Inline SVG.
    return super.computeReplacedLogicalWidth(shouldComputePreferred: shouldComputePreferred)
  }

  override func computeReplacedLogicalHeight(estimatedUsedWidth: LayoutUnit? = nil) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    let _ = SetForScope(scopedVariable: &inLayout, newValue: true)
    // TODO(asuhan): add stack stats
    assert(needsLayout())

    resourcesNeedingToInvalidateClients.clear()

    // Arbitrary affine transforms are incompatible with RenderLayoutState.
    let _ = LayoutStateDisabler(context: view().frameView().layoutContext())

    let needsLayout = selfNeedsLayout()
    let checkForRepaintOverride: LayoutRepainter.CheckForRepaint? = !needsLayout ? .No : nil
    let repainter = LayoutRepainter(
      renderer: self, checkForRepaintOverride: checkForRepaintOverride)

    let oldSize = size()
    updateLogicalWidth()
    updateLogicalHeight()
    buildLocalToBorderBoxTransform()

    isLayoutSizeChanged = needsLayout || (svgSVGElement().hasRelativeLengths() && oldSize != size())
    SVGRenderSupport.layoutChildren(
      self, needsLayout || SVGRenderSupport.filtersForceContainerLayout(self))

    if !resourcesNeedingToInvalidateClients.isEmptyIgnoringNullReferences() {
      // Invalidate resource clients, which may mark some nodes for layout.
      for resource in resourcesNeedingToInvalidateClients {
        resource.removeAllClientsFromCache()
        SVGResourcesCache.clientStyleChanged(
          resource, .Layout, oldStyle: nil, newStyle: resource.style())
      }

      isLayoutSizeChanged = false
      SVGRenderSupport.layoutChildren(self, false)
    }

    // At this point LayoutRepainter already grabbed the old bounds,
    // recalculate them now so repaintAfterLayout() uses the new bounds.
    if needsBoundariesOrTransformUpdate {
      updateCachedBoundaries()
      needsBoundariesOrTransformUpdate = false
    }

    clearOverflow()
    if !shouldApplyViewportClip() {
      var contentRepaintRect = repaintRectInLocalCoordinates()
      contentRepaintRect = localToBorderBoxTransform.mapRect(rect: contentRepaintRect)
      addVisualOverflow(rect: enclosingLayoutRect(rect: contentRepaintRect))
    }

    updateLayerTransform()
    hasBoxDecorations =
      isDocumentElementRenderer() ? hasVisibleBoxDecorationStyle() : hasVisibleBoxDecorations()
    invalidateBackgroundObscurationStatus()

    repainter.repaintAfterLayout()

    clearNeedsLayout()
  }

  override final func paintReplaced(
    _ paintInfo: inout PaintInfoWrapper, _ paintOffset: LayoutPointWrapper
  ) {
    // An empty viewport disables rendering.
    let clipViewport = shouldApplyViewportClip()
    if clipViewport && contentSize().isEmpty() {
      return
    }

    // Don't paint, if the context explicitly disabled it.
    if paintInfo.phase != .EventRegion && paintInfo.context().paintingDisabled()
      && !paintInfo.context().detectingContentfulPaint()
    {
      return
    }

    // SVG outlines are painted during foreground phase.
    if paintInfo.phase == .Outline || paintInfo.phase == .SelfOutline {
      return
    }

    // An empty viewBox also disables rendering.
    // (http://www.w3.org/TR/SVG/coords.html#ViewBoxAttribute)
    if svgSVGElement().hasEmptyViewBox() {
      return
    }

    let context = paintInfo.context()
    if context.detectingContentfulPaint() {
      for current: RenderObjectWrapper in childrenOfType(parent: self) {
        if !current.isLegacyRenderSVGHiddenContainer() {
          context.setContentfulPaintDetected()
          return
        }
      }
      return
    }

    // Don't paint if we don't have kids, except if we have filters we should paint those.
    if firstChild() == nil {
      let resources = SVGResourcesCache.cachedResourcesForRenderer(self)
      if resources?.filter() == nil {
        if paintInfo.phase == .Foreground {
          page().addRelevantUnpaintedObject(object: self, objectPaintRect: visualOverflowRect())
        }
        return
      }
    }

    if paintInfo.phase == .Foreground {
      page().addRelevantRepaintedObject(object: self, objectPaintRect: visualOverflowRect())
    }

    // Make a copy of the PaintInfo because applyTransform will modify the damage rect.
    var childPaintInfo = paintInfo.deepCopy()
    childPaintInfo.context().save()

    // Apply initial viewport clip
    if clipViewport {
      let clipRect = snappedIntRect(rect: overflowClipRect(location: paintOffset))
      childPaintInfo.context().clip(rect: FloatRectWrapper(r: clipRect))
      if paintInfo.phase == .EventRegion && childPaintInfo.eventRegionContext() != nil {
        childPaintInfo.eventRegionContext()!.pushClip(clipRect: clipRect)
      }
    }

    // Convert from container offsets (html renderers) to a relative transform (svg renderers).
    // Transform from our paint container's coordinate system to our local coords.
    let adjustedPaintOffset = roundedIntPoint(point: paintOffset)
    let transform =
      AffineTransform.makeTranslation(toFloatSize(a: FloatPoint(p: adjustedPaintOffset)))
      * localToBorderBoxTransform
    childPaintInfo.applyTransform(transform)
    if paintInfo.phase == .EventRegion && childPaintInfo.eventRegionContext() != nil {
      childPaintInfo.eventRegionContext()!.pushTransform(transform: transform)
    }

    // SVGRenderingContext must be destroyed before we restore the childPaintInfo.context(), because a filter may have
    // changed the context and it is only reverted when the SVGRenderingContext destructor finishes applying the filter.
    do {
      let renderingContext = SVGRenderingContext()
      var continueRendering = true
      if childPaintInfo.phase == .Foreground {
        renderingContext.prepareToRenderSVGContent(self, childPaintInfo)
        continueRendering = renderingContext.isRenderingPrepared()
      }

      if continueRendering {
        childPaintInfo.updateSubtreePaintRootForChildren(renderer: self)
        for child: RenderElementWrapper in childrenOfType(parent: self) {
          child.paint(paintInfo: &childPaintInfo, paintOffset: location())
        }
      }
    }

    if paintInfo.phase == .EventRegion && childPaintInfo.eventRegionContext() != nil {
      childPaintInfo.eventRegionContext()!.popTransform()
      if clipViewport {
        childPaintInfo.eventRegionContext()!.popClip()
      }
    }
    childPaintInfo.context().restore()
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func localToParentTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func repaintRectInLocalCoordinates(
    _ repaintRectCalculation: RepaintRectCalculation = .Fast
  ) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func clippedOverflowRect(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ context: VisibleRectContext
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func rectsForRepaintingAfterLayout(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ repaintOutlineBounds: RepaintOutlineBounds
  ) -> RepaintRects {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func mapLocalToContainer(
    _ ancestorContainer: RenderLayerModelObjectWrapper?, _ transformState: TransformState,
    _ mode: MapCoordinatesMode, _ wasFixed: inout Bool?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func pushMappingToContainer(
    _ ancestorToStopAt: RenderLayerModelObjectWrapper?, _ geometryMap: RenderGeometryMap
  ) -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func canBeSelectionLeaf() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func shouldApplyViewportClip() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateCachedBoundaries() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func buildLocalToBorderBoxTransform() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func calculateIntrinsicSize() -> FloatSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let m_containerSize = IntSize()
  private var inLayout = false
  private let localToBorderBoxTransform = AffineTransform()
  private let resourcesNeedingToInvalidateClients = WeakHashSet<LegacyRenderSVGResourceContainer>()
  var isLayoutSizeChanged = false
  private var needsBoundariesOrTransformUpdate = false
  private var hasBoxDecorations = false
}
