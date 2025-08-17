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

private func areaCastingShadowInHole(
  holeRect: LayoutRectWrapper, shadowExtent: LayoutUnit, shadowSpread: LayoutUnit,
  shadowOffset: LayoutSizeWrapper
) -> LayoutRectWrapper {
  var bounds = holeRect

  bounds.inflate(d: shadowExtent)

  if shadowSpread < 0 {
    bounds.inflate(d: -shadowSpread)
  }

  var offsetBounds = bounds
  offsetBounds.move(size: -shadowOffset)
  return unionRect(a: bounds, b: offsetBounds)
}

struct BackgroundImageGeometry {
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
            context.fillRect(rect: pixelSnappedBorderRect.rect(), color: shadowColor)
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
          context.clip(rect: pixelSnappedBorderRect.rect())
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

  static func calculateBackgroundImageGeometry(
    renderer: RenderBoxModelObjectWrapper, paintContainer: RenderLayerModelObjectWrapper?,
    fillLayer: FillLayerWrapper, paintOffset: LayoutPointWrapper, borderBoxRect: LayoutRectWrapper,
    overrideOrigin: FillBox? = nil
  )
    -> BackgroundImageGeometry
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func document() -> Document {
    return renderer.document()
  }

  private func view() -> RenderViewWrapper {
    return renderer.view()
  }

  private let renderer: RenderBoxModelObjectWrapper
  private let paintInfo: PaintInfoWrapper
  private var overrideClip: FillBox?
  private let overrideOrigin: FillBox? = nil
}
