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
    let scale = FloatSize()
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
      context, clippedContentBounds, clipperData!.inputs.scale, clipperData!.imageBuffer, true)
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func pathOnlyClipping(
    _ context: GraphicsContextWrapper, _ renderer: RenderElementWrapper,
    _ animatedLocalTransform: AffineTransform, _ objectBoundingBox: FloatRectWrapper,
    _ usedZoom: Float32
  ) -> LegacyRenderSVGResource.ApplyResult {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func drawContentIntoMaskImage(
    _ maskImageBuffer: ImageBufferWrapper, _ objectBoundingBox: FloatRectWrapper,
    _ usedZoom: Float32
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func calculateClipContentRepaintRect(_ repaintRectCalculation: RepaintRectCalculation) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let clipBoundaries = [FloatRectWrapper](repeating: FloatRectWrapper(), count: 2)  // TODO(asuhan): use an enumerated array
  private let clipperMap: HashMap<RenderObjectWrapper, ClipperData>? = nil
}
