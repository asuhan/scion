/*
 * Copyright (C) 2023 Apple Inc. All rights reserved.
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

func halfOfAFullWidthCharacter(annotationBox: BoxWrapper) -> InlineLayoutUnit {
  return annotationBox.style.computedFontSize() / 2
}

func baseContentIndex(rubyBaseStart: UInt64, boxes: InlineDisplay.Boxes) -> UInt64 {
  var baseContentIndex = rubyBaseStart + 1
  if boxes[Int(baseContentIndex)].layoutBox.isRubyAnnotationBox() {
    baseContentIndex += 1
  }
  return baseContentIndex
}

func annotationMarginBoxVisualRect(
  annotationBox: BoxWrapper, lineHeight: InlineLayoutUnit,
  inlineFormattingContext: InlineFormattingContext
) -> InlineRect {
  let marginBoxLogicalRect = InlineRect(
    rect: BoxGeometry.marginBoxRect(
      box: inlineFormattingContext.geometryForBox(layoutBox: annotationBox)
    ).FloatRect())
  let rootStyle = inlineFormattingContext.root().style
  if rootStyle.isHorizontalWritingMode() {
    return marginBoxLogicalRect
  }
  var visualTopLeft = marginBoxLogicalRect.topLeft().transposedPoint()
  if rootStyle.isFlippedBlocksWritingMode() {
    return InlineRect(topLeft: visualTopLeft, size: marginBoxLogicalRect.size().transposedSize())
  }
  visualTopLeft.move(dx: lineHeight - marginBoxLogicalRect.height(), dy: 0)
  return InlineRect(topLeft: visualTopLeft, size: marginBoxLogicalRect.size().transposedSize())
}

func baseLogicalWidthFromRubyBaseEnd(
  rubyBaseLayoutBox: BoxWrapper, lineRuns: Line.RunList,
  candidateRuns: InlineContentBreaker.ContinuousContent.RunList
) -> InlineLayoutUnit {
  assert(rubyBaseLayoutBox.isRubyBase())
  // Canidate content is supposed to hold the base content and in case of soft wrap opportunities, line may have some base content too.
  var baseLogicalWidth = InlineLayoutUnit()
  var hasSeenRubyBaseStart = false
  for candidateRun in candidateRuns.reversed() {
    let inlineItem = candidateRun.inlineItem
    if inlineItem.isInlineBoxStart() && inlineItem.layoutBox === rubyBaseLayoutBox {
      hasSeenRubyBaseStart = true
      break
    }
    baseLogicalWidth += candidateRun.contentWidth
  }
  if hasSeenRubyBaseStart {
    return baseLogicalWidth
  }
  // Let's check the line for the rest of the base content.
  for lineRun in lineRuns.reversed() {
    if (lineRun.isInlineBoxStart() || lineRun.isLineSpanningInlineBoxStart())
      && lineRun.layoutBox === rubyBaseLayoutBox
    {
      break
    }
    baseLogicalWidth += lineRun.logicalWidth
  }
  return baseLogicalWidth
}

func annotationOverlapCheck(
  adjacentDisplayBox: InlineDisplay.Box, overhangingRect: InlineLayoutRect,
  lineLogicalHeight: InlineLayoutUnit, inlineFormattingContext: InlineFormattingContext
) -> Bool {
  // We are in the middle of a line, should not see any line breaks or ellipsis boxes here.
  assert(!adjacentDisplayBox.isEllipsis() && !adjacentDisplayBox.isRootInlineBox())
  // Skip empty content like <span></span>
  if adjacentDisplayBox.visualRectIgnoringBlockDirection().isEmpty() {
    return false
  }

  if adjacentDisplayBox.inkOverflow.intersects(other: overhangingRect) {
    return true
  }
  let adjacentLayoutBox = adjacentDisplayBox.layoutBox
  // Adjacent ruby may have overlapping annotation.
  if adjacentLayoutBox.isRubyBase() && adjacentLayoutBox.associatedRubyAnnotationBox() != nil {
    return annotationMarginBoxVisualRect(
      annotationBox: adjacentLayoutBox.associatedRubyAnnotationBox()!,
      lineHeight: lineLogicalHeight,
      inlineFormattingContext: inlineFormattingContext
    ).intersects(other: InlineRect(rect: overhangingRect))
  }
  return false
}

class RubyFormattingContext {
  static func canBreakBefore(character: UChar) -> Bool {
    let lineBreak = ULineBreak(
      rawValue: u_getIntPropertyValue(character: character, property: .UCHAR_LINE_BREAK))
    // UNICODE LINE BREAKING ALGORITHM
    // http://www.unicode.org/reports/tr14/
    // And Requirements for Japanese Text Layout, 3.1.7 Characters Not Starting a Line
    // https://www.w3.org/TR/jlreq/#characters_not_starting_a_line
    switch lineBreak {
    case .U_LB_NONSTARTER, .U_LB_CLOSE_PARENTHESIS, .U_LB_CLOSE_PUNCTUATION, .U_LB_EXCLAMATION,
      .U_LB_BREAK_SYMBOLS, .U_LB_INFIX_NUMERIC, .U_LB_ZWSPACE, .U_LB_WORD_JOINER:
      return false
    default:
      break
    }
    // Special care for Requirements for Japanese Text Layout
    switch character {
    case 0x2019,  // RIGHT SINGLE QUOTATION MARK
      0x201D,  // RIGHT DOUBLE QUOTATION MARK
      0x00BB,  // RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK
      0x2010,  // HYPHEN
      0x2013,  // EN DASH
      0x300C:  // LEFT CORNER BRACKET
      return false
    default:
      break
    }
    return true
  }

  static func canBreakAfter(character: UChar) -> Bool {
    // https://www.w3.org/TR/jlreq/#characters_not_ending_a_line
    switch character {
    case 0x2018,  // LEFT SINGLE QUOTATION MARK
      0x201C,  // LEFT DOUBLE QUOTATION MARK
      0x0028,  // LEFT PARENTHESIS
      0x3014,  // LEFT TORTOISE SHELL BRACKET
      0x005B,  // LEFT SQUARE BRACKET
      0x007B,  // LEFT CURLY BRACKET
      0x3008,  // LEFT ANGLE BRACKET
      0x300A,  // LEFT DOUBLE ANGLE BRACKET
      0x300C,  // LEFT CORNER BRACKET
      0x300E,  // LEFT WHITE CORNER BRACKET
      0x3010,  // LEFT BLACK LENTICULAR BRACKET
      0x2985,  // LEFT WHITE PARENTHESIS
      0x3018,  // LEFT WHITE TORTOISE SHELL BRACKET
      0x3016,  // LEFT WHITE LENTICULAR BRACKET
      0x00AB,  // LEFT-POINTING DOUBLE ANGLE QUOTATION MARK
      0x301D:  // REVERSED DOUBLE PRIME QUOTATION MARK
      return false
    default:
      break
    }
    return true
  }

  // Line building
  static func isAtSoftWrapOpportunity(previous: InlineItemWrapper, current: InlineItemWrapper)
    -> Bool
  {
    let previousLayoutBox = previous.layoutBox
    let currentLayoutBox = current.layoutBox
    assert(previousLayoutBox.isRubyInlineBox() || currentLayoutBox.isRubyInlineBox())

    if currentLayoutBox.isRuby() {
      assert(
        (!previous.isInlineBoxStart() && !previous.isInlineBoxEnd())
          || previous.layoutBox.isRubyInlineBox())

      if current.isInlineBoxStart() {
        // At the beginning of <ruby>.
        let leadingTextItem = previous as? InlineTextItemWrapper
        if leadingTextItem == nil {
          return true
        }
        if leadingTextItem!.length == 0 {
          // FIXME: This needs to know prior context.
          return true
        }
        let lastCharacter = leadingTextItem!.inlineTextBox().content[leadingTextItem!.end() - 1]
        return RubyFormattingContext.canBreakAfter(character: lastCharacter)
      }
      // Don't break between base end and <ruby> end.
      return false
    }

    if currentLayoutBox.isRubyBase() || previousLayoutBox.isRubyBase() {
      // There's always a soft wrap opportunity between two bases.
      return currentLayoutBox.isRubyBase() && previousLayoutBox.isRubyBase()
    }

    if previousLayoutBox.isRuby() {
      assert(
        (!current.isInlineBoxStart() && !current.isInlineBoxEnd()) || current.layoutBox.isRuby())

      if previous.isInlineBoxEnd() {
        // At the end of <ruby>
        let trailingTextItem = current as? InlineTextItemWrapper
        if trailingTextItem == nil {
          return true
        }
        if trailingTextItem!.length == 0 {
          // FIXME: This should be turned into one of those "can't decide it yet" cases.
          return true
        }
        let firstCharacter = trailingTextItem!.inlineTextBox().content[trailingTextItem!.start()]
        return RubyFormattingContext.canBreakBefore(character: firstCharacter)
      }
      // We should handled this case already when looking at current: base, previous: ruby.
      fatalError("Not reached")
    }

    fatalError("Not reached")
  }

  static func annotationBoxLogicalWidth(
    rubyBaseLayoutBox: BoxWrapper, inlineFormattingContext: InlineFormattingContext
  ) -> InlineLayoutUnit {
    assert(rubyBaseLayoutBox.isRubyBase())
    let annotationBox = rubyBaseLayoutBox.associatedRubyAnnotationBox()
    if annotationBox == nil {
      return InlineLayoutUnit()
    }

    inlineFormattingContext.integrationUtils!.layoutWithFormattingContextForBox(
      box: annotationBox!)

    return inlineFormattingContext.geometryForBox(layoutBox: annotationBox!).marginBoxWidth()
      .float()
  }

  static func baseEndAdditionalLogicalWidth(
    rubyBaseLayoutBox: BoxWrapper, lineRuns: Line.RunList,
    candidateRuns: InlineContentBreaker.ContinuousContent.RunList,
    inlineFormattingContext: InlineFormattingContext
  ) -> InlineLayoutUnit {
    assert(rubyBaseLayoutBox.isRubyBase())
    if hasInterlinearAnnotation(rubyBaseLayoutBox: rubyBaseLayoutBox) {
      // Base is supposed be at least as wide as the annotation is.
      // Let's adjust the inline box end width to accomodate such overflowing interlinear annotations.
      let rubyBaseContentWidth = baseLogicalWidthFromRubyBaseEnd(
        rubyBaseLayoutBox: rubyBaseLayoutBox, lineRuns: lineRuns, candidateRuns: candidateRuns)
      assert(rubyBaseContentWidth >= 0)
      return max(
        0,
        annotationBoxLogicalWidth(
          rubyBaseLayoutBox: rubyBaseLayoutBox, inlineFormattingContext: inlineFormattingContext)
          - rubyBaseContentWidth
      )
    }
    // While inter-character annotations don't participate in inline layout, they take up space.
    return annotationBoxLogicalWidth(
      rubyBaseLayoutBox: rubyBaseLayoutBox, inlineFormattingContext: inlineFormattingContext)
  }

  static func applyRubyAlign(line: Line, inlineFormattingContext: InlineFormattingContext)
    -> [BoxWrapper:
    InlineLayoutUnit]
  {
    var alignmentOffsetList: [BoxWrapper: InlineLayoutUnit] = [:]
    // https://drafts.csswg.org/css-ruby/#interlinear-inline
    // Within each base and annotation box, how the extra space is distributed when its content is narrower than
    // the measure of the box is specified by its ruby-align property.
    let runs = line.runs
    var index: UInt64 = 0
    while index < runs.count {
      let lineRun = runs[Int(index)]
      if lineRun.isInlineBoxStart() && lineRun.layoutBox.isRubyBase() {
        index = applyRubyAlignOnBaseContent(
          rubyBaseStart: index, line: line, alignmentOffsetList: &alignmentOffsetList,
          inlineFormattingContext: inlineFormattingContext)
      }
      index += 1
    }
    return alignmentOffsetList
  }

  typealias MaximumLayoutBoundsStretchMap = [ObjectIdentifier: InlineLevelBox.AscentAndDescent]

  // Line box building
  static func applyAnnotationContributionToLayoutBounds(
    lineBox: LineBox, inlineFormattingContext: InlineFormattingContext
  ) {
    // In order to ensure consistent spacing of lines, documents with ruby typically ensure that the line-height is
    // large enough to accommodate ruby between lines of text. Therefore, ordinarily, ruby annotation containers and ruby annotation
    // boxes do not contribute to the measured height of a line's inline contents;
    // line-height calculations are performed using only the ruby base container, exactly as if it were a normal inline.
    // However, if the line-height specified on the ruby container is less than the distance between the top of the top ruby annotation
    // container and the bottom of the bottom ruby annotation container, then additional leading is added on the appropriate side(s).
    var descentRubySet = MaximumLayoutBoundsStretchMap()
    for inlineLevelBox in lineBox.nonRootInlineLevelBoxes().reversed() {
      if !inlineLevelBox.isInlineBox() || !inlineLevelBox.layoutBox.isRubyBase() {
        continue
      }
      adjustLayoutBoundsAndStretchAncestorRubyBase(
        lineBox: lineBox, rubyBaseInlineBox: inlineLevelBox, descendantRubySet: &descentRubySet,
        inlineFormattingContext: inlineFormattingContext)
    }
  }

  static func baseEndAdditionalLogicalWidth(
    rubyBaseLayoutBox: BoxWrapper, baseDisplayBox: InlineDisplay.Box,
    baseContentWidth: InlineLayoutUnit,
    inlineFormattingContext: InlineFormattingContext
  ) -> InlineLayoutUnit {
    if !hasInterCharacterAnnotation(rubyBaseLayoutBox: rubyBaseLayoutBox) {
      // FIXME: We may want to include interlinear annotations here too so that applyAlignmentOffsetList would not need to initiate resizing (only moving base content).
      if baseContentWidth == 0 {
        return InlineLayoutUnit()
      }
      let annotationBox = rubyBaseLayoutBox.associatedRubyAnnotationBox()
      if annotationBox == nil {
        return InlineLayoutUnit()
      }
      let annotationBoxLogicalGeometry = inlineFormattingContext.geometryForBox(
        layoutBox: annotationBox!)
      return annotationBoxLogicalGeometry.marginBoxWidth().float()
    }
    // Note that intercharacter annotation stays vertical even when the ruby itself is vertical (which makes it look like interlinear).
    return annotationBoxLogicalWidth(
      rubyBaseLayoutBox: rubyBaseLayoutBox, inlineFormattingContext: inlineFormattingContext)
  }

  static func applyRubyAlignOnAnnotationBox(
    line: Line, spaceToDistribute: InlineLayoutUnit,
    inlineFormattingContext: InlineFormattingContext
  ) -> InlineLayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func rubyPosition(rubyBaseLayoutBox: BoxWrapper) -> RubyPosition {
    assert(rubyBaseLayoutBox.isRubyBase())
    let computedRubyPosition = rubyBaseLayoutBox.style.rubyPosition()
    if rubyBaseLayoutBox.style.isHorizontalWritingMode() {
      return computedRubyPosition
    }
    // inter-character: If the writing mode of the enclosing ruby container is vertical, this value has the same effect as over.
    return rubyBaseLayoutBox.style.isInterCharacterRubyPosition() ? .Over : computedRubyPosition
  }

  static func placeAnnotationBox(
    rubyBaseLayoutBox: BoxWrapper, rubyBaseMarginBoxLogicalRect: Rect,
    inlineFormattingContext: InlineFormattingContext
  ) -> InlineLayoutPoint {
    assert(rubyBaseLayoutBox.isRubyBase())
    let annotationBox = rubyBaseLayoutBox.associatedRubyAnnotationBox()
    if annotationBox == nil {
      fatalError("Not reached")
    }
    let annotationBoxLogicalGeometry = inlineFormattingContext.geometryForBox(
      layoutBox: annotationBox!)

    if hasInterlinearAnnotation(rubyBaseLayoutBox: rubyBaseLayoutBox) {
      // Move it over/under the base and make it border box positioned.
      let leftOffset = annotationBoxLogicalGeometry.marginStart()
      let topOffset =
        RubyFormattingContext.rubyPosition(rubyBaseLayoutBox: rubyBaseLayoutBox) == .Over
        ? -annotationBoxLogicalGeometry.marginBoxHeight() : rubyBaseMarginBoxLogicalRect.height()
      var logicalTopLeft = rubyBaseMarginBoxLogicalRect.topLeft()
      logicalTopLeft.move(s: LayoutSizeWrapper(width: leftOffset, height: topOffset))
      return logicalTopLeft.FloatPoint()
    }
    // Inter-character annotation box is stretched to the size of the base content box and vertically centered.
    let annotationContentBoxLogicalHeight = annotationBoxLogicalGeometry.contentBoxHeight()
    let annotationBorderTop = annotationBoxLogicalGeometry.borderBefore()
    let borderBoxRight =
      rubyBaseMarginBoxLogicalRect.right() - annotationBoxLogicalGeometry.marginBoxWidth()
      + annotationBoxLogicalGeometry.marginStart()
    return InlineLayoutPoint(
      x: borderBoxRight.float(),
      y: (rubyBaseMarginBoxLogicalRect.top()
        + ((rubyBaseMarginBoxLogicalRect.height() - annotationContentBoxLogicalHeight) / 2)
        - annotationBorderTop).float()
    )
  }

  static func sizeAnnotationBox(
    rubyBaseLayoutBox: BoxWrapper, rubyBaseMarginBoxLogicalRect: Rect,
    inlineFormattingContext: InlineFormattingContext
  ) -> InlineLayoutSize {
    // FIXME: This is where we should take advantage of the ruby-column setup.
    assert(rubyBaseLayoutBox.isRubyBase())
    let annotationBox = rubyBaseLayoutBox.associatedRubyAnnotationBox()
    if annotationBox == nil {
      fatalError("Not reached")
    }
    let annotationBoxLogicalGeometry = inlineFormattingContext.geometryForBox(
      layoutBox: annotationBox!)
    if hasInterlinearAnnotation(rubyBaseLayoutBox: rubyBaseLayoutBox) {
      // Layout the annotation box again if we decided to change its size.
      let newWidth = max(
        rubyBaseMarginBoxLogicalRect.width(), annotationBoxLogicalGeometry.marginBoxWidth())
      if newWidth != annotationBoxLogicalGeometry.marginBoxWidth() {
        inlineFormattingContext.integrationUtils!.layoutWithFormattingContextForBox(
          box: annotationBox!, widthConstraint: newWidth)
      }

      return InlineLayoutSize(
        width: (newWidth - annotationBoxLogicalGeometry.horizontalMarginBorderAndPadding()).float(),
        height: annotationBoxLogicalGeometry.contentBoxHeight().float())
    }

    return annotationBoxLogicalGeometry.contentBoxSize().FloatSize()
  }

  static func applyAnnotationAlignmentOffset(
    displayBoxes: InlineDisplay.Boxes, alignmentOffset: InlineLayoutUnit,
    inlineFormattingContext: InlineFormattingContext
  ) {
    if alignmentOffset == 0 {
      return
    }
    InlineContentAligner.applyRubyAnnotationAlignmentOffset(
      displayBoxes: displayBoxes, alignmentOffset: alignmentOffset,
      inlineFormattingContext: inlineFormattingContext)
  }

  static func applyRubyOverhang(
    parentFormattingContext: InlineFormattingContext, lineLogicalHeight: InlineLayoutUnit,
    displayBoxes: InlineDisplay.Boxes, interlinearRubyColumnRangeList: [Range<UInt64>]
  ) {
    // FIXME: We are only supposed to apply overhang when annotation box is wider than base, but at this point we can't tell (this needs to be addressed together with annotation box sizing).
    if interlinearRubyColumnRangeList.isEmpty {
      return
    }

    let isHorizontalWritingMode = parentFormattingContext.root().style.isHorizontalWritingMode()
    for startEndPair in interlinearRubyColumnRangeList {
      assert(!startEndPair.isEmpty)
      if startEndPair.upperBound - startEndPair.lowerBound == 1 {
        continue
      }

      let rubyBaseStart = startEndPair.lowerBound
      let rubyBaseLayoutBox = displayBoxes[Int(rubyBaseStart)].layoutBox
      assert(rubyBaseLayoutBox.isRubyBase())
      assert(hasInterlinearAnnotation(rubyBaseLayoutBox: rubyBaseLayoutBox))
      if rubyBaseLayoutBox.style.rubyOverhang() == .None {
        continue
      }

      let beforeOverhang = overhangForAnnotationBefore(
        rubyBaseLayoutBox: rubyBaseLayoutBox, rubyBaseStart: rubyBaseStart, boxes: displayBoxes,
        lineLogicalHeight: lineLogicalHeight, inlineFormattingContext: parentFormattingContext)
      let afterOverhang = overhangForAnnotationAfter(
        rubyBaseLayoutBox: rubyBaseLayoutBox,
        rubyBaseRange: rubyBaseStart..<startEndPair.upperBound, boxes: displayBoxes,
        lineLogicalHeight: lineLogicalHeight,
        inlineFormattingContext: parentFormattingContext)

      let hasJustifiedAdjacentAfterContent = hasJustifiedAdjacentAfterContent(
        displayBoxes: displayBoxes, startEndPair: startEndPair)

      if beforeOverhang != 0 {
        // When "before" adjacent content slightly pulls the rest of the content on the line leftward, justify content should stay intact.
        moveBoxRangeToVisualLeft(
          start: rubyBaseStart,
          end: hasJustifiedAdjacentAfterContent
            ? startEndPair.upperBound : UInt64(displayBoxes.count - 1),
          shiftValue: beforeOverhang, parentFormattingContext: parentFormattingContext,
          displayBoxes: displayBoxes, isHorizontalWritingMode: isHorizontalWritingMode)
      }
      if afterOverhang != 0 {
        // Normally we shift all the "after" boxes to the left here as one monolithic content
        // but in case of justified alignment we can only move the adjacent run under the annotation
        // and expand the justified space to keep the rest of the runs stationary.
        if hasJustifiedAdjacentAfterContent {
          let afterRubyBaseDisplayBox = displayBoxes[Int(startEndPair.upperBound)]
          let expansion = afterRubyBaseDisplayBox.expansion()
          let inflateValue = afterOverhang + beforeOverhang
          afterRubyBaseDisplayBox.setExpansion(
            expansion: InlineDisplay.Box.Expansion(
              behavior: expansion.behavior,
              horizontalExpansion: expansion.horizontalExpansion + inflateValue
            ))
          isHorizontalWritingMode
            ? afterRubyBaseDisplayBox.expandHorizontally(delta: inflateValue)
            : afterRubyBaseDisplayBox.expandVertically(delta: inflateValue)
          moveBoxRangeToVisualLeft(
            start: startEndPair.lowerBound, end: startEndPair.upperBound, shiftValue: afterOverhang,
            parentFormattingContext: parentFormattingContext,
            displayBoxes: displayBoxes, isHorizontalWritingMode: isHorizontalWritingMode)
        } else {
          moveBoxRangeToVisualLeft(
            start: startEndPair.lowerBound, end: UInt64(displayBoxes.count - 1),
            shiftValue: afterOverhang,
            parentFormattingContext: parentFormattingContext,
            displayBoxes: displayBoxes, isHorizontalWritingMode: isHorizontalWritingMode)
        }
      }
    }
  }

  // FIXME: If this turns out to be a pref bottleneck, make sure we pass in the accumulated shift to overhangForAnnotationBefore/after and
  // offset all box geometry as we check for overlap.
  static func moveBoxRangeToVisualLeft(
    start: UInt64, end: UInt64, shiftValue: InlineLayoutUnit,
    parentFormattingContext: InlineFormattingContext,
    displayBoxes: InlineDisplay.Boxes,
    isHorizontalWritingMode: Bool
  ) {
    for index in start...end {
      let displayBox = displayBoxes[Int(index)]
      isHorizontalWritingMode
        ? displayBox.moveHorizontally(offset: -shiftValue)
        : displayBox.moveVertically(offset: -shiftValue)

      let layoutBox = displayBox.layoutBox
      if displayBox.isInlineLevelBox() && !displayBox.isRootInlineBox() {
        parentFormattingContext.geometryForBox(layoutBox: layoutBox).moveHorizontally(
          offset: LayoutUnit(value: -shiftValue))
      }

      if layoutBox.isRubyBase() && layoutBox.associatedRubyAnnotationBox() != nil {
        parentFormattingContext.geometryForBox(layoutBox: layoutBox.associatedRubyAnnotationBox()!)
          .moveHorizontally(offset: LayoutUnit(value: -shiftValue))
      }
    }
  }

  static func hasJustifiedAdjacentAfterContent(
    displayBoxes: InlineDisplay.Boxes, startEndPair: Range<UInt64>
  ) -> Bool {
    if startEndPair.upperBound == displayBoxes.count {
      return false
    }
    let afterRubyBaseDisplayBox = displayBoxes[Int(startEndPair.upperBound)]
    if afterRubyBaseDisplayBox.layoutBox.isRubyBase() {
      // Adjacent content is also a ruby base.
      return false
    }
    return afterRubyBaseDisplayBox.expansion().horizontalExpansion != 0
  }

  enum RubyBasesMayNeedResizing: UInt8 {
    case No
    case Yes
  }

  static func applyAlignmentOffsetList(
    displayBoxes: InlineDisplay.Boxes, alignmentOffsetList: [BoxWrapper: InlineLayoutUnit],
    rubyBasesMayNeedResizing: RubyBasesMayNeedResizing,
    inlineFormattingContext: InlineFormattingContext
  ) {
    if alignmentOffsetList.isEmpty {
      return
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Miscellaneous helpers
  static func hasInterlinearAnnotation(rubyBaseLayoutBox: BoxWrapper) -> Bool {
    assert(rubyBaseLayoutBox.isRubyBase())
    return rubyBaseLayoutBox.associatedRubyAnnotationBox() != nil
      && !hasInterCharacterAnnotation(rubyBaseLayoutBox: rubyBaseLayoutBox)
  }

  static func hasInterCharacterAnnotation(rubyBaseLayoutBox: BoxWrapper) -> Bool {
    assert(rubyBaseLayoutBox.isRubyBase())
    if !rubyBaseLayoutBox.style.isHorizontalWritingMode() {
      // If the writing mode of the enclosing ruby container is vertical, this value has the same effect as over.
      return false
    }

    if let annotationBox = rubyBaseLayoutBox.associatedRubyAnnotationBox() {
      return annotationBox.style.isInterCharacterRubyPosition()
    }
    return false
  }

  static func adjustLayoutBoundsAndStretchAncestorRubyBase(
    lineBox: LineBox, rubyBaseInlineBox: InlineLevelBox,
    descendantRubySet: inout MaximumLayoutBoundsStretchMap,
    inlineFormattingContext: InlineFormattingContext
  ) {
    let rubyBaseLayoutBox = rubyBaseInlineBox.layoutBox
    assert(rubyBaseLayoutBox.isRubyBase())

    var layoutBounds = rubyBaseInlineBox.layoutBounds
    let annotationBox = rubyBaseLayoutBox.associatedRubyAnnotationBox()
    if annotationBox == nil || !hasInterlinearAnnotation(rubyBaseLayoutBox: rubyBaseLayoutBox) {
      // Make sure descendant rubies with annotations are propagated.
      stretchAncestorRubyBaseIfApplicable(
        layoutBounds: layoutBounds,
        rubyBaseLayoutBox: rubyBaseLayoutBox, lineBox: lineBox,
        inlineFormattingContext: inlineFormattingContext, descendantRubySet: &descendantRubySet)
      return
    }

    var over = InlineLayoutUnit()
    var under = InlineLayoutUnit()
    let annotationBoxLogicalHeight: InlineLayoutUnit = inlineFormattingContext.geometryForBox(
      layoutBox: annotationBox!
    )
    .marginBoxHeight().float()
    let isAnnotationBefore = rubyPosition(rubyBaseLayoutBox: rubyBaseLayoutBox) == .Over
    if isAnnotationBefore {
      over = annotationBoxLogicalHeight
    } else {
      under = annotationBoxLogicalHeight
    }

    // FIXME: The spec says annotation should not stretch the line unless line-height is not normal and annotation does not fit (i.e. line is sized too small for the annotation)
    // Legacy ruby behaves slightly differently by stretching the line box as needed.
    let isFirstFormattedLine = lineBox.lineIndex == 0
    let descendantLayoutBounds = descendantRubySet[
      ObjectIdentifier(rubyBaseInlineBox), default: InlineLevelBox.AscentAndDescent()]
    let ascent = max(rubyBaseInlineBox.ascent(), descendantLayoutBounds.ascent)
    let descent = max(rubyBaseInlineBox.descent(), descendantLayoutBounds.descent)

    if rubyBaseInlineBox.isPreferredLineHeightFontMetricsBased() {
      var extraSpaceForAnnotation = InlineLayoutUnit()
      if !isFirstFormattedLine {
        // Note that annotation may leak into the half leading space (gap between lines).
        let lineGap = rubyBaseLayoutBox.style.metricsOfPrimaryFont().intLineSpacing()
        extraSpaceForAnnotation = max(0, (InlineLayoutUnit(lineGap) - (ascent + descent)) / 2)
      }
      let ascentWithAnnotation = (ascent + over) - extraSpaceForAnnotation
      let descentWithAnnotation = (descent + under) - extraSpaceForAnnotation

      layoutBounds.ascent = max(ascentWithAnnotation, layoutBounds.ascent)
      layoutBounds.descent = max(descentWithAnnotation, layoutBounds.descent)
    } else {
      let ascentWithAnnotation = ascent + over
      let descentWithAnnotation = descent + under
      // FIXME: Normally we would check if there's space for both the ascent and the descent parts of the content
      // but in order to keep ruby tight we let subsequent lines (potentially) overlap each other by
      // only checking against total height (this affects the annotation box vertical placement by letting it overlap the previous line's descent)
      // However we have to make sure there's enough space for the annotation box on the first line.
      // This tight content arrangement is a legacy ruby behavior (see placeChildInlineBoxesInBlockDirection) and we may wanna reconsider it at some point.
      if isFirstFormattedLine {
        layoutBounds.ascent = max(ascentWithAnnotation, layoutBounds.ascent)
        layoutBounds.descent = max(descentWithAnnotation, layoutBounds.descent)
      } else if layoutBounds.height() < ascentWithAnnotation + descentWithAnnotation {
        // In case line-height does not produce enough space for annotation.
        let extraSpaceNeededForAnnotation =
          (ascentWithAnnotation + descentWithAnnotation) - layoutBounds.height()
        // Note that this makes annotation leak into previous/next line's (bottom/top) half leading. It ensures though that we don't
        // overly stretch lines and break (logical) vertical rhythm too much.
        if isAnnotationBefore {
          layoutBounds.ascent += extraSpaceNeededForAnnotation
        } else {
          layoutBounds.descent += extraSpaceNeededForAnnotation
        }
      }
    }

    rubyBaseInlineBox.setLayoutBounds(layoutBounds: layoutBounds)
    stretchAncestorRubyBaseIfApplicable(
      layoutBounds: layoutBounds,
      rubyBaseLayoutBox: rubyBaseLayoutBox, lineBox: lineBox,
      inlineFormattingContext: inlineFormattingContext,
      descendantRubySet: &descendantRubySet)
  }

  static func stretchAncestorRubyBaseIfApplicable(
    layoutBounds: InlineLevelBox.AscentAndDescent,
    rubyBaseLayoutBox: BoxWrapper, lineBox: LineBox,
    inlineFormattingContext: InlineFormattingContext,
    descendantRubySet: inout MaximumLayoutBoundsStretchMap
  ) {
    let rootBox = inlineFormattingContext.root()
    var ancestor = rubyBaseLayoutBox.parent()
    while CPtrToInt(ancestor.p) != CPtrToInt(rootBox.p) {
      if ancestor.isRubyBase() {
        let ancestorInlineBox = lineBox.inlineLevelBoxFor(layoutBox: ancestor)
        if ancestorInlineBox == nil {
          fatalError("Not reached")
        }
        let previousDescendantLayoutBounds = descendantRubySet[
          ObjectIdentifier(ancestorInlineBox!)]!
        descendantRubySet[ObjectIdentifier(ancestorInlineBox!)] = InlineLevelBox.AscentAndDescent(
          ascent: max(previousDescendantLayoutBounds.ascent, layoutBounds.ascent),
          descent: max(previousDescendantLayoutBounds.descent, layoutBounds.descent))
        break
      }
      ancestor = ancestor.parent()
    }
  }

  static func applyRubyAlignOnBaseContent(
    rubyBaseStart: UInt64, line: Line, alignmentOffsetList: inout [BoxWrapper: InlineLayoutUnit],
    inlineFormattingContext: InlineFormattingContext
  ) -> UInt64 {
    let runs = line.runs
    if runs.isEmpty {
      fatalError("Not reached")
    }
    let rubyBaseLayoutBox = runs[Int(rubyBaseStart)].layoutBox
    let rubyBaseEnd = rubyBaseEnd(
      rubyBaseLayoutBox: rubyBaseLayoutBox, rubyBaseStart: rubyBaseStart, runs: runs)
    if rubyBaseEnd - rubyBaseStart == 1 {
      // Blank base needs no alignment.
      return rubyBaseEnd
    }
    let annotationBox = rubyBaseLayoutBox.associatedRubyAnnotationBox()
    if annotationBox == nil {
      return rubyBaseStart + 1
    }

    inlineFormattingContext.integrationUtils!.layoutWithFormattingContextForBox(
      box: annotationBox!)

    let annotationBoxLogicalWidth: InlineLayoutUnit = inlineFormattingContext.geometryForBox(
      layoutBox: annotationBox!
    ).marginBoxWidth().float()
    let baseContentLogicalWidth =
      runs[Int(rubyBaseEnd)].logicalLeft - runs[Int(rubyBaseStart)].logicalRight()
    if annotationBoxLogicalWidth <= baseContentLogicalWidth {
      return rubyBaseStart + 1
    }

    let spaceToDistribute = annotationBoxLogicalWidth - baseContentLogicalWidth
    let alignmentOffset = InlineContentAligner.applyRubyAlign(
      rubyAlign: rubyBaseLayoutBox.style.rubyAlign(), runs: line.runs,
      range: rubyBaseStart..<(rubyBaseEnd + 1), spaceToDistribute: spaceToDistribute
    )
    // Reset the spacing we added at LineBuilder.
    let rubyBaseEndRun = runs[Int(rubyBaseEnd)]
    rubyBaseEndRun.shrinkHorizontally(width: spaceToDistribute)
    rubyBaseEndRun.moveHorizontally(offset: 2 * alignmentOffset)

    assert(!alignmentOffsetList.keys.contains(rubyBaseLayoutBox))
    alignmentOffsetList[rubyBaseLayoutBox] = alignmentOffset
    return rubyBaseEnd
  }

  static func rubyBaseEnd(
    rubyBaseLayoutBox: BoxWrapper, rubyBaseStart: UInt64, runs: Line.RunList
  ) -> UInt64 {
    let rubyBox = rubyBaseLayoutBox.parent()
    for index in (rubyBaseStart + 1)..<UInt64(runs.count) {
      if runs[Int(index)].layoutBox.parent() === rubyBox {
        return index
      }
    }
    return UInt64(runs.count - 1)
  }

  static func overhangForAnnotationBefore(
    rubyBaseLayoutBox: BoxWrapper, rubyBaseStart: UInt64, boxes: InlineDisplay.Boxes,
    lineLogicalHeight: InlineLayoutUnit, inlineFormattingContext: InlineFormattingContext
  ) -> InlineLayoutUnit {
    // [root inline box][ruby container][ruby base][ruby annotation]
    assert(rubyBaseStart >= 2)
    let annotationBox = rubyBaseLayoutBox.associatedRubyAnnotationBox()
    if annotationBox == nil || !hasInterlinearAnnotation(rubyBaseLayoutBox: rubyBaseLayoutBox)
      || rubyBaseStart <= 2
    {
      return InlineLayoutUnit()
    }
    if rubyBaseStart + 1 >= boxes.count {
      // We have to have some base content.
      fatalError("Not reached")
    }
    let isHorizontalWritingMode = inlineFormattingContext.root().style.isHorizontalWritingMode()
    let baseContentStart = baseContentIndex(rubyBaseStart: rubyBaseStart, boxes: boxes)
    if baseContentStart >= boxes.count {
      fatalError("Not reached")
    }
    let overhangValue = min(
      halfOfAFullWidthCharacter(annotationBox: annotationBox!),
      gapBetweenBaseAndContent(
        boxes: boxes, rubyBaseStart: rubyBaseStart, baseContentStart: baseContentStart,
        isHorizontalWritingMode: isHorizontalWritingMode))
    return wouldAnnotationOrBaseOverlapAdjacentContent(
      annotationBox: annotationBox!, lineLogicalHeight: lineLogicalHeight,
      inlineFormattingContext: inlineFormattingContext, baseContentStart: baseContentStart,
      boxes: boxes, isHorizontalWritingMode: isHorizontalWritingMode, overhangValue: overhangValue,
      rubyBaseStart: rubyBaseStart)
      ? 0 : overhangValue
  }

  // FIXME: Usually the first content box is visually the leftmost, but we should really look for content shifted to the left through negative margins on inline boxes.
  static func gapBetweenBaseAndContent(
    boxes: InlineDisplay.Boxes, rubyBaseStart: UInt64, baseContentStart: UInt64,
    isHorizontalWritingMode: Bool
  )
    -> Float32
  {
    // FIXME: Usually the first content box is visually the leftmost, but we should really look for content shifted to the left through negative margins on inline boxes.
    let contentVisualRect = boxes[Int(baseContentStart)].visualRectIgnoringBlockDirection()
    let baseVisualRect = boxes[Int(rubyBaseStart)].visualRectIgnoringBlockDirection()
    if isHorizontalWritingMode {
      return max(0, contentVisualRect.x() - baseVisualRect.x())
    }
    return max(0, contentVisualRect.y() - baseVisualRect.y())
  }

  static func wouldAnnotationOrBaseOverlapAdjacentContent(
    annotationBox: ElementBoxWrapper, lineLogicalHeight: InlineLayoutUnit,
    inlineFormattingContext: InlineFormattingContext, baseContentStart: UInt64,
    boxes: InlineDisplay.Boxes, isHorizontalWritingMode: Bool, overhangValue: Float32,
    rubyBaseStart: UInt64
  ) -> Bool {
    // Check of adjacent (previous) content for overlapping.
    var overhangingAnnotationVisualRect = annotationMarginBoxVisualRect(
      annotationBox: annotationBox, lineHeight: lineLogicalHeight,
      inlineFormattingContext: inlineFormattingContext)
    var baseContentBoxRect = boxes[Int(baseContentStart)].inkOverflow
    // This is how much the annotation box/base content would be closer to content outside of base.
    let offset =
      isHorizontalWritingMode
      ? InlineLayoutPoint(x: -overhangValue, y: 0) : InlineLayoutPoint(x: 0, y: -overhangValue)
    overhangingAnnotationVisualRect.moveBy(offset: offset)
    baseContentBoxRect.moveBy(delta: offset)

    for index in 1..<(rubyBaseStart - 1) {
      let previousDisplayBox = boxes[Int(index)]
      if annotationOverlapCheck(
        adjacentDisplayBox: previousDisplayBox,
        overhangingRect: overhangingAnnotationVisualRect.InlineLayoutRect(),
        lineLogicalHeight: lineLogicalHeight,
        inlineFormattingContext: inlineFormattingContext)
      {
        return true
      }
      if annotationOverlapCheck(
        adjacentDisplayBox: previousDisplayBox, overhangingRect: baseContentBoxRect,
        lineLogicalHeight: lineLogicalHeight, inlineFormattingContext: inlineFormattingContext)
      {
        return true
      }
    }
    return false
  }

  static func overhangForAnnotationAfter(
    rubyBaseLayoutBox: BoxWrapper, rubyBaseRange: Range<UInt64>, boxes: InlineDisplay.Boxes,
    lineLogicalHeight: InlineLayoutUnit, inlineFormattingContext: InlineFormattingContext
  ) -> InlineLayoutUnit {
    let annotationBox = rubyBaseLayoutBox.associatedRubyAnnotationBox()
    if annotationBox == nil || !hasInterlinearAnnotation(rubyBaseLayoutBox: rubyBaseLayoutBox) {
      return InlineLayoutUnit()
    }

    if rubyBaseRange.isEmpty || rubyBaseRange.upperBound - rubyBaseRange.lowerBound == 1
      || rubyBaseRange.upperBound == boxes.count
    {
      return InlineLayoutUnit()
    }

    let isHorizontalWritingMode = inlineFormattingContext.root().style.isHorizontalWritingMode()
    // FIXME: Usually the last content box is visually the rightmost, but negative margin may override it.
    // FIXME: Currently justified content always expands producing 0 value for gapBetweenBaseEndAndContent.
    let overhangValue = min(
      halfOfAFullWidthCharacter(annotationBox: annotationBox!),
      gapBetweenBaseEndAndContent(
        boxes: boxes, rubyBaseRange: rubyBaseRange, isHorizontalWritingMode: isHorizontalWritingMode
      ))
    return wouldAnnotationOrBaseOverlapLineContent(
      boxes: boxes, rubyBaseRange: rubyBaseRange, annotationBox: annotationBox!,
      lineLogicalHeight: lineLogicalHeight, inlineFormattingContext: inlineFormattingContext,
      overhangValue: overhangValue, isHorizontalWritingMode: isHorizontalWritingMode)
      ? 0 : overhangValue
  }

  static func gapBetweenBaseEndAndContent(
    boxes: InlineDisplay.Boxes, rubyBaseRange: Range<UInt64>, isHorizontalWritingMode: Bool
  )
    -> Float32
  {
    let baseStartVisualRect = boxes[Int(rubyBaseRange.lowerBound)]
      .visualRectIgnoringBlockDirection()
    let baseContentEndVisualRect = boxes[Int(rubyBaseRange.upperBound - 1)]
      .visualRectIgnoringBlockDirection()
    if isHorizontalWritingMode {
      return max(0, baseStartVisualRect.maxX() - baseContentEndVisualRect.maxX())
    }
    return max(0, baseStartVisualRect.maxY() - baseContentEndVisualRect.maxY())
  }

  static func wouldAnnotationOrBaseOverlapLineContent(
    boxes: InlineDisplay.Boxes, rubyBaseRange: Range<UInt64>, annotationBox: ElementBoxWrapper,
    lineLogicalHeight: InlineLayoutUnit, inlineFormattingContext: InlineFormattingContext,
    overhangValue: InlineLayoutUnit, isHorizontalWritingMode: Bool
  ) -> Bool {
    // Check of adjacent (next) content for overlapping.
    var overhangingAnnotationVisualRect = annotationMarginBoxVisualRect(
      annotationBox: annotationBox, lineHeight: lineLogicalHeight,
      inlineFormattingContext: inlineFormattingContext)
    let baseContentBoxRect = boxes[Int(rubyBaseRange.upperBound - 1)].inkOverflow
    // This is how much the base content would be closer to content outside of base.
    let offset =
      isHorizontalWritingMode
      ? InlineLayoutPoint(x: overhangValue, y: 0) : InlineLayoutPoint(x: 0, y: overhangValue)
    overhangingAnnotationVisualRect.moveBy(offset: offset)
    for index in (Int(rubyBaseRange.upperBound + 1)..<boxes.count).reversed() {
      let previousDisplayBox = boxes[index]
      if annotationOverlapCheck(
        adjacentDisplayBox: previousDisplayBox,
        overhangingRect: overhangingAnnotationVisualRect.InlineLayoutRect(),
        lineLogicalHeight: lineLogicalHeight,
        inlineFormattingContext: inlineFormattingContext)
      {
        return true
      }
      if annotationOverlapCheck(
        adjacentDisplayBox: previousDisplayBox,
        overhangingRect: baseContentBoxRect,
        lineLogicalHeight: lineLogicalHeight,
        inlineFormattingContext: inlineFormattingContext)
      {
        return true
      }
    }
    return false
  }
}
