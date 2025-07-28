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

  let path = PathWrapper()
  path.moveTo(point: p1)

  assert(p1.y == p2.y)

  let yAxis = p1.y
  let x1 = min(p1.x, p2.x)
  let x2 = max(p1.x, p2.x)

  var controlPoint1 = FloatPoint(x: 0, y: yAxis + wavyStrokeParameters.controlPointDistance)
  var controlPoint2 = FloatPoint(x: 0, y: yAxis - wavyStrokeParameters.controlPointDistance)

  var x = x1
  while x + 2 * wavyStrokeParameters.step <= x2 {
    controlPoint1.setX(x: x + wavyStrokeParameters.step)
    controlPoint2.setX(x: x + wavyStrokeParameters.step)
    x += 2 * wavyStrokeParameters.step
    path.addBezierCurveTo(
      controlPoint1: controlPoint1, controlPoint2: controlPoint2,
      endPoint: FloatPoint(x: x, y: yAxis))
  }

  context.setShouldAntialias(shouldAntialias: true)
  context.setStrokeThickness(thickness: rect.height())
  context.strokePath(path: path)
}

private func translateIntersectionPointsToSkipInkBoundaries(
  intersections: DashArray, dilationAmount: Float32, totalWidth: Float32
) -> DashArray {
  assert(intersections.count % 2 == 0)

  // Step 1: Make pairs so we can sort based on range starting-point. We dilate the ranges in this step as well.
  var tuples: [(Float32, Float32)] = []
  for i in stride(from: 0, to: intersections.count, by: 2) {
    tuples.append(
      (Float32(intersections[i]) - dilationAmount, Float32(intersections[i + 1]) + dilationAmount))
  }
  tuples.sort(by: { l, r in l.0 < r.0 })

  // Step 2: Deal with intersecting ranges.
  var intermediateTuples: [(Float32, Float32)] = []
  if tuples.count >= 2 {
    intermediateTuples.append(tuples.first!)
    for (secondStart, secondEnd) in intermediateTuples[1...] {
      let (_, firstEnd) = intermediateTuples.last!
      if secondStart <= firstEnd && secondEnd <= firstEnd {
        // Ignore this range completely
      } else if secondStart <= firstEnd {
        let lastIdx = intermediateTuples.count - 1
        let (lastStart, _) = intermediateTuples[lastIdx]
        intermediateTuples[lastIdx] = (lastStart, secondEnd)
      } else {
        intermediateTuples.append((secondStart, secondEnd))
      }
    }
  } else {
    intermediateTuples = tuples
  }

  // Step 3: Output the space between the ranges, but only if the space warrants an underline.
  var previous: Float32 = 0
  var result = DashArray()
  for (tupleFirst, tupleSecond) in intermediateTuples {
    if tupleFirst - previous > dilationAmount {
      result.append(Float64(previous))
      result.append(Float64(tupleFirst))
    }
    previous = tupleSecond
  }
  if totalWidth - previous > dilationAmount {
    result.append(Float64(previous))
    result.append(Float64(totalWidth))
  }

  return result
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

private func extractDecorations(
  style: RenderStyleWrapper, decorations: TextDecorationLine, paintBehavior: PaintBehavior,
  remainingDecorations: inout TextDecorationLine,
  result: inout TextDecorationPainter.Styles
) {
  if decorations.isEmpty {
    return
  }

  let color = TextDecorationPainter.decorationColor(style: style, paintBehavior: paintBehavior)
  let decorationStyle = style.textDecorationStyle()

  if decorations.contains(.Underline) {
    remainingDecorations.remove(.Underline)
    result.underline.color = color
    result.underline.decorationStyle = decorationStyle
  }
  if decorations.contains(.Overline) {
    remainingDecorations.remove(.Overline)
    result.overline.color = color
    result.overline.decorationStyle = decorationStyle
  }
  if decorations.contains(.LineThrough) {
    remainingDecorations.remove(.LineThrough)
    result.linethrough.color = color
    result.linethrough.decorationStyle = decorationStyle
  }
}

struct TextDecorationPainter {
  init(
    context: GraphicsContextWrapper, font: FontCascadeWrapper, shadow: ShadowData?,
    colorFilter: FilterOperations?, isPrinting: Bool, isHorizontal: Bool
  ) {
    self.context = context
    self.isPrinting = isPrinting
    self.isHorizontal = isHorizontal
    self.shadow = shadow
    self.shadowColorFilter = colorFilter
    self.font = font
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
      var color = ColorWrapper()
      var decorationStyle: TextDecorationStyle = .Solid
    }
    var underline = DecorationStyleAndColor()
    var overline = DecorationStyleAndColor()
    var linethrough = DecorationStyleAndColor()

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

  private func paintDecoration(
    decoration: TextDecorationLine, style: TextDecorationStyle, color: ColorWrapper,
    rect: FloatRectWrapper, textRun: TextRunWrapper,
    decorationGeometry: BackgroundDecorationGeometry,
    decorationStyle: Styles
  ) {
    context.setStrokeColor(color: color)

    let strokeStyle = textDecorationStyleToStrokeStyle(decorationStyle: style)

    if style == .Wavy {
      strokeWavyTextDecoration(
        context: context, rect: rect, wavyStrokeParameters: decorationGeometry.wavyStrokeParameters)
    } else if decoration == .Underline || decoration == .Overline {
      if (decorationStyle.skipInk == .Auto || decorationStyle.skipInk == .All) && isHorizontal {
        if !context.paintingDisabled() {
          let underlineBoundingBox = context.computeUnderlineBoundsForText(
            rect: rect, printing: isPrinting)
          let intersections = font.dashesForIntersectionsWithRect(
            run: textRun, textOrigin: decorationGeometry.textOrigin,
            lineExtents: underlineBoundingBox)
          let boundaries = translateIntersectionPointsToSkipInkBoundaries(
            intersections: intersections, dilationAmount: underlineBoundingBox.height(),
            totalWidth: rect.width())
          assert(boundaries.count % 2 == 0)
          // We don't use underlineBoundingBox here because drawLinesForText() will run computeUnderlineBoundsForText() internally.
          context.drawLinesForText(
            point: rect.location(), thickness: rect.height(), widths: boundaries,
            printing: isPrinting, doubleUnderlines: style == .Double, strokeStyle: strokeStyle)
        }
      } else {
        // FIXME: Need to support text-decoration-skip: none.
        context.drawLineForText(
          rect: rect, printing: isPrinting, doubleUnderlines: style == .Double, style: strokeStyle)
      }
    } else {
      fatalError("Not reached")
    }
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

  static func decorationColor(style: RenderStyleWrapper, paintBehavior: PaintBehavior = [])
    -> ColorWrapper
  {
    if paintBehavior.contains(.ForceBlackText) {
      return ColorWrapper.black
    }

    if paintBehavior.contains(.ForceWhiteText) {
      return ColorWrapper.white
    }

    return style.visitedDependentColorWithColorFilter(
      colorProperty: .CSSPropertyTextDecorationColor, paintBehavior: paintBehavior)
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
  private var isPrinting = false
  private var isHorizontal = true
  private var shadow: ShadowData? = nil
  private var shadowColorFilter: FilterOperations? = nil
  private let font: FontCascadeWrapper
}
