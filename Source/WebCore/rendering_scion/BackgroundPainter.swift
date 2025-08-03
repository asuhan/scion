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
      BackgroundPainter.setupMaskingBackgroundClip(
        borderRect: rect,
        paintFunction: {
          _, paintRect in
          renderer.paintMaskForTextFillBox(
            context: context, paintRect: paintRect, inlineBox: inlineBoxIterator,
            scrolledPaintRect: scrolledPaintRect)
        }, backgroundClipOuterLayerScope: backgroundClipOuterLayerScope,
        backgroundClipInnerLayerScope: backgroundClipInnerLayerScope)
    case .BorderArea:
      if let borderAreaPath = BorderPainter.pathForBorderArea(
        rect: rect, style: style, deviceScaleFactor: deviceScaleFactor,
        includeLogicalLeftEdge: includeLeftEdge, includeLogicalRightEdge: includeRightEdge)
      {
        backgroundClipStateSaver.save()
        context.clipPath(path: borderAreaPath)
        break
      }

      BackgroundPainter.setupMaskingBackgroundClip(
        borderRect: rect,
        paintFunction: {
          borderRect, paintRect in
          let borderPaintInfo = PaintInfoWrapper(
            newContext: context, newRect: LayoutRectWrapper(r: paintRect),
            newPhase: .BlockBackground, newPaintBehavior: .ForceBlackBorder)
          let borderPainter = BorderPainter(renderer: renderer, paintInfo: borderPaintInfo)
          borderPainter.paintBorder(rect: borderRect, style: style)
        }, backgroundClipOuterLayerScope: backgroundClipOuterLayerScope,
        backgroundClipInnerLayerScope: backgroundClipInnerLayerScope)
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

  private static func setupMaskingBackgroundClip(
    borderRect: LayoutRectWrapper, paintFunction: (LayoutRectWrapper, FloatRectWrapper) -> Void,
    backgroundClipOuterLayerScope: TransparencyLayerScope,
    backgroundClipInnerLayerScope: TransparencyLayerScope
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func document() -> Document {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func view() -> RenderViewWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let renderer: RenderBoxModelObjectWrapper
  private let paintInfo: PaintInfoWrapper
  private var overrideClip: FillBox?
  private let overrideOrigin: FillBox? = nil
}
