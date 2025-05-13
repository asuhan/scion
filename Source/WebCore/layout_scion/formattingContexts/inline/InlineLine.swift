/*
 * Copyright (C) 2020 Apple Inc. All rights reserved.
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

func toLineRunType(inlineItem: InlineItemWrapper) -> Line.Run.`Type` {
  switch inlineItem.type {
  case .HardLineBreak:
    return .HardLineBreak
  case .WordBreakOpportunity:
    return .WordBreakOpportunity
  case .AtomicInlineBox:
    if inlineItem.layoutBox.isListMarkerBox() {
      return (inlineItem.layoutBox as! ElementBoxWrapper).isListMarkerOutside()
        ? .ListMarkerOutside : .ListMarkerInside
    }
    return .AtomicInlineBox
  case .InlineBoxStart:
    return .InlineBoxStart
  case .InlineBoxEnd:
    return .InlineBoxEnd
  case .Opaque:
    return .Opaque
  default:
    fatalError("Not reached")
  }
}

struct Line {
  init(inlineFormattingContext: InlineFormattingContext) {
    self.runs = RunList()
    self.inlineFormattingContext = inlineFormattingContext
    self.trimmableTrailingContent = TrimmableTrailingContent(runs: self.runs)
  }

  mutating func initialize(lineSpanningInlineBoxes: [InlineItemWrapper], isFirstFormattedLine: Bool)
  {
    self.isFirstFormattedLine = isFirstFormattedLine
    inlineBoxListWithClonedDecorationEnd.removeAll()
    clonedEndDecorationWidthForInlineBoxRuns = InlineLayoutUnit()
    rubyAlignContentRightOffset = InlineLayoutUnit()
    nonSpanningInlineLevelBoxCount = 0
    hasNonDefaultBidiLevelRun = false
    hasRubyContent = false
    contentLogicalWidth = InlineLayoutUnit()
    inlineBoxLogicalLeftStack.removeAll()
    runs.removeAll()
    resetTrailingContent()
    for inlineBoxStartItem in lineSpanningInlineBoxes {
      if inlineBoxStartItem.style().boxDecorationBreak() != .Clone {
        runs.append(
          Run(
            lineSpanningInlineBoxItem: inlineBoxStartItem, logicalLeft: lastRunLogicalRight(),
            logicalWidth: InlineLayoutUnit()))
      } else {
        // https://drafts.csswg.org/css-break/#break-decoration
        // clone: Each box fragment is independently wrapped with the border, padding, and margin.
        let inlineBoxGeometry = formattingContext().geometryForBox(
          layoutBox: inlineBoxStartItem.layoutBox)
        let marginBorderAndPaddingStart = inlineBoxGeometry.marginBorderAndPaddingStart()
        let runLogicalLeft = lastRunLogicalRight()
        runs.append(
          Run(
            lineSpanningInlineBoxItem: inlineBoxStartItem, logicalLeft: runLogicalLeft,
            logicalWidth: marginBorderAndPaddingStart.float()))
        // Do not let negative margin make the content shorter than it already is.
        contentLogicalWidth = max(contentLogicalWidth, runLogicalLeft + marginBorderAndPaddingStart)
        contentLogicalWidth += addBorderAndPaddingEndForInlineBoxDecorationClone(
          inlineBoxStartItem: inlineBoxStartItem)
      }
    }
  }

  mutating func append(
    inlineItem: InlineItemWrapper, style: RenderStyleWrapper, logicalWidth: InlineLayoutUnit
  ) {
    if let inlineTextItem = inlineItem as? InlineTextItemWrapper {
      appendTextContent(inlineTextItem: inlineTextItem, style: style, logicalWidth: logicalWidth)
    } else if inlineItem.isLineBreak() {
      appendLineBreak(inlineItem: inlineItem, style: style)
    } else if inlineItem.isWordBreakOpportunity() {
      appendWordBreakOpportunity(inlineItem: inlineItem, style: style)
    } else if inlineItem.isInlineBoxStart() {
      appendInlineBoxStart(inlineItem: inlineItem, style: style, logicalWidthIn: logicalWidth)
    } else if inlineItem.isInlineBoxEnd() {
      appendInlineBoxEnd(inlineItem: inlineItem, style: style, logicalWidth: logicalWidth)
    } else if inlineItem.isAtomicInlineBox() {
      appendAtomicInlineBox(
        inlineItem: inlineItem, style: style, marginBoxLogicalWidth: logicalWidth)
    } else if inlineItem.isOpaque() {
      assert(logicalWidth == 0)
      appendOpaqueBox(inlineItem: inlineItem, style: style)
    } else {
      fatalError("Not reached")
    }
    hasNonDefaultBidiLevelRun =
      hasNonDefaultBidiLevelRun || inlineItem.bidiLevel != .UBIDI_DEFAULT_LTR
  }

  // Reserved for TextOnlySimpleLineBuilder
  mutating func appendTextFast(
    inlineTextItem: InlineTextItemWrapper, style: RenderStyleWrapper, logicalWidth: InlineLayoutUnit
  ) {
    let lineHasContent = !runs.isEmpty

    if willCollapseCompletelyFast(inlineTextItem: inlineTextItem, lineHasContent: lineHasContent) {
      return
    }

    let needsNewRun = needsNewRunFast(
      inlineTextItem: inlineTextItem, lineHasContent: lineHasContent)
    let oldContentLogicalWidth = contentLogicalWidth
    if needsNewRun {
      let runLogicalLeft = lastRunLogicalRight()
      runs.append(
        Run(
          inlineTextItem: inlineTextItem, style: style, logicalLeft: runLogicalLeft,
          logicalWidth: logicalWidth))
      contentLogicalWidth = runLogicalLeft + logicalWidth
    } else {
      let lastRun = runs.last!
      assert(lastRun.isText())
      if style.letterSpacing() >= 0 {
        lastRun.expand(inlineTextItem: inlineTextItem, logicalWidth: logicalWidth)
        contentLogicalWidth = lastRun.logicalRight()
      } else {
        let contentWidthWithoutLastTextRun = contentLogicalWidth - max(0, lastRun.logicalWidth)
        let lastRunLogicalRight = lastRun.logicalRight()
        lastRun.expand(inlineTextItem: inlineTextItem, logicalWidth: logicalWidth)
        // Negative letter spacing should only shorten the content to the boundary of the previous run.
        contentLogicalWidth = max(
          contentWidthWithoutLastTextRun, lastRunLogicalRight + logicalWidth)
      }
    }

    trailingSoftHyphenWidth = nil
    let isTrimmable = updateTrimmableStatusFast(
      inlineTextItem: inlineTextItem, logicalWidth: logicalWidth,
      oldContentLogicalWidth: oldContentLogicalWidth)

    updateHangingStatusFast(
      inlineTextItem: inlineTextItem, style: style, isTrimmable: isTrimmable,
      logicalWidth: logicalWidth)

    if inlineTextItem.hasTrailingSoftHyphen {
      trailingSoftHyphenWidth = TextUtil.hyphenWidth(style: style)
    }
  }

  func willCollapseCompletelyFast(inlineTextItem: InlineTextItemWrapper, lineHasContent: Bool)
    -> Bool
  {
    if inlineTextItem.isEmpty() {
      return true
    }
    if !inlineTextItem.isWhitespace()
      || InlineTextItemWrapper.shouldPreserveSpacesAndTabs(inlineTextItem: inlineTextItem)
    {
      return false
    }
    return !lineHasContent || runs.last!.hasCollapsibleTrailingWhitespace()
  }

  func needsNewRunFast(inlineTextItem: InlineTextItemWrapper, lineHasContent: Bool) -> Bool {
    if !lineHasContent {
      return true
    }
    let lastRun = runs.last!
    if lastRun.hasCollapsedTrailingWhitespace() {
      return true
    }
    if lastRun.layoutBox !== inlineTextItem.layoutBox {
      return true
    }
    if inlineTextItem.isZeroWidthSpaceSeparator() {
      return true
    }
    if inlineTextItem.isQuirkNonBreakingSpace() || lastRun.isNonBreakingSpace() {
      return true
    }
    return false
  }

  mutating func updateTrimmableStatusFast(
    inlineTextItem: InlineTextItemWrapper, logicalWidth: InlineLayoutUnit,
    oldContentLogicalWidth: InlineLayoutUnit
  ) -> Bool {
    if inlineTextItem.isFullyTrimmable() {
      let trimmableWidth = logicalWidth
      let trimmableContentOffset = (contentLogicalWidth - oldContentLogicalWidth) - trimmableWidth
      trimmableTrailingContent.addFullyTrimmableContent(
        runIndex: UInt64(runs.count - 1), trimmableContentOffset: trimmableContentOffset,
        trimmableWidth: trimmableWidth)
      return true
    }
    trimmableTrailingContent.reset()
    return false
  }

  mutating func updateHangingStatusFast(
    inlineTextItem: InlineTextItemWrapper, style: RenderStyleWrapper, isTrimmable: Bool,
    logicalWidth: InlineLayoutUnit
  ) {
    let runHasHangableWhitespaceEnd =
      !isTrimmable && inlineTextItem.isWhitespace()
      && TextUtil.shouldTrailingWhitespaceHang(style: style)
    if runHasHangableWhitespaceEnd {
      hangingContent.setTrailingWhitespace(
        length: UInt64(inlineTextItem.length), logicalWidth: logicalWidth)
      return
    }
    hangingContent.resetTrailingContent()
  }

  func hasContent() -> Bool {
    for run in runs.reversed() {
      if run.isContentful() && !run.isGenerated() {
        return true
      }
    }
    return false
  }

  func hasContentOrListMarker() -> Bool {
    if runs.isEmpty {
      return false
    }
    if runs.first!.isListMarkerInside() {
      return true
    }
    return hasContent()
  }

  func contentLogicalRight() -> InlineLayoutUnit {
    return lastRunLogicalRight() + clonedEndDecorationWidthForInlineBoxRuns
  }

  func hangingTrailingContentWidth() -> InlineLayoutUnit { return hangingContent.trailingWidth() }

  func hangingTrailingWhitespaceLength() -> UInt64 {
    return hangingContent.trailingWhitespaceLength()
  }

  func isHangingTrailingContentWhitespace() -> Bool {
    return hangingContent.trailingWhitespaceLength() != 0
  }

  func trimmableTrailingWidth() -> InlineLayoutUnit { return trimmableTrailingContent.width() }

  func isTrailingRunFullyTrimmable() -> Bool {
    return trimmableTrailingContent.isTrailingRunFullyTrimmable()
  }

  mutating func addTrailingHyphen(hyphenLogicalWidth: InlineLayoutUnit) {
    for i in (0..<runs.count).reversed() {
      let run = runs[i]
      if !run.isText() {
        continue
      }
      run.setNeedsHyphen(hyphenLogicalWidth: hyphenLogicalWidth)
      contentLogicalWidth += hyphenLogicalWidth
      return
    }
    fatalError("Not reached")
  }

  enum TrailingContentAction: UInt8 {
    case Remove
    case Preserve
  }
  @discardableResult
  mutating func handleTrailingTrimmableContent(
    trailingTrimmableContentAction: TrailingContentAction
  )
    -> InlineLayoutUnit
  {
    if trimmableTrailingContent.isEmpty() || runs.isEmpty {
      return InlineLayoutUnit()
    }

    if trailingTrimmableContentAction == .Preserve {
      trimmableTrailingContent.reset()
      return InlineLayoutUnit()
    }

    let trimmedWidth = trimmableTrailingContent.remove()
    contentLogicalWidth -= trimmedWidth
    return trimmedWidth
  }

  mutating func handleTrailingHangingContent(
    intrinsicWidthMode: IntrinsicWidthMode?, horizontalAvailableSpaceForContent: InlineLayoutUnit,
    isLastFormattedLine: Bool
  ) {
    // https://drafts.csswg.org/css-text/#hanging
    if hangingContent.trailingWidth() == 0 {
      return
    }

    if hangingContent.isTrailingContentPunctuation() && !isLastFormattedLine {
      hangingContent.resetTrailingContent()
    }

    let lineEndsWithForcedLineBreak =
      isLastFormattedLine || (!runs.isEmpty && runs.last!.isLineBreak())
    let hangingTrailingContentIsConditional =
      hangingContent.isTrailingContentConditional()
      || (hangingContent.isTrailingContentConditionalWhenFollowedByForcedLineBreak()
        && lineEndsWithForcedLineBreak)

    if let intrinsicWidthMode = intrinsicWidthMode {
      // 1. The hanging glyph is not taken into account when computing intrinsic sizes (min-content size and max-content size)
      // 2. Glyphs that conditionally hang are not taken into account when computing min-content sizes, but they are taken into account for max-content sizes.
      if intrinsicWidthMode == .Minimum || !hangingTrailingContentIsConditional {
        assert(trimmableTrailingContent.isEmpty())
        contentLogicalWidth -= hangingContent.trailingWidth()
      }
    } else {
      // Make sure when the conditionally hanging content actually fits we don't hang the content anymore during normal layout.
      if hangingTrailingContentIsConditional {
        // In some cases, a glyph at the end of a line can conditionally hang: it hangs only if it does not otherwise fit in the line prior to justification.
        let doesTrailingHangingContentFit =
          contentLogicalWidth <= horizontalAvailableSpaceForContent
        if doesTrailingHangingContentFit {
          // Reset here means the trailing content is not hanging anymore -i.e. part of the line content.
          hangingContent.resetTrailingContent()
        }
      }
    }
  }

  mutating func handleOverflowingNonBreakingSpace(
    trailingContentAction: TrailingContentAction, overflowingWidth: InlineLayoutUnit
  ) {
    var index = startIndexForOverflowingNonBreakingSpace(overflowingWidth: overflowingWidth)
    var removedOrCollapsedContentWidth = InlineLayoutUnit()
    while index < runs.count {
      let run = runs[Int(index)]

      if !run.isNonBreakingSpace() {
        run.moveHorizontally(offset: -removedOrCollapsedContentWidth)
        index += 1
        continue
      }
      if trailingContentAction == .Preserve {
        run.moveHorizontally(offset: -removedOrCollapsedContentWidth)
        removedOrCollapsedContentWidth += run.logicalWidth
        run.shrinkHorizontally(width: run.logicalWidth)
        index += 1
        continue
      }

      removedOrCollapsedContentWidth += run.logicalWidth
      runs.remove(at: Int(index))
    }
    contentLogicalWidth -= removedOrCollapsedContentWidth
  }

  func startIndexForOverflowingNonBreakingSpace(overflowingWidth: InlineLayoutUnit) -> UInt64 {
    var trimmedContentWidth = InlineLayoutUnit()
    for (index, run) in runs.enumerated().reversed() {
      if run.isLineBreak() || run.isInlineBox() || run.isWordBreakOpportunity()
        || run.isWordSeparator()
      {
        // It's ok to trim/remove non-breaking spaces across inline boxes.
        continue
      }
      if !run.isNonBreakingSpace() {
        // Only trim/remove trailing non-breaking space.
        return UInt64(index)
      }
      trimmedContentWidth += run.logicalWidth
      if trimmedContentWidth >= overflowingWidth {
        // This is how much non-breakable space needs to be removed or trimmed.
        return UInt64(index)
      }
    }
    return 0
  }

  mutating func removeOverflowingOutOfFlowContent() -> BoxWrapper? {
    var lastTrailingOpaqueItemIndex: UInt64? = nil
    for (index, run) in runs.enumerated().reversed() {
      if run.isOpaque() {
        lastTrailingOpaqueItemIndex = UInt64(index)
        continue
      }
      if run.logicalWidth == 0 && (run.isInlineBoxStart() || run.isInlineBoxEnd()) {
        continue
      }
      break
    }
    if let lastTrailingOpaqueItemIndex = lastTrailingOpaqueItemIndex {
      let lastTrailingOpaqueBox = runs[Int(lastTrailingOpaqueItemIndex)].layoutBox
      runs.removeSubrange(Int(lastTrailingOpaqueItemIndex)..<runs.count)
      assert(!runs.isEmpty)
      return lastTrailingOpaqueBox
    }
    return nil
  }

  mutating func resetBidiLevelForTrailingWhitespace(rootBidiLevel: UBiDiLevel) {
    assert(trimmableTrailingContent.isEmpty())
    if !hasNonDefaultBidiLevelRun {
      return
    }
    // UAX#9 L1: trailing whitespace should use paragraph direction.
    // see https://unicode.org/reports/tr9/#L1
    var trailingNonWhitespaceOnlyRunIndex: UInt64? = nil
    for index in (0..<runs.count).reversed() {
      let run = runs[index]
      if run.isAtomicInlineBox() || run.isLineBreak()
        || (run.isText() && !run.hasTrailingWhitespace())
      {
        break
      }

      if !run.hasTrailingWhitespace() {
        // Skip non-content type of runs e.g. <span>
        continue
      }
      // No need to adjust the bidi level unless the directionality is different.
      // e.g. rtl root dir with trailing whitespace attached to an rtl run.
      let sameInlineDirection = run.bidiLevel.rawValue % 2 == rootBidiLevel.rawValue % 2
      if !run.isWhitespaceOnly() {
        trailingNonWhitespaceOnlyRunIndex = !sameInlineDirection ? UInt64(index) : nil
        // There can't be any trailing whitespace in front of this non-whitespace/whitespace content.
        break
      }
      // Whitespace only runs just need simple bidi level reset.
      if !sameInlineDirection {
        run.setBidiLevel(bidiLevel: rootBidiLevel)
      }
    }

    if let runIndex = trailingNonWhitespaceOnlyRunIndex {
      let run = runs[Int(runIndex)]
      let detachedTrailingRun = run.detachTrailingWhitespace()!
      detachedTrailingRun.setBidiLevel(bidiLevel: rootBidiLevel)
      if runIndex == runs.count - 1 {
        runs.append(detachedTrailingRun)
        return
      }
      runs.insert(detachedTrailingRun, at: Int(runIndex + 1))
    }
  }

  class Run {
    enum `Type`: UInt8 {
      case Text
      case NonBreakingSpace
      case WordSeparator
      case HardLineBreak
      case SoftLineBreak
      case WordBreakOpportunity
      case AtomicInlineBox
      case ListMarkerInside
      case ListMarkerOutside
      case InlineBoxStart
      case InlineBoxEnd
      case LineSpanningInlineBoxStart
      case Opaque
    }

    func isText() -> Bool { return type == .Text || isWordSeparator() || isNonBreakingSpace() }

    func isNonBreakingSpace() -> Bool { return type == .NonBreakingSpace }

    func isWordSeparator() -> Bool { return type == .WordSeparator }

    func isAtomicInlineBox() -> Bool { return type == .AtomicInlineBox }

    func isListMarker() -> Bool { return isListMarkerInside() || isListMarkerOutside() }

    func isListMarkerInside() -> Bool { return type == .ListMarkerInside }

    func isListMarkerOutside() -> Bool { return type == .ListMarkerOutside }

    func isLineBreak() -> Bool { return isHardLineBreak() || isSoftLineBreak() }

    func isSoftLineBreak() -> Bool { return type == .SoftLineBreak }

    func isHardLineBreak() -> Bool { return type == .HardLineBreak }

    func isWordBreakOpportunity() -> Bool { return type == .WordBreakOpportunity }

    func isInlineBox() -> Bool {
      return isInlineBoxStart() || isLineSpanningInlineBoxStart() || isInlineBoxEnd()
    }

    func isInlineBoxStart() -> Bool { return type == .InlineBoxStart }

    func isContentful() -> Bool {
      return (isText() && textContent!.length != 0) || isAtomicInlineBox() || isLineBreak()
        || isListMarker()
    }

    func isGenerated() -> Bool { return isListMarker() }

    func isLineSpanningInlineBoxStart() -> Bool { return type == .LineSpanningInlineBoxStart }

    func isInlineBoxEnd() -> Bool { return type == .InlineBoxEnd }

    func isOpaque() -> Bool { return type == .Opaque }

    static func isContentfulOrHasDecoration(run: Run, formattingContext: InlineFormattingContext)
      -> Bool
    {
      if run.isContentful() {
        return true
      }
      if run.isInlineBox() {
        if run.logicalWidth != 0 {
          return true
        }
        if run.layoutBox.isRubyBase() {
          return true
        }
        // Even negative horizontal margin makes the line "contentful".
        let inlineBoxGeometry = formattingContext.geometryForBox(layoutBox: run.layoutBox)
        if run.isInlineBoxStart() {
          return inlineBoxGeometry.marginStart().bool() || inlineBoxGeometry.borderStart().bool()
            || inlineBoxGeometry.paddingStart().bool()
        }
        if run.isInlineBoxEnd() {
          return inlineBoxGeometry.marginEnd().bool() || inlineBoxGeometry.borderEnd().bool()
            || inlineBoxGeometry.paddingEnd().bool()
        }
        if run.isLineSpanningInlineBoxStart() {
          if run.style.boxDecorationBreak() != .Clone {
            return false
          }
          return inlineBoxGeometry.borderStart().bool() || inlineBoxGeometry.paddingStart().bool()
        }
      }
      return false
    }

    struct Text {
      var start: UInt64 = 0
      var length: UInt64 = 0
      var needsHyphen = false
    }

    func logicalRight() -> InlineLayoutUnit {
      return logicalLeft + logicalWidth
    }

    func hasTrailingWhitespace() -> Bool {
      return trailingWhitespace != nil
    }

    func isWhitespaceOnly() -> Bool {
      return hasTrailingWhitespace() && trailingWhitespace!.length == textContent!.length
    }

    func inlineDirection() -> TextDirection {
      return style.direction()
    }

    func letterSpacing() -> InlineLayoutUnit {
      return style.letterSpacing()
    }

    // FIXME: Maybe add create functions intead?
    init(
      zeroWidthInlineItem: InlineItemWrapper, style: RenderStyleWrapper,
      logicalLeft: InlineLayoutUnit
    ) {
      self.type = toLineRunType(inlineItem: zeroWidthInlineItem)
      self.layoutBox = zeroWidthInlineItem.layoutBox
      self.style = style
      self.logicalLeft = logicalLeft
      self.bidiLevel = zeroWidthInlineItem.bidiLevel
    }

    init(
      lineSpanningInlineBoxItem: InlineItemWrapper, logicalLeft: InlineLayoutUnit,
      logicalWidth: InlineLayoutUnit
    ) {
      self.type = .LineSpanningInlineBoxStart
      self.layoutBox = lineSpanningInlineBoxItem.layoutBox
      self.style = lineSpanningInlineBoxItem.style()
      self.logicalLeft = logicalLeft
      self.logicalWidth = logicalWidth
      self.bidiLevel = lineSpanningInlineBoxItem.bidiLevel
    }

    init(
      inlineTextItem: InlineTextItemWrapper, style: RenderStyleWrapper,
      logicalLeft: InlineLayoutUnit,
      logicalWidth: InlineLayoutUnit
    ) {
      self.type =
        inlineTextItem.isWordSeparator
        ? .WordSeparator : (inlineTextItem.isQuirkNonBreakingSpace() ? .NonBreakingSpace : .Text)
      self.layoutBox = inlineTextItem.layoutBox
      self.style = style
      self.logicalLeft = logicalLeft
      self.logicalWidth = logicalWidth
      self.bidiLevel = inlineTextItem.bidiLevel
      var length = UInt64(inlineTextItem.length)
      let whitespaceType = trailingWhitespaceType(inlineTextItem: inlineTextItem)
      if let whitespaceType = whitespaceType {
        if whitespaceType == .Collapsed {
          length = 1
        }
        trailingWhitespace = TrailingWhitespace(
          type: whitespaceType, width: logicalWidth, length: length)
      }
      textContent = Text(start: UInt64(inlineTextItem.start()), length: length)
    }

    init(
      softLineBreakItem: InlineSoftLineBreakItemWrapper, style: RenderStyleWrapper,
      logicalLeft: InlineLayoutUnit
    ) {
      self.type = .SoftLineBreak
      self.layoutBox = softLineBreakItem.layoutBox
      self.style = style
      self.logicalLeft = logicalLeft
      self.bidiLevel = softLineBreakItem.bidiLevel
      self.textContent = Text(start: UInt64(softLineBreakItem.position()), length: 1)
    }

    init(
      inlineItem: InlineItemWrapper, style: RenderStyleWrapper,
      logicalLeft: InlineLayoutUnit,
      logicalWidth: InlineLayoutUnit
    ) {
      self.type = toLineRunType(inlineItem: inlineItem)
      self.layoutBox = inlineItem.layoutBox
      self.style = style
      self.logicalLeft = logicalLeft
      self.logicalWidth = logicalWidth
      self.bidiLevel = inlineItem.bidiLevel
    }

    func hasTextCombine() -> Bool { return style.hasTextCombine() }

    func expand(inlineTextItem: InlineTextItemWrapper, logicalWidth: InlineLayoutUnit) {
      assert(!hasCollapsedTrailingWhitespace())
      assert(isText() && inlineTextItem.isText())
      assert(CPtrToInt(layoutBox.p) == CPtrToInt(inlineTextItem.layoutBox.p))
      assert(bidiLevel == inlineTextItem.bidiLevel)

      self.logicalWidth += logicalWidth
      let whitespaceType = trailingWhitespaceType(inlineTextItem: inlineTextItem)

      if let whitespaceType = whitespaceType {
        let whitespaceWidth =
          trailingWhitespace == nil ? logicalWidth : trailingWhitespace!.width + logicalWidth
        let trailingWhitespaceLength = UInt64(
          whitespaceType == .Collapsed ? 1 : inlineTextItem.length)
        trailingWhitespace = TrailingWhitespace(
          type: whitespaceType, width: whitespaceWidth, length: trailingWhitespaceLength)
        textContent!.length += trailingWhitespaceLength
        return
      }
      trailingWhitespace = nil
      textContent!.length += UInt64(inlineTextItem.length)
      lastNonWhitespaceContentStart = UInt64(inlineTextItem.start())
    }

    func moveHorizontally(offset: InlineLayoutUnit) {
      logicalLeft += offset
    }

    func shrinkHorizontally(width: InlineLayoutUnit) {
      logicalWidth -= width
    }

    func setExpansion(expansion: InlineDisplay.Box.Expansion) {
      self.expansion = expansion
    }

    func setNeedsHyphen(hyphenLogicalWidth: InlineLayoutUnit) {
      assert(textContent != nil)
      textContent!.needsHyphen = true
      logicalWidth += hyphenLogicalWidth
    }

    func setBidiLevel(bidiLevel: UBiDiLevel) {
      self.bidiLevel = bidiLevel
    }

    struct TrailingWhitespace {
      enum `Type` {
        case NotCollapsible
        case Collapsible
        case Collapsed
      }
      var type = Type.NotCollapsible
      var width = InlineLayoutUnit()
      var length: UInt64 = 0
    }

    func hasCollapsibleTrailingWhitespace() -> Bool {
      return trailingWhitespace != nil
        && (trailingWhitespace!.type == .Collapsible || hasCollapsedTrailingWhitespace())
    }

    func hasCollapsedTrailingWhitespace() -> Bool {
      return trailingWhitespace != nil && trailingWhitespace!.type == .Collapsed
    }

    func trailingWhitespaceType(inlineTextItem: InlineTextItemWrapper) -> TrailingWhitespace.`Type`?
    {
      if !inlineTextItem.isWhitespace() {
        return nil
      }
      if InlineTextItemWrapper.shouldPreserveSpacesAndTabs(inlineTextItem: inlineTextItem) {
        return .NotCollapsible
      }
      if inlineTextItem.length == 1 {
        return .Collapsible
      }
      return .Collapsed
    }

    func removeTrailingWhitespace() -> InlineLayoutUnit {
      assert(trailingWhitespace != nil)
      // According to https://www.w3.org/TR/css-text-3/#white-space-property matrix
      // Trimmable whitespace is always collapsible so the length of the trailing trimmable whitespace is always 1 (or non-existent).
      assert(textContent != nil && textContent!.length != 0)
      let trailingTrimmableContentLength: UInt64 = 1

      var trimmedWidth = trailingWhitespace!.width
      if lastNonWhitespaceContentStart != nil && inlineDirection() == .RTL {
        // While LTR content could also suffer from slightly incorrect content width after trimming trailing whitespace (see TextUtil::width)
        // it hardly produces visually observable result.
        // FIXME: This may still incorrectly leave some content on the line (vs. re-measuring also at ::expand).
        let inlineTextBox = layoutBox as! InlineTextBoxWrapper
        let startPosition = lastNonWhitespaceContentStart!
        let endPosition = textContent!.start + textContent!.length
        assert(startPosition < endPosition - trailingTrimmableContentLength)
        if inlineTextBox.content[UInt32(endPosition - 1)] == CharacterNames.Unicode.space {
          trimmedWidth = TextUtil.trailingWhitespaceWidth(
            inlineTextBox: inlineTextBox, fontCascade: style.fontCascade(),
            startPosition: UInt32(startPosition), endPosition: UInt32(endPosition))
        }
      }
      textContent!.length -= trailingTrimmableContentLength
      trailingWhitespace = nil
      shrinkHorizontally(width: trimmedWidth)
      return trimmedWidth
    }

    func hasTrailingLetterSpacing() -> Bool {
      return !hasTrailingWhitespace() && letterSpacing() > 0
    }

    func trailingLetterSpacing() -> InlineLayoutUnit {
      if !hasTrailingLetterSpacing() {
        return InlineLayoutUnit()
      }
      return letterSpacing()
    }

    func removeTrailingLetterSpacing() -> InlineLayoutUnit {
      assert(hasTrailingLetterSpacing())
      let trailingWidth = trailingLetterSpacing()
      shrinkHorizontally(width: trailingWidth)
      assert(
        logicalWidth > 0 || (logicalWidth == 0 && letterSpacing() >= Float32(intMaxForLayoutUnit)))
      return trailingWidth
    }

    func detachTrailingWhitespace() -> Run? {
      if trailingWhitespace == nil || isWhitespaceOnly() {
        return nil
      }

      assert(trailingWhitespace!.length < textContent!.length)
      let trailingWhitespaceRun = self.clone()

      let leadingNonWhitespaceContentLength = textContent!.length - trailingWhitespace!.length
      trailingWhitespaceRun.textContent = Text(
        start: textContent!.start + leadingNonWhitespaceContentLength,
        length: trailingWhitespace!.length, needsHyphen: false)

      trailingWhitespaceRun.logicalWidth = trailingWhitespace!.width
      trailingWhitespaceRun.logicalLeft = logicalRight() - trailingWhitespace!.width

      trailingWhitespaceRun.trailingWhitespace = nil
      trailingWhitespaceRun.lastNonWhitespaceContentStart = nil

      logicalWidth -= trailingWhitespaceRun.logicalWidth
      textContent!.length = leadingNonWhitespaceContentLength
      trailingWhitespace = nil

      return trailingWhitespaceRun
    }

    private init(
      type: `Type`, layoutBox: BoxWrapper, style: RenderStyleWrapper,
      logicalLeft: InlineLayoutUnit, logicalWidth: InlineLayoutUnit,
      expansion: InlineDisplay.Box.Expansion, bidiLevel: UBiDiLevel,
      trailingWhitespace: TrailingWhitespace?, lastNonWhitespaceContentStart: UInt64?,
      textContent: Text?
    ) {
      self.type = type
      self.layoutBox = layoutBox
      self.style = style
      self.logicalLeft = logicalLeft
      self.logicalWidth = logicalWidth
      self.expansion = expansion
      self.bidiLevel = bidiLevel
      self.trailingWhitespace = trailingWhitespace
      self.lastNonWhitespaceContentStart = lastNonWhitespaceContentStart
      self.textContent = textContent
    }

    private func clone() -> Run {
      return Line.Run(
        type: type, layoutBox: layoutBox, style: style,
        logicalLeft: logicalLeft, logicalWidth: logicalWidth,
        expansion: expansion, bidiLevel: bidiLevel,
        trailingWhitespace: trailingWhitespace,
        lastNonWhitespaceContentStart: lastNonWhitespaceContentStart,
        textContent: textContent)
    }

    private var type: `Type` = .Text
    var layoutBox: BoxWrapper
    var style: RenderStyleWrapper
    var logicalLeft = InlineLayoutUnit()
    var logicalWidth = InlineLayoutUnit()
    var expansion = InlineDisplay.Box.Expansion()
    var bidiLevel: UBiDiLevel = .UBIDI_DEFAULT_LTR
    var trailingWhitespace: TrailingWhitespace? = nil
    var lastNonWhitespaceContentStart: UInt64? = nil
    var textContent: Text? = nil
  }

  mutating func inflateContentLogicalWidth(delta: InlineLayoutUnit) {
    contentLogicalWidth += delta
  }

  // FIXME: This is temporary and should be removed when annotation transitions to inline box structure.
  mutating func adjustContentRightWithRubyAlign(offset: InlineLayoutUnit) {
    rubyAlignContentRightOffset = offset
  }

  class RunList: Sequence {
    subscript(index: Int) -> Run {
      return storage[index]
    }

    func makeIterator() -> IndexingIterator<[Run]> {
      return storage.makeIterator()
    }

    func enumerated() -> EnumeratedSequence<[Run]> {
      return storage.enumerated()
    }

    func reversed() -> ReversedCollection<[Run]> {
      return storage.reversed()
    }

    func append(_ run: Run) {
      storage.append(run)
    }

    func insert(_ newElement: Run, at i: Int) {
      storage.insert(newElement, at: i)
    }

    func removeAll() {
      storage.removeAll()
    }

    func remove(at index: Int) {
      storage.remove(at: index)
    }

    func removeSubrange(_ bounds: Range<Int>) {
      storage.removeSubrange(bounds)
    }

    var count: Int {
      return storage.count
    }

    var isEmpty: Bool {
      return storage.isEmpty
    }

    var first: Run? {
      return storage.first
    }

    var last: Run? {
      return storage.last
    }

    private var storage: [Run] = []
  }

  typealias InlineBoxListWithClonedDecorationEnd = [UInt: InlineLayoutUnit]

  struct Result {
    var runs = RunList()
    var contentLogicalWidth = InlineLayoutUnit()
    var contentLogicalRight = InlineLayoutUnit()
    var isHangingTrailingContentWhitespace = false
    var hangingTrailingContentWidth = InlineLayoutUnit()
    var hangablePunctuationStartWidth = InlineLayoutUnit()
    var contentNeedsBidiReordering = false
    var nonSpanningInlineLevelBoxCount: UInt64 = 0
  }
  func close() -> Result {
    let contentLogicalRight = contentLogicalRight() + rubyAlignContentRightOffset
    return Result(
      runs: runs,
      contentLogicalWidth: contentLogicalWidth,
      contentLogicalRight: contentLogicalRight,
      isHangingTrailingContentWhitespace: hangingContent.trailingWhitespaceLength() != 0,
      hangingTrailingContentWidth: hangingContent.trailingWidth(),
      hangablePunctuationStartWidth: hangingContent.leadingPunctuationWidth,
      contentNeedsBidiReordering: hasNonDefaultBidiLevelRun,
      nonSpanningInlineLevelBoxCount: nonSpanningInlineLevelBoxCount
    )
  }

  static func restoreTrimmedTrailingWhitespace(
    trimmedTrailingWhitespaceWidth: InlineLayoutUnit, runs: RunList
  ) -> Bool {
    var lastRun = runs.last!
    if lastRun.isText() {
      return restoreTrailingRun(
        trailingRun: &lastRun, trimmedTrailingWhitespaceWidth: trimmedTrailingWhitespaceWidth)
    }

    let isHardLineBreakWithTrailingTextRun =
      lastRun.isHardLineBreak() && runs.count > 1 && runs[runs.count - 2].isText()
    var trailingRun = runs[runs.count - 2]
    if isHardLineBreakWithTrailingTextRun {
      if !restoreTrailingRun(
        trailingRun: &trailingRun,
        trimmedTrailingWhitespaceWidth: trimmedTrailingWhitespaceWidth)
      {
        return false
      }
      lastRun.moveHorizontally(offset: trimmedTrailingWhitespaceWidth)
      return true
    }
    return false
  }

  static func restoreTrailingRun(
    trailingRun: inout Run, trimmedTrailingWhitespaceWidth: InlineLayoutUnit
  )
    -> Bool
  {
    assert(trailingRun.isText())
    let layoutBox = trailingRun.layoutBox as! InlineTextBoxWrapper
    if trailingRun.textContent!.start + trailingRun.textContent!.length
      == layoutBox.content.length()
    {
      fatalError("Not reached")
    }
    trailingRun.logicalWidth += trimmedTrailingWhitespaceWidth
    // This must be collapsed whitespace.
    trailingRun.textContent!.length += 1
    return true
  }

  func lastRunLogicalRight() -> InlineLayoutUnit {
    return runs.isEmpty ? 0 : runs.last!.logicalRight()
  }

  private mutating func appendTextContent(
    inlineTextItem: InlineTextItemWrapper, style: RenderStyleWrapper, logicalWidth: InlineLayoutUnit
  ) {
    if willCollapseCompletely(inlineTextItem: inlineTextItem) {
      return
    }

    let needsNewRun = needsNewRun(inlineTextItem: inlineTextItem, style: style)
    let oldContentLogicalWidth = contentLogicalWidth
    let runHasHangablePunctuationStart =
      isFirstFormattedLine
      && TextUtil.hasHangablePunctuationStart(inlineTextItem: inlineTextItem, style: style)
      && !lineHasVisuallyNonEmptyContent()
    var contentLogicalRight = InlineLayoutUnit()
    if needsNewRun {
      // Note, negative word spacing may cause glyph overlap.
      var runLogicalLeft = InlineLayoutUnit()
      if runHasHangablePunctuationStart {
        runLogicalLeft = -TextUtil.hangablePunctuationStartWidth(
          inlineTextItem: inlineTextItem, style: style)
      } else {
        runLogicalLeft =
          lastRunLogicalRight()
          + (inlineTextItem.isWordSeparator ? style.fontCascade().wordSpacing() : 0)
      }
      runs.append(
        Run(
          inlineTextItem: inlineTextItem, style: style, logicalLeft: runLogicalLeft,
          logicalWidth: logicalWidth))
      // Note that the _content_ logical right may be larger than the _run_ logical right.
      contentLogicalRight = runLogicalLeft + logicalWidth
    } else {
      let lastRun = runs.last!
      assert(lastRun.isText())
      if style.letterSpacing() >= 0 {
        lastRun.expand(inlineTextItem: inlineTextItem, logicalWidth: logicalWidth)
        contentLogicalRight = lastRun.logicalRight()
      } else {
        let contentWidthWithoutLastTextRun = contentWidthWithoutLastTextRun(
          lastRun: lastRun, style: style)
        let lastRunLogicalRight = lastRun.logicalRight()
        lastRun.expand(inlineTextItem: inlineTextItem, logicalWidth: logicalWidth)
        // Negative letter spacing should only shorten the content to the boundary of the previous run.
        contentLogicalRight = max(
          contentWidthWithoutLastTextRun, lastRunLogicalRight + logicalWidth)
      }
    }
    // Ensure that property values that act like negative margin are not making the line wider.
    contentLogicalWidth = max(
      oldContentLogicalWidth, contentLogicalRight + clonedEndDecorationWidthForInlineBoxRuns)

    let lastRunIndex = runs.count - 1
    trailingSoftHyphenWidth = nil
    let isTrimmable = updateTrimmableStatus(
      inlineTextItem: inlineTextItem, logicalWidth: logicalWidth,
      oldContentLogicalWidth: oldContentLogicalWidth, lastRunIndex: lastRunIndex)
    updateHangingStatus(
      inlineTextItem: inlineTextItem, style: style,
      runHasHangablePunctuationStart: runHasHangablePunctuationStart, isTrimmable: isTrimmable,
      lastRunIndex: lastRunIndex, logicalWidth: logicalWidth)

    if inlineTextItem.hasTrailingSoftHyphen {
      trailingSoftHyphenWidth = TextUtil.hyphenWidth(style: style)
    }
  }

  func willCollapseCompletely(inlineTextItem: InlineTextItemWrapper) -> Bool {
    if inlineTextItem.isEmpty() {
      // Some generated content initiates empty text items. They are truly collapsible.
      return true
    }
    if !inlineTextItem.isWhitespace() {
      return false
    }
    if InlineTextItemWrapper.shouldPreserveSpacesAndTabs(inlineTextItem: inlineTextItem) {
      return false
    }
    // This content is collapsible. Let's check if the last item is collapsed.
    for run in runs.reversed() {
      if run.isAtomicInlineBox() {
        return false
      }
      // https://drafts.csswg.org/css-text-3/#white-space-phase-1
      // Any collapsible space immediately following another collapsible space—even one outside the boundary of the inline containing that space,
      // provided both spaces are within the same inline formatting context—is collapsed to have zero advance width.
      if run.isText() {
        return run.hasCollapsibleTrailingWhitespace()
      }
      assert(
        run.isListMarker() || run.isLineSpanningInlineBoxStart() || run.isInlineBoxStart()
          || run.isInlineBoxEnd() || run.isWordBreakOpportunity() || run.isOpaque())
    }
    // Leading whitespace.
    return true
  }

  private func needsNewRun(inlineTextItem: InlineTextItemWrapper, style: RenderStyleWrapper) -> Bool
  {
    if runs.isEmpty {
      return true
    }
    let lastRun = runs.last!
    if lastRun.layoutBox !== inlineTextItem.layoutBox {
      return true
    }
    if lastRun.bidiLevel != inlineTextItem.bidiLevel {
      return true
    }
    if !lastRun.isText() {
      return true
    }
    if lastRun.hasCollapsedTrailingWhitespace() {
      return true
    }
    if style.fontCascade().wordSpacing() != 0
      && (inlineTextItem.isWordSeparator
        || (lastRun.isWordSeparator() && lastRun.bidiLevel != .UBIDI_DEFAULT_LTR))
    {
      return true
    }
    if inlineTextItem.isZeroWidthSpaceSeparator() {
      return true
    }
    if inlineTextItem.isQuirkNonBreakingSpace() || lastRun.isNonBreakingSpace() {
      return true
    }
    if !inlineTextItem.style().isLeftToRightDirection()
      && TextUtil.shouldPreserveSpacesAndTabs(layoutBox: inlineTextItem.layoutBox)
      && inlineTextItem.isWhitespace() != lastRun.isWhitespaceOnly()
    {
      // Whitespace content with position dependent width (e.g. tab character) does not work well when included with non-whitespace content.
      // We may end up with mismatching computed widths and misplaced glyphs at paint time -unless we keep dedicated runs with explicit positions.
      return true
    }
    return false
  }

  func contentWidthWithoutLastTextRun(lastRun: Run, style: RenderStyleWrapper) -> InlineLayoutUnit {
    // FIXME: We may need to traverse all the way to the previous non-text run (or even across inline boxes).
    if style.fontCascade().wordSpacing() >= 0 {
      return contentLogicalWidth - max(0, lastRun.logicalWidth)
    }
    // FIXME: Let's see if we need to optimize for this is the rare case of both letter and word spacing being negative.
    var rightMostPosition = InlineLayoutUnit()
    for run in runs.reversed() {
      rightMostPosition = max(rightMostPosition, run.logicalRight())
    }
    return max(0, rightMostPosition)
  }

  mutating func updateTrimmableStatus(
    inlineTextItem: InlineTextItemWrapper, logicalWidth: InlineLayoutUnit,
    oldContentLogicalWidth: InlineLayoutUnit, lastRunIndex: Int
  )
    -> Bool
  {
    if inlineTextItem.isFullyTrimmable() {
      let trimmableWidth = logicalWidth
      let trimmableContentOffset = (contentLogicalWidth - oldContentLogicalWidth) - trimmableWidth
      trimmableTrailingContent.addFullyTrimmableContent(
        runIndex: UInt64(lastRunIndex), trimmableContentOffset: trimmableContentOffset,
        trimmableWidth: trimmableWidth)
      return true
    }
    trimmableTrailingContent.reset()
    return false
  }

  mutating func updateHangingStatus(
    inlineTextItem: InlineTextItemWrapper, style: RenderStyleWrapper,
    runHasHangablePunctuationStart: Bool, isTrimmable: Bool, lastRunIndex: Int,
    logicalWidth: InlineLayoutUnit
  ) {
    if runHasHangablePunctuationStart {
      hangingContent.setLeadingPunctuation(
        logicalWidth:
          TextUtil.hangablePunctuationStartWidth(inlineTextItem: inlineTextItem, style: style))
    }

    let runHasHangableWhitespaceEnd =
      !isTrimmable && inlineTextItem.isWhitespace()
      && TextUtil.shouldTrailingWhitespaceHang(style: runs[lastRunIndex].style)
    if runHasHangableWhitespaceEnd {
      hangingContent.setTrailingWhitespace(
        length: UInt64(inlineTextItem.length), logicalWidth: logicalWidth)
      return
    }
    if TextUtil.hasHangablePunctuationEnd(inlineTextItem: inlineTextItem, style: style) {
      hangingContent.setTrailingPunctuation(
        logicalWidth: TextUtil.hangablePunctuationEndWidth(
          inlineTextItem: inlineTextItem, style: style))
      return
    }
    if TextUtil.hasHangableStopOrCommaEnd(inlineTextItem: inlineTextItem, style: style) {
      let isConditionalHanging = style.hangingPunctuation().contains(.AllowEnd)
      hangingContent.setTrailingStopOrComma(
        logicalWidth: TextUtil.hangableStopOrCommaEndWidth(
          inlineTextItem: inlineTextItem, style: style),
        isConditional: isConditionalHanging)
      return
    }
    hangingContent.resetTrailingContent()
  }

  private mutating func appendAtomicInlineBox(
    inlineItem: InlineItemWrapper, style: RenderStyleWrapper,
    marginBoxLogicalWidth: InlineLayoutUnit
  ) {
    resetTrailingContent()
    // Do not let negative margin make the content shorter than it already is.
    contentLogicalWidth = max(contentLogicalWidth, lastRunLogicalRight() + marginBoxLogicalWidth)
    nonSpanningInlineLevelBoxCount += 1
    let marginStart = formattingContext().geometryForBox(layoutBox: inlineItem.layoutBox)
      .marginStart()
    if marginStart >= 0 {
      runs.append(
        Run(
          inlineItem: inlineItem, style: style, logicalLeft: lastRunLogicalRight(),
          logicalWidth: marginBoxLogicalWidth))
      return
    }
    // Negative margin-start pulls the content to the logical left direction.
    // Negative margin also squeezes the margin box, we need to stretch it to make sure the subsequent content won't overlap.
    // e.g. <img style="width: 100px; margin-left: -100px;"> pulls the replaced box to -100px with the margin box width of 0px.
    // Instead we need to position it at -100px and size it to 100px so the subsequent content starts at 0px.
    runs.append(
      Run(
        inlineItem: inlineItem, style: style,
        logicalLeft: lastRunLogicalRight() + marginStart.float(),
        logicalWidth: marginBoxLogicalWidth - marginStart.float()))
  }

  private mutating func appendInlineBoxStart(
    inlineItem: InlineItemWrapper, style: RenderStyleWrapper, logicalWidthIn: InlineLayoutUnit
  ) {
    var logicalWidth = logicalWidthIn
    let inlineBoxGeometry = formattingContext().geometryForBox(layoutBox: inlineItem.layoutBox)
    if inlineBoxGeometry.marginBorderAndPaddingStart().bool() {
      hangingContent.resetTrailingContent()
    }
    // This is really just a placeholder to mark the start of the inline box <span>.
    nonSpanningInlineLevelBoxCount += 1
    var logicalLeft = lastRunLogicalRight()
    // Incoming logical width includes the cloned decoration end to be able to do line breaking.
    let borderAndPaddingEndForDecorationClone = addBorderAndPaddingEndForInlineBoxDecorationClone(
      inlineBoxStartItem: inlineItem)
    // Do not let negative margin make the content shorter than it already is.
    contentLogicalWidth = max(contentLogicalWidth, logicalLeft + logicalWidth)

    let marginStart = inlineBoxGeometry.marginStart()
    if marginStart < 0 {
      // Negative margin-start pulls the content to the logical left direction.
      logicalLeft += marginStart.float()
      logicalWidth -= marginStart.float()
    }
    logicalWidth -= borderAndPaddingEndForDecorationClone

    let mayPullNonInlineBoxContentToLogicalLeft = style.letterSpacing() < 0
    if mayPullNonInlineBoxContentToLogicalLeft {
      inlineBoxLogicalLeftStack.append(logicalLeft)
    }

    hasRubyContent = hasRubyContent || inlineItem.layoutBox.isRubyBase()
    runs.append(
      Run(
        inlineItem: inlineItem, style: style, logicalLeft: logicalLeft, logicalWidth: logicalWidth))
  }

  private mutating func appendInlineBoxEnd(
    inlineItem: InlineItemWrapper, style: RenderStyleWrapper, logicalWidth: InlineLayoutUnit
  ) {
    if formattingContext().geometryForBox(layoutBox: inlineItem.layoutBox)
      .marginBorderAndPaddingEnd().bool()
    {
      hangingContent.resetTrailingContent()
    }
    // Prevent trailing letter-spacing from spilling out of the inline box.
    // https://drafts.csswg.org/css-text-3/#letter-spacing-property See example 21.
    removeTrailingLetterSpacingForLine()
    contentLogicalWidth -= removeBorderAndPaddingEndForInlineBoxDecorationClone(
      inlineBoxEndItem: inlineItem)
    var logicalLeft = lastRunLogicalRight()
    let mayPullNonInlineBoxContentToLogicalLeft = style.letterSpacing() < 0
    if mayPullNonInlineBoxContentToLogicalLeft {
      // Do not let negative spacing pull content to the left of the inline box logical left.
      // e.g. <span style="border-left: solid red; letter-spacing: -200px;">content</span>This should not be to the left of the red border)
      logicalLeft = max(
        logicalLeft, inlineBoxLogicalLeftStack.isEmpty ? 0 : inlineBoxLogicalLeftStack.removeLast())
    }
    runs.append(
      Run(
        inlineItem: inlineItem, style: style, logicalLeft: logicalLeft, logicalWidth: logicalWidth))
    // Do not let negative margin make the content shorter than it already is.
    contentLogicalWidth = max(contentLogicalWidth, logicalLeft + logicalWidth)
  }

  // This is really just a placeholder to mark the end of the inline box </span>.
  mutating func removeTrailingLetterSpacingForLine() {
    if !trimmableTrailingContent.isTrailingRunPartiallyTrimmable() {
      return
    }
    contentLogicalWidth -= trimmableTrailingContent.removePartiallyTrimmableContent()
  }

  private mutating func appendLineBreak(inlineItem: InlineItemWrapper, style: RenderStyleWrapper) {
    trailingSoftHyphenWidth = nil
    if inlineItem.isHardLineBreak() {
      nonSpanningInlineLevelBoxCount += 1
      runs.append(
        Run(zeroWidthInlineItem: inlineItem, style: style, logicalLeft: lastRunLogicalRight()))
      return
    }
    // Soft line breaks (preserved new line characters) require inline text boxes for compatibility reasons.
    runs.append(
      Run(
        softLineBreakItem: inlineItem as! InlineSoftLineBreakItemWrapper, style: inlineItem.style(),
        logicalLeft: lastRunLogicalRight()))
  }

  private mutating func appendWordBreakOpportunity(
    inlineItem: InlineItemWrapper, style: RenderStyleWrapper
  ) {
    runs.append(
      Run(zeroWidthInlineItem: inlineItem, style: style, logicalLeft: lastRunLogicalRight()))
  }

  private mutating func appendOpaqueBox(inlineItem: InlineItemWrapper, style: RenderStyleWrapper) {
    runs.append(
      Run(zeroWidthInlineItem: inlineItem, style: style, logicalLeft: lastRunLogicalRight()))
  }

  private mutating func addBorderAndPaddingEndForInlineBoxDecorationClone(
    inlineBoxStartItem: InlineItemWrapper
  )
    -> InlineLayoutUnit
  {
    assert(inlineBoxStartItem.isInlineBoxStart())
    if inlineBoxStartItem.style().boxDecorationBreak() != .Clone {
      return InlineLayoutUnit()
    }
    // https://drafts.csswg.org/css-break/#break-decoration
    let inlineBoxGeometry = formattingContext().geometryForBox(
      layoutBox: inlineBoxStartItem.layoutBox)
    let borderAndPaddingEnd = inlineBoxGeometry.borderEnd() + inlineBoxGeometry.paddingEnd()
    let key = CPtrToInt(inlineBoxStartItem.layoutBox.p)
    if !inlineBoxListWithClonedDecorationEnd.keys.contains(key) {
      inlineBoxListWithClonedDecorationEnd[key] =
        borderAndPaddingEnd.float()
    }
    clonedEndDecorationWidthForInlineBoxRuns += borderAndPaddingEnd.float()
    return borderAndPaddingEnd.float()
  }

  private mutating func removeBorderAndPaddingEndForInlineBoxDecorationClone(
    inlineBoxEndItem: InlineItemWrapper
  )
    -> InlineLayoutUnit
  {
    assert(inlineBoxEndItem.isInlineBoxEnd())
    let borderAndPaddingEnd =
      inlineBoxListWithClonedDecorationEnd.removeValue(
        forKey: CPtrToInt(inlineBoxEndItem.layoutBox.p)) ?? InlineLayoutUnit()
    if borderAndPaddingEnd.isInfinite {
      return InlineLayoutUnit()
    }
    // This inline box end now contributes to the line content width in the regular way, so let's remove
    // it from the side structure where we keep track of the "not-yet placed but space taking" decorations.
    clonedEndDecorationWidthForInlineBoxRuns -= borderAndPaddingEnd
    return borderAndPaddingEnd
  }

  private mutating func resetTrailingContent() {
    trimmableTrailingContent.reset()
    hangingContent.resetTrailingContent()
    trailingSoftHyphenWidth = nil
  }

  private func lineHasVisuallyNonEmptyContent() -> Bool {
    let formattingContext = formattingContext()
    for run in runs.reversed() {
      if Run.isContentfulOrHasDecoration(run: run, formattingContext: formattingContext) {
        return true
      }
    }
    return false
  }

  func formattingContext() -> InlineFormattingContext {
    return inlineFormattingContext
  }

  struct TrimmableTrailingContent {
    init(runs: RunList) {
      self.runs = runs
    }

    mutating func addFullyTrimmableContent(
      runIndex: UInt64, trimmableContentOffset: InlineLayoutUnit, trimmableWidth: InlineLayoutUnit
    ) {
      // Any subsequent trimmable whitespace should collapse to zero advanced width and ignored at ::appendTextContent().
      assert(!hasFullyTrimmableContent)
      fullyTrimmableWidth = trimmableContentOffset + trimmableWidth
      self.trimmableContentOffset = trimmableContentOffset
      // Note that just because the trimmable width is 0 (font-size: 0px), it does not mean we don't have a trimmable trailing content.
      hasFullyTrimmableContent = true
      firstTrimmableRunIndex = firstTrimmableRunIndex ?? runIndex
    }

    mutating func remove() -> InlineLayoutUnit {
      // Remove trimmable trailing content and move all the subsequent trailing runs.
      // <span> </span><span></span>
      // [trailing whitespace][inline box end][inline box start][inline box end]
      // Trim the whitespace run and move the trailing inline box runs to the logical left.
      assert(!isEmpty())
      let trimmableRun = runs[Int(firstTrimmableRunIndex!)]
      assert(trimmableRun.isText())

      var trimmedWidth = trimmableContentOffset
      if hasFullyTrimmableContent {
        trimmedWidth += trimmableRun.removeTrailingWhitespace()
      }
      if partiallyTrimmableWidth != 0 {
        trimmedWidth += trimmableRun.removeTrailingLetterSpacing()
      }

      // When the trimmable run is followed by some non-content runs, we need to adjust their horizontal positions.
      // e.g. <div>text is followed by trimmable content    <span> </span></div>
      // When the [text...] run is trimmed (trailing whitespace is removed), both "<span>" and "</span>" runs
      // need to be moved horizontally to catch up with the [text...] run. Note that the whitespace inside the <span> does
      // not produce a run since in ::appendText() we see it as a fully trimmable run.
      for index in Int(firstTrimmableRunIndex! + 1)..<runs.count {
        let run = runs[Int(index)]
        assert(
          run.isWordBreakOpportunity() || run.isLineSpanningInlineBoxStart()
            || run.isInlineBoxStart() || run.isInlineBoxEnd() || run.isLineBreak() || run.isOpaque()
        )
        run.moveHorizontally(offset: -trimmedWidth)
      }
      if trimmableRun.textContent!.length == 0 {
        // This trimmable run is fully collapsed now (e.g. <div><img>    <span></span></div>).
        // We don't need to keep it around anymore.
        runs.remove(at: Int(firstTrimmableRunIndex!))
      }
      reset()
      return trimmedWidth
    }

    mutating func removePartiallyTrimmableContent() -> InlineLayoutUnit {
      // Partially trimmable content is always gated by a fully trimmable content.
      // We can't just trim spacing in the middle.
      assert(fullyTrimmableWidth == 0)
      return remove()
    }

    func width() -> InlineLayoutUnit {
      return fullyTrimmableWidth + partiallyTrimmableWidth
    }

    func isEmpty() -> Bool { return firstTrimmableRunIndex == nil }

    func isTrailingRunFullyTrimmable() -> Bool { return hasFullyTrimmableContent }

    func isTrailingRunPartiallyTrimmable() -> Bool {
      return partiallyTrimmableWidth != 0
    }

    mutating func reset() {
      hasFullyTrimmableContent = false
      firstTrimmableRunIndex = nil
      fullyTrimmableWidth = InlineLayoutUnit()
      partiallyTrimmableWidth = InlineLayoutUnit()
      trimmableContentOffset = InlineLayoutUnit()
    }

    var runs: RunList
    var firstTrimmableRunIndex: UInt64? = nil
    var hasFullyTrimmableContent = false
    var trimmableContentOffset = InlineLayoutUnit()
    var fullyTrimmableWidth = InlineLayoutUnit()
    var partiallyTrimmableWidth = InlineLayoutUnit()
  }

  struct HangingContent {
    mutating func setLeadingPunctuation(logicalWidth: InlineLayoutUnit) {
      leadingPunctuationWidth = logicalWidth
    }

    mutating func setTrailingPunctuation(logicalWidth: InlineLayoutUnit) {
      trailingContent = TrailingContent(
        type: .Punctuation, isConditional: .No, length: 1, width: logicalWidth)
    }

    mutating func setTrailingStopOrComma(logicalWidth: InlineLayoutUnit, isConditional: Bool) {
      trailingContent = TrailingContent(
        type: .StopOrComma, isConditional: isConditional ? .Yes : .No, length: 1,
        width: logicalWidth)
    }

    mutating func setTrailingWhitespace(length: UInt64, logicalWidth: InlineLayoutUnit) {
      // If white-space is set to pre-wrap, the UA must (unconditionally) hang this sequence, unless the sequence is followed
      // by a forced line break, in which case it must conditionally hang the sequence is instead.
      // Note that end of last line in a paragraph is considered a forced break.
      trailingContent = TrailingContent(
        type: .Whitespace, isConditional: .WhenFollowedByForcedLineBreak, length: length,
        width: logicalWidth)
    }

    mutating func resetTrailingContent() {
      trailingContent = nil
    }

    func trailingWidth() -> InlineLayoutUnit {
      if let trailingContent = trailingContent {
        return trailingContent.width
      }
      return InlineLayoutUnit()
    }

    func trailingWhitespaceLength() -> UInt64 {
      if let trailingContent = trailingContent {
        return trailingContent.type == .Whitespace ? trailingContent.length : 0
      }
      return 0
    }

    func isTrailingContentPunctuation() -> Bool {
      if let trailingContent = trailingContent {
        return trailingContent.type == .Punctuation
      }
      return false
    }

    func isTrailingContentConditional() -> Bool {
      if let trailingContent = trailingContent {
        return trailingContent.isConditional == .Yes
      }
      return false
    }

    func isTrailingContentConditionalWhenFollowedByForcedLineBreak() -> Bool {
      if let trailingContent = trailingContent {
        return trailingContent.isConditional == .WhenFollowedByForcedLineBreak
      }
      return false
    }

    var leadingPunctuationWidth = InlineLayoutUnit()
    // There's either a whitespace or punctuation trailing content.
    struct TrailingContent {
      enum `Type`: UInt8 {
        case Whitespace
        case StopOrComma
        case Punctuation
      }
      var type: `Type` = .Whitespace

      enum IsConditional: UInt8 {
        case Yes
        case No
        case WhenFollowedByForcedLineBreak
      }
      var isConditional: IsConditional = .No
      var length: UInt64 = 0
      var width = InlineLayoutUnit()
    }
    var trailingContent: TrailingContent? = nil
  }

  let inlineFormattingContext: InlineFormattingContext
  var runs: RunList
  var trimmableTrailingContent: TrimmableTrailingContent
  var hangingContent = HangingContent()
  var contentLogicalWidth = InlineLayoutUnit()
  var nonSpanningInlineLevelBoxCount: UInt64 = 0
  var trailingSoftHyphenWidth: InlineLayoutUnit? = nil
  var inlineBoxListWithClonedDecorationEnd = InlineBoxListWithClonedDecorationEnd()
  var clonedEndDecorationWidthForInlineBoxRuns = InlineLayoutUnit()
  var hasNonDefaultBidiLevelRun = false
  var isFirstFormattedLine = false
  var hasRubyContent = false
  var rubyAlignContentRightOffset = InlineLayoutUnit()
  var inlineBoxLogicalLeftStack: [InlineLayoutUnit] = []
}
