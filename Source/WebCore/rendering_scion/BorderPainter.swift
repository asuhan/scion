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

private func borderStyleHasInnerDetail(style: BorderStyle) -> Bool {
  switch style {
  case .None, .Hidden, .Inset, .Outset, .Solid, .Dotted, .Dashed:
    return false
  case .Groove, .Ridge, .Double:
    return true
  }
}

private func edgeIsSimple(edge: BorderEdge) -> Bool {
  return edge.widthForPainting() == 0 || borderStyleFillsBorderArea(style: edge.style)
}

private func decorationHasAllSimpleEdges(edges: RectEdges<BorderEdge>) -> Bool {
  return edgeIsSimple(edge: edges.top) && edgeIsSimple(edge: edges.right)
    && edgeIsSimple(edge: edges.bottom) && edgeIsSimple(edge: edges.left)
}

private func calculateSideRect(outerBorder: RoundedRect, edges: BorderEdges, side: BoxSide)
  -> LayoutRectWrapper
{
  var sideRect = outerBorder.rect
  let width = edges.at(side: side).widthForPainting()

  switch side {
  case .Top:
    sideRect.setHeight(height: width)
  case .Right:
    sideRect.shiftXEdgeTo(edge: sideRect.maxX() - width)
  case .Bottom:
    sideRect.shiftYEdgeTo(edge: sideRect.maxY() - width)
  case .Left:
    sideRect.setWidth(width: width)
  }

  return sideRect
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

private func edgeIsSolid(edge: BorderEdge) -> Bool {
  return edge.presentButInvisible() || edge.widthForPainting() == 0 || edge.style == .Solid
}

private func decorationHasAllSolidEdges(edges: RectEdges<BorderEdge>) -> Bool {
  return edgeIsSolid(edge: edges.top) && edgeIsSolid(edge: edges.right)
    && edgeIsSolid(edge: edges.bottom) && edgeIsSolid(edge: edges.left)
}

private func borderWillArcInnerEdge(firstRadius: LayoutSizeWrapper, secondRadius: LayoutSizeWrapper)
  -> Bool
{
  return !firstRadius.isEmpty() || !secondRadius.isEmpty()
}

private func colorsMatchAtCorner(side: BoxSide, adjacentSide: BoxSide, edges: BorderEdges) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func joinRequiresMitre(
  side: BoxSide, adjacentSide: BoxSide, edges: BorderEdges, allowOverdraw: Bool
) -> Bool {
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

    if rect.isEmpty()
      && !paintsBorderImage(rect: rect, ninePieceImage: style.borderImage(), style: style)
    {
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

  private func paintsBorderImage(
    rect: LayoutRectWrapper, ninePieceImage: NinePieceImage, style: RenderStyleWrapper
  ) -> Bool {
    let styleImage = ninePieceImage.image()
    if styleImage == nil {
      return false
    }

    if !styleImage!.isLoaded(renderer: renderer) {
      return false
    }

    if !styleImage!.canRender(renderer: renderer, multiplier: style.usedZoom()) {
      return false
    }

    var rectWithOutsets = rect
    rectWithOutsets.expand(box: style.imageOutsets(image: ninePieceImage))
    return !rectWithOutsets.isEmpty()
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
    let boundingRect = border.rect
    if clipRect.contains(other: boundingRect) {
      return false
    }

    let radii = border.radii

    let topLeftRect = LayoutRectWrapper(location: boundingRect.location(), size: radii.topLeft)
    if clipRect.intersects(other: topLeftRect) {
      return false
    }

    var topRightRect = LayoutRectWrapper(location: boundingRect.location(), size: radii.topRight)
    topRightRect.setX(x: boundingRect.maxX() - topRightRect.width())
    if clipRect.intersects(other: topRightRect) {
      return false
    }

    var bottomLeftRect = LayoutRectWrapper(
      location: boundingRect.location(), size: radii.bottomLeft)
    bottomLeftRect.setY(y: boundingRect.maxY() - bottomLeftRect.height())
    if clipRect.intersects(other: bottomLeftRect) {
      return false
    }

    var bottomRightRect = LayoutRectWrapper(
      location: boundingRect.location(), size: radii.bottomRight)
    bottomRightRect.setX(x: boundingRect.maxX() - bottomRightRect.width())
    bottomRightRect.setY(y: boundingRect.maxY() - bottomRightRect.height())
    if clipRect.intersects(other: bottomRightRect) {
      return false
    }

    return true
  }

  static func shouldAntialiasLines(context: GraphicsContextWrapper) -> Bool {
    // FIXME: We may want to not antialias when scaled by an integral value,
    // and we may want to antialias when translated by a non-integral value.
    return !context.getCTM().isIdentityOrTranslationOrFlipped()
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
    let graphicsContext = paintInfo.context()

    assert(!graphicsContext.paintingDisabled())

    // If no borders intersects with the dirty area, we can skip the painting.
    if sides.innerBorder.contains(otherRect: paintInfo.rect) {
      return
    }

    var haveAlphaColor = false
    var haveAllDoubleEdges = true
    var numEdgesVisible = 4
    var allEdgesShareColor = true
    var firstVisibleSide: BoxSide? = nil
    var edgesToDraw = BoxSideSet()

    for boxSide in allBoxSides {
      let currEdge = sides.edges.at(side: boxSide)

      if currEdge.shouldRender() {
        edgesToDraw.update(with: edgeFlagForSide(side: boxSide))
      }

      if currEdge.presentButInvisible() {
        numEdgesVisible -= 1
        allEdgesShareColor = false
        continue
      }

      if currEdge.widthForPainting() == 0 {
        numEdgesVisible -= 1
        continue
      }

      if firstVisibleSide == nil {
        firstVisibleSide = boxSide
      } else if !equalIgnoringSemanticColor(
        a: currEdge.color, b: sides.edges.at(side: firstVisibleSide!).color)
      {
        allEdgesShareColor = false
      }

      if !currEdge.color.isOpaque() {
        haveAlphaColor = true
      }

      if currEdge.style != .Double {
        haveAllDoubleEdges = false
      }
    }

    let deviceScaleFactor = document().deviceScaleFactor()
    if (sides.haveAllSolidEdges || haveAllDoubleEdges) && allEdgesShareColor {
      // Fast path for drawing all solid edges and all unrounded double edges
      if numEdgesVisible == 4 && (sides.outerBorder.isRounded() || haveAlphaColor)
        && (sides.haveAllSolidEdges
          || (!sides.outerBorder.isRounded() && !sides.innerBorder.isRounded()))
      {
        let path = PathWrapper()

        let pixelSnappedOuterBorder = sides.outerBorder.pixelSnappedRoundedRectForPainting(
          deviceScaleFactor: deviceScaleFactor)
        if pixelSnappedOuterBorder.isRounded()
          && sides.bleedAvoidance != .BackgroundBleedUseTransparencyLayer
        {
          path.addRoundedRect(roundedRect: pixelSnappedOuterBorder)
        } else {
          path.addRect(rect: pixelSnappedOuterBorder.rect())
        }

        if haveAllDoubleEdges {
          var innerThirdRect = sides.outerBorder.rect
          var outerThirdRect = sides.outerBorder.rect
          for side in allBoxSides {
            let (outerWidth, innerWidth) = sides.edges.at(side: side).getDoubleBorderStripeWidths()
            switch side {
            case .Top:
              innerThirdRect.shiftYEdgeTo(edge: innerThirdRect.y() + innerWidth)
              outerThirdRect.shiftYEdgeTo(edge: outerThirdRect.y() + outerWidth)
            case .Right:
              innerThirdRect.setWidth(width: innerThirdRect.width() - innerWidth)
              outerThirdRect.setWidth(width: outerThirdRect.width() - outerWidth)
            case .Bottom:
              innerThirdRect.setHeight(height: innerThirdRect.height() - innerWidth)
              outerThirdRect.setHeight(height: outerThirdRect.height() - outerWidth)
            case .Left:
              innerThirdRect.shiftXEdgeTo(edge: innerThirdRect.x() + innerWidth)
              outerThirdRect.shiftXEdgeTo(edge: outerThirdRect.x() + outerWidth)
            }
          }

          var pixelSnappedOuterThird = sides.outerBorder.pixelSnappedRoundedRectForPainting(
            deviceScaleFactor: deviceScaleFactor)
          pixelSnappedOuterThird.setRect(
            rect: snapRectToDevicePixels(
              rect: outerThirdRect, pixelSnappingFactor: deviceScaleFactor))

          if pixelSnappedOuterThird.isRounded()
            && sides.bleedAvoidance != .BackgroundBleedUseTransparencyLayer
          {
            path.addRoundedRect(roundedRect: pixelSnappedOuterThird)
          } else {
            path.addRect(rect: pixelSnappedOuterThird.rect())
          }

          var pixelSnappedInnerThird = sides.innerBorder.pixelSnappedRoundedRectForPainting(
            deviceScaleFactor: deviceScaleFactor)
          pixelSnappedInnerThird.setRect(
            rect: snapRectToDevicePixels(
              rect: innerThirdRect, pixelSnappingFactor: deviceScaleFactor))
          if pixelSnappedInnerThird.isRounded()
            && sides.bleedAvoidance != .BackgroundBleedUseTransparencyLayer
          {
            path.addRoundedRect(roundedRect: pixelSnappedInnerThird)
          } else {
            path.addRect(rect: pixelSnappedInnerThird.rect())
          }
        }

        let pixelSnappedInnerBorder = sides.innerBorder.pixelSnappedRoundedRectForPainting(
          deviceScaleFactor: deviceScaleFactor)
        if pixelSnappedInnerBorder.isRounded() {
          path.addRoundedRect(roundedRect: pixelSnappedInnerBorder)
        } else {
          path.addRect(rect: pixelSnappedInnerBorder.rect())
        }

        graphicsContext.setFillRule(fillRule: .EvenOdd)
        graphicsContext.setFillColor(color: sides.edges.at(side: firstVisibleSide!).color)
        graphicsContext.fillPath(path: path)
        return
      }
      // Avoid creating transparent layers
      if sides.haveAllSolidEdges && numEdgesVisible != 4 && !sides.outerBorder.isRounded()
        && haveAlphaColor
      {
        let path = PathWrapper()

        for side in allBoxSides {
          if sides.edges.at(side: side).shouldRender() {
            let sideRect = calculateSideRect(
              outerBorder: sides.outerBorder, edges: sides.edges, side: side)
            path.addRect(rect: sideRect.FloatRect())  // FIXME: Need pixel snapping here.
          }
        }

        graphicsContext.setFillRule(fillRule: .NonZero)
        graphicsContext.setFillColor(color: sides.edges.at(side: firstVisibleSide!).color)
        graphicsContext.fillPath(path: path)
        return
      }
    }

    let clipToOuterBorder = sides.outerBorder.isRounded()
    let _ = GraphicsContextStateSaver(
      context: graphicsContext, saveAndRestore: clipToOuterBorder && !sides.appliedClipAlready)
    if clipToOuterBorder {
      // Clip to the inner and outer radii rects.
      if sides.bleedAvoidance != .BackgroundBleedUseTransparencyLayer {
        graphicsContext.clipRoundedRect(
          rect: sides.outerBorder.pixelSnappedRoundedRectForPainting(
            deviceScaleFactor: deviceScaleFactor))
      }
      graphicsContext.clipOutRoundedRect(
        rect: sides.innerBorder.pixelSnappedRoundedRectForPainting(
          deviceScaleFactor: deviceScaleFactor))
    }

    // If only one edge visible antialiasing doesn't create seams
    let antialias =
      BorderPainter.shouldAntialiasLines(context: graphicsContext) || numEdgesVisible == 1
    let innerBorderAdjustment = IntPoint(
      x: (sides.innerBorder.rect.x() - sides.unadjustedInnerBorder.rect.x()).toInt(),
      y: (sides.innerBorder.rect.y() - sides.unadjustedInnerBorder.rect.y()).toInt())
    if haveAlphaColor {
      paintTranslucentBorderSides(
        outerBorder: sides.outerBorder, innerBorder: sides.unadjustedInnerBorder,
        innerBorderAdjustment: innerBorderAdjustment, edges: sides.edges,
        edgesToDraw: edgesToDraw, radii: sides.radii, bleedAvoidance: sides.bleedAvoidance,
        includeLogicalLeftEdge: sides.includeLogicalLeftEdge,
        includeLogicalRightEdge: sides.includeLogicalRightEdge, antialias: antialias,
        isHorizontal: sides.isHorizontal)
    } else {
      paintBorderSides(
        outerBorder: sides.outerBorder, innerBorder: sides.unadjustedInnerBorder,
        innerBorderAdjustment: innerBorderAdjustment, edges: sides.edges,
        edgeSet: edgesToDraw, radii: sides.radii, bleedAvoidance: sides.bleedAvoidance,
        includeLogicalLeftEdge: sides.includeLogicalLeftEdge,
        includeLogicalRightEdge: sides.includeLogicalRightEdge, antialias: antialias,
        isHorizontal: sides.isHorizontal)
    }
  }

  private func paintTranslucentBorderSides(
    outerBorder: RoundedRect, innerBorder: RoundedRect, innerBorderAdjustment: IntPoint,
    edges: BorderEdges, edgesToDraw: BoxSideSet, radii: BorderData.Radii?,
    bleedAvoidance: BackgroundBleedAvoidance, includeLogicalLeftEdge: Bool,
    includeLogicalRightEdge: Bool, antialias: Bool, isHorizontal: Bool
  ) {
    var edgesToDraw = edgesToDraw
    while !edgesToDraw.isEmpty {
      // Find undrawn edges sharing a color.
      var commonColor = ColorWrapper()

      var commonColorEdgeSet = BoxSideSet()
      for side in BorderPainter.paintOrderSides {
        if !edgesToDraw.contains(edgeFlagForSide(side: side)) {
          continue
        }

        let edge = edges.at(side: side)
        var includeEdge = false
        if commonColorEdgeSet.isEmpty {
          commonColor = edge.color
          includeEdge = true
        } else {
          includeEdge = equalIgnoringSemanticColor(a: edge.color, b: commonColor)
        }

        if includeEdge {
          commonColorEdgeSet.update(with: edgeFlagForSide(side: side))
        }
      }

      let useTransparencyLayer =
        includesAdjacentEdges(flags: commonColorEdgeSet) && !commonColor.isOpaque()
      if useTransparencyLayer {
        paintInfo.context().beginTransparencyLayer(opacity: commonColor.alphaAsFloat())
        commonColor = commonColor.opaqueColor()
      }

      paintBorderSides(
        outerBorder: outerBorder, innerBorder: innerBorder,
        innerBorderAdjustment: innerBorderAdjustment, edges: edges, edgeSet: commonColorEdgeSet,
        radii: radii,
        bleedAvoidance: bleedAvoidance, includeLogicalLeftEdge: includeLogicalLeftEdge,
        includeLogicalRightEdge: includeLogicalRightEdge, antialias: antialias,
        isHorizontal: isHorizontal,
        overrideColor: commonColor)

      if useTransparencyLayer {
        paintInfo.context().endTransparencyLayer()
      }

      edgesToDraw.subtract(commonColorEdgeSet)
    }
  }

  private func paintBorderSides(
    outerBorder: RoundedRect, innerBorder: RoundedRect, innerBorderAdjustment: IntPoint,
    edges: BorderEdges, edgeSet: BoxSideSet, radii: BorderData.Radii?,
    bleedAvoidance: BackgroundBleedAvoidance, includeLogicalLeftEdge: Bool,
    includeLogicalRightEdge: Bool, antialias: Bool, isHorizontal: Bool,
    overrideColor: ColorWrapper? = nil
  ) {
    let renderRadii = outerBorder.isRounded()

    let roundedPath = PathWrapper()
    if renderRadii {
      roundedPath.addRoundedRect(rect: outerBorder)
    }

    // The inner border adjustment for bleed avoidance mode BackgroundBleedBackgroundOverBorder
    // is only applied to sideRect, which is okay since BackgroundBleedBackgroundOverBorder
    // is only to be used for solid borders and the shape of the border painted by drawBoxSideFromPath
    // only depends on sideRect when painting solid borders.

    paintOneSide(
      side: .Top, adjacentSide1: .Left, adjacentSide2: .Right, outerBorder: outerBorder,
      innerBorder: innerBorder, innerBorderAdjustment: innerBorderAdjustment, edges: edges,
      edgeSet: edgeSet, radii: radii, bleedAvoidance: bleedAvoidance,
      includeLogicalLeftEdge: includeLogicalLeftEdge,
      includeLogicalRightEdge: includeLogicalRightEdge, antialias: antialias,
      isHorizontal: isHorizontal, overrideColor: overrideColor, renderRadii: renderRadii,
      roundedPath: roundedPath)
    paintOneSide(
      side: .Bottom, adjacentSide1: .Left, adjacentSide2: .Right, outerBorder: outerBorder,
      innerBorder: innerBorder, innerBorderAdjustment: innerBorderAdjustment, edges: edges,
      edgeSet: edgeSet, radii: radii, bleedAvoidance: bleedAvoidance,
      includeLogicalLeftEdge: includeLogicalLeftEdge,
      includeLogicalRightEdge: includeLogicalRightEdge, antialias: antialias,
      isHorizontal: isHorizontal, overrideColor: overrideColor, renderRadii: renderRadii,
      roundedPath: roundedPath)
    paintOneSide(
      side: .Left, adjacentSide1: .Top, adjacentSide2: .Bottom, outerBorder: outerBorder,
      innerBorder: innerBorder, innerBorderAdjustment: innerBorderAdjustment, edges: edges,
      edgeSet: edgeSet, radii: radii, bleedAvoidance: bleedAvoidance,
      includeLogicalLeftEdge: includeLogicalLeftEdge,
      includeLogicalRightEdge: includeLogicalRightEdge, antialias: antialias,
      isHorizontal: isHorizontal, overrideColor: overrideColor, renderRadii: renderRadii,
      roundedPath: roundedPath)
    paintOneSide(
      side: .Right, adjacentSide1: .Top, adjacentSide2: .Bottom, outerBorder: outerBorder,
      innerBorder: innerBorder, innerBorderAdjustment: innerBorderAdjustment, edges: edges,
      edgeSet: edgeSet, radii: radii, bleedAvoidance: bleedAvoidance,
      includeLogicalLeftEdge: includeLogicalLeftEdge,
      includeLogicalRightEdge: includeLogicalRightEdge, antialias: antialias,
      isHorizontal: isHorizontal, overrideColor: overrideColor, renderRadii: renderRadii,
      roundedPath: roundedPath)
  }

  private func paintOneSide(
    side: BoxSide, adjacentSide1: BoxSide, adjacentSide2: BoxSide, outerBorder: RoundedRect,
    innerBorder: RoundedRect, innerBorderAdjustment: IntPoint, edges: BorderEdges,
    edgeSet: BoxSideSet, radii: BorderData.Radii?,
    bleedAvoidance: BackgroundBleedAvoidance, includeLogicalLeftEdge: Bool,
    includeLogicalRightEdge: Bool, antialias: Bool, isHorizontal: Bool,
    overrideColor: ColorWrapper?, renderRadii: Bool, roundedPath: PathWrapper
  ) {
    let edge = edges.at(side: side)
    if !edge.shouldRender() || !edgeSet.contains(edgeFlagForSide(side: side)) {
      return
    }

    var sideRect = outerBorder.rect
    var firstRadius = LayoutSizeWrapper()
    var secondRadius = LayoutSizeWrapper()

    switch side {
    case .Top:
      sideRect.setHeight(height: edge.widthForPainting() + Float32(innerBorderAdjustment.y))
      firstRadius = innerBorder.radii.topLeft
      secondRadius = innerBorder.radii.topRight
    case .Right:
      sideRect.shiftXEdgeTo(
        edge: sideRect.maxX() - edge.widthForPainting() - Float32(innerBorderAdjustment.x))
      firstRadius = innerBorder.radii.bottomRight
      secondRadius = innerBorder.radii.topRight
    case .Bottom:
      sideRect.shiftYEdgeTo(
        edge: sideRect.maxY() - edge.widthForPainting() - Float32(innerBorderAdjustment.y))
      firstRadius = innerBorder.radii.bottomLeft
      secondRadius = innerBorder.radii.bottomRight
    case .Left:
      sideRect.setWidth(width: edge.widthForPainting() + Float32(innerBorderAdjustment.x))
      firstRadius = innerBorder.radii.bottomLeft
      secondRadius = innerBorder.radii.topLeft
    }

    let usePath =
      renderRadii
      && (borderStyleHasInnerDetail(style: edge.style)
        || borderWillArcInnerEdge(firstRadius: firstRadius, secondRadius: secondRadius))
    paintOneBorderSide(
      outerBorder: outerBorder, innerBorder: innerBorder, sideRect: sideRect, side: side,
      adjacentSide1: adjacentSide1, adjacentSide2: adjacentSide2, edges: edges, radii: radii,
      path: usePath ? roundedPath : nil, bleedAvoidance: bleedAvoidance,
      includeLogicalLeftEdge: includeLogicalLeftEdge,
      includeLogicalRightEdge: includeLogicalRightEdge, antialias: antialias,
      isHorizontal: isHorizontal, overrideColor: overrideColor)
  }

  private func paintOneBorderSide(
    outerBorder: RoundedRect, innerBorder: RoundedRect,
    sideRect: LayoutRectWrapper, side: BoxSide,
    adjacentSide1: BoxSide, adjacentSide2: BoxSide,
    edges: BorderEdges, radii: BorderData.Radii?, path: PathWrapper?,
    bleedAvoidance: BackgroundBleedAvoidance, includeLogicalLeftEdge: Bool,
    includeLogicalRightEdge: Bool, antialias: Bool, isHorizontal: Bool, overrideColor: ColorWrapper?
  ) {
    let edgeToRender = edges.at(side: side)
    assert(edgeToRender.widthForPainting() != 0)
    let adjacentEdge1 = edges.at(side: adjacentSide1)
    let adjacentEdge2 = edges.at(side: adjacentSide2)

    let /*mitreAdjacentSide1*/ _ = joinRequiresMitre(
      side: side, adjacentSide: adjacentSide1, edges: edges, allowOverdraw: !antialias)
    let /*mitreAdjacentSide2*/ _ = joinRequiresMitre(
      side: side, adjacentSide: adjacentSide2, edges: edges, allowOverdraw: !antialias)

    let adjacentSide1StylesMatch = colorsMatchAtCorner(
      side: side, adjacentSide: adjacentSide1, edges: edges)
    let adjacentSide2StylesMatch = colorsMatchAtCorner(
      side: side, adjacentSide: adjacentSide2, edges: edges)

    let colorToPaint = overrideColor != nil ? overrideColor! : edgeToRender.color

    let graphicsContext = paintInfo.context()

    if let path = path {
      let _ = GraphicsContextStateSaver(context: graphicsContext)

      clipBorderSidePolygon(
        outerBorder: outerBorder, innerBorder: innerBorder, side: side,
        firstEdgeMatches: adjacentSide1StylesMatch, secondEdgeMatches: adjacentSide2StylesMatch)

      let thickness = max(
        edgeToRender.widthForPainting(), adjacentEdge1.widthForPainting(),
        adjacentEdge2.widthForPainting())
      drawBoxSideFromPath(
        borderRect: outerBorder.rect, borderPath: path, edges: edges, radii: radii,
        thickness: edgeToRender.widthForPainting(), drawThickness: thickness, side: side,
        color: colorToPaint, borderStyle: edgeToRender.style, bleedAvoidance: bleedAvoidance,
        includeLogicalLeftEdge: includeLogicalLeftEdge,
        includeLogicalRightEdge: includeLogicalRightEdge, isHorizontal: isHorizontal)
    } else {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  private func drawBoxSideFromPath(
    borderRect: LayoutRectWrapper, borderPath: PathWrapper, edges: BorderEdges,
    radii: BorderData.Radii?, thickness: Float32, drawThickness: Float32, side: BoxSide,
    color: ColorWrapper, borderStyle: BorderStyle, bleedAvoidance: BackgroundBleedAvoidance,
    includeLogicalLeftEdge: Bool, includeLogicalRightEdge: Bool, isHorizontal: Bool
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func clipBorderSidePolygon(
    outerBorder: RoundedRect, innerBorder: RoundedRect, side: BoxSide, firstEdgeMatches: Bool,
    secondEdgeMatches: Bool
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func borderRectAdjustedForBleedAvoidance(
    rect: LayoutRectWrapper, bleedAvoidance: BackgroundBleedAvoidance
  ) -> LayoutRectWrapper {
    if bleedAvoidance != .BackgroundBleedBackgroundOverBorder {
      return rect
    }

    // We shrink the rectangle by one device pixel on each side to make it fully overlap the anti-aliased background border
    return shrinkRectByOneDevicePixel(
      context: paintInfo.context(), rect: rect, devicePixelRatio: document().deviceScaleFactor())
  }

  private func document() -> Document { return renderer.document() }

  private let renderer: RenderElementWrapper
  private let paintInfo: PaintInfoWrapper

  // willBeOverdrawn assumes that we draw in order: top, bottom, left, right.
  // This is different from BoxSide enum order.
  private static let paintOrderSides: [BoxSide] = [.Top, .Bottom, .Left, .Right]
}
