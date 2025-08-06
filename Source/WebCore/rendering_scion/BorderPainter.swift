/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2005 Allan Sandfeld Jensen (kde@carewolf.com)
 *           (C) 2005, 2006 Samuel Weinig (sam.weinig@gmail.com)
 * Copyright (C) 2005-2022 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
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
 *
 */

private func decorationHasAllSimpleEdges(edges: RectEdges<BorderEdge>) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func shrinkRectByOneDevicePixel(
  context: GraphicsContextWrapper, rect: LayoutRectWrapper, devicePixelRatio: Float32
) -> LayoutRectWrapper {
  var shrunkRect = rect
  let transform = context.getCTM()
  shrunkRect.inflateX(
    dx: -ceilToDevicePixel(
      value: Float32(1.0 / transform.xScale()), pixelSnappingFactor: devicePixelRatio))
  shrunkRect.inflateY(
    dy: -ceilToDevicePixel(
      value: Float32(1.0 / transform.yScale()), pixelSnappingFactor: devicePixelRatio))
  return shrunkRect
}

class BorderPainter {
  init(renderer: RenderElementWrapper, paintInfo: PaintInfoWrapper) {
    self.renderer = renderer
    self.paintInfo = paintInfo
  }

  func paintBorder(
    rect: LayoutRectWrapper, style: RenderStyleWrapper,
    bleedAvoidance: BackgroundBleedAvoidance = .BackgroundBleedNone,
    includeLogicalLeftEdge: Bool = true, includeLogicalRightEdge: Bool = true
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func paintNinePieceImage(
    rect: LayoutRectWrapper, style: RenderStyleWrapper, ninePieceImage: NinePieceImage,
    op: CompositeOperator
  ) -> Bool {
    let styleImage = ninePieceImage.image()
    if styleImage == nil {
      return false
    }

    if !styleImage!.isLoaded(renderer: renderer) {
      return true  // Never paint a nine-piece image incrementally, but don't paint the fallback borders either.
    }

    if !styleImage!.canRender(renderer: renderer, multiplier: style.usedZoom()) {
      return false
    }

    let modelObject = renderer as? RenderBoxModelObjectWrapper
    if modelObject == nil {
      return false
    }

    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func pathForBorderArea(
    rect: LayoutRectWrapper, style: RenderStyleWrapper, deviceScaleFactor: Float32,
    includeLogicalLeftEdge: Bool = true, includeLogicalRightEdge: Bool = true
  ) -> PathWrapper? {
    // TODO(asuhan): check these arguments
    let edges = borderEdges(
      style: style, deviceScaleFactor: deviceScaleFactor, setColorsToBlack: includeLogicalLeftEdge,
      includeLogicalLeftEdge: includeLogicalRightEdge)
    if !decorationHasAllSimpleEdges(edges: edges) {
      return nil
    }

    let borderShape = BorderShape.shapeForBorderRect(
      style: style, borderRect: rect, includeLogicalLeftEdge: includeLogicalLeftEdge,
      includeLogicalRightEdge: includeLogicalRightEdge)
    return borderShape.pathForBorderArea(deviceScaleFactor: deviceScaleFactor)
  }

  private func document() -> Document { return renderer.document() }

  private let renderer: RenderElementWrapper
  private let paintInfo: PaintInfoWrapper
}
