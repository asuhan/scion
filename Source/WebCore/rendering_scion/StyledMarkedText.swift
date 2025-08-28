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

private func resolveStyleForMarkedText(
  markedText: MarkedText, baseStyle: StyledMarkedText.Style, renderer: RenderTextWrapper,
  lineStyle: RenderStyleWrapper, paintInfo: PaintInfoWrapper
)
  -> StyledMarkedText
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func coalesceAdjacentWithSameRanges(styledTexts: [StyledMarkedText]) -> [StyledMarkedText] {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func orderHighlights(
  markedTextsNames: ListSet<AtomStringWrapper, AtomStringWrapper>, markedTexts: [MarkedText]
) {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func coalesceAdjacent(
  textsToCoalesce: [StyledMarkedText],
  equalityFunction: (StyledMarkedText.Style, StyledMarkedText.Style) -> Bool
) -> [StyledMarkedText] {
  if textsToCoalesce.count <= 1 {
    return textsToCoalesce
  }

  var styledMarkedTexts: [StyledMarkedText] = []
  styledMarkedTexts.reserveCapacity(textsToCoalesce.count)
  styledMarkedTexts.append(textsToCoalesce[0])
  for currentStyledMarkedText in textsToCoalesce[1...] {
    let previousStyledMarkedText = styledMarkedTexts.last!
    if previousStyledMarkedText.endOffset == currentStyledMarkedText.startOffset
      && equalityFunction(previousStyledMarkedText.style, currentStyledMarkedText.style)
    {
      previousStyledMarkedText.endOffset = currentStyledMarkedText.endOffset
      continue
    }
    styledMarkedTexts.append(currentStyledMarkedText)
  }

  return styledMarkedTexts
}

final class StyledMarkedText: MarkedText {
  struct Style {
    let backgroundColor = ColorWrapper()
    var textStyles = TextPaintStyle()
    var textDecorationStyles = TextDecorationPainter.Styles()
    var textShadow: ShadowData? = nil
    let alpha: Float32 = 1
  }

  init(marker: MarkedText) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  init(marker: MarkedText, style: Style) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var style: Style

  static func subdivideAndResolve(
    textsToSubdivide: [MarkedText], renderer: RenderTextWrapper, isFirstLine: Bool,
    paintInfo: PaintInfoWrapper
  ) -> [StyledMarkedText] {
    if textsToSubdivide.isEmpty {
      return []
    }

    // Keep track of original order of highlights.
    let markedTextsNames = ListSet<AtomStringWrapper, AtomStringWrapper>()
    for markedText in textsToSubdivide {
      if !markedText.highlightName.isNull() {
        markedTextsNames.add(value: markedText.highlightName)
      }
    }

    let lineStyle = isFirstLine ? renderer.firstLineStyle() : renderer.style()
    let baseStyle = computeStyleForUnmarkedMarkedText(
      renderer: renderer, lineStyle: lineStyle, isFirstLine: isFirstLine, paintInfo: paintInfo)

    if textsToSubdivide.count == 1 && textsToSubdivide[0].type == .Unmarked {
      let styledMarkedText = StyledMarkedText(marker: textsToSubdivide[0])
      styledMarkedText.style = baseStyle
      return [styledMarkedText]
    }

    let markedTexts = MarkedText.subdivide(markedTexts: textsToSubdivide, overlapStrategy: .None)
    assert(!markedTexts.isEmpty)

    // Check if vector contains custom highlights.
    let containsHighlights = markedTexts.contains { item in item.type == .Highlight }

    // Sort custom highlights to follow correct priority/insertion order.
    if containsHighlights {
      orderHighlights(markedTextsNames: markedTextsNames, markedTexts: markedTexts)

      let frontmostMarkedTexts = markedTexts.map({ markedText in
        resolveStyleForMarkedText(
          markedText: markedText, baseStyle: baseStyle, renderer: renderer, lineStyle: lineStyle,
          paintInfo: paintInfo)
      })

      return coalesceAdjacentWithSameRanges(styledTexts: frontmostMarkedTexts)
    }

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
