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
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

class BackgroundPainter {
  init(renderer: RenderBoxModelObjectWrapper, paintInfo: PaintInfoWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintFillLayer(
    color: ColorWrapper, bgLayer: FillLayerWrapper, rect: LayoutRectWrapper,
    bleedAvoidance: BackgroundBleedAvoidance, inlineBoxIterator: InlineIterator.InlineBoxIterator,
    backgroundImageStrip: LayoutRectWrapper = LayoutRectWrapper(),
    op: CompositeOperator = .SourceOver,
    backgroundObject: RenderElementWrapper? = nil,
    baseBgColorUsage: BaseBackgroundColorUsage = .BaseBackgroundColorUse
  ) {
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
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      } else {
        context.fillRect(rect: pixelSnappedRect, color: bgColor, op: op)
      }

      return
    }

    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func borderShapeRespectingBleedAvoidance() -> BorderShape {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintBoxShadow(
    paintRect: LayoutRectWrapper, style: RenderStyleWrapper, shadowStyle: ShadowStyle,
    includeLogicalLeftEdge: Bool = true, includeLogicalRightEdge: Bool = true
  ) {
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

  private let renderer: RenderBoxModelObjectWrapper
  private let paintInfo: PaintInfoWrapper
  private let overrideClip: FillBox?
}
