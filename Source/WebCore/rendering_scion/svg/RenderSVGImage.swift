/*
 * Copyright (C) 2006 Alexander Kellett <lypanov@kde.org>
 * Copyright (C) 2006, 2009 Apple Inc.
 * Copyright (C) 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2007, 2008, 2009 Rob Buis <buis@kde.org>
 * Copyright (C) 2009 Google, Inc.
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) 2010 Patrick Gansterer <paroga@paroga.com>
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

final class RenderSVGImageWrapper: RenderSVGModelObjectWrapper {
  func protectedImageElement() -> SVGImageElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  private func updateImageViewport() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func objectBoundingBox() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func repaintRectInLocalCoordinates(
    _ repaintRectCalculation: RepaintRectCalculation = .Fast
  ) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): add stack stats

    let repainter = LayoutRepainter(renderer: self)

    updateImageViewport()
    setCurrentSVGLayoutRect(enclosingLayoutRect(rect: m_objectBoundingBox))

    updateLayerTransform()

    repainter.repaintAfterLayout()
    clearNeedsLayout()
  }

  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    let relevantPaintPhases: PaintPhase = [
      .Foreground, .ClippingMask, .Mask, .Outline, .SelfOutline,
    ]
    if !shouldPaintSVGRenderer(paintInfo, relevantPaintPhases)
      || imageResource!.cachedImage() == nil
    {
      return
    }

    if paintInfo.phase == .ClippingMask {
      paintSVGClippingMask(paintInfo: paintInfo, objectBoundingBox: objectBoundingBox())
      return
    }

    let adjustedPaintOffset = paintOffset + currentSVGLayoutLocation()
    if paintInfo.phase == .Mask {
      paintSVGMask(paintInfo, adjustedPaintOffset)
      return
    }

    var visualOverflowRect = visualOverflowRectEquivalent()
    visualOverflowRect.moveBy(offset: adjustedPaintOffset)
    if !visualOverflowRect.intersects(other: paintInfo.rect) {
      return
    }

    if paintInfo.phase == .Outline || paintInfo.phase == .SelfOutline {
      paintSVGOutline(paintInfo, adjustedPaintOffset)
      return
    }

    assert(paintInfo.phase == .Foreground)
    let _ = GraphicsContextStateSaver(context: paintInfo.context())

    let coordinateSystemOriginTranslation =
      adjustedPaintOffset - flooredLayoutPoint(p: objectBoundingBox().location())
    paintInfo.context().translate(
      x: coordinateSystemOriginTranslation.width().float(),
      y: coordinateSystemOriginTranslation.height().float())

    if style().svgStyle().bufferedRendering() == .Static
      && bufferForeground(paintInfo, flooredLayoutPoint(p: objectBoundingBox().location()))
    {
      return
    }

    paintForeground(paintInfo, flooredLayoutPoint(p: objectBoundingBox().location()))
  }

  private func paintForeground(_ paintInfo: PaintInfoWrapper, _ paintOffset: LayoutPointWrapper) {
    let context = paintInfo.context()
    if context.invalidatingImagesWithAsyncDecodes() {
      if cachedImage()?.isClientWaitingForAsyncDecoding(client: self) ?? false {
        cachedImage()!.removeAllClientsWaitingForAsyncDecoding()
      }
      return
    }

    if imageResource!.cachedImage() == nil {
      page().addRelevantUnpaintedObject(
        object: self, objectPaintRect: visualOverflowRectEquivalent())
      return
    }

    let image = imageResource!.image()
    if image?.isNull() ?? true {
      page().addRelevantUnpaintedObject(
        object: self, objectPaintRect: visualOverflowRectEquivalent())
      return
    }

    var contentBoxRect = borderBoxRectEquivalent().FloatRect()
    var replacedContentRect = FloatRectWrapper(
      x: 0, y: 0, width: image!.width(), height: image!.height())
    protectedImageElement().preserveAspectRatio().transformRect(
      destRect: &contentBoxRect, srcRect: &replacedContentRect)

    contentBoxRect.moveBy(delta: paintOffset.FloatPoint())

    let result = paintIntoRect(paintInfo, contentBoxRect, sourceRect: replacedContentRect)

    if cachedImage() != nil {
      // For now, count images as unpainted if they are still progressively loading. We may want
      // to refine this in the future to account for the portion of the image that has painted.
      let visibleRect = intersection(replacedContentRect, contentBoxRect)
      if cachedImage()!.isLoading() || result == .DidRequestDecoding {
        page().addRelevantUnpaintedObject(
          object: self, objectPaintRect: enclosingLayoutRect(rect: visibleRect))
      } else {
        page().addRelevantRepaintedObject(
          object: self, objectPaintRect: enclosingLayoutRect(rect: visibleRect))
      }
    }
  }

  private func paintIntoRect(
    _ paintInfo: PaintInfoWrapper, _ rect: FloatRectWrapper, sourceRect: FloatRectWrapper
  ) -> ImageDrawResult {
    if imageResource!.cachedImage() == nil || rect.width() <= 0 || rect.height() <= 0 {
      return .DidNothing
    }

    let image = imageResource!.image()
    if image == nil || image!.isNull() {
      return .DidNothing
    }

    let options = ImagePaintingOptionsWrapper(
      compositeOperator: .SourceOver,
      decodingMode: .Synchronous,
      orientation: imageOrientation(),
      interpolationQuality: .Default,
      allowImageSubsampling: settings().imageSubsamplingEnabled() ? .Yes : .No,
      showDebugBackground: settings().showDebugBorders() ? .Yes : .No
    )

    let drawResult = paintInfo.context().drawImage(image!, rect, sourceRect, options)
    if drawResult == .DidRequestDecoding {
      imageResource!.cachedImage()!.addClientWaitingForAsyncDecoding(client: self)
    }

    return drawResult
  }

  private func bufferForeground(_ paintInfo: PaintInfoWrapper, _ paintOffset: LayoutPointWrapper)
    -> Bool
  {
    let destinationContext = paintInfo.context()

    var repaintBoundingBox = borderBoxRectEquivalent()
    repaintBoundingBox.moveBy(offset: paintOffset)

    // Invalidate an existing buffer if the scale is not correct.
    let absoluteTransform = destinationContext.getCTM(includeScale: .DefinitelyIncludeDeviceScale)

    let absoluteTargetRect = enclosingIntRect(
      rect: absoluteTransform.mapRect(rect: repaintBoundingBox.FloatRect()))
    if bufferedForeground != nil {
      if absoluteTargetRect.size != bufferedForeground!.backendSize() {
        bufferedForeground = nil
      } else {
        let absoluteTransformBuffer = bufferedForeground!.context().getCTM(
          includeScale: .DefinitelyIncludeDeviceScale)
        if absoluteTransformBuffer != absoluteTransform {
          bufferedForeground = nil
        }
      }
    }

    // Create a new buffer and paint the foreground into it.
    if bufferedForeground == nil {
      bufferedForeground = destinationContext.createAlignedImageBuffer(
        FloatSize(size: expandedIntSize(repaintBoundingBox.size().FloatSize())))
      if bufferedForeground == nil {
        return false
      }
    }

    let bufferedContext = bufferedForeground!.context()
    bufferedContext.clearRect(rect: FloatRectWrapper(r: absoluteTargetRect))

    let bufferedInfo = paintInfo.deepCopy()
    bufferedInfo.setContext(bufferedContext)
    paintForeground(bufferedInfo, paintOffset)

    destinationContext.concatCTM(transform: absoluteTransform.inverse() ?? AffineTransform())
    destinationContext.drawImageBuffer(bufferedForeground!, FloatRectWrapper(r: absoluteTargetRect))
    destinationContext.concatCTM(transform: absoluteTransform)

    return true
  }

  private func cachedImage() -> CachedImageWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let m_objectBoundingBox = FloatRectWrapper()
  private let imageResource: RenderImageResource? = nil
  private var bufferedForeground: ImageBufferWrapper? = nil
}
