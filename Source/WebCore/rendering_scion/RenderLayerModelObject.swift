/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2006, 2007, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2010, 2012 Google Inc. All rights reserved.
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

import wk_interop

class RenderLayerModelObjectWrapper: RenderElementWrapper {
  init(
    _ type: RenderObjectWrapper.`Type`, _ document: Document, _ style: RenderStyleWrapper,
    _ baseTypeFlags: RenderObjectWrapper.TypeFlag,
    _ typeSpecificFlags: RenderObjectWrapper.TypeSpecificFlags
  ) {
    super.init(
      type: type, document: document, style, baseTypeFlags.union(.IsLayerModelObject),
      typeSpecificFlags)
    assert(isRenderLayerModelObject())
  }

  override init(p: UnsafeMutableRawPointer) { super.init(p: p) }

  func hasSelfPaintingLayerModelObject() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layer() -> RenderLayerWrapper? {
    if let rawLayer = wk_interop.RenderLayerModelObject_layer(p) {
      return RenderLayerWrapper(p: rawLayer)
    }
    return nil
  }

  func checkedLayer() -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleWillChange(diff: StyleDifference, newStyle: RenderStyleWrapper) {
    RenderLayerModelObjectWrapper.s_wasFloating = isFloating()
    RenderLayerModelObjectWrapper.s_hadLayer = hasLayer()
    RenderLayerModelObjectWrapper.s_wasTransformed = isTransformed()
    if RenderLayerModelObjectWrapper.s_hadLayer {
      RenderLayerModelObjectWrapper.s_layerWasSelfPainting = layer()!.isSelfPaintingLayer
    }

    let oldStyle: RenderStyleWrapper? = hasInitializedStyle ? style() : nil
    if diff == .RepaintLayer && parent() != nil && oldStyle != nil
      && oldStyle!.clip() != newStyle.clip()
    {
      layer()!.clearClipRectsIncludingDescendants()
    }
    super.styleWillChange(diff: diff, newStyle: newStyle)
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)
    updateFromStyle()

    // When an out-of-flow-positioned element changes its display between block and inline-block,
    // then an incremental layout on the element's containing block lays out the element through
    // LayoutPositionedObjects, which skips laying out the element's parent.
    // The element's parent needs to relayout so that it calls
    // RenderBlockFlow::setStaticInlinePositionForChild with the out-of-flow-positioned child, so
    // that when it's laid out, its RenderBox::computePositionedLogicalWidth/Height takes into
    // account its new inline/block position rather than its old block/inline position.
    // Position changes and other types of display changes are handled elsewhere.
    if (oldStyle != nil && isOutOfFlowPositioned() && parent() != nil
      && (CPtrToInt(parent()!.p) != CPtrToInt(containingBlock()?.p)))
      && (style().position() == oldStyle!.position())
      && (style().isOriginalDisplayInlineType() != oldStyle!.isOriginalDisplayInlineType())
      && ((style().isOriginalDisplayBlockType()) || (style().isOriginalDisplayInlineType()))
      && ((oldStyle!.isOriginalDisplayBlockType()) || (oldStyle!.isOriginalDisplayInlineType()))
    {
      parent()!.setChildNeedsLayout()
    }

    var gainedOrLostLayer = false
    if requiresLayer() {
      if layer() == nil && layerCreationAllowedForSubtree() {
        gainedOrLostLayer = true
        if RenderLayerModelObjectWrapper.s_wasFloating && isFloating() {
          setChildNeedsLayout()
        }
        createLayer()
        if parent() != nil && !needsLayout() && containingBlock() != nil {
          layer()!.repaintStatus = .NeedsFullRepaint
        }
      }
    } else if layer()?.parent() != nil {
      gainedOrLostLayer = true
      if oldStyle?.hasBlendMode() ?? false {
        layer()!.willRemoveChildWithBlendMode()
      }
      setHasTransformRelatedProperty(false)  // All transform-related properties force layers, so we know we don't have one or the object doesn't support them.
      setHasSVGTransform(false)  // Same reason as for setHasTransformRelatedProperty().
      setHasReflection(false)

      // Repaint the about to be destroyed self-painting layer when style change also triggers repaint.
      if layer()!.isSelfPaintingLayer && layer()!.repaintStatus == .NeedsFullRepaint
        && layer()!.cachedClippedOverflowRect() != nil
      {
        repaintUsingContainer(containerForRepaint().renderer, layer()!.cachedClippedOverflowRect()!)
      }

      layer()!.removeOnlyThisLayer(timing: .StyleChange)  // calls destroyLayer() which clears m_layer
      if RenderLayerModelObjectWrapper.s_wasFloating && isFloating() {
        setChildNeedsLayout()
      }
      if RenderLayerModelObjectWrapper.s_wasTransformed {
        setNeedsLayoutAndPrefWidthsRecalc()
      }
    }

    if gainedOrLostLayer {
      InspectorInstrumentationWrapper.didAddOrRemoveScrollbars(renderer: self)
    }

    if layer() != nil {
      layer()!.styleChanged(diff: diff, oldStyle: oldStyle)
      if RenderLayerModelObjectWrapper.s_hadLayer
        && layer()!.isSelfPaintingLayer != RenderLayerModelObjectWrapper.s_layerWasSelfPainting
      {
        setChildNeedsLayout()
      }
    }

    let newStyleIsViewportConstrained = style().hasViewportConstrainedPosition()
    let oldStyleIsViewportConstrained = oldStyle?.hasViewportConstrainedPosition() ?? false
    if newStyleIsViewportConstrained != oldStyleIsViewportConstrained {
      if newStyleIsViewportConstrained && layer() != nil {
        view().frameView().addViewportConstrainedObject(self)
      } else {
        view().frameView().removeViewportConstrainedObject(self)
      }
    }

    let newStyle = style()
    if oldStyle != nil && oldStyle!.scrollPadding() != newStyle.scrollPadding() {
      if isDocumentElementRenderer() {
        let frameView = view().frameView()
        frameView.updateScrollbarSteps()
      } else if let renderLayer = layer() {
        renderLayer.updateScrollbarSteps()
      }
    }

    let scrollMarginChanged = oldStyle != nil && oldStyle!.scrollMargin() != newStyle.scrollMargin()
    let scrollAlignChanged =
      oldStyle != nil && oldStyle!.scrollSnapAlign() != newStyle.scrollSnapAlign()
    let scrollSnapStopChanged =
      oldStyle != nil && oldStyle!.scrollSnapStop() != newStyle.scrollSnapStop()
    if scrollMarginChanged || scrollAlignChanged || scrollSnapStopChanged,
      let scrollSnapBox = enclosingScrollableContainer()
    {
      scrollSnapBox.setNeedsLayout()
    }
  }

  func requiresLayer() -> Bool { fatalError("Not reached") }

  // Returns true if the background is painted opaque in the given rect.
  // The query rect is given in local coordinate system.
  func backgroundIsKnownToBeOpaqueInRect(_ localRect: LayoutRectWrapper) -> Bool { return false }

  // Returns false if the rect has no intersection with the applied clip rect. When the context specifies edge-inclusive
  // intersection, this return value allows distinguishing between no intersection and zero-area intersection.
  @discardableResult
  func applyCachedClipAndScrollPosition(
    _ rects: inout RepaintRects, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> Bool { return false }

  func shouldPlaceVerticalScrollbarOnLeftForLayerModelObject() -> Bool {
    return wk_interop.RenderLayerModelObject_shouldPlaceVerticalScrollbarOnLeft(p)
  }

  // Single source of truth deciding if a SVG renderer should be painted. All SVG renderers
  // use this method to test if they should continue processing in the paint() function or stop.
  func shouldPaintSVGRenderer(_ paintInfo: PaintInfoWrapper, _ relevantPaintPhases: PaintPhase = [])
    -> Bool
  {
    if paintInfo.context().paintingDisabled() {
      return false
    }

    if !relevantPaintPhases.isEmpty && !relevantPaintPhases.contains(paintInfo.phase) {
      return false
    }

    if !paintInfo.shouldPaintWithinRoot(renderer: self) {
      return false
    }

    if style().usedVisibility() == .Hidden || style().display() == .None {
      return false
    }

    return true
  }

  // Provides the SVG implementation for computeVisibleRectsInContainer().
  // This lives in RenderLayerModelObject, which is the common base-class for all SVG renderers.
  func computeVisibleRectsInSVGContainer(
    _ rects: RepaintRects, _ container: RenderLayerModelObjectWrapper?,
    _ context: RenderObjectWrapper.VisibleRectContext
  ) -> RepaintRects? {
    assert(self is RenderSVGModelObjectWrapper || self is RenderSVGBlockWrapper)
    assert(!style().hasInFlowPosition())
    assert(!view().frameView().layoutContext().isPaintOffsetCacheEnabled())

    if CPtrToInt(container?.p) == CPtrToInt(p) {
      return rects
    }

    let (localContainer, containerIsSkipped) = self.container(container)
    if localContainer == nil {
      return rects
    }

    assert(!containerIsSkipped)

    var adjustedRects = rects

    var locationOffset = LayoutSizeWrapper()
    if let modelObject = self as? RenderSVGModelObjectWrapper {
      locationOffset = modelObject.locationOffsetEquivalent()
    } else if let svgBlock = self as? RenderSVGBlockWrapper {
      locationOffset = svgBlock.locationOffset()
    }

    // We are now in our parent container's coordinate space. Apply our transform to obtain a bounding box
    // in the parent's coordinate space that encloses us.
    if hasLayer() && layer()!.transform != nil {
      adjustedRects.transform(layer()!.transform!)
    }

    adjustedRects.move(locationOffset)

    if localContainer!.hasNonVisibleOverflow() {
      let isEmpty = !(localContainer as! RenderLayerModelObjectWrapper)
        .applyCachedClipAndScrollPosition(&adjustedRects, container, context)
      if isEmpty {
        if context.options.contains(.UseEdgeInclusiveIntersection) {
          return nil
        }
        return adjustedRects
      }
    }

    return localContainer!.computeVisibleRectsInContainer(adjustedRects, container, context)
  }

  // Provides the SVG implementation for mapLocalToContainer().
  // This lives in RenderLayerModelObject, which is the common base-class for all SVG renderers.
  func mapLocalToSVGContainer(
    _ ancestorContainer: RenderLayerModelObjectWrapper, _ transformState: TransformState,
    _ mode: MapCoordinatesMode, _ wasFixed: inout Bool?
  ) {
    assert(self is RenderSVGModelObjectWrapper || self is RenderSVGBlockWrapper)
    assert(style().position() == .Static)

    if CPtrToInt(ancestorContainer.p) == CPtrToInt(p) {
      return
    }

    assert(!view().frameView().layoutContext().isPaintOffsetCacheEnabled())

    let (container, ancestorSkipped) = container(ancestorContainer)
    if container == nil {
      return
    }

    assert(!ancestorSkipped)

    // If this box has a transform, it acts as a fixed position container for fixed descendants,
    // and may itself also be fixed position. So propagate 'fixed' up only if this box is fixed position.
    var mode = mode
    if isTransformed() {
      mode.remove(.IsFixed)
    }

    var unused: Bool? = nil
    let containerOffset = offsetFromContainer(
      container!, LayoutPointWrapper(size: transformState.mappedPoint()), &unused)

    pushOntoTransformState(transformState, mode, nil, container, containerOffset, false)

    mode.remove(.ApplyContainerFlip)

    container!.mapLocalToContainer(ancestorContainer, transformState, mode, &wasFixed)
  }

  func updateHasSVGTransformFlags() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nominalSVGLayoutLocation() -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func currentSVGLayoutLocation() -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setCurrentSVGLayoutLocation(_ location: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func svgClipperResourceFromStyle() -> RenderSVGResourceClipperWrapper? {
    if !document().settings().layerBasedSVGEngineEnabled() {
      return nil
    }

    guard let referenceClipPathOperation = style().clipPath() as? ReferencePathOperation
    else { return nil }

    if let referencedClipPathElement = ReferencedSVGResources.referencedClipPathElement(
      treeScopeForSVGReferences(), referenceClipPathOperation),
      let referencedClipperRenderer = referencedClipPathElement.renderer()
        as? RenderSVGResourceClipperWrapper
    {
      return referencedClipperRenderer
    }

    if let svgElement = element() as? SVGElementWrapper {
      document().addPendingSVGResource(referenceClipPathOperation.fragment, svgElement)
    }

    return nil
  }

  func svgFilterResourceFromStyle() -> RenderSVGResourceFilter? {
    if !document().settings().layerBasedSVGEngineEnabled() {
      return nil
    }

    let operations = style().filter()
    if operations.size() != 1 {
      return nil
    }

    guard let referenceFilterOperation = operations.at(0) as? ReferenceFilterOperationWrapper else {
      return nil
    }

    if let referencedFilterElement = ReferencedSVGResources.referencedFilterElement(
      treeScope: treeScopeForSVGReferences(), referenceFilter: referenceFilterOperation),
      let referencedFilterRenderer = referencedFilterElement.renderer() as? RenderSVGResourceFilter
    {
      return referencedFilterRenderer
    }

    if let svgElement = element() as? SVGElementWrapper {
      document().addPendingSVGResource(referenceFilterOperation.fragment(), svgElement)
    }

    return nil
  }

  func svgMaskerResourceFromStyle() -> RenderSVGResourceMasker? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func svgMarkerStartResourceFromStyle() -> RenderSVGResourceMarkerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func svgMarkerMidResourceFromStyle() -> RenderSVGResourceMarkerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func svgMarkerEndResourceFromStyle() -> RenderSVGResourceMarkerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pointInSVGClippingArea(_ point: FloatPoint) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSVGClippingMask(paintInfo: PaintInfoWrapper, objectBoundingBox: FloatRectWrapper) {
    assert(paintInfo.phase == .ClippingMask)
    let context = paintInfo.context()
    if !paintInfo.shouldPaintWithinRoot(renderer: self) || style().usedVisibility() != .Visible
      || context.paintingDisabled()
    {
      return
    }

    assert(document().settings().layerBasedSVGEngineEnabled())
    if let referencedClipperRenderer = svgClipperResourceFromStyle() {
      referencedClipperRenderer.applyMaskClipping(paintInfo, self, objectBoundingBox)
    }
  }

  func paintSVGMask(_ paintInfo: PaintInfoWrapper, _ adjustedPaintOffset: LayoutPointWrapper) {
    assert(paintInfo.phase == .Mask)
    let context = paintInfo.context()
    if !paintInfo.shouldPaintWithinRoot(renderer: self) || context.paintingDisabled() {
      return
    }

    assert(isSVGLayerAwareRenderer())
    if let referencedMaskerRenderer = svgMaskerResourceFromStyle() {
      referencedMaskerRenderer.applyMask(paintInfo, self, adjustedPaintOffset)
    }
  }

  func layerTransform() -> TransformationMatrix? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateLayerTransform() {
    if let box = self as? RenderBoxWrapper,
      style().offsetPath() != nil
        && MotionPath.needsUpdateAfterContainingBlockLayout(style().offsetPath()!),
      let containingBlock = containingBlock()
    {
      view().frameView().layoutContext().setBoxNeedsTransformUpdateAfterContainerLayout(
        box, containingBlock)
      return
    }
    // Transform-origin depends on box size, so we need to update the layer transform after layout.
    if hasLayer() {
      layer()!.updateTransform()
    }
  }

  func applyTransform(
    transform: inout TransformationMatrix, style: RenderStyleWrapper, boundingBox: FloatRectWrapper,
    options: RenderStyleWrapper.TransformOperationOption
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func createLayer() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateFromStyle() {}

  // Used to store state between styleWillChange and styleDidChange
  private static var s_wasFloating = false
  private static var s_hadLayer = false
  private static var s_wasTransformed = false
  private static var s_layerWasSelfPainting = false
}

// Pixel-snapping (== 'device pixel alignment') helpers.
func rendererNeedsPixelSnapping(renderer: RenderLayerModelObjectWrapper) -> Bool {
  if renderer.document().settings().layerBasedSVGEngineEnabled()
    && renderer.isSVGLayerAwareRenderer() && !renderer.isRenderSVGRoot()
  {
    return false
  }
  return true
}

func snapRectToDevicePixelsIfNeeded(
  rect: LayoutRectWrapper, renderer: RenderLayerModelObjectWrapper
) -> FloatRectWrapper {
  if !rendererNeedsPixelSnapping(renderer: renderer) {
    return rect.FloatRect()
  }
  return snapRectToDevicePixels(
    rect: rect, pixelSnappingFactor: renderer.document().deviceScaleFactor())
}

func snapRectToDevicePixelsIfNeeded(
  rect: FloatRectWrapper, renderer: RenderLayerModelObjectWrapper
) -> FloatRectWrapper {
  if !rendererNeedsPixelSnapping(renderer: renderer) {
    return rect
  }
  return snapRectToDevicePixels(
    rect: LayoutRectWrapper(r: rect), pixelSnappingFactor: renderer.document().deviceScaleFactor())
}
