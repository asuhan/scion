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

  func paintRange(
    textRun: TextRunWrapper, boxRect: FloatRectWrapper, textOrigin: FloatPoint, start: UInt32,
    end: UInt32
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setGlyphDisplayListIfNeeded<LayoutRun>(
    run: LayoutRun, paintInfo: PaintInfoWrapper, textRun: TextRunWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintTextWithShadows(
    shadow: ShadowData?, colorFilter: FilterOperations?, font: FontCascadeWrapper,
    textRun: TextRunWrapper, boxRect: FloatRectWrapper, textOrigin: FloatPoint,
    startOffset: UInt32, endOffset: UInt32, emphasisMark: AtomStringWrapper,
    emphasisMarkOffset: Float32, stroked: Bool
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintTextAndEmphasisMarksIfNeeded(
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

    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let context: GraphicsContextWrapper
  private let font: FontCascadeWrapper
  private let renderStyle: RenderStyleWrapper
  private var style = TextPaintStyle()
  private var emphasisMark = AtomStringWrapper()
  private var shadow = ShadowData()
  private var shadowColorFilter = FilterOperations()
  private var combinedText: RenderCombineTextWrapper? = nil
  private var emphasisMarkOffset: Float32 = 0
  private var textBoxIsHorizontal: Bool = true
}
