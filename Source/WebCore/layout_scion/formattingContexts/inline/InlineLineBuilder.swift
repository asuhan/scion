/*
 * Copyright (C) 2019-2023 Apple Inc. All rights reserved.
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

struct LineContent {
  var range = InlineItemRange()
  var endsWithHyphen = false
  var partialTrailingContentLength: UInt64 = 0
  var overflowLogicalWidth: InlineLayoutUnit? = nil
  var rubyBaseAlignmentOffsetList: [BoxWrapper: InlineLayoutUnit] = [:]
  var rubyAnnotationOffset = InlineLayoutUnit()
}

internal func isContentfulOrHasDecoration(
  inlineItem: InlineItemWrapper, formattingContext: InlineFormattingContext
) -> Bool {
  if inlineItem.isFloat() || inlineItem.isOpaque() {
    return false
  }
  if let inlineTextItem = inlineItem as? InlineTextItemWrapper {
    let wouldProduceEmptyRun =
      inlineTextItem.isFullyTrimmable() || inlineTextItem.isEmpty()
      || inlineTextItem
        .isWordSeparator
      || inlineTextItem.isZeroWidthSpaceSeparator()
      || inlineTextItem
        .isQuirkNonBreakingSpace()
    return !wouldProduceEmptyRun
  }

  if inlineItem.isInlineBoxStart() {
    return formattingContext.geometryForBox(layoutBox: inlineItem.layoutBox)
      .marginBorderAndPaddingStart().bool()
  }
  if inlineItem.isInlineBoxEnd() {
    return formattingContext.geometryForBox(layoutBox: inlineItem.layoutBox)
      .marginBorderAndPaddingEnd().bool()
  }
  return inlineItem.isAtomicInlineBox() || inlineItem.isLineBreak()
}

internal func toString(runs: Line.RunList) -> StringBuilderWrapper {
  // FIXME: We could try to reuse the content builder in InlineItemsBuilder if this turns out to be a perf bottleneck.
  let lineContentBuilder = StringBuilderWrapper()
  for run in runs {
    if !run.isText() {
      continue
    }
    let textContent = run.textContent!
    lineContentBuilder.append(
      string:
        StringWrapperView(s: (run.layoutBox as! InlineTextBoxWrapper).content).substring(
          start: UInt32(textContent.start), length: UInt32(textContent.length)))
  }
  return lineContentBuilder
}

@discardableResult
internal func computedVisualOrder(
  lineRuns: Line.RunList, visualOrderList: inout [Int32]
) -> [Int32] {
  // TODO(asuhan): implement this
  var runLevels: [UBiDiLevel] = []
  runLevels.reserveCapacity(lineRuns.count)

  var runIndexOffsetMap: [UInt64] = []
  runIndexOffsetMap.reserveCapacity(lineRuns.count)
  var hasOpaqueRun = false
  var accumulatedOffset: UInt64 = 0
  for lineRun in lineRuns {
    if lineRun.bidiLevel == InlineItemWrapper.opaqueBidiLevel {
      accumulatedOffset += 1
      hasOpaqueRun = true
      continue
    }

    // bidiLevels are required to be less than the MAX + 1, otherwise
    // ubidi_reorderVisual will silently fail.
    if lineRun.bidiLevel.rawValue > UBiDiLevel.UBIDI_MAX_EXPLICIT_LEVEL.rawValue + 1 {
      assert(lineRun.bidiLevel == UBiDiLevel.UBIDI_DEFAULT_LTR)
      continue
    }

    runLevels.append(lineRun.bidiLevel)
    runIndexOffsetMap.append(accumulatedOffset)
  }

  visualOrderList.reserveCapacity(runLevels.count)
  while visualOrderList.count < runLevels.count {
    visualOrderList.append(0)
  }
  ubidi_reorderVisual(runLevels: runLevels, visualOrderList: &visualOrderList)
  if hasOpaqueRun {
    assert(visualOrderList.count == runIndexOffsetMap.count)
    for i in 0..<runIndexOffsetMap.count {
      visualOrderList[i] += Int32(runIndexOffsetMap[Int(visualOrderList[i])])
    }
  }
  return visualOrderList
}

internal func hasTrailingSoftWrapOpportunity(
  softWrapOpportunityIndex: UInt64, layoutRangeEnd: UInt64,
  inlineItemList: ArraySlice<InlineItemWrapper>
) -> Bool {
  if softWrapOpportunityIndex == 0 || softWrapOpportunityIndex == layoutRangeEnd {
    // This candidate inline content ends because the entire content ends and not because there's a soft wrap opportunity.
    return false
  }
  // See https://www.w3.org/TR/css-text-3/#line-break-details
  let trailingInlineItem = inlineItemList[Int(softWrapOpportunityIndex - 1)]
  if trailingInlineItem.isFloat() {
    // While we stop at floats, they are not considered real soft wrap opportunities.
    return false
  }
  if trailingInlineItem.isAtomicInlineBox() || trailingInlineItem.isLineBreak()
    || trailingInlineItem.isWordBreakOpportunity() || trailingInlineItem.isInlineBoxEnd()
  {
    // For Web-compatibility there is a soft wrap opportunity before and after each replaced element or other atomic inline.
    return true
  }
  if let inlineTextItem = trailingInlineItem as? InlineTextItemWrapper {
    if inlineTextItem.isWhitespace() {
      return true
    }
    // Now in case of non-whitespace trailing content, we need to check if the actual soft wrap opportunity belongs to the next set.
    // e.g. "this_is_the_trailing_run<span> <-but_this_space_here_is_the_soft_wrap_opportunity"
    // When there's an inline box start(<span>)/end(</span>) between the trailing and the (next)leading run, while we break before the inline box start (<span>)
    // the actual soft wrap position is after the inline box start (<span>) but in terms of line breaking continuity the inline box start (<span>) and the whitespace run belong together.
    assert(layoutRangeEnd <= inlineItemList.count)
    for index in softWrapOpportunityIndex..<layoutRangeEnd {
      let inlineItem = inlineItemList[Int(index)]
      if inlineItem.isInlineBoxStart() || inlineItem.isInlineBoxEnd()
        || inlineItem.isOpaque()
      {
        continue
      }
      // FIXME: Check if [non-whitespace][inline-box][no-whitespace] content has rules about it.
      // For now let's say the soft wrap position belongs to the next set of runs when [non-whitespace][inline-box][whitespace], [non-whitespace][inline-box][box] etc.
      if let inlineItemListTextItem = inlineItem as? InlineTextItemWrapper {
        return !inlineItemListTextItem.isWhitespace()
      }
      return false
    }
    return true
  }

  if trailingInlineItem.isInlineBoxStart() {
    // This is a special case when the inline box's first child is a float box.
    return false
  }
  if trailingInlineItem.isOpaque() {
    for index in (0..<softWrapOpportunityIndex).reversed() {
      if !inlineItemList[Int(index)].isOpaque() {
        return hasTrailingSoftWrapOpportunity(
          softWrapOpportunityIndex: index + 1, layoutRangeEnd: layoutRangeEnd,
          inlineItemList: inlineItemList)
      }
    }
    assert(inlineItemList[Int(softWrapOpportunityIndex)].isFloat())
    return false
  }
  fatalError("Not reached")
}

internal func inlineBaseDirectionForLineContent(
  runs: Line.RunList, rootStyle: RenderStyleWrapper, previousLine: PreviousLine?
) -> TextDirection {
  assert(!runs.isEmpty)
  let shouldUseBlockDirection = rootStyle.unicodeBidi() != .Plaintext
  if shouldUseBlockDirection {
    return rootStyle.direction()
  }
  // A previous line ending with a line break (<br> or preserved \n) introduces a new unicode paragraph with its own direction.
  if let previousLine = previousLine {
    if !previousLine.endsWithLineBreak {
      return previousLine.inlineBaseDirection
    }
  }
  return TextUtil.directionForTextContent(content: toString(runs: runs).view())
}

struct LineCandidate {
  mutating func reset() {
    floatItem = nil
    inlineContent.reset()
  }

  struct InlineContent {
    mutating func appendInlineItem(
      inlineItem: InlineItemWrapper, style: RenderStyleWrapper, logicalWidth: InlineLayoutUnit
    ) {
      if inlineItem.isAtomicInlineBox() || inlineItem.isInlineBoxStartOrEnd()
        || inlineItem.isOpaque()
      {
        return continuousContent.append(
          inlineItem: inlineItem, style: style, logicalWidth: logicalWidth)
      }

      if let inlineTextItem = inlineItem as? InlineTextItemWrapper {
        return continuousContent.appendTextContent(
          inlineTextItem: inlineTextItem, style: style, logicalWidth: logicalWidth)
      }

      if inlineItem.isLineBreak() {
        trailingLineBreak = inlineItem
        return
      }

      fatalError("Not reached")
    }

    mutating func reset() {
      continuousContent.reset()
      trailingLineBreak = nil
      trailingWordBreakOpportunity = nil
      accumulatedClonedDecorationEnd = InlineLayoutUnit()
      hasTrailingSoftWrapOpportunity = false
    }

    func isEmpty() -> Bool {
      return continuousContent.runs.isEmpty && trailingWordBreakOpportunity == nil
        && trailingLineBreak == nil
    }

    mutating func setHasTrailingSoftWrapOpportunity(hasTrailingSoftWrapOpportunity: Bool) {
      self.hasTrailingSoftWrapOpportunity = hasTrailingSoftWrapOpportunity
    }

    mutating func setTrailingSoftHyphenWidth(hyphenWidth: InlineLayoutUnit) {
      continuousContent.setTrailingSoftHyphenWidth(hyphenWidth: hyphenWidth)
    }

    mutating func setHangingContentWidth(logicalWidth: InlineLayoutUnit) {
      continuousContent.setHangingContentWidth(logicalWidth: logicalWidth)
    }

    mutating func setAccumulatedClonedDecorationEnd(accumulatedWidth: InlineLayoutUnit) {
      accumulatedClonedDecorationEnd = accumulatedWidth
    }

    mutating func setMinimumRequiredWidth(minimumRequiredWidth: InlineLayoutUnit) {
      continuousContent.setMinimumRequiredWidth(minimumRequiredWidth: minimumRequiredWidth)
    }

    var continuousContent = InlineContentBreaker.ContinuousContent()
    var trailingLineBreak: InlineItemWrapper? = nil
    var trailingWordBreakOpportunity: InlineItemWrapper? = nil
    var accumulatedClonedDecorationEnd = InlineLayoutUnit()
    var hasTrailingSoftWrapOpportunity = false
  }

  // Candidate content is a collection of inline content or a float box.
  var inlineContent = InlineContent()
  var floatItem: InlineItemWrapper? = nil
}

internal func availableWidth(
  candidateContent: LineCandidate.InlineContent, line: Line, lineWidth: InlineLayoutUnit,
  intrinsicWidthMode: IntrinsicWidthMode?
) -> InlineLayoutUnit {
  // 1. Preferred width computation sums up floats while line breaker subtracts them.
  // 2. Available space is inherently a LayoutUnit based value (coming from block/flex etc layout) and it is the result of a floored float.
  // These can all lead to epsilon-scale differences.
  var lineWidthCopy = lineWidth
  if intrinsicWidthMode == nil || intrinsicWidthMode! == .Maximum {
    lineWidthCopy += LayoutUnit.epsilon()
  }
  var availableWidth = lineWidthCopy - line.contentLogicalRight()
  let inlineBoxListWithClonedDecorationEnd = line.inlineBoxListWithClonedDecorationEnd
  // We may try to commit a inline box end here which already takes up place implicitly through the cloned decoration.
  // Let's not account for its logical width twice.
  if inlineBoxListWithClonedDecorationEnd.isEmpty {
    return availableWidth.isNaN
      ? maxInlineLayoutUnit() : (availableWidth + candidateContent.accumulatedClonedDecorationEnd)
  }
  for run in candidateContent.continuousContent.runs {
    if !run.inlineItem.isInlineBoxEnd() {
      continue
    }
    if let decorationEntry = inlineBoxListWithClonedDecorationEnd[
      CPtrToInt(run.inlineItem.layoutBox.p)]
    {
      availableWidth += decorationEntry
    }
  }
  return availableWidth.isNaN
    ? maxInlineLayoutUnit() : (availableWidth + candidateContent.accumulatedClonedDecorationEnd)
}

internal func haveEnoughSpaceForFloatWithClear(
  floatBoxMarginBox: LayoutRectWrapper, isLeftPositioned: Bool, lineLogicalRect: InlineRect,
  contentLogicalWidth: InlineLayoutUnit
) -> Bool {
  var adjustedLineLogicalLeft = lineLogicalRect.left()
  var adjustedLineLogicalRight = lineLogicalRect.right()
  if isLeftPositioned {
    adjustedLineLogicalLeft = max(floatBoxMarginBox.maxX().float(), adjustedLineLogicalLeft)
  } else {
    adjustedLineLogicalRight = min(floatBoxMarginBox.x().float(), adjustedLineLogicalRight)
  }
  let availableSpaceForContentWithPlacedFloat = adjustedLineLogicalRight - adjustedLineLogicalLeft
  return contentLogicalWidth <= availableSpaceForContentWithPlacedFloat
}

final class LineBuilder: AbstractLineBuilder {
  init(
    inlineFormattingContext: InlineFormattingContext,
    rootHorizontalConstraints: HorizontalConstraints, inlineItemList: InlineItemList
  ) {
    self.floatingContext = inlineFormattingContext.floatingContext!
    super.init(
      inlineFormattingContext: inlineFormattingContext, rootBox: inlineFormattingContext.root(),
      rootHorizontalConstraints: rootHorizontalConstraints, inlineItemList: inlineItemList)
  }

  override func layoutInlineContent(lineInput: LineInput, previousLine: PreviousLine?)
    -> LineLayoutResult
  {
    // TODO(asuhan): implement this
    let previousLineEndsWithLineBreak =
      previousLine == nil || !previousLine!.hasInlineContent ? nil : previousLine!.endsWithLineBreak
    initialize(
      initialLineLogicalRect: lineInput.initialLogicalRect,
      needsLayoutRange: lineInput.needsLayoutRange, previousLine: previousLine,
      previousLineEndsWithLineBreak: previousLineEndsWithLineBreak)
    let lineContent = placeInlineAndFloatContent(needsLayoutRange: lineInput.needsLayoutRange)
    let result = line.close()

    if isInIntrinsicWidthMode() {
      return LineLayoutResult(
        inlineItemRange: lineContent.range,
        inlineContent: result.runs,
        floatContent: LineLayoutResult.FloatContent(
          placedFloats: placedFloats, suspendedFloats: suspendedFloats,
          hasIntrusiveFloat: UsedFloat()),
        contentGeometry: LineLayoutResult.ContentGeometry(
          logicalLeft: InlineLayoutUnit(), logicalWidth: result.contentLogicalWidth,
          logicalRightIncludingNegativeMargin: InlineLayoutUnit(),
          trailingOverflowingContentWidth: lineContent.overflowLogicalWidth),
        lineGeometry: LineLayoutResult.LineGeometry(
          logicalTopLeft: lineLogicalRect.topLeft(), logicalWidth: InlineLayoutUnit(),
          initialLogicalLeftIncludingIntrusiveFloats: InlineLayoutUnit(), initialLetterClearGap: nil
        )
      )
    }

    let isLastInlineContent = isLastLineWithInlineContent(
      lineContent: lineContent, needsLayoutEnd: lineInput.needsLayoutRange.endIndex(),
      lineRuns: result.runs)
    // Lines with nothing but content trailing out-of-flow boxes should also be considered last line for alignment
    // e.g. <div style="text-align-last: center">last line<br><div style="display: inline; position: absolute"></div></div>
    // Both the inline content ('last line') and the trailing out-of-flow box are supposed to be center aligned.
    let shouldTreatAsLastLine =
      isLastInlineContent || lineContent.range.endIndex() == lineInput.needsLayoutRange.endIndex()
    let inlineBaseDirection =
      !result.runs.isEmpty
      ? inlineBaseDirectionForLineContent(
        runs: result.runs, rootStyle: rootStyle(), previousLine: previousLine) : .LTR
    let contentLogicalLeft =
      !result.runs.isEmpty
      ? InlineFormattingUtils.horizontalAlignmentOffset(
        rootStyle: rootStyle(), contentLogicalRightIn: result.contentLogicalRight,
        lineLogicalWidth: lineLogicalRect.width(),
        hangingTrailingWidth: result.hangingTrailingContentWidth, runs: result.runs,
        isLastLine: shouldTreatAsLastLine, inlineBaseDirectionOverride: inlineBaseDirection)
      : InlineLayoutUnit()
    var visualOrderList: [Int32] = []
    if result.contentNeedsBidiReordering {
      computedVisualOrder(lineRuns: result.runs, visualOrderList: &visualOrderList)
    }
    return LineLayoutResult(
      inlineItemRange: lineContent.range, inlineContent: result.runs,
      floatContent: LineLayoutResult.FloatContent(
        placedFloats: placedFloats, suspendedFloats: suspendedFloats,
        hasIntrusiveFloat: lineIsConstrainedByFloat),
      contentGeometry: LineLayoutResult.ContentGeometry(
        logicalLeft: contentLogicalLeft, logicalWidth: result.contentLogicalWidth,
        logicalRightIncludingNegativeMargin: contentLogicalLeft + result.contentLogicalRight,
        trailingOverflowingContentWidth: lineContent.overflowLogicalWidth),
      lineGeometry: LineLayoutResult.LineGeometry(
        logicalTopLeft: lineLogicalRect.topLeft(), logicalWidth: lineLogicalRect.width(),
        initialLogicalLeftIncludingIntrusiveFloats: lineInitialLogicalRect.left()
          + initialIntrusiveFloatsWidth, initialLetterClearGap: initialLetterClearGap
      ),
      hangingContent: LineLayoutResult.HangingContent(
        shouldContributeToScrollableOverflow: !result.isHangingTrailingContentWhitespace,
        logicalWidth: result.hangingTrailingContentWidth,
        hangablePunctuationStartWidth: result.hangablePunctuationStartWidth
      ),
      directionality: LineLayoutResult.Directionality(
        visualOrderList: visualOrderList, inlineBaseDirection: inlineBaseDirection
      ),
      isFirstLast: LineLayoutResult.IsFirstLast(
        isFirstFormattedLine: isFirstFormattedLine() ? .WithinIFC : .No,
        isLastLineWithInlineContent: isLastInlineContent),
      ruby: LineLayoutResult.Ruby(
        baseAlignmentOffsetList: lineContent.rubyBaseAlignmentOffsetList,
        annotationAlignmentOffset: lineContent.rubyAnnotationOffset),
      endsWithHyphen: lineContent.endsWithHyphen,
      nonSpanningInlineLevelBoxCount: result.nonSpanningInlineLevelBoxCount,
      trimmedTrailingWhitespaceWidth: InlineLayoutUnit(),
      firstLineStartTrim: InlineLayoutUnit(),
      hintForNextLineTopToAvoidIntrusiveFloat: lineContent.range.isEmpty()
        ? lineLogicalRect.top() + candidateContentMaximumHeight : nil
    )
  }

  func candidateContentForLine(
    lineCandidate: inout LineCandidate, currentInlineItemIndexIn: UInt64,
    layoutRange: InlineItemRange,
    currentLogicalRightIn: InlineLayoutUnit
  ) {
    var currentInlineItemIndex = currentInlineItemIndexIn
    var currentLogicalRight = currentLogicalRightIn
    assert(currentInlineItemIndex < layoutRange.endIndex())
    lineCandidate.reset()
    // 1. Simply add any overflow content from the previous line to the candidate content. It's always a text content.
    // 2. Find the next soft wrap position or explicit line break.
    // 3. Collect floats between the inline content.
    let softWrapOpportunityIndex = formattingContext().formattingUtils().nextWrapOpportunity(
      startIndex: currentInlineItemIndex, layoutRange: layoutRange, inlineItemList: inlineItemList)
    // softWrapOpportunityIndex == layoutRange.end means we don't have any wrap opportunity in this content.
    assert(softWrapOpportunityIndex <= layoutRange.endIndex())

    let isLeadingPartiaContent =
      currentInlineItemIndex == layoutRange.startIndex() && partialLeadingTextItem != nil
    if isLeadingPartiaContent {
      assert(overflowingLogicalWidth == nil)
      // Handle leading partial content first (overflowing text from the previous line).
      let itemWidth = formattingContext().formattingUtils().inlineItemWidth(
        inlineItem: partialLeadingTextItem!, contentLogicalLeft: currentLogicalRight,
        useFirstLineStyle: isFirstFormattedLine())
      lineCandidate.inlineContent.appendInlineItem(
        inlineItem: partialLeadingTextItem!, style: partialLeadingTextItem!.style(),
        logicalWidth: itemWidth)
      currentLogicalRight += itemWidth
      currentInlineItemIndex += 1
    }

    var firstInlineTextItemIndex: UInt64? = nil
    var lastInlineTextItemIndex: UInt64? = nil
    var trailingSoftHyphenInlineTextItemIndex: UInt64? = nil
    var inlineBoxListWithClonedDecorationEnd: Set<BoxWrapper> = []
    var accumulatedDecorationEndWidth = InlineLayoutUnit()
    for index in currentInlineItemIndex..<softWrapOpportunityIndex {
      let inlineItem = inlineItemList[Int(index)]
      let style = isFirstFormattedLine() ? inlineItem.firstLineStyle() : inlineItem.style()

      let needsLayout =
        inlineItem.isFloat() || inlineItem.isAtomicInlineBox()
        || (inlineItem.isOpaque() && inlineItem.layoutBox.isRubyAnnotationBox())
      if needsLayout {
        // FIXME: Intrinsic width mode should call into the intrinsic width codepath. Currently we only get here when box has fixed width (meaning no need to run intrinsic width on the box).
        if !isInIntrinsicWidthMode() {
          formattingContext().integrationUtils!.layoutWithFormattingContextForBox(
            box: inlineItem.layoutBox as! ElementBoxWrapper)
        }
      }

      if inlineItem.isFloat() {
        lineCandidate.floatItem = inlineItem
        // This is a soft wrap opportunity, must be the only item in the list.
        assert(currentInlineItemIndex + 1 == softWrapOpportunityIndex)
        continue
      }

      if let inlineTextItem = inlineItem as? InlineTextItemWrapper {
        var logicalWidth = InlineLayoutUnit()
        if overflowingLogicalWidth != nil {
          logicalWidth = overflowingLogicalWidth!
          overflowingLogicalWidth = nil
        } else {
          logicalWidth = formattingContext().formattingUtils().inlineItemWidth(
            inlineItem: inlineTextItem, contentLogicalLeft: currentLogicalRight,
            useFirstLineStyle: isFirstFormattedLine())
        }
        lineCandidate.inlineContent.appendInlineItem(
          inlineItem: inlineTextItem, style: style, logicalWidth: logicalWidth)
        // Word spacing does not make the run longer, but it produces an offset instead. See Line::appendTextContent as well.
        currentLogicalRight +=
          logicalWidth + (inlineTextItem.isWordSeparator ? style.fontCascade().wordSpacing() : 0)
        firstInlineTextItemIndex = firstInlineTextItemIndex ?? index
        lastInlineTextItemIndex = index
        trailingSoftHyphenInlineTextItemIndex = inlineTextItem.hasTrailingSoftHyphen ? index : nil
        continue
      }
      if inlineItem.isInlineBoxStart() || inlineItem.isInlineBoxEnd() {
        let layoutBox = inlineItem.layoutBox
        var logicalWidth = formattingContext().formattingUtils().inlineItemWidth(
          inlineItem: inlineItem, contentLogicalLeft: currentLogicalRight,
          useFirstLineStyle: isFirstFormattedLine())
        if layoutBox.isRubyBase() {
          if inlineItem.isInlineBoxStart() {
            // There should only be one ruby base per/annotation candidate content as we allow line breaking between bases unless some special characters between ruby bases prevent us from doing so (see RubyFormattingContext::canBreakAtCharacter)
            var inlineContent = lineCandidate.inlineContent
            inlineContent.setMinimumRequiredWidth(
              minimumRequiredWidth: (inlineContent.continuousContent.minimumRequiredWidth
                ?? InlineLayoutUnit())
                + RubyFormattingContext.annotationBoxLogicalWidth(
                  rubyBaseLayoutBox: layoutBox, inlineFormattingContext: formattingContext())
            )
          } else {
            logicalWidth += RubyFormattingContext.baseEndAdditionalLogicalWidth(
              rubyBaseLayoutBox: layoutBox, lineRuns: line.runs,
              candidateRuns: lineCandidate.inlineContent.continuousContent.runs,
              inlineFormattingContext: formattingContext())
          }
        }

        if style.boxDecorationBreak() == .Clone {
          if inlineItem.isInlineBoxStart() {
            inlineBoxListWithClonedDecorationEnd.insert(layoutBox)
          } else if inlineBoxListWithClonedDecorationEnd.contains(layoutBox) {
            accumulatedDecorationEndWidth += logicalWidth
          }
        }
        lineCandidate.inlineContent.appendInlineItem(
          inlineItem: inlineItem, style: style, logicalWidth: logicalWidth)
        currentLogicalRight += logicalWidth
        continue
      }
      if inlineItem.isAtomicInlineBox() {
        let logicalWidth = formattingContext().formattingUtils().inlineItemWidth(
          inlineItem: inlineItem, contentLogicalLeft: currentLogicalRight,
          useFirstLineStyle: isFirstFormattedLine())
        // FIXME: While the line breaking related properties for atomic level boxes do not depend on the line index (first line style) it'd be great to figure out the correct style to pass in.
        lineCandidate.inlineContent.appendInlineItem(
          inlineItem: inlineItem, style: inlineItem.layoutBox.parent().style,
          logicalWidth: logicalWidth)
        currentLogicalRight += logicalWidth
        continue
      }
      if inlineItem.isLineBreak() || inlineItem.isWordBreakOpportunity() {
        // Since both <br> and <wbr> are explicit word break opportunities they have to be trailing items in this candidate run list unless they are embedded in inline boxes.
        // e.g. <span><wbr></span>
        for i in index + 1..<softWrapOpportunityIndex {
          assert(inlineItemList[Int(i)].isInlineBoxEnd() || inlineItemList[Int(i)].isOpaque())
        }
        lineCandidate.inlineContent.appendInlineItem(
          inlineItem: inlineItem, style: style, logicalWidth: InlineLayoutUnit())
        continue
      }
      if inlineItem.isOpaque() {
        lineCandidate.inlineContent.appendInlineItem(
          inlineItem: inlineItem, style: style, logicalWidth: InlineLayoutUnit())
        continue
      }
      fatalError("Not reached")
    }
    lineCandidate.inlineContent.setAccumulatedClonedDecorationEnd(
      accumulatedWidth: accumulatedDecorationEndWidth)

    setLeadingAndTrailingHangingPunctuation(
      lineCandidate: &lineCandidate, layoutRange: layoutRange,
      currentInlineItemIndex: currentInlineItemIndex,
      firstInlineTextItemIndex: firstInlineTextItemIndex,
      lastInlineTextItemIndex: lastInlineTextItemIndex)

    setTrailingSoftHyphenWidth(
      trailingSoftHyphenInlineTextItemIndex: trailingSoftHyphenInlineTextItemIndex,
      softWrapOpportunityIndex: softWrapOpportunityIndex, lineCandidate: &lineCandidate)
    lineCandidate.inlineContent.setHasTrailingSoftWrapOpportunity(
      hasTrailingSoftWrapOpportunity: hasTrailingSoftWrapOpportunity(
        softWrapOpportunityIndex: softWrapOpportunityIndex, layoutRangeEnd: layoutRange.endIndex(),
        inlineItemList: inlineItemList))
  }

  // TODO(asuhan): Candiate -> Candidate
  func leadingPunctuationWidthForLineCandiate(
    firstInlineTextItemIndex: UInt64, candidateContentStartIndex: UInt64
  ) -> InlineLayoutUnit {
    let isFirstLineFirstContent = isFirstFormattedLine() && !line.hasContent()
    if !isFirstLineFirstContent {
      return InlineLayoutUnit()
    }

    let inlineTextItem = inlineItemList[Int(firstInlineTextItemIndex)] as! InlineTextItemWrapper
    let style = isFirstFormattedLine() ? inlineTextItem.firstLineStyle() : inlineTextItem.style()
    if !TextUtil.hasHangablePunctuationStart(inlineTextItem: inlineTextItem, style: style) {
      return InlineLayoutUnit()
    }

    if firstInlineTextItemIndex != 0 {
      // The text content is not the first in the candidate list. However it may be the first contentful one.
      for index in (candidateContentStartIndex..<firstInlineTextItemIndex).reversed() {
        if isContentfulOrHasDecoration(
          inlineItem: inlineItemList[Int(index)], formattingContext: formattingContext())
        {
          return InlineLayoutUnit()
        }
      }
    }
    // This candidate leading content may have hanging punctuation start.
    return TextUtil.hangablePunctuationStartWidth(inlineTextItem: inlineTextItem, style: style)
  }

  // TODO(asuhan): Candiate -> Candidate
  func trailingPunctuationOrStopOrCommaWidthForLineCandiate(
    lastInlineTextItemIndex: UInt64, layoutRangeEnd: UInt64
  ) -> InlineLayoutUnit {
    let inlineTextItem = inlineItemList[Int(lastInlineTextItemIndex)] as! InlineTextItemWrapper
    let style = isFirstFormattedLine() ? inlineTextItem.firstLineStyle() : inlineTextItem.style()

    if TextUtil.hasHangableStopOrCommaEnd(inlineTextItem: inlineTextItem, style: style) {
      // Stop or comma does apply to all lines not just the last formatted one.
      return TextUtil.hangableStopOrCommaEndWidth(inlineTextItem: inlineTextItem, style: style)
    }

    if TextUtil.hasHangablePunctuationEnd(inlineTextItem: inlineTextItem, style: style) {
      // FIXME: If this turns out to be problematic (finding out if this is the last formatted line that is), we
      // may have to fallback to a post-process setup, where after finishing laying out the content, we go back and re-layout
      // the last (2?) line(s) when there's trailing hanging punctuation.
      // For now let's probe the content all the way to layoutRangeEnd.
      for index in (lastInlineTextItemIndex + 1)..<layoutRangeEnd {
        if isContentfulOrHasDecoration(
          inlineItem: inlineItemList[Int(index)], formattingContext: formattingContext())
        {
          return InlineLayoutUnit()
        }
      }
      return TextUtil.hangablePunctuationEndWidth(inlineTextItem: inlineTextItem, style: style)
    }

    return InlineLayoutUnit()
  }

  func setTrailingSoftHyphenWidth(
    trailingSoftHyphenInlineTextItemIndex: UInt64?, softWrapOpportunityIndex: UInt64,
    lineCandidate: inout LineCandidate
  ) {
    if trailingSoftHyphenInlineTextItemIndex == nil {
      return
    }
    for index in trailingSoftHyphenInlineTextItemIndex!..<softWrapOpportunityIndex {
      if !(inlineItemList[Int(index)] is InlineTextItemWrapper) {
        return
      }
    }
    let trailingInlineTextItem = inlineItemList[Int(trailingSoftHyphenInlineTextItemIndex!)]
    let style =
      isFirstFormattedLine()
      ? trailingInlineTextItem.firstLineStyle() : trailingInlineTextItem.style()
    lineCandidate.inlineContent.setTrailingSoftHyphenWidth(
      hyphenWidth: TextUtil.hyphenWidth(style: style))
  }

  func setLeadingAndTrailingHangingPunctuation(
    lineCandidate: inout LineCandidate, layoutRange: InlineItemRange,
    currentInlineItemIndex: UInt64,
    firstInlineTextItemIndex: UInt64?,
    lastInlineTextItemIndex: UInt64?
  ) {
    var hangingContentWidth = lineCandidate.inlineContent.continuousContent.hangingContentWidth()
    // Do not even try to check for trailing punctuation when the candidate content already has whitespace type of hanging content.
    if hangingContentWidth == 0 && lastInlineTextItemIndex != nil {
      hangingContentWidth += trailingPunctuationOrStopOrCommaWidthForLineCandiate(
        lastInlineTextItemIndex: lastInlineTextItemIndex!, layoutRangeEnd: layoutRange.endIndex())
    }
    if firstInlineTextItemIndex != nil {
      hangingContentWidth += leadingPunctuationWidthForLineCandiate(
        firstInlineTextItemIndex: firstInlineTextItemIndex!,
        candidateContentStartIndex: currentInlineItemIndex)
    }
    if hangingContentWidth != 0 {
      lineCandidate.inlineContent.setHangingContentWidth(logicalWidth: hangingContentWidth)
    }
  }

  struct Result {
    var isEndOfLine: InlineContentBreaker.IsEndOfLine = .No
    struct CommittedContentCount {
      var value: UInt64 = 0
      var isRevert = false
    }
    var committedCount = CommittedContentCount()
    var partialTrailingContentLength: UInt64 = 0
    var overflowLogicalWidth: InlineLayoutUnit? = nil
  }
  enum MayOverConstrainLine: UInt8 {
    case No
    case Yes
    case OnlyWhenFirstFloatOnLine
  }

  func tryPlacingFloatBox(floatBox: BoxWrapper, mayOverConstrainLine: MayOverConstrainLine) -> Bool
  {
    // TODO(asuhan): implement this
    if isFloatLayoutSuspended() {
      return false
    }

    let boxGeometry = formattingContext().geometryForBox(layoutBox: floatBox)
    if !shouldTryToPlaceFloatBox(
      floatBox: floatBox, floatBoxMarginBoxWidth: boxGeometry.marginBoxWidth(),
      mayOverConstrainLine: mayOverConstrainLine)
    {
      return false
    }

    let lineMarginBoxLeft = max(0, lineLogicalRect.left() - lineMarginStart)
    computeFloatBoxPosition(
      lineMarginBoxLeft: lineMarginBoxLeft, floatBox: floatBox, boxGeometry: boxGeometry)

    let willFloatBoxShrinkLine = willFloatBoxShrinkLine(
      boxGeometry: boxGeometry, lineMarginBoxLeft: lineMarginBoxLeft)

    if floatBox.hasFloatClear()
      && !willFloatBoxWithClearFit(
        boxGeometry: boxGeometry, floatBox: floatBox, willFloatBoxShrinkLine: willFloatBoxShrinkLine
      )
    {
      return false
    }

    placeFloatBox(boxGeometry: boxGeometry, floatBox: floatBox)

    adjustLineRectIfNeeded(willFloatBoxShrinkLine: willFloatBoxShrinkLine)

    return true
  }

  func computeFloatBoxPosition(
    lineMarginBoxLeft: InlineLayoutUnit, floatBox: BoxWrapper, boxGeometry: BoxGeometry
  ) {
    // Set static position first.
    var staticPosition = LayoutPointWrapper(
      x: LayoutUnit(value: lineMarginBoxLeft), y: LayoutUnit(value: lineLogicalRect.top()))
    if let additionalOffsets = adjustLineRectForInitialLetterIfApplicable(floatBox: floatBox) {
      staticPosition.setY(
        y: LayoutUnit(value: lineLogicalRect.top() + additionalOffsets.capHeightOffset.float()))
      boxGeometry.setVerticalMargin(
        margin: BoxGeometry.VerticalEdges(
          before: boxGeometry.marginBefore() + additionalOffsets.sunkenBelowFirstLineOffset,
          after: boxGeometry.marginAfter()))
    }
    staticPosition.move(dx: boxGeometry.marginStart(), dy: boxGeometry.marginBefore())
    boxGeometry.setTopLeft(topLeft: staticPosition)
    // Compute float position by running float layout.
    let floatingPosition = floatingContext.positionForFloat(
      layoutBox: floatBox, boxGeometry: boxGeometry,
      horizontalConstraints: rootHorizontalConstraints)
    boxGeometry.setTopLeft(topLeft: floatingPosition)
  }

  func willFloatBoxShrinkLine(boxGeometry: BoxGeometry, lineMarginBoxLeft: InlineLayoutUnit) -> Bool
  {
    // Float boxes don't get positioned higher than the line.
    let floatBoxMarginBox = BoxGeometry.marginBoxRect(box: boxGeometry)
    if floatBoxMarginBox.isEmpty() {
      return false
    }
    if floatBoxMarginBox.right().float() <= lineMarginBoxLeft {
      // Previous floats already constrain the line horizontally more than this one.
      return false
    }
    // Empty rect case: "line-height: 0px;" line still intersects with intrusive floats.
    return floatBoxMarginBox.top().float() == lineLogicalRect.top()
      || floatBoxMarginBox.top().float() < lineLogicalRect.bottom()
  }

  func willFloatBoxWithClearFit(
    boxGeometry: BoxGeometry, floatBox: BoxWrapper, willFloatBoxShrinkLine: Bool
  ) -> Bool {
    if !willFloatBoxShrinkLine {
      return true
    }
    let lineIsConsideredEmpty = !line.hasContent() && !isLineConstrainedByFloat()
    if lineIsConsideredEmpty {
      return true
    }
    // When floats with clear are placed under existing floats, we may find ourselves in an over-constrained state and
    // can't place this float here.
    let contentLogicalWidth = line.contentLogicalWidth - line.trimmableTrailingWidth()
    return haveEnoughSpaceForFloatWithClear(
      floatBoxMarginBox: BoxGeometry.marginBoxRect(box: boxGeometry).LayoutRect(),
      isLeftPositioned: floatingContext.isLogicalLeftPositioned(floatBox: floatBox),
      lineLogicalRect: lineLogicalRect,
      contentLogicalWidth: contentLogicalWidth)
  }

  func placeFloatBox(boxGeometry: BoxGeometry, floatBox: BoxWrapper) {
    let lineIndex = previousLine != nil ? (previousLine!.lineIndex + 1) : 0
    let floatItem = floatingContext.makeFloatItem(
      floatBox: floatBox, boxGeometry: boxGeometry, line: lineIndex)
    layoutState().placedFloats().append(newFloatItem: floatItem)
    placedFloats.append(floatItem)
  }

  func adjustLineRectIfNeeded(willFloatBoxShrinkLine: Bool) {
    if !willFloatBoxShrinkLine {
      // This float is placed outside the line box. No need to shrink the current line.
      return
    }
    let constraints = floatAvoidingRect(
      lineLogicalRect: lineLogicalRect, lineMarginStart: lineMarginStart)
    lineLogicalRect = constraints.logicalRect
    lineIsConstrainedByFloat = lineIsConstrainedByFloat.union(constraints.constrainedSideSet)
  }

  func handleInlineContent(layoutRange: InlineItemRange, lineCandidate: LineCandidate) -> Result {
    var result = LineBuilder.Result()
    let inlineContent = lineCandidate.inlineContent

    let continuousInlineContent = inlineContent.continuousContent
    if continuousInlineContent.runs.isEmpty {
      assert(
        inlineContent.trailingLineBreak != nil || inlineContent.trailingWordBreakOpportunity != nil)
      result = LineBuilder.Result(isEndOfLine: inlineContent.trailingLineBreak != nil ? .Yes : .No)
      return result
    }

    let constraints = adjustedLineRectWithCandidateInlineContent(lineCandidate: lineCandidate)
    let availableWidthForCandidateContent = availableWidthForCandidateContent(
      constraints: constraints, inlineContent: inlineContent)

    let lineIsConsideredContentful =
      line.hasContentOrListMarker() || isLineConstrainedByFloat()
      || !constraints.constrainedSideSet.isEmpty
    var lineBreakingResult = InlineContentBreaker.Result(
      action: .Keep, isEndOfLine: .No, partialTrailingContent: nil, lastWrapOpportunityItem: nil)
    if let minimumRequiredWidth = continuousInlineContent.minimumRequiredWidth {
      if minimumRequiredWidth > availableWidthForCandidateContent {
        if lineIsConsideredContentful {
          lineBreakingResult = InlineContentBreaker.Result(
            action: .Wrap, isEndOfLine: .Yes, partialTrailingContent: nil,
            lastWrapOpportunityItem: nil)
        }
      }
    } else if continuousInlineContent.logicalWidth() > availableWidthForCandidateContent {
      let lineStatus = InlineContentBreaker.LineStatus(
        contentLogicalRight: line.contentLogicalRight(),
        availableWidth: availableWidthForCandidateContent,
        trimmableOrHangingWidth: line.trimmableTrailingWidth(),
        trailingSoftHyphenWidth: line.trailingSoftHyphenWidth,
        hasFullyTrimmableTrailingContent: line.isTrailingRunFullyTrimmable(),
        hasContent: lineIsConsideredContentful,
        hasWrapOpportunityAtPreviousPosition: !wrapOpportunityList.isEmpty)
      lineBreakingResult = inlineContentBreaker.processInlineContent(
        candidateContent: continuousInlineContent, lineStatus: lineStatus)
    }
    result = processLineBreakingResult(
      lineCandidate: lineCandidate, layoutRange: layoutRange, lineBreakingResult: lineBreakingResult
    )

    let lineGainsNewContent =
      lineBreakingResult.action == .Keep || lineBreakingResult.action == .Break
    if lineGainsNewContent {
      // Sometimes in order to put this content on the line, we have to avoid additional float boxes (when the new content is taller than any previous content and we have vertically stacked floats on this line)
      // which means we need to adjust the line rect to accommodate such new constraints.
      lineLogicalRect = constraints.logicalRect
      lineIsConstrainedByFloat = lineIsConstrainedByFloat.union(constraints.constrainedSideSet)
    }
    candidateContentMaximumHeight = constraints.logicalRect.height()
    return result
  }

  func availableWidthForCandidateContent(
    constraints: RectAndFloatConstraints, inlineContent: LineCandidate.InlineContent
  ) -> InlineLayoutUnit {
    let lineIndex = previousLine != nil ? (previousLine!.lineIndex + 1) : 0
    // If width constraint overrides exist (e.g. text-wrap: balance), modify the available width accordingly.
    let availableLineWidthOverride = layoutState().availableLineWidthOverride
    let widthOverride = availableLineWidthOverride.availableLineWidthOverrideForLine(
      lineIndex: lineIndex)
    let availableTotalWidthForContent =
      widthOverride != nil
      ? widthOverride!.float() - lineMarginStart : constraints.logicalRect.width()
    return availableWidth(
      candidateContent: inlineContent, line: line, lineWidth: availableTotalWidthForContent,
      intrinsicWidthMode: intrinsicWidthMode)
  }

  func processLineBreakingResult(
    lineCandidate: LineCandidate, layoutRange: InlineItemRange,
    lineBreakingResult: InlineContentBreaker.Result
  ) -> Result {
    let candidateRuns = lineCandidate.inlineContent.continuousContent.runs

    if lineBreakingResult.action == .Keep {
      // This continuous content can be fully placed on the current line.
      for run in candidateRuns {
        line.append(inlineItem: run.inlineItem, style: run.style, logicalWidth: run.contentWidth)
      }
      // We are keeping this content on the line but we need to check if we could have wrapped here
      // in order to be able to revert back to this position if needed.
      // Let's just ignore cases like collapsed leading whitespace for now.
      if lineCandidate.inlineContent.hasTrailingSoftWrapOpportunity && line.hasContentOrListMarker()
      {
        let trailingRun = candidateRuns.last!
        let trailingInlineItem = trailingRun.inlineItem

        // Note that wrapping here could be driven both by the style of the parent and the inline item itself.
        // e.g inline boxes set the wrapping rules for their content and not for themselves
        let layoutBoxParent = trailingInlineItem.layoutBox.parent()

        // Need to ensure we use the correct style here, so the content breaker and line builder remain in sync.
        let parentStyle =
          isFirstFormattedLine() ? layoutBoxParent.firstLineStyle() : layoutBoxParent.style

        var isWrapOpportunity = TextUtil.isWrappingAllowed(style: parentStyle)
        if !isWrapOpportunity && trailingInlineItem.isInlineBoxStartOrEnd() {
          isWrapOpportunity = TextUtil.isWrappingAllowed(style: trailingRun.style)
        }
        if isWrapOpportunity {
          wrapOpportunityList.append(trailingInlineItem)
        }
      }
      return LineBuilder.Result(
        isEndOfLine: lineBreakingResult.isEndOfLine,
        committedCount: LineBuilder.Result.CommittedContentCount(
          value: UInt64(candidateRuns.count), isRevert: false))
    }

    if lineBreakingResult.action == .Wrap {
      assert(lineBreakingResult.isEndOfLine == .Yes)
      // This continuous content can't be placed on the current line. Nothing to commit at this time.
      // However there are cases when, due to whitespace collapsing, this overflowing content should not be separated from
      // the content on the line.
      // <div>X <span> X</span></div>
      // If the second 'X' overflows the line, the trailing whitespace gets trimmed which introduces a stray inline box
      // on the first line ('X <span>' and 'X</span>' first and second line respectively).
      // In such cases we need to revert the content on the line to a previous wrapping opportunity to keep such content together.
      let needsRevert =
        line.trimmableTrailingWidth() != 0 && !line.runs.isEmpty
        && line.runs.last!.isInlineBoxStart()
      if needsRevert && wrapOpportunityList.count > 1 {
        wrapOpportunityList.removeLast()
        return LineBuilder.Result(
          isEndOfLine: .Yes,
          committedCount: LineBuilder.Result.CommittedContentCount(
            value: rebuildLineWithInlineContent(
              layoutRange: layoutRange, lastInlineItemToAdd: wrapOpportunityList.last!),
            isRevert: true))
      }
      return LineBuilder.Result(
        isEndOfLine: .Yes,
        committedCount: LineBuilder.Result.CommittedContentCount(),
        partialTrailingContentLength: 0,
        overflowLogicalWidth: eligibleOverflowWidthAsLeading(
          candidateRuns: candidateRuns, lineBreakingResult: lineBreakingResult,
          isFirstFormattedLine: isFirstFormattedLine()))
    }
    if lineBreakingResult.action == .WrapWithHyphen {
      assert(lineBreakingResult.isEndOfLine == .Yes)
      // This continuous content can't be placed on the current line, nothing to commit.
      // However we need to make sure that the current line gains a trailing hyphen.
      assert(line.trailingSoftHyphenWidth != nil)
      line.addTrailingHyphen(hyphenLogicalWidth: line.trailingSoftHyphenWidth!)
      return LineBuilder.Result(isEndOfLine: .Yes)
    }
    if lineBreakingResult.action == .RevertToLastWrapOpportunity {
      assert(lineBreakingResult.isEndOfLine == .Yes)
      // Not only this content can't be placed on the current line, but we even need to revert the line back to an earlier position.
      assert(!wrapOpportunityList.isEmpty)
      return LineBuilder.Result(
        isEndOfLine: .Yes,
        committedCount: LineBuilder.Result.CommittedContentCount(
          value: rebuildLineWithInlineContent(
            layoutRange: layoutRange, lastInlineItemToAdd: wrapOpportunityList.last!),
          isRevert: true))
    }
    if lineBreakingResult.action == .RevertToLastNonOverflowingWrapOpportunity {
      assert(lineBreakingResult.isEndOfLine == .Yes)
      assert(!wrapOpportunityList.isEmpty)
      let committedCount = rebuildLineForTrailingSoftHyphen(layoutRange: layoutRange)
      if committedCount != 0 {
        return LineBuilder.Result(
          isEndOfLine: .Yes,
          committedCount: LineBuilder.Result.CommittedContentCount(
            value: committedCount, isRevert: true))
      }
      return LineBuilder.Result(isEndOfLine: .Yes)
    }
    if lineBreakingResult.action == .Break {
      assert(lineBreakingResult.isEndOfLine == .Yes)
      // Commit the combination of full and partial content on the current line.
      assert(lineBreakingResult.partialTrailingContent != nil)
      commitPartialContent(
        runs: candidateRuns, partialTrailingContent: lineBreakingResult.partialTrailingContent!)
      // When breaking multiple runs <span style="word-break: break-all">text</span><span>content</span>, we might end up breaking them at run boundary.
      // It simply means we don't really have a partial run. Partial content yes, but not partial run.
      let trailingRunIndex = lineBreakingResult.partialTrailingContent!.trailingRunIndex
      let committedInlineItemCount = trailingRunIndex + 1
      if let partialRun = lineBreakingResult.partialTrailingContent!.partialRun {
        let trailingInlineTextItem =
          candidateRuns[Int(trailingRunIndex)].inlineItem as! InlineTextItemWrapper
        assert(partialRun.length < trailingInlineTextItem.length)
        let overflowLength = UInt64(trailingInlineTextItem.length) - partialRun.length
        return LineBuilder.Result(
          isEndOfLine: .Yes,
          committedCount: LineBuilder.Result.CommittedContentCount(
            value: committedInlineItemCount, isRevert: false),
          partialTrailingContentLength: overflowLength,
          overflowLogicalWidth: eligibleOverflowWidthAsLeading(
            candidateRuns: candidateRuns, lineBreakingResult: lineBreakingResult,
            isFirstFormattedLine: isFirstFormattedLine()))
      } else {
        return LineBuilder.Result(
          isEndOfLine: .Yes,
          committedCount: LineBuilder.Result.CommittedContentCount(
            value: committedInlineItemCount, isRevert: false))
      }
    }
    fatalError("Not reached")
  }

  struct RectAndFloatConstraints {
    var logicalRect: InlineRect
    var constrainedSideSet = UsedFloat()
  }

  func floatAvoidingRect(lineLogicalRect: InlineRect, lineMarginStart: InlineLayoutUnit)
    -> RectAndFloatConstraints
  {
    var constraints = floatAvoidingRectConstraints(
      logicalRect: lineLogicalRect, lineMarginStart: lineMarginStart)
    if let adjustedRect = formattingContext().quirks().adjustedRectForLineGridLineAlign(
      rect: constraints.logicalRect)
    {
      constraints.logicalRect = adjustedRect
    }

    return constraints
  }

  func floatAvoidingRectConstraints(logicalRect: InlineRect, lineMarginStart: InlineLayoutUnit)
    -> RectAndFloatConstraints
  {
    if isInIntrinsicWidthMode() || floatingContext.isEmpty() {
      return RectAndFloatConstraints(logicalRect: logicalRect, constrainedSideSet: UsedFloat())
    }

    let constraints = formattingContext().formattingUtils().floatConstraintsForLine(
      lineLogicalTop: logicalRect.top(), contentLogicalHeight: logicalRect.height(),
      floatingContext: floatingContext)
    if constraints.left == nil && constraints.right == nil {
      return RectAndFloatConstraints(logicalRect: logicalRect, constrainedSideSet: UsedFloat())
    }

    var constrainedSideSet = UsedFloat()
    // text-indent acts as (start)margin on the line. When looking for intrusive floats we need to check against the line's _margin_ box.
    var marginBoxRect = InlineRect(
      top: logicalRect.top(), left: logicalRect.left() - lineMarginStart,
      width: logicalRect.width() + lineMarginStart, height: logicalRect.height())

    if constraints.left != nil && constraints.left!.x.float() > marginBoxRect.left() {
      marginBoxRect.shiftLeftTo(left: constraints.left!.x.float())
      constrainedSideSet = constrainedSideSet.union(.Left)
    }
    if constraints.right != nil && constraints.right!.x.float() < marginBoxRect.right() {
      marginBoxRect.setRight(right: max(marginBoxRect.left(), constraints.right!.x.float()))
      constrainedSideSet = constrainedSideSet.union(.Right)
    }

    let lineLogicalRect = InlineRect(
      top: marginBoxRect.top(), left: marginBoxRect.left() + lineMarginStart,
      width: marginBoxRect.width() - lineMarginStart, height: marginBoxRect.height())
    return RectAndFloatConstraints(
      logicalRect: lineLogicalRect, constrainedSideSet: constrainedSideSet)
  }

  func adjustedLineRectWithCandidateInlineContent(lineCandidate: LineCandidate)
    -> RectAndFloatConstraints
  {
    // TODO(asuhan): implement this
    // Check if the candidate content would stretch the line and whether additional floats are getting in the way.
    let inlineContent = lineCandidate.inlineContent
    if isInIntrinsicWidthMode() {
      return RectAndFloatConstraints(logicalRect: lineLogicalRect)
    }
    // FIXME: Use InlineFormattingUtils::inlineLevelBoxAffectsLineBox instead.
    var candidateContentHeight = InlineLayoutUnit()
    let lineBoxContain = rootStyle().lineBoxContain()
    for run in inlineContent.continuousContent.runs {
      let inlineItem = run.inlineItem
      if inlineItem.isText() {
        let styleToUse = isFirstFormattedLine() ? inlineItem.firstLineStyle() : inlineItem.style()
        candidateContentHeight = max(candidateContentHeight, styleToUse.computedLineHeight())
      } else if inlineItem.isAtomicInlineBox() && lineBoxContain.contains(.Replaced) {
        candidateContentHeight = max(
          candidateContentHeight,
          formattingContext().geometryForBox(layoutBox: inlineItem.layoutBox).marginBoxHeight()
            .float())
      }
    }
    if candidateContentHeight <= lineLogicalRect.height() {
      return RectAndFloatConstraints(logicalRect: lineLogicalRect)
    }

    return floatAvoidingRect(
      lineLogicalRect: InlineRect(
        topLeft: lineLogicalRect.topLeft(), width: lineLogicalRect.width(),
        height: candidateContentHeight), lineMarginStart: lineMarginStart)
  }

  func rebuildLineWithInlineContent(
    layoutRange: InlineItemRange, lastInlineItemToAdd: InlineItemWrapper
  )
    -> UInt64
  {
    // TODO(asuhan): implement this
    assert(!wrapOpportunityList.isEmpty)
    var numberOfInlineItemsOnLine: UInt64 = 0
    var numberOfFloatsInRange: UInt64 = 0
    // We might already have added floats. They shrink the available horizontal space for the line.
    // Let's just reuse what the line has at this point.
    line.initialize(
      lineSpanningInlineBoxes: lineSpanningInlineBoxes, isFirstFormattedLine: isFirstFormattedLine()
    )
    if partialLeadingTextItem != nil {
      line.append(
        inlineItem: partialLeadingTextItem!, style: partialLeadingTextItem!.style(),
        logicalWidth: formattingContext().formattingUtils().inlineItemWidth(
          inlineItem: partialLeadingTextItem!, contentLogicalLeft: InlineLayoutUnit(),
          useFirstLineStyle: isFirstFormattedLine()))
      numberOfInlineItemsOnLine += 1
      if partialLeadingTextItem === lastInlineItemToAdd {
        return 1
      }
    }

    var index = layoutRange.startIndex() + numberOfInlineItemsOnLine
    while index < layoutRange.endIndex() {
      let inlineItem = inlineItemList[Int(index)]
      if inlineItem.isFloat() {
        numberOfFloatsInRange += 1
        index += 1
        continue
      }
      let style = isFirstFormattedLine() ? inlineItem.firstLineStyle() : inlineItem.style()
      var inlineItemWidth =
        !inlineItem.isOpaque()
        ? formattingContext().formattingUtils().inlineItemWidth(
          inlineItem: inlineItem, contentLogicalLeft: line.contentLogicalRight(),
          useFirstLineStyle: isFirstFormattedLine()) : InlineLayoutUnit()
      if inlineItem.isInlineBoxEnd() && inlineItem.layoutBox.isRubyBase() {
        inlineItemWidth += RubyFormattingContext.baseEndAdditionalLogicalWidth(
          rubyBaseLayoutBox: inlineItem.layoutBox, lineRuns: line.runs,
          candidateRuns: InlineContentBreaker.ContinuousContent.RunList(),
          inlineFormattingContext: formattingContext())
      }

      line.append(inlineItem: inlineItem, style: style, logicalWidth: inlineItemWidth)
      numberOfInlineItemsOnLine += 1
      if inlineItem === lastInlineItemToAdd {
        break
      }
      index += 1
    }

    // Remove floats that are outside of this "rebuild" range to ensure we don't add them twice.
    while index < layoutRange.endIndex() {
      let inlineItem = inlineItemList[Int(index)]
      if inlineItem.isFloat() && unplaceFloatBox(floatBox: inlineItem.layoutBox) {
        break
      }
      index += 1
    }

    return numberOfInlineItemsOnLine + numberOfFloatsInRange
  }

  func unplaceFloatBox(floatBox: BoxWrapper) -> Bool {
    if let indexToRemove = placedFloats.firstIndex(where: { $0.layoutBox() === floatBox }) {
      placedFloats.remove(at: indexToRemove)
    }
    return layoutState().placedFloats().remove(floatBox: floatBox)
  }

  func rebuildLineForTrailingSoftHyphen(layoutRange: InlineItemRange) -> UInt64 {
    if wrapOpportunityList.isEmpty {
      // We are supposed to have a wrapping opportunity on the current line at this point.
      assert(false)
      return 0
    }
    // Revert all the way back to a wrap opportunity when either a soft hyphen fits or no hyphen is required.
    for i in (1..<wrapOpportunityList.count).reversed() {
      let softWrapOpportunityItem = wrapOpportunityList[i]
      // FIXME: If this turns out to be a perf issue, we could also traverse the wrap list and keep adding the items
      // while watching the available width very closely.
      let committedCount = rebuildLineWithInlineContent(
        layoutRange: layoutRange, lastInlineItemToAdd: softWrapOpportunityItem)
      let availableWidth = lineLogicalRect.width() - line.contentLogicalRight()
      let trailingSoftHyphenWidth = line.trailingSoftHyphenWidth
      // Check if the trailing hyphen now fits the line (or we don't need hyphen anymore).
      if trailingSoftHyphenWidth == nil || trailingSoftHyphenWidth! <= availableWidth {
        if trailingSoftHyphenWidth != nil {
          line.addTrailingHyphen(hyphenLogicalWidth: trailingSoftHyphenWidth!)
        }
        return committedCount
      }
    }
    // Have at least some content on the line.
    let committedCount = rebuildLineWithInlineContent(
      layoutRange: layoutRange, lastInlineItemToAdd: wrapOpportunityList.first!)
    if let trailingSoftHyphenWidth = line.trailingSoftHyphenWidth {
      line.addTrailingHyphen(hyphenLogicalWidth: trailingSoftHyphenWidth)
    }
    return committedCount
  }

  func commitPartialContent(
    runs: InlineContentBreaker.ContinuousContent.RunList,
    partialTrailingContent: InlineContentBreaker.Result.PartialTrailingContent
  ) {
    for (index, run) in runs.enumerated() {
      if partialTrailingContent.trailingRunIndex == UInt64(index) {
        // Create and commit partial trailing item.
        if let partialRun = partialTrailingContent.partialRun {
          assert(run.inlineItem.isText())
          let trailingInlineTextItem = run.inlineItem as! InlineTextItemWrapper
          let partialTrailingTextItem = trailingInlineTextItem.left(
            length: UInt32(partialRun.length))
          line.append(
            inlineItem: partialTrailingTextItem, style: trailingInlineTextItem.style(),
            logicalWidth: partialRun.logicalWidth)
          if let hyphenWidth = partialRun.hyphenWidth {
            line.addTrailingHyphen(hyphenLogicalWidth: hyphenWidth)
          }
          return
        }
        // The partial run is the last content to commit.
        line.append(inlineItem: run.inlineItem, style: run.style, logicalWidth: run.contentWidth)
        if let hyphenWidth = partialTrailingContent.hyphenWidth {
          line.addTrailingHyphen(hyphenLogicalWidth: hyphenWidth)
        }
        return
      }
      line.append(inlineItem: run.inlineItem, style: run.style, logicalWidth: run.contentWidth)
    }
  }

  func initialize(
    initialLineLogicalRect: InlineRect, needsLayoutRange: InlineItemRange,
    previousLine: PreviousLine?, previousLineEndsWithLineBreak: Bool?
  ) {
    // TODO(asuhan): implement this
    assert(
      !needsLayoutRange.isEmpty()
        || (previousLine != nil && !previousLine!.suspendedFloats.isEmpty))
    reset()

    self.previousLine = previousLine
    placedFloats.removeAll()
    suspendedFloats.removeAll()
    lineSpanningInlineBoxes.removeAll()
    overflowingLogicalWidth = nil
    partialLeadingTextItem = nil
    initialLetterClearGap = nil
    candidateContentMaximumHeight = InlineLayoutUnit()
    inlineContentBreaker.setHyphenationDisabled(
      hyphenationIsDisabled: layoutState().isHyphenationDisabled())

    createLineSpanningInlineBoxes(needsLayoutRange: needsLayoutRange)
    line.initialize(
      lineSpanningInlineBoxes: lineSpanningInlineBoxes, isFirstFormattedLine: isFirstFormattedLine()
    )

    lineInitialLogicalRect = initialLineLogicalRect
    lineMarginStart = formattingContext().formattingUtils().computedTextIndent(
      isIntrinsicWidthMode: isInIntrinsicWidthMode() ? .Yes : .No,
      previousLineEndsWithLineBreak: previousLineEndsWithLineBreak,
      availableWidth: initialLineLogicalRect.width())

    let constraints = floatAvoidingRect(lineLogicalRect: initialLineLogicalRect, lineMarginStart: 0)
    lineLogicalRect = constraints.logicalRect
    lineIsConstrainedByFloat = constraints.constrainedSideSet
    // This is by how much intrusive floats (coming from parent/sibling FCs) initially offset the line.
    initialIntrusiveFloatsWidth = lineLogicalRect.left() - initialLineLogicalRect.left()
    lineLogicalRect.moveHorizontally(offset: lineMarginStart)
    // While negative margins normally don't expand the available space, preferred width computation gets confused by negative text-indent
    // (shrink the space needed for the content) which we have to balance it here.
    lineLogicalRect.expandHorizontally(delta: -lineMarginStart)

    initializeLeadingContentFromOverflow(
      needsLayoutRange: needsLayoutRange, previousLine: previousLine)
  }

  func placeInlineAndFloatContent(needsLayoutRange: InlineItemRange) -> LineContent {
    // TODO(asuhan): implement this
    var resumedFloatCount: UInt64 = 0
    if !layoutPreviouslySuspendedFloats(resumedFloatCount: &resumedFloatCount) {
      // Couldn't even manage to place all suspended floats from previous line(s). -which also means we can't fit any inline content at this vertical position.
      return LineContent(
        range: InlineItemRange(start: needsLayoutRange.start, end: needsLayoutRange.start))
    }

    var lineContent = LineContent()
    var placedInlineItemCount: UInt64 = 0

    layoutInlineAndFloatContent(
      needsLayoutRange: needsLayoutRange, resumedFloatCount: resumedFloatCount,
      lineContent: &lineContent,
      placedInlineItemCount: &placedInlineItemCount)

    computePlacedInlineItemRange(
      needsLayoutRange: needsLayoutRange, resumedFloatCount: resumedFloatCount,
      placedInlineItemCount: placedInlineItemCount, lineContent: &lineContent)

    assert(lineContent.range.endIndex() <= needsLayoutRange.endIndex())

    handleLineEnding(needsLayoutRange: needsLayoutRange, lineContent: &lineContent)

    return lineContent
  }

  func layoutPreviouslySuspendedFloats(resumedFloatCount: inout UInt64) -> Bool {
    if previousLine == nil {
      return true
    }
    // FIXME: Note that placedInlineItemCount is not incremented here as these floats are already accounted for (at previous line)
    // as LineContent only takes one range -meaning that inline layout may continue while float layout is being suspended
    // and the placed InlineItem range ends at the last inline item placed on the current line.
    var index = 0
    while index < previousLine!.suspendedFloats.count {
      let suspendedFloat = previousLine!.suspendedFloats[index]
      let isPlaced = tryPlacingFloatBox(
        floatBox: suspendedFloat, mayOverConstrainLine: index == 0 ? .OnlyWhenFirstFloatOnLine : .No
      )
      if !isPlaced {
        // Can't place more floats here. We'll try to place these floats on subsequent lines.
        while index < previousLine!.suspendedFloats.count {
          suspendedFloats.append(previousLine!.suspendedFloats[index])
          index += 1
        }
        return false
      }
      resumedFloatCount += 1
      index += 1
    }
    previousLine!.suspendedFloats.removeAll()
    return true
  }

  func layoutInlineAndFloatContent(
    needsLayoutRange: InlineItemRange, resumedFloatCount: UInt64,
    lineContent: inout LineContent,
    placedInlineItemCount: inout UInt64
  ) {
    var lineCandidate = LineCandidate()

    var currentItemIndex = needsLayoutRange.startIndex()
    while currentItemIndex < needsLayoutRange.endIndex() {
      // 1. Collect the set of runs that we can commit to the line as one entity e.g. <span>text_and_span_start_span_end</span>.
      // 2. Apply floats and shrink the available horizontal space e.g. <span>intru_<div style="float: left"></div>sive_float</span>.
      // 3. Check if the content fits the line and commit the content accordingly (full, partial or not commit at all).
      // 4. Return if we are at the end of the line either by not being able to fit more content or because of an explicit line break.
      candidateContentForLine(
        lineCandidate: &lineCandidate, currentInlineItemIndexIn: currentItemIndex,
        layoutRange: needsLayoutRange, currentLogicalRightIn: line.contentLogicalRight())
      // Now check if we can put this content on the current line.
      if let floatItem = lineCandidate.floatItem {
        assert(lineCandidate.inlineContent.isEmpty())
        if !tryPlacingFloatBox(
          floatBox: floatItem.layoutBox, mayOverConstrainLine: line.runs.isEmpty ? .Yes : .No)
        {
          // This float overconstrains the line (it simply means shrinking the line box by the float would cause inline content overflow.)
          // At this point we suspend float layout but continue with inline layout.
          // Such suspended float will be placed at the next available vertical positon when this line "closes".
          suspendedFloats.append(floatItem.layoutBox)
        }
        placedInlineItemCount += 1
      } else {
        let result = handleInlineContent(
          layoutRange: needsLayoutRange, lineCandidate: lineCandidate)
        var isEndOfLine = result.isEndOfLine == .Yes
        if !result.committedCount.isRevert {
          placedInlineItemCount += result.committedCount.value
          let inlineContent = lineCandidate.inlineContent
          let inlineContentIsFullyPlaced =
            inlineContent.continuousContent.runs.count == result.committedCount.value
            && result.partialTrailingContentLength == 0
          if inlineContentIsFullyPlaced {
            if let wordBreakOpportunity = inlineContent.trailingWordBreakOpportunity {
              // <wbr> needs to be on the line as an empty run so that we can construct an inline box and compute basic geometry.
              placedInlineItemCount += 1
              line.append(
                inlineItem: wordBreakOpportunity, style: wordBreakOpportunity.style(),
                logicalWidth: InlineLayoutUnit())
            }
            if inlineContent.trailingLineBreak != nil {
              // Fully placed (or empty) content followed by a line break means "end of line".
              // FIXME: This will put the line break box at the end of the line while in case of some inline boxes, the line break
              // could very well be at an earlier position. This has no visual implications at this point though (only geometry correctness on the line break box).
              // e.g. <span style="border-right: 10px solid green">text<br></span> where the <br>'s horizontal position is before the right border and not after.
              let trailingLineBreak = inlineContent.trailingLineBreak!
              line.append(
                inlineItem: trailingLineBreak, style: trailingLineBreak.style(),
                logicalWidth: InlineLayoutUnit())
              placedInlineItemCount += 1
              isEndOfLine = true
            }
          }
        } else {
          placedInlineItemCount = result.committedCount.value
        }

        if isEndOfLine {
          lineContent.partialTrailingContentLength = result.partialTrailingContentLength
          lineContent.overflowLogicalWidth = result.overflowLogicalWidth
          return
        }
      }
      currentItemIndex = needsLayoutRange.startIndex() + placedInlineItemCount
    }
    // Looks like we've run out of content.
    assert(placedInlineItemCount != 0 || resumedFloatCount != 0)
  }

  func computePlacedInlineItemRange(
    needsLayoutRange: InlineItemRange, resumedFloatCount: UInt64, placedInlineItemCount: UInt64,
    lineContent: inout LineContent
  ) {
    lineContent.range = InlineItemRange(start: needsLayoutRange.start, end: needsLayoutRange.start)

    if placedInlineItemCount == 0 {
      return
    }

    // Layout range already includes "suspended" floats from previous line(s). See layoutPreviouslySuspendedFloats above for details.
    assert(placedFloats.count >= resumedFloatCount)
    let onlyFloatContentPlaced =
      placedInlineItemCount == UInt64(placedFloats.count) - resumedFloatCount
    if onlyFloatContentPlaced || lineContent.partialTrailingContentLength == 0 {
      lineContent.range.end = InlineItemPosition(
        index: needsLayoutRange.startIndex() + placedInlineItemCount, offset: 0)
      return
    }

    let trailingInlineItemIndex = needsLayoutRange.startIndex() + placedInlineItemCount - 1
    let overflowingInlineTextItemLength =
      (inlineItemList[Int(trailingInlineItemIndex)] as! InlineTextItemWrapper).length
    assert(
      lineContent.partialTrailingContentLength != 0
        && lineContent.partialTrailingContentLength < overflowingInlineTextItemLength)
    lineContent.range.end = InlineItemPosition(
      index: trailingInlineItemIndex,
      offset: UInt64(overflowingInlineTextItemLength) - lineContent.partialTrailingContentLength)
  }

  func handleLineEnding(needsLayoutRange: InlineItemRange, lineContent: inout LineContent) {
    let isLastInlineContent = isLastLineWithInlineContent(
      lineContent: lineContent, needsLayoutEnd: needsLayoutRange.endIndex(), lineRuns: line.runs)
    let horizontalAvailableSpace = lineLogicalRect.width()
    let rootStyle = self.rootStyle()

    handleTrailingContent(
      isLastInlineContent: isLastInlineContent, rootStyle: rootStyle,
      horizontalAvailableSpace: horizontalAvailableSpace, lineContent: &lineContent)

    // On each line, reset the embedding level of any sequence of whitespace characters at the end of the line
    // to the paragraph embedding level
    line.resetBidiLevelForTrailingWhitespace(
      rootBidiLevel: rootStyle.isLeftToRightDirection() ? .UBIDI_LTR : .UBIDI_RTL)

    if line.hasContent() {
      applyRunBasedAlignmentIfApplicable(
        lineContent: &lineContent,
        isLastInlineContent: isLastInlineContent,
        horizontalAvailableSpace: horizontalAvailableSpace, rootStyle: rootStyle)
      let lastTextContent = line.runs.last!.textContent
      lineContent.endsWithHyphen = lastTextContent != nil && lastTextContent!.needsHyphen
    }
  }

  func handleTrailingContent(
    isLastInlineContent: Bool, rootStyle: RenderStyleWrapper,
    horizontalAvailableSpace: InlineLayoutUnit, lineContent: inout LineContent
  ) {
    let quirks = formattingContext().quirks()
    line.handleTrailingTrimmableContent(
      trailingTrimmableContentAction: isLineBreakAfterWhitespace(
        isLastInlineContent: isLastInlineContent,
        rootStyle: rootStyle,
        horizontalAvailableSpace: horizontalAvailableSpace
      ) ? .Preserve : .Remove)
    if quirks.trailingNonBreakingSpaceNeedsAdjustment(
      isInIntrinsicWidthMode: isInIntrinsicWidthMode(),
      lineHasOverflow: lineHasOverflow(horizontalAvailableSpace: horizontalAvailableSpace))
    {
      line.handleOverflowingNonBreakingSpace(
        trailingContentAction: isLineBreakAfterWhitespace(
          isLastInlineContent: isLastInlineContent, rootStyle: rootStyle,
          horizontalAvailableSpace: horizontalAvailableSpace)
          ? .Preserve : .Remove,
        overflowingWidth: line.contentLogicalWidth - horizontalAvailableSpace)
    }

    line.handleTrailingHangingContent(
      intrinsicWidthMode: intrinsicWidthMode,
      horizontalAvailableSpaceForContent: horizontalAvailableSpace,
      isLastFormattedLine: isLastInlineContent)

    let mayNeedOutOfFlowOverflowTrimming =
      !isInIntrinsicWidthMode()
      && lineHasOverflow(horizontalAvailableSpace: horizontalAvailableSpace)
      && lineContent.partialTrailingContentLength == 0
      && TextUtil.isWrappingAllowed(style: rootStyle)
    if mayNeedOutOfFlowOverflowTrimming {
      // Overflowing out-of-flow boxes should wrap the to subsequent lines just like any other in-flow content.
      // However since we take a shortcut by not considering out-of-flow content as inflow but instead treating it as an opaque box with zero width and no
      // soft wrap opportunity, any overflowing out-of-flow content would pile up as trailing content.
      // Alternatively we could initiate a two pass layout first with out-of-flow content treated as true inflow and a second without them.
      assert(lineContent.range.end.offset == 0)
      if let lastRemovedTrailingBox = line.removeOverflowingOutOfFlowContent() {
        lineContent.range.end.index = lineEndIndex(
          lineContent: lineContent, lastRemovedTrailingBox: lastRemovedTrailingBox)
      }
    }
  }

  func lineEndIndex(lineContent: LineContent, lastRemovedTrailingBox: BoxWrapper) -> UInt64 {
    for index in lineContent.range.start.index..<lineContent.range.end.index {
      if inlineItemList[Int(index)].layoutBox == lastRemovedTrailingBox {
        return index
      }
    }
    assert(false)
    return lineContent.range.end.index
  }

  func lineHasOverflow(horizontalAvailableSpace: InlineLayoutUnit) -> Bool {
    return horizontalAvailableSpace < line.contentLogicalWidth && line.hasContentOrListMarker()
  }

  func isLineBreakAfterWhitespace(
    isLastInlineContent: Bool, rootStyle: RenderStyleWrapper,
    horizontalAvailableSpace: InlineLayoutUnit
  ) -> Bool {
    return rootStyle.lineBreak() == .AfterWhiteSpace && intrinsicWidthMode != .Minimum
      && (!isLastInlineContent
        || lineHasOverflow(horizontalAvailableSpace: horizontalAvailableSpace))
  }

  func applyRunBasedAlignmentIfApplicable(
    lineContent: inout LineContent,
    isLastInlineContent: Bool,
    horizontalAvailableSpace: InlineLayoutUnit, rootStyle: RenderStyleWrapper
  ) {
    // TODO(asuhan): implement this
    if isInIntrinsicWidthMode() {
      return
    }

    let spaceToDistribute =
      horizontalAvailableSpace - line.contentLogicalWidth
      + (line.isHangingTrailingContentWhitespace() ? line.hangingTrailingContentWidth() : 0)
    if root().isRubyAnnotationBox()
      && rootStyle.textAlign() == RenderStyleWrapper.initialTextAlign()
    {
      lineContent.rubyAnnotationOffset = RubyFormattingContext.applyRubyAlignOnAnnotationBox(
        line:
          line, spaceToDistribute: spaceToDistribute, inlineFormattingContext: formattingContext())
      line.inflateContentLogicalWidth(delta: spaceToDistribute)
      line.adjustContentRightWithRubyAlign(offset: 2 * lineContent.rubyAnnotationOffset)
      return
    }
    // Text is justified according to the method specified by the text-justify property,
    // in order to exactly fill the line box. Unless otherwise specified by text-align-last,
    // the last line before a forced break or the end of the block is start-aligned.
    let hasTextAlignJustify =
      (isLastInlineContent || line.runs.last!.isLineBreak())
      ? rootStyle.textAlignLast() == .Justify : rootStyle.textAlign() == .Justify
    if hasTextAlignJustify {
      let additionalSpaceForAlignedContent = InlineContentAligner.applyTextAlignJustify(
        runs: line.runs, spaceToDistribute: spaceToDistribute,
        hangingTrailingWhitespaceLength: line.hangingTrailingWhitespaceLength())
      line.inflateContentLogicalWidth(delta: additionalSpaceForAlignedContent)
    }
    if line.hasRubyContent {
      lineContent.rubyBaseAlignmentOffsetList = RubyFormattingContext.applyRubyAlign(
        line: line, inlineFormattingContext: formattingContext())
    }
  }

  func createLineSpanningInlineBoxes(needsLayoutRange: InlineItemRange) {
    // TODO(asuhan): implement this
    if needsLayoutRange.isEmpty() {
      return
    }
    // An inline box may not necessarily start on the current line:
    // <span>first line<br>second line<span>with some more embedding<br> forth line</span></span>
    // We need to make sure that there's an [InlineBoxStart] for every inline box that's present on the current line.
    // We only have to do it on the first run as any subsequent inline content is either at the same/higher nesting level.
    let firstInlineItem = inlineItemList[Int(needsLayoutRange.startIndex())]
    // If the parent is the formatting root, we can stop here. This is root inline box content, there's no nesting inline box from the previous line(s)
    // unless the inline box closing is forced over to the current line.
    // e.g.
    // <span>normally the inline box closing forms a continuous content</span>
    // <span>unless it's forced to the next line<br></span>
    let firstLayoutBox = firstInlineItem.layoutBox
    let hasLeadingInlineBoxEnd = firstInlineItem.isInlineBoxEnd()

    if !hasLeadingInlineBoxEnd {
      if isRootLayoutBox(elementBox: firstLayoutBox.parent()) {
        return
      }

      if isRootLayoutBox(elementBox: firstLayoutBox.parent().parent()) {
        // In many cases the entire content is wrapped inside a single inline box.
        // e.g. <div><span>wall of text with<br>single, line spanning inline box...</span></div>
        assert(firstLayoutBox.parent().isInlineBox())
        lineSpanningInlineBoxes.append(
          InlineItemWrapper(
            layoutBox: firstLayoutBox.parent(), type: InlineItemWrapper.Type_.InlineBoxStart,
            bidiLevel: InlineItemWrapper.opaqueBidiLevel))
        return
      }
    }

    var spanningLayoutBoxList = [BoxWrapper]()
    if hasLeadingInlineBoxEnd {
      spanningLayoutBoxList.append(firstLayoutBox)
    }

    var ancestor = firstInlineItem.layoutBox.parent()
    while !isRootLayoutBox(elementBox: ancestor) {
      spanningLayoutBoxList.append(ancestor)
      ancestor = ancestor.parent()
    }
    // Let's treat these spanning inline items as opaque bidi content. They should not change the bidi levels on adjacent content.
    for spanningInlineBox in spanningLayoutBoxList.reversed() {
      lineSpanningInlineBoxes.append(
        InlineItemWrapper(
          layoutBox: spanningInlineBox, type: InlineItemWrapper.Type_.InlineBoxStart,
          bidiLevel: InlineItemWrapper.opaqueBidiLevel))
    }
  }

  func initializeLeadingContentFromOverflow(
    needsLayoutRange: InlineItemRange, previousLine: PreviousLine?
  ) {
    // TODO(asuhan): implement this
    if previousLine == nil || needsLayoutRange.start.offset == 0 {
      return
    }
    let overflowingInlineItemPosition = needsLayoutRange.start
    if let overflowingInlineTextItem = inlineItemList[Int(overflowingInlineItemPosition.index)]
      as? InlineTextItemWrapper
    {
      assert(overflowingInlineItemPosition.offset < overflowingInlineTextItem.length)
      let overflowingLength =
        overflowingInlineTextItem.length - UInt32(overflowingInlineItemPosition.offset)
      if overflowingLength != 0 {
        // Turn previous line's overflow content into the next line's leading content.
        // "sp[<-line break->]lit_content" -> break position: 2 -> leading partial content length: 11.
        partialLeadingTextItem = overflowingInlineTextItem.right(
          length: overflowingLength, width: previousLine!.trailingOverflowingContentWidth)
        return
      }
      overflowingLogicalWidth = previousLine!.trailingOverflowingContentWidth
    }
    overflowingLogicalWidth = previousLine!.trailingOverflowingContentWidth
  }

  func isRootLayoutBox(elementBox: ElementBoxWrapper) -> Bool {
    return elementBox.p == root().p
  }

  struct InitialLetterOffsets {
    var capHeightOffset: LayoutUnit
    var sunkenBelowFirstLineOffset: LayoutUnit
  }

  func adjustLineRectForInitialLetterIfApplicable(floatBox: BoxWrapper) -> InitialLetterOffsets? {
    let drop = floatBox.style.initialLetterDrop()
    let isInitialLetter =
      floatBox.isFloatingPositioned() && floatBox.style.pseudoElementType() == .FirstLetter
      && drop != 0
    if !isInitialLetter {
      return nil
    }

    // Here we try to set the vertical start position for the float in flush with the adjoining text content's cap height.
    // It's a super premature as at this point we don't normally deal with vertical geometry -other than the incoming vertical constraint.
    var initialLetterCapHeightOffset = formattingContext().quirks()
      .initialLetterAlignmentOffset(
        floatBox: floatBox, lineBoxStyle: rootStyle())
    // While initial-letter based floats do not set their clear property, intrusive floats from sibling IFCs are supposed to be cleared.
    let intrusiveBottom = blockLayoutState().intrusiveInitialLetterLogicalBottom
    if initialLetterCapHeightOffset == nil && intrusiveBottom == nil {
      return nil
    }

    var clearGapBeforeFirstLine = InlineLayoutUnit()
    if intrusiveBottom != nil {
      // When intrusive initial letter is cleared, we introduce a clear gap. This is (with proper floats) normally computed before starting
      // line layout but intrusive initial letters are cleared only when another initial letter shows up. Regular inline content
      // does not need clearance.
      let intrusiveInitialLetterWidth = max(
        0, lineLogicalRect.left() - lineInitialLogicalRect.left())
      lineLogicalRect.setLeft(left: lineInitialLogicalRect.left())
      lineLogicalRect.expandHorizontally(delta: intrusiveInitialLetterWidth)
      clearGapBeforeFirstLine = intrusiveBottom!.float()
    }

    var sunkenBelowFirstLineOffset = LayoutUnit()
    let letterHeight = floatBox.style.initialLetterHeight()
    if drop < letterHeight {
      // Sunken/raised initial letter pushes contents of the first line down.
      let numberOfSunkenLines = letterHeight - drop
      let verticalGapForInlineContent =
        Float32(numberOfSunkenLines) * rootStyle().computedLineHeight()
      clearGapBeforeFirstLine += verticalGapForInlineContent
      // And we pull the initial letter up.
      initialLetterCapHeightOffset =
        LayoutUnit(
          value: -verticalGapForInlineContent
            + (initialLetterCapHeightOffset ?? LayoutUnit(value: 0)).float())
    } else if drop > letterHeight {
      // Initial letter is sunken below the first line.
      let numberOfLinesAboveInitialLetter = drop - letterHeight
      sunkenBelowFirstLineOffset =
        LayoutUnit(
          value: Float32(numberOfLinesAboveInitialLetter) * rootStyle().computedLineHeight())
    }

    lineLogicalRect.moveVertically(offset: clearGapBeforeFirstLine)
    // There should never be multiple initial letters.
    assert(initialLetterClearGap == nil)
    initialLetterClearGap = clearGapBeforeFirstLine
    return InitialLetterOffsets(
      capHeightOffset: initialLetterCapHeightOffset ?? LayoutUnit(value: 0),
      sunkenBelowFirstLineOffset: sunkenBelowFirstLineOffset
    )
  }

  func isLastLineWithInlineContent(
    lineContent: LineContent, needsLayoutEnd: UInt64, lineRuns: Line.RunList
  ) -> Bool {
    // TODO(asuhan): implement this
    if lineContent.partialTrailingContentLength != 0 {
      return false
    }
    // FIXME: This needs work with partial layout.
    if lineContent.range.endIndex() == needsLayoutEnd {
      return LineBuilder.lineHasNonOutOfFlowRun(lineRuns: lineRuns)
    }
    // Omit floats to see if this is the last line with inline content.
    var i = needsLayoutEnd
    while i > 0 {
      i -= 1
      if isContentfulOrHasDecoration(
        inlineItem: inlineItemList[Int(i)], formattingContext: formattingContext())
      {
        // InlineItems beyond this line range won't produce any inline content.
        return i == lineContent.range.endIndex() &- 1
      }
    }
    // There has to be at least one non-float item.
    fatalError("Not reached")
  }

  static func lineHasNonOutOfFlowRun(lineRuns: Line.RunList) -> Bool {
    for lineRun in lineRuns.reversed() {
      if !lineRun.isOpaque() {
        return true
      }
    }
    return false
  }

  func isFloatLayoutSuspended() -> Bool {
    return !suspendedFloats.isEmpty
  }

  func shouldTryToPlaceFloatBox(
    floatBox: BoxWrapper, floatBoxMarginBoxWidth: LayoutUnit,
    mayOverConstrainLine: MayOverConstrainLine
  ) -> Bool {
    // TODO(asuhan): implement this
    switch mayOverConstrainLine {
    case .Yes:
      return true
    case .OnlyWhenFirstFloatOnLine:
      // This is a resumed float from a previous line. Now we need to find a place for it.
      // (which also means that the current line can't have any floats that we couldn't place yet)
      assert(suspendedFloats.isEmpty)
      if !isLineConstrainedByFloat() {
        return true
      }
      fallthrough
    case .No:
      let lineIsConsideredEmpty = !line.hasContent() && !isLineConstrainedByFloat()
      if lineIsConsideredEmpty {
        return true
      }
      // Non-clear type of floats stack up (horizontally). It's easy to check if there's space for this float at all,
      // while floats with clear needs post-processing to see if they overlap existing line content (and here we just check if they may fit at all).
      let lineLogicalWidth =
        floatBox.hasFloatClear() ? lineInitialLogicalRect.width() : lineLogicalRect.width()
      let availableWidthForFloat =
        lineLogicalWidth - line.contentLogicalRight() + line.trimmableTrailingWidth()
      return availableWidthForFloat >= floatBoxMarginBoxWidth.float()
    }
  }

  func isLineConstrainedByFloat() -> Bool {
    return !lineIsConstrainedByFloat.isEmpty
  }

  var floatingContext: FloatingContext
  var lineInitialLogicalRect = InlineRect()
  var lineMarginStart = InlineLayoutUnit()
  var initialIntrusiveFloatsWidth = InlineLayoutUnit()
  var candidateContentMaximumHeight = InlineLayoutUnit()
  var placedFloats = LineLayoutResult.PlacedFloatList()
  var suspendedFloats = LineLayoutResult.SuspendedFloatList()
  var overflowingLogicalWidth: InlineLayoutUnit? = nil
  var lineSpanningInlineBoxes: [InlineItemWrapper] = []
  var lineIsConstrainedByFloat = UsedFloat()
  var initialLetterClearGap: InlineLayoutUnit? = nil
}
