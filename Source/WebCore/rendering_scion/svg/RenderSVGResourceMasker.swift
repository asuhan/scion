/*
 * Copyright (C) Research In Motion Limited 2009-2010. All rights reserved.
 * Copyright (C) 2021, 2022, 2023 Igalia S.L.
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

final class RenderSVGResourceMasker: RenderSVGResourceContainerWrapper {
  private func maskElement() -> SVGMaskElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func applyMask(
    _ paintInfo: PaintInfoWrapper, _ targetRenderer: RenderLayerModelObjectWrapper,
    _ adjustedPaintOffset: LayoutPointWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func resourceBoundingBox(
    _ object: RenderObjectWrapper, _ repaintRectCalculation: RepaintRectCalculation
  ) -> FloatRectWrapper {
    let targetBoundingBox = object.objectBoundingBox()

    let recursionTracking = SVGVisitedRendererTracking(
      RenderSVGResourceMasker.s_visitedSetResourceBoundingBox)
    if recursionTracking.isVisiting(self) {
      return targetBoundingBox
    }

    let unused = SVGVisitedRendererTracking.Scope(recursionTracking, self)
    use(unused)

    let maskElement = maskElement()
    var maskRect = maskElement.calculateMaskContentRepaintRect(repaintRectCalculation)
    if maskElement.maskContentUnits() == .SVG_UNIT_TYPE_OBJECTBOUNDINGBOX {
      let contentTransform = AffineTransform()
      contentTransform.translate(targetBoundingBox.location())
      contentTransform.scale(targetBoundingBox.size())
      maskRect = contentTransform.mapRect(rect: maskRect)
    }

    let maskBoundaries = SVGLengthContext.resolveRectangle(
      maskElement, maskElement.maskUnits(), targetBoundingBox)
    maskRect.intersect(other: maskBoundaries)
    return maskRect.isEmpty() ? targetBoundingBox : maskRect
  }

  private static let s_visitedSetResourceBoundingBox = SVGVisitedRendererTracking.VisitedSet()
}
