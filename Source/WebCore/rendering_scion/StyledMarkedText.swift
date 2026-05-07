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

private func computeStyleForPseudoElementStyle(
  style: inout StyledMarkedText.Style, pseudoElementStyle: RenderStyleWrapper?,
  paintInfo: PaintInfoWrapper
) {
  if pseudoElementStyle == nil {
    return
  }

  let pseudoElementStyle = pseudoElementStyle!
  style.backgroundColor = pseudoElementStyle.visitedDependentColorWithColorFilter(
    colorProperty: .CSSPropertyBackgroundColor, paintBehavior: paintInfo.paintBehavior)
  style.textStyles.fillColor = pseudoElementStyle.computedStrokeColor()
  style.textStyles.strokeColor = pseudoElementStyle.computedStrokeColor()
  style.textStyles.hasExplicitlySetFillColor = pseudoElementStyle.hasExplicitlySetColor()

  let color = TextDecorationPainter.decorationColor(
    style: pseudoElementStyle, paintBehavior: paintInfo.paintBehavior)
  let decorationStyle = pseudoElementStyle.textDecorationStyle()
  let decorations = pseudoElementStyle.textDecorationsInEffect()

  if decorations.contains(.Underline) {
    style.textDecorationStyles.underline.color = color
    style.textDecorationStyles.underline.decorationStyle = decorationStyle
  }
  if decorations.contains(.Overline) {
    style.textDecorationStyles.overline.color = color
    style.textDecorationStyles.overline.decorationStyle = decorationStyle
  }
  if decorations.contains(.LineThrough) {
    style.textDecorationStyles.linethrough.color = color
    style.textDecorationStyles.linethrough.decorationStyle = decorationStyle
  }
}

private func resolveStyleForMarkedText(
  markedText: MarkedText, baseStyle: StyledMarkedText.Style, renderer: RenderTextWrapper,
  lineStyle: RenderStyleWrapper, paintInfo: PaintInfoWrapper
)
  -> StyledMarkedText
{
  var style = baseStyle
  switch markedText.type {
  case .Correction, .DictationAlternatives, .Unmarked:
    break
  case .GrammarError:
    let renderStyle = renderer.grammarErrorPseudoStyle()
    computeStyleForPseudoElementStyle(
      style: &style, pseudoElementStyle: renderStyle, paintInfo: paintInfo)
  case .Highlight:
    let renderStyle = renderer.parent()!.getUncachedPseudoStyle(
      pseudoElementRequest: Style.PseudoElementRequest(
        pseudoId: .Highlight, nameArgument: markedText.highlightName), parentStyle: renderer.style()
    )
    computeStyleForPseudoElementStyle(
      style: &style, pseudoElementStyle: renderStyle, paintInfo: paintInfo)
  case .SpellingError:
    let renderStyle = renderer.spellingErrorPseudoStyle()
    computeStyleForPseudoElementStyle(
      style: &style, pseudoElementStyle: renderStyle, paintInfo: paintInfo)
  case .FragmentHighlight:
    if let renderStyle = renderer.targetTextPseudoStyle() {
      computeStyleForPseudoElementStyle(
        style: &style, pseudoElementStyle: renderStyle, paintInfo: paintInfo)
    } else {
      let styleColorOptions: StyleColorOptions = .UseSystemAppearance
      style.backgroundColor = renderer.theme().annotationHighlightColor(options: styleColorOptions)
    }
  case .DraggedContent:
    style.alpha = 0.25
  case .TransparentContent:
    style.alpha = 0.0
  case .Selection:
    style.textStyles = computeTextSelectionPaintStyle(
      textPaintStyle: style.textStyles, renderer: renderer, lineStyle: lineStyle,
      paintInfo: paintInfo, selectionShadow: &style.textShadow)

    let selectionBackgroundColor = renderer.selectionBackgroundColor()
    style.backgroundColor = selectionBackgroundColor
    if selectionBackgroundColor.isValid() && selectionBackgroundColor.isVisible()
      && style.textStyles.fillColor == selectionBackgroundColor
    {
      style.backgroundColor = selectionBackgroundColor.invertedColorWithAlpha(alpha: 1)
    }
  case .TextMatch:
    // Text matches always use the light system appearance.
    let styleColorOptions: StyleColorOptions = .UseSystemAppearance
    style.backgroundColor = renderer.theme().textSearchHighlightColor(options: styleColorOptions)
  }
  let styledMarkedText = StyledMarkedText(marker: markedText)
  styledMarkedText.style = style
  return styledMarkedText
}

private func computeStylesForTextDecorations(
  previousTextDecorationStyles: TextDecorationPainter.Styles,
  currentTextDecorationStyles: TextDecorationPainter.Styles
) -> TextDecorationPainter.Styles {
  let textDecorations = TextDecorationPainter.textDecorationsInEffectForStyle(
    style: currentTextDecorationStyles)

  if textDecorations.isEmpty {
    return previousTextDecorationStyles
  }

  var textDecorationStyles = previousTextDecorationStyles

  if textDecorations.contains(.Underline) {
    textDecorationStyles.underline.color = currentTextDecorationStyles.underline.color
    textDecorationStyles.underline.decorationStyle =
      currentTextDecorationStyles.underline.decorationStyle
  }
  if textDecorations.contains(.Overline) {
    textDecorationStyles.overline.color = currentTextDecorationStyles.overline.color
    textDecorationStyles.overline.decorationStyle =
      currentTextDecorationStyles.overline.decorationStyle
  }
  if textDecorations.contains(.LineThrough) {
    textDecorationStyles.linethrough.color = currentTextDecorationStyles.linethrough.color
    textDecorationStyles.linethrough.decorationStyle =
      currentTextDecorationStyles.linethrough.decorationStyle
  }
  return textDecorationStyles
}

private func coalesceAdjacentWithSameRanges(styledTexts: [StyledMarkedText]) -> [StyledMarkedText] {
  assert(!styledTexts.isEmpty)
  var frontmostMarkedTexts: [StyledMarkedText] = []
  frontmostMarkedTexts.append(styledTexts[0])
  for currentStyledMarkedText in styledTexts[1...] {
    let previousStyledMarkedText = frontmostMarkedTexts.last!
    // StyledMarkedTexts completely cover each other.
    if previousStyledMarkedText.startOffset == currentStyledMarkedText.startOffset
      && previousStyledMarkedText.endOffset == currentStyledMarkedText.endOffset
    {
      // If either background for two different custom highlight StyledMarkedTexts are not opaque, blend colors together.
      if previousStyledMarkedText.highlightName != currentStyledMarkedText.highlightName
        && (!previousStyledMarkedText.style.backgroundColor.isOpaque()
          || !currentStyledMarkedText.style.backgroundColor.isOpaque()
          || (currentStyledMarkedText.highlightName.isNull()
            && currentStyledMarkedText.style.backgroundColor.isVisible()))
      {
        previousStyledMarkedText.style.backgroundColor = blendSourceOver(
          backdrop: previousStyledMarkedText.style.backgroundColor,
          source: currentStyledMarkedText.style.backgroundColor)
      }
      // Take text color of StyledMarkedText, maintaining insertion and priority order.
      if currentStyledMarkedText.type != .Unmarked
        && currentStyledMarkedText.style.textStyles.hasExplicitlySetFillColor
      {
        previousStyledMarkedText.style.textStyles.fillColor =
          currentStyledMarkedText.style.textStyles.fillColor
      }
      // Take the highlightName of the latest StyledMarkedText, regardless of priority.
      if !currentStyledMarkedText.highlightName.isNull() {
        previousStyledMarkedText.highlightName = currentStyledMarkedText.highlightName
      }

      if previousStyledMarkedText.priority <= currentStyledMarkedText.priority {
        previousStyledMarkedText.priority = currentStyledMarkedText.priority
        // If highlight, combine textDecorationStyles accordingly.
        // FIXME: Check for taking textDecorationStyles needs to accommodate other MarkedText type.
        if !currentStyledMarkedText.highlightName.isNull() {
          previousStyledMarkedText.style.textDecorationStyles = computeStylesForTextDecorations(
            previousTextDecorationStyles: previousStyledMarkedText.style.textDecorationStyles,
            currentTextDecorationStyles: currentStyledMarkedText.style.textDecorationStyles)
        }
        // If higher or same priority and opaque, override background color.
        if currentStyledMarkedText.style.backgroundColor.isOpaque() {
          previousStyledMarkedText.style.backgroundColor =
            currentStyledMarkedText.style.backgroundColor
        }
      }
      continue
    }
    frontmostMarkedTexts.append(currentStyledMarkedText)
  }
  return frontmostMarkedTexts
}

private func orderHighlights(
  markedTextsNames: ListSet<AtomStringWrapper>, markedTexts: inout [MarkedText]
) {
  if markedTexts.isEmpty {
    return
  }

  var markedTextsNamesPriority: [AtomStringWrapper: Int] = [:]
  var index: Int = 0
  for highlightName in markedTextsNames {
    markedTextsNamesPriority.updateValue(index, forKey: highlightName)
    index += 1
  }

  index = 0
  while index < markedTexts.count - 1 {
    // If two adjacent highlights with same ranges are not in correct priority order, swap them and move on.
    if !markedTexts[index].highlightName.isNull()
      && !markedTexts[index + 1].highlightName.isNull()
      && markedTextsNamesPriority[markedTexts[index].highlightName]!
        > markedTextsNamesPriority[markedTexts[index + 1].highlightName]!
      && markedTexts[index].startOffset == markedTexts[index + 1].startOffset
      && markedTexts[index].endOffset == markedTexts[index + 1].endOffset
    {
      markedTexts.swapAt(index, index + 1)
    }
    index += 1
  }
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
    var backgroundColor = ColorWrapper()
    var textStyles = TextPaintStyle()
    var textDecorationStyles = TextDecorationPainter.Styles()
    var textShadow: ShadowData? = nil
    var alpha: Float32 = 1
  }

  convenience init(marker: MarkedText) {
    self.init(marker: marker, style: Style())
  }

  init(marker: MarkedText, style: Style) {
    self.style = style
    super.init(
      startOffset: marker.startOffset, endOffset: marker.endOffset, type: marker.type,
      marker: marker.marker, highlightName: marker.highlightName, priority: marker.priority)
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
    let markedTextsNames = ListSet<AtomStringWrapper>()
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

    var markedTexts = MarkedText.subdivide(markedTexts: textsToSubdivide, overlapStrategy: .None)
    assert(!markedTexts.isEmpty)

    // Check if vector contains custom highlights.
    let containsHighlights = markedTexts.contains { item in item.type == .Highlight }

    // Sort custom highlights to follow correct priority/insertion order.
    if containsHighlights {
      orderHighlights(markedTextsNames: markedTextsNames, markedTexts: &markedTexts)

      let frontmostMarkedTexts = markedTexts.map({ markedText in
        resolveStyleForMarkedText(
          markedText: markedText, baseStyle: baseStyle, renderer: renderer, lineStyle: lineStyle,
          paintInfo: paintInfo)
      })

      return coalesceAdjacentWithSameRanges(styledTexts: frontmostMarkedTexts)
    }

    // Compute frontmost overlapping styled marked texts.
    var frontmostMarkedTexts: [StyledMarkedText] = []
    frontmostMarkedTexts.reserveCapacity(markedTexts.count)
    frontmostMarkedTexts.append(
      resolveStyleForMarkedText(
        markedText: markedTexts[0], baseStyle: baseStyle, renderer: renderer, lineStyle: lineStyle,
        paintInfo: paintInfo))
    for currentStyledMarkedText in markedTexts[1...] {
      var previousStyledMarkedText = frontmostMarkedTexts.last!
      // Marked texts completely cover each other.
      if previousStyledMarkedText.startOffset == currentStyledMarkedText.startOffset
        && previousStyledMarkedText.endOffset == currentStyledMarkedText.endOffset
      {
        previousStyledMarkedText = resolveStyleForMarkedText(
          markedText: currentStyledMarkedText, baseStyle: previousStyledMarkedText.style,
          renderer: renderer, lineStyle: lineStyle, paintInfo: paintInfo)
        continue
      }
      frontmostMarkedTexts.append(
        resolveStyleForMarkedText(
          markedText: currentStyledMarkedText, baseStyle: baseStyle, renderer: renderer,
          lineStyle: lineStyle, paintInfo: paintInfo))
    }

    return frontmostMarkedTexts
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
