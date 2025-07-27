/*
 * (C) 1999 Lars Knoll (knoll@kde.org)
 * (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2004-2017 Apple Inc. All rights reserved.
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

/*
 * Draw one cubic Bezier curve and repeat the same pattern along the the decoration's axis.
 * The start point (p1), controlPoint1, controlPoint2 and end point (p2) of the Bezier curve
 * form a diamond shape:
 *
 *                              step
 *                         |-----------|
 *
 *                   controlPoint1
 *                         +
 *
 *
 *                  . .
 *                .     .
 *              .         .
 * (x1, y1) p1 +           .            + p2 (x2, y2) - <--- Decoration's axis
 *                          .         .               |
 *                            .     .                 |
 *                              . .                   | controlPointDistance
 *                                                    |
 *                                                    |
 *                         +                          -
 *                   controlPoint2
 *
 *             |-----------|
 *                 step
 */
private func strokeWavyTextDecoration(
  context: GraphicsContextWrapper, rect: FloatRectWrapper,
  wavyStrokeParameters: WavyStrokeParameters
) {
  if rect.isEmpty() || wavyStrokeParameters.step == 0 {
    return
  }

  var p1 = rect.minXMinYCorner()
  var p2 = rect.maxXMinYCorner()

  // Extent the wavy line before and after the text so it can cover the whole length.
  p1.setX(x: p1.x - 2 * wavyStrokeParameters.step)
  p2.setX(x: p2.x + 2 * wavyStrokeParameters.step)

  var bounds = rect
  // Offset the bounds and set extra height to ensure the whole wavy line is covered.
  bounds.setY(y: bounds.y() - wavyStrokeParameters.controlPointDistance)
  bounds.setHeight(height: bounds.height() + 2 * wavyStrokeParameters.controlPointDistance)
  // Clip the extra wavy line added before
  let _ = GraphicsContextStateSaver(context: context)
  context.clip(rect: bounds)

  context.adjustLineToPixelBoundaries(
    p1: p1, p2: p2, strokeWidth: rect.height(), penStyle: context.strokeStyle())

  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func textDecorationStyleToStrokeStyle(decorationStyle: TextDecorationStyle) -> StrokeStyle {
  var strokeStyle: StrokeStyle = .SolidStroke
  switch decorationStyle {
  case .Solid:
    strokeStyle = .SolidStroke
  case .Double:
    strokeStyle = .DoubleStroke
  case .Dotted:
    strokeStyle = .DottedStroke
  case .Dashed:
    strokeStyle = .DashedStroke
  case .Wavy:
    strokeStyle = .WavyStroke
  }

  return strokeStyle
}

private func collectStylesForRenderer(
  result: inout TextDecorationPainter.Styles, renderer: RenderObjectWrapper,
  remainingDecorations: TextDecorationLine, firstLineStyle: Bool, paintBehavior: PaintBehavior,
  pseudoId: PseudoId
) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

struct TextDecorationPainter {
  init(
    context: GraphicsContextWrapper, font: FontCascadeWrapper, shadow: ShadowData?,
    colorFilter: FilterOperations?, isPrinting: Bool, isHorizontal: Bool
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct Styles {
    static func == (this: Styles, other: Styles) -> Bool {
      return this.underline.color == other.underline.color
        && this.overline.color == other.overline.color
        && this.linethrough.color == other.linethrough.color
        && this.underline.decorationStyle == other.underline.decorationStyle
        && this.overline.decorationStyle == other.overline.decorationStyle
        && this.linethrough.decorationStyle == other.linethrough.decorationStyle
    }

    struct DecorationStyleAndColor: Equatable {
      let color = ColorWrapper()
      let decorationStyle: TextDecorationStyle = .Solid
    }
    let underline = DecorationStyleAndColor()
    let overline = DecorationStyleAndColor()
    let linethrough = DecorationStyleAndColor()

    var skipInk: TextDecorationSkipInk = .None
  }

  struct BackgroundDecorationGeometry {
    let textOrigin: FloatPoint
    let boxOrigin: FloatPoint
    let textBoxWidth: Float32
    let textDecorationThickness: Float32
    let underlineOffset: Float32
    let overlineOffset: Float32
    let linethroughCenter: Float32
    let clippingOffset: Float32
    let wavyStrokeParameters: WavyStrokeParameters
  }

  func paintBackgroundDecorations(
    style: RenderStyleWrapper, textRun: TextRunWrapper,
    decorationGeometry: BackgroundDecorationGeometry, decorationType: TextDecorationLine,
    decorationStyle: Styles
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct ForegroundDecorationGeometry {
    let boxOrigin: FloatPoint
    let textBoxWidth: Float32
    let textDecorationThickness: Float32
    let linethroughCenter: Float32
    let wavyStrokeParameters: WavyStrokeParameters
  }

  func paintForegroundDecorations(
    foregroundDecorationGeometry: ForegroundDecorationGeometry, decorationStyle: Styles
  ) {
    paintLineThrough(
      foregroundDecorationGeometry: foregroundDecorationGeometry,
      color: decorationStyle.linethrough.color, decorationStyle: decorationStyle)
  }

  static func stylesForRenderer(
    renderer: RenderObjectWrapper, requestedDecorations: TextDecorationLine,
    firstLineStyle: Bool = false, paintBehavior: PaintBehavior = [], pseudoId: PseudoId = .None
  ) -> Styles {
    if requestedDecorations.isEmpty {
      return Styles()
    }

    var result = Styles()
    collectStylesForRenderer(
      result: &result, renderer: renderer, remainingDecorations: requestedDecorations,
      firstLineStyle: false, paintBehavior: paintBehavior, pseudoId: pseudoId)
    if firstLineStyle {
      collectStylesForRenderer(
        result: &result, renderer: renderer, remainingDecorations: requestedDecorations,
        firstLineStyle: true, paintBehavior: paintBehavior, pseudoId: pseudoId)
    }
    result.skipInk = renderer.style().textDecorationSkipInk()
    return result
  }

  static func textDecorationsInEffectForStyle(style: Styles) -> TextDecorationLine {
    var decorations = TextDecorationLine()
    if style.underline.color.isValid() {
      decorations.insert(.Underline)
    }
    if style.overline.color.isValid() {
      decorations.insert(.Overline)
    }
    if style.linethrough.color.isValid() {
      decorations.insert(.LineThrough)
    }
    return decorations
  }

  private func paintLineThrough(
    foregroundDecorationGeometry: ForegroundDecorationGeometry, color: ColorWrapper,
    decorationStyle: Styles
  ) {
    var rect = FloatRectWrapper(
      location: foregroundDecorationGeometry.boxOrigin,
      size: FloatSize(
        width: foregroundDecorationGeometry.textBoxWidth,
        height: foregroundDecorationGeometry.textDecorationThickness))
    rect.move(dx: 0, dy: foregroundDecorationGeometry.linethroughCenter)

    context.setStrokeColor(color: color)

    let style = decorationStyle.linethrough.decorationStyle
    let strokeStyle = textDecorationStyleToStrokeStyle(decorationStyle: style)

    if style == .Wavy {
      strokeWavyTextDecoration(
        context: context, rect: rect,
        wavyStrokeParameters: foregroundDecorationGeometry.wavyStrokeParameters)
    } else {
      context.drawLineForText(
        rect: rect, printing: isPrinting, doubleUnderlines: style == .Double, style: strokeStyle)
    }
  }

  private let context: GraphicsContextWrapper
  private let isPrinting = false
}
