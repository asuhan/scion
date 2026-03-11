/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003-2022 Apple Inc. All rights reserved.
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

import Foundation

private func applyBoxShadowForBackground(context: GraphicsContextWrapper, style: RenderStyleWrapper)
{
  var boxShadow = style.boxShadow()!
  while boxShadow.style != .Normal {
    boxShadow = boxShadow.next!
  }

  let shadowOffset = FloatSize(width: boxShadow.x().value(), height: boxShadow.y().value())
  context.setDropShadow(
    dropShadow: GraphicsDropShadow(
      offset: shadowOffset, radius: boxShadow.radius.value(),
      color: style.colorWithColorFilter(color: boxShadow.color),
      radiusMode: boxShadow.isWebkitBoxShadow ? .Legacy : .Default))
}

private func getSpace(areaSize: LayoutUnit, tileSize: LayoutUnit) -> LayoutUnit? {
  let numberOfTiles = areaSize / tileSize
  if numberOfTiles > 1 {
    return (areaSize - numberOfTiles * tileSize) / (numberOfTiles - 1)
  }
  return nil
}

private func resolveEdgeRelativeLength(
  length: LengthWrapper, edge: Edge, availableSpace: LayoutUnit, areaSize: LayoutSizeWrapper,
  tileSize: LayoutSizeWrapper
) -> LayoutUnit {
  let result = minimumValueForLength(length: length, maximumValue: availableSpace)

  if edge == .Right {
    return areaSize.width() - tileSize.width() - result
  }

  if edge == .Bottom {
    return areaSize.height() - tileSize.height() - result
  }

  return result
}

private func pixelSnapBackgroundImageGeometryForPainting(
  destinationRect: inout LayoutRectWrapper, tileSize: inout LayoutSizeWrapper,
  phase: inout LayoutSizeWrapper, space: inout LayoutSizeWrapper, scaleFactor: Float32
) {
  tileSize = LayoutSizeWrapper(
    size: snapRectToDevicePixels(
      rect: LayoutRectWrapper(location: destinationRect.location(), size: tileSize),
      pixelSnappingFactor: scaleFactor
    ).size())
  phase = LayoutSizeWrapper(
    size: snapRectToDevicePixels(
      rect: LayoutRectWrapper(location: destinationRect.location(), size: phase),
      pixelSnappingFactor: scaleFactor
    )
    .size())
  space = LayoutSizeWrapper(
    size: snapRectToDevicePixels(
      rect: LayoutRectWrapper(location: LayoutPointWrapper(), size: space),
      pixelSnappingFactor: scaleFactor
    ).size())
  destinationRect = LayoutRectWrapper(
    r: snapRectToDevicePixels(rect: destinationRect, pixelSnappingFactor: scaleFactor))
}

private func areaCastingShadowInHole(
  holeRect: LayoutRectWrapper, shadowExtent: LayoutUnit, shadowSpread: LayoutUnit,
  shadowOffset: LayoutSizeWrapper
) -> LayoutRectWrapper {
  var bounds = holeRect

  bounds.inflate(d: shadowExtent)

  if shadowSpread < Int32(0) {
    bounds.inflate(d: -shadowSpread)
  }

  var offsetBounds = bounds
  offsetBounds.move(size: -shadowOffset)
  return unionRect(a: bounds, b: offsetBounds)
}

struct BackgroundImageGeometry {
  init(
    destinationRect: LayoutRectWrapper, tileSizeWithoutPixelSnapping: LayoutSizeWrapper,
    tileSize: LayoutSizeWrapper, phase: LayoutSizeWrapper, spaceSize: LayoutSizeWrapper,
    fixedAttachment: Bool
  ) {
    self.destinationRect = destinationRect
    self.destinationOrigin = destinationRect.location()
    self.tileSizeWithoutPixelSnapping = tileSizeWithoutPixelSnapping
    self.tileSize = tileSize
    self.phase = phase
    self.spaceSize = spaceSize
    self.hasNonLocalGeometry = fixedAttachment
  }

  func relativePhase() -> LayoutSizeWrapper {
    var relativePhase = phase.deepCopy()
    relativePhase += destinationRect.location() - destinationOrigin
    return relativePhase
  }

  mutating func clip(clipRect: LayoutRectWrapper) {
    destinationRect.intersect(other: clipRect)
  }

  var destinationRect: LayoutRectWrapper
  let destinationOrigin: LayoutPointWrapper
  let tileSizeWithoutPixelSnapping: LayoutSizeWrapper
  let tileSize: LayoutSizeWrapper
  let phase: LayoutSizeWrapper
  let spaceSize: LayoutSizeWrapper
  let hasNonLocalGeometry: Bool  // Has background-attachment: fixed. Implies that we can't always cheaply compute destRect.
}

class BackgroundPainter {
  init(renderer: RenderBoxModelObjectWrapper, paintInfo: PaintInfoWrapper) {
    self.renderer = renderer
    self.paintInfo = paintInfo
    // background-clip has no effect when painting the root background.
    // https://www.w3.org/TR/css-backgrounds-3/#background-clip
    if renderer.isDocumentElementRenderer() {
      setOverrideClip(overrideClip: .BorderBox)
    }
  }

  func setOverrideClip(overrideClip: FillBox) {
    self.overrideClip = overrideClip
  }

  func setOverrideOrigin(overrideOrigin: FillBox) {
    self.overrideOrigin = overrideOrigin
  }

  func paintBackground(paintRect: LayoutRectWrapper, bleedAvoidance: BackgroundBleedAvoidance) {
    if renderer.isDocumentElementRenderer() {
      paintRootBoxFillLayers()
      return
    }

    if !BackgroundPainter.paintsOwnBackground(renderer: renderer) {
      return
    }

    if renderer.backgroundIsKnownToBeObscured(paintOffset: paintRect.location())
      && !BackgroundPainter.boxShadowShouldBeAppliedToBackground(
        renderer: renderer, paintOffset: paintRect.location(), bleedAvoidance: bleedAvoidance,
        inlineBox: InlineIterator.InlineBoxIterator())
    {
      return
    }

    let backgroundColor = renderer.style().visitedDependentColorWithColorFilter(
      colorProperty: .CSSPropertyBackgroundColor)
    let compositeOp = document().compositeOperatorForBackgroundColor(
      color: backgroundColor, renderer: renderer)

    paintFillLayers(
      color: backgroundColor, fillLayer: renderer.style().backgroundLayers(), rect: paintRect,
      bleedAvoidance: bleedAvoidance, op: compositeOp)
  }

  func paintFillLayers(
    color: ColorWrapper, fillLayer: FillLayerWrapper, rect: LayoutRectWrapper,
    bleedAvoidance: BackgroundBleedAvoidance, op: CompositeOperator,
    backgroundObject: RenderElementWrapper? = nil
  ) {
    var layers: [FillLayerWrapper] = []
    var shouldDrawBackgroundInSeparateBuffer = false

    var layer: FillLayerWrapper? = fillLayer
    while layer != nil {
      layers.append(layer!)

      if layer!.blendMode != .Normal {
        shouldDrawBackgroundInSeparateBuffer = true
      }

      // Stop traversal when an opaque layer is encountered.
      // FIXME: It would be possible for the following occlusion culling test to be more aggressive
      // on layers with no repeat by testing whether the image covers the layout rect.
      // Testing that here would imply duplicating a lot of calculations that are currently done in
      // BackgroundPainter::paintFillLayer. A more efficient solution might be to move
      // the layer recursion into paintFillLayer, or to compute the layer geometry here
      // and pass it down.

      // The clipOccludesNextLayers condition must be evaluated first to avoid short-circuiting.
      if layer!.clipOccludesNextLayers(
        firstLayer: ObjectIdentifier(layer!) == ObjectIdentifier(fillLayer))
        && layer!.hasOpaqueImage(renderer: renderer)
        && layer!.image()!.canRender(renderer: renderer, multiplier: renderer.style().usedZoom())
        && layer!.hasRepeatXY()
        && layer!.blendMode == .Normal
        && !BackgroundPainter.boxShadowShouldBeAppliedToBackground(
          renderer: renderer, paintOffset: rect.location(), bleedAvoidance: bleedAvoidance,
          inlineBox: InlineIterator.InlineBoxIterator())
      {
        break
      }

      layer = layer!.next()
    }

    let context = paintInfo.context()
    var baseBgColorUsage: BaseBackgroundColorUsage = .BaseBackgroundColorUse

    if shouldDrawBackgroundInSeparateBuffer {
      paintFillLayer(
        color: color, bgLayer: layers.last!, rect: rect, bleedAvoidance: bleedAvoidance,
        inlineBoxIterator: InlineIterator.InlineBoxIterator(),
        backgroundImageStrip: LayoutRectWrapper(), op: op,
        backgroundObject: backgroundObject, baseBgColorUsage: .BaseBackgroundColorOnly)
      baseBgColorUsage = .BaseBackgroundColorSkip
      context.beginTransparencyLayer(opacity: 1)
    }

    for layer in layers.reversed() {
      paintFillLayer(
        color: color, bgLayer: layer, rect: rect, bleedAvoidance: bleedAvoidance,
        inlineBoxIterator: InlineIterator.InlineBoxIterator(),
        backgroundImageStrip: LayoutRectWrapper(), op: op, backgroundObject: backgroundObject,
        baseBgColorUsage: baseBgColorUsage)
    }

    if shouldDrawBackgroundInSeparateBuffer {
      context.endTransparencyLayer()
    }
  }

  func paintFillLayer(
    color: ColorWrapper, bgLayer: FillLayerWrapper, rect: LayoutRectWrapper,
    bleedAvoidance: BackgroundBleedAvoidance, inlineBoxIterator: InlineIterator.InlineBoxIterator,
    backgroundImageStrip: LayoutRectWrapper = LayoutRectWrapper(),
    op: CompositeOperator = .SourceOver,
    backgroundObject: RenderElementWrapper? = nil,
    baseBgColorUsage: BaseBackgroundColorUsage = .BaseBackgroundColorUse
  ) {
    var baseBgColorUsage = baseBgColorUsage
    let context = paintInfo.context()

    if (context.paintingDisabled() && !context.detectingContentfulPaint()) || rect.isEmpty() {
      return
    }

    let (includeLeftEdge, includeRightEdge) =
      inlineBoxIterator.bool() ? inlineBoxIterator.get().hasClosedLeftAndRightEdge() : (true, true)

    let style = renderer.style()
    let layerClip = overrideClip ?? bgLayer.clip

    let hasRoundedBorder = style.hasBorderRadius() && (includeLeftEdge || includeRightEdge)
    let clippedWithLocalScrolling =
      renderer.hasNonVisibleOverflow() && bgLayer.attachment == .LocalBackground
    let isBorderFill = layerClip == .BorderBox
    let isRoot = renderer.isDocumentElementRenderer()

    var bgColor = color
    let bgImage = bgLayer.image()
    var shouldPaintBackgroundImage =
      bgImage != nil && bgImage!.canRender(renderer: renderer, multiplier: style.usedZoom())

    if context.detectingContentfulPaint() {
      if !context.contentfulPaintDetected() && shouldPaintBackgroundImage
        && bgImage!.cachedImage() != nil
      {
        if style.backgroundSizeType() != .Size || !style.backgroundSizeLength().isEmpty() {
          context.setContentfulPaintDetected()
        }
        return
      }
    }

    if context.invalidatingImagesWithAsyncDecodes() {
      if shouldPaintBackgroundImage
        && bgImage!.cachedImage()!.isClientWaitingForAsyncDecoding(client: renderer)
      {
        bgImage!.cachedImage()!.removeAllClientsWaitingForAsyncDecoding()
      }
      return
    }

    var forceBackgroundToWhite = false
    if document().printing() {
      if style.printColorAdjust() == .Economy {
        forceBackgroundToWhite = true
      }
      if document().settings().shouldPrintBackgrounds() {
        forceBackgroundToWhite = false
      }
    }

    // When printing backgrounds is disabled or using economy mode,
    // change existing background colors and images to a solid white background.
    // If there's no bg color or image, leave it untouched to avoid affecting transparency.
    // We don't try to avoid loading the background images, because this style flag is only set
    // when printing, and at that point we've already loaded the background images anyway. (To avoid
    // loading the background images we'd have to do this check when applying styles rather than
    // while rendering.)
    if forceBackgroundToWhite {
      // Note that we can't reuse this variable below because the bgColor might be changed
      let shouldPaintBackgroundColor = bgLayer.next() == nil && bgColor.isVisible()
      if shouldPaintBackgroundImage || shouldPaintBackgroundColor {
        bgColor = .white
        shouldPaintBackgroundImage = false
      }
    }

    let baseBgColorOnly = (baseBgColorUsage == .BaseBackgroundColorOnly)
    if baseBgColorOnly && (!isRoot || bgLayer.next() != nil || bgColor.isOpaque()) {
      return
    }

    let colorVisible = bgColor.isVisible()
    let deviceScaleFactor = document().deviceScaleFactor()
    let pixelSnappedRect = snapRectToDevicePixels(
      rect: rect, pixelSnappingFactor: deviceScaleFactor)

    // Fast path for drawing simple color backgrounds.
    if !isRoot && !clippedWithLocalScrolling && !shouldPaintBackgroundImage && isBorderFill
      && bgLayer.next() == nil
    {
      if !colorVisible {
        return
      }

      let applyBoxShadowToBackground = BackgroundPainter.boxShadowShouldBeAppliedToBackground(
        renderer: renderer, paintOffset: rect.location(), bleedAvoidance: bleedAvoidance,
        inlineBox: inlineBoxIterator)
      let _ = GraphicsContextStateSaver(
        context: context, saveAndRestore: applyBoxShadowToBackground)
      if applyBoxShadowToBackground {
        applyBoxShadowForBackground(context: context, style: style)
      }

      if hasRoundedBorder && bleedAvoidance != .BackgroundBleedUseTransparencyLayer {
        let borderShape = borderShapeRespectingBleedAvoidance(
          includeLeftEdge: includeLeftEdge, includeRightEdge: includeRightEdge, rect: rect,
          bleedAvoidance: bleedAvoidance, deviceScaleFactor: deviceScaleFactor, style: style)
        let previousOperator = context.compositeOperation()
        let saveRestoreCompositeOp = op != previousOperator
        if saveRestoreCompositeOp {
          context.setCompositeOperation(operation: op)
        }

        if bleedAvoidance == .BackgroundBleedBackgroundOverBorder {
          borderShape.fillInnerShape(
            context: context, color: bgColor, deviceScaleFactor: deviceScaleFactor)
        } else {
          borderShape.fillOuterShape(
            context: context, color: bgColor, deviceScaleFactor: deviceScaleFactor)
        }

        if saveRestoreCompositeOp {
          context.setCompositeOperation(operation: previousOperator)
        }
      } else {
        context.fillRect(rect: pixelSnappedRect, color: bgColor, op: op)
      }

      return
    }

    // FillBox::BorderBox radius clipping is taken care of by BackgroundBleedUseTransparencyLayer
    let clipToBorderRadius =
      hasRoundedBorder && !(isBorderFill && bleedAvoidance == .BackgroundBleedUseTransparencyLayer)
    let _ = GraphicsContextStateSaver(context: context, saveAndRestore: clipToBorderRadius)
    if clipToBorderRadius {

      switch layerClip {
      case .BorderBox, .BorderArea, .Text, .NoClip:
        let borderShape = borderShapeRespectingBleedAvoidance(
          includeLeftEdge: includeLeftEdge, includeRightEdge: includeRightEdge, rect: rect,
          bleedAvoidance: bleedAvoidance, deviceScaleFactor: deviceScaleFactor, style: style,
          shrinkForBleedAvoidance: isBorderFill)
        borderShape.clipToOuterShape(context: context, deviceScaleFactor: deviceScaleFactor)
      case .PaddingBox:
        let borderShape = borderShapeRespectingBleedAvoidance(
          includeLeftEdge: includeLeftEdge, includeRightEdge: includeRightEdge, rect: rect,
          bleedAvoidance: bleedAvoidance, deviceScaleFactor: deviceScaleFactor, style: style,
          shrinkForBleedAvoidance: isBorderFill)
        borderShape.clipToInnerShape(context: context, deviceScaleFactor: deviceScaleFactor)
      case .ContentBox:
        let borderShape = renderer.borderShapeForContentClipping(borderBoxRect: rect)
        borderShape.clipToInnerShape(context: context, deviceScaleFactor: deviceScaleFactor)
      }
    }

    let bLeft = includeLeftEdge ? renderer.borderLeft() : LayoutUnit(value: 0)
    let bRight = includeRightEdge ? renderer.borderRight() : LayoutUnit(value: 0)
    let pLeft = includeLeftEdge ? renderer.paddingLeft() : LayoutUnit(value: 0)
    let pRight = includeRightEdge ? renderer.paddingRight() : LayoutUnit(value: 0)

    let _ = GraphicsContextStateSaver(context: context, saveAndRestore: clippedWithLocalScrolling)
    var scrolledPaintRect = rect
    if clippedWithLocalScrolling {
      // Clip to the overflow area.
      let renderBox = renderer as! RenderBoxWrapper
      context.clip(rect: renderBox.overflowClipRect(location: rect.location()).FloatRect())

      // Adjust the paint rect to reflect a scrolled content box with borders at the ends.
      scrolledPaintRect.moveBy(offset: LayoutPointWrapper(point: -renderBox.scrollPosition()))
      scrolledPaintRect.setWidth(
        width: bLeft + LayoutUnit(value: renderBox.layer()!.scrollWidth()) + bRight)
      scrolledPaintRect.setHeight(
        height: renderBox.borderTop() + LayoutUnit(value: renderBox.layer()!.scrollHeight())
          + renderBox.borderBottom()
      )
    }

    let backgroundClipStateSaver = GraphicsContextStateSaver(
      context: context, saveAndRestore: false)

    let backgroundClipOuterLayerScope = TransparencyLayerScope(
      context: context, alpha: 1, beginLayer: false)
    let backgroundClipInnerLayerScope = TransparencyLayerScope(
      context: context, alpha: 1, beginLayer: false)

    switch layerClip {
    case .BorderBox:
      break
    case .PaddingBox, .ContentBox:
      // Clip to the padding or content boxes as necessary.
      if !clipToBorderRadius {
        let includePadding = layerClip == .ContentBox
        let clipRect = LayoutRectWrapper(
          x: scrolledPaintRect.x() + bLeft + (includePadding ? pLeft : LayoutUnit(value: 0)),
          y: scrolledPaintRect.y() + renderer.borderTop()
            + (includePadding ? renderer.paddingTop() : LayoutUnit(value: 0)),
          width: scrolledPaintRect.width() - bLeft - bRight
            - (includePadding ? pLeft + pRight : LayoutUnit(value: 0)),
          height: scrolledPaintRect.height() - renderer.borderTop() - renderer.borderBottom()
            - (includePadding
              ? renderer.paddingTop() + renderer.paddingBottom() : LayoutUnit(value: 0)))
        backgroundClipStateSaver.save()
        context.clip(rect: clipRect.FloatRect())
      }
    case .Text:
      // We have to draw our text into a mask that can then be used to clip background drawing.
      // First figure out how big the mask has to be. It should be no bigger than what we need
      // to actually render, so we should intersect the dirty rect with the border box of the background.
      setupMaskingBackgroundClip(
        borderRect: rect,
        paintFunction: {
          _, paintRect in
          renderer.paintMaskForTextFillBox(
            context: context, paintRect: paintRect, inlineBox: inlineBoxIterator,
            scrolledPaintRect: scrolledPaintRect)
        }, backgroundClipOuterLayerScope: backgroundClipOuterLayerScope,
        backgroundClipInnerLayerScope: backgroundClipInnerLayerScope, rect: rect,
        deviceScaleFactor: deviceScaleFactor,
        backgroundClipStateSaver: backgroundClipStateSaver, context: context)
    case .BorderArea:
      if let borderAreaPath = BorderPainter.pathForBorderArea(
        rect: rect, style: style, deviceScaleFactor: deviceScaleFactor,
        includeLogicalLeftEdge: includeLeftEdge, includeLogicalRightEdge: includeRightEdge)
      {
        backgroundClipStateSaver.save()
        context.clipPath(path: borderAreaPath)
        break
      }

      setupMaskingBackgroundClip(
        borderRect: rect,
        paintFunction: {
          borderRect, paintRect in
          let borderPaintInfo = PaintInfoWrapper(
            newContext: context, newRect: LayoutRectWrapper(r: paintRect),
            newPhase: .BlockBackground, newPaintBehavior: .ForceBlackBorder)
          let borderPainter = BorderPainter(renderer: renderer, paintInfo: borderPaintInfo)
          borderPainter.paintBorder(rect: borderRect, style: style)
        }, backgroundClipOuterLayerScope: backgroundClipOuterLayerScope,
        backgroundClipInnerLayerScope: backgroundClipInnerLayerScope, rect: rect,
        deviceScaleFactor: deviceScaleFactor,
        backgroundClipStateSaver: backgroundClipStateSaver, context: context)
    case .NoClip:
      break
    }

    var isOpaqueRoot = false
    if isRoot {
      let shouldPaintBaseBackground = view().rootElementShouldPaintBaseBackground()
      isOpaqueRoot = bgLayer.next() != nil || bgColor.isOpaque() || shouldPaintBaseBackground
      if !shouldPaintBaseBackground {
        baseBgColorUsage = .BaseBackgroundColorSkip
      }

      view().frameView().setContentIsOpaque(contentIsOpaque: isOpaqueRoot)
    }

    // Paint the color first underneath all images, culled if background image occludes it.
    // FIXME: In the bgLayer.hasFiniteBounds() case, we could improve the culling test
    // by verifying whether the background image covers the entire layout rect.
    if bgLayer.next() == nil {
      var backgroundRect = scrolledPaintRect
      let applyBoxShadowToBackground = BackgroundPainter.boxShadowShouldBeAppliedToBackground(
        renderer: renderer, paintOffset: rect.location(), bleedAvoidance: bleedAvoidance,
        inlineBox: inlineBoxIterator)
      if applyBoxShadowToBackground || !shouldPaintBackgroundImage
        || !bgLayer.hasOpaqueImage(renderer: renderer) || !bgLayer.hasRepeatXY()
        || bgLayer.isEmpty()
      {
        if !applyBoxShadowToBackground {
          backgroundRect.intersect(other: paintInfo.rect)
        }

        // If we have an alpha and we are painting the root element, blend with the base background color.
        var baseColor = ColorWrapper()
        var shouldClearBackground = false
        if (baseBgColorUsage != .BaseBackgroundColorSkip) && isOpaqueRoot {
          baseColor = view().frameView().baseBackgroundColor()
          if !baseColor.isVisible() {
            shouldClearBackground = true
          }
        }

        let _ = GraphicsContextStateSaver(
          context: context, saveAndRestore: applyBoxShadowToBackground)
        if applyBoxShadowToBackground {
          applyBoxShadowForBackground(context: context, style: style)
        }

        let backgroundRectForPainting = snapRectToDevicePixels(
          rect: backgroundRect, pixelSnappingFactor: deviceScaleFactor)
        if baseColor.isVisible() {
          if !baseBgColorOnly && bgColor.isVisible() {
            baseColor = blendSourceOver(backdrop: baseColor, source: bgColor)
          }
          context.fillRect(rect: backgroundRectForPainting, color: baseColor, op: .Copy)
        } else if !baseBgColorOnly && bgColor.isVisible() {
          var operation = context.compositeOperation()
          if shouldClearBackground {
            if op == .DestinationOut {  // We're punching out the background.
              operation = op
            } else {
              operation = .Copy
            }
          }
          context.fillRect(rect: backgroundRectForPainting, color: bgColor, op: operation)
        } else if shouldClearBackground {
          context.clearRect(rect: backgroundRectForPainting)
        }
      }
    }

    // no progressive loading of the background image
    if !baseBgColorOnly && shouldPaintBackgroundImage {
      // Multiline inline boxes paint like the image was one long strip spanning lines. The backgroundImageStrip is this fictional rectangle.
      let imageRect = backgroundImageStrip.isEmpty() ? scrolledPaintRect : backgroundImageStrip
      let paintOffset =
        backgroundImageStrip.isEmpty() ? rect.location() : backgroundImageStrip.location()
      var geometry = BackgroundPainter.calculateBackgroundImageGeometry(
        renderer: renderer, paintContainer: paintInfo.paintContainer, fillLayer: bgLayer,
        paintOffset: paintOffset, borderBoxRect: imageRect, overrideOrigin: overrideOrigin)

      let clientForBackgroundImage = backgroundObject ?? renderer
      bgImage!.setContainerContextForRenderer(
        renderer: clientForBackgroundImage,
        containerSize: geometry.tileSizeWithoutPixelSnapping.FloatSize(),
        containerZoom: renderer.style().usedZoom())

      geometry.clip(clipRect: LayoutRectWrapper(r: pixelSnappedRect))
      if geometry.destinationRect.isEmpty() {
        return
      }
      let isFirstLine =
        inlineBoxIterator.bool() && inlineBoxIterator.get().lineBox().get().isFirst()
      if let image = bgImage!.image(
        renderer: backgroundObject ?? renderer, size: geometry.tileSize.FloatSize(),
        isForFirstLine: isFirstLine
      ) {
        context.setDrawLuminanceMask(drawLuminanceMask: bgLayer.maskMode == .Luminance)

        let options = ImagePaintingOptionsWrapper(
          compositeOperator: op == .SourceOver ? bgLayer.compositeForPainting() : op,
          blendMode: bgLayer.blendMode,
          decodingMode: renderer.decodingModeForImageDraw(image: image, paintInfo: paintInfo),
          orientation: .FromImage,
          interpolationQuality: renderer.chooseInterpolationQuality(
            context: context, image: image, layer: bgLayer, size: geometry.tileSize
          ),
          allowImageSubsampling: document().settings().imageSubsamplingEnabled() ? .Yes : .No,
          showDebugBackground: document().settings().showDebugBorders() ? .Yes : .No
        )

        let drawResult = context.drawTiledImage(
          image: image, destination: geometry.destinationRect.FloatRect(),
          source: toLayoutPoint(size: geometry.relativePhase()).FloatPoint(),
          tileSize: geometry.tileSize.FloatSize(), spacing: geometry.spaceSize.FloatSize(),
          options: options)
        if drawResult == .DidRequestDecoding {
          assert(bgImage!.hasCachedImage())
          bgImage!.cachedImage()!.addClientWaitingForAsyncDecoding(client: renderer)
        }

        if renderer.element() != nil && !context.paintingDisabled() {
          renderer.element()!.setHasEverPaintedImages(hasEverPaintedImages: true)
        }
      }
    }
  }

  private func setupMaskingBackgroundClip(
    borderRect: LayoutRectWrapper, paintFunction: (LayoutRectWrapper, FloatRectWrapper) -> Void,
    backgroundClipOuterLayerScope: TransparencyLayerScope,
    backgroundClipInnerLayerScope: TransparencyLayerScope,
    rect: LayoutRectWrapper, deviceScaleFactor: Float32,
    backgroundClipStateSaver: GraphicsContextStateSaver,
    context: GraphicsContextWrapper
  ) {
    var transparencyLayerBounds = snapRectToDevicePixels(
      rect: rect, pixelSnappingFactor: deviceScaleFactor)
    transparencyLayerBounds.intersect(
      other: snapRectToDevicePixels(rect: paintInfo.rect, pixelSnappingFactor: deviceScaleFactor))
    transparencyLayerBounds.inflate(d: 1)

    backgroundClipStateSaver.save()
    context.clip(rect: transparencyLayerBounds)

    backgroundClipOuterLayerScope.beginLayer(alpha: 1)
    paintFunction(borderRect, transparencyLayerBounds)

    context.setCompositeOperation(operation: .SourceIn)
    backgroundClipInnerLayerScope.beginLayer(alpha: 1)
    context.setCompositeOperation(operation: .SourceOver)
  }

  private func borderShapeRespectingBleedAvoidance(
    includeLeftEdge: Bool, includeRightEdge: Bool, rect: LayoutRectWrapper,
    bleedAvoidance: BackgroundBleedAvoidance, deviceScaleFactor: Float32, style: RenderStyleWrapper,
    shrinkForBleedAvoidance: Bool = true
  ) -> BorderShape {
    var borderRect = rect
    if shrinkForBleedAvoidance && bleedAvoidance == .BackgroundBleedShrinkBackground {
      // Ideally we'd use the border rect, but add a device pixel of additional inset to preserve corner shape.
      borderRect = shrinkRectByOneDevicePixel(
        context: paintInfo.context(), rect: borderRect, devicePixelRatio: deviceScaleFactor)
    }

    return BorderShape.shapeForBorderRect(
      style: style, borderRect: borderRect, includeLogicalLeftEdge: includeLeftEdge,
      includeLogicalRightEdge: includeRightEdge)
  }

  func paintBoxShadow(
    paintRect: LayoutRectWrapper, style: RenderStyleWrapper, shadowStyle: ShadowStyle,
    includeLogicalLeftEdge: Bool = true, includeLogicalRightEdge: Bool = true
  ) {
    // FIXME: Deal with border-image. Would be great to use border-image as a mask.
    let context = paintInfo.context()
    if context.paintingDisabled() || style.boxShadow() == nil {
      return
    }

    let borderShape = BorderShape.shapeForBorderRect(
      style: style, borderRect: paintRect, includeLogicalLeftEdge: includeLogicalLeftEdge,
      includeLogicalRightEdge: includeLogicalRightEdge)

    let hasBorderRadius = style.hasBorderRadius()
    let deviceScaleFactor = document().deviceScaleFactor()

    let hasOpaqueBackground = style.visitedDependentColorWithColorFilter(
      colorProperty: .CSSPropertyBackgroundColor
    ).isOpaque()
    var shadow = style.boxShadow()
    while shadow != nil {
      if shadow!.style != shadowStyle {
        shadow = shadow!.next
        continue
      }

      var shadowOffset = LayoutSizeWrapper(width: shadow!.x().value(), height: shadow!.y().value())
      let shadowPaintingExtent = shadow!.paintingExtent()
      let shadowSpread = LayoutUnit(value: shadow!.spread.value())
      let shadowRadius = shadow!.radius.value()

      if shadowOffset.isZero() && shadowRadius == 0 && !shadowSpread.bool() {
        shadow = shadow!.next
        continue
      }

      let shadowColor = style.colorWithColorFilter(color: shadow!.color)

      if shadow!.style == .Normal {
        var shadowShape = borderShape
        shadowShape.inflate(amount: shadowSpread)
        if shadowShape.isEmpty() {
          shadow = shadow!.next
          continue
        }

        // If the box is opaque, it is unnecessary to clip it out. However, doing so saves time
        // when painting the shadow. On the other hand, it introduces subpixel gaps along the
        // corners. Those are avoided by insetting the clipping path by one pixel.
        var adjustedBorderShape = borderShape
        if BackgroundPainter.shouldInflateBorderRect(
          hasOpaqueBackground: hasOpaqueBackground, context: context)
        {
          adjustedBorderShape.inflate(amount: -LayoutUnit(value: UInt64(1)))
        }

        var shadowRect = paintRect
        shadowRect.inflate(d: shadowPaintingExtent + shadowSpread)
        shadowRect.move(size: shadowOffset)
        let pixelSnappedShadowRect = snapRectToDevicePixels(
          rect: shadowRect, pixelSnappingFactor: deviceScaleFactor)

        let _ = GraphicsContextStateSaver(context: context)
        context.clip(rect: pixelSnappedShadowRect)

        // Move the fill just outside the clip, adding at least 1 pixel of separation so that the fill does not
        // bleed in (due to antialiasing) if the context is transformed.
        let xOffset =
          paintRect.width() + max(LayoutUnit(value: 0), shadowOffset.width()) + shadowPaintingExtent
          + 2 * shadowSpread
          + LayoutUnit(value: 1)
        let extraOffset = LayoutSizeWrapper(width: xOffset.ceil(), height: 0)
        shadowOffset -= extraOffset
        shadowShape.move(offset: extraOffset)

        let pixelSnappedFillRect = shadowShape.snappedOuterRect(
          deviceScaleFactor: deviceScaleFactor)

        let shadowRectOrigin = shadowShape.borderRect().location() + shadowOffset
        let snappedShadowOrigin = FloatPoint(
          x: roundToDevicePixel(
            value: shadowRectOrigin.x, pixelSnappingFactor: deviceScaleFactor),
          y: roundToDevicePixel(value: shadowRectOrigin.y, pixelSnappingFactor: deviceScaleFactor)
        )
        let snappedShadowOffset = snappedShadowOrigin - pixelSnappedFillRect.location()

        context.setDropShadow(
          dropShadow: GraphicsDropShadow(
            offset: snappedShadowOffset, radius: shadowRadius, color: shadowColor,
            radiusMode: shadow!.isWebkitBoxShadow ? .Legacy : .Default))

        adjustedBorderShape.clipOutOuterShape(
          context: context, deviceScaleFactor: deviceScaleFactor)

        if hasBorderRadius {
          var influenceShape = BorderShape.shapeForBorderRect(style: style, borderRect: shadowRect)
          let influenceRadii = influenceShape.radii()
          influenceRadii.expand(size: 2 * shadowPaintingExtent + shadowSpread)
          influenceShape.setRadii(radii: influenceRadii)

          if influenceShape.outerShapeContains(rect: paintInfo.rect) {
            context.fillRect(
              rect: shadowShape.snappedOuterRect(deviceScaleFactor: deviceScaleFactor),
              color: ColorWrapper.black)
          } else {
            shadowShape.fillOuterShape(
              context: context, color: ColorWrapper.black, deviceScaleFactor: deviceScaleFactor)
          }
        } else {
          context.fillRect(rect: pixelSnappedFillRect, color: ColorWrapper.black)
        }
      } else {
        // Inset shadow.
        let borderRect = borderShape.deprecatedInnerRoundedRect()
        var holeRect = borderRect.rect
        holeRect.inflate(d: -shadowSpread)

        let isHorizontal = style.isHorizontalWritingMode()
        if !includeLogicalLeftEdge {
          if isHorizontal {
            holeRect.shiftXEdgeBy(
              delta:
                -(max(shadowOffset.width(), LayoutUnit(value: 0)) + shadowPaintingExtent
                + shadowSpread))
          } else {
            holeRect.shiftYEdgeBy(
              delta:
                -(max(shadowOffset.height(), LayoutUnit(value: 0)) + shadowPaintingExtent
                + shadowSpread))
          }
        }

        if !includeLogicalRightEdge {
          if isHorizontal {
            holeRect.setWidth(
              width: holeRect.width() - min(shadowOffset.width(), LayoutUnit(value: 0))
                + shadowPaintingExtent + shadowSpread)
          } else {
            holeRect.setHeight(
              height: holeRect.height() - min(shadowOffset.height(), LayoutUnit(value: 0))
                + shadowPaintingExtent
                + shadowSpread)
          }
        }

        var roundedHoleRect = RoundedRect(rect: holeRect, radii: borderRect.radii)
        if shadowSpread.bool() && roundedHoleRect.isRounded() {
          let roundedRectCorrectingForSpread = BackgroundPainter.roundedRectCorrectingForSpread(
            style: style, paintRect: paintRect, shadowSpread: shadowSpread,
            includeLogicalLeftEdge: includeLogicalLeftEdge,
            includeLogicalRightEdge: includeLogicalRightEdge)
          roundedHoleRect.radii = roundedRectCorrectingForSpread.radii
        }

        let pixelSnappedHoleRect = roundedHoleRect.pixelSnappedRoundedRectForPainting(
          deviceScaleFactor: deviceScaleFactor)
        let pixelSnappedBorderRect = borderRect.pixelSnappedRoundedRectForPainting(
          deviceScaleFactor: deviceScaleFactor)
        if pixelSnappedHoleRect.isEmpty() {
          if hasBorderRadius {
            context.fillRoundedRect(rect: pixelSnappedBorderRect, color: shadowColor)
          } else {
            context.fillRect(rect: pixelSnappedBorderRect.rect, color: shadowColor)
          }
          shadow = shadow!.next
          continue
        }

        let fillColor = shadowColor.opaqueColor()
        let shadowCastingRect = areaCastingShadowInHole(
          holeRect: borderRect.rect, shadowExtent: shadowPaintingExtent, shadowSpread: shadowSpread,
          shadowOffset: shadowOffset)
        let pixelSnappedOuterRect = snapRectToDevicePixels(
          rect: shadowCastingRect, pixelSnappingFactor: deviceScaleFactor)

        let _ = GraphicsContextStateSaver(context: context)
        if hasBorderRadius {
          context.clipRoundedRect(rect: pixelSnappedBorderRect)
        } else {
          context.clip(rect: pixelSnappedBorderRect.rect)
        }

        let xOffset =
          2 * paintRect.width() + max(LayoutUnit(value: 0), shadowOffset.width())
          + shadowPaintingExtent - 2 * shadowSpread + LayoutUnit(value: 1)
        let extraOffset = LayoutSizeWrapper(width: xOffset.ceil(), height: 0)

        context.translate(size: extraOffset.FloatSize())
        shadowOffset -= extraOffset

        let snappedShadowOffset = roundSizeToDevicePixels(
          size: shadowOffset, pixelSnappingFactor: deviceScaleFactor)
        context.setDropShadow(
          dropShadow: GraphicsDropShadow(
            offset: snappedShadowOffset, radius: shadowRadius, color: shadowColor,
            radiusMode: shadow!.isWebkitBoxShadow ? .Legacy : .Default))
        context.fillRectWithRoundedHole(
          rect: pixelSnappedOuterRect, roundedHoleRect: pixelSnappedHoleRect, color: fillColor)
      }

      shadow = shadow!.next
    }
  }

  private static func shouldInflateBorderRect(
    hasOpaqueBackground: Bool, context: GraphicsContextWrapper
  ) -> Bool {
    if !hasOpaqueBackground {
      return false
    }

    // FIXME: The function to decide on the policy based on the transform should be a named function.
    // FIXME: It's not clear if this check is right. What about integral scale factors?
    let transform = context.getCTM()
    if transform.a() != 1 || (transform.d() != 1 && transform.d() != -1) || transform.b() != 0
      || transform.c() != 0
    {
      return true
    }
    return false
  }

  private static func roundedRectCorrectingForSpread(
    style: RenderStyleWrapper, paintRect: LayoutRectWrapper, shadowSpread: LayoutUnit,
    includeLogicalLeftEdge: Bool,
    includeLogicalRightEdge: Bool
  ) -> RoundedRect {
    let horizontal = style.isHorizontalWritingMode()
    let leftWidth = LayoutUnit(
      value: (!horizontal || includeLogicalLeftEdge) ? style.borderLeftWidth() + shadowSpread : 0)
    let rightWidth = LayoutUnit(
      value: (!horizontal || includeLogicalRightEdge) ? style.borderRightWidth() + shadowSpread : 0)
    let topWidth = LayoutUnit(
      value: (horizontal || includeLogicalLeftEdge) ? style.borderTopWidth() + shadowSpread : 0)
    let bottomWidth = LayoutUnit(
      value: (horizontal || includeLogicalRightEdge) ? style.borderBottomWidth() + shadowSpread : 0)

    return style.getRoundedInnerBorderFor(
      borderRect: paintRect, topWidth: topWidth, bottomWidth: bottomWidth, leftWidth: leftWidth,
      rightWidth: rightWidth, includeLogicalLeftEdge: includeLogicalLeftEdge,
      includeLogicalRightEdge: includeLogicalRightEdge)
  }

  static func paintsOwnBackground(renderer: RenderBoxModelObjectWrapper) -> Bool {
    if !renderer.isBody() {
      return true
    }
    if renderer.shouldApplyAnyContainment() {
      return true
    }
    // The <body> only paints its background if the root element has defined a background independent of the body,
    // or if the <body>'s parent is not the document element's renderer (e.g. inside SVG foreignObject).
    let documentElementRenderer = renderer.document().documentElement()!.containerRenderer()
    return documentElementRenderer == nil || documentElementRenderer!.shouldApplyAnyContainment()
      || documentElementRenderer!.hasBackground()
      || CPtrToInt(documentElementRenderer!.id()) != CPtrToInt(renderer.parent()?.id())
  }

  static func calculateBackgroundImageGeometry(
    renderer: RenderBoxModelObjectWrapper, paintContainer: RenderLayerModelObjectWrapper?,
    fillLayer: FillLayerWrapper, paintOffset: LayoutPointWrapper, borderBoxRect: LayoutRectWrapper,
    overrideOrigin: FillBox? = nil
  )
    -> BackgroundImageGeometry
  {
    let view = renderer.view()

    var left = LayoutUnit()
    var top = LayoutUnit()
    var positioningAreaSize = LayoutSizeWrapper()
    // Determine the background positioning area and set destination rect to the background painting area.
    // Destination rect will be adjusted later if the background is non-repeating.
    let enclosingLayer = renderer.enclosingLayer()
    let isTransformed =
      renderer.isTransformed()
      || (enclosingLayer != nil && enclosingLayer!.hasTransformedAncestor())
    let fixedAttachment = fillLayer.attachment == .FixedBackground && !isTransformed

    var destinationRect = borderBoxRect
    let deviceScaleFactor = renderer.document().deviceScaleFactor()
    if !fixedAttachment {
      var right = LayoutUnit()
      var bottom = LayoutUnit()
      // Scroll and Local.
      let fillLayerOrigin = overrideOrigin ?? fillLayer.origin
      if fillLayerOrigin != .BorderBox {
        left = renderer.borderLeft()
        right = renderer.borderRight()
        top = renderer.borderTop()
        bottom = renderer.borderBottom()
        if fillLayerOrigin == .ContentBox {
          left += renderer.paddingLeft()
          right += renderer.paddingRight()
          top += renderer.paddingTop()
          bottom += renderer.paddingBottom()
        }
      }

      // The background of the box generated by the root element covers the entire canvas including
      // its margins. Since those were added in already, we have to factor them out when computing
      // the background positioning area.
      if renderer.isDocumentElementRenderer() {
        positioningAreaSize =
          (renderer as! RenderBoxWrapper).size()
          - LayoutSizeWrapper(width: left + right, height: top + bottom)
        positioningAreaSize = LayoutSizeWrapper(
          size: snapSizeToDevicePixel(
            size: positioningAreaSize, location: LayoutPointWrapper(),
            pixelSnappingFactor: deviceScaleFactor))
        if view.frameView().hasExtendedBackgroundRectForPainting() {
          let extendedBackgroundRect = LayoutRectWrapper(
            rect: view.frameView().extendedBackgroundRectForPainting())
          left += (renderer.marginLeft() - extendedBackgroundRect.x())
          top += (renderer.marginTop() - extendedBackgroundRect.y())
        }
      } else {
        positioningAreaSize =
          borderBoxRect.size() - LayoutSizeWrapper(width: left + right, height: top + bottom)
        positioningAreaSize = LayoutSizeWrapper(
          size: snapRectToDevicePixels(
            rect: LayoutRectWrapper(location: paintOffset, size: positioningAreaSize),
            pixelSnappingFactor: deviceScaleFactor
          )
          .size())
      }
    } else {
      var viewportRect = LayoutRectWrapper()
      var topContentInset: Float32 = 0
      if renderer.settings().fixedBackgroundsPaintRelativeToDocument() {
        viewportRect = LayoutRectWrapper(rect: view.unscaledDocumentRect())
      } else {
        let frameView = view.frameView()
        let useFixedLayout = frameView.useFixedLayout() && !frameView.fixedLayoutSize().isEmpty()

        if useFixedLayout {
          // Use the fixedLayoutSize() when useFixedLayout() because the rendering will scale
          // down the frameView to to fit in the current viewport.
          viewportRect.setSize(size: LayoutSizeWrapper(size: frameView.fixedLayoutSize()))
        } else {
          viewportRect.setSize(size: LayoutSizeWrapper(size: frameView.sizeForVisibleContent()))
        }

        if renderer.fixedBackgroundPaintsInLocalCoordinates() {
          if !useFixedLayout {
            // Shifting location up by topContentInset is needed for layout tests which expect
            // layout to be shifted down when calling window.internals.setTopContentInset().
            topContentInset = frameView.topContentInset(
              contentInsetTypeToReturn: .WebCoreOrPlatformContentInset)
            viewportRect.setLocation(location: LayoutPointWrapper(x: 0, y: -topContentInset))
          }
        } else if useFixedLayout || frameView.frameScaleFactor() != 1 {
          // scrollPositionForFixedPosition() is adjusted for page scale and it does not include
          // topContentInset so do not add it to the calculation below.
          viewportRect.setLocation(location: frameView.scrollPositionForFixedPosition())
        } else {
          // documentScrollPositionRelativeToViewOrigin() includes -topContentInset in its height
          // so we need to account for that in calculating the phase size
          topContentInset = frameView.topContentInset(
            contentInsetTypeToReturn: .WebCoreOrPlatformContentInset)
          viewportRect.setLocation(
            location: LayoutPointWrapper(
              point: frameView.documentScrollPositionRelativeToViewOrigin()))
        }

        top += topContentInset
      }

      if let paintContainer = paintContainer {
        viewportRect.moveBy(
          offset: LayoutPointWrapper(
            size: -paintContainer.localToAbsolute(localPoint: FloatPoint()))
        )
      }

      destinationRect = viewportRect
      positioningAreaSize = destinationRect.size()
      positioningAreaSize.setHeight(height: positioningAreaSize.height() - topContentInset)
      positioningAreaSize = LayoutSizeWrapper(
        size: snapRectToDevicePixels(
          rect: LayoutRectWrapper(location: destinationRect.location(), size: positioningAreaSize),
          pixelSnappingFactor: deviceScaleFactor
        ).size())
    }

    var tileSize = calculateFillTileSize(
      renderer: renderer, fillLayer: fillLayer, positioningAreaSize: positioningAreaSize)

    var backgroundRepeatX = fillLayer.repeat.x
    var backgroundRepeatY = fillLayer.repeat.y
    let availableWidth = positioningAreaSize.width() - tileSize.width()
    let availableHeight = positioningAreaSize.height() - tileSize.height()

    var spaceSize = LayoutSizeWrapper()
    var phase = LayoutSizeWrapper()
    var computedXPosition = resolveEdgeRelativeLength(
      length: fillLayer.xPosition, edge: fillLayer.backgroundXOrigin,
      availableSpace: availableWidth, areaSize: positioningAreaSize,
      tileSize: tileSize)
    if backgroundRepeatX == .Round && positioningAreaSize.width() > 0 && tileSize.width() > 0 {
      let numTiles = max(1, roundToInt(value: positioningAreaSize.width() / tileSize.width()))
      if fillLayer.size().size.height.isAuto() && backgroundRepeatY != .Round {
        tileSize.setHeight(
          height: tileSize.height() * positioningAreaSize.width() / (numTiles * tileSize.width()))
      }

      tileSize.setWidth(width: positioningAreaSize.width() / numTiles)
      phase.setWidth(
        width: tileSize.width().bool()
          ? tileSize.width() - fmodf((computedXPosition + left).float(), tileSize.width().float())
          : 0)
    }

    var computedYPosition = resolveEdgeRelativeLength(
      length: fillLayer.yPosition, edge: fillLayer.backgroundYOrigin,
      availableSpace: availableHeight, areaSize: positioningAreaSize,
      tileSize: tileSize)
    if backgroundRepeatY == .Round && positioningAreaSize.height() > 0 && tileSize.height() > 0 {
      let numTiles = max(1, roundToInt(value: positioningAreaSize.height() / tileSize.height()))
      if fillLayer.size().size.width.isAuto() && backgroundRepeatX != .Round {
        tileSize.setWidth(
          width: tileSize.width() * positioningAreaSize.height() / (numTiles * tileSize.height()))
      }

      tileSize.setHeight(height: positioningAreaSize.height() / numTiles)
      phase.setHeight(
        height: tileSize.height().bool()
          ? tileSize.height() - fmodf((computedYPosition + top).float(), tileSize.height().float())
          : 0)
    }

    if backgroundRepeatX == .Repeat {
      phase.setWidth(
        width: tileSize.width().bool()
          ? tileSize.width()
            - fmodf((computedXPosition + left).float(), tileSize.width().float()) : 0)
      spaceSize.setWidth(width: Int32(0))
    } else if backgroundRepeatX == .Space && tileSize.width() > 0 {
      if let space = getSpace(areaSize: positioningAreaSize.width(), tileSize: tileSize.width()) {
        let actualWidth = tileSize.width() + space
        computedXPosition = minimumValueForLength(
          length: LengthWrapper(), maximumValue: availableWidth)
        spaceSize.setWidth(width: space)
        spaceSize.setHeight(height: 0)
        phase.setWidth(
          width: actualWidth.bool()
            ? actualWidth - fmodf((computedXPosition + left).float(), actualWidth.float()) : 0)
      } else {
        backgroundRepeatX = .NoRepeat
      }
    }

    if backgroundRepeatX == .NoRepeat {
      var xOffset = left + computedXPosition
      if xOffset > 0 {
        destinationRect.move(dx: xOffset, dy: LayoutUnit(value: 0))
      }
      xOffset = min(xOffset, LayoutUnit(value: 0))
      phase.setWidth(width: -xOffset)
      destinationRect.setWidth(width: tileSize.width() + xOffset)
      spaceSize.setWidth(width: Int32(0))
    }

    if backgroundRepeatY == .Repeat {
      phase.setHeight(
        height: tileSize.height().bool()
          ? tileSize.height() - fmodf((computedYPosition + top).float(), tileSize.height().float())
          : 0)
      spaceSize.setHeight(height: 0)
    } else if backgroundRepeatY == .Space && tileSize.height() > 0 {
      if let space = getSpace(areaSize: positioningAreaSize.height(), tileSize: tileSize.height()) {
        let actualHeight = tileSize.height() + space
        computedYPosition = minimumValueForLength(
          length: LengthWrapper(), maximumValue: availableHeight)
        spaceSize.setHeight(height: space)
        phase.setHeight(
          height: actualHeight.bool()
            ? actualHeight - fmodf((computedYPosition + top).float(), actualHeight.float()) : 0)
      } else {
        backgroundRepeatY = .NoRepeat
      }
    }
    if backgroundRepeatY == .NoRepeat {
      var yOffset = top + computedYPosition
      if yOffset > 0 {
        destinationRect.move(dx: LayoutUnit(value: 0), dy: yOffset)
      }
      yOffset = min(yOffset, LayoutUnit(value: 0))
      phase.setHeight(height: -yOffset)
      destinationRect.setHeight(height: tileSize.height() + yOffset)
      spaceSize.setHeight(height: 0)
    }

    if fixedAttachment {
      let attachmentPoint = borderBoxRect.location()
      phase.expand(
        width: max(attachmentPoint.x - destinationRect.x(), LayoutUnit(value: 0)),
        height: max(attachmentPoint.y - destinationRect.y(), LayoutUnit(value: 0)))
    }

    destinationRect.intersect(other: borderBoxRect)

    let tileSizeWithoutPixelSnapping = tileSize.deepCopy()
    pixelSnapBackgroundImageGeometryForPainting(
      destinationRect: &destinationRect, tileSize: &tileSize, phase: &phase, space: &spaceSize,
      scaleFactor: deviceScaleFactor)

    return BackgroundImageGeometry(
      destinationRect: destinationRect, tileSizeWithoutPixelSnapping: tileSizeWithoutPixelSnapping,
      tileSize: tileSize, phase: phase, spaceSize: spaceSize, fixedAttachment: fixedAttachment)
  }

  static func boxShadowShouldBeAppliedToBackground(
    renderer: RenderBoxModelObjectWrapper, paintOffset: LayoutPointWrapper,
    bleedAvoidance: BackgroundBleedAvoidance, inlineBox: InlineIterator.InlineBoxIterator
  ) -> Bool {
    if bleedAvoidance != .BackgroundBleedNone {
      return false
    }

    let style = renderer.style()

    if style.hasUsedAppearance() {
      return false
    }

    var hasOneNormalBoxShadow = false
    var currentShadow = style.boxShadow()
    while currentShadow != nil {
      if currentShadow!.style != .Normal {
        continue
      }

      if hasOneNormalBoxShadow {
        return false
      }
      hasOneNormalBoxShadow = true

      if !currentShadow!.spread.isZero() {
        return false
      }
      currentShadow = currentShadow!.next
    }

    if !hasOneNormalBoxShadow {
      return false
    }

    let backgroundColor = style.visitedDependentColorWithColorFilter(
      colorProperty: .CSSPropertyBackgroundColor)
    if !backgroundColor.isOpaque() {
      return false
    }

    var lastBackgroundLayer = style.backgroundLayers()
    var next = lastBackgroundLayer.next()
    while next != nil {
      lastBackgroundLayer = next!
      next = lastBackgroundLayer.next()
    }

    if lastBackgroundLayer.clip != .BorderBox {
      return false
    }

    if lastBackgroundLayer.image() != nil && style.hasBorderRadius() {
      return false
    }

    if inlineBox.bool()
      && !BackgroundPainter.applyToInlineBox(
        inlineBox: inlineBox, lastBackgroundLayer: lastBackgroundLayer)
    {
      return false
    }

    if renderer.hasNonVisibleOverflow() && lastBackgroundLayer.attachment == .LocalBackground {
      return false
    }

    if renderer is RenderTableCellWrapper {
      return false
    }

    if let imageRenderer = renderer as? RenderImageWrapper {
      return !imageRenderer.backgroundIsKnownToBeObscured(paintOffset: paintOffset)
    }

    return true
  }

  private static func applyToInlineBox(
    inlineBox: InlineIterator.InlineBoxIterator, lastBackgroundLayer: FillLayerWrapper
  ) -> Bool {
    // The checks here match how paintFillLayer() decides whether to clip (if it does, the shadow
    // would be clipped out, so it has to be drawn separately).
    if inlineBox.get().isRootInlineBox() {
      return true
    }
    if !inlineBox.get().previousInlineBox().bool() && !inlineBox.get().nextInlineBox().bool() {
      return true
    }
    let image = lastBackgroundLayer.image()
    let renderer = inlineBox.get().renderer()
    let hasFillImage =
      image != nil && image!.canRender(renderer: renderer, multiplier: renderer.style().usedZoom())
    return !hasFillImage && !renderer.style().hasBorderRadius()
  }

  private func paintRootBoxFillLayers() {
    assert(renderer.isDocumentElementRenderer())
    if paintInfo.skipRootBackground() {
      return
    }

    let rootBackgroundRenderer = view().rendererForRootBackground()
    if rootBackgroundRenderer == nil {
      return
    }

    let style = rootBackgroundRenderer!.style()
    let backgroundColor = style.visitedDependentColorWithColorFilter(
      colorProperty: .CSSPropertyBackgroundColor)
    let compositeOp = document().compositeOperatorForBackgroundColor(
      color: backgroundColor, renderer: renderer)

    paintFillLayers(
      color: backgroundColor, fillLayer: style.backgroundLayers(), rect: view().backgroundRect(),
      bleedAvoidance: .BackgroundBleedNone, op: compositeOp,
      backgroundObject: rootBackgroundRenderer)
  }

  private static func calculateFillTileSize(
    renderer: RenderBoxModelObjectWrapper, fillLayer: FillLayerWrapper,
    positioningAreaSize: LayoutSizeWrapper
  ) -> LayoutSizeWrapper {
    let image = fillLayer.image()
    var type = fillLayer.size().type
    let devicePixelSize = LayoutUnit(value: 1.0 / renderer.document().deviceScaleFactor())

    var imageIntrinsicSize = LayoutSizeWrapper()
    if let image = image {
      imageIntrinsicSize = renderer.calculateImageIntrinsicDimensions(
        image: image, positioningAreaSize: positioningAreaSize, scaleByUsedZoom: .Yes)
      imageIntrinsicSize.scale(
        widthScale: 1 / image.imageScaleFactor(), heightScale: 1 / image.imageScaleFactor())
    } else {
      imageIntrinsicSize = positioningAreaSize
    }

    switch type {
    case .Size:
      var tileSize = positioningAreaSize.deepCopy()

      let layerWidth = fillLayer.size().size.width
      let layerHeight = fillLayer.size().size.height

      if layerWidth.isFixed() {
        tileSize.setWidth(width: layerWidth.value())
      } else if layerWidth.isPercentOrCalculated() {
        let resolvedWidth = valueForLength(
          length: layerWidth, maximumValue: positioningAreaSize.width())
        // Non-zero resolved value should always produce some content.
        tileSize.setWidth(
          width: !resolvedWidth.bool() ? resolvedWidth : max(devicePixelSize, resolvedWidth))
      }

      if layerHeight.isFixed() {
        tileSize.setHeight(height: layerHeight.value())
      } else if layerHeight.isPercentOrCalculated() {
        let resolvedHeight = valueForLength(
          length: layerHeight, maximumValue: positioningAreaSize.height())
        // Non-zero resolved value should always produce some content.
        tileSize.setHeight(
          height: !resolvedHeight.bool() ? resolvedHeight : max(devicePixelSize, resolvedHeight))
      }

      // If one of the values is auto we have to use the appropriate
      // scale to maintain our aspect ratio.
      let hasNaturalAspectRatio = image != nil && image!.imageHasNaturalDimensions()
      if layerWidth.isAuto() && !layerHeight.isAuto() {
        if hasNaturalAspectRatio && imageIntrinsicSize.height().bool() {
          tileSize.setWidth(
            width:
              imageIntrinsicSize.width() * tileSize.height() / imageIntrinsicSize.height())
        }
      } else if !layerWidth.isAuto() && layerHeight.isAuto() {
        if hasNaturalAspectRatio && imageIntrinsicSize.width().bool() {
          tileSize.setHeight(
            height:
              imageIntrinsicSize.height() * tileSize.width() / imageIntrinsicSize.width())
        }
      } else if layerWidth.isAuto() && layerHeight.isAuto() {
        // If both width and height are auto, use the image's intrinsic size.
        tileSize = imageIntrinsicSize
      }

      tileSize.clampNegativeToZero()
      return tileSize
    case .None:
      // If both values are ‘auto’ then the intrinsic width and/or height of the image should be used, if any.
      if !imageIntrinsicSize.isEmpty() {
        return imageIntrinsicSize
      }

      // If the image has neither an intrinsic width nor an intrinsic height, its size is determined as for ‘contain’.
      type = .Contain
      fallthrough
    case .Contain, .Cover:
      // Scale computation needs higher precision than what LayoutUnit can offer.
      let localImageIntrinsicSize = imageIntrinsicSize.FloatSize()
      let localPositioningAreaSize = positioningAreaSize.FloatSize()

      let horizontalScaleFactor =
        localImageIntrinsicSize.width != 0
        ? (localPositioningAreaSize.width / localImageIntrinsicSize.width) : 1
      let verticalScaleFactor =
        localImageIntrinsicSize.height != 0
        ? (localPositioningAreaSize.height / localImageIntrinsicSize.height) : 1
      let scaleFactor =
        type == .Contain
        ? min(horizontalScaleFactor, verticalScaleFactor)
        : max(horizontalScaleFactor, verticalScaleFactor)

      if localImageIntrinsicSize.isEmpty() {
        return LayoutSizeWrapper()
      }

      return LayoutSizeWrapper(
        size: localImageIntrinsicSize.scaled(s: scaleFactor).expandedTo(
          other: FloatSize(width: devicePixelSize.float(), height: devicePixelSize.float())))
    }
  }

  private func document() -> Document {
    return renderer.document()
  }

  private func view() -> RenderViewWrapper {
    return renderer.view()
  }

  private let renderer: RenderBoxModelObjectWrapper
  private let paintInfo: PaintInfoWrapper
  private var overrideClip: FillBox?
  private var overrideOrigin: FillBox? = nil
}
