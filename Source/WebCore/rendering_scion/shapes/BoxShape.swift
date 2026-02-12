/*
 * Copyright (C) 2013 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation

private func adjustRadiusForMarginBoxShape(_ radius: LayoutUnit, _ margin: LayoutUnit) -> LayoutUnit
{
  // This algorithm is defined in the CSS Shapes specifcation
  if !margin.bool() {
    return radius
  }

  let ratio = radius / margin
  if ratio < Int32(1) {
    return LayoutUnit(value: radius + (margin * (1 + pow((ratio - 1).float(), 3.0))))
  }

  return radius + margin
}

private func computeMarginBoxShapeRadius(
  _ radius: LayoutSizeWrapper, _ adjacentMargins: LayoutSizeWrapper
) -> LayoutSizeWrapper {
  return LayoutSizeWrapper(
    width: adjustRadiusForMarginBoxShape(radius.width(), adjacentMargins.width()),
    height: adjustRadiusForMarginBoxShape(radius.height(), adjacentMargins.height()))
}

private func computeMarginBoxShapeRadii(_ radii: RoundedRect.Radii, _ renderer: RenderBoxWrapper)
  -> RoundedRect.Radii
{
  return RoundedRect.Radii(
    topLeft: computeMarginBoxShapeRadius(
      radii.topLeft, LayoutSizeWrapper(width: renderer.marginLeft(), height: renderer.marginTop())
    ),
    topRight: computeMarginBoxShapeRadius(
      radii.topRight,
      LayoutSizeWrapper(width: renderer.marginRight(), height: renderer.marginTop())),
    bottomLeft: computeMarginBoxShapeRadius(
      radii.bottomLeft,
      LayoutSizeWrapper(width: renderer.marginLeft(), height: renderer.marginBottom())),
    bottomRight: computeMarginBoxShapeRadius(
      radii.bottomRight,
      LayoutSizeWrapper(width: renderer.marginRight(), height: renderer.marginBottom())))
}

func computeRoundedRectForBoxShape(box: CSSBoxType, renderer: RenderBoxWrapper) -> RoundedRect {
  let style = renderer.style()
  switch box {
  case .MarginBox:
    if !style.hasBorderRadius() {
      return RoundedRect(rect: renderer.marginBoxRect(), radii: RoundedRect.Radii())
    }

    let marginBox = renderer.marginBoxRect()
    let borderShape = BorderShape.shapeForBorderRect(
      style: style, borderRect: renderer.borderBoxRect())
    var radii = computeMarginBoxShapeRadii(borderShape.radii(), renderer)
    radii.scale(
      factor: calcBorderRadiiConstraintScaleFor(
        rect: marginBox.FloatRect(), radii: FloatRoundedRect.Radii(intRadii: radii)))
    return RoundedRect(rect: marginBox, radii: radii)
  case .PaddingBox:
    return BorderShape.shapeForBorderRect(style: style, borderRect: renderer.borderBoxRect())
      .deprecatedInnerRoundedRect()
  case .FillBox, .ContentBox:
    let borderShape = renderer.borderShapeForContentClipping(
      borderBoxRect: renderer.borderBoxRect())
    return borderShape.deprecatedInnerRoundedRect()
  // stroke-box, view-box compute to border-box for HTML elements.
  case .BorderBox, .StrokeBox, .ViewBox, .BoxMissing:
    return BorderShape.shapeForBorderRect(style: style, borderRect: renderer.borderBoxRect())
      .deprecatedRoundedRect()
  }
}

final class BoxShape: ShapeWrapper {
  init(_ bounds: FloatRoundedRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
