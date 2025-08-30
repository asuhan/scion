/*
 * Copyright (C) 2013 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

struct TextPaintStyle: Equatable {
  init() {
    self.init(color: ColorWrapper())
  }

  init(color: ColorWrapper) {
    self.fillColor = color
    self.strokeColor = color
  }

  var fillColor: ColorWrapper
  var strokeColor: ColorWrapper
  var emphasisMarkColor = ColorWrapper()
  var strokeWidth: Float32 = 0
  // This is not set for -webkit-text-fill-color.
  var hasExplicitlySetFillColor: Bool = false
  let paintOrder: PaintOrder = .Normal
  let lineJoin: LineJoin = .Miter
  let lineCap: LineCap = .Butt
  let miterLimit: Float32 = defaultMiterLimit
}

func computeTextPaintStyle(
  frame: LocalFrameWrapper, lineStyle: RenderStyleWrapper, paintInfo: PaintInfoWrapper
) -> TextPaintStyle {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func computeTextSelectionPaintStyle(
  textPaintStyle: TextPaintStyle, renderer: RenderTextWrapper,
  lineStyle: RenderStyleWrapper, paintInfo: PaintInfoWrapper,
  selectionShadow: inout ShadowData?
) -> TextPaintStyle {
  var selectionPaintStyle = textPaintStyle

  let foreground =
    paintInfo.forceTextColor() ? paintInfo.forcedTextColor() : renderer.selectionForegroundColor()
  if foreground.isValid() && foreground != selectionPaintStyle.fillColor {
    selectionPaintStyle.fillColor = foreground
  }

  let emphasisMarkForeground =
    paintInfo.forceTextColor() ? paintInfo.forcedTextColor() : renderer.selectionEmphasisMarkColor()
  if emphasisMarkForeground.isValid()
    && emphasisMarkForeground != selectionPaintStyle.emphasisMarkColor
  {
    selectionPaintStyle.emphasisMarkColor = emphasisMarkForeground
  }

  if let pseudoStyle = renderer.selectionPseudoStyle() {
    selectionPaintStyle.hasExplicitlySetFillColor = pseudoStyle.hasExplicitlySetColor()
    selectionShadow = ShadowData.clone(
      data: paintInfo.forceTextColor() ? nil : pseudoStyle.textShadow())
    let viewportSize = renderer.frame().view() != nil ? renderer.frame().view()!.size() : IntSize()
    let strokeWidth = pseudoStyle.computedStrokeWidth(viewportSize: viewportSize)
    if strokeWidth != selectionPaintStyle.strokeWidth {
      selectionPaintStyle.strokeWidth = strokeWidth
    }

    let stroke =
      paintInfo.forceTextColor() ? paintInfo.forcedTextColor() : pseudoStyle.computedStrokeColor()
    if stroke != selectionPaintStyle.strokeColor {
      selectionPaintStyle.strokeColor = stroke
    }
  } else {
    selectionShadow = ShadowData.clone(
      data: paintInfo.forceTextColor() ? nil : lineStyle.textShadow())
  }
  return selectionPaintStyle
}

enum FillColorType {
  case UseNormalFillColor
  case UseEmphasisMarkColor
}

func updateGraphicsContext(
  context: GraphicsContextWrapper, paintStyle: TextPaintStyle,
  fillColorType: FillColorType = .UseNormalFillColor
) {
  var mode = context.textDrawingMode()
  var newMode = mode
  if paintStyle.strokeWidth > 0 && paintStyle.strokeColor.isVisible() {
    newMode = newMode.union(.Stroke)
  }
  if mode != newMode {
    context.setTextDrawingMode(textDrawingMode: newMode)
    mode = newMode
  }

  let fillColor =
    fillColorType == .UseEmphasisMarkColor ? paintStyle.emphasisMarkColor : paintStyle.fillColor
  if mode.contains(.Fill) && (fillColor != context.fillColor()) {
    context.setFillColor(color: fillColor)
  }

  if mode.contains(.Stroke) {
    if paintStyle.strokeColor != context.strokeColor() {
      context.setStrokeColor(color: paintStyle.strokeColor)
    }
    if paintStyle.strokeWidth != context.strokeThickness() {
      context.setStrokeThickness(thickness: paintStyle.strokeWidth)
    }
    context.setLineJoin(lineJoin: paintStyle.lineJoin)
    context.setLineCap(lineCap: paintStyle.lineCap)
    if paintStyle.lineJoin == .Miter {
      context.setMiterLimit(miter: paintStyle.miterLimit)
    }
  }
}
