/*
 * Copyright (C) 2004, 2005, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2007 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Google, Inc.
 * Copyright (C) 2009 Apple Inc. All rights reserved.
 * Copyright (c) 2020, 2021, 2022 Igalia S.L.
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

private func viewBoxToViewTransform(
  _ svgSVGElement: SVGSVGElementWrapper, _ viewportSize: FloatSize
) -> AffineTransform {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

final class RenderSVGViewportContainerWrapper: RenderSVGContainerWrapper {
  init(parent: RenderSVGRootWrapper, style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func svgSVGElement() -> SVGSVGElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func viewport() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func viewportSize() -> FloatSize { return m_viewport.size() }

  override final func updateFromStyle() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isOutermostSVGViewportContainer() -> Bool { return isAnonymous() }

  override final func updateLayoutSizeIfNeeded() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func overridenObjectBoundingBoxWithoutTransformations() -> FloatRectWrapper? {
    return viewport()
  }

  override func updateLayerTransform() {
    assert(hasLayer())

    // First update the supplemental layer transform.
    let useSVGSVGElement = svgSVGElement()
    var viewportSize = viewportSize()

    supplementalLayerTransform.makeIdentity()

    if isOutermostSVGViewportContainer() {
      // Handle pan - set on outermost <svg> element.
      let translation = useSVGSVGElement.currentTranslateValue()
      if !translation.isZero() {
        supplementalLayerTransform.translate(translation)
      }

      // Handle zoom - take effective zoom from outermost <svg> element.
      let scale = useSVGSVGElement.renderer()!.style().usedZoom()
      if scale != 1 {
        supplementalLayerTransform.scale(Float64(scale))
        viewportSize.scale(1 / scale)
      }
    } else if !m_viewport.location().isZero() {
      supplementalLayerTransform.translate(m_viewport.location())
    }

    if useSVGSVGElement.hasViewBoxAttr() {  // TODO(asuhan): implement and use hasAttribute
      // An empty viewBox disables the rendering -- dirty the visible descendant status!
      if useSVGSVGElement.hasEmptyViewBox() {
        layer()!.dirtyVisibleContentStatus()
      } else {
        let viewBoxTransform = viewBoxToViewTransform(useSVGSVGElement, viewportSize)
        if !viewBoxTransform.isIdentity() {
          if supplementalLayerTransform.isIdentity() {
            supplementalLayerTransform = viewBoxTransform
          } else {
            supplementalLayerTransform.multiply(viewBoxTransform)
          }
        }
      }
    }

    // After updating the supplemental layer transform we're able to use it in RenderLayerModelObjects::updateLayerTransform().
    super.updateLayerTransform()
  }

  private var supplementalLayerTransform: AffineTransform
  private let m_viewport: FloatRectWrapper
}
