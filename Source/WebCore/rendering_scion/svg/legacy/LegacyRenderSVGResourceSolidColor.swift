/*
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
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

final class LegacyRenderSVGResourceSolidColor: LegacyRenderSVGResource {
  override init() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func applyResource(
    _ renderer: RenderElementWrapper, _ style: RenderStyleWrapper,
    _ context: GraphicsContextWrapper, _ resourceMode: RenderSVGResourceMode
  ) -> LegacyRenderSVGResource.ApplyResult {
    assert(!resourceMode.isEmpty)

    let svgStyle = style.svgStyle()

    let isRenderingMask = renderer.view().frameView().paintBehavior().contains(
      .RenderingSVGClipOrMask)

    if resourceMode.contains(.ApplyToFill) {
      if !isRenderingMask {
        context.setAlpha(alpha: svgStyle.fillOpacity())
      } else {
        context.setAlpha(alpha: 1)
      }
      context.setFillColor(color: style.colorByApplyingColorFilter(color: color))
      if isRenderingMask {
        context.setFillRule(fillRule: svgStyle.clipRule())
      } else {
        context.setFillRule(fillRule: svgStyle.fillRule())
      }

      if resourceMode.contains(.ApplyToText) {
        context.setTextDrawingMode(textDrawingMode: .Fill)
      }
    } else if resourceMode.contains(.ApplyToStroke) {
      // When rendering the mask for a LegacyRenderSVGResourceClipper, the stroke code path is never hit.
      assert(!isRenderingMask)
      context.setAlpha(alpha: svgStyle.strokeOpacity())
      context.setStrokeColor(color: style.colorByApplyingColorFilter(color: color))

      SVGRenderSupport.applyStrokeStyleToContext(context, style, renderer)

      if resourceMode.contains(.ApplyToText) {
        context.setTextDrawingMode(textDrawingMode: .Stroke)
      }
    }

    return [.ResourceApplied]
  }

  override func postApplyResource(
    _ renderer: RenderElementWrapper, _ context: GraphicsContextWrapper,
    _ resourceMode: RenderSVGResourceMode, _ path: PathWrapper?, _ shape: RenderElementWrapper?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func resourceBoundingBox(
    _ object: RenderObjectWrapper, _ repaintRectCalculation: RepaintRectCalculation
  ) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var color: ColorWrapper
}
