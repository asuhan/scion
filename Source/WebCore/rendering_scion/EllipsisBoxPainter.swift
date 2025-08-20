/*
 * Copyright (C) 2022 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON
 * ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

struct EllipsisBoxPainter {
  init(
    lineBox: InlineIterator.LineBox, paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper,
    selectionForegroundColor: ColorWrapper, selectionBackgroundColor: ColorWrapper
  ) {
    self.lineBox = lineBox
    self.paintInfo = paintInfo
    self.paintOffset = paintOffset
    self.selectionForegroundColor = selectionForegroundColor
    self.selectionBackgroundColor = selectionBackgroundColor
  }

  func paint() {
    // FIXME: Transition it to TextPainter.
    let context = paintInfo.context()
    let style = lineBox.style()
    var textColor = style.visitedDependentColorWithColorFilter(
      colorProperty: .CSSPropertyWebkitTextFillColor)

    if paintInfo.forceTextColor() {
      textColor = paintInfo.forcedTextColor()
    }

    if lineBox.ellipsisSelectionState() != .None {
      paintSelection()

      // Select the correct color for painting the text.
      let foreground =
        paintInfo.forceTextColor() ? paintInfo.forcedTextColor() : selectionForegroundColor
      if foreground.isValid() && foreground != textColor {
        context.setFillColor(color: foreground)
      }
    }

    if textColor != context.fillColor() {
      context.setFillColor(color: textColor)
    }

    var setShadow = false
    if let textShadow = style.textShadow() {
      let shadowColor = style.colorWithColorFilter(color: textShadow.color)
      context.setDropShadow(
        dropShadow: GraphicsDropShadow(
          offset: LayoutSizeWrapper(
            width: textShadow.x().value(), height: textShadow.y().value()
          ).FloatSize(),
          radius: textShadow.radius.value(), color: shadowColor, radiusMode: .Default))
      setShadow = true
    }

    let visualRect = lineBox.ellipsisVisualRect()
    var textOrigin = visualRect.location()
    textOrigin.move(
      dx: paintOffset.x.float(),
      dy: paintOffset.y.float() + Float32(style.metricsOfPrimaryFont().intAscent()))
    context.drawBidiText(font: style.fontCascade(), run: lineBox.ellipsisText(), point: textOrigin)

    if textColor != context.fillColor() {
      context.setFillColor(color: textColor)
    }

    if setShadow {
      context.clearDropShadow()
    }
  }

  private func paintSelection() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let lineBox: InlineIterator.LineBox
  private let paintInfo: PaintInfoWrapper
  private let paintOffset: LayoutPointWrapper
  private let selectionForegroundColor: ColorWrapper
  private let selectionBackgroundColor: ColorWrapper
}
