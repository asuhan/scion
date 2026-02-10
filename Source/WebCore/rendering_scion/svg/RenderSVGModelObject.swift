/*
 * Copyright (c) 2009, Google Inc. All rights reserved.
 * Copyright (C) 2020, 2021, 2022, 2024 Igalia S.L.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

class RenderSVGModelObjectWrapper: RenderLayerModelObjectWrapper {
  override func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)

    // SVG masks are painted independent of the target renderers visibility.
    // FIXME: [LBSE] Upstream RenderElement changes
    // bool hasSVGMask = hasSVGMask();
    let hasSVGMask = false
    if hasSVGMask && hasLayer() && style().usedVisibility() != .Visible {
      layer()!.setHasVisibleContent()
    }
  }

  func currentSVGLayoutRect() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setCurrentSVGLayoutRect(_ layoutRect: LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func currentSVGLayoutLocation() -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func setCurrentSVGLayoutLocation(_ location: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Mimic the RenderBox accessors - by sharing the same terminology the painting / hit testing / layout logic is
  // similar to read compared to non-SVG renderers such as RenderBox & friends.
  func borderBoxRectEquivalent() -> LayoutRectWrapper {
    return LayoutRectWrapper(location: LayoutPointWrapper(), size: layoutRect.size())
  }

  func visualOverflowRectEquivalent() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func locationOffsetEquivalent() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasVisualOverflow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderBoxRectInFragmentEquivalent(
    fragment: RenderFragmentContainerWrapper?,
    flags: RenderBoxWrapper.RenderBoxFragmentInfoFlags = .CacheRenderBoxFragmentInfo
  ) -> LayoutRectWrapper {
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

  func computeClipPath(_ transform: AffineTransform) -> PathWrapper {
    if layer()!.isTransformed() {
      transform.multiply(
        layer()!.currentTransform(RenderStyleWrapper.individualTransformOperations)
          .toAffineTransform())
    }

    if let useElement = protectedElement() as? SVGUseElementWrapper {
      if let clipChildRenderer = useElement.rendererClipChild() {
        transform.multiply(
          (clipChildRenderer as! RenderLayerModelObjectWrapper).checkedLayer()!
            .currentTransform(RenderStyleWrapper.individualTransformOperations).toAffineTransform())
      }
      if let clipChild = useElement.clipChild() {
        return pathFromGraphicsElement(clipChild)
      }
    }

    return pathFromGraphicsElement(element() as! SVGGraphicsElementWrapper)
  }

  override func updateFromStyle() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func localRectsForRepaint(_ repaintOutlineBounds: RepaintOutlineBounds) -> RepaintRects {
    if isInsideEntirelyHiddenLayer() {
      return RepaintRects()
    }

    assert(!view().frameView().layoutContext().isPaintOffsetCacheEnabled())

    let visualOverflowRect = visualOverflowRectEquivalent()
    var rects = RepaintRects(rect: visualOverflowRect)
    if repaintOutlineBounds == .Yes {
      rects.outlineBoundsRect = visualOverflowRect
    }

    return rects
  }

  override func computeVisibleRectsInContainer(
    _ rects: RepaintRects, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> RepaintRects? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func mapLocalToContainer(
    _ ancestorContainer: RenderLayerModelObjectWrapper?, _ transformState: TransformState,
    _ mode: MapCoordinatesMode, _ wasFixed: inout Bool?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func outlineBoundsForRepaint(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ geometryMap: RenderGeometryMap? = nil
  )
    -> LayoutRectWrapper
  {
    assert(!view().frameView().layoutContext().isPaintOffsetCacheEnabled())

    var outlineBounds = visualOverflowRectEquivalent()

    if CPtrToInt(repaintContainer?.p) != CPtrToInt(p) {
      var containerRelativeQuad = FloatQuad()
      if geometryMap != nil {
        containerRelativeQuad = geometryMap!.mapToContainer(
          outlineBounds.FloatRect(), repaintContainer)
      } else {
        containerRelativeQuad = localToContainerQuad(
          localQuad: FloatQuad(inRect: outlineBounds.FloatRect()), container: repaintContainer)
      }

      outlineBounds = LayoutRectWrapper(r: containerRelativeQuad.boundingBox())
    }

    return outlineBounds
  }

  override func pushMappingToContainer(
    _ ancestorToStopAt: RenderLayerModelObjectWrapper?, _ geometryMap: RenderGeometryMap
  ) -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func offsetFromContainer(
    _ container: RenderElementWrapper, _ physicalPoint: LayoutPointWrapper,
    _ offsetDependsOnPoint: inout Bool?
  ) -> LayoutSizeWrapper {
    assert(CPtrToInt(container.p) == CPtrToInt(self.container()?.p))
    assert(!isInFlowPositioned())
    assert(!isAbsolutelyPositioned())
    assert(isInline())
    return locationOffsetEquivalent()
  }

  override func addFocusRingRects(
    rects: inout [LayoutRectWrapper], additionalOffset: LayoutPointWrapper,
    paintContainer: RenderLayerModelObjectWrapper? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSVGOutline(_ paintInfo: PaintInfoWrapper, _ adjustedPaintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns false if the rect has no intersection with the applied clip rect. When the context specifies edge-inclusive
  // intersection, this return value allows distinguishing between no intersection and zero-area intersection.
  @discardableResult
  override final func applyCachedClipAndScrollPosition(
    _ rects: inout RepaintRects, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> Bool {
    // Based on render box' applyCachedClipAndScrollPosition -- unused options removed.
    if !context.options.contains(.ApplyContainerClip) && CPtrToInt(p) == CPtrToInt(container?.p) {
      return true
    }

    var clipRect = LayoutRectWrapper(
      location: LayoutPointWrapper(), size: cachedSizeForOverflowClip())
    if effectiveOverflowX() == .Visible {
      clipRect.expandToInfiniteX()
    }
    if effectiveOverflowY() == .Visible {
      clipRect.expandToInfiniteY()
    }

    var intersects = false
    if context.options.contains(.UseEdgeInclusiveIntersection) {
      intersects = rects.edgeInclusiveIntersect(clipRect)
    } else {
      intersects = rects.intersect(clipRect)
    }

    return intersects
  }

  private func cachedSizeForOverflowClip() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let layoutRect = LayoutRectWrapper()
}
