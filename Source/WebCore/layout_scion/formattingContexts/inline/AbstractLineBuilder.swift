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

struct LineInput {
  var needsLayoutRange: InlineItemRange
  var initialLogicalRect: InlineRect
}

class AbstractLineBuilder {
  init(
    inlineFormattingContext: InlineFormattingContext, rootBox: ElementBoxWrapper,
    rootHorizontalConstraints: HorizontalConstraints, inlineItemList: InlineItemList
  ) {
    self.line = Line(inlineFormattingContext: inlineFormattingContext)
    self.inlineItemList = inlineItemList[0..<inlineItemList.count]
    self.inlineFormattingContext = inlineFormattingContext
    self.rootBox = rootBox
    self.rootHorizontalConstraints = rootHorizontalConstraints
  }

  func layoutInlineContent(lineInput: LineInput, previousLine: PreviousLine?) -> LineLayoutResult {
    fatalError("Should be overridden by subclass")
  }

  func reset() {
    wrapOpportunityList.removeAll()
    partialLeadingTextItem = nil
    previousLine = nil
  }

  func eligibleOverflowWidthAsLeading(
    candidateRuns: InlineContentBreaker.ContinuousContent.RunList,
    lineBreakingResult: InlineContentBreaker.Result, isFirstFormattedLine: Bool
  ) -> InlineLayoutUnit? {
    let eligibleTrailingRunIndex = eligibleTrailingRunIndex(
      candidateRuns: candidateRuns, lineBreakingResult: lineBreakingResult)

    if eligibleTrailingRunIndex == nil {
      return nil
    }

    let overflowingRun = candidateRuns[Int(eligibleTrailingRunIndex!)]
    // FIXME: Add support for other types of continuous content.
    let inlineTextItem = overflowingRun.inlineItem as! InlineTextItemWrapper
    if inlineTextItem.isWhitespace() {
      return nil
    }
    if isFirstFormattedLine {
      let usedStyle = overflowingRun.style
      let style = overflowingRun.inlineItem.style()
      if CPtrToInt(usedStyle.p) != CPtrToInt(style.p)
        && CPtrToInt(usedStyle.fontCascade().p) != CPtrToInt(style.fontCascade().p)
      {
        // We may have the incorrect text width when styles differ. Just re-measure the text content when we place it on the next line.
        return nil
      }
    }
    let logicalWidthForNextLineAsLeading = overflowingRun.contentWidth
    if lineBreakingResult.action == .Wrap {
      return logicalWidthForNextLineAsLeading
    }
    if lineBreakingResult.action == .Break
      && lineBreakingResult.partialTrailingContent!.partialRun != nil
    {
      return logicalWidthForNextLineAsLeading
        - lineBreakingResult.partialTrailingContent!.partialRun!.logicalWidth
    }
    return nil
  }

  func eligibleTrailingRunIndex(
    candidateRuns: InlineContentBreaker.ContinuousContent.RunList,
    lineBreakingResult: InlineContentBreaker.Result
  ) -> UInt64? {
    assert(lineBreakingResult.action == .Wrap || lineBreakingResult.action == .Break)
    if candidateRuns.count == 1 && candidateRuns.first!.inlineItem.isText() {
      // A single text run is always a candidate.
      return 0
    }
    if let partialTrailingContent = lineBreakingResult.partialTrailingContent {
      if lineBreakingResult.action == .Break {
        let trailingRun = candidateRuns[
          Int(partialTrailingContent.trailingRunIndex)]
        if trailingRun.inlineItem.isText() {
          return partialTrailingContent.trailingRunIndex
        }
      }
    }
    return nil
  }

  func isInIntrinsicWidthMode() -> Bool {
    return intrinsicWidthMode != nil
  }

  func isFirstFormattedLine() -> Bool {
    return previousLine == nil
  }

  func formattingContext() -> InlineFormattingContext {
    return inlineFormattingContext
  }

  func layoutState() -> InlineLayoutState {
    return formattingContext().layoutState()
  }

  func blockLayoutState() -> BlockLayoutState {
    return layoutState().parentBlockLayoutState
  }

  func root() -> ElementBoxWrapper {
    return rootBox
  }

  func rootStyle() -> RenderStyleWrapper {
    return isFirstFormattedLine() ? root().firstLineStyle() : root().style
  }

  var line: Line
  var lineLogicalRect = InlineRect()
  var inlineItemList: ArraySlice<InlineItemWrapper>
  var wrapOpportunityList: [InlineItemWrapper] = []
  var partialLeadingTextItem: InlineTextItemWrapper? = nil
  var previousLine: PreviousLine? = nil

  var inlineFormattingContext: InlineFormattingContext
  var rootBox = ElementBoxWrapper()  // Note that this is not necessarily a block container (see range builder).
  var rootHorizontalConstraints = HorizontalConstraints()

  var inlineContentBreaker = InlineContentBreaker()
  var intrinsicWidthMode: IntrinsicWidthMode? = nil
}
