/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2022 Apple Inc. All rights reserved.
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

func rotation(boxRect: FloatRectWrapper, direction: RotationDirection) -> AffineTransform {
  return direction == .Clockwise
    ? AffineTransform(
      a: 0, b: 1, c: -1, d: 0, e: Float64(boxRect.x() + boxRect.maxY()),
      f: Float64(boxRect.maxY() - boxRect.x()))
    : AffineTransform(
      a: 0, b: -1, c: 1, d: 0, e: Float64(boxRect.x() - boxRect.maxY()),
      f: Float64(boxRect.x() + boxRect.maxY()))
}

class ShadowApplier {
  init(
    style: RenderStyleWrapper, context: GraphicsContextWrapper, shadow: ShadowData?,
    colorFilter: FilterOperations?, textRect: FloatRectWrapper,
    lastShadowIterationShouldDrawText: Bool = true, opaque: Bool = false,
    orientation: FontOrientation = .Horizontal
  ) {
    self.context = context
    self.shadow = shadow
    self.onlyDrawsShadow = !isLastShadowIteration() || !lastShadowIterationShouldDrawText
    self.avoidDrawingShadow = shadowIsCompletelyCoveredByText(textIsOpaque: opaque)
    self.nothingToDraw = (shadow != nil) && avoidDrawingShadow && onlyDrawsShadow
    self.didSaveContext = false
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  deinit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isLastShadowIteration() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func shadowIsCompletelyCoveredByText(textIsOpaque: Bool) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let extraOffset = FloatSize()
  let context: GraphicsContextWrapper
  let shadow: ShadowData?
  var onlyDrawsShadow: Bool = false
  var avoidDrawingShadow: Bool = false
  var nothingToDraw: Bool = false
  var didSaveContext: Bool = false
}

struct TextPainter {
  init(context: GraphicsContextWrapper, font: FontCascadeWrapper, renderStyle: RenderStyleWrapper) {
    self.context = context
    self.font = font
    self.renderStyle = renderStyle
  }

  mutating func setStyle(textPaintStyle: TextPaintStyle) { self.style = textPaintStyle }

  mutating func setShadow(shadow: ShadowData) { self.shadow = shadow }

  mutating func setShadowColorFilter(colorFilter: FilterOperations) {
    shadowColorFilter = colorFilter
  }

  mutating func setIsHorizontal(isHorizontal: Bool) { textBoxIsHorizontal = isHorizontal }

  mutating func setEmphasisMark(
    mark: AtomStringWrapper, offset: Float32, combinedText: RenderCombineTextWrapper?
  ) {
    self.emphasisMark = mark
    self.emphasisMarkOffset = offset
    self.combinedText = combinedText
  }

  mutating func paintRange(
    textRun: TextRunWrapper, boxRect: FloatRectWrapper, textOrigin: FloatPoint, start: UInt32,
    end: UInt32
  ) {
    assert(start < end)
    paintTextAndEmphasisMarksIfNeeded(
      textRun: textRun, boxRect: boxRect, textOrigin: textOrigin, startOffset: start,
      endOffset: end, paintStyle: style, shadow: shadow, shadowColorFilter: shadowColorFilter)
  }

  mutating func setGlyphDisplayListIfNeeded<LayoutRun: DisplayTextBox>(
    run: LayoutRun, paintInfo: PaintInfoWrapper, textRun: TextRunWrapper
  ) {
    if !TextPainter.shouldUseGlyphDisplayList(paintInfo: paintInfo) {
      run.removeFromGlyphDisplayListCache()
    } else {
      glyphDisplayList = GlyphDisplayListCache.singleton.get(
        run: run, font: font, context: context, textRun: textRun, paintInfo: paintInfo)
    }
  }

  static func shouldUseGlyphDisplayList(paintInfo: PaintInfoWrapper) -> Bool {
    return !paintInfo.context().paintingDisabled() && paintInfo.enclosingSelfPaintingLayer() != nil
  }

  private mutating func paintTextOrEmphasisMarks(
    font: FontCascadeWrapper, textRun: TextRunWrapper, emphasisMark: AtomStringWrapper,
    emphasisMarkOffset: Float32, textOrigin: FloatPoint, startOffset: UInt32, endOffset: UInt32
  ) {
    assert(startOffset < endOffset)

    if context.detectingContentfulPaint() {
      if !textRun.text().containsOnly(isSpecialCharacter: isASCIIWhitespace) {
        context.setContentfulPaintDetected()
      }
      return
    }

    if !emphasisMark.isEmpty() {
      context.drawEmphasisMarks(
        font: font, run: textRun, mark: emphasisMark,
        point: textOrigin + FloatSize(width: 0, height: emphasisMarkOffset), from: startOffset,
        to: endOffset)
    } else if startOffset != 0 || endOffset < textRun.length() || glyphDisplayList == nil {
      context.drawText(
        font: font, run: textRun, point: textOrigin, from: startOffset, to: endOffset)
    } else {
      // Replaying back a whole cached glyph run to the GraphicsContext.
      context.drawDisplayListItems(
        items: glyphDisplayList!.items(), resourceHeap: glyphDisplayList!.resourceHeap(),
        controlFactory: ControlFactoryWrapper.shared(),
        destination: textOrigin)
    }
    glyphDisplayList = nil
  }

  private mutating func paintTextWithShadows(
    shadow: ShadowData?, colorFilter: FilterOperations?, font: FontCascadeWrapper,
    textRun: TextRunWrapper, boxRect: FloatRectWrapper, textOrigin: FloatPoint,
    startOffset: UInt32, endOffset: UInt32, emphasisMark: AtomStringWrapper,
    emphasisMarkOffset: Float32, stroked: Bool
  ) {
    if shadow == nil {
      paintTextOrEmphasisMarks(
        font: font, textRun: textRun, emphasisMark: emphasisMark,
        emphasisMarkOffset: emphasisMarkOffset, textOrigin: textOrigin, startOffset: startOffset,
        endOffset: endOffset)
      return
    }

    let fillColor = context.fillColor()
    let opaque = fillColor.isOpaque()
    let lastShadowIterationShouldDrawText = !stroked && opaque
    if !opaque {
      context.setFillColor(color: ColorWrapper.black)
    }
    var crtShadow = shadow
    while crtShadow != nil {
      let shadowApplier = ShadowApplier(
        style: renderStyle, context: context, shadow: crtShadow, colorFilter: colorFilter,
        textRect: boxRect, lastShadowIterationShouldDrawText: lastShadowIterationShouldDrawText,
        opaque: opaque,
        orientation: (textBoxIsHorizontal || combinedText != nil) ? .Horizontal : .Vertical
      )
      if !shadowApplier.nothingToDraw {
        paintTextOrEmphasisMarks(
          font: font, textRun: textRun, emphasisMark: emphasisMark,
          emphasisMarkOffset: emphasisMarkOffset,
          textOrigin: textOrigin + shadowApplier.extraOffset,
          startOffset: startOffset, endOffset: endOffset)
      }
      crtShadow = crtShadow!.next
    }

    if !lastShadowIterationShouldDrawText {
      if !opaque {
        context.setFillColor(color: fillColor)
      }
      paintTextOrEmphasisMarks(
        font: font, textRun: textRun, emphasisMark: emphasisMark,
        emphasisMarkOffset: emphasisMarkOffset, textOrigin: textOrigin, startOffset: startOffset,
        endOffset: endOffset)
    }
  }

  private mutating func paintTextAndEmphasisMarksIfNeeded(
    textRun: TextRunWrapper, boxRect: FloatRectWrapper, textOrigin: FloatPoint, startOffset: UInt32,
    endOffset: UInt32, paintStyle: TextPaintStyle, shadow: ShadowData?,
    shadowColorFilter: FilterOperations?
  ) {
    if paintStyle.paintOrder == .Normal {
      // FIXME: Truncate right-to-left text correctly.
      paintTextWithShadows(
        shadow: shadow, colorFilter: shadowColorFilter, font: font, textRun: textRun,
        boxRect: boxRect, textOrigin: textOrigin, startOffset: startOffset, endOffset: endOffset,
        emphasisMark: nullAtom(), emphasisMarkOffset: 0, stroked: paintStyle.strokeWidth > 0)
    } else {
      let textDrawingMode = context.textDrawingMode()
      let paintOrder = RenderStyleWrapper.paintTypesForPaintOrder(order: paintStyle.paintOrder)
      var shadowToUse = shadow

      for order in paintOrder {
        switch order {
        case .Fill:
          var textDrawingModeWithoutStroke = textDrawingMode
          textDrawingModeWithoutStroke.remove(.Stroke)
          context.setTextDrawingMode(textDrawingMode: textDrawingModeWithoutStroke)
          paintTextWithShadows(
            shadow: shadowToUse, colorFilter: shadowColorFilter, font: font, textRun: textRun,
            boxRect: boxRect, textOrigin: textOrigin, startOffset: startOffset,
            endOffset: endOffset, emphasisMark: nullAtom(), emphasisMarkOffset: 0, stroked: false)
          shadowToUse = nil
          context.setTextDrawingMode(textDrawingMode: textDrawingMode)
        case .Stroke:
          var textDrawingModeWithoutFill = textDrawingMode
          textDrawingModeWithoutFill.remove(.Fill)
          context.setTextDrawingMode(textDrawingMode: textDrawingModeWithoutFill)
          paintTextWithShadows(
            shadow: shadowToUse, colorFilter: shadowColorFilter, font: font, textRun: textRun,
            boxRect: boxRect, textOrigin: textOrigin, startOffset: startOffset,
            endOffset: endOffset, emphasisMark: nullAtom(), emphasisMarkOffset: 0,
            stroked: paintStyle.strokeWidth > 0)
          shadowToUse = nil
          context.setTextDrawingMode(textDrawingMode: textDrawingMode)
        case .Markers:
          continue
        }
      }
    }

    if emphasisMark.isEmpty() {
      return
    }

    let boxOrigin = boxRect.location()
    updateGraphicsContext(
      context: context, paintStyle: paintStyle, fillColorType: .UseEmphasisMarkColor)
    let emphasisMarkTextRun =
      combinedText != nil ? TextPainter.objectReplacementCharacterTextRun : textRun
    let emphasisMarkTextOrigin =
      combinedText != nil
      ? FloatPoint(
        x: boxOrigin.x + boxRect.width() / 2,
        y: boxOrigin.y + Float32(font.metricsOfPrimaryFont().intAscent())) : textOrigin
    if combinedText != nil {
      context.concatCTM(transform: rotation(boxRect: boxRect, direction: .Clockwise))
    }

    // FIXME: Truncate right-to-left text correctly.
    paintTextWithShadows(
      shadow: shadow, colorFilter: shadowColorFilter,
      font: combinedText != nil ? combinedText!.originalFont() : font,
      textRun: emphasisMarkTextRun, boxRect: boxRect, textOrigin: emphasisMarkTextOrigin,
      startOffset: startOffset, endOffset: endOffset,
      emphasisMark: emphasisMark, emphasisMarkOffset: emphasisMarkOffset,
      stroked: paintStyle.strokeWidth > 0)

    if combinedText != nil {
      context.concatCTM(transform: rotation(boxRect: boxRect, direction: .Counterclockwise))
    }
  }

  private let context: GraphicsContextWrapper
  private let font: FontCascadeWrapper
  private let renderStyle: RenderStyleWrapper
  private var style = TextPaintStyle()
  private var emphasisMark = AtomStringWrapper()
  private var shadow = ShadowData()
  private var shadowColorFilter = FilterOperations()
  private var combinedText: RenderCombineTextWrapper? = nil
  private var glyphDisplayList: DisplayList.DisplayListWrapper? = nil
  private var emphasisMarkOffset: Float32 = 0
  private var textBoxIsHorizontal: Bool = true

  private static var objectReplacementCharacterTextRun: TextRunWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
