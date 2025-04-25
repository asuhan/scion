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

struct TextOnlyLineBreakResult {
  var isEndOfLine: InlineContentBreaker.IsEndOfLine = .Yes
  var committedCount: UInt64 = 0
  var overflowingContentLength: UInt64 = 0
  var overflowLogicalWidth: InlineLayoutUnit? = nil
  var isRevert = false
}

struct CandidateTextContent {
  mutating func append(contentWidth: InlineLayoutUnit) {
    logicalWidth += contentWidth
    endIndex += 1
  }

  var startIndex: UInt64 = 0
  var endIndex: UInt64 = 0
  var logicalWidth = InlineLayoutUnit()
}

internal func measuredInlineTextItem(
  inlineTextItem: InlineTextItemWrapper, style: RenderStyleWrapper,
  contentLogicalLeft: InlineLayoutUnit
) -> InlineLayoutUnit {
  assert(inlineTextItem.width() == nil)
  if !inlineTextItem.isWhitespace()
    || InlineTextItemWrapper.shouldPreserveSpacesAndTabs(inlineTextItem: inlineTextItem)
  {
    return TextUtil.width(
      inlineTextItem: inlineTextItem, fontCascade: style.fontCascade(),
      contentLogicalLeft: contentLogicalLeft)
  }
  return TextUtil.width(
    inlineTextItem: inlineTextItem, fontCascade: style.fontCascade(), from: inlineTextItem.start(),
    to: inlineTextItem.start() + 1, contentLogicalLeft: contentLogicalLeft)
}

internal func placedInlineItemEnd(
  layoutRangeStartIndex: UInt64, placedInlineItemCount: UInt64, overflowingContentLength: UInt64,
  inlineItemList: ArraySlice<InlineItemWrapper>
) -> InlineItemPosition {
  if overflowingContentLength == 0 {
    return InlineItemPosition(index: layoutRangeStartIndex + placedInlineItemCount, offset: 0)
  }

  let trailingInlineItemIndex = layoutRangeStartIndex + placedInlineItemCount - 1
  let overflowingInlineTextItemLength =
    (inlineItemList[Int(trailingInlineItemIndex)] as! InlineTextItemWrapper).length
  return InlineItemPosition(
    index: trailingInlineItemIndex,
    offset: UInt64(overflowingInlineTextItemLength) - overflowingContentLength
  )
}

internal func shouldConsumeTrailingLineBreak(
  result: TextOnlyLineBreakResult, trailingInlineItemIndex: UInt64, layoutRangeEnd: UInt64,
  line: Line, inlineItemList: ArraySlice<InlineItemWrapper>
) -> Bool {
  if result.overflowingContentLength != 0 || result.isRevert {
    return false
  }
  return trailingInlineItemIndex < layoutRangeEnd
    && inlineItemList[Int(trailingInlineItemIndex)].isLineBreak()
}

internal func isLastLineWithInlineContent(
  placedContentEnd: InlineItemPosition, layoutRangeEndIndex: UInt64
) -> Bool {
  return placedContentEnd.index == layoutRangeEndIndex && placedContentEnd.offset == 0
}

internal func consumeTrailingLineBreakIfApplicable(
  result: TextOnlyLineBreakResult, trailingInlineItemIndex: UInt64, layoutRangeEnd: UInt64,
  line: inout Line, inlineItemList: ArraySlice<InlineItemWrapper>
) -> Bool {
  if !shouldConsumeTrailingLineBreak(
    result: result, trailingInlineItemIndex: trailingInlineItemIndex,
    layoutRangeEnd: layoutRangeEnd, line: line, inlineItemList: inlineItemList)
  {
    return false
  }
  let trailingLineBreak = inlineItemList[Int(trailingInlineItemIndex)]
  assert(trailingLineBreak.isLineBreak())
  line.append(
    inlineItem: trailingLineBreak, style: trailingLineBreak.style(),
    logicalWidth: InlineLayoutUnit())
  return true
}

internal func contentWidthWithOffset(
  inlineTextItem: InlineTextItemWrapper, rootStyle: RenderStyleWrapper,
  totalOffset: InlineLayoutUnit
) -> InlineLayoutUnit {
  if let logicalWidth = inlineTextItem.width() {
    return logicalWidth
  }
  return measuredInlineTextItem(
    inlineTextItem: inlineTextItem, style: rootStyle,
    contentLogicalLeft: totalOffset)
}

final class TextOnlySimpleLineBuilder: AbstractLineBuilder {
  override init(
    inlineFormattingContext: InlineFormattingContext, rootBox: ElementBoxWrapper,
    rootHorizontalConstraints: HorizontalConstraints, inlineItemList: InlineItemList
  ) {
    super.init(
      inlineFormattingContext: inlineFormattingContext, rootBox: rootBox,
      rootHorizontalConstraints: rootHorizontalConstraints, inlineItemList: inlineItemList)
    self.isWrappingAllowed = TextUtil.isWrappingAllowed(style: rootStyle())
  }

  override func layoutInlineContent(lineInput: LineInput, previousLine: PreviousLine?)
    -> LineLayoutResult
  {
    initialize(
      layoutRange: lineInput.needsLayoutRange, initialLogicalRect: lineInput.initialLogicalRect,
      previousLine: previousLine)
    let rootStyle = self.rootStyle()
    let placedContentEnd =
      isWrappingAllowed
      ? placeInlineTextContent(rootStyle: rootStyle, layoutRange: lineInput.needsLayoutRange)
      : placeNonWrappingInlineTextContent(
        rootStyle: rootStyle, layoutRange: lineInput.needsLayoutRange)
    let result = line.close()

    let isLastInlineContent = isLastLineWithInlineContent(
      placedContentEnd: placedContentEnd, layoutRangeEndIndex: lineInput.needsLayoutRange.endIndex()
    )
    let contentLogicalLeft = InlineFormattingUtils.horizontalAlignmentOffset(
      rootStyle: rootStyle, contentLogicalRightIn: result.contentLogicalRight,
      lineLogicalWidth: lineLogicalRect.width(),
      hangingTrailingWidth: result.hangingTrailingContentWidth, runs: result.runs,
      isLastLine: isLastInlineContent)
    return LineLayoutResult(
      inlineItemRange: InlineItemRange(
        start: lineInput.needsLayoutRange.start, end: placedContentEnd),
      inlineContent: result.runs,
      floatContent: LineLayoutResult.FloatContent(),
      contentGeometry: LineLayoutResult.ContentGeometry(
        logicalLeft: contentLogicalLeft,
        logicalWidth: result.contentLogicalWidth,
        logicalRightIncludingNegativeMargin: contentLogicalLeft + result.contentLogicalRight,
        trailingOverflowingContentWidth: overflowContentLogicalWidth),
      lineGeometry: LineLayoutResult.LineGeometry(
        logicalTopLeft: lineLogicalRect.topLeft(),
        logicalWidth: lineLogicalRect.width(),
        initialLogicalLeftIncludingIntrusiveFloats: lineLogicalRect.left()
      ),
      hangingContent: LineLayoutResult.HangingContent(
        shouldContributeToScrollableOverflow: !result.isHangingTrailingContentWhitespace,
        logicalWidth: result.hangingTrailingContentWidth
      ),
      directionality: LineLayoutResult.Directionality(),
      isFirstLast: LineLayoutResult.IsFirstLast(
        isFirstFormattedLine: isFirstFormattedLine()
          ? LineLayoutResult.IsFirstLast.FirstFormattedLine.WithinIFC
          : LineLayoutResult.IsFirstLast.FirstFormattedLine.No,
        isLastLineWithInlineContent: isLastInlineContent
      ),
      ruby: LineLayoutResult.Ruby(),
      endsWithHyphen: false,
      nonSpanningInlineLevelBoxCount: 0,
      trimmedTrailingWhitespaceWidth: trimmedTrailingWhitespaceWidth
    )
  }

  static func isEligibleForSimplifiedTextOnlyInlineLayoutByContent(
    inlineItems: InlineContentCache.InlineItems, placedFloats: PlacedFloats
  ) -> Bool {
    if inlineItems.isEmpty() {
      return false
    }
    if !inlineItems.hasTextAndLineBreakOnlyContent() || inlineItems.hasInlineBoxes()
      || inlineItems.requiresVisualReordering()
    {
      return false
    }
    if !placedFloats.isEmpty() {
      return false
    }

    return true
  }

  static func isEligibleForSimplifiedInlineLayoutByStyle(style: RenderStyleWrapper) -> Bool {
    if style.fontCascade().wordSpacing() != 0 {
      return false
    }
    if !style.isLeftToRightDirection() {
      return false
    }
    if style.wordBreak() == .AutoPhrase {
      return false
    }
    if style.textIndent() != RenderStyleWrapper.initialTextIndent() {
      return false
    }
    if style.textAlignLast() == .Justify || style.textAlign() == .Justify
      || style.display() == .RubyAnnotation
    {
      return false
    }
    if style.boxDecorationBreak() == .Clone {
      return false
    }
    if !style.hangingPunctuation().isEmpty {
      return false
    }
    if style.hyphenationLimitLines() != RenderStyleWrapper.initialHyphenationLimitLines() {
      return false
    }
    if style.textWrapMode() == .Wrap
      && (style.textWrapStyle() == .Balance || style.textWrapStyle() == .Pretty)
    {
      return false
    }
    if style.lineAlign() != .None || style.lineSnap() != .None {
      return false
    }

    return true
  }

  func isAtSoftWrapOpportunityOrContentEnd(
    inlineTextItem: InlineTextItemWrapper, layoutRange: InlineItemRange, nextItemIndex: UInt64,
    hasWrapOpportunityBeforeWhitespace: Bool
  ) -> Bool {
    // TODO(asuhan): implement this
    if inlineTextItem.isWhitespace() {
      return true
    }
    if nextItemIndex >= layoutRange.endIndex() || inlineItemList[Int(nextItemIndex)].isLineBreak() {
      return true
    }
    let nextInlineTextItem = inlineItemList[Int(nextItemIndex)] as! InlineTextItemWrapper
    if nextInlineTextItem.isWhitespace() {
      return hasWrapOpportunityBeforeWhitespace
    }
    return inlineTextItem.inlineTextBox() == nextInlineTextItem.inlineTextBox()
      || TextUtil.mayBreakInBetween(
        previousInlineItem: inlineTextItem, nextInlineItem: nextInlineTextItem)
  }

  func processCandidateContent(
    rootStyle: RenderStyleWrapper, layoutRange: InlineItemRange,
    candidateContent: inout CandidateTextContent, result: inout TextOnlyLineBreakResult,
    placedInlineItemCount: inout UInt64
  ) -> Bool {
    result = commitCandidateContent(
      rootStyle: rootStyle, candidateContent: candidateContent, layoutRange: layoutRange)
    placedInlineItemCount =
      !result.isRevert ? placedInlineItemCount + result.committedCount : result.committedCount
    candidateContent = CandidateTextContent(
      startIndex: candidateContent.endIndex,
      endIndex: candidateContent.endIndex,
      logicalWidth: InlineLayoutUnit()
    )
    return result.isEndOfLine == .Yes
  }

  func contentWidth(
    inlineTextItem: InlineTextItemWrapper, rootStyle: RenderStyleWrapper,
    candidateContent: CandidateTextContent, wrapping: Bool
  )
    -> InlineLayoutUnit
  {
    return contentWidthWithOffset(
      inlineTextItem: inlineTextItem, rootStyle: rootStyle,
      totalOffset: (wrapping ? line.contentLogicalRight() : 0)
        + candidateContent.logicalWidth)
  }

  func placeInlineTextContent(rootStyle: RenderStyleWrapper, layoutRange: InlineItemRange)
    -> InlineItemPosition
  {
    let hasWrapOpportunityBeforeWhitespace =
      rootStyle.whiteSpaceCollapse() != .BreakSpaces && rootStyle.lineBreak() != .AfterWhiteSpace
    var placedInlineItemCount: UInt64 = 0
    var result = TextOnlyLineBreakResult()
    var candidateContent = CandidateTextContent(
      startIndex: layoutRange.startIndex(),
      endIndex: layoutRange.startIndex(),
      logicalWidth: InlineLayoutUnit()
    )

    var nextItemIndex = layoutRange.startIndex()

    // Handle leading partial content first (overflowing text from the previous line).
    var isEndOfLine = false
    if partialLeadingTextItem != nil {
      candidateContent.append(contentWidth: InlineLayoutUnit())
      nextItemIndex += 1
      if isAtSoftWrapOpportunityOrContentEnd(
        inlineTextItem: partialLeadingTextItem!, layoutRange: layoutRange,
        nextItemIndex: nextItemIndex,
        hasWrapOpportunityBeforeWhitespace: hasWrapOpportunityBeforeWhitespace)
      {
        isEndOfLine = processCandidateContent(
          rootStyle: rootStyle, layoutRange: layoutRange, candidateContent: &candidateContent,
          result: &result, placedInlineItemCount: &placedInlineItemCount)
      }
    }

    while !isEndOfLine && nextItemIndex < layoutRange.endIndex() {
      let inlineItem = inlineItemList[Int(nextItemIndex)]
      nextItemIndex += 1
      assert(inlineItem.isText() || inlineItem.isLineBreak())

      if let inlineTextItem = inlineItem as? InlineTextItemWrapper {
        candidateContent.append(
          contentWidth: contentWidth(
            inlineTextItem: inlineTextItem, rootStyle: rootStyle,
            candidateContent: candidateContent, wrapping: true
          ))
        if isAtSoftWrapOpportunityOrContentEnd(
          inlineTextItem: inlineTextItem, layoutRange: layoutRange,
          nextItemIndex: nextItemIndex,
          hasWrapOpportunityBeforeWhitespace: hasWrapOpportunityBeforeWhitespace)
        {
          isEndOfLine = processCandidateContent(
            rootStyle: rootStyle, layoutRange: layoutRange, candidateContent: &candidateContent,
            result: &result, placedInlineItemCount: &placedInlineItemCount)
        }
        continue
      }
      if inlineItem.isLineBreak() {
        isEndOfLine = true
        result = TextOnlyLineBreakResult()
        continue
      }
    }
    if consumeTrailingLineBreakIfApplicable(
      result: result, trailingInlineItemIndex: layoutRange.startIndex() + placedInlineItemCount,
      layoutRangeEnd: layoutRange.endIndex(), line: &line, inlineItemList: inlineItemList)
    {
      placedInlineItemCount += 1
    }
    assert(placedInlineItemCount != 0)
    let placedContentEnd = placedInlineItemEnd(
      layoutRangeStartIndex: layoutRange.startIndex(), placedInlineItemCount: placedInlineItemCount,
      overflowingContentLength: result.overflowingContentLength,
      inlineItemList: inlineItemList)
    handleLineEnding(
      rootStyle: rootStyle, placedContentEnd: placedContentEnd,
      layoutRangeEndIndex: layoutRange.endIndex())
    overflowContentLogicalWidth = result.overflowLogicalWidth
    return placedContentEnd
  }

  func placeNonWrappingInlineTextContent(
    rootStyle: RenderStyleWrapper, layoutRange: InlineItemRange
  ) -> InlineItemPosition {
    // TODO(asuhan): implement this
    assert(!TextUtil.isWrappingAllowed(style: rootStyle))
    assert(partialLeadingTextItem == nil)

    var candidateContent = CandidateTextContent(
      startIndex: layoutRange.startIndex(), endIndex: layoutRange.startIndex(),
      logicalWidth: InlineLayoutUnit())
    var isEndOfLine = false
    var trailingLineBreakIndex: UInt64? = nil
    var nextItemIndex = layoutRange.startIndex()

    while !isEndOfLine {
      let inlineItem = inlineItemList[Int(nextItemIndex)]
      if let inlineTextItem = inlineItem as? InlineTextItemWrapper {
        candidateContent.append(
          contentWidth: contentWidth(
            inlineTextItem: inlineTextItem, rootStyle: rootStyle,
            candidateContent: candidateContent, wrapping: false
          ))
      } else if inlineItem.isLineBreak() {
        trailingLineBreakIndex = nextItemIndex
      } else {
        assert(false)
        return layoutRange.end
      }
      nextItemIndex += 1
      isEndOfLine = nextItemIndex >= layoutRange.endIndex() || trailingLineBreakIndex != nil
    }

    if trailingLineBreakIndex != nil && candidateContent.startIndex == candidateContent.endIndex {
      let trailingInlineItem = inlineItemList[Int(trailingLineBreakIndex!)]
      line.append(
        inlineItem: trailingInlineItem, style: trailingInlineItem.style(),
        logicalWidth: InlineLayoutUnit())
      return InlineItemPosition(index: trailingLineBreakIndex! + 1, offset: 0)
    }

    let result = commitCandidateContent(
      rootStyle: rootStyle, candidateContent: candidateContent, layoutRange: layoutRange)
    nextItemIndex = layoutRange.startIndex() + result.committedCount
    if consumeTrailingLineBreakIfApplicable(
      result: result, trailingInlineItemIndex: nextItemIndex,
      layoutRangeEnd: layoutRange.endIndex(), line: &line, inlineItemList: inlineItemList)
    {
      nextItemIndex += 1
    }

    let placedInlineItemCount = nextItemIndex - layoutRange.startIndex()
    let placedContentEnd = placedInlineItemEnd(
      layoutRangeStartIndex: layoutRange.startIndex(), placedInlineItemCount: placedInlineItemCount,
      overflowingContentLength: result.overflowingContentLength, inlineItemList: inlineItemList)
    handleLineEnding(
      rootStyle: rootStyle, placedContentEnd: placedContentEnd,
      layoutRangeEndIndex: layoutRange.endIndex())
    return placedContentEnd
  }

  func handleOverflowingTextContent(
    rootStyle: RenderStyleWrapper, candidateContent: InlineContentBreaker.ContinuousContent,
    layoutRange: InlineItemRange
  ) -> TextOnlyLineBreakResult {
    assert(!candidateContent.runs.isEmpty)

    let availableWidth = availableWidth()
    var lineBreakingResult = InlineContentBreaker.Result(
      action: .Keep, isEndOfLine: .No, partialTrailingContent: nil, lastWrapOpportunityItem: nil
    )
    if candidateContent.logicalWidth() > availableWidth {
      let lineStatus = InlineContentBreaker.LineStatus(
        contentLogicalRight: line.contentLogicalRight(),
        availableWidth: availableWidth,
        trimmableOrHangingWidth: line.trimmableTrailingWidth(),
        trailingSoftHyphenWidth: line.trailingSoftHyphenWidth,
        hasFullyTrimmableTrailingContent: line.isTrailingRunFullyTrimmable(),
        hasContent: line.hasContentOrListMarker(),
        hasWrapOpportunityAtPreviousPosition: !wrapOpportunityList.isEmpty
      )
      lineBreakingResult = inlineContentBreaker.processInlineContent(
        candidateContent: candidateContent, lineStatus: lineStatus)
    }

    if lineBreakingResult.action == .Keep {
      let committedRuns = candidateContent.runs
      for run in committedRuns {
        line.appendTextFast(
          inlineTextItem: run.inlineItem as! InlineTextItemWrapper, style: run.style,
          logicalWidth: run.contentWidth)
      }
      if line.hasContentOrListMarker() {
        wrapOpportunityList.append(committedRuns.last!.inlineItem)
      }
      return TextOnlyLineBreakResult(
        isEndOfLine: lineBreakingResult.isEndOfLine, committedCount: UInt64(committedRuns.count))
    }

    assert(lineBreakingResult.isEndOfLine == .Yes)

    if lineBreakingResult.action == .Wrap {
      return TextOnlyLineBreakResult(
        isEndOfLine: .Yes,
        committedCount: UInt64(0),
        overflowingContentLength: UInt64(0),
        overflowLogicalWidth: eligibleOverflowWidthAsLeading(
          candidateRuns: candidateContent.runs, lineBreakingResult: lineBreakingResult,
          isFirstFormattedLine: isFirstFormattedLine())
      )
    }

    if lineBreakingResult.action == .WrapWithHyphen {
      assert(line.trailingSoftHyphenWidth != nil)
      line.addTrailingHyphen(hyphenLogicalWidth: line.trailingSoftHyphenWidth!)
      return TextOnlyLineBreakResult(isEndOfLine: .Yes)
    }

    if lineBreakingResult.action == .Break {
      return processPartialContent(
        lineBreakingResult: lineBreakingResult, candidateContent: candidateContent)
    }

    // Revert to a previous position cases.
    if wrapOpportunityList.isEmpty {
      assert(false)
      return TextOnlyLineBreakResult(isEndOfLine: .Yes)
    }

    if lineBreakingResult.action == .RevertToLastWrapOpportunity {
      return TextOnlyLineBreakResult(
        isEndOfLine: .Yes,
        committedCount: revertToTrailingItem(
          rootStyle: rootStyle, layoutRange: layoutRange,
          trailingInlineItem: wrapOpportunityList.last as! InlineTextItemWrapper),
        overflowingContentLength: UInt64(0),
        overflowLogicalWidth: nil,
        isRevert: true)
    }

    if lineBreakingResult.action == .RevertToLastNonOverflowingWrapOpportunity {
      return TextOnlyLineBreakResult(
        isEndOfLine: .Yes,
        committedCount: revertToLastNonOverflowingItem(
          rootStyle: rootStyle, layoutRange: layoutRange),
        overflowingContentLength: UInt64(0),
        overflowLogicalWidth: nil,
        isRevert: true)
    }

    assert(false)
    return TextOnlyLineBreakResult(isEndOfLine: .Yes)
  }

  private func processPartialContent(
    lineBreakingResult: InlineContentBreaker.Result,
    candidateContent: InlineContentBreaker.ContinuousContent
  )
    -> TextOnlyLineBreakResult
  {
    if lineBreakingResult.partialTrailingContent == nil {
      fatalError("Not reached")
    }
    let trailingRunIndex = lineBreakingResult.partialTrailingContent!.trailingRunIndex
    let runs = candidateContent.runs
    for index in 0..<trailingRunIndex {
      let run = runs[Int(index)]
      line.appendTextFast(
        inlineTextItem: run.inlineItem as! InlineTextItemWrapper, style: run.style,
        logicalWidth: run.contentWidth)
    }

    let committedInlineItemCount = trailingRunIndex + 1
    let trailingRun = runs[Int(trailingRunIndex)]
    if lineBreakingResult.partialTrailingContent!.partialRun == nil {
      line.appendTextFast(
        inlineTextItem: trailingRun.inlineItem as! InlineTextItemWrapper, style: trailingRun.style,
        logicalWidth: trailingRun.contentWidth)
      if let hyphenWidth = lineBreakingResult.partialTrailingContent!.hyphenWidth {
        line.addTrailingHyphen(hyphenLogicalWidth: hyphenWidth)
      }
      return TextOnlyLineBreakResult(isEndOfLine: .Yes, committedCount: committedInlineItemCount)
    }

    let partialRun = lineBreakingResult.partialTrailingContent!.partialRun!
    let trailingInlineTextItem = runs[Int(trailingRunIndex)].inlineItem as! InlineTextItemWrapper
    line.appendTextFast(
      inlineTextItem: trailingInlineTextItem.left(length: UInt32(partialRun.length)),
      style: trailingRun.style,
      logicalWidth: partialRun.logicalWidth)
    if let hyphenWidth = partialRun.hyphenWidth {
      line.addTrailingHyphen(hyphenLogicalWidth: hyphenWidth)
    }
    let overflowingContentLength = UInt64(trailingInlineTextItem.length) - partialRun.length
    return TextOnlyLineBreakResult(
      isEndOfLine: .Yes,
      committedCount: committedInlineItemCount,
      overflowingContentLength: overflowingContentLength,
      overflowLogicalWidth: eligibleOverflowWidthAsLeading(
        candidateRuns: candidateContent.runs, lineBreakingResult: lineBreakingResult,
        isFirstFormattedLine: isFirstFormattedLine())
    )
  }

  func commitCandidateContent(
    rootStyle: RenderStyleWrapper, candidateContent: CandidateTextContent,
    layoutRange: InlineItemRange
  ) -> TextOnlyLineBreakResult {
    // TODO(asuhan): implement this
    let hasLeadingPartialContent =
      partialLeadingTextItem != nil && candidateContent.startIndex == layoutRange.startIndex()

    if candidateContent.logicalWidth <= availableWidth() && !hasLeadingPartialContent {
      for index in candidateContent.startIndex..<candidateContent.endIndex {
        let inlineTextItem = inlineItemList[Int(index)] as! InlineTextItemWrapper
        line.appendTextFast(
          inlineTextItem: inlineTextItem, style: rootStyle,
          logicalWidth: contentWidthWithOffset(
            inlineTextItem: inlineTextItem, rootStyle: rootStyle,
            totalOffset: line.contentLogicalRight()
          ))
      }

      if line.hasContentOrListMarker() {
        wrapOpportunityList.append(inlineItemList[Int(candidateContent.endIndex - 1)])
      }
      return TextOnlyLineBreakResult(
        isEndOfLine: InlineContentBreaker.IsEndOfLine.No,
        committedCount: candidateContent.endIndex - candidateContent.startIndex
      )
    }

    var candidateContentForLineBreaking = InlineContentBreaker.ContinuousContent()
    var startIndex = candidateContent.startIndex

    if hasLeadingPartialContent {
      candidateContentForLineBreaking.appendTextContent(
        inlineTextItem: partialLeadingTextItem!, style: rootStyle,
        logicalWidth: contentWidthWithOffset(
          inlineTextItem: partialLeadingTextItem!, rootStyle: rootStyle,
          totalOffset: line.contentLogicalRight()
        ))
      startIndex += 1
    }
    for index in startIndex..<candidateContent.endIndex {
      let inlineTextItem = inlineItemList[Int(index)] as! InlineTextItemWrapper
      candidateContentForLineBreaking.appendTextContent(
        inlineTextItem: inlineTextItem, style: rootStyle,
        logicalWidth: contentWidthWithOffset(
          inlineTextItem: inlineTextItem, rootStyle: rootStyle,
          totalOffset: line.contentLogicalRight() + candidateContentForLineBreaking.logicalWidth()
        ))
    }
    return handleOverflowingTextContent(
      rootStyle: rootStyle, candidateContent: candidateContentForLineBreaking,
      layoutRange: layoutRange)
  }

  func initialize(
    layoutRange: InlineItemRange, initialLogicalRect: InlineRect, previousLine: PreviousLine?
  ) {
    reset()

    assert(
      !layoutRange.isEmpty() || (previousLine != nil && !previousLine!.suspendedFloats.isEmpty))
    partialLeadingTextItem = partialLeadingTextItem(
      layoutRange: layoutRange, previousLine: previousLine)
    line.initialize(lineSpanningInlineBoxes: [], isFirstFormattedLine: isFirstFormattedLine())
    self.previousLine = previousLine
    lineLogicalRect = initialLogicalRect
    trimmedTrailingWhitespaceWidth = InlineLayoutUnit()
    overflowContentLogicalWidth = nil
  }

  func handleLineEnding(
    rootStyle: RenderStyleWrapper, placedContentEnd: InlineItemPosition, layoutRangeEndIndex: UInt64
  ) {
    let horizontalAvailableSpace = lineLogicalRect.width()
    let isLastInlineContent = isLastLineWithInlineContent(
      placedContentEnd: placedContentEnd, layoutRangeEndIndex: layoutRangeEndIndex)
    trimmedTrailingWhitespaceWidth = line.handleTrailingTrimmableContent(
      trailingTrimmableContentAction: shouldPreserveTrailingWhitespace(
        rootStyle: rootStyle, horizontalAvailableSpace: horizontalAvailableSpace,
        isLastInlineContent: isLastInlineContent)
        ? .Preserve : .Remove)
    if formattingContext().quirks().trailingNonBreakingSpaceNeedsAdjustment(
      isInIntrinsicWidthMode: isInIntrinsicWidthMode(),
      lineHasOverflow: horizontalAvailableSpace < line.contentLogicalWidth)
    {
      line.handleOverflowingNonBreakingSpace(
        trailingContentAction: shouldPreserveTrailingWhitespace(
          rootStyle: rootStyle, horizontalAvailableSpace: horizontalAvailableSpace,
          isLastInlineContent: isLastInlineContent) ? .Preserve : .Remove,
        overflowingWidth: line.contentLogicalWidth - horizontalAvailableSpace)
    }
    line.handleTrailingHangingContent(
      intrinsicWidthMode: intrinsicWidthMode,
      horizontalAvailableSpaceForContent: horizontalAvailableSpace,
      isLastFormattedLine: isLastInlineContent)
  }

  func shouldPreserveTrailingWhitespace(
    rootStyle: RenderStyleWrapper, horizontalAvailableSpace: InlineLayoutUnit,
    isLastInlineContent: Bool
  ) -> Bool {
    return rootStyle.lineBreak() == .AfterWhiteSpace && intrinsicWidthMode != .Minimum
      && (!isLastInlineContent || horizontalAvailableSpace < line.contentLogicalWidth)
  }

  func partialLeadingTextItem(layoutRange: InlineItemRange, previousLine: PreviousLine?)
    -> InlineTextItemWrapper?
  {
    // TODO(asuhan): implement this
    if previousLine == nil || layoutRange.start.offset == 0 {
      return nil
    }

    let overflowingInlineTextItem =
      inlineItemList[Int(layoutRange.start.index)] as! InlineTextItemWrapper
    assert(layoutRange.start.offset < overflowingInlineTextItem.length)
    let overflowingLength = overflowingInlineTextItem.length - UInt32(layoutRange.start.offset)
    if overflowingLength != 0 {
      // Turn previous line's overflow content into the next line's leading content.
      // "sp[<-line break->]lit_content" -> break position: 2 -> leading partial content length: 11.
      return overflowingInlineTextItem.right(
        length: overflowingLength, width: previousLine!.trailingOverflowingContentWidth)
    }
    return nil
  }

  private func revertToTrailingItem(
    rootStyle: RenderStyleWrapper, layoutRange: InlineItemRange,
    trailingInlineItem: InlineTextItemWrapper
  ) -> UInt64 {
    let isFirstFormattedLine = isFirstFormattedLine()
    line.initialize(lineSpanningInlineBoxes: [], isFirstFormattedLine: isFirstFormattedLine)
    var numberOfInlineItemsOnLine: UInt64 = 0

    if partialLeadingTextItem != nil
      && appendTextInlineItem(
        inlineTextItem: partialLeadingTextItem!,
        rootStyle: rootStyle,
        trailingInlineItem: trailingInlineItem,
        numberOfInlineItemsOnLine: &numberOfInlineItemsOnLine)
    {
      return numberOfInlineItemsOnLine
    }
    for index in layoutRange.startIndex() + numberOfInlineItemsOnLine..<layoutRange.endIndex() {
      if appendTextInlineItem(
        inlineTextItem: inlineItemList[Int(index)] as! InlineTextItemWrapper,
        rootStyle: rootStyle,
        trailingInlineItem: trailingInlineItem,
        numberOfInlineItemsOnLine: &numberOfInlineItemsOnLine)
      {
        return numberOfInlineItemsOnLine
      }
    }
    assert(false)
    return 0
  }

  func appendTextInlineItem(
    inlineTextItem: InlineTextItemWrapper, rootStyle: RenderStyleWrapper,
    trailingInlineItem: InlineTextItemWrapper,
    numberOfInlineItemsOnLine: inout UInt64
  ) -> Bool {
    let logicalWidth =
      inlineTextItem.width() != nil
      ? inlineTextItem.width()!
      : measuredInlineTextItem(
        inlineTextItem: inlineTextItem, style: rootStyle,
        contentLogicalLeft: line.contentLogicalRight())
    line.appendTextFast(
      inlineTextItem: inlineTextItem, style: rootStyle, logicalWidth: logicalWidth)
    numberOfInlineItemsOnLine += 1
    return ObjectIdentifier(inlineTextItem) == ObjectIdentifier(trailingInlineItem)
  }

  func revertToLastNonOverflowingItem(rootStyle: RenderStyleWrapper, layoutRange: InlineItemRange)
    -> UInt64
  {
    // Revert all the way back to a wrap opportunity when either a soft hyphen fits or no hyphen is required.
    for (i, wrapOpportunity) in wrapOpportunityList.enumerated().reversed() {
      let committedCount = revertToTrailingItem(
        rootStyle: rootStyle, layoutRange: layoutRange,
        trailingInlineItem: wrapOpportunity as! InlineTextItemWrapper)
      let trailingSoftHyphenWidth = line.trailingSoftHyphenWidth

      let hasRevertedEnough =
        i == 0 || trailingSoftHyphenWidth == nil || trailingSoftHyphenWidth! <= availableWidth()
      if hasRevertedEnough {
        if trailingSoftHyphenWidth != nil {
          line.addTrailingHyphen(hyphenLogicalWidth: trailingSoftHyphenWidth!)
        }
        return committedCount
      }
    }
    assert(false)
    return 0
  }

  func availableWidth() -> InlineLayoutUnit {
    let epsilon = intrinsicWidthMode == .Minimum ? 0 : LayoutUnit.epsilon()
    let contentLogicalRight = line.contentLogicalRight()
    return (lineLogicalRect.width() + epsilon)
      - (!contentLogicalRight.isNaN ? contentLogicalRight : 0)
  }

  var isWrappingAllowed = false
  var trimmedTrailingWhitespaceWidth = InlineLayoutUnit()
  var overflowContentLogicalWidth: InlineLayoutUnit? = nil
}
