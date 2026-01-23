/*
 * Copyright (C) Research In Motion Limited 2010-2012. All rights reserved.
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
 */

struct MeasureTextData {
  let allCharactersMap: SVGTextLayoutAttributesBuilder.SVGCharacterDataMapRef?
  var processRenderer = false
}

struct SVGTextMetricsBuilder {
  init() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func buildMetricsAndLayoutAttributes(
    _ textRoot: RenderSVGTextWrapper, _ stopAtLeaf: RenderSVGInlineTextWrapper?,
    _ allCharactersMap: SVGTextLayoutAttributesBuilder.SVGCharacterDataMapRef
  ) {
    let data = MeasureTextData(allCharactersMap: allCharactersMap)
    walkTree(textRoot, stopAtLeaf, data)
  }

  private mutating func advance() -> Bool {
    textPosition += currentMetrics.length
    if textPosition >= run!.length() {
      return false
    }

    if isComplexText {
      advanceComplexText()
    } else {
      advanceSimpleText()
    }

    return currentMetrics.length > 0
  }

  private mutating func advanceSimpleText() {
    let glyphBuffer = GlyphBufferWrapper()
    let before = simpleWidthIterator!.currentCharacterIndex()
    simpleWidthIterator!.advance(textPosition + 1, glyphBuffer)
    let after = simpleWidthIterator!.currentCharacterIndex()
    if before == after {
      currentMetrics = SVGTextMetrics()
      return
    }

    let currentWidth = simpleWidthIterator!.runWidthSoFar() - totalWidth
    totalWidth = simpleWidthIterator!.runWidthSoFar()

    currentMetrics = SVGTextMetrics(text!, after - before, currentWidth)
  }

  private mutating func advanceComplexText() {
    let metricsLength: UInt32 = currentCharacterStartsSurrogatePair() ? 2 : 1
    currentMetrics = SVGTextMetrics.measureCharacterRange(text!, textPosition, metricsLength)
    complexStartToCurrentMetrics = SVGTextMetrics.measureCharacterRange(
      text!, 0, textPosition + metricsLength)
    assert(currentMetrics.length == metricsLength)

    // Frequent case for Arabic text: when measuring a single character the arabic isolated form is taken
    // when rendering the glyph "in context" (with it's surrounding characters) it changes due to shaping.
    // So whenever currentWidth != currentMetrics.width(), we are processing a text run whose length is
    // not equal to the sum of the individual lengths of the glyphs, when measuring them isolated.
    let currentWidth = complexStartToCurrentMetrics.width - totalWidth
    currentMetrics.width = currentWidth

    totalWidth = complexStartToCurrentMetrics.width
  }

  private func initializeMeasurementWithTextRenderer(_ text: RenderSVGInlineTextWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private mutating func walkTree(
    _ start: RenderElementWrapper, _ stopAtLeaf: RenderSVGInlineTextWrapper?,
    _ data: MeasureTextData
  ) {
    var valueListPosition: UInt32 = 0
    var lastCharacter: UChar = 0
    var child = start.firstChild()
    while child != nil {
      if let text = child as? RenderSVGInlineTextWrapper {
        var data = data
        data.processRenderer = stopAtLeaf == nil || CPtrToInt(stopAtLeaf!.p) == CPtrToInt(text.p)
        (valueListPosition, lastCharacter) = measureTextRenderer(
          text, data, (valueListPosition, lastCharacter))
        if stopAtLeaf != nil && CPtrToInt(stopAtLeaf!.p) == CPtrToInt(text.p) {
          return
        }
      } else if let renderer = child as? RenderSVGInlineWrapper,
        let inlineChild = renderer.firstChild()
      {
        // Visit children of text content elements.
        child = inlineChild
        continue
      }
      child = child!.nextInPreOrderAfterChildren(start)
    }
  }

  private mutating func measureTextRenderer(
    _ text: RenderSVGInlineTextWrapper, _ data: MeasureTextData, _ state: (UInt32, UChar)
  ) -> (UInt32, UChar) {
    var (valueListPosition, lastCharacter) = state
    let attributes = text.layoutAttributes()
    let textMetricsValues = attributes.textMetricsValues()
    if data.processRenderer {
      if data.allCharactersMap != nil {
        attributes.clear()
      } else {
        textMetricsValues.a.removeAll()
      }
    }

    initializeMeasurementWithTextRenderer(text)

    let scaledFont = text.scaledFont()
    let preserveWhiteSpace = text.style().whiteSpaceCollapse() == .Preserve
    if canUseSimplifiedTextMeasuring && data.processRenderer {
      // If we are not specifying specific configuration for characters, data.allCharactersMap has only 1 entry for default case.
      // This is extremely common, and that's why we crafted a fast path here.
      // FIXME: For any cases, we are handling one character by one character in SVGTextMetrics. But many texts do not have
      // characterDataMap. We should handle multiple characters in one SVGTextMetrics. This also makes RTL work.
      // FIXME: This function is called even though width information is not changed at all. RenderSVGText / RenderSVGInlineText
      // should track the potential changes to width etc. and invoke this function only when it is actually changed.
      if data.allCharactersMap != nil && run!.direction() == .LTR
        && data.allCharactersMap!.m.count == 1
      {
        let defaultPosition: UInt32 = 1
        let characterData = data.allCharactersMap!.m[defaultPosition]!  // "1" is the default value and always exists.

        let view = run!.text()
        let length = view.length()
        var skippedCharacters: UInt32 = 0
        let scalingFactor = text.scalingFactor()
        assert(scalingFactor != 0)
        let scaledHeight = scaledFont.metricsOfPrimaryFont().height() / scalingFactor

        // canUseSimplifiedTextMeasuring ensures that this does not include surrogate pairs. So we do not need to consider about them.
        for i in 0..<length {
          let currentCharacter = view.characterAt(index: i)
          assert(!UTF16.isLeadSurrogate(currentCharacter))
          if currentCharacter == CharacterNames.Unicode.space && !preserveWhiteSpace
            && (lastCharacter == 0 || lastCharacter == CharacterNames.Unicode.space)
          {
            if data.processRenderer {
              textMetricsValues.a.append(SVGTextMetrics(.SkippedSpaceMetrics))
            }
            skippedCharacters += 1
            continue
          }

          if (valueListPosition + i - skippedCharacters + 1) == defaultPosition {
            attributes.characterDataMap().m[i + 1] = characterData
          }

          let width = scaledFont.widthForTextUsingSimplifiedMeasuring(
            text: view.substring(start: i, length: 1), textDirection: .LTR)
          let scaledWidth = width / scalingFactor
          textMetricsValues.a.append(SVGTextMetrics(1, scaledWidth, scaledHeight))
          lastCharacter = currentCharacter
        }

        return (valueListPosition + length - skippedCharacters, lastCharacter)
      }
    }

    if !isComplexText {
      simpleWidthIterator = WidthIteratorWrapper(scaledFont, run!)
    }

    var surrogatePairCharacters: UInt32 = 0
    var skippedCharacters: UInt32 = 0
    while advance() {
      let currentCharacter = run![textPosition]
      if currentCharacter == CharacterNames.Unicode.space && !preserveWhiteSpace
        && (lastCharacter == 0 || lastCharacter == CharacterNames.Unicode.space)
      {
        if data.processRenderer {
          textMetricsValues.a.append(SVGTextMetrics(.SkippedSpaceMetrics))
        }
        skippedCharacters += currentMetrics.length
        continue
      }

      if data.processRenderer {
        if data.allCharactersMap != nil {
          if let characterData = data.allCharactersMap!.m[
            valueListPosition + textPosition - skippedCharacters - surrogatePairCharacters + 1]
          {
            attributes.characterDataMap().m[textPosition + 1] = characterData
          }
        }
        textMetricsValues.a.append(currentMetrics)
      }

      if data.allCharactersMap != nil && currentCharacterStartsSurrogatePair() {
        surrogatePairCharacters += 1
      }

      lastCharacter = currentCharacter
    }

    simpleWidthIterator = nil
    return (valueListPosition + textPosition - skippedCharacters, lastCharacter)
  }

  private func currentCharacterStartsSurrogatePair() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let text: RenderSVGInlineTextWrapper?
  private let run: TextRunWrapper? = nil
  private var textPosition: UInt32 = 0
  private let isComplexText = false
  private let canUseSimplifiedTextMeasuring = false
  private var currentMetrics = SVGTextMetrics()
  private var totalWidth: Float32

  // Simple text only.
  private var simpleWidthIterator: WidthIteratorWrapper? = nil

  // Complex text only.
  private var complexStartToCurrentMetrics: SVGTextMetrics
}
