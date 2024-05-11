/*
 * Copyright (C) 2024 Apple Inc. All rights reserved.
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

final class RangeBasedLineBuilder: AbstractLineBuilder {
  init(
    inlineFormattingContext: InlineFormattingContext,
    rootHorizontalConstraints: HorizontalConstraints, inlineItemList: InlineItemList
  ) {
    textOnlySimpleLineBuilder = TextOnlySimpleLineBuilder(
      inlineFormattingContext: inlineFormattingContext,
      rootBox: inlineItemList.first!.layoutBox as! ElementBoxWrapper,
      rootHorizontalConstraints: rootHorizontalConstraints, inlineItemList: inlineItemList)
    super.init(
      inlineFormattingContext: inlineFormattingContext, rootBox: inlineFormattingContext.root(),
      rootHorizontalConstraints: rootHorizontalConstraints, inlineItemList: inlineItemList)
  }

  override func layoutInlineContent(lineInput: LineInput, previousLine: PreviousLine?)
    -> LineLayoutResult
  {
    // TODO(asuhan): implement this
    // 1. Shrink the layout range that we can run text-only builder on (currently it's just the opening/closing inline box)
    // 2. Run text-only line builder
    // 3. Insert/append the missing inline box run
    let isFirstLine = lineInput.needsLayoutRange.startIndex() == 0

    let needsLayoutRange = adjustedNeedsLayoutRange(lineInput: lineInput, isFirstLine: isFirstLine)
    assert(!needsLayoutRange.isEmpty())

    var lineLayoutResult = textOnlySimpleLineBuilder.layoutInlineContent(
      lineInput: LineInput(
        needsLayoutRange: needsLayoutRange, initialLogicalRect: lineInput.initialLogicalRect),
      previousLine: previousLine)

    insertLeadingInlineBoxRun(
      lineLayoutResult: &lineLayoutResult, isFirstLine: isFirstLine, lineInput: lineInput,
      previousLine: previousLine)
    appendTrailingInlineBoxRunIfNeeded(
      lineLayoutResult: &lineLayoutResult, isFirstLine: isFirstLine,
      lineInput: lineInput,
      needsLayoutRange: needsLayoutRange)

    return lineLayoutResult
  }

  internal func adjustedNeedsLayoutRange(lineInput: LineInput, isFirstLine: Bool) -> InlineItemRange
  {
    // TODO(asuhan): implement this
    var needsLayoutRange = lineInput.needsLayoutRange
    if isFirstLine {
      assert(inlineItemList.first!.isInlineBoxStart())
      assert(needsLayoutRange.start.offset == 0)
      // Skip leading InlineItemStart (e.g. <span>)
      needsLayoutRange.start.index += 1
    }
    // SKip trailing InlineItemEnd (e.g. </span>)
    assert(inlineItemList.last!.isInlineBoxEnd())
    assert(needsLayoutRange.end.offset == 0)
    needsLayoutRange.end.index -= 1
    return needsLayoutRange
  }

  internal func insertLeadingInlineBoxRun(
    lineLayoutResult: inout LineLayoutResult, isFirstLine: Bool, lineInput: LineInput,
    previousLine: PreviousLine?
  ) {
    // TODO(asuhan): implement this
    let leadingInlineItem = inlineItemList.first!
    assert(leadingInlineItem.isInlineBoxStart())

    if isFirstLine {
      assert(previousLine == nil)
      lineLayoutResult.inlineContent.insert(
        Line.Run(
          zeroWidthInlineItem: leadingInlineItem, style: leadingInlineItem.firstLineStyle(),
          logicalLeft: 0),
        at: 0)
      lineLayoutResult.inlineItemRange.start = lineInput.needsLayoutRange.start
      return
    }
    // Subsequent lines need leading spanning inline box run.
    lineLayoutResult.inlineContent.insert(
      Line.Run(
        zeroWidthInlineItem: leadingInlineItem, style: RenderStyleWrapper(), logicalLeft: 0),
      at: 0)
  }

  internal func appendTrailingInlineBoxRunIfNeeded(
    lineLayoutResult: inout LineLayoutResult, isFirstLine: Bool, lineInput: LineInput,
    needsLayoutRange: InlineItemRange
  ) {
    // TODO(asuhan): implement this
    if lineLayoutResult.inlineItemRange.end != needsLayoutRange.end {
      return
    }
    let trailingInlineItem = inlineItemList.last!
    lineLayoutResult.inlineContent.append(
      Line.Run(
        zeroWidthInlineItem: trailingInlineItem,
        style: isFirstLine ? trailingInlineItem.firstLineStyle() : trailingInlineItem.style(),
        logicalLeft: lineLayoutResult.contentGeometry.logicalWidth))
    lineLayoutResult.inlineItemRange.end = lineInput.needsLayoutRange.end
  }

  static func isEligibleForRangeInlineLayout(
    inlineFormattingContext: InlineFormattingContext, inlineItems: InlineContentCache.InlineItems,
    placedFloats:
      PlacedFloats
  ) -> Bool {
    // TODO(asuhan): implement this
    if inlineItems.isEmpty() {
      return false
    }
    // Range based line builder only supports the following content <inline box>eligible for text only layout</inline box>
    let inlineItemList = inlineItems.content()
    let isFullyNestedContent =
      inlineItems.inlineBoxCount() == 1 && inlineItemList.first!.isInlineBoxStart()
      && inlineItemList.last!.isInlineBoxEnd() && inlineItemList.count > 2
    if !isFullyNestedContent {
      return false
    }

    let inlineBox = inlineItemList.first!.layoutBox
    let inlineBoxGeometry = inlineFormattingContext.geometryForBox(layoutBox: inlineBox)
    if inlineBoxGeometry.horizontalMarginBorderAndPadding().bool() {
      // FIXME: Add start decoration support is just a matter of shrinking the available space for the first line (or on subsequent lines when decoration break is present)
      return false
    }
    if inlineBox.style.boxDecorationBreak() != RenderStyleWrapper.initialBoxDecorationBreak() {
      return false
    }

    // Check the nested text content.
    if !inlineItems.hasTextAndLineBreakOnlyContent() || inlineItems.requiresVisualReordering()
      || !placedFloats.isEmpty()
    {
      return false
    }

    if !TextOnlySimpleLineBuilder.isEligibleForSimplifiedInlineLayoutByStyle(
      style: inlineFormattingContext.root().style)
      || !TextOnlySimpleLineBuilder.isEligibleForSimplifiedInlineLayoutByStyle(
        style: inlineBox.style)
    {
      return false
    }

    return true
  }

  var textOnlySimpleLineBuilder: TextOnlySimpleLineBuilder
}
