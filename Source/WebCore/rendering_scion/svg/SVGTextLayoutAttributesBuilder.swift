/*
 * Copyright (C) Research In Motion Limited 2010-2012. All rights reserved.
 * Copyright (C) 2024 Apple Inc. All rights reserved.
 * Copyright (C) 2015 Google Inc. All rights reserved.
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

// SVGTextLayoutAttributesBuilder performs the first layout phase for SVG text.
//
// It extracts the x/y/dx/dy/rotate values from the SVGTextPositioningElements in the DOM.
// These values are propagated to the corresponding RenderSVGInlineText renderers.
// The first layout phase only extracts the relevant information needed in RenderBlockLineLayout
// to create the InlineBox tree based on text chunk boundaries & BiDi information.
// The second layout phase is carried out by SVGTextLayoutEngine.

private let space = UChar(Character(" ").asciiValue!)

private func processRenderSVGInlineText(
  _ text: RenderSVGInlineTextWrapper, _ atCharacter: inout UInt32, lastCharacterWasSpace: inout Bool
) {
  let string = text.text()
  let length = string.length()
  if text.style().whiteSpaceCollapse() == .Preserve {
    atCharacter += length
    return
  }

  // FIXME: This is not a complete whitespace collapsing implementation; it doesn't handle newlines or tabs.
  for i in 0..<length {
    let character = string[i]
    if character == space && lastCharacterWasSpace {
      continue
    }

    lastCharacterWasSpace = character == space
    atCharacter += 1
  }
}

struct SVGTextLayoutAttributesBuilder: ~Copyable {
  init() { self.textLength = 0 }

  @discardableResult
  mutating func buildLayoutAttributesForForSubtree(_ textRoot: RenderSVGTextWrapper) -> Bool {
    characterDataMap.m.removeAll()

    if textPositions.isEmpty {
      textLength = 0
      var lastCharacterWasSpace = true
      collectTextPositioningElements(textRoot, &lastCharacterWasSpace)
    }

    if textLength == 0 {
      return false
    }

    buildCharacterDataMap(textRoot)
    metricsBuilder.buildMetricsAndLayoutAttributes(textRoot, nil, characterDataMap)
    return true
  }

  mutating func buildLayoutAttributesForTextRenderer(_ text: RenderSVGInlineTextWrapper) {
    guard let textRoot = RenderSVGTextWrapper.locateRenderSVGTextAncestor(start: text) else {
      return
    }

    if textPositions.isEmpty {
      characterDataMap.m.removeAll()

      textLength = 0
      var lastCharacterWasSpace = true
      collectTextPositioningElements(textRoot, &lastCharacterWasSpace)

      if textLength == 0 {
        return
      }

      buildCharacterDataMap(textRoot)
    }

    metricsBuilder.buildMetricsAndLayoutAttributes(textRoot, text, characterDataMap)
  }

  func rebuildMetricsForSubtree(_ text: RenderSVGTextWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Invoked whenever the underlying DOM tree changes, so that m_textPositions is rebuild.
  func clearTextPositioningElements() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func numberOfTextPositioningElements() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private struct TextPosition {
    init(
      _ newElement: SVGTextPositioningElementWrapper? = nil, _ newStart: UInt32 = 0,
      _ newLength: UInt32 = 0
    ) {
      element = newElement
      start = newStart
      length = newLength
    }

    let element: SVGTextPositioningElementWrapper?
    let start: UInt32
    var length: UInt32
  }

  private mutating func buildCharacterDataMap(_ textRoot: RenderSVGTextWrapper) {
    let outermostTextElement = SVGTextPositioningElementWrapper.elementFromRenderer(textRoot)!

    // Grab outermost <text> element value lists and insert them in the character data map.
    let wholeTextPosition = TextPosition(outermostTextElement, 0, textLength)
    fillCharacterDataMap(wholeTextPosition)

    // Handle x/y default attributes.
    var characterData = characterDataMap.m[1]
    if characterData == nil {
      var data = SVGCharacterData()
      data.x = 0
      data.y = 0
      characterDataMap.m[1] = data
    } else {
      if SVGTextLayoutAttributes.isEmptyValue(characterData!.x) {
        characterData!.x = 0
      }
      if SVGTextLayoutAttributes.isEmptyValue(characterData!.y) {
        characterData!.y = 0
      }
      characterDataMap.m[1] = characterData!
    }

    // Fill character data map using child text positioning elements in top-down order.
    for textPosition in textPositions {
      fillCharacterDataMap(textPosition)
    }
  }

  private mutating func collectTextPositioningElements(
    _ start: RenderBoxModelObjectWrapper, _ lastCharacterWasSpace: inout Bool
  ) {
    assert(!(start is RenderSVGTextWrapper) || textPositions.isEmpty)

    for child: RenderObjectWrapper in childrenOfType(parent: start) {
      if let inlineText = child as? RenderSVGInlineTextWrapper {
        processRenderSVGInlineText(
          inlineText, &textLength, lastCharacterWasSpace: &lastCharacterWasSpace)
        continue
      }

      guard let inlineChild = child as? RenderSVGInlineWrapper else { continue }

      let element = SVGTextPositioningElementWrapper.elementFromRenderer(inlineChild)

      let atPosition = textPositions.count
      if element != nil {
        textPositions.append(TextPosition(element, textLength))
      }

      collectTextPositioningElements(inlineChild, &lastCharacterWasSpace)

      if element == nil {
        continue
      }

      // Update text position, after we're back from recursion.
      assert(textPositions[atPosition].length == 0)
      textPositions[atPosition].length = textLength - textPositions[atPosition].start
    }
  }

  private func fillCharacterDataMap(_ position: TextPosition) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  class SVGCharacterDataMapRef {
    var m: SVGCharacterDataMap = [:]
  }

  private var textLength: UInt32
  private var textPositions: [TextPosition] = []
  private var characterDataMap: SVGCharacterDataMapRef = SVGCharacterDataMapRef()
  private let metricsBuilder = SVGTextMetricsBuilder()
}
