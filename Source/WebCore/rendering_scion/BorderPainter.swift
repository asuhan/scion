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

private func borderStyleFillsBorderArea(style: BorderStyle) -> Bool {
  switch style {
  case .None, .Hidden, .Inset, .Groove, .Outset, .Ridge, .Solid:
    return true
  case .Dotted, .Dashed, .Double:
    return false
  }
}

private func edgeIsSimple(edge: BorderEdge) -> Bool {
  return edge.widthForPainting() == 0 || borderStyleFillsBorderArea(style: edge.style)
}

private func decorationHasAllSimpleEdges(edges: RectEdges<BorderEdge>) -> Bool {
  return edgeIsSimple(edge: edges.top) && edgeIsSimple(edge: edges.right)
    && edgeIsSimple(edge: edges.bottom) && edgeIsSimple(edge: edges.left)
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

private func decorationHasAllSolidEdges(edges: RectEdges<BorderEdge>) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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
    let graphicsContext = paintInfo.context()

    if graphicsContext.paintingDisabled() {
      return
    }

    if rect.isEmpty() && !paintsBorderImage(rect: rect, ninePieceImage: style.borderImage()) {
      return
    }

    let rectToClipOut = renderer.paintRectToClipOutFromBorder(paintRect: rect)
    let appliedClipAlready = !rectToClipOut.isEmpty()
    let _ = GraphicsContextStateSaver(context: graphicsContext, saveAndRestore: appliedClipAlready)
    if !rectToClipOut.isEmpty() {
      graphicsContext.clipOut(
        rect: snapRectToDevicePixels(
          rect: rectToClipOut, pixelSnappingFactor: document().deviceScaleFactor()))
    }

    // border-image is not affected by border-radius.
    if paintNinePieceImage(rect: rect, style: style, ninePieceImage: style.borderImage()) {
      return
    }

    let borderShape = BorderShape.shapeForBorderRect(
      style: style, borderRect: rect, includeLogicalLeftEdge: includeLogicalLeftEdge,
      includeLogicalRightEdge: includeLogicalRightEdge)

    // To handle corner styles other than `round`, we'll have to plumb the borderShape through all the border painting functions.
    var outerBorder = borderShape.deprecatedRoundedRect()
    var innerBorder = borderShape.deprecatedInnerRoundedRect()
    let unadjustedInnerBorder = innerBorder

    switch bleedAvoidance {
    case .BackgroundBleedNone, .BackgroundBleedShrinkBackground,
      .BackgroundBleedUseTransparencyLayer:
      break
    case .BackgroundBleedBackgroundOverBorder:
      let shrunkBorderRect = borderRectAdjustedForBleedAvoidance(
        rect: rect, bleedAvoidance: bleedAvoidance)
      let shrunkBorderShape = BorderShape.shapeForBorderRect(
        style: style, borderRect: shrunkBorderRect, includeLogicalLeftEdge: includeLogicalLeftEdge,
        includeLogicalRightEdge: includeLogicalRightEdge)
      innerBorder = shrunkBorderShape.deprecatedInnerRoundedRect()
    }

    let edges = borderEdges(
      style: style, deviceScaleFactor: document().deviceScaleFactor(),
      setColorsToBlack: paintInfo.paintBehavior.contains(.ForceBlackBorder),
      includeLogicalLeftEdge: includeLogicalLeftEdge,
      includeLogicalRightEdge: includeLogicalRightEdge)
    let haveAllSolidEdges = decorationHasAllSolidEdges(edges: edges)

    if haveAllSolidEdges && outerBorder.isRounded()
      && BorderPainter.allCornersClippedOut(border: outerBorder, clipRect: paintInfo.rect)
    {
      outerBorder.radii = RoundedRect.Radii()
    }

    paintSides(
      sides: Sides(
        outerBorder: outerBorder,
        innerBorder: innerBorder,
        unadjustedInnerBorder: unadjustedInnerBorder,
        radii: style.hasBorderRadius() ? style.borderRadii() : nil,
        edges: edges,
        haveAllSolidEdges: haveAllSolidEdges,
        bleedAvoidance: bleedAvoidance,
        includeLogicalLeftEdge: includeLogicalLeftEdge,
        includeLogicalRightEdge: includeLogicalRightEdge,
        appliedClipAlready: appliedClipAlready,
        isHorizontal: style.isHorizontalWritingMode()
      ))
  }

  private func paintsBorderImage(rect: LayoutRectWrapper, ninePieceImage: NinePieceImage) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func paintNinePieceImage(
    rect: LayoutRectWrapper, style: RenderStyleWrapper, ninePieceImage: NinePieceImage,
    op: CompositeOperator = .SourceOver
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

    // FIXME: border-image is broken with full page zooming when tiling has to happen, since the tiling function
    // doesn't have any understanding of the zoom that is in effect on the tile.
    let deviceScaleFactor = document().deviceScaleFactor()

    var rectWithOutsets = rect
    rectWithOutsets.expand(box: style.imageOutsets(image: ninePieceImage))
    let destination = LayoutRectWrapper(
      r: snapRectToDevicePixels(rect: rectWithOutsets, pixelSnappingFactor: deviceScaleFactor))

    let source = modelObject!.calculateImageIntrinsicDimensions(
      image: styleImage!, positioningAreaSize: destination.size(), scaleByUsedZoom: .No)

    // If both values are ‘auto’ then the intrinsic width and/or height of the image should be used, if any.
    styleImage!.setContainerContextForRenderer(
      renderer: renderer, containerSize: source.FloatSize(), containerZoom: style.usedZoom())

    ninePieceImage.paint(
      graphicsContext: paintInfo.context(), renderer: renderer, style: style,
      destination: destination, source: source, deviceScaleFactor: deviceScaleFactor, op: op)
    return true
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

  static func allCornersClippedOut(border: RoundedRect, clipRect: LayoutRectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct Sides {
    let outerBorder: RoundedRect
    let innerBorder: RoundedRect
    let unadjustedInnerBorder: RoundedRect
    let radii: BorderData.Radii?
    let edges: BorderEdges
    let haveAllSolidEdges: Bool
    let bleedAvoidance: BackgroundBleedAvoidance
    let includeLogicalLeftEdge: Bool
    let includeLogicalRightEdge: Bool
    let appliedClipAlready: Bool
    let isHorizontal: Bool
  }

  private func paintSides(sides: Sides) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func borderRectAdjustedForBleedAvoidance(
    rect: LayoutRectWrapper, bleedAvoidance: BackgroundBleedAvoidance
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func document() -> Document { return renderer.document() }

  private let renderer: RenderElementWrapper
  private let paintInfo: PaintInfoWrapper
}
