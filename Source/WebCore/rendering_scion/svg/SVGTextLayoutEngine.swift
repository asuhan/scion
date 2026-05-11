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
    self.layoutAttributes = layoutAttributes
    assert(!layoutAttributes.a.isEmpty)
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

  mutating func finishLayout() -> SVGTextFragmentMap {
    // After all text fragments are stored in their correpsonding SVGInlineTextBoxes, we can layout individual text chunks.
    // Chunk layouting is only performed for line layout boxes, not for path layout, where it has already been done.
    m_chunkLayoutBuilder.layoutTextChunks(
      m_lineLayoutBoxes[...], m_lineLayoutChunkStarts, m_fragmentMap)

    // Finalize transform matrices, after the chunk layout corrections have been applied, and all fragment x/y positions are finalized.
    if !m_lineLayoutBoxes.isEmpty {
      finalizeTransformMatrices(&m_lineLayoutBoxes)
    }

    if !m_pathLayoutBoxes.isEmpty {
      finalizeTransformMatrices(&m_pathLayoutBoxes)
    }

    return m_fragmentMap
  }

  private mutating func updateCharacterPositionIfNeeded(_ x: inout Float32, _ y: inout Float32) {
    if m_inPathLayout {
      return
    }

    // Replace characters x/y position, with the current text position plus any
    // relative adjustments, if it doesn't specify an absolute position itself.
    if SVGTextLayoutAttributes.isEmptyValue(x) {
      x = m_x + m_dx
    }

    if SVGTextLayoutAttributes.isEmptyValue(y) {
      y = m_y + m_dy
    }

    m_dx = 0
    m_dy = 0
  }

  private mutating func updateCurrentTextPosition(x: Float32, y: Float32, glyphAdvance: Float32) {
    // Update current text position after processing the character.
    if m_isVerticalText {
      m_x = x
      m_y = y + glyphAdvance
    } else {
      m_x = x + glyphAdvance
      m_y = y
    }
  }

  private mutating func updateRelativePositionAdjustmentsIfNeeded(_ dx: Float32, _ dy: Float32) {
    // Update relative positioning information.
    if SVGTextLayoutAttributes.isEmptyValue(dx) && SVGTextLayoutAttributes.isEmptyValue(dy) {
      return
    }

    var dx = dx
    if SVGTextLayoutAttributes.isEmptyValue(dx) {
      dx = 0
    }
    var dy = dy
    if SVGTextLayoutAttributes.isEmptyValue(dy) {
      dy = 0
    }

    if m_inPathLayout {
      if m_isVerticalText {
        m_dx += dx
        m_dy = dy
      } else {
        m_dx = dx
        m_dy += dy
      }

      return
    }

    m_dx = dx
    m_dy = dy
  }

  private mutating func recordTextFragment(
    _ textBox: InlineIterator.SVGTextBoxIterator, _ textMetricsValues: ArraySlice<SVGTextMetrics>
  ) {
    assert(m_currentTextFragment.length == 0)
    assert(m_visualMetricsListOffset > 0)

    // Figure out length of fragment.
    m_currentTextFragment.length = m_visualCharacterOffset - m_currentTextFragment.characterOffset

    // Figure out fragment metrics.
    let lastCharacterMetrics = textMetricsValues[Int(m_visualMetricsListOffset - 1)]
    m_currentTextFragment.width = lastCharacterMetrics.width
    m_currentTextFragment.height = lastCharacterMetrics.height

    if m_currentTextFragment.length > 1 {
      // SVGTextLayoutAttributesBuilder assures that the length of the range is equal to the sum of the individual lengths of the glyphs.
      var length: Float32 = 0
      if m_isVerticalText {
        for textMetricsValue in textMetricsValues[
          Int(m_currentTextFragment.metricsListOffset)..<Int(m_visualMetricsListOffset)]
        {
          length += textMetricsValue.height
        }
        m_currentTextFragment.height = length
      } else {
        for textMetricsValue in textMetricsValues[
          Int(m_currentTextFragment.metricsListOffset)..<Int(m_visualMetricsListOffset)]
        {
          length += textMetricsValue.width
        }
        m_currentTextFragment.width = length
      }
    }

    let key = InlineIterator.SVGTextBox.Key(
      chunk: textBox.get().renderer(), start: textBox.get().start())
    let fragments = m_fragmentMap.ensure(key, { () in return SVGTextFragmentArrayRef() }).value!

    fragments.a.append(m_currentTextFragment)
    m_currentTextFragment = SVGTextFragment()
  }

  private func parentDefinesTextLength(_ parent: RenderObjectWrapper) -> Bool {
    var currentParent: RenderObjectWrapper? = parent
    while currentParent != nil {
      if let textContentElement = SVGTextContentElementWrapper.elementFromRenderer(currentParent) {
        let lengthContext = SVGLengthContext(context: textContentElement)
        if textContentElement.lengthAdjust() == .SVGLengthAdjustSpacing
          && textContentElement.specifiedTextLength().value(lengthContext) > 0
        {
          return true
        }
      }

      if currentParent!.isRenderSVGText() {
        return false
      }

      currentParent = currentParent!.parent()
    }

    fatalError("Not reached")
  }

  private mutating func layoutTextOnLineOrPath(
    _ textBox: InlineIterator.SVGTextBoxIterator, _ text: RenderSVGInlineTextWrapper,
    _ style: RenderStyleWrapper
  ) {
    if m_inPathLayout && m_textPath.isEmpty() {
      return
    }

    let textParent = text.parent()!
    let lengthContext = textParent.element() as! SVGElementWrapper

    let definesTextLength = parentDefinesTextLength(textParent)

    let svgStyle = style.svgStyle()

    m_visualMetricsListOffset = 0
    m_visualCharacterOffset = 0

    let visualMetricsValues = text.layoutAttributes().textMetricsValues()
    assert(!visualMetricsValues.a.isEmpty)

    let upconvertedCharacters = StringWrapperView(s: text.text()).upconvertedCharacters()
    let characters = upconvertedCharacters.uchars
    let font = style.fontCascade()

    var spacingLayout = SVGTextLayoutEngineSpacing(font)
    let baselineLayout = SVGTextLayoutEngineBaseline(font)

    var didStartTextFragment = false
    var applySpacingToNextCharacter = false

    var lastAngle: Float32 = 0
    var baselineShift = baselineLayout.calculateBaselineShift(svgStyle, lengthContext)
    baselineShift -= baselineLayout.calculateAlignmentBaselineShift(m_isVerticalText, text)

    // Main layout algorithm.
    while true {
      // Find the start of the current text box in this list, respecting ligatures.
      var visualMetrics = SVGTextMetrics(.SkippedSpaceMetrics)
      if !currentVisualCharacterMetrics(textBox.get(), visualMetricsValues.a[...], &visualMetrics) {
        break
      }

      if visualMetrics.isEmpty() {
        advanceToNextVisualCharacter(visualMetrics)
        continue
      }

      var (isValid, logicalAttributes) = currentLogicalCharacterAttributes()
      if !isValid {
        break
      }

      assert(logicalAttributes != nil)
      var logicalMetrics = SVGTextMetrics(.SkippedSpaceMetrics)
      if !currentLogicalCharacterMetrics(&logicalAttributes!, &logicalMetrics) {
        break
      }

      let characterDataMap = logicalAttributes!.characterDataMap()
      let data = characterDataMap.m[m_logicalCharacterOffset + 1] ?? SVGCharacterData()

      var x = data.x
      var y = data.y
      let previousBoxOnLine = textBox.get().previousOnLine()

      // If we start a new chunk following an chunk that had a textLength set, use that
      // textLength to determine the chunk start position, instead of glyph advance values.
      let moveToExpectedChunkStartPositionIfNeeded = { [self] () in
        if m_inPathLayout || !m_lastChunkHasTextLength || !previousBoxOnLine.bool() {
          return
        }

        if m_isVerticalText {
          if !SVGTextLayoutAttributes.isEmptyValue(y) {
            return
          }
        } else if !SVGTextLayoutAttributes.isEmptyValue(x) {
          return
        }

        guard
          let textContentElement = SVGTextContentElementWrapper.elementFromRenderer(
            previousBoxOnLine.get().renderer())
        else { return }

        let lengthContext = SVGLengthContext(context: textContentElement)
        let specifiedTextLength = textContentElement.specifiedTextLength().value(lengthContext)

        if m_lastChunkIsVerticalText {
          y = m_lastChunkStartPosition + specifiedTextLength
        } else {
          x = m_lastChunkStartPosition + specifiedTextLength
        }
      }

      let startsNewTextChunk = { () in
        // If we're at a position that could start a new text chunk, but doesn't for intrinsic reasons (no x/y information specified for the
        // current character), check further if there are other conditions met that enforce a new text chunk -- e.g. previous sibiling on the
        // same line specified 'textLength' (consider: <text><tspan textLength="100">AB</tspan> <tspan dy="1em">...
        // The space character is not allowed to be part of the 'AB' text chunk -- there is not explicit x/y given for the space character
        // but because of the textLength attribute, we have to keep the space in a separated chunk, and position it such that it renders
        // after the user-specified textLength.
        if logicalAttributes!.context().characterStartsNewTextChunk(m_logicalCharacterOffset) {
          return true
        }

        // If we encounter an InlineTextBox that follows an InlineFlowBox with specified textLength,
        // and if the InlineTextBox content is not positioned by explicit x/y attributes, then we have
        // to correct the position of the InlineTextBox, to account for the textLength adjustments
        // that will be applied on chunk-level in the next SVG text layout phase. Failing to do so,
        // will lay out the remaining content at the nominal position, as if no textLength was given.
        if m_lastChunkHasTextLength && previousBoxOnLine.bool() {
          return true
        }

        return false
      }()

      // When we've advanced to the box start offset, determine using the original x/y values
      // whether this character starts a new text chunk before doing any further processing.
      if m_visualCharacterOffset == textBox.get().start() {
        moveToExpectedChunkStartPositionIfNeeded()
        if startsNewTextChunk {
          m_lineLayoutChunkStarts.add(
            InlineIterator.SVGTextBox.Key(
              chunk: textBox.get().renderer(), start: textBox.get().start()))
        }
      }

      var angle = SVGTextLayoutAttributes.isEmptyValue(data.rotate) ? 0 : data.rotate

      // Calculate glyph orientation angle.
      let currentCharacter = characters[Int(m_visualCharacterOffset)]
      let orientationAngle = baselineLayout.calculateGlyphOrientationAngle(
        m_isVerticalText, svgStyle, currentCharacter)

      // Calculate glyph advance & x/y orientation shifts.
      let glyphAdvanceAndOrientation = baselineLayout.calculateGlyphAdvanceAndOrientation(
        m_isVerticalText, visualMetrics, orientationAngle)
      let glyphAdvance = glyphAdvanceAndOrientation.advance
      var xOrientationShift = glyphAdvanceAndOrientation.xOrientationShift
      var yOrientationShift = glyphAdvanceAndOrientation.yOrientationShift

      // Assign current text position to x/y values, if needed.
      updateCharacterPositionIfNeeded(&x, &y)

      // Apply dx/dy value adjustments to current text position, if needed.
      updateRelativePositionAdjustmentsIfNeeded(data.dx, data.dy)

      // Calculate CSS 'letter-spacing' and 'word-spacing' for next character, if needed.
      let spacing = spacingLayout.calculateCSSSpacing(currentCharacter)

      var textPathOffset: Float32 = 0
      if m_inPathLayout {
        let scaledGlyphAdvance = glyphAdvance * m_textPathScaling
        if m_isVerticalText {
          // If there's an absolute y position available, it marks the beginning of a new position along the path.
          if !SVGTextLayoutAttributes.isEmptyValue(y) {
            m_textPathCurrentOffset = y + m_textPathStartOffset
          }

          m_textPathCurrentOffset += m_dy
          m_dy = 0

          // Apply dx/dy correction and setup translations that move to the glyph midpoint.
          xOrientationShift += m_dx + baselineShift
          yOrientationShift -= scaledGlyphAdvance / 2
        } else {
          // If there's an absolute x position available, it marks the beginning of a new position along the path.
          if !SVGTextLayoutAttributes.isEmptyValue(x) {
            m_textPathCurrentOffset = x + m_textPathStartOffset
          }

          m_textPathCurrentOffset += m_dx
          m_dx = 0

          // Apply dx/dy correction and setup translations that move to the glyph midpoint.
          xOrientationShift -= scaledGlyphAdvance / 2
          yOrientationShift += m_dy - baselineShift
        }

        // Calculate current offset along path.
        textPathOffset = m_textPathCurrentOffset + scaledGlyphAdvance / 2

        // Move to next character.
        m_textPathCurrentOffset +=
          scaledGlyphAdvance + m_textPathSpacing + spacing * m_textPathScaling

        // Skip character, if we're before the path.
        if textPathOffset < 0 {
          advanceToNextLogicalCharacter(logicalMetrics)
          advanceToNextVisualCharacter(visualMetrics)
          continue
        }

        // Stop processing, if the next character lies behind the path.
        if textPathOffset > m_textPathLength {
          break
        }

        let traversalState = m_textPath.traversalStateAtLength(textPathOffset)
        assert(traversalState.success())

        let point = traversalState.current()
        x = point.x
        y = point.y

        angle = traversalState.normalAngle()

        // For vertical text on path, the actual angle has to be rotated 90 degrees anti-clockwise, not the orientation angle!
        if m_isVerticalText {
          angle -= 90
        }
      } else {
        // Apply all previously calculated shift values.
        if m_isVerticalText {
          x += baselineShift
        } else {
          y -= baselineShift
        }

        x += m_dx
        y += m_dy
      }

      // Remember the position / direction of the start position of the new text chunk.
      if startsNewTextChunk {
        m_lastChunkStartPosition = m_isVerticalText ? y : x
        m_lastChunkIsVerticalText = m_isVerticalText
        m_lastChunkHasTextLength = definesTextLength
      }

      // Determine whether we have to start a new fragment.
      let shouldStartNewFragment =
        m_dx != 0 || m_dy != 0 || m_isVerticalText || m_inPathLayout || angle != 0
        || angle != lastAngle
        || orientationAngle != 0 || applySpacingToNextCharacter || definesTextLength

      // If we already started a fragment, close it now.
      if didStartTextFragment && shouldStartNewFragment {
        applySpacingToNextCharacter = false
        recordTextFragment(textBox, visualMetricsValues.a[...])
      }

      // Eventually start a new fragment, if not yet done.
      if !didStartTextFragment || shouldStartNewFragment {
        assert(m_currentTextFragment.characterOffset == 0)
        assert(m_currentTextFragment.length == 0)

        didStartTextFragment = true
        m_currentTextFragment.characterOffset = m_visualCharacterOffset
        m_currentTextFragment.metricsListOffset = m_visualMetricsListOffset
        m_currentTextFragment.x = x
        m_currentTextFragment.y = y

        // Build fragment transformation.
        if angle != 0 {
          m_currentTextFragment.transform.rotate(Float64(angle))
        }

        if xOrientationShift != 0 || yOrientationShift != 0 {
          m_currentTextFragment.transform.translate(
            Float64(xOrientationShift), Float64(yOrientationShift))
        }

        if orientationAngle != 0 {
          m_currentTextFragment.transform.rotate(Float64(orientationAngle))
        }

        m_currentTextFragment.isTextOnPath = m_inPathLayout && m_textPathScaling != 1
        if m_currentTextFragment.isTextOnPath {
          if m_isVerticalText {
            m_currentTextFragment.lengthAdjustTransform.scaleNonUniform(
              1, Float64(m_textPathScaling))
          } else {
            m_currentTextFragment.lengthAdjustTransform.scaleNonUniform(
              Float64(m_textPathScaling), 1)
          }
        }
      }

      // Update current text position, after processing of the current character finished.
      if m_inPathLayout {
        updateCurrentTextPosition(x: x, y: y, glyphAdvance: glyphAdvance)
      } else {
        // Apply CSS 'letter-spacing' and 'word-spacing' to next character, if needed.
        if spacing != 0 {
          applySpacingToNextCharacter = true
        }

        var xNew = x - m_dx
        var yNew = y - m_dy

        if m_isVerticalText {
          xNew -= baselineShift
        } else {
          yNew += baselineShift
        }

        updateCurrentTextPosition(x: xNew, y: yNew, glyphAdvance: glyphAdvance + spacing)
      }

      advanceToNextLogicalCharacter(logicalMetrics)
      advanceToNextVisualCharacter(visualMetrics)
      lastAngle = angle
    }

    if !didStartTextFragment {
      return
    }

    // Close last open fragment, if needed.
    recordTextFragment(textBox, visualMetricsValues.a[...])
  }

  private func finalizeTransformMatrices(_ textBoxes: inout [InlineIterator.SVGTextBoxIterator]) {
    if textBoxes.isEmpty {
      return
    }

    for textBox in textBoxes {
      let textBoxTransformation = m_chunkLayoutBuilder.transformationForTextBox(textBox)
      if textBoxTransformation.isIdentity() {
        continue
      }

      let key = InlineIterator.SVGTextBox.Key(
        chunk: textBox.get().renderer(), start: textBox.get().start())
      if m_fragmentMap.contains(key) {
        for fragment in m_fragmentMap.get(key).a {
          assert(fragment.lengthAdjustTransform.isIdentity())
          fragment.lengthAdjustTransform = textBoxTransformation
        }
      }
    }

    textBoxes.removeAll()
  }

  private mutating func currentLogicalCharacterAttributes() -> (Bool, SVGTextLayoutAttributes?) {
    if m_layoutAttributesPosition == layoutAttributes.a.count {
      return (false, nil)
    }

    var logicalAttributes = layoutAttributes.a[Int(m_layoutAttributesPosition)]

    if m_logicalCharacterOffset != logicalAttributes.context().text().length() {
      return (true, logicalAttributes)
    }

    m_layoutAttributesPosition += 1
    if m_layoutAttributesPosition == layoutAttributes.a.count {
      return (false, logicalAttributes)
    }

    logicalAttributes = layoutAttributes.a[Int(m_layoutAttributesPosition)]
    m_logicalMetricsListOffset = 0
    m_logicalCharacterOffset = 0
    return (true, logicalAttributes)
  }

  private mutating func currentLogicalCharacterMetrics(
    _ logicalAttributes: inout SVGTextLayoutAttributes, _ logicalMetrics: inout SVGTextMetrics
  )
    -> Bool
  {
    var textMetricsValues = logicalAttributes.textMetricsValues()
    var textMetricsSize = textMetricsValues.a.count
    while true {
      if m_logicalMetricsListOffset == textMetricsSize {
        var isValid = false
        var newLogicalAttributes: SVGTextLayoutAttributes? = nil
        (isValid, newLogicalAttributes) = currentLogicalCharacterAttributes()
        if !isValid {
          return false
        }
        logicalAttributes = newLogicalAttributes!

        textMetricsValues = logicalAttributes.textMetricsValues()
        textMetricsSize = textMetricsValues.a.count
        continue
      }

      assert(textMetricsSize != 0)
      assert(m_logicalMetricsListOffset < textMetricsSize)
      logicalMetrics = textMetricsValues.a[Int(m_logicalMetricsListOffset)]
      if logicalMetrics.isEmpty() || (logicalMetrics.width == 0 && logicalMetrics.height == 0) {
        advanceToNextLogicalCharacter(logicalMetrics)
        continue
      }

      // Stop if we found the next valid logical text metrics object.
      return true
    }

    fatalError("Not reached")
  }

  private mutating func currentVisualCharacterMetrics(
    _ textBox: InlineIterator.SVGTextBox, _ visualMetricsValues: ArraySlice<SVGTextMetrics>,
    _ visualMetrics: inout SVGTextMetrics
  ) -> Bool {
    assert(!visualMetricsValues.isEmpty)
    let textMetricsSize = visualMetricsValues.count
    let boxStart = textBox.start()
    let boxLength = textBox.length()

    while m_visualMetricsListOffset < textMetricsSize {
      // Advance to text box start location.
      if m_visualCharacterOffset < boxStart {
        advanceToNextVisualCharacter(visualMetricsValues[Int(m_visualMetricsListOffset)])
        continue
      }

      // Stop if we've finished processing this text box.
      if m_visualCharacterOffset >= boxStart + boxLength {
        return false
      }

      visualMetrics = visualMetricsValues[Int(m_visualMetricsListOffset)]
      return true
    }

    return false
  }

  private mutating func advanceToNextLogicalCharacter(_ logicalMetrics: SVGTextMetrics) {
    m_logicalMetricsListOffset += 1
    m_logicalCharacterOffset += logicalMetrics.length
  }

  private mutating func advanceToNextVisualCharacter(_ visualMetrics: SVGTextMetrics) {
    m_visualMetricsListOffset += 1
    m_visualCharacterOffset += visualMetrics.length
  }

  let layoutAttributes: RenderSVGTextWrapper.LayoutAttributesRef

  private var m_lineLayoutBoxes: [InlineIterator.SVGTextBoxIterator] = []
  private var m_pathLayoutBoxes: [InlineIterator.SVGTextBoxIterator] = []

  // Output.
  private let m_fragmentMap = HashMap<InlineIterator.SVGTextBox.Key, SVGTextFragmentArrayRef>()

  private var m_chunkLayoutBuilder = SVGTextChunkBuilder()
  private let m_lineLayoutChunkStarts = HashSet<InlineIterator.SVGTextBox.Key>()

  private var m_currentTextFragment = SVGTextFragment()
  private var m_layoutAttributesPosition: UInt32 = 0
  private var m_logicalCharacterOffset: UInt32 = 0
  private var m_logicalMetricsListOffset: UInt32 = 0
  private var m_visualCharacterOffset: UInt32 = 0
  private var m_visualMetricsListOffset: UInt32 = 0
  private var m_x: Float32 = 0
  private var m_y: Float32 = 0
  private var m_dx: Float32 = 0
  private var m_dy: Float32 = 0
  private var m_lastChunkStartPosition: Float32 = 0
  private var m_lastChunkHasTextLength = false
  private var m_lastChunkIsVerticalText = false
  private var m_isVerticalText = false
  private var m_inPathLayout = false

  // Text on path layout
  private var m_textPath = PathWrapper()
  private var m_textPathLength: Float32 = 0
  private var m_textPathStartOffset: Float32 = 0
  private var m_textPathCurrentOffset: Float32 = 0
  private var m_textPathSpacing: Float32 = 0
  private var m_textPathScaling: Float32 = 1
}
