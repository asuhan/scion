/*
 * Copyright (C) 2004, 2005, 2007, 2008 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Rob Buis <buis@kde.org>
 * Copyright (C) Research In Motion Limited 2009-2010. All rights reserved.
 * Copyright (C) 2022, 2023, 2024 Igalia S.L.
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

final class RenderSVGResourceMarkerWrapper: RenderSVGResourceContainerWrapper {
  func hasReverseStart() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Calculates marker boundaries, mapped to the target element's coordinate space
  func computeMarkerBoundingBox(
    _ options: SVGBoundingBoxComputation.DecorationOptions, _ markerTransformation: AffineTransform
  ) -> FloatRectWrapper {
    let boundingBoxComputation = SVGBoundingBoxComputation(self)
    let boundingBox = boundingBoxComputation.computeDecoratedBoundingBox(options)

    // Map repaint rect into parent coordinate space, in which the marker boundaries have to be evaluated
    return markerTransformation.mapRect(rect: supplementalLayerTransform.mapRect(rect: boundingBox))
  }

  func markerTransformation(_ origin: FloatPoint, autoAngle: Float32, strokeWidth: Float32)
    -> AffineTransform
  {
    let transform = AffineTransform()
    transform.translate(origin)
    transform.rotate(Float64(angle() ?? autoAngle))

    // The 'referencePoint()' coordinate maps to SVGs refX/refY, given in coordinates relative to the viewport established by the marker
    let mappedOrigin = supplementalLayerTransform.mapPoint(referencePoint())

    if markerUnits() == .SVGMarkerUnitsStrokeWidth {
      transform.scaleNonUniform(Float64(strokeWidth), Float64(strokeWidth))
    }

    transform.translate(-mappedOrigin)
    return transform
  }

  func markerElement() -> SVGMarkerElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func referencePoint() -> FloatPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func angle() -> Float32? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func markerUnits() -> SVGMarkerUnitsType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func viewport() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func viewportSize() -> FloatSize { return m_viewport.size() }

  override final func updateLayoutSizeIfNeeded() -> Bool {
    let previousViewportSize = viewportSize()
    m_viewport = computeViewport()
    return selfNeedsLayout() || previousViewportSize != viewportSize()
  }

  override final func overridenObjectBoundingBoxWithoutTransformations() -> FloatRectWrapper? {
    return viewport()
  }

  override func updateLayerTransform() {
    assert(hasLayer())

    // First update the supplemental layer transform.
    let useMarkerElement = markerElement()
    let viewportSize = viewportSize()

    supplementalLayerTransform.makeIdentity()

    if useMarkerElement.hasViewBoxAttr() {  // TODO(asuhan): implement and use hasAttribute
      // An empty viewBox disables the rendering -- dirty the visible descendant status!
      if useMarkerElement.hasEmptyViewBox() {
        layer()!.dirtyVisibleContentStatus()
      } else {
        let viewBoxTransform = useMarkerElement.viewBoxToViewTransform(
          viewportSize.width, viewportSize.height)
        if !viewBoxTransform.isIdentity() {
          supplementalLayerTransform = viewBoxTransform
        }
      }
    }

    // After updating the supplemental layer transform we're able to use it in RenderLayerModelObjects::updateLayerTransform().
    super.updateLayerTransform()
  }

  private func computeViewport() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func updateFromStyle() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var supplementalLayerTransform = AffineTransform()
  private var m_viewport = FloatRectWrapper()
}
