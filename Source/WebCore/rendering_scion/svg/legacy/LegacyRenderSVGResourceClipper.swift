/*
 * Copyright (C) 2004, 2005, 2007, 2008 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Rob Buis <buis@kde.org>
 * Copyright (C) Research In Motion Limited 2009-2010. All rights reserved.
 * Copyright (C) 2011 Dirk Schulze <krit@webkit.org>
 * Copyright (C) 2022 Apple Inc. All rights reserved.
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

private class ClipperData {
  struct Inputs: Equatable {
    init() {
      self.init(
        objectBoundingBox: FloatRectWrapper(), clippedContentBounds: FloatRectWrapper(),
        FloatSize(), 1, false)
    }

    init(
      objectBoundingBox: FloatRectWrapper, clippedContentBounds: FloatRectWrapper,
      _ scale: FloatSize, _ usedZoom: Float32, _ paintingDisabled: Bool
    ) {
      self.objectBoundingBox = objectBoundingBox
      self.clippedContentBounds = clippedContentBounds
      self.scale = scale
      self.usedZoom = usedZoom
      self.paintingDisabled = paintingDisabled
    }

    let objectBoundingBox: FloatRectWrapper
    let clippedContentBounds: FloatRectWrapper
    let scale: FloatSize
    let usedZoom: Float32
    let paintingDisabled: Bool
  }

  func invalidate(_ inputs: Inputs) -> Bool {
    if self.inputs != inputs {
      imageBuffer = nil
      self.inputs = inputs
    }
    return imageBuffer == nil
  }

  var imageBuffer: ImageBufferWrapper? = nil
  var inputs = Inputs()
}

class LegacyRenderSVGResourceClipper: LegacyRenderSVGResourceContainer {
  private func clipPathElement() -> SVGClipPathElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func protectedClipPathElement() -> SVGClipPathElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func applyResource(
    _ renderer: RenderElementWrapper, _ style: RenderStyleWrapper,
    _ context: GraphicsContextWrapper, _ resourceMode: RenderSVGResourceMode
  ) -> LegacyRenderSVGResource.ApplyResult {
    assert(resourceMode.isEmpty)

    let repaintRect = renderer.repaintRectInLocalCoordinates()
    if repaintRect.isEmpty() {
      return [.ResourceApplied]
    }

    let boundingBox = renderer.objectBoundingBox()
    return applyClippingToContext(
      context: context, renderer: renderer, objectBoundingBox: boundingBox,
      clippedContentBounds: boundingBox)
  }

  // clipPath can be clipped too, but don't have a boundingBox or repaintRect. So we can't call
  // applyResource directly and use the rects from the object, since they are empty for RenderSVGResources
  // FIXME: We made applyClippingToContext public because we cannot call applyResource on HTML elements (it asserts on RenderObject::objectBoundingBox)
  // objectBoundingBox ia used to compute clip path geometry when clipPathUnits="objectBoundingBox".
  // clippedContentBounds is the bounds of the content to which clipping is being applied.
  @discardableResult
  func applyClippingToContext(
    context: GraphicsContextWrapper, renderer: RenderElementWrapper,
    objectBoundingBox: FloatRectWrapper, clippedContentBounds: FloatRectWrapper,
    usedZoom: Float32 = 1
  ) -> LegacyRenderSVGResource.ApplyResult {
    // TODO(asuhan): add logging

    let animatedLocalTransform = clipPathElement().animatedLocalTransform()

    let clipResult = pathOnlyClipping(
      context, renderer, animatedLocalTransform, objectBoundingBox, usedZoom)
    if resourceWasApplied(clipResult) {
      if clipperMap!.contains(renderer) {
        clipperMap!.get(renderer).imageBuffer = nil
      }

      return clipResult
    }

    var clipperData = clipperMap!.ensure(renderer, { () in return ClipperData() }).value

    if clipperData!.invalidate(
      computeInputs(
        context, renderer, objectBoundingBox: objectBoundingBox,
        clippedContentBounds: clippedContentBounds, usedZoom: usedZoom))
    {
      // FIXME (149469): This image buffer should not be unconditionally unaccelerated. Making it match the context breaks nested clipping, though.
      clipperData!.imageBuffer = context.createScaledImageBuffer(
        clippedContentBounds, clipperData!.inputs.scale, DestinationColorSpace.SRGB(),
        .Unaccelerated)  // FIXME
      if clipperData!.imageBuffer == nil {
        return []
      }

      let maskContext = clipperData!.imageBuffer!.context()
      maskContext.concatCTM(transform: animatedLocalTransform)

      // clipPath can also be clipped by another clipPath.
      var succeeded = false
      if let resources = SVGResourcesCache.cachedResourcesForRenderer(self),
        let clipper = resources.clipper()
      {
        let _ = GraphicsContextStateSaver(context: maskContext)

        if clipper.applyClippingToContext(
          context: maskContext, renderer: self, objectBoundingBox: objectBoundingBox,
          clippedContentBounds: clippedContentBounds
        ).isEmpty {
          return []
        }

        succeeded = drawContentIntoMaskImage(clipperData!.imageBuffer!, objectBoundingBox, usedZoom)
        // The context restore applies the clipping on non-CG platforms.
      } else {
        succeeded = drawContentIntoMaskImage(clipperData!.imageBuffer!, objectBoundingBox, usedZoom)
      }

      if !succeeded {
        clipperData = ClipperData()
      }
    }

    if clipperData!.imageBuffer == nil {
      return []
    }

    SVGRenderingContext.clipToImageBuffer(
      context, clippedContentBounds, clipperData!.inputs.scale, &clipperData!.imageBuffer, true)
    return [.ResourceApplied]
  }

  override func resourceBoundingBox(
    _ object: RenderObjectWrapper, _ repaintRectCalculation: RepaintRectCalculation
  ) -> FloatRectWrapper {
    // Resource was not layouted yet. Give back the boundingBox of the object.
    if selfNeedsLayout() {
      clipperMap!.ensure(
        object,
        { () in  // For selfNeedsClientInvalidation().
          return ClipperData()
        })
      return object.objectBoundingBox()
    }

    if clipBoundaries[Int(repaintRectCalculation.rawValue)].isEmpty() {
      calculateClipContentRepaintRect(repaintRectCalculation)
    }

    if clipPathElement().clipPathUnits() == .SVG_UNIT_TYPE_OBJECTBOUNDINGBOX {
      let objectBoundingBox = object.objectBoundingBox()
      let transform = AffineTransform()
      transform.translate(objectBoundingBox.location())
      transform.scale(objectBoundingBox.size())
      return transform.mapRect(rect: clipBoundaries[Int(repaintRectCalculation.rawValue)])
    }

    return clipBoundaries[Int(repaintRectCalculation.rawValue)]
  }

  private func computeInputs(
    _ context: GraphicsContextWrapper, _ renderer: RenderElementWrapper,
    objectBoundingBox: FloatRectWrapper, clippedContentBounds: FloatRectWrapper, usedZoom: Float32
  ) -> ClipperData.Inputs {
    let absoluteTransform = SVGRenderingContext.calculateTransformationToOutermostCoordinateSystem(
      renderer)

    // Ignore 2D rotation, as it doesn't affect the size of the mask.
    let scale = FloatSize(
      width: Float32(absoluteTransform.xScale()), height: Float32(absoluteTransform.yScale()))

    // Determine scale factor for the clipper. The size of intermediate ImageBuffers shouldn't be bigger than kMaxFilterSize.
    ImageBufferWrapper.sizeNeedsClamping(objectBoundingBox.size(), scale)

    return ClipperData.Inputs(
      objectBoundingBox: objectBoundingBox, clippedContentBounds: clippedContentBounds, scale,
      usedZoom, context.paintingDisabled())
  }

  private func pathOnlyClipping(
    _ context: GraphicsContextWrapper, _ renderer: RenderElementWrapper,
    _ animatedLocalTransform: AffineTransform, _ objectBoundingBox: FloatRectWrapper,
    _ usedZoom: Float32
  ) -> LegacyRenderSVGResource.ApplyResult {
    // If the current clip-path gets clipped itself, we have to fall back to masking.
    if style().clipPath() != nil {
      return []
    }

    var clipRule: WindRule = .NonZero
    var clipPath = PathWrapper()

    let rendererRequiresMaskClipping = { (renderer: RenderObjectWrapper) in
      // Only shapes or paths are supported for direct clipping. We need to fall back to masking for texts.
      if renderer is RenderSVGTextWrapper {
        return true
      }
      let style = renderer.style()
      if style.display() == .None || style.usedVisibility() != .Visible {
        return false
      }
      // Current shape in clip-path gets clipped too. Fall back to masking.
      if style.clipPath() != nil {
        return true
      }
      // Fall back to masking if there is more than one clipping path.
      if !clipPath.isEmpty() {
        return true
      }
      return false
    }

    // If clip-path only contains one visible shape or path, we can use path-based clipping. Invisible
    // shapes don't affect the clipping and can be ignored. If clip-path contains more than one
    // visible shape, the additive clipping may not work, caused by the clipRule. EvenOdd
    // as well as NonZero can cause self-clipping of the elements.
    // See also http://www.w3.org/TR/SVG/painting.html#FillRuleProperty
    var childNode = clipPathElement().firstChild()
    while childNode != nil {
      guard let graphicsElement = childNode as? SVGGraphicsElementWrapper else {
        childNode = childNode!.nextSibling()
        continue
      }
      guard let renderer = graphicsElement.containerRenderer() else {
        childNode = childNode!.nextSibling()
        continue
      }
      if rendererRequiresMaskClipping(renderer) {
        return []
      }

      // For <use> elements, delegate the decision whether to use mask clipping or not to the referenced element.
      if let useElement = graphicsElement as? SVGUseElementWrapper,
        let clipChildRenderer = useElement.rendererClipChild(),
        rendererRequiresMaskClipping(clipChildRenderer)
      {
        return []
      }

      clipPath = graphicsElement.toClipPath()
      clipRule = renderer.style().svgStyle().clipRule()
      childNode = childNode!.nextSibling()
    }

    // Only one visible shape/path was found. Directly continue clipping and transform the content to userspace if necessary.
    if clipPathElement().clipPathUnits() == .SVG_UNIT_TYPE_OBJECTBOUNDINGBOX {
      let transform = AffineTransform()
      transform.translate(objectBoundingBox.location())
      transform.scale(objectBoundingBox.size())
      clipPath.transform(transform)
    } else if usedZoom != 1 {
      let transform = AffineTransform()
      transform.scale(Float64(usedZoom))
      clipPath.transform(transform)
    }

    // Transform path by animatedLocalTransform.
    clipPath.transform(animatedLocalTransform)

    // The SVG specification wants us to clip everything, if clip-path doesn't have a child.
    if clipPath.isEmpty() {
      clipPath.addRect(rect: FloatRectWrapper())
    }

    var result: LegacyRenderSVGResource.ApplyResult = [.ResourceApplied]
    if let shapeRenderer = renderer as? LegacyRenderSVGShapeWrapper,
      shapeRenderer.shapeType == .Rectangle
    {
      // When clipping a rect with a path, if we know the path is entirely inside the rect, we can skip a clip when filling the rect.
      let clipBounds = clipPath.fastBoundingRect()
      if objectBoundingBox.contains(clipBounds) {
        result.update(with: .ClipContainsRendererContent)
      }
    }

    context.clipPath(path: clipPath, clipRule: clipRule)
    return result
  }

  private func drawContentIntoMaskImage(
    _ maskImageBuffer: ImageBufferWrapper, _ objectBoundingBox: FloatRectWrapper,
    _ usedZoom: Float32
  ) -> Bool {
    let maskContext = maskImageBuffer.context()

    let maskContentTransformation = AffineTransform()
    if clipPathElement().clipPathUnits() == .SVG_UNIT_TYPE_OBJECTBOUNDINGBOX {
      maskContentTransformation.translate(objectBoundingBox.location())
      maskContentTransformation.scale(objectBoundingBox.size())
      maskContext.concatCTM(transform: maskContentTransformation)
    } else if usedZoom != 1 {
      maskContentTransformation.scale(Float64(usedZoom))
      maskContext.concatCTM(transform: maskContentTransformation)
    }

    // Switch to a paint behavior where all children of this <clipPath> will be rendered using special constraints:
    // - fill-opacity/stroke-opacity/opacity set to 1
    // - masker/filter not applied when rendering the children
    // - fill is set to the initial fill paint server (solid, black)
    // - stroke is set to the initial stroke paint server (none)
    let oldBehavior = view().frameView().paintBehavior()
    view().frameView().setPaintBehavior(oldBehavior.union(.RenderingSVGClipOrMask))

    // Draw all clipPath children into a global mask.
    for child: SVGElementWrapper in childrenOfType(parent: protectedClipPathElement()) {
      guard let renderer = child.containerRenderer() else { continue }
      if renderer.needsLayout() {
        view().frameView().setPaintBehavior(oldBehavior)
        return false
      }
      let style = renderer.style()
      if style.display() == .None || style.usedVisibility() != .Visible {
        continue
      }

      var newClipRule = style.svgStyle().clipRule()
      let useElement = child as? SVGUseElementWrapper
      if useElement != nil {
        guard let renderer = useElement!.rendererClipChild() else { continue }
        // TODO(asuhan): use hasAttributeWithoutSynchronization instead
        if !useElement!.hasSvgClipRuleAttrWithoutSynchronization() {
          newClipRule = renderer.style().svgStyle().clipRule()
        }
      }

      // Only shapes, paths and texts are allowed for clipping.
      if !renderer.isRenderOrLegacyRenderSVGShape() && !renderer.isRenderSVGText() {
        continue
      }

      maskContext.setFillRule(fillRule: newClipRule)

      // In the case of a <use> element, we obtained its renderere above, to retrieve its clipRule.
      // We have to pass the <use> renderer itself to renderSubtreeToContext() to apply it's x/y/transform/etc. values when rendering.
      // So if useElement is non-null, refetch the childNode->renderer(), as renderer got overridden above.
      SVGRenderingContext.renderSubtreeToContext(
        maskContext, useElement != nil ? child.containerRenderer()! : renderer,
        maskContentTransformation)
    }

    view().frameView().setPaintBehavior(oldBehavior)
    return true
  }

  private func calculateClipContentRepaintRect(_ repaintRectCalculation: RepaintRectCalculation) {
    // This is a rough heuristic to appraise the clip size and doesn't consider clip on clip.
    var childNode = clipPathElement().firstChild()
    while childNode != nil {
      let renderer = childNode!.renderer()
      if !childNode!.isSVGElement() || renderer == nil {
        childNode = childNode!.nextSibling()
        continue
      }
      if !renderer!.isRenderOrLegacyRenderSVGShape() && !renderer!.isRenderSVGText()
        && !childNode!.hasUseTagName()  // TODO(asuhan): use hasTagName
      {
        childNode = childNode!.nextSibling()
        continue
      }
      let style = renderer!.style()
      if style.display() == .None || style.usedVisibility() != .Visible {
        childNode = childNode!.nextSibling()
        continue
      }
      clipBoundaries[Int(repaintRectCalculation.rawValue)].unite(
        other: renderer!.localToParentTransform().mapRect(
          rect: renderer!.repaintRectInLocalCoordinates(repaintRectCalculation)))
      childNode = childNode!.nextSibling()
    }
    clipBoundaries[Int(repaintRectCalculation.rawValue)] = clipPathElement()
      .animatedLocalTransform().mapRect(rect: clipBoundaries[Int(repaintRectCalculation.rawValue)])
  }

  private var clipBoundaries = [FloatRectWrapper](repeating: FloatRectWrapper(), count: 2)  // TODO(asuhan): use an enumerated array
  private let clipperMap: HashMap<RenderObjectWrapper, ClipperData>? = nil
}
