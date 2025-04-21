/*
 * Copyright (C) 2018 Apple Inc. All rights reserved.
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

import Foundation

internal func endsWithSoftWrapOpportunity(
  previousInlineTextItem: InlineTextItemWrapper, nextInlineTextItem: InlineTextItemWrapper
) -> Bool {
  assert(!nextInlineTextItem.isWhitespace())
  // We are at the position after a whitespace.
  if previousInlineTextItem.isWhitespace() {
    return true
  }
  // When both these non-whitespace runs belong to the same layout box with the same bidi level, it's guaranteed that
  // they are split at a soft breaking opportunity. See InlineItemsBuilder::moveToNextBreakablePosition.
  if previousInlineTextItem.inlineTextBox() === nextInlineTextItem.inlineTextBox() {
    if previousInlineTextItem.bidiLevel == nextInlineTextItem.bidiLevel {
      return true
    }
    // The bidi boundary may or may not be the reason for splitting the inline text box content.
    // FIXME: We could add a "reason flag" to InlineTextItem to tell why the split happened.
    let style = previousInlineTextItem.style()
    let lineBreakIteratorFactory = CachedLineBreakIteratorFactoryWrapper(
      stringView: StringWrapperView(s: previousInlineTextItem.inlineTextBox().content),
      locale: style.computedLocale(),
      mode: TextUtil.lineBreakIteratorMode(lineBreak: style.lineBreak()),
      contentAnalysis: TextUtil.contentAnalysis(wordBreak: style.wordBreak())
    )
    let softWrapOpportunityCandidate = nextInlineTextItem.start()
    return TextUtil.findNextBreakablePosition(
      lineBreakIteratorFactory: lineBreakIteratorFactory,
      startPosition: softWrapOpportunityCandidate, style: style) == softWrapOpportunityCandidate
  }
  return TextUtil.mayBreakInBetween(
    previousInlineItem: previousInlineTextItem, nextInlineItem: nextInlineTextItem)
}

internal func nearestCommonAncestor(
  first: BoxWrapper, second: BoxWrapper, rootBox: ElementBoxWrapper
) -> ElementBoxWrapper {
  let firstParent = first.parent()
  let secondParent = second.parent()
  // Cover a few common cases first.
  // 'some content'
  if CPtrToInt(firstParent.p) == CPtrToInt(secondParent.p) {
    return firstParent
  }
  // some<span>content</span>
  if CPtrToInt(secondParent.p) != CPtrToInt(rootBox.p)
    && CPtrToInt(secondParent.parent().p) == CPtrToInt(firstParent.p)
  {
    return firstParent
  }
  // <span>some</span>content
  if CPtrToInt(firstParent.p) != CPtrToInt(rootBox.p)
    && CPtrToInt(firstParent.parent().p) == CPtrToInt(secondParent.p)
  {
    return secondParent
  }
  // <span>some</span><span>content</span>
  if CPtrToInt(firstParent.p) != CPtrToInt(rootBox.p)
    && CPtrToInt(secondParent.p) != CPtrToInt(rootBox.p)
    && CPtrToInt(firstParent.parent().p) == CPtrToInt(secondParent.parent().p)
  {
    return firstParent.parent()
  }

  var descendantsSet: Set<UInt> = []
  var descendant = firstParent
  while CPtrToInt(descendant.p) != CPtrToInt(rootBox.p) {
    descendantsSet.insert(CPtrToInt(descendant.p))
    descendant = descendant.parent()
  }
  descendant = secondParent
  while CPtrToInt(descendant.p) != CPtrToInt(rootBox.p) {
    let (inserted, _) = descendantsSet.insert(CPtrToInt(descendant.p))
    if inserted {
      return descendant
    }
    descendant = descendant.parent()
  }
  return rootBox
}

struct InlineFormattingUtils {
  init(inlineFormattingContext: InlineFormattingContext) {
    self.inlineFormattingContext = inlineFormattingContext
  }

  func logicalTopForNextLine(
    lineLayoutResult: LineLayoutResult, lineLogicalRect: InlineRect,
    floatingContext: FloatingContext
  ) -> InlineLayoutUnit {
    let didManageToPlaceInlineContentOrFloat = !lineLayoutResult.inlineItemRange.isEmpty()
    if didManageToPlaceInlineContentOrFloat {
      // Normally the next line's logical top is the previous line's logical bottom, but when the line ends
      // with the clear property set, the next line needs to clear the existing floats.
      if lineLayoutResult.inlineContent.isEmpty {
        return lineLogicalRect.bottom()
      }
      let lastRunLayoutBox = lineLayoutResult.inlineContent.last!.layoutBox
      if !lastRunLayoutBox.hasFloatClear() || lastRunLayoutBox.isOutOfFlowPositioned() {
        return lineLogicalRect.bottom()
      }
      let positionWithClearance = floatingContext.verticalPositionWithClearance(
        layoutBox: lastRunLayoutBox,
        boxGeometry: formattingContext().geometryForBox(layoutBox: lastRunLayoutBox))
      if positionWithClearance == nil {
        return lineLogicalRect.bottom()
      }
      return max(
        lineLogicalRect.bottom(), InlineLayoutUnit(positionWithClearance!.position.float()))
    }

    if let firstAvailableVerticalPosition = intrusiveFloatBottom(
      lineLayoutResult: lineLayoutResult, lineLogicalRect: lineLogicalRect,
      floatingContext: floatingContext)
    {
      return firstAvailableVerticalPosition
    }
    // Do not get stuck on the same vertical position even when we find ourselves in this unexpected state.
    return ceilf(nextafterf(lineLogicalRect.bottom(), Float32.greatestFiniteMagnitude))
  }

  func intrusiveFloatBottom(
    lineLayoutResult: LineLayoutResult, lineLogicalRect: InlineRect,
    floatingContext: FloatingContext
  )
    -> InlineLayoutUnit?
  {
    // Floats must have prevented us placing any content on the line.
    // Move next line below the intrusive float(s).
    assert(
      lineLayoutResult.inlineContent.isEmpty
        || lineLayoutResult.inlineContent[0].isLineSpanningInlineBoxStart())
    let floatConstraints = floatingContext.constraints(
      candidateTop: toLayoutUnit(value: lineLogicalRect.top()),
      candidateBottom: nextLineLogicalTop(
        lineLayoutResult: lineLayoutResult, lineLogicalRect: lineLogicalRect),
      mayBeAboveLastFloat: .Yes
    )
    if floatConstraints.left != nil && floatConstraints.right != nil {
      // In case of left and right constraints, we need to pick the one that's closer to the current line.
      return min(floatConstraints.left!.y, floatConstraints.right!.y).float()
    }
    if floatConstraints.left != nil {
      return floatConstraints.left!.y.float()
    }
    if floatConstraints.right != nil {
      return floatConstraints.right!.y.float()
    }
    // If we didn't manage to place a content on this vertical position due to intrusive floats, we have to have
    // at least one float here.
    fatalError("Not reached")
    // return nil
  }

  func nextLineLogicalTop(lineLayoutResult: LineLayoutResult, lineLogicalRect: InlineRect)
    -> LayoutUnit
  {
    if let nextLineLogicalTopCandidate = lineLayoutResult.hintForNextLineTopToAvoidIntrusiveFloat {
      return LayoutUnit(value: nextLineLogicalTopCandidate)
    }
    // We have to have a hint when intrusive floats prevented any inline content placement.
    fatalError("Not reached")
    /*
    return LayoutUnit(
      value: lineLogicalRect.top() + formattingContext().root().style.computedLineHeight())
    */
  }

  enum IsIntrinsicWidthMode: UInt8 {
    case No
    case Yes
  }

  func computedTextIndent(
    isIntrinsicWidthMode: IsIntrinsicWidthMode, previousLineEndsWithLineBreak: Bool?,
    availableWidth: InlineLayoutUnit
  ) -> InlineLayoutUnit {
    // TODO(asuhan): implement this
    let root = formattingContext().root()

    // text-indent property specifies the indentation applied to lines of inline content in a block.
    // The indent is treated as a margin applied to the start edge of the line box.
    // The first formatted line of an element is always indented. For example, the first line of an anonymous block box
    // is only affected if it is the first child of its parent element.
    // If 'each-line' is specified, indentation also applies to all lines where the previous line ends with a hard break.
    // [Integration] root()->parent() would normally produce a valid layout box.
    var shouldIndent = false
    if previousLineEndsWithLineBreak == nil {
      shouldIndent = !root.isAnonymous()
      if root.isAnonymous() {
        if !root.isInlineIntegrationRoot() {
          shouldIndent = root.parent().firstInFlowChild() === root
        } else {
          shouldIndent = root.isFirstChildForIntegration()
        }
      }
    } else {
      shouldIndent = root.style.textIndentLine() == .EachLine && previousLineEndsWithLineBreak!
    }

    // Specifying 'hanging' inverts whether the line should be indented or not.
    if root.style.textIndentType() == .Hanging {
      shouldIndent = !shouldIndent
    }

    if !shouldIndent {
      return InlineLayoutUnit()
    }

    let textIndent = root.style.textIndent()
    if textIndent == RenderStyleWrapper.initialTextIndent() {
      return InlineLayoutUnit()
    }
    if isIntrinsicWidthMode == .Yes && textIndent.isPercent() {
      // Percentages must be treated as 0 for the purpose of calculating intrinsic size contributions.
      // https://drafts.csswg.org/css-text/#text-indent-property
      return InlineLayoutUnit()
    }
    return minimumValueForLength(length: textIndent, maximumValue: availableWidth)
      .float()
  }

  func inlineLevelBoxAffectsLineBox(inlineLevelBox: InlineLevelBox) -> Bool {
    if !inlineLevelBox.mayStretchLineBox() {
      return false
    }

    if inlineLevelBox.isLineBreakBox() {
      return false
    }
    if inlineLevelBox.isListMarker() {
      return true
    }
    if inlineLevelBox.isInlineBox() {
      return formattingContext().layoutState().inStandardsMode
        ? true
        : formattingContext().quirks().inlineBoxAffectsLineBox(inlineLevelBox: inlineLevelBox)
    }
    if inlineLevelBox.isAtomicInlineBox() {
      return !inlineLevelBox.layoutBox.isRubyAnnotationBox()
    }
    return false
  }

  func initialLineHeight(isFirstLine: Bool) -> InlineLayoutUnit {
    if formattingContext().layoutState().inStandardsMode {
      return isFirstLine
        ? formattingContext().root().firstLineStyle().computedLineHeight()
        : formattingContext().root().style.computedLineHeight()
    }
    return formattingContext().quirks().initialLineHeight()
  }

  func floatConstraintsForLine(
    lineLogicalTop: InlineLayoutUnit, contentLogicalHeight: InlineLayoutUnit,
    floatingContext: FloatingContext
  ) -> FloatingContext.Constraints {
    let logicalTopCandidate = LayoutUnit(value: lineLogicalTop)
    let logicalBottomCandidate = LayoutUnit(value: lineLogicalTop + contentLogicalHeight)
    if logicalTopCandidate.mightBeSaturated() || logicalBottomCandidate.mightBeSaturated() {
      return FloatingContext.Constraints()
    }
    // Check for intruding floats and adjust logical left/available width for this line accordingly.
    return floatingContext.constraints(
      candidateTop: logicalTopCandidate, candidateBottom: logicalBottomCandidate,
      mayBeAboveLastFloat: .Yes)
  }

  static func flipVisualRectToLogicalForWritingMode(
    visualRect: InlineRect, writingMode: WritingMode
  ) -> InlineRect {
    switch writingModeToBlockFlowDirection(writingMode: writingMode) {
    case .TopToBottom, .BottomToTop:
      return visualRect
    case .LeftToRight, .RightToLeft:
      // FIXME: While vertical-lr and vertical-rl modes do differ in the ordering direction of line boxes
      // in a block container (see: https://drafts.csswg.org/css-writing-modes/#block-flow)
      // we ignore it for now as RenderBlock takes care of it for us.
      return InlineRect(
        top: visualRect.left(), left: visualRect.top(), width: visualRect.height(),
        height: visualRect.width())
    }
  }

  static func horizontalAlignmentOffset(
    rootStyle: RenderStyleWrapper, contentLogicalRightIn: InlineLayoutUnit,
    lineLogicalWidth: InlineLayoutUnit, hangingTrailingWidth: InlineLayoutUnit, runs: Line.RunList,
    isLastLine: Bool, inlineBaseDirectionOverride: TextDirection? = nil
  ) -> InlineLayoutUnit {
    // TODO(asuhan): implement this
    var contentLogicalRight = contentLogicalRightIn
    // Depending on the line’s alignment/justification, the hanging glyph can be placed outside the line box.
    if hangingTrailingWidth != 0 {
      // If white-space is set to pre-wrap, the UA must (unconditionally) hang this sequence, unless the sequence is followed
      // by a forced line break, in which case it must conditionally hang the sequence is instead.
      // Note that end of last line in a paragraph is considered a forced break.
      let isConditionalHanging = runs.last!.isLineBreak() || isLastLine
      // In some cases, a glyph at the end of a line can conditionally hang: it hangs only if it does not otherwise fit in the line prior to justification.
      if isConditionalHanging {
        // FIXME: Conditional hanging needs partial overflow trimming at glyph boundary, one by one until they fit.
        contentLogicalRight = min(contentLogicalRight, lineLogicalWidth)
      } else {
        contentLogicalRight -= hangingTrailingWidth
      }
    }

    let isLastLineOrAfterLineBreak = isLastLine || (!runs.isEmpty && runs.last!.isLineBreak())
    let horizontalAvailableSpace = lineLogicalWidth - contentLogicalRight

    if horizontalAvailableSpace <= 0 {
      return InlineLayoutUnit()
    }

    let isLeftToRightDirection = (inlineBaseDirectionOverride ?? rootStyle.direction()) == .LTR

    switch computedHorizontalAlignment(
      rootStyle: rootStyle, isLastLineOrAfterLineBreak: isLastLineOrAfterLineBreak)
    {
    case .Left, .WebKitLeft:
      if !isLeftToRightDirection {
        return horizontalAvailableSpace
      }
      fallthrough
    case .Start:
      return InlineLayoutUnit()
    case .Right, .WebKitRight:
      if !isLeftToRightDirection {
        return InlineLayoutUnit()
      }
      fallthrough
    case .End:
      return horizontalAvailableSpace
    case .Center, .WebKitCenter:
      return horizontalAvailableSpace / 2
    case .Justify:
      // TextAlignMode::Justify is a run alignment (and we only do inline box alignment here)
      return InlineLayoutUnit()
    }
  }

  static func computedHorizontalAlignment(
    rootStyle: RenderStyleWrapper, isLastLineOrAfterLineBreak: Bool
  )
    -> TextAlignMode
  {
    let textAlign = rootStyle.textAlign()
    if !isLastLineOrAfterLineBreak {
      return textAlign
    }
    // The last line before a forced break or the end of the block is aligned according to text-align-last.
    switch rootStyle.textAlignLast() {
    case .Auto:
      return textAlign == .Justify ? .Start : textAlign
    case .Start:
      return .Start
    case .End:
      return .End
    case .Left:
      return .Left
    case .Right:
      return .Right
    case .Center:
      return .Center
    case .Justify:
      return .Justify
    }
  }

  static func leadingInlineItemPositionForNextLine(
    lineContentEnd: InlineItemPosition, previousLineContentEnd: InlineItemPosition?,
    lineHasIntrusiveOrNewlyPlacedFloat: Bool, layoutRangeEnd: InlineItemPosition
  ) -> InlineItemPosition {
    if previousLineContentEnd == nil {
      return lineContentEnd
    }
    if previousLineContentEnd!.index < lineContentEnd.index
      || (previousLineContentEnd!.index == lineContentEnd.index
        && previousLineContentEnd!.offset
          < lineContentEnd.offset)
    {
      // Either full or partial advancing.
      return lineContentEnd
    }
    if lineContentEnd == previousLineContentEnd! && lineHasIntrusiveOrNewlyPlacedFloat {
      // Couldn't manage to put any content on line due to floats.
      return lineContentEnd
    }
    if lineContentEnd == layoutRangeEnd {
      // End of content.
      return layoutRangeEnd
    }
    // This looks like a partial content and we are stuck. Let's force-move over to the next inline item.
    // We certainly lose some content, but we would be busy looping otherwise.
    fatalError("Not reached")
    /*
    return InlineItemPosition(
      index: min(lineContentEnd.index + 1, layoutRangeEnd.index),
      offset: 0
    )
    */
  }

  func inlineItemWidth(
    inlineItem: InlineItemWrapper, contentLogicalLeft: InlineLayoutUnit, useFirstLineStyle: Bool
  ) -> InlineLayoutUnit {
    assert(inlineItem.layoutBox.isInlineLevelBox())
    if let inlineTextItem = inlineItem as? InlineTextItemWrapper {
      if let contentWidth = inlineTextItem.width() {
        return contentWidth
      }
      let fontCascade =
        useFirstLineStyle
        ? inlineTextItem.firstLineStyle().fontCascade() : inlineTextItem.style().fontCascade()
      if !inlineTextItem.isWhitespace()
        || InlineTextItemWrapper.shouldPreserveSpacesAndTabs(inlineTextItem: inlineTextItem)
      {
        return TextUtil.width(
          inlineTextItem: inlineTextItem, fontCascade: fontCascade,
          contentLogicalLeft: contentLogicalLeft)
      }
      return TextUtil.width(
        inlineTextItem: inlineTextItem, fontCascade: fontCascade,
        from: inlineTextItem.start(), to: inlineTextItem.start() + 1,
        contentLogicalLeft: contentLogicalLeft)
    }

    if inlineItem.isLineBreak() || inlineItem.isWordBreakOpportunity() {
      return InlineLayoutUnit()
    }

    let layoutBox = inlineItem.layoutBox
    let boxGeometry = formattingContext().geometryForBox(layoutBox: layoutBox)

    if layoutBox.isReplacedBox() {
      return boxGeometry.marginBoxWidth().float()
    }

    if inlineItem.isInlineBoxStart() {
      var logicalWidth =
        boxGeometry.marginStart() + boxGeometry.borderStart() + boxGeometry.paddingStart()
      let style = useFirstLineStyle ? inlineItem.firstLineStyle() : inlineItem.style()
      if style.boxDecorationBreak() == .Clone {
        logicalWidth += boxGeometry.borderEnd() + boxGeometry.paddingEnd()
      }
      return logicalWidth.float()
    }

    if inlineItem.isInlineBoxEnd() {
      return (boxGeometry.marginEnd() + boxGeometry.borderEnd() + boxGeometry.paddingEnd()).float()
    }

    if inlineItem.isOpaque() {
      return InlineLayoutUnit()
    }

    // Non-replaced inline box (e.g. inline-block)
    return boxGeometry.marginBoxWidth().float()
  }

  func nextWrapOpportunity(
    startIndex: UInt64, layoutRange: InlineItemRange, inlineItemList: ArraySlice<InlineItemWrapper>
  ) -> UInt64 {
    // 1. Find the start candidate by skipping leading non-content items e.g "<span><span>start". Opportunity is after "<span><span>".
    // 2. Find the end candidate by skipping non-content items inbetween e.g. "<span><span>start</span>end". Opportunity is after "</span>".
    // 3. Check if there's a soft wrap opportunity between the 2 candidate inline items and repeat.
    // 4. Any force line break/explicit wrap content inbetween is considered as wrap opportunity.

    // [ex-][inline box start][inline box end][float][ample] (ex-<span></span><div style="float:left"></div>ample). Wrap index is at [ex-].
    // [ex][inline box start][amp-][inline box start][le] (ex<span>amp-<span>ample). Wrap index is at [amp-].
    // [ex-][inline box start][line break][ample] (ex-<span><br>ample). Wrap index is after [br].
    var previousInlineItemIndex: UInt64? = nil
    for index in startIndex..<layoutRange.endIndex() {
      let currentItem = inlineItemList[Int(index)]
      if currentItem.isLineBreak() || currentItem.isWordBreakOpportunity() {
        // We always stop at explicit wrapping opportunities e.g. <br>. However the wrap position may be at later position.
        // e.g. <span><span><br></span></span> <- wrap position is after the second </span>
        // but in case of <span><br><span></span></span> <- wrap position is right after <br>.
        var skipIndex = index + 1
        while skipIndex < layoutRange.endIndex() && inlineItemList[Int(skipIndex)].isInlineBoxEnd()
        {
          skipIndex += 1
        }
        return skipIndex
      }
      let isNonRubyInlineBox =
        (currentItem.isInlineBoxStart() || currentItem.isInlineBoxEnd())
        && !currentItem.layoutBox.isRubyInlineBox()
      if isNonRubyInlineBox {
        // Need to see what comes next to decide.
        continue
      }
      if currentItem.isOpaque() {
        // This item is invisible to line breaking. Need to pretend it's not here.
        continue
      }
      assert(
        currentItem.isText() || currentItem.isAtomicInlineBox() || currentItem.isFloat()
          || currentItem.layoutBox.isRubyInlineBox())
      if currentItem.isFloat() {
        // While floats are not part of the inline content and they are not supposed to introduce soft wrap opportunities,
        // e.g. [text][float box][float box][text][float box][text] is essentially just [text][text][text]
        // figuring out whether a float (or set of floats) should stay on the line or not (and handle potentially out of order inline items)
        // brings in unnecessary complexity.
        // For now let's always treat a float as a soft wrap opportunity.
        let wrappingPosition = index == startIndex ? min(index + 1, layoutRange.endIndex()) : index
        return wrappingPosition
      }
      if previousInlineItemIndex == nil {
        previousInlineItemIndex = index
        continue
      }
      // At this point previous and current items are not necessarily adjacent items e.g "previous<span>current</span>"
      let previousItem = inlineItemList[Int(previousInlineItemIndex!)]
      if isAtSoftWrapOpportunity(previous: previousItem, next: currentItem) {
        if previousInlineItemIndex! + 1 == index
          && (!previousItem.isText() || !currentItem.isText())
        {
          // We only know the exact soft wrap opportunity index when the previous and current items are next to each other.
          return index
        }
        // There's a soft wrap opportunity between 'previousInlineItemIndex' and 'index'.
        // Now forward-find from the start position to see where we can actually wrap.
        // [ex-][ample] vs. [ex-][inline box start][inline box end][ample]
        // where [ex-] is previousInlineItemIndex and [ample] is index.

        // inline content and their inline boxes form unbreakable content.
        // ex-<span></span>ample               : wrap opportunity is after "ex-<span></span>".
        // ex-<span>ample                      : wrap opportunity is after "ex-".
        // ex-<span><span></span></span>ample  : wrap opportunity is after "ex-<span><span></span></span>".
        // ex-</span></span>ample              : wrap opportunity is after "ex-</span></span>".
        // ex-</span><span>ample               : wrap opportunity is after "ex-</span>".
        // ex-<span><span>ample                : wrap opportunity is after "ex-".
        struct InlineBoxPosition {
          var inlineBox: BoxWrapper? = nil
          var index: UInt64 = 0
        }
        var inlineBoxStack: [InlineBoxPosition] = []
        let start = previousInlineItemIndex!
        let end = index
        // Soft wrap opportunity is at the first inline box that encloses the trailing content.
        for candidateIndex in (start + 1)..<end {
          let inlineItem = inlineItemList[Int(candidateIndex)]
          assert(inlineItem.isInlineBoxStartOrEnd() || inlineItem.isOpaque())
          if inlineItem.isInlineBoxStart() {
            inlineBoxStack.append(
              InlineBoxPosition(inlineBox: inlineItem.layoutBox, index: candidateIndex))
          } else if inlineItem.isInlineBoxEnd() && !inlineBoxStack.isEmpty {
            inlineBoxStack.removeLast()
          }
        }
        return inlineBoxStack.isEmpty ? index : inlineBoxStack.first!.index
      }
      previousInlineItemIndex = index
    }
    return layoutRange.endIndex()
  }

  static func textEmphasisForInlineBox(layoutBox: BoxWrapper, rootBox: ElementBoxWrapper) -> (
    InlineLayoutUnit, InlineLayoutUnit
  ) {
    // Generic, non-inline box inline-level content (e.g. replaced elements) can't have text-emphasis annotations.
    assert(layoutBox.isInlineBox() || layoutBox === rootBox)

    let style = layoutBox.style
    let hasTextEmphasis = style.textEmphasisMark() != .None
    if !hasTextEmphasis {
      return (InlineLayoutUnit(), InlineLayoutUnit())
    }
    let emphasisPosition = style.textEmphasisPosition()
    // Normally we resolve visual -> logical values at pre-layout time, but emphaisis values are not part of the general box geometry.
    var hasAboveTextEmphasis = false
    var hasUnderTextEmphasis = false
    if style.isVerticalWritingMode() {
      hasAboveTextEmphasis = !emphasisPosition.contains(.Left)
      hasUnderTextEmphasis = !hasAboveTextEmphasis
    } else {
      hasAboveTextEmphasis = !emphasisPosition.contains(.Under)
      hasUnderTextEmphasis = !hasAboveTextEmphasis
    }

    if !hasAboveTextEmphasis && !hasUnderTextEmphasis {
      return (InlineLayoutUnit(), InlineLayoutUnit())
    }

    if let rubyBase = enclosingRubyBase(layoutBox: layoutBox, rootBox: rootBox) {
      if RubyFormattingContext.hasInterlinearAnnotation(rubyBaseLayoutBox: rubyBase) {
        let annotationPosition = rubyBase.style.rubyPosition()
        if (hasAboveTextEmphasis && annotationPosition == .Over)
          || (hasUnderTextEmphasis && annotationPosition == .Under)
        {
          // FIXME: Check if annotation box has content.
          return (InlineLayoutUnit(), InlineLayoutUnit())
        }
      }
    }
    let annotationSize = style.fontCascade().floatEmphasisMarkHeight(
      mark: style.textEmphasisMarkString())
    return (hasAboveTextEmphasis ? annotationSize : 0, hasAboveTextEmphasis ? 0 : annotationSize)
  }

  private static func enclosingRubyBase(layoutBox: BoxWrapper, rootBox: ElementBoxWrapper)
    -> ElementBoxWrapper?
  {
    if CPtrToInt(layoutBox.p) == CPtrToInt(rootBox.p) {
      return nil
    }
    var ancestor = layoutBox.parent()
    while CPtrToInt(ancestor.p) != CPtrToInt(rootBox.p) {
      if ancestor.isRubyBase() {
        return ancestor
      }
      ancestor = ancestor.parent()
    }
    return nil
  }

  static func lineEndingTruncationPolicy(
    rootStyle: RenderStyleWrapper, numberOfLinesWithInlineContent: UInt64,
    numberOfVisibleLinesAllowed: UInt64?
  ) -> LineEndingTruncationPolicy {
    if let numberOfVisibleLinesAllowed = numberOfVisibleLinesAllowed {
      // text-overflow: ellipsis should not apply inside clamping content.
      return numberOfVisibleLinesAllowed == numberOfLinesWithInlineContent
        ? .WhenContentOverflowsInBlockDirection : .NoTruncation
    }

    // Truncation is in effect when the block container has overflow other than visible.
    if rootStyle.overflowX() != .Visible && rootStyle.textOverflow() == .Ellipsis {
      return .WhenContentOverflowsInInlineDirection
    }
    return .NoTruncation
  }

  func shouldDiscardRemainingContentInBlockDirection(numberOfLinesWithInlineContent: UInt64) -> Bool
  {
    if let lineClamp = formattingContext().layoutState().parentBlockLayoutState.lineClamp {
      if !lineClamp.shouldDiscardOverflow {
        return false
      }
      assert(lineClamp.isLegacy)
      return lineClamp.maximumLines == numberOfLinesWithInlineContent
    }
    return false
  }

  private func isAtSoftWrapOpportunity(previous: InlineItemWrapper, next: InlineItemWrapper) -> Bool
  {
    // FIXME: Transition no-wrapping logic from InlineContentBreaker to here where we compute the soft wrap opportunity indexes.
    // "is at" simple means that there's a soft wrap opportunity right after the [previous].
    // [text][ ][text][inline box start]... (<div>text content<span>..</div>)
    // soft wrap indexes: 0 and 1 definitely, 2 depends on the content after the [inline box start].

    // https://www.w3.org/TR/css-text-4/#line-break-details
    // Figure out if the new incoming content puts the uncommitted content on a soft wrap opportunity.
    // e.g. [inline box start][prior_continuous_content][inline box end] (<span>prior_continuous_content</span>)
    // An incoming <img> box would enable us to commit the "<span>prior_continuous_content</span>" content
    // but an incoming text content would not necessarily.
    assert(
      previous.isText() || previous.isAtomicInlineBox() || previous.layoutBox.isRubyInlineBox())
    assert(next.isText() || next.isAtomicInlineBox() || next.layoutBox.isRubyInlineBox())

    if previous.layoutBox.isRubyInlineBox() || next.layoutBox.isRubyInlineBox() {
      return RubyFormattingContext.isAtSoftWrapOpportunity(previous: previous, current: next)
    }

    let mayWrapPrevious = TextUtil.isWrappingAllowed(style: previous.layoutBox.parent().style)
    let mayWrapNext = TextUtil.isWrappingAllowed(style: next.layoutBox.parent().style)
    if previous.layoutBox.parent() == next.layoutBox.parent() && !mayWrapPrevious && !mayWrapNext {
      return false
    }

    if let previousInlineTextItem = previous as? InlineTextItemWrapper,
      let nextInlineTextItem = next as? InlineTextItemWrapper
    {
      if previousInlineTextItem.isWhitespace() || nextInlineTextItem.isWhitespace() {
        // For soft wrap opportunities created by characters that disappear at the line break (e.g. U+0020 SPACE), properties on the box directly
        // containing that character control the line breaking at that opportunity.
        // "<nowrap> </nowrap>after"
        if previousInlineTextItem.isWhitespace() {
          return mayWrapPrevious
        }

        // "<span>before</span><nowrap> </nowrap>"
        if !mayWrapNext {
          return false
        }
        // 'white-space: break-spaces' and '-webkit-line-break: after-white-space': line breaking opportunity exists after every preserved white space character, but not before.
        let style = nextInlineTextItem.style()
        return style.whiteSpaceCollapse() != .BreakSpaces && style.lineBreak() != .AfterWhiteSpace
      }
      if previous.style().lineBreak() == .Anywhere || next.style().lineBreak() == .Anywhere {
        // which elements’ line-break, word-break, and overflow-wrap properties control the determination of soft wrap opportunities at such boundaries is undefined in this level.
        // There is a soft wrap opportunity around every typographic character unit, including around any punctuation character or preserved white spaces, or in the middle of words.
        return true
      }
      // Both previous and next items are non-whitespace text.
      // [text][text] : is a continuous content.
      // [text-][text] : after [hyphen] position is a soft wrap opportunity.
      let previousAndNextHaveSameParent =
        previousInlineTextItem.layoutBox.parent() === nextInlineTextItem.layoutBox.parent()
      if previousAndNextHaveSameParent
        && !TextUtil.isWrappingAllowed(style: previousInlineTextItem.style())
      {
        return false
      }
      // For soft wrap opportunities defined by the boundary between two characters, the white-space property on the nearest common ancestor of the two characters controls breaking.
      if !endsWithSoftWrapOpportunity(
        previousInlineTextItem: previousInlineTextItem, nextInlineTextItem: nextInlineTextItem)
      {
        return false
      }
      return TextUtil.isWrappingAllowed(
        style: nearestCommonAncestor(
          first: previousInlineTextItem.layoutBox, second: nextInlineTextItem.layoutBox,
          rootBox: formattingContext().root()
        ).style)
    }
    if previous.layoutBox.isListMarkerBox() {
      let listMarkerBox = previous.layoutBox as! ElementBoxWrapper
      return !listMarkerBox.isListMarkerInsideList() || !listMarkerBox.isListMarkerOutside()
    }
    if next.layoutBox.isListMarkerBox() {
      // FIXME: SHould this ever be the case?
      return true
    }
    if previous.isAtomicInlineBox() || next.isAtomicInlineBox() {
      // [text][inline box start][inline box end][inline box] (text<span></span><img>) : there's a soft wrap opportunity between the [text] and [img].
      // The line breaking behavior of a replaced element or other atomic inline is equivalent to an ideographic character.
      return true
    }

    fatalError("Not reached")
  }

  func formattingContext() -> InlineFormattingContext {
    return inlineFormattingContext
  }

  var inlineFormattingContext: InlineFormattingContext
}
