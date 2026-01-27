/*
 * Copyright (C) Research In Motion Limited 2010-2012. All rights reserved.
 * Copyright (C) Apple 2023-2024. All rights reserved.
 * Copyright (C) Google 2014-2017. All rights reserved.
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

// SVGTextLayoutEngine performs the second layout phase for SVG text.
//
// The InlineBox tree was created, containing the text chunk information, necessary to apply
// certain SVG specific text layout properties (text-length adjustments and text-anchor).
// The second layout phase uses the SVGTextLayoutAttributes stored in the individual
// RenderSVGInlineText renderers to compute the final positions for each character
// which are stored in the SVGInlineTextBox objects.

struct SVGTextLayoutEngine {
  init(_ layoutAttributes: RenderSVGTextWrapper.LayoutAttributesRef) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func beginTextPathLayout(
    _ textPath: RenderSVGTextPath, _ lineLayout: inout SVGTextLayoutEngine
  ) {
    m_inPathLayout = true

    m_textPath = textPath.layoutPath()
    if m_textPath.isEmpty() {
      return
    }

    let startOffset = textPath.startOffset()
    m_textPathLength = m_textPath.length()

    if textPath.startOffset().lengthType == .Percentage {
      m_textPathStartOffset = startOffset.valueAsPercentage() * m_textPathLength
    } else {
      m_textPathStartOffset = startOffset.valueInSpecifiedUnits
      if let targetElement = textPath.targetElement() {
        // FIXME: A value of zero is valid. Need to differentiate this case from being unspecified.
        let pathLength = targetElement.pathLength()
        if pathLength != 0 {
          m_textPathStartOffset *= m_textPathLength / pathLength
        }
      }
    }

    lineLayout.m_chunkLayoutBuilder.buildTextChunks(
      lineLayout.m_lineLayoutBoxes[...], lineLayout.m_lineLayoutChunkStarts,
      lineLayout.m_fragmentMap)

    // Handle text-anchor as additional start offset for text paths.
    m_textPathStartOffset += lineLayout.m_chunkLayoutBuilder.totalAnchorShift()
    m_textPathCurrentOffset = m_textPathStartOffset

    // Eventually handle textLength adjustments.
    guard let textContentElement = SVGTextContentElementWrapper.elementFromRenderer(textPath) else {
      return
    }

    let lengthContext = SVGLengthContext(context: textContentElement)
    let desiredTextLength = textContentElement.specifiedTextLength().value(lengthContext)
    if desiredTextLength == 0 {
      return
    }

    let totalLength = lineLayout.m_chunkLayoutBuilder.totalLength()
    let totalCharacters = lineLayout.m_chunkLayoutBuilder.totalCharacters()

    if textContentElement.lengthAdjust() == .SVGLengthAdjustSpacing {
      if totalCharacters > 1 {
        m_textPathSpacing = (desiredTextLength - totalLength) / Float32(totalCharacters - 1)
      }
    } else {
      m_textPathScaling = desiredTextLength / totalLength
    }
  }

  mutating func endTextPathLayout() {
    m_inPathLayout = false
    m_textPath = PathWrapper()
    m_textPathLength = 0
    m_textPathStartOffset = 0
    m_textPathCurrentOffset = 0
    m_textPathSpacing = 0
    m_textPathScaling = 1
  }

  mutating func layoutInlineTextBox(_ textBox: InlineIterator.SVGTextBoxIterator) {
    let text = textBox.get().renderer()
    assert(text.parent()?.element()?.isSVGElement() ?? false)

    let style = text.style()

    m_isVerticalText = style.isVerticalWritingMode()
    layoutTextOnLineOrPath(textBox, text, style)

    if m_inPathLayout {
      m_pathLayoutBoxes.append(textBox)
      return
    }

    m_lineLayoutBoxes.append(textBox)
  }

  func finishLayout() -> SVGTextFragmentMap {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func layoutTextOnLineOrPath(
    _ textBox: InlineIterator.SVGTextBoxIterator, _ text: RenderSVGInlineTextWrapper,
    _ style: RenderStyleWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let layoutAttributes: RenderSVGTextWrapper.LayoutAttributesRef

  private var m_lineLayoutBoxes: [InlineIterator.SVGTextBoxIterator] = []
  private var m_pathLayoutBoxes: [InlineIterator.SVGTextBoxIterator] = []

  // Output.
  private let m_fragmentMap = HashMap<InlineIterator.SVGTextBox.Key, [SVGTextFragment]>()

  private var m_chunkLayoutBuilder: SVGTextChunkBuilder
  private let m_lineLayoutChunkStarts: HashSet<InlineIterator.SVGTextBox.Key>

  private var m_isVerticalText = false
  private var m_inPathLayout = false

  // Text on path layout
  private var m_textPath: PathWrapper
  private var m_textPathLength: Float32 = 0
  private var m_textPathStartOffset: Float32 = 0
  private var m_textPathCurrentOffset: Float32 = 0
  private var m_textPathSpacing: Float32 = 0
  private var m_textPathScaling: Float32 = 1
}
