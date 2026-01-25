/*
 * Copyright (C) 2004, 2005, 2007, 2008 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Rob Buis <buis@kde.org>
 * Copyright (C) Research In Motion Limited 2009-2010. All rights reserved.
 * Copyright (C) 2011 Dirk Schulze <krit@webkit.org>
 * Copyright (C) 2021, 2022, 2023, 2024 Igalia S.L.
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

enum ClippingMode {
  case NoClipping
  case PathClipping
  case MaskClipping
}

private var currentClippingMode: ClippingMode = .NoClipping

private func sharedClipAllPath() -> PathWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

final class RenderSVGResourceClipperWrapper: RenderSVGResourceContainerWrapper {
  private func protectedClipPathElement() -> SVGClipPathElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldApplyPathClipping() -> SVGGraphicsElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func applyPathClipping(
    context: GraphicsContextWrapper, targetRenderer: RenderLayerModelObjectWrapper,
    objectBoundingBox: FloatRectWrapper, graphicsElement: SVGGraphicsElementWrapper
  ) {
    assert(hasLayer())
    assert(layer()!.isSelfPaintingLayer)

    assert(currentClippingMode == .NoClipping || currentClippingMode == .MaskClipping)
    let _ = SetForScope(scopedVariable: &currentClippingMode, newValue: ClippingMode.PathClipping)

    let containerRenderer = graphicsElement.containerRenderer()!
    assert(containerRenderer.hasLayer())
    let clipRenderer = containerRenderer as! RenderSVGModelObjectWrapper

    let clipPathTransform = AffineTransform()
    if clipPathUnits() == .SVG_UNIT_TYPE_OBJECTBOUNDINGBOX {
      clipPathTransform.translate(objectBoundingBox.location())
      clipPathTransform.scale(objectBoundingBox.size())
    } else if !targetRenderer.isSVGLayerAwareRenderer() {
      clipPathTransform.translate(Float64(objectBoundingBox.x()), Float64(objectBoundingBox.y()))
      clipPathTransform.scale(Float64(targetRenderer.style().usedZoom()))
    }
    if layer()!.isTransformed() {
      clipPathTransform.multiply(layer()!.transform!.toAffineTransform())
    }

    let clipPath = clipRenderer.computeClipPath(clipPathTransform)
    let windRule = clipRenderer.style().svgStyle().clipRule()

    // The SVG specification wants us to clip everything, if clip-path doesn't have a child.
    if clipPath.isEmpty() {
      context.clipPath(path: sharedClipAllPath(), clipRule: windRule)
    } else {
      let ctm = context.getCTM()
      context.concatCTM(transform: clipPathTransform)
      context.clipPath(path: clipPath, clipRule: windRule)
      context.setCTM(transform: ctm)
    }
  }

  func resourceBoundingBox(
    _ object: RenderObjectWrapper, _ repaintRectCalculation: RepaintRectCalculation
  ) -> FloatRectWrapper {
    let recursionTracking = SVGVisitedRendererTracking(
      RenderSVGResourceClipperWrapper.s_visitedSetResourceBoundingBox)
    let targetBoundingBox = object.objectBoundingBox()
    if recursionTracking.isVisiting(self) {
      return targetBoundingBox
    }

    let _ = SVGVisitedRendererTracking.Scope(recursionTracking, self)

    let clipContentRepaintRect = protectedClipPathElement().calculateClipContentRepaintRect(
      repaintRectCalculation)
    if clipPathUnits() == .SVG_UNIT_TYPE_OBJECTBOUNDINGBOX {
      let contentTransform = AffineTransform()
      contentTransform.translate(targetBoundingBox.location())
      contentTransform.scale(targetBoundingBox.size())
      return contentTransform.mapRect(rect: clipContentRepaintRect)
    }

    return clipContentRepaintRect
  }

  private static let s_visitedSetResourceBoundingBox = SVGVisitedRendererTracking.VisitedSet()

  private func clipPathUnits() -> SVGUnitTypes.SVGUnitType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func updateFromStyle() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
