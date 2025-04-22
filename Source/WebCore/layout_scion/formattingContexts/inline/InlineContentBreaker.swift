/*
 * Copyright (C) 2018-2023 Apple Inc. All rights reserved.
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

internal func hasLeadingTextContent(continuousContent: InlineContentBreaker.ContinuousContent)
  -> Bool
{
  for run in continuousContent.runs {
    let inlineItem = run.inlineItem
    if inlineItem.isInlineBoxStartOrEnd() || inlineItem.isOpaque() {
      continue
    }
    return inlineItem.isText()
  }
  return false
}

internal func nextTextRunIndex(
  runs: InlineContentBreaker.ContinuousContent.RunList, startIndex: UInt64
) -> UInt64? {
  for index in Int(startIndex + 1)..<runs.count {
    if runs[index].inlineItem.isText() {
      return UInt64(index)
    }
  }
  return nil
}

internal func inlineItemIsWhitespace(inlineItem: InlineItemWrapper) -> Bool {
  if let textItem = inlineItem as? InlineTextItemWrapper {
    return textItem.isWhitespace()
  }
  return false
}

internal func isWhitespaceOnlyContent(continuousContent: InlineContentBreaker.ContinuousContent)
  -> Bool
{
  // [<span></span> ] [<span> </span>] [ <span style="padding: 0px;"></span>] are all considered visually empty whitespace content.
  // [<span style="border: 1px solid red"></span> ] while this is whitespace content only, it is not considered visually empty.
  assert(!continuousContent.runs.isEmpty)
  var hasWhitespace = false
  for run in continuousContent.runs {
    let inlineItem = run.inlineItem
    if inlineItem.isInlineBoxStartOrEnd() || inlineItem.isOpaque() {
      continue
    }
    let isWhitespace = inlineItemIsWhitespace(inlineItem: inlineItem)
    if !isWhitespace {
      return false
    }
    hasWhitespace = true
  }
  return hasWhitespace
}

internal func isNonContentRunsOnly(continuousContent: InlineContentBreaker.ContinuousContent)
  -> Bool
{
  // <span></span> <- non content runs.
  for run in continuousContent.runs {
    let inlineItem = run.inlineItem
    if inlineItem.isInlineBoxStartOrEnd() || inlineItem.isOpaque() {
      continue
    }
    if let inlineTextItem = inlineItem as? InlineTextItemWrapper {
      if inlineTextItem.isEmpty() {
        continue
      }
    }
    return false
  }
  return true
}

internal func firstTextRunIndex(
  continuousContentRuns: InlineContentBreaker.ContinuousContent.RunList
) -> UInt64? {
  for (index, run) in continuousContentRuns.enumerated() {
    if run.inlineItem.isText() {
      return UInt64(index)
    }
  }
  return nil
}

internal func findTrailingRunIndexBeforeBreakableRun(
  runs: InlineContentBreaker.ContinuousContent.RunList, breakableRunIndex: UInt64
) -> UInt64? {
  // When the breaking position is at the beginning of the run, the trailing run is the previous one.
  if breakableRunIndex == 0 {
    return nil
  }
  // Try not break content at inline box boundary
  // e.g. <span>fits</span><span>overflows</span>
  // when the text "overflows" completely overflows, let's break the content right before the '<span>'.
  var lastOpaqueItemIndex: UInt64? = nil
  for trailingCandidateIndex in (0..<breakableRunIndex).reversed() {
    let inlineItem = runs[Int(trailingCandidateIndex)].inlineItem
    if inlineItem.isOpaque() {
      lastOpaqueItemIndex = trailingCandidateIndex
      continue
    }
    let isAtInlineBox = inlineItem.isInlineBoxStart()
    if !isAtInlineBox {
      return lastOpaqueItemIndex ?? trailingCandidateIndex
    }
    lastOpaqueItemIndex = nil
  }
  return nil
}

internal func isBreakableRun(run: InlineContentBreaker.ContinuousContent.Run) -> Bool {
  if !run.inlineItem.isText() {
    // Can't break horizontal spacing -> e.g. <span style="padding-right: 100px;">textcontent</span>, if the [inline box end] is the overflown inline item
    // we need to check if there's another inline item beyond the [inline box end] to split.
    return false
  }
  // Check if this text run needs to stay on the current line.
  return TextUtil.isWrappingAllowed(style: run.style)
}

internal func canBreakBefore(character: UInt32, lineBreak: LineBreak) -> Bool {
  // FIXME: This should include all the cases from https://unicode.org/reports/tr14
  // Use a breaking matrix similar to lineBreakTable in BreakLines.cpp
  // Also see kBreakAllLineBreakClassTable in third_party/blink/renderer/platform/text/text_break_iterator.cc
  if lineBreak != .Loose {
    // The following breaks are allowed for loose line breaking if the preceding character belongs to the Unicode
    // line breaking class ID, and are otherwise forbidden:
    // ‐ U+2010, – U+2013
    // https://drafts.csswg.org/css-text/#line-break-property
    if character == CharacterNames.Unicode.hyphen || character == CharacterNames.Unicode.enDash {
      return false
    }
  }
  if character == CharacterNames.Unicode.noBreakSpace {
    return false
  }
  let isPunctuation =
    UCharMasks.U_GET_GC_MASK(c: character)
    & (UCharMasks.U_GC_PS_MASK | UCharMasks.U_GC_PE_MASK | UCharMasks.U_GC_PI_MASK
      | UCharMasks.U_GC_PF_MASK | UCharMasks.U_GC_PO_MASK)
  return character == CharacterNames.Unicode.reverseSolidus || isPunctuation == 0
}

internal func lastValidBreakingPosition(
  runs: InlineContentBreaker.ContinuousContent.RunList, textRunIndex: UInt64
) -> UInt64? {
  let textRun = runs[Int(textRunIndex)]
  let inlineTextItem = textRun.inlineItem as! InlineTextItemWrapper
  assert(inlineTextItem.length != 0)
  let lineBreak = textRun.style.lineBreak()

  let adjacentTextRunIndex = nextTextRunIndex(runs: runs, startIndex: textRunIndex)
  if adjacentTextRunIndex == nil {
    return UInt64(inlineTextItem.end())
  }

  let nextInlineTextItem = runs[Int(adjacentTextRunIndex!)].inlineItem as! InlineTextItemWrapper
  let canBreakAtRunBoundary =
    nextInlineTextItem.isWhitespace()
    ? nextInlineTextItem.style().whiteSpaceCollapse() != .BreakSpaces
    : canBreakBefore(
      character: UInt32(nextInlineTextItem.inlineTextBox().content[nextInlineTextItem.start()]),
      lineBreak: lineBreak)
  if canBreakAtRunBoundary {
    return UInt64(inlineTextItem.end())
  }

  // Find out if the candidate position for arbitrary breaking is valid. We can't always break between any characters.
  let text = inlineTextItem.inlineTextBox().content
  let left = inlineTextItem.start()
  for index in ((left + 1)..<inlineTextItem.end()).reversed() {
    U16_SET_CP_START(s: text, start: left, i: index)
    // We should never find surrogates/segments across inline items.
    assert(index >= inlineTextItem.start())
    if canBreakBefore(character: UInt32(text[index]), lineBreak: lineBreak) {
      return index == inlineTextItem.start() ? nil : UInt64(index)
    }
  }
  return nil
}

internal func midWordBreak(
  textRun: InlineContentBreaker.ContinuousContent.Run, runLogicalLeft: InlineLayoutUnit,
  availableWidth: InlineLayoutUnit
) -> TextUtil.WordBreakLeft? {
  assert(textRun.style.wordBreak() == .BreakAll)
  let inlineTextItem = textRun.inlineItem as! InlineTextItemWrapper

  let wordBreak = TextUtil.breakWord(
    inlineTextItem: inlineTextItem, fontCascade: textRun.style.fontCascade(),
    textWidth: textRun.spaceRequired(), availableWidth: availableWidth,
    contentLogicalLeft: runLogicalLeft)
  if wordBreak.length == 0 || wordBreak.length == inlineTextItem.length {
    return nil
  }

  // Find out if the candidate position for arbitrary breaking is valid. We can't always break between any characters.
  let lineBreak = textRun.style.lineBreak()
  let text = inlineTextItem.inlineTextBox().content
  if canBreakBefore(
    character: UInt32(text[inlineTextItem.start() + UInt32(wordBreak.length)]), lineBreak: lineBreak
  ) {
    return wordBreak
  }

  let left = inlineTextItem.start()
  var right = left + UInt32(wordBreak.length)
  while right > left {
    U16_SET_CP_START(s: text, start: left, i: right)
    if canBreakBefore(character: UInt32(text[right]), lineBreak: lineBreak) {
      break
    }
    right -= 1
  }
  if left == right {
    return nil
  }
  return TextUtil.WordBreakLeft(
    length: UInt64(right - left),
    logicalWidth: TextUtil.width(
      inlineTextItem: inlineTextItem, fontCascade: textRun.style.fontCascade(), from: left,
      to: right, contentLogicalLeft: runLogicalLeft)
  )
}

internal func limitBeforeValue(style: RenderStyleWrapper) -> UInt64 {
  return style.hyphenationLimitBefore() == RenderStyleWrapper.initialHyphenationLimitBefore()
    ? 0 : UInt64(style.hyphenationLimitBefore())
}

internal func limitAfterValue(style: RenderStyleWrapper) -> UInt64 {
  return style.hyphenationLimitAfter() == RenderStyleWrapper.initialHyphenationLimitAfter()
    ? 0 : UInt64(style.hyphenationLimitAfter())
}

internal func hasEnoughContentForHyphenation(contentLength: UInt64, style: RenderStyleWrapper)
  -> Bool
{
  return limitBeforeValue(style: style) + limitAfterValue(style: style) <= contentLength
}

internal func firstHyphenPosition(content: StringWrapperView, style: RenderStyleWrapper) -> UInt64?
{
  // FIXME: We may produce slighly incorrect (less fine-grained) hyphenation here as the incoming content may just be a partial word.
  // (same applies to hyphenPosition below)
  let contentLength = UInt64(content.length())
  if !hasEnoughContentForHyphenation(contentLength: UInt64(contentLength), style: style) {
    return nil
  }

  let limitBefore = limitBeforeValue(style: style)
  var candidatePosition = min(contentLength, contentLength - limitAfterValue(style: style) + 1)
  var firstHyphenLocation: UInt64? = nil
  while true {
    let hyphenIndex = lastHyphenLocation(
      string: content, beforeIndex: candidatePosition, localeIdentifier: style.computedLocale())
    if hyphenIndex == 0 || hyphenIndex < limitBefore {
      return firstHyphenLocation
    }
    if hyphenIndex >= candidatePosition {
      fatalError("Not reached")
    }
    firstHyphenLocation = hyphenIndex
    candidatePosition = hyphenIndex
  }
}

internal func lastHyphenPosition(content: StringWrapperView, style: RenderStyleWrapper) -> UInt64? {
  let contentLength = UInt64(content.length())
  if !hasEnoughContentForHyphenation(contentLength: contentLength, style: style) {
    return nil
  }

  let hyphenIndex = lastHyphenLocation(
    string: content,
    beforeIndex: min(contentLength, contentLength - limitAfterValue(style: style) + 1),
    localeIdentifier: style.computedLocale())
  if hyphenIndex != 0 {
    return hyphenIndex >= limitBeforeValue(style: style) ? hyphenIndex : nil
  }
  return nil
}

internal func hyphenPositionBefore(
  content: StringWrapperView, style: RenderStyleWrapper, beforePosition: UInt64
) -> UInt64? {
  // Find the hyphen position as follows:
  // 1. Split the text by taking the hyphen width into account
  // 2. Find the last hyphen position before the split position
  let contentLength = content.length()
  if beforePosition < limitBeforeValue(style: style)
    || !hasEnoughContentForHyphenation(contentLength: UInt64(contentLength), style: style)
  {
    return nil
  }

  let hyphenIndex = lastHyphenLocation(
    string: content,
    beforeIndex: min(beforePosition, UInt64(contentLength) - limitAfterValue(style: style)) + 1,
    localeIdentifier: style.computedLocale())
  if hyphenIndex != 0 {
    return hyphenIndex >= limitBeforeValue(style: style) ? hyphenIndex : nil
  }
  return nil
}

class InlineContentBreaker {
  struct PartialRun {
    var length: UInt64 = 0
    var logicalWidth = InlineLayoutUnit()
    // FIXME: Remove this and collapse the rest of PartialRun over to PartialTrailingContent.
    var hyphenWidth: InlineLayoutUnit? = nil
  }
  enum IsEndOfLine: UInt8 {
    case No
    case Yes
  }
  struct Result {
    enum Action {
      case Keep  // Keep content on the current line.
      case Break  // Partial content is on the current line.
      case Wrap  // Content is wrapped to the next line.
      case WrapWithHyphen  // Content is wrapped to the next line and the current line ends with a visible hyphen.
      // The current content overflows and can't get broken up into smaller bits.
      case RevertToLastWrapOpportunity  // The content needs to be reverted back to the last wrap opportunity.
      case RevertToLastNonOverflowingWrapOpportunity  // The content needs to be reverted back to a wrap opportunity that still fits the line.
    }
    struct PartialTrailingContent {
      var trailingRunIndex: UInt64 = 0
      var partialRun: PartialRun? = nil  // nullopt partial run means the trailing run is a complete run.
      var hyphenWidth: InlineLayoutUnit? = nil  // Hyphen may be at the end of a full run in the middle of the continuous content (e.g. with adjacent InlineTextItems).
    }
    var action: Action = .Keep
    var isEndOfLine: IsEndOfLine = .No
    var partialTrailingContent: PartialTrailingContent? = nil
    var lastWrapOpportunityItem: InlineItemWrapper? = nil
  }

  // This struct represents the amount of continuous content committed to content breaking at a time (no in-between wrap opportunities).
  // e.g.
  // <div>text content <span>span1</span>between<span>span2</span></div>
  // [text][ ][content][ ][inline box start][span1][inline box end][between][inline box start][span2][inline box end]
  // continuous candidate content at a time:
  // 1. [text]
  // 2. [ ]
  // 3. [content]
  // 4. [ ]
  // 5. [inline box start][span1][inline box end][between][inline box start][span2][inline box end]
  // see https://drafts.csswg.org/css-text-3/#line-break-details
  struct ContinuousContent {
    func logicalWidth() -> InlineLayoutUnit { return m_logicalWidth }
    func hangingContentWidth() -> InlineLayoutUnit {
      return m_hangingContentWidth ?? 0
    }

    func hasTrimmableSpace() -> Bool {
      return trailingTrimmableWidth != 0 || leadingTrimmableWidth != 0
    }

    func hasHangingSpace() -> Bool {
      return hangingContentWidth() != 0
    }

    func isHangingContent() -> Bool {
      if let hangingContentWidth = m_hangingContentWidth {
        return hangingContentWidth == logicalWidth()
      }
      return false
    }

    mutating func append(
      inlineItem: InlineItemWrapper, style: RenderStyleWrapper, logicalWidth: InlineLayoutUnit
    ) {
      assert(
        inlineItem.isAtomicInlineBox() || inlineItem.isInlineBoxStartOrEnd()
          || inlineItem.isOpaque())
      isTextOnlyContent = false
      hasTrailingWordSeparator = hasTrailingWordSeparator && !inlineItem.isAtomicInlineBox()
      appendToRunList(
        inlineItem: inlineItem, style: style, offset: InlineLayoutUnit(), contentWidth: logicalWidth
      )
      if inlineItem.isAtomicInlineBox() {
        // Inline boxes (whitespace-> <span></span>) do not prevent the trailing content from getting trimmed/hung
        // but atomic inline level boxes do.
        resetTrailingTrimmableContent()
      }
    }

    mutating func appendTextContent(
      inlineTextItem: InlineTextItemWrapper, style: RenderStyleWrapper,
      logicalWidth: InlineLayoutUnit
    ) {
      hasTextContent = true
      let isAfterWordSeparator = hasTrailingWordSeparator
      hasTrailingWordSeparator = inlineTextItem.isWordSeparator
      // https://www.w3.org/TR/css-text-4/#white-space-phase-2
      let isTrailingHangingContent =
        inlineTextItem.isWhitespace() && TextUtil.shouldTrailingWhitespaceHang(style: style)
      if isTrailingHangingContent {
        setHangingContentWidth(logicalWidth: logicalWidth)
      }

      let trimmableWidth = trimmableWidth(
        logicalWidth: logicalWidth, inlineTextItem: inlineTextItem,
        isTrailingHangingContent: isTrailingHangingContent)
      if trimmableWidth == nil {
        let contentOffset = isAfterWordSeparator ? style.wordSpacing() : 0
        appendToRunList(
          inlineItem: inlineTextItem, style: style, offset: contentOffset,
          contentWidth: logicalWidth)
        if contentOffset != 0 && isFullyTrimmable {
          // word-spacing offset gets trimmed together with the leading trimmable content.
          leadingTrimmableWidth += contentOffset
        }
        resetTrailingTrimmableContent()
        return
      }

      isFullyTrimmable = isFullyTrimmable || runs.isEmpty
      assert(trimmableWidth! <= logicalWidth)
      let isLeadingTrimmable = trimmableWidth != nil && (logicalWidth == 0 || isFullyTrimmable)
      appendToRunList(
        inlineItem: inlineTextItem, style: style,
        offset: isAfterWordSeparator ? style.wordSpacing() : 0,
        contentWidth: logicalWidth)
      if isLeadingTrimmable {
        assert(trailingTrimmableWidth == 0)
        leadingTrimmableWidth += trimmableWidth!
        return
      }
      trailingTrimmableWidth =
        trimmableWidth! == logicalWidth ? trailingTrimmableWidth + logicalWidth : trimmableWidth!
    }

    func trimmableWidth(
      logicalWidth: InlineLayoutUnit, inlineTextItem: InlineTextItemWrapper,
      isTrailingHangingContent: Bool
    )
      -> InlineLayoutUnit?
    {
      if isTrailingHangingContent {
        return nil
      }
      if inlineTextItem.isFullyTrimmable() || inlineTextItem.isQuirkNonBreakingSpace() {
        return logicalWidth
      }
      return nil
    }

    mutating func setHangingContentWidth(logicalWidth: InlineLayoutUnit) {
      self.m_hangingContentWidth = logicalWidth
    }

    mutating func setTrailingSoftHyphenWidth(hyphenWidth: InlineLayoutUnit) {
      m_logicalWidth += hyphenWidth
      hasTrailingSoftHyphen = true
    }

    mutating func setMinimumRequiredWidth(minimumRequiredWidth: InlineLayoutUnit) {
      self.minimumRequiredWidth = minimumRequiredWidth
    }

    mutating func appendToRunList(
      inlineItem: InlineItemWrapper, style: RenderStyleWrapper, offset: InlineLayoutUnit,
      contentWidth: InlineLayoutUnit
    ) {
      runs.append(
        Run(inlineItem: inlineItem, style: style, offset: offset, contentWidth: contentWidth))
      m_logicalWidth = clampTo(value: m_logicalWidth + offset + contentWidth)
    }

    mutating func resetTrailingTrimmableContent() {
      if leadingTrimmableWidth == 0 {
        leadingTrimmableWidth = trailingTrimmableWidth
      }
      trailingTrimmableWidth = InlineLayoutUnit()
      isFullyTrimmable = false
    }

    mutating func reset() {
      m_logicalWidth = InlineLayoutUnit()
      leadingTrimmableWidth = InlineLayoutUnit()
      trailingTrimmableWidth = InlineLayoutUnit()
      m_hangingContentWidth = nil
      minimumRequiredWidth = nil
      runs.removeAll()
      hasTextContent = false
      isTextOnlyContent = true
      isFullyTrimmable = false
      hasTrailingWordSeparator = false
      hasTrailingSoftHyphen = false
    }

    struct Run {
      func spaceRequired() -> InlineLayoutUnit {
        return offset + contentWidth
      }

      var inlineItem: InlineItemWrapper
      var style: RenderStyleWrapper
      var offset = InlineLayoutUnit()
      var contentWidth = InlineLayoutUnit()
    }
    typealias RunList = [Run]

    var runs = RunList()
    var m_logicalWidth = InlineLayoutUnit()
    var leadingTrimmableWidth = InlineLayoutUnit()
    var trailingTrimmableWidth = InlineLayoutUnit()
    var m_hangingContentWidth: InlineLayoutUnit? = nil
    var minimumRequiredWidth: InlineLayoutUnit? = nil
    var hasTextContent = false
    var isTextOnlyContent = true
    var isFullyTrimmable = false
    var hasTrailingWordSeparator = false
    var hasTrailingSoftHyphen = false
  }

  struct LineStatus {
    var contentLogicalRight = InlineLayoutUnit()
    var availableWidth = InlineLayoutUnit()
    // Both of these types of trailing content may be ignored when checking for content fit.
    var trimmableOrHangingWidth = InlineLayoutUnit()
    var trailingSoftHyphenWidth: InlineLayoutUnit? = nil
    var hasFullyTrimmableTrailingContent = false
    var hasContent = false
    var hasWrapOpportunityAtPreviousPosition = false
  }

  func processInlineContent(candidateContent: ContinuousContent, lineStatus: LineStatus) -> Result {
    assert(!lineStatus.availableWidth.isNaN)
    assert(
      isMinimumInIntrinsicWidthMode || candidateContent.logicalWidth() > lineStatus.availableWidth)

    if let result = simplifiedMinimumInstrinsicWidthBreak(
      candidateContent: candidateContent, lineStatus: lineStatus)
    {
      return result
    }

    var result = processOverflowingContent(
      continuousContent: candidateContent, lineStatus: lineStatus)
    if result.action == .Wrap && lineStatus.trailingSoftHyphenWidth != nil
      && hasLeadingTextContent(continuousContent: candidateContent)
    {
      // A trailing soft hyphen with a wrapped text content turns into a visible hyphen.
      // Let's check if there's enough space for the hyphen character.
      let hyphenOverflows = lineStatus.trailingSoftHyphenWidth! > lineStatus.availableWidth
      let action: Result.Action =
        hyphenOverflows ? .RevertToLastNonOverflowingWrapOpportunity : .WrapWithHyphen
      result = Result(action: action, isEndOfLine: .Yes)
    }
    return result
  }

  func setHyphenationDisabled(hyphenationIsDisabled: Bool) {
    self.hyphenationIsDisabled = hyphenationIsDisabled
  }

  func processOverflowingContent(continuousContent: ContinuousContent, lineStatus: LineStatus)
    -> Result
  {
    assert(!continuousContent.runs.isEmpty)

    assert(continuousContent.logicalWidth() > lineStatus.availableWidth)
    if let result = checkForTrailingContentFit(
      continuousContent: continuousContent, lineStatus: lineStatus)
    {
      return result
    }

    var overflowingRunIndex: UInt64 = 0
    if continuousContent.hasTextContent {
      if let result = tryBreakingContentWithText(
        continuousContent: continuousContent, lineStatus: lineStatus,
        overflowingRunIndex: &overflowingRunIndex)
      {
        return result
      }
    } else if continuousContent.runs.count > 1 {
      // FIXME: Add support for various content.
      let runs = continuousContent.runs
      for (i, run) in runs.enumerated() {
        if run.inlineItem.isAtomicInlineBox() {
          overflowingRunIndex = UInt64(i)
          break
        }
      }
    }

    // If we are not allowed to break this overflowing content, we still need to decide whether keep it or wrap it to the next line.
    if !lineStatus.hasContent {
      return Result(action: .Keep, isEndOfLine: .No)
    }
    // Now either wrap this content over to the next line or revert back to an earlier wrapping opportunity, or not wrap at all.
    if shouldWrapUnbreakableContentToNextLine(
      overflowingRunIndex: overflowingRunIndex, continuousContent: continuousContent)
    {
      return Result(action: .Wrap, isEndOfLine: .Yes)
    }
    if lineStatus.hasWrapOpportunityAtPreviousPosition {
      return Result(action: .RevertToLastWrapOpportunity, isEndOfLine: .Yes)
    }
    return Result(action: .Keep, isEndOfLine: .No)
  }

  func checkForTrailingContentFit(continuousContent: ContinuousContent, lineStatus: LineStatus)
    -> Result?
  {
    if continuousContent.isFullyTrimmable {
      // fully trimmable content stays on the current line (and gets fully trimmed).
      return Result(action: .Keep)
    }
    if continuousContent.hasTrimmableSpace() {
      // Check if the content fits if we trimmed it.
      if isWhitespaceOnlyContent(continuousContent: continuousContent) {
        return Result(action: .Keep)
      }
      var spaceRequired =
        continuousContent.logicalWidth() - continuousContent.trailingTrimmableWidth
      if lineStatus.hasFullyTrimmableTrailingContent {
        spaceRequired -= continuousContent.leadingTrimmableWidth
      }
      if spaceRequired <= lineStatus.availableWidth {
        return Result(action: .Keep)
      }
    }

    if continuousContent.isHangingContent() {
      return Result(action: .Keep)
    }
    if continuousContent.hasHangingSpace() {
      let spaceRequired = continuousContent.logicalWidth() - continuousContent.hangingContentWidth()
      if spaceRequired <= lineStatus.availableWidth {
        return Result(action: .Keep)
      }
    }

    let canIgnoreNonContentTrailingRuns =
      lineStatus.trimmableOrHangingWidth != 0
      && isNonContentRunsOnly(continuousContent: continuousContent)
    if canIgnoreNonContentTrailingRuns {
      // Let's see if the non-content runs fit when the line has trailing trimmable/hanging content.
      // "text content <span style="padding: 1px"></span>" <- the <span></span> runs could fit after trimming the trailing whitespace.
      if continuousContent.logicalWidth() <= lineStatus.availableWidth
        + lineStatus.trimmableOrHangingWidth
      {
        return Result(action: .Keep)
      }
    }

    return nil
  }

  func tryBreakingContentWithText(
    continuousContent: ContinuousContent, lineStatus: LineStatus, overflowingRunIndex: inout UInt64
  )
    -> Result?
  {
    // 1. This text content is not breakable.
    // 2. This breakable text content does not fit at all. Not even the first glyph. This is a very special case.
    // 3. We can break the content but it still overflows.
    // 4. Managed to break the content before the overflow point.
    let overflowingContent = processOverflowingContentWithText(
      continuousContent: continuousContent, lineStatus: lineStatus)
    overflowingRunIndex = overflowingContent.runIndex
    if overflowingContent.breakingPosition == nil {
      return nil
    }
    let trailingContent = overflowingContent.breakingPosition!.trailingContent
    if trailingContent == nil {
      // We tried to break the content but the available space can't even accommodate the first glyph.
      // 1. Wrap the content over to the next line when we've got content on the line already.
      // 2. Keep the first glyph on the empty line (or keep the whole run if it has only one glyph/completely empty)
      // including closing inline boxes e.g. <span><span>X</span></span> where "X" is the overflowing glyph).
      if lineStatus.hasContent {
        return Result(action: .Wrap, isEndOfLine: .Yes)
      }

      let leadingTextRunIndex = firstTextRunIndex(continuousContentRuns: continuousContent.runs)!
      let leadingTextRun = continuousContent.runs[Int(leadingTextRunIndex)]
      let inlineTextItem = leadingTextRun.inlineItem as! InlineTextItemWrapper
      let firstCharacterLength = TextUtil.firstUserPerceivedCharacterLength(
        inlineTextItem: inlineTextItem)
      assert(firstCharacterLength > 0)

      if inlineTextItem.length <= firstCharacterLength {
        if let runToBreakAfter = trailingRunIndex(
          leadingTextRunIndex: leadingTextRunIndex, continuousContent: continuousContent)
        {
          return Result(
            action: .Break, isEndOfLine: .Yes,
            partialTrailingContent: Result.PartialTrailingContent(
              trailingRunIndex: runToBreakAfter, partialRun: nil, hyphenWidth: nil))
        }
        return Result(action: .Break, isEndOfLine: .Yes)
      }

      let firstCharacterWidth = TextUtil.width(
        inlineTextItem: inlineTextItem, fontCascade: leadingTextRun.style.fontCascade(),
        from: inlineTextItem.start(),
        to: inlineTextItem.start() + UInt32(firstCharacterLength),
        contentLogicalLeft: lineStatus.contentLogicalRight)
      return Result(
        action: .Break, isEndOfLine: .Yes,
        partialTrailingContent: Result.PartialTrailingContent(
          trailingRunIndex: leadingTextRunIndex,
          partialRun: PartialRun(length: firstCharacterLength, logicalWidth: firstCharacterWidth),
          hyphenWidth: nil))
    }
    if trailingContent!.overflows && lineStatus.hasContent {
      // We managed to break a run with overflow but the line already has content. Let's wrap it to the next line.
      return Result(action: .Wrap, isEndOfLine: .Yes)
    }
    // Either we managed to break with no overflow or the line is empty.
    let trailingPartialContent = Result.PartialTrailingContent(
      trailingRunIndex: UInt64(overflowingContent.breakingPosition!.runIndex),
      partialRun: trailingContent!.partialRun,
      hyphenWidth: trailingContent!.hyphenWidth)
    return Result(action: .Break, isEndOfLine: .Yes, partialTrailingContent: trailingPartialContent)
  }

  func trailingRunIndex(leadingTextRunIndex: UInt64, continuousContent: ContinuousContent)
    -> UInt64?
  {
    // Keep the overflowing text content and the closing inline box runs together.
    // e.g. X</span><span>Y</span> where "X" overflows, the trailing run index is 1.
    let runs = continuousContent.runs
    if leadingTextRunIndex == runs.count - 1 {
      return nil
    }
    for runIndex in Int(leadingTextRunIndex + 1)..<runs.count {
      let inlineItem = runs[runIndex].inlineItem
      if inlineItem.isOpaque() {
        continue
      }
      if !inlineItem.isInlineBoxEnd() {
        return UInt64(runIndex - 1)
      }
    }
    return nil
  }

  func shouldWrapUnbreakableContentToNextLine(
    overflowingRunIndex: UInt64, continuousContent: ContinuousContent
  ) -> Bool {
    // The individual runs in this continuous content don't break, let's check if we are allowed to wrap this content to next line (e.g. pre would prevent us from wrapping).
    // Parent style drives the wrapping behavior here unless the overflowing run is an inline box.
    // In such cases decoration overflow is considered as "content" and we need to check the style accordingly.
    // e.g. <div style="white-space: nowrap">no wrap<div style="display: inline-block; white-space: normal">yes wrap</div></div>.
    // While the inline-block has pre-wrap which allows wrapping (for its own content), the content lives in a nowrap context.
    let runs = continuousContent.runs
    let overflowingBox = runs[Int(overflowingRunIndex)].inlineItem.layoutBox
    let styleToUse =
      overflowingBox.isInlineBox() ? overflowingBox.style : overflowingBox.parent().style
    var isWrappingAllowed = TextUtil.isWrappingAllowed(style: styleToUse)
    var index = Int(overflowingRunIndex)
    while !isWrappingAllowed && index >= 0 {
      let styleToUse = runs[index].inlineItem.layoutBox.parent().style
      isWrappingAllowed = TextUtil.isWrappingAllowed(style: styleToUse)
      index -= 1
    }
    return isWrappingAllowed
  }

  struct OverflowingTextContent {
    var runIndex: UInt64 = 0  // Overflowing run index. There's always an overflowing run.
    struct BreakingPosition {
      var runIndex: UInt64 = 0
      struct TrailingContent {
        // Trailing content is either the run's left side (when we break the run somewhere in the middle) or the previous run.
        // Sometimes the breaking position is at the very beginning of the first run, so there's no trailing run at all.
        var overflows = false
        var partialRun: InlineContentBreaker.PartialRun? = nil
        var hyphenWidth: InlineLayoutUnit? = nil
      }
      var trailingContent: TrailingContent? = nil
    }
    var breakingPosition: BreakingPosition? = nil
  }

  func processOverflowingContentWithText(
    continuousContent: ContinuousContent, lineStatus: LineStatus
  ) -> OverflowingTextContent {
    let runs = continuousContent.runs
    assert(!runs.isEmpty)

    // Check where the overflow occurs and use the corresponding style to figure out the breaking behavior.
    // <span style="word-break: normal">first</span><span style="word-break: break-all">second</span><span style="word-break: normal">third</span>

    // First find the overflowing run.
    var nonOverflowingContentWidth = InlineLayoutUnit()
    var overflowingRunIndex = runs.count
    for (index, run) in runs.enumerated() {
      if run.inlineItem.isOpaque() {
        continue
      }
      let runLogicalWidth = run.spaceRequired()
      if nonOverflowingContentWidth + runLogicalWidth > lineStatus.availableWidth {
        overflowingRunIndex = index
        break
      }
      nonOverflowingContentWidth += runLogicalWidth
    }
    if overflowingRunIndex == runs.count {
      // We have to have either an overflowing run or a soft hyphen.
      assert(continuousContent.hasTrailingSoftHyphen && runs.count != 0)
      return OverflowingTextContent(runIndex: runs.count != 0 ? UInt64(runs.count - 1) : 0)
    }

    // Check first if we can actually break the overflowing run.
    if let breakingPosition = tryBreakingOverflowingRun(
      lineStatus: lineStatus, runs: runs, overflowingRunIndex: UInt64(overflowingRunIndex),
      nonOverflowingContentWidth: nonOverflowingContentWidth)
    {
      return OverflowingTextContent(
        runIndex: UInt64(overflowingRunIndex), breakingPosition: breakingPosition)
    }

    let overflowingInlineItem = runs[overflowingRunIndex].inlineItem
    // In some cases we just can't break before certain overflowing runs due to content specific CSS rules, e.g. line-break: after-white-space.
    // This is in addition to having soft wrap opportunties only after the whitespace. This is about not breaking at all
    // before the whitespace content e.g.
    // <div style="line-break: after-white-space; word-wrap: break-word">before<span style="white-space: pre">   </span>after</div>
    // "before" content is not breakable sine it is _before_ the overflowing whitespace content.
    let textItem = overflowingInlineItem as? InlineTextItemWrapper
    let isBreakingAllowedBeforeOverflowingRun =
      textItem == nil || !textItem!.isWhitespace()
      || textItem!.style().lineBreak() != .AfterWhiteSpace
    if isBreakingAllowedBeforeOverflowingRun {
      // We did not manage to break the run that overflows the line.
      // Let's try to find a previous breaking position starting from the overflowing run. It surely fits.
      if let breakingPosition = tryBreakingPreviousNonOverflowingRuns(
        lineStatus: lineStatus, runs: runs, overflowingRunIndex: UInt64(overflowingRunIndex),
        nonOverflowingContentWidth: nonOverflowingContentWidth)
      {
        return OverflowingTextContent(
          runIndex: UInt64(overflowingRunIndex), breakingPosition: breakingPosition)
      }
    }

    if let breakingPosition = tryHyphenationAcrossOverflowingInlineTextItems(
      lineStatus: lineStatus, runs: runs, overflowingRunIndex: UInt64(overflowingRunIndex))
    {
      return OverflowingTextContent(
        runIndex: UInt64(overflowingRunIndex), breakingPosition: breakingPosition)
    }

    // At this point we know that there's no breakable run all the way to the overflowing run.
    // Now we need to check if any run after the overflowing content can break.
    // e.g. <span>this_content_overflows_but_not_breakable<span><span style="word-break: break-all">but_this_is_breakable</span>
    if let breakingPosition = tryBreakingNextOverflowingRuns(
      lineStatus: lineStatus, runs: runs, overflowingRunIndex: UInt64(overflowingRunIndex),
      nonOverflowingContentWidth: nonOverflowingContentWidth)
    {
      return OverflowingTextContent(
        runIndex: UInt64(overflowingRunIndex), breakingPosition: breakingPosition)
    }

    // Give up, there's no breakable run in here.
    return OverflowingTextContent(runIndex: UInt64(overflowingRunIndex))
  }

  func simplifiedMinimumInstrinsicWidthBreak(
    candidateContent: ContinuousContent, lineStatus: LineStatus
  ) -> Result? {
    if !isMinimumInIntrinsicWidthMode || !candidateContent.isTextOnlyContent {
      return nil
    }

    let leadingInlineTextItem = candidateContent.runs.first!.inlineItem as! InlineTextItemWrapper
    let style = leadingInlineTextItem.style()
    if !TextUtil.isWrappingAllowed(style: style) {
      return Result(action: .Keep, isEndOfLine: .No)
    }

    if !lineStatus.hasContent {
      if leadingInlineTextItem.isEmpty() {
        return Result(action: .Keep, isEndOfLine: .No)
      }
      let breakBehavior = wordBreakBehavior(
        style: style, hasWrapOpportunityAtPreviousPosition: false)
      if breakBehavior.isEmpty {
        return Result(action: .Keep, isEndOfLine: .No)
      }

      if breakBehavior.contains(.AtArbitraryPositionWithinWords)
        || breakBehavior.contains(.AtArbitraryPosition)
      {
        let firstCharacterLength = TextUtil.firstUserPerceivedCharacterLength(
          inlineTextItem: leadingInlineTextItem)
        if leadingInlineTextItem.length <= firstCharacterLength {
          return Result(action: .Keep, isEndOfLine: .Yes)
        }
        let firstCharacterWidth = TextUtil.width(
          inlineTextItem: leadingInlineTextItem, fontCascade: style.fontCascade(),
          from: leadingInlineTextItem.start(),
          to: leadingInlineTextItem.start() + UInt32(firstCharacterLength),
          contentLogicalLeft: InlineLayoutUnit(), useTrailingWhitespaceMeasuringOptimization: .No)
        return Result(
          action: .Break, isEndOfLine: .Yes,
          partialTrailingContent: Result.PartialTrailingContent(
            trailingRunIndex: 0,
            partialRun: PartialRun(length: firstCharacterLength, logicalWidth: firstCharacterWidth),
            hyphenWidth: nil
          ))
      }
      return nil
    }
    return Result(
      action: lineStatus.trailingSoftHyphenWidth == nil
        ? .Wrap : .RevertToLastNonOverflowingWrapOpportunity, isEndOfLine: .Yes)
  }

  struct CandidateTextRunForBreaking {
    var index: UInt64 = 0
    var isOverflowingRun = true
    var logicalLeft = InlineLayoutUnit()
  }

  func tryBreakingTextRun(
    runs: ContinuousContent.RunList, candidateTextRun: CandidateTextRunForBreaking,
    availableWidth: InlineLayoutUnit, lineStatus: LineStatus
  ) -> PartialRun? {
    let candidateRun = runs[Int(candidateTextRun.index)]
    assert(candidateRun.inlineItem.isText())
    let inlineTextItem = candidateRun.inlineItem as! InlineTextItemWrapper
    let style = candidateRun.style
    let lineHasRoomForContent = availableWidth > 0

    let breakRules = wordBreakBehavior(
      style: style,
      hasWrapOpportunityAtPreviousPosition: lineStatus.hasWrapOpportunityAtPreviousPosition)
    if breakRules.isEmpty {
      return nil
    }

    let fontCascade = style.fontCascade()
    if breakRules.contains(.AtArbitraryPositionWithinWords) {
      return tryBreakingAtArbitraryPositionWithinWords(
        style: style, inlineTextItem: inlineTextItem, candidateTextRun: candidateTextRun,
        candidateRun: candidateRun, breakRules: breakRules, availableWidth: availableWidth,
        lineHasRoomForContent: lineHasRoomForContent, lineStatus: lineStatus, runs: runs,
        fontCascade: fontCascade
      )
    }

    if breakRules.contains(.AtHyphenationOpportunities) {
      if let partialRun = tryBreakingAtHyphenationOpportunity(
        style: style,
        inlineTextItem: inlineTextItem,
        fontCascade: fontCascade, runs: runs, candidateTextRun: candidateTextRun,
        candidateRun: candidateRun, lineStatus: lineStatus,
        availableWidth: availableWidth)
      {
        return partialRun
      }
    }

    if breakRules.contains(.AtArbitraryPosition) {
      // With arbitrary breaking there's always a valid breaking position (even if it is before the first position).
      return tryBreakingAtArbitraryPosition(
        inlineTextItem: inlineTextItem, lineHasRoomForContent: lineHasRoomForContent,
        fontCascade: fontCascade, runs: runs, candidateTextRun: candidateTextRun,
        candidateRun: candidateRun, availableWidth: availableWidth)
    }

    return nil
  }

  func tryBreakingAtArbitraryPositionWithinWords(
    style: RenderStyleWrapper, inlineTextItem: InlineTextItemWrapper,
    candidateTextRun: CandidateTextRunForBreaking,
    candidateRun: ContinuousContent.Run, breakRules: InlineContentBreaker.WordBreakRule,
    availableWidth: InlineLayoutUnit, lineHasRoomForContent: Bool, lineStatus: LineStatus,
    runs: ContinuousContent.RunList,
    fontCascade: FontCascadeWrapper
  )
    -> PartialRun?
  {
    // Breaking is allowed within “words”: specifically, in addition to soft wrap opportunities allowed for normal, any typographic letter units
    // It does not affect rules governing the soft wrap opportunities created by white space. Hyphenation is not applied.
    assert(!breakRules.contains(.AtHyphenationOpportunities))
    if inlineTextItem.isWhitespace() {
      // AtArbitraryPositionWithinWords does not affect the breaking opportunities around whitespace.
      return nil
    }

    if inlineTextItem.length == 0 {
      // Empty/single character text runs may be breakable based on style, but in practice we can't really split them any further.
      return nil
    }

    if candidateTextRun.isOverflowingRun {
      if lineHasRoomForContent {
        // Try to break the overflowing run mid-word.
        if let wordBreak = midWordBreak(
          textRun: candidateRun, runLogicalLeft: candidateTextRun.logicalLeft,
          availableWidth: availableWidth)
        {
          return PartialRun(length: wordBreak.length, logicalWidth: wordBreak.logicalWidth)
        }
      }
      if canBreakBefore(
        character: UInt32(inlineTextItem.inlineTextBox().content[inlineTextItem.start()]),
        lineBreak: style.lineBreak())
      {
        return PartialRun()
      } else {
        // Since this is an overflowing content and we are allowed to break at arbitrary position, we really ought to find a breaking position.
        // Unless of course it's really an unbreakable content with nothing but e.g. punctuation characters.
        // FIXME: This should be merged with the "let's keep the first character on the line" logic (see in InlineContentBreaker::processOverflowingContent)
        if let wordBreak = firstBreakablePosition(
          style: style, inlineTextItem: inlineTextItem, candidateTextRun: candidateTextRun,
          lineStatus: lineStatus)
        {
          return PartialRun(length: wordBreak.length, logicalWidth: wordBreak.logicalWidth)
        }
      }
      return nil
    }

    // This is a non-overflowing content.
    assert(lineHasRoomForContent)
    if let breakingPosition = lastValidBreakingPosition(
      runs: runs, textRunIndex: candidateTextRun.index)
    {
      assert(breakingPosition <= inlineTextItem.end())
      let trailingLength = breakingPosition - UInt64(inlineTextItem.start())
      let startPosition = inlineTextItem.start()
      let endPosition = startPosition + UInt32(trailingLength)
      return PartialRun(
        length: trailingLength,
        logicalWidth: TextUtil.width(
          inlineTextItem: inlineTextItem, fontCascade: fontCascade, from: startPosition,
          to: endPosition,
          contentLogicalLeft: candidateTextRun.logicalLeft))
    }
    return nil
  }

  func tryBreakingAtHyphenationOpportunity(
    style: RenderStyleWrapper, inlineTextItem: InlineTextItemWrapper,
    fontCascade: FontCascadeWrapper, runs: ContinuousContent.RunList,
    candidateTextRun: CandidateTextRunForBreaking,
    candidateRun: ContinuousContent.Run, lineStatus: LineStatus,
    availableWidth: InlineLayoutUnit
  ) -> PartialRun? {
    let content = inlineTextItem.inlineTextBox().content.substring(
      position: inlineTextItem.start(), length: inlineTextItem.length)
    let hyphenWidth = TextUtil.hyphenWidth(style: style)

    if let position = hyphenLocation(
      content: content, style: style, inlineTextItem: inlineTextItem, fontCascade: fontCascade,
      runs: runs, candidateTextRun: candidateTextRun, candidateRun: candidateRun,
      lineStatus: lineStatus, hyphenWidth: hyphenWidth, availableWidth: availableWidth)
    {
      let trailingPartialRunWidthWithHyphen = TextUtil.width(
        inlineTextItem: inlineTextItem, fontCascade: fontCascade, from: inlineTextItem.start(),
        to: inlineTextItem.start() + UInt32(position),
        contentLogicalLeft: candidateTextRun.logicalLeft)
      return PartialRun(
        length: position, logicalWidth: trailingPartialRunWidthWithHyphen, hyphenWidth: hyphenWidth)
    }
    return nil
  }

  func tryBreakingAtArbitraryPosition(
    inlineTextItem: InlineTextItemWrapper, lineHasRoomForContent: Bool,
    fontCascade: FontCascadeWrapper,
    runs: ContinuousContent.RunList,
    candidateTextRun: CandidateTextRunForBreaking,
    candidateRun: ContinuousContent.Run,
    availableWidth: InlineLayoutUnit
  ) -> PartialRun? {
    if inlineTextItem.length == 0 {
      // Empty text runs may be breakable based on style, but in practice we can't really split them any further.
      return nil
    }
    if !candidateTextRun.isOverflowingRun {
      // When the run can be split at arbitrary position let's just return the entire run when it is intended to fit on the line.
      // However the breaking properties only set rules for text content, so let's check if this run is adjacent to another text run.
      assert(inlineTextItem.length != 0)
      // FIXME: We may need to check if the "next" text run is visually adjacent to this non-overflowing run too (e.g. A<span style="border: 100px solid green;"></span>B)
      if nextTextRunIndex(runs: runs, startIndex: candidateTextRun.index) != nil {
        // We are in-between text runs. It's okay to return the entire run triggering split at the very right edge.
        let trailingPartialRunWidth = TextUtil.width(
          inlineTextItem: inlineTextItem, fontCascade: fontCascade,
          contentLogicalLeft: candidateTextRun.logicalLeft)
        return PartialRun(
          length: UInt64(inlineTextItem.length), logicalWidth: trailingPartialRunWidth)
      }
      if inlineTextItem.length > 1 {
        let startPosition = inlineTextItem.start()
        let endPosition = inlineTextItem.end() - 1
        return PartialRun(
          length: UInt64(inlineTextItem.length - 1),
          logicalWidth: TextUtil.width(
            inlineTextItem: inlineTextItem, fontCascade: fontCascade, from: startPosition,
            to: endPosition, contentLogicalLeft: candidateTextRun.logicalLeft))
      }
      return nil
    }
    if !lineHasRoomForContent {
      // Fast path for cases when there's no room at all. The content is breakable but we don't have space for it.
      return PartialRun()
    }
    let wordBreak = TextUtil.breakWord(
      inlineTextItem: inlineTextItem, fontCascade: fontCascade,
      textWidth: candidateRun.spaceRequired(), availableWidth: availableWidth,
      contentLogicalLeft: candidateTextRun.logicalLeft)
    return PartialRun(length: wordBreak.length, logicalWidth: wordBreak.logicalWidth)
  }

  func hyphenLocation(
    content: StringWrapper, style: RenderStyleWrapper, inlineTextItem: InlineTextItemWrapper,
    fontCascade: FontCascadeWrapper, runs: ContinuousContent.RunList,
    candidateTextRun: CandidateTextRunForBreaking,
    candidateRun: ContinuousContent.Run, lineStatus: LineStatus, hyphenWidth: InlineLayoutUnit,
    availableWidth: InlineLayoutUnit
  ) -> UInt64? {
    if !candidateTextRun.isOverflowingRun {
      return lastHyphenPosition(content: StringWrapperView(s: content), style: style)
    }

    let availableWidthExcludingHyphen = availableWidth - hyphenWidth
    let hasSomeRoomForContent =
      availableWidthExcludingHyphen > 0
      && enoughWidthForHyphenation(
        availableWidth: availableWidthExcludingHyphen, fontSize: fontCascade.size())
    if hasSomeRoomForContent && candidateRun.spaceRequired() != 0 {
      let leftSideLength = TextUtil.breakWord(
        inlineTextItem: inlineTextItem, fontCascade: fontCascade,
        textWidth: candidateRun.spaceRequired(), availableWidth: availableWidthExcludingHyphen,
        contentLogicalLeft: candidateTextRun.logicalLeft
      ).length
      if let position = hyphenPositionBefore(
        content: StringWrapperView(s: content), style: style, beforePosition: leftSideLength)
      {
        return position
      }
    }
    return !lineStatus.hasContent
      && firstTextRunIndex(continuousContentRuns: runs)! == candidateTextRun.index
      ? firstHyphenPosition(content: StringWrapperView(s: content), style: style) : nil
  }

  func firstBreakablePosition(
    style: RenderStyleWrapper, inlineTextItem: InlineTextItemWrapper,
    candidateTextRun: CandidateTextRunForBreaking, lineStatus: LineStatus
  )
    -> TextUtil.WordBreakLeft?
  {
    if lineStatus.hasContent {
      return nil
    }
    let text = inlineTextItem.inlineTextBox().content
    let left = inlineTextItem.start()
    var right = left
    U16_SET_CP_START(s: text, start: left, i: right)
    while right < inlineTextItem.end() {
      U16_FWD_1(s: text, i: &right, length: inlineTextItem.length)
      if canBreakBefore(character: UInt32(text[right]), lineBreak: style.lineBreak()) {
        if right == inlineTextItem.end() {
          return nil
        }
        return TextUtil.WordBreakLeft(
          length: UInt64(right - left),
          logicalWidth: TextUtil.width(
            inlineTextItem: inlineTextItem, fontCascade: style.fontCascade(), from: left, to: right,
            contentLogicalLeft: candidateTextRun.logicalLeft)
        )
      }
    }
    return nil
  }

  func tryBreakingOverflowingRun(
    lineStatus: LineStatus, runs: ContinuousContent.RunList, overflowingRunIndex: UInt64,
    nonOverflowingContentWidth: InlineLayoutUnit
  ) -> OverflowingTextContent.BreakingPosition? {
    let overflowingRun = runs[Int(overflowingRunIndex)]
    assert(!overflowingRun.inlineItem.isOpaque())
    if !isBreakableRun(run: overflowingRun) {
      return nil
    }

    let availableWidth = max(0, lineStatus.availableWidth - nonOverflowingContentWidth)
    let partialOverflowingRun = tryBreakingTextRun(
      runs: runs,
      candidateTextRun: CandidateTextRunForBreaking(
        index: overflowingRunIndex, isOverflowingRun: true,
        logicalLeft: lineStatus.contentLogicalRight + nonOverflowingContentWidth),
      availableWidth: availableWidth, lineStatus: lineStatus)
    if partialOverflowingRun == nil {
      return nil
    }
    if partialOverflowingRun!.length != 0 {
      return OverflowingTextContent.BreakingPosition(
        runIndex: overflowingRunIndex,
        trailingContent: OverflowingTextContent.BreakingPosition.TrailingContent(
          overflows: false, partialRun: partialOverflowingRun))
    }
    // When the breaking position is at the beginning of the run, the trailing run is the previous one.
    if let trailingRunIndex = findTrailingRunIndexBeforeBreakableRun(
      runs: runs, breakableRunIndex: overflowingRunIndex)
    {
      return OverflowingTextContent.BreakingPosition(
        runIndex: trailingRunIndex,
        trailingContent: OverflowingTextContent.BreakingPosition.TrailingContent())
    }
    // Sometimes we can't accommodate even the very first character.
    // Note that this is different from when there's no breakable run in this set.
    return OverflowingTextContent.BreakingPosition()
  }

  func tryBreakingPreviousNonOverflowingRuns(
    lineStatus: LineStatus, runs: ContinuousContent.RunList, overflowingRunIndex: UInt64,
    nonOverflowingContentWidth: InlineLayoutUnit
  ) -> OverflowingTextContent.BreakingPosition? {
    var previousContentWidth = nonOverflowingContentWidth
    for index in (0..<overflowingRunIndex).reversed() {
      let run = runs[Int(index)]
      previousContentWidth -= run.spaceRequired()
      if !isBreakableRun(run: run) {
        continue
      }
      assert(run.inlineItem.isText())
      let availableWidth = max(0, lineStatus.availableWidth - previousContentWidth)
      if let partialRun = tryBreakingTextRun(
        runs: runs,
        candidateTextRun: CandidateTextRunForBreaking(
          index: index, isOverflowingRun: false,
          logicalLeft: lineStatus.contentLogicalRight + previousContentWidth),
        availableWidth: availableWidth,
        lineStatus: lineStatus)
      {
        // We know this run fits, so if breaking is allowed on the run, it should return a non-empty left-side
        // since it's either at hyphen position or the entire run is returned.
        assert(partialRun.length != 0)
        let runIsFullyAccommodated =
          partialRun.length == (run.inlineItem as! InlineTextItemWrapper).length
        if runIsFullyAccommodated {
          // Try not break content at inline box boundary.
          // e.g. <span style="word-wrap: break-word">fits_and_we_break_at_the_right_edge</span><span>overflows</span>
          // we should forward the breaking index to the closing inline box.
          // FIXME: We may wanna skip over the visually empty inline boxes only e.g. <span style="word-wrap: break-word">fits_and_we_break_at_the_right_edge</span><span></span><span>overflows</span>
          var trailingInlineBoxEndIndex: UInt64? = nil
          for candidateIndex in (index + 1)...overflowingRunIndex {
            let trailingInlineItem = runs[Int(candidateIndex)].inlineItem
            if trailingInlineItem.isInlineBoxEnd() {
              trailingInlineBoxEndIndex = candidateIndex
            }
            if !trailingInlineItem.isInlineBoxStartOrEnd() {
              break
            }
          }
          assert(
            trailingInlineBoxEndIndex == nil || trailingInlineBoxEndIndex! <= overflowingRunIndex)
          let trailingRunIndex = trailingInlineBoxEndIndex ?? index
          return OverflowingTextContent.BreakingPosition(
            runIndex: trailingRunIndex,
            trailingContent: OverflowingTextContent.BreakingPosition.TrailingContent(
              overflows: false))
        }
        return OverflowingTextContent.BreakingPosition(
          runIndex: index,
          trailingContent: OverflowingTextContent.BreakingPosition.TrailingContent(
            overflows: false, partialRun: partialRun))
      }
    }
    return nil
  }

  func tryBreakingNextOverflowingRuns(
    lineStatus: LineStatus, runs: ContinuousContent.RunList, overflowingRunIndex: UInt64,
    nonOverflowingContentWidth: InlineLayoutUnit
  ) -> OverflowingTextContent.BreakingPosition? {
    var nextContentWidth =
      nonOverflowingContentWidth + runs[Int(overflowingRunIndex)].spaceRequired()
    for index in overflowingRunIndex + 1..<UInt64(runs.count) {
      let run = runs[Int(index)]
      if !isBreakableRun(run: run) {
        nextContentWidth += run.spaceRequired()
        continue
      }
      assert(run.inlineItem.isText())
      // At this point the available space is zero. Let's try the break these overflowing set of runs at the earliest possible.
      if let partialRun = tryBreakingTextRun(
        runs: runs,
        candidateTextRun: CandidateTextRunForBreaking(
          index: index, isOverflowingRun: true,
          logicalLeft: lineStatus.contentLogicalRight + nextContentWidth),
        availableWidth: 0, lineStatus: lineStatus)
      {
        // <span>unbreakable_and_overflows<span style="word-break: break-all">breakable</span>
        // The partial run length could very well be 0 meaning the trailing run is actually the overflowing run (see above in the example).
        if partialRun.length != 0 {
          // We managed to break this text run mid content. It has to be either an arbitrary mid-word or a hyphen break.
          return OverflowingTextContent.BreakingPosition(
            runIndex: index,
            trailingContent: OverflowingTextContent.BreakingPosition.TrailingContent(
              overflows: true, partialRun: partialRun))
        }
        if let trailingRunIndex = findTrailingRunIndexBeforeBreakableRun(
          runs: runs, breakableRunIndex: index)
        {
          // We may end up _before_ the overflowing run e.g.
          // <span></span><span style="border: 10px solid">breakable</span>
          // with 0px constraint, where while the second (non-empty) [inline box start] overflows, the trailing
          // run ends up being the first [inline box end] inline item.
          return OverflowingTextContent.BreakingPosition(
            runIndex: trailingRunIndex,
            trailingContent: OverflowingTextContent.BreakingPosition.TrailingContent(
              overflows: true))
        }
        // This happens when the overflowing run is also the first run in this set, no trailing run.
        return OverflowingTextContent.BreakingPosition(
          runIndex: overflowingRunIndex,
          trailingContent: OverflowingTextContent.BreakingPosition.TrailingContent())
      }
      nextContentWidth += run.spaceRequired()
    }
    return nil
  }

  func tryHyphenationAcrossOverflowingInlineTextItems(
    lineStatus: LineStatus, runs: ContinuousContent.RunList, overflowingRunIndex: UInt64
  ) -> OverflowingTextContent.BreakingPosition? {
    if runs.count == 1 {
      return nil
    }

    let style = runs.first!.inlineItem.style()
    if !wordBreakBehavior(
      style: style,
      hasWrapOpportunityAtPreviousPosition: lineStatus.hasWrapOpportunityAtPreviousPosition
    ).contains(.AtHyphenationOpportunities) {
      return nil
    }

    // 1. concatenate adjacent text content
    // 2. find the last hyphen location before the overflowing position
    // 3. find the inline text item where the hyphen location is and compute the partial run width
    let content = StringBuilderWrapper()
    var overflowingRunStartPosition: UInt64 = 0
    for (index, run) in runs.enumerated() {
      let inlineItem = run.inlineItem
      // FIXME: Maybe content across inline boxes should be hyphenated as well.
      if inlineItem.isOpaque() {
        continue
      }
      if inlineItem.style().fontCascade() !== style.fontCascade() {
        return nil
      }

      let inlineTextItem = inlineItem as? InlineTextItemWrapper
      if inlineTextItem == nil || inlineTextItem!.isWhitespace() {
        return nil
      }
      content.append(
        string:
          inlineTextItem!.inlineTextBox().content.substring(
            position: inlineTextItem!.start(), length: inlineTextItem!.length))
      overflowingRunStartPosition +=
        index < overflowingRunIndex ? UInt64(inlineTextItem!.length) : 0
    }
    // Only non-whitespace text runs with same style.
    let fontCascade = style.fontCascade()
    let hyphenWidth = TextUtil.hyphenWidth(style: style)
    let availableWidthExcludingHyphen = lineStatus.availableWidth - hyphenWidth
    if availableWidthExcludingHyphen <= 0
      || !enoughWidthForHyphenation(
        availableWidth: availableWidthExcludingHyphen, fontSize: fontCascade.size())
    {
      return nil
    }

    let overflowingRun = runs[Int(overflowingRunIndex)]
    let textItem = overflowingRun.inlineItem as? InlineTextItemWrapper
    assert(textItem != nil)
    if textItem == nil {
      return nil
    }
    // Make sure we always hyphenate before the overflow.
    let overflowPositionWithHyphen = TextUtil.breakWord(
      inlineTextItem: textItem!, fontCascade: fontCascade,
      textWidth: overflowingRun.spaceRequired(), availableWidth: availableWidthExcludingHyphen,
      contentLogicalLeft: lineStatus.contentLogicalRight
    ).length
    let hyphenLocation = hyphenPositionBefore(
      content: content.view(), style: style,
      beforePosition: overflowingRunStartPosition + overflowPositionWithHyphen)
    if hyphenLocation == nil {
      return nil
    }

    // hyphenLocation must be in or before the overflowing run.
    assert(hyphenLocation! <= overflowingRunStartPosition + overflowPositionWithHyphen)
    var hyphenLocationWithinInlineTextItem = hyphenLocation!
    var hyphenatedRunIndex: UInt64 = 0
    while hyphenatedRunIndex <= overflowingRunIndex {
      let inlineItem = runs[Int(hyphenatedRunIndex)].inlineItem
      if inlineItem.isOpaque() {
        hyphenatedRunIndex += 1
        continue
      }
      let inlineTextItem = inlineItem as! InlineTextItemWrapper
      if inlineTextItem.length >= hyphenLocationWithinInlineTextItem {
        break
      }
      hyphenLocationWithinInlineTextItem -= UInt64(inlineTextItem.length)
      hyphenatedRunIndex += 1
    }
    let hyphenatedlineTextItem = runs[Int(hyphenatedRunIndex)].inlineItem as! InlineTextItemWrapper
    if hyphenLocationWithinInlineTextItem > hyphenatedlineTextItem.length {
      fatalError("Not reached")
    }

    // Hyphen may be right at the run (end) boundary.
    var partialRun: InlineContentBreaker.PartialRun? = nil
    if hyphenLocationWithinInlineTextItem < hyphenatedlineTextItem.length {
      let trailingPartialRunWidthWithHyphen = TextUtil.width(
        inlineTextItem: hyphenatedlineTextItem, fontCascade: fontCascade,
        from: hyphenatedlineTextItem.start(),
        to: hyphenatedlineTextItem.start() + UInt32(hyphenLocationWithinInlineTextItem),
        contentLogicalLeft: lineStatus.contentLogicalRight)
      partialRun = InlineContentBreaker.PartialRun(
        length: hyphenLocationWithinInlineTextItem, logicalWidth: trailingPartialRunWidthWithHyphen,
        hyphenWidth: hyphenWidth)
    }
    return OverflowingTextContent.BreakingPosition(
      runIndex: hyphenatedRunIndex,
      trailingContent: OverflowingTextContent.BreakingPosition.TrailingContent(
        overflows: false, partialRun: partialRun, hyphenWidth: hyphenWidth
      ))
  }

  struct WordBreakRule: OptionSet {
    let rawValue: UInt8
    static let AtArbitraryPositionWithinWords = WordBreakRule(rawValue: 1 << 0)
    static let AtArbitraryPosition = WordBreakRule(rawValue: 1 << 1)
    static let AtHyphenationOpportunities = WordBreakRule(rawValue: 1 << 2)
  }

  func wordBreakBehavior(style: RenderStyleWrapper, hasWrapOpportunityAtPreviousPosition: Bool)
    -> WordBreakRule
  {
    // Disregard any prohibition against line breaks mandated by the word-break property.
    // The different wrapping opportunities must not be prioritized.
    // Note hyphenation is not applied.
    if style.lineBreak() == .Anywhere {
      return .AtArbitraryPosition
    }

    // Breaking is allowed within “words”.
    if style.wordBreak() == .BreakAll {
      return .AtArbitraryPositionWithinWords
    }

    // For compatibility with legacy content, the word-break property also supports a deprecated break-word keyword.
    // When specified, this has the same effect as word-break: normal and overflow-wrap: anywhere, regardless of the actual value of the overflow-wrap property.
    if style.wordBreak() == .BreakWord && !hasWrapOpportunityAtPreviousPosition {
      return includeHyphenationIfAllowed(wordBreakRule: .AtArbitraryPosition, style: style)
    }
    // OverflowWrap::BreakWord/Anywhere An otherwise unbreakable sequence of characters may be broken at an arbitrary point if there are no otherwise-acceptable break points in the line.
    // Note that this applies to content where CSS properties (e.g. WordBreak::KeepAll) make it unbreakable.
    // Soft wrap opportunities introduced by overflow-wrap/word-wrap: break-word are not considered when calculating min-content intrinsic sizes.
    let overflowWrapBreakWordIsApplicable = !isMinimumInIntrinsicWidthMode
    if ((overflowWrapBreakWordIsApplicable && style.overflowWrap() == .BreakWord)
      || style.overflowWrap() == .Anywhere) && !hasWrapOpportunityAtPreviousPosition
    {
      return includeHyphenationIfAllowed(wordBreakRule: .AtArbitraryPosition, style: style)
    }
    // Breaking is forbidden within “words”.
    if style.wordBreak() == .KeepAll {
      return WordBreakRule()
    }
    return includeHyphenationIfAllowed(wordBreakRule: nil, style: style)
  }

  func includeHyphenationIfAllowed(wordBreakRule: WordBreakRule?, style: RenderStyleWrapper)
    -> WordBreakRule
  {
    let hyphenationIsAllowed =
      !hyphenationIsDisabled && style.hyphens() == .Auto
      && canHyphenate(localeIdentifier: style.computedLocale())
    if hyphenationIsAllowed {
      if let wordBreakRule = wordBreakRule {
        return wordBreakRule.union(.AtHyphenationOpportunities)
      }
      return .AtHyphenationOpportunities
    }
    if let wordBreakRule = wordBreakRule {
      return wordBreakRule
    }
    return WordBreakRule()
  }

  var isMinimumInIntrinsicWidthMode = false
  var hyphenationIsDisabled = false
}
