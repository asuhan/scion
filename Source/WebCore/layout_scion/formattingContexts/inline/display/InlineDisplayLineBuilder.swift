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

internal func truncateTextContentWithMismatchingDirection(
  displayBox: InlineDisplay.Box, contentWidth: Float32, availableWidthForContent: Float32,
  canFullyTruncate: Bool
) -> Float32 {
  // While truncation normally starts at the end of the content and progress backwards, with mismatching direction
  // we take a different approach and truncate content the other way around (i.e. ellipsis follows inline direction truncating the beginning of the content).
  // <div dir=rtl>some long content</div>
  // [...ng content]
  let inlineTextBox = displayBox.layoutBox as! InlineTextBoxWrapper
  let textContent = displayBox.text()

  let availableWidthForTruncatedContent = contentWidth - availableWidthForContent
  let truncatedSide = TextUtil.breakWord(
    inlineTextBox: inlineTextBox, startPosition: UInt64(textContent.start),
    length: UInt64(textContent.length),
    textWidth: contentWidth,
    availableWidth: availableWidthForTruncatedContent, contentLogicalLeft: InlineLayoutUnit(),
    fontCascade: displayBox.style().fontCascade())

  assert(truncatedSide.length < textContent.length)
  var visibleLength = UInt64(textContent.length) - truncatedSide.length
  let visibleWidth = contentWidth - truncatedSide.logicalWidth
  // TextUtil::breakWord never returns overflowing content (left side) which means the right side is normally wider (by one character) than what we need.
  let visibleContentOverflows = truncatedSide.logicalWidth < availableWidthForTruncatedContent
  if !visibleContentOverflows {
    textContent.setPartiallyVisibleContentLength(truncatedLength: visibleLength)
    return visibleWidth
  }

  let wouldFullyTruncate = visibleLength <= 1
  if wouldFullyTruncate && canFullyTruncate {
    displayBox.setIsFullyTruncated()
    return 0
  }

  visibleLength = !wouldFullyTruncate ? visibleLength - 1 : 1
  textContent.setPartiallyVisibleContentLength(truncatedLength: visibleLength)
  let visibleStartPosition = textContent.end() - visibleLength
  return TextUtil.width(
    inlineTextBox: inlineTextBox, fontCascade: displayBox.style().fontCascade(),
    from: UInt32(visibleStartPosition), toIn: UInt32(textContent.end()),
    contentLogicalLeft: InlineLayoutUnit(),
    useTrailingWhitespaceMeasuringOptimization: .No)
}

internal func truncate(
  displayBox: InlineDisplay.Box, contentWidth: Float32, availableWidthForContent: Float32,
  canFullyTruncate: Bool
) -> Float32 {
  if displayBox.isText() {
    if availableWidthForContent == 0 && canFullyTruncate {
      displayBox.setIsFullyTruncated()
      return 0
    }
    let contentDirection: TextDirection = displayBox.bidiLevel.rawValue % 2 != 0 ? .RTL : .LTR
    if displayBox.layoutBox.parent().style.direction() != contentDirection {
      return truncateTextContentWithMismatchingDirection(
        displayBox: displayBox, contentWidth: contentWidth,
        availableWidthForContent: availableWidthForContent, canFullyTruncate: canFullyTruncate)
    }

    let inlineTextBox = displayBox.layoutBox as! InlineTextBoxWrapper
    let textContent = displayBox.text()
    let visibleSide = TextUtil.breakWord(
      inlineTextBox: inlineTextBox, startPosition: UInt64(textContent.start),
      length: UInt64(textContent.length), textWidth: contentWidth,
      availableWidth: availableWidthForContent, contentLogicalLeft: InlineLayoutUnit(),
      fontCascade: displayBox.style().fontCascade())
    if visibleSide.length != 0 {
      textContent.setPartiallyVisibleContentLength(truncatedLength: visibleSide.length)
      return visibleSide.logicalWidth
    }
    if canFullyTruncate {
      displayBox.setIsFullyTruncated()
      return 0
    }
    let firstCharacterLength = TextUtil.firstUserPerceivedCharacterLength(
      inlineTextBox: inlineTextBox, startPosition: UInt64(textContent.start),
      length: UInt64(textContent.length))
    let firstCharacterWidth = TextUtil.width(
      inlineTextBox: inlineTextBox, fontCascade: displayBox.style().fontCascade(),
      from: textContent.start,
      toIn: textContent.start + UInt32(firstCharacterLength),
      contentLogicalLeft: InlineLayoutUnit(),
      useTrailingWhitespaceMeasuringOptimization: .No)
    textContent.setPartiallyVisibleContentLength(truncatedLength: firstCharacterLength)
    return firstCharacterWidth
  }

  if canFullyTruncate {
    // Atomic inline level boxes are never partially truncated.
    displayBox.setIsFullyTruncated()
    return 0
  }
  return contentWidth
}

internal func truncateOverflowingDisplayBoxes(
  boxes: InlineDisplay.Boxes, startIndex: UInt64, endIndex: UInt64, lineBoxVisualLeft: Float32,
  lineBoxVisualRight: Float32, ellipsisWidth: Float32, rootStyle: RenderStyleWrapper,
  lineEndingTruncationPolicy: LineEndingTruncationPolicy
) -> Float32 {
  assert(endIndex != 0 && startIndex <= endIndex)
  // We gotta truncate some runs.
  let isHorizontal = rootStyle.isHorizontalWritingMode()
  // The logically first character or atomic inline-level element on a line must be clipped rather than ellipsed.
  var isFirstContentRun = true
  if rootStyle.isLeftToRightDirection() {
    var visualRightForContentEnd = max(0, lineBoxVisualRight - ellipsisWidth)
    if visualRightForContentEnd != 0 {
      visualRightForContentEnd += LayoutUnit.epsilon()
    }
    var truncateRight: Float32? = nil
    for index in startIndex...endIndex {
      let displayBox = boxes[Int(index)]
      if displayBox.isInlineBox() {
        continue
      }
      if rightForDisplayBox(displayBox: displayBox, isHorizontal: isHorizontal)
        > visualRightForContentEnd
      {
        let visibleWidth = truncate(
          displayBox: displayBox,
          contentWidth: widthForDisplayBox(displayBox: displayBox, isHorizontal: isHorizontal),
          availableWidthForContent: max(
            0,
            visualRightForContentEnd
              - leftForDisplayBox(displayBox: displayBox, isHorizontal: isHorizontal)),
          canFullyTruncate: !isFirstContentRun)
        let truncatePosition =
          leftForDisplayBox(displayBox: displayBox, isHorizontal: isHorizontal) + visibleWidth
        truncateRight = truncateRight ?? truncatePosition
      }
      isFirstContentRun = false
    }
    return truncateRight ?? rightForDisplayBox(displayBox: boxes.last!, isHorizontal: isHorizontal)
  }

  var truncateLeft: Float32? = nil
  var visualLeftForContentEnd = max(0, lineBoxVisualLeft + ellipsisWidth)
  if visualLeftForContentEnd != 0 {
    visualLeftForContentEnd -= LayoutUnit.epsilon()
  }
  for index in (startIndex...endIndex).reversed() {
    let displayBox = boxes[Int(index)]
    if displayBox.isInlineBox() {
      continue
    }
    if leftForDisplayBox(displayBox: displayBox, isHorizontal: isHorizontal)
      < visualLeftForContentEnd
    {
      let visibleWidth = truncate(
        displayBox: displayBox,
        contentWidth: widthForDisplayBox(displayBox: displayBox, isHorizontal: isHorizontal),
        availableWidthForContent: max(
          0,
          rightForDisplayBox(displayBox: displayBox, isHorizontal: isHorizontal)
            - visualLeftForContentEnd), canFullyTruncate: !isFirstContentRun)
      let truncatePosition =
        rightForDisplayBox(displayBox: displayBox, isHorizontal: isHorizontal) - visibleWidth
      truncateLeft = truncateLeft ?? truncatePosition
    }
    isFirstContentRun = false
  }
  return (truncateLeft ?? leftForDisplayBox(displayBox: boxes.first!, isHorizontal: isHorizontal))
    - ellipsisWidth
}

internal func leftForDisplayBox(displayBox: InlineDisplay.Box, isHorizontal: Bool) -> Float32 {
  return isHorizontal ? displayBox.left() : displayBox.top()
}

internal func rightForDisplayBox(displayBox: InlineDisplay.Box, isHorizontal: Bool) -> Float32 {
  return isHorizontal ? displayBox.right() : displayBox.bottom()
}

internal func widthForDisplayBox(displayBox: InlineDisplay.Box, isHorizontal: Bool) -> Float32 {
  return isHorizontal ? displayBox.width() : displayBox.height()
}

internal func trailingEllipsisVisualRectAfterTruncation(
  lineEndingTruncationPolicy: LineEndingTruncationPolicy, ellipsisText: StringWrapper,
  displayLine: InlineDisplay.Line, displayBoxes: InlineDisplay.Boxes,
  isLastLineWithInlineContent: Bool
) -> FloatRectWrapper? {
  assert(lineEndingTruncationPolicy != .NoTruncation)
  if displayBoxes.isEmpty {
    return nil
  }

  if !needsEllipsis(
    lineEndingTruncationPolicy: lineEndingTruncationPolicy, displayLine: displayLine,
    isLastLineWithInlineContent: isLastLineWithInlineContent)
  {
    return nil
  }

  assert(displayBoxes[0].isRootInlineBox())
  let rootInlineBox = displayBoxes[0]
  let rootStyle = rootInlineBox.style()
  let ellipsisWidth = max(
    0,
    rootStyle.fontCascade().width(
      run: TextRunWrapper(stringView: StringWrapperView(s: ellipsisText))))

  var ellipsisStart: Float32 = 0
  if !contentNeedsTruncation(
    lineEndingTruncationPolicy: lineEndingTruncationPolicy, displayLine: displayLine,
    ellipsisWidth: ellipsisWidth)
  {
    // The content does not overflow the line box. The ellipsis is supposed to be either visually trailing or leading depending on the inline direction.
    if displayBoxes.count > 1 {
      ellipsisStart =
        rootStyle.isLeftToRightDirection()
        ? displayBoxes.last!.right() : displayBoxes[1].left() - ellipsisWidth
    } else {
      // All we have is the root inline box.
      ellipsisStart = displayBoxes.first!.left()
    }
  } else {
    let lineBoxVisualLeft =
      rootStyle.isHorizontalWritingMode() ? displayLine.left() : displayLine.top()
    let lineBoxVisualRight = max(
      rootStyle.isHorizontalWritingMode() ? displayLine.right() : displayLine.bottom(),
      lineBoxVisualLeft)
    ellipsisStart = truncateOverflowingDisplayBoxes(
      boxes: displayBoxes, startIndex: 0, endIndex: UInt64(displayBoxes.count - 1),
      lineBoxVisualLeft: lineBoxVisualLeft, lineBoxVisualRight: lineBoxVisualRight,
      ellipsisWidth: ellipsisWidth, rootStyle: rootStyle,
      lineEndingTruncationPolicy: lineEndingTruncationPolicy)
  }

  if rootStyle.isHorizontalWritingMode() {
    return FloatRectWrapper(
      x: ellipsisStart, y: rootInlineBox.top(), width: ellipsisWidth, height: rootInlineBox.height()
    )
  }
  return FloatRectWrapper(
    x: rootInlineBox.left(), y: ellipsisStart, width: rootInlineBox.width(), height: ellipsisWidth)
}

internal func makeRoomForLinkBoxOnClampedLineIfNeededStartIndex(
  displayBoxes: InlineDisplay.Boxes, insertionPosition: UInt64
) -> UInt64 {
  assert(insertionPosition != 0)
  for (index, displayBox) in displayBoxes.enumerated().reversed() {
    if displayBox.isRootInlineBox() {
      return UInt64(index + 1)
    }
    return UInt64(index)
  }
  fatalError("Not reached")
}

internal func makeRoomForLinkBoxOnClampedLineIfNeeded(
  clampedLine: inout InlineDisplay.Line, displayBoxes: InlineDisplay.Boxes,
  insertionPosition: UInt64,
  linkContentWidth: Float32
) {
  assert(insertionPosition != 0)
  var ellipsisBoxRect = clampedLine.ellipsis!.visualRect
  if ellipsisBoxRect.maxX() + linkContentWidth <= clampedLine.right() {
    return
  }
  let rootStyle = displayBoxes[0].layoutBox.style
  let endIndex = insertionPosition - 1
  let startIndex = makeRoomForLinkBoxOnClampedLineIfNeededStartIndex(
    displayBoxes: displayBoxes, insertionPosition: insertionPosition)
  let ellipsisPosition =
    clampedLine.right() - linkContentWidth - Float32(legacyMatchingLinkBoxOffset)
  let ellipsisStart = truncateOverflowingDisplayBoxes(
    boxes: displayBoxes, startIndex: startIndex, endIndex: endIndex,
    lineBoxVisualLeft: clampedLine.left(),
    lineBoxVisualRight: ellipsisPosition, ellipsisWidth: ellipsisBoxRect.width(),
    rootStyle: rootStyle, lineEndingTruncationPolicy: .WhenContentOverflowsInBlockDirection)
  ellipsisBoxRect.setX(x: ellipsisStart)
  clampedLine.setEllipsis(
    ellipsis: InlineDisplay.Line.Ellipsis(
      type: .Block,
      visualRect: ellipsisBoxRect,
      text: TextUtil.ellipsisTextInInlineDirection(isHorizontal: clampedLine.isHorizontal)))
}

internal let legacyMatchingLinkBoxOffset = 3

internal func moveDisplayBoxToClampedLine(
  displayLines: InlineDisplay.Lines, clampedLineIndex: UInt64, displayBox: inout InlineDisplay.Box,
  horizontalOffset: LayoutUnit
) {
  let clampedLine = displayLines[Int(clampedLineIndex)]
  displayBox.setLeft(
    physicalLeft: Float32(clampedLine.ellipsis!.visualRect.maxX() + horizontalOffset)
      + Float32(legacyMatchingLinkBoxOffset))
  // Assume baseline alignment here.
  displayBox.moveVertically(
    offset: (clampedLine.top() + clampedLine.baseline())
      - (displayLines.last!.top() + displayLines.last!.baseline()))
  displayBox.moveToLine(lineIndex: UInt32(clampedLineIndex))
}

internal func isEligibleForLinkBoxLineClamp(displayBoxes: InlineDisplay.Boxes) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

internal func computeInsertionPosition(displayBoxes: InlineDisplay.Boxes, clampedLineIndex: UInt64)
  -> UInt64?
{
  for (boxIndex, displayBox) in displayBoxes.enumerated() {
    if displayBox.lineIndex > clampedLineIndex {
      return UInt64(boxIndex)
    }
  }
  return nil
}

internal func handleTrailingLineBreakIfApplicable(
  displayBoxes: InlineDisplay.Boxes, linkContentWidth: Float32, insertionPosition: inout UInt64
) {
  // "more info" gets inserted after the trailing run on the clamped line unless the trailing content is forced line break.
  let trailingDisplayBox = displayBoxes[Int(insertionPosition - 1)]
  if !trailingDisplayBox.isLineBreak() {
    return
  }
  // Move trailing line break after the link box.
  trailingDisplayBox.moveHorizontally(offset: linkContentWidth)
  insertionPosition -= 1
}

internal func contentNeedsTruncation(
  lineEndingTruncationPolicy: LineEndingTruncationPolicy, displayLine: InlineDisplay.Line,
  ellipsisWidth: InlineLayoutUnit
) -> Bool {
  switch lineEndingTruncationPolicy {
  case .WhenContentOverflowsInInlineDirection:
    assert(displayLine.contentLogicalWidth > displayLine.lineBoxLogicalRect.width())
    return true
  case .WhenContentOverflowsInBlockDirection:
    return displayLine.contentLogicalLeft + displayLine.contentLogicalWidth + ellipsisWidth
      > displayLine.lineBoxLogicalRect.maxX()
  default:
    fatalError("Not reached")
  }
}

internal func needsEllipsis(
  lineEndingTruncationPolicy: LineEndingTruncationPolicy, displayLine: InlineDisplay.Line,
  isLastLineWithInlineContent: Bool
) -> Bool {
  if lineEndingTruncationPolicy == .WhenContentOverflowsInInlineDirection {
    return displayLine.contentLogicalWidth != 0
      && displayLine.contentLogicalWidth > displayLine.lineBoxLogicalRect.width()
  }
  assert(lineEndingTruncationPolicy == .WhenContentOverflowsInBlockDirection)
  return !isLastLineWithInlineContent
}

internal func flipLogicalLineRectToVisualForWritingMode(
  lineLogicalRect: InlineRect, writingMode: WritingMode
) -> InlineRect {
  switch writingModeToBlockFlowDirection(writingMode: writingMode) {
  case .TopToBottom, .BottomToTop:
    return lineLogicalRect
  case .LeftToRight, .RightToLeft:
    // See InlineFormattingUtils for more info.
    return InlineRect(
      top: lineLogicalRect.left(), left: lineLogicalRect.top(), width: lineLogicalRect.height(),
      height: lineLogicalRect.width())
  }
}

struct InlineDisplayLineBuilder {
  init(inlineFormattingContext: InlineFormattingContext, constraints: ConstraintsForInlineContent) {
    self.inlineFormattingContext = inlineFormattingContext
    self.constraints = constraints
  }

  func build(
    lineLayoutResult: LineLayoutResult, lineBox: LineBox, lineIsFullyTruncatedInBlockDirection: Bool
  ) -> InlineDisplay.Line {
    let rootInlineBox = lineBox.rootInlineBox
    let isLeftToRightDirection = lineLayoutResult.directionality.inlineBaseDirection == .LTR
    let lineBoxLogicalRect = lineBox.logicalRect
    let lineBoxVisualLeft =
      isLeftToRightDirection
      ? lineBoxLogicalRect.left()
      : (constraints.visualLeft + constraints.horizontal.logicalWidth
        + constraints.horizontal.logicalLeft).float() - lineBoxLogicalRect.right()

    let rootInlineBoxRect = lineBox.logicalRectForRootInlineBox()
    let contentVisualOffsetInInlineDirection =
      isLeftToRightDirection
      ? rootInlineBoxRect.left()
      : lineBoxLogicalRect.width()
        - lineLayoutResult.contentGeometry.logicalRightIncludingNegativeMargin  // Note that with hanging content lineLayoutResult.contentGeometry.logicalRight is not the same as rootLineBoxRect.right().

    let lineBoxVisualRectInInlineDirection = InlineRect(
      top: lineBoxLogicalRect.top(), left: lineBoxVisualLeft, width: lineBoxLogicalRect.width(),
      height: lineBoxLogicalRect.height())
    let enclosingLineGeometry = collectEnclosingLineGeometry(
      lineLayoutResult: lineLayoutResult, lineBox: lineBox,
      lineBoxRect: lineBoxVisualRectInInlineDirection)

    let writingMode = root().style.writingMode()
    return InlineDisplay.Line(
      lineBoxLogicalRect: lineBoxLogicalRect.InlineLayoutRect(),
      lineBoxRect: flipLogicalLineRectToVisualForWritingMode(
        lineLogicalRect: lineBoxVisualRectInInlineDirection, writingMode: writingMode
      ).InlineLayoutRect(),
      contentOverflow: flipLogicalLineRectToVisualForWritingMode(
        lineLogicalRect: enclosingLineGeometry.contentOverflowRect, writingMode: writingMode
      ).InlineLayoutRect(),
      enclosingLogicalTopAndBottom: enclosingLineGeometry.enclosingTopAndBottom,
      alignmentBaseline: rootInlineBox.logicalTop() + rootInlineBox.ascent(),
      baselineType: lineBox.baselineType,
      contentLogicalLeft: rootInlineBoxRect.left(),
      contentLogicalLeftIgnoringInlineDirection: contentVisualOffsetInInlineDirection,
      contentLogicalWidth: rootInlineBox.logicalWidth(),
      isLeftToRightDirection: isLeftToRightDirection,
      isHorizontal: rootInlineBox.layoutBox.style.isHorizontalWritingMode(),
      isTruncatedInBlockDirection: lineIsFullyTruncatedInBlockDirection)
  }

  static func applyEllipsisIfNeeded(
    truncationPolicy: LineEndingTruncationPolicy, displayLine: inout InlineDisplay.Line,
    displayBoxes: InlineDisplay.Boxes, isLastLineWithInlineContent: Bool, isLegacyLineClamp: Bool
  ) {
    if truncationPolicy == .NoTruncation || displayBoxes.count == 0 {
      return
    }

    let ellipsisText = InlineDisplayLineBuilder.ellipsisText(
      truncationPolicy: truncationPolicy, displayLine: displayLine, displayBoxes: displayBoxes,
      isLegacyLineClamp: isLegacyLineClamp)

    if ellipsisText.isNull() {
      return
    }

    if let ellipsisRect = trailingEllipsisVisualRectAfterTruncation(
      lineEndingTruncationPolicy: truncationPolicy, ellipsisText: ellipsisText.string(),
      displayLine: displayLine, displayBoxes: displayBoxes,
      isLastLineWithInlineContent: isLastLineWithInlineContent)
    {
      displayLine.setEllipsis(
        ellipsis: InlineDisplay.Line.Ellipsis(
          type: truncationPolicy == .WhenContentOverflowsInInlineDirection ? .Inline : .Block,
          visualRect: ellipsisRect, text: ellipsisText)
      )
    }
  }

  static func ellipsisText(
    truncationPolicy: LineEndingTruncationPolicy, displayLine: InlineDisplay.Line,
    displayBoxes: InlineDisplay.Boxes, isLegacyLineClamp: Bool
  ) -> AtomStringWrapper {
    if truncationPolicy == .WhenContentOverflowsInInlineDirection || isLegacyLineClamp {
      // Legacy line clamp always uses ...
      return TextUtil.ellipsisTextInInlineDirection(isHorizontal: displayLine.isHorizontal)
    }
    let blockEllipsis = displayBoxes[0].layoutBox.style.blockEllipsis()
    if blockEllipsis.type == .None {
      return nullAtom()
    }
    if blockEllipsis.type == .Auto {
      return TextUtil.ellipsisTextInInlineDirection(isHorizontal: displayLine.isHorizontal)
    }
    return blockEllipsis.string
  }

  static func addLineClampTrailingLinkBoxIfApplicable(
    inlineFormattingContext: InlineFormattingContext, inlineLayoutState: InlineLayoutState,
    displayContent: InlineDisplay.Content
  ) {
    // This is link-box type of line clamping (-webkit-line-clamp) where we check if the inline content ends in a link
    // and move such link content next to the clamped line's trailing ellispsis. It is meant to produce the following rendering
    //
    // first line
    // second line is clamped... more info
    //
    // where "more info" is a link and it comes from the end of the inline content (normally invisible due to block direction clamping)
    // This is to match legacy line clamping behavior (and not a block-ellispsis: <string> implementation) which was introduced
    // at https://commits.webkit.org/6086@main to support special article rendering with clamped lines.
    // It supports horizontal, left-to-right content only where the link inline box has (non-split) text content and when
    // the link content ('more info') fits the clamped line.
    let clampedLineIndex = inlineLayoutState.clampedLineIndex
    if clampedLineIndex == nil {
      return
    }
    let displayLines = displayContent.lines
    if clampedLineIndex! >= displayLines.count
      || !displayLines[Int(clampedLineIndex!)].hasEllipsis()
    {
      fatalError("Not reached")
    }

    var displayBoxes = displayContent.boxes

    if !isEligibleForLinkBoxLineClamp(displayBoxes: displayBoxes) {
      return
    }

    var insertionPosition = computeInsertionPosition(
      displayBoxes: displayBoxes, clampedLineIndex: clampedLineIndex!)
    if insertionPosition == nil || insertionPosition! == 0
      || insertionPosition! >= displayBoxes.count - 1
    {
      // Unexpected cases where the insertion point is at the leading/trailing box. They both indicate incorrect line-clamp
      // position and would produce incorrect rendering.
      fatalError("Not reached with security implication")
    }
    var clampedLine = displayLines[Int(clampedLineIndex!)]
    let linkContentWidth = displayBoxes[displayBoxes.count - 2]
      .visualRectIgnoringBlockDirection().width()
    if linkContentWidth >= clampedLine.lineBoxWidth() {
      // Not enough space for "more info" content.
      return
    }
    var linkContentDisplayBox = displayBoxes.removeLast()
    var linkInlineBoxDisplayBox = displayBoxes.removeLast()

    handleTrailingLineBreakIfApplicable(
      displayBoxes: displayBoxes, linkContentWidth: linkContentWidth,
      insertionPosition: &insertionPosition!)

    makeRoomForLinkBoxOnClampedLineIfNeeded(
      clampedLine: &clampedLine, displayBoxes: displayBoxes, insertionPosition: insertionPosition!,
      linkContentWidth: linkContentWidth)

    // link box content
    moveDisplayBoxToClampedLine(
      displayLines: displayLines, clampedLineIndex: clampedLineIndex!,
      displayBox: &linkContentDisplayBox,
      horizontalOffset: inlineFormattingContext.geometryForBox(
        layoutBox: linkInlineBoxDisplayBox.layoutBox
      )
      .marginBorderAndPaddingStart())
    displayBoxes.insert(linkInlineBoxDisplayBox, at: Int(insertionPosition!))
    // Link inline box
    moveDisplayBoxToClampedLine(
      displayLines: displayLines, clampedLineIndex: clampedLineIndex!,
      displayBox: &linkInlineBoxDisplayBox, horizontalOffset: LayoutUnit())
    displayBoxes.insert(linkInlineBoxDisplayBox, at: Int(insertionPosition!))

    clampedLine.setHasContentAfterEllipsisBox()
  }

  struct EnclosingLineGeometry {
    var enclosingTopAndBottom = InlineDisplay.Line.EnclosingTopAndBottom()
    var contentOverflowRect = InlineRect()
  }

  func collectEnclosingLineGeometry(
    lineLayoutResult: LineLayoutResult, lineBox: LineBox, lineBoxRect: InlineRect
  ) -> EnclosingLineGeometry {
    var (enclosingTop, enclosingBottom) = InlineDisplayLineBuilder.initialEnclosingTopAndBottom(
      lineBox: lineBox, rootInlineBox: lineBox.rootInlineBox, lineBoxRect: lineBoxRect)
    var contentOverflowRect = contentOverflowRect(
      lineLayoutResult: lineLayoutResult, lineBox: lineBox, lineBoxRect: lineBoxRect)
    for inlineLevelBox in lineBox.nonRootInlineLevelBoxes() {
      if !inlineLevelBox.isAtomicInlineBox() && !inlineLevelBox.isInlineBox()
        && !inlineLevelBox.isLineBreakBox()
      {
        continue
      }

      let layoutBox = inlineLevelBox.layoutBox
      var borderBox = InlineRect()

      if inlineLevelBox.isAtomicInlineBox() {
        borderBox = lineBox.logicalBorderBoxForAtomicInlineBox(
          layoutBox: layoutBox,
          boxGeometry: formattingContext().geometryForBox(layoutBox: layoutBox))
        borderBox.moveBy(offset: lineBoxRect.topLeft())
      } else if inlineLevelBox.isInlineBox() {
        let boxGeometry = formattingContext().geometryForBox(layoutBox: layoutBox)
        // In standards mode, inline boxes always start with an imaginary strut.
        let isContentful =
          formattingContext().layoutState().inStandardsMode || inlineLevelBox.hasContent
          || boxGeometry.horizontalBorderAndPadding().bool()
        if !isContentful {
          continue
        }
        borderBox = lineBox.logicalBorderBoxForInlineBox(
          layoutBox: layoutBox, boxGeometry: boxGeometry)
        borderBox.moveBy(offset: lineBoxRect.topLeft())
        // Collect scrollable overflow from inline boxes. All other inline level boxes (e.g atomic inline level boxes) stretch the line.
        if lineBox.hasContent {
          // Empty lines (e.g. continuation pre/post blocks) don't expect scrollbar overflow.
          contentOverflowRect.expandVerticallyToContain(other: borderBox)
        }
      } else if inlineLevelBox.isLineBreakBox() {
        borderBox = lineBox.logicalBorderBoxForInlineBox(
          layoutBox: layoutBox,
          boxGeometry: formattingContext().geometryForBox(layoutBox: layoutBox))
        borderBox.moveBy(offset: lineBoxRect.topLeft())
      } else {
        fatalError("Not reached")
      }

      let adjustedBorderBoxTop = borderBox.top() - (inlineLevelBox.textEmphasisAbove() ?? 0)
      let adjustedBorderBoxBottom = borderBox.bottom() + (inlineLevelBox.textEmphasisBelow() ?? 0)
      enclosingTop = min(enclosingTop ?? adjustedBorderBoxTop, adjustedBorderBoxTop)
      enclosingBottom = max(enclosingBottom ?? adjustedBorderBoxBottom, adjustedBorderBoxBottom)
    }
    return EnclosingLineGeometry(
      enclosingTopAndBottom: InlineDisplay.Line.EnclosingTopAndBottom(
        top: enclosingTop ?? lineBoxRect.top(), bottom: enclosingBottom ?? lineBoxRect.top()),
      contentOverflowRect: contentOverflowRect)
  }

  static func initialEnclosingTopAndBottom(
    lineBox: LineBox, rootInlineBox: InlineLevelBox, lineBoxRect: InlineRect
  ) -> (
    InlineLayoutUnit?, InlineLayoutUnit?
  ) {
    if !lineBox.hasContent || !rootInlineBox.hasContent {
      return (nil, nil)
    }
    return (
      lineBoxRect.top() + rootInlineBox.logicalTop() - (rootInlineBox.textEmphasisAbove() ?? 0),
      lineBoxRect.top() + rootInlineBox.logicalBottom() + (rootInlineBox.textEmphasisBelow() ?? 0)
    )
  }

  func contentOverflowRect(
    lineLayoutResult: LineLayoutResult, lineBox: LineBox, lineBoxRect: InlineRect
  ) -> InlineRect {
    var rect = lineBoxRect
    var rootInlineBoxWidth = lineBox.logicalRectForRootInlineBox().width()
    let isLeftToRightDirection = root().style.isLeftToRightDirection()
    if lineLayoutResult.hangingContent.shouldContributeToScrollableOverflow {
      rect.expandHorizontally(delta: lineLayoutResult.hangingContent.logicalWidth)
    } else if !isLeftToRightDirection {
      // This is to balance hanging RTL trailing content. See LineBoxBuilder::build.
      rootInlineBoxWidth -= lineLayoutResult.hangingContent.logicalWidth
    }
    let rootInlineBoxHorizontalOverflow = rootInlineBoxWidth - rect.width()
    if rootInlineBoxHorizontalOverflow > 0 {
      isLeftToRightDirection
        ? rect.shiftRightBy(offset: rootInlineBoxHorizontalOverflow)
        : rect.shiftLeftBy(offset: -rootInlineBoxHorizontalOverflow)
    }
    return rect
  }

  func formattingContext() -> InlineFormattingContext {
    return inlineFormattingContext
  }

  func root() -> BoxWrapper {
    return formattingContext().root()
  }

  var inlineFormattingContext: InlineFormattingContext
  var constraints: ConstraintsForInlineContent
}
