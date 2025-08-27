/*
 * Copyright (C) 2021 Apple Inc. All rights reserved.
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

private func coalesceAdjacent(
  textsToCoalesce: [StyledMarkedText],
  equalityFunction: (StyledMarkedText.Style, StyledMarkedText.Style) -> Bool
) -> [StyledMarkedText] {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

final class StyledMarkedText: MarkedText {
  struct Style {
    let backgroundColor = ColorWrapper()
    var textStyles = TextPaintStyle()
    var textDecorationStyles = TextDecorationPainter.Styles()
    var textShadow: ShadowData? = nil
    let alpha: Float32 = 1
  }

  init(marker: MarkedText, style: Style) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let style: Style

  static func subdivideAndResolve(
    textsToSubdivide: [MarkedText], renderer: RenderTextWrapper, isFirstLine: Bool,
    paintInfo: PaintInfoWrapper
  ) -> [StyledMarkedText] {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func coalesceAdjacentWithEqualBackground(markedTexts: [StyledMarkedText])
    -> [StyledMarkedText]
  {
    return coalesceAdjacent(
      textsToCoalesce: markedTexts,
      equalityFunction: { (a: Style, b: Style) -> Bool in
        return a.backgroundColor == b.backgroundColor
      })
  }

  static func coalesceAdjacentWithEqualForeground(markedTexts: [StyledMarkedText])
    -> [StyledMarkedText]
  {
    return coalesceAdjacent(
      textsToCoalesce: markedTexts,
      equalityFunction: { (a: Style, b: Style) -> Bool in
        return a.textStyles == b.textStyles && a.textShadow == b.textShadow && a.alpha == b.alpha
      })
  }

  static func coalesceAdjacentWithEqualDecorations(markedTexts: [StyledMarkedText])
    -> [StyledMarkedText]
  {
    return coalesceAdjacent(
      textsToCoalesce: markedTexts,
      equalityFunction: { (a: Style, b: Style) -> Bool in
        return a.textDecorationStyles == b.textDecorationStyles && a.textStyles == b.textStyles
          && a.textShadow == b.textShadow && a.alpha == b.alpha
      })
  }

  static func computeStyleForUnmarkedMarkedText(
    renderer: RenderTextWrapper, lineStyle: RenderStyleWrapper, isFirstLine: Bool,
    paintInfo: PaintInfoWrapper
  ) -> Style {
    var style = Style()
    style.textDecorationStyles = TextDecorationPainter.stylesForRenderer(
      renderer: renderer, requestedDecorations: lineStyle.textDecorationsInEffect(),
      firstLineStyle: isFirstLine, paintBehavior: paintInfo.paintBehavior)
    style.textStyles = computeTextPaintStyle(
      frame: renderer.frame(), lineStyle: lineStyle, paintInfo: paintInfo)
    style.textShadow = ShadowData.clone(
      data: paintInfo.forceTextColor() ? nil : lineStyle.textShadow())
    return style
  }
}
