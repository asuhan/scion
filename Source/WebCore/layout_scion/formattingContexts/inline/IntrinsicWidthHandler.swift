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

private func isBoxEligibleForNonLineBuilderMinimumWidth(_ box: ElementBoxWrapper) -> Bool {
  // Note that hanging trailing content needs line builder (combination of wrapping is allowed but whitespace is preserved).
  let style = box.style
  return TextUtil.isWrappingAllowed(style: style)
    && (style.lineBreak() == .Anywhere || style.wordBreak() == .BreakAll
      || style.wordBreak() == .BreakWord)
    && style.whiteSpaceCollapse() != .Preserve
}

private func isSubtreeEligibleForNonLineBuilderMinimumWidth(_ root: ElementBoxWrapper) -> Bool {
  var isSimpleBreakableContent = isBoxEligibleForNonLineBuilderMinimumWidth(root)
  var child = root.firstChild()
  while child != nil && isSimpleBreakableContent {
    if child!.isFloatingPositioned() {
      isSimpleBreakableContent = false
      break
    }
    let isInlineBoxWithInlineContent =
      child!.isInlineBox() && !child!.isInlineTextBox() && !child!.isLineBreakBox()
    if isInlineBoxWithInlineContent {
      isSimpleBreakableContent = isSubtreeEligibleForNonLineBuilderMinimumWidth(
        child! as! ElementBoxWrapper)
    }
    child = child!.nextSibling()
  }
  return isSimpleBreakableContent
}

private func isContentEligibleForNonLineBuilderMinimumWidth(
  _ rootBox: ElementBoxWrapper, _ mayUseSimplifiedTextOnlyInlineLayout: Bool
) -> Bool {
  return
    (mayUseSimplifiedTextOnlyInlineLayout && isBoxEligibleForNonLineBuilderMinimumWidth(rootBox))
    || (!mayUseSimplifiedTextOnlyInlineLayout
      && isSubtreeEligibleForNonLineBuilderMinimumWidth(rootBox))
}

struct IntrinsicWidthHandler: ~Copyable {
  init(
    _ inlineFormattingContext: InlineFormattingContext,
    _ inlineItems: InlineContentCache.InlineItems
  ) {
    m_inlineFormattingContext = inlineFormattingContext
    m_inlineItems = inlineItems
    m_inlineItemRange = InlineItemRange(
      start: InlineItemPosition(index: 0),
      end: InlineItemPosition(index: UInt64(inlineItems.content().count)))
    m_mayUseSimplifiedTextOnlyInlineLayoutInRange =
      TextOnlySimpleLineBuilder.isEligibleForSimplifiedInlineLayoutByStyle(
        style: formattingContextRoot().style)
    if !m_mayUseSimplifiedTextOnlyInlineLayoutInRange {
      return
    }

    m_mayUseSimplifiedTextOnlyInlineLayoutInRange =
      inlineItems.hasTextAndLineBreakOnlyContent() && !inlineItems.requiresVisualReordering()
    if !m_mayUseSimplifiedTextOnlyInlineLayoutInRange {
      return
    }
    // Non-bidi text only content maybe nested inside inline boxes e.g. <div>simple text</div>, <div><span>simple text inside inline box</span></div> or
    // <div>some text<span>and some more inside inline box</span></div>
    let inlineBoxCount = inlineItems.inlineBoxCount()
    if inlineBoxCount == 0 {
      return
    }

    let inlineItemList = inlineItems.content()
    let inlineBoxStartAndEndInlineItemsCount = 2 * inlineBoxCount
    assert(inlineBoxStartAndEndInlineItemsCount <= inlineItemList.count)

    m_mayUseSimplifiedTextOnlyInlineLayoutInRange =
      inlineBoxStartAndEndInlineItemsCount < inlineItemList.count
    if !m_mayUseSimplifiedTextOnlyInlineLayoutInRange {
      return
    }

    for index in 0..<Int(inlineBoxCount) {
      let inlineItem = inlineItemList[index]
      let isNestingInlineBox =
        inlineItem.isInlineBoxStart()
        && inlineItemList[Int(inlineItems.size()) - 1 - index].isInlineBoxEnd()
      m_mayUseSimplifiedTextOnlyInlineLayoutInRange =
        isNestingInlineBox
        && !formattingContext().geometryForBox(layoutBox: inlineItem.layoutBox)
          .horizontalMarginBorderAndPadding().bool()
        && TextOnlySimpleLineBuilder.isEligibleForSimplifiedInlineLayoutByStyle(
          style: inlineItem.style())
      if !m_mayUseSimplifiedTextOnlyInlineLayoutInRange {
        return
      }
    }
    m_inlineItemRange = InlineItemRange(
      start: InlineItemPosition(index: inlineBoxCount),
      end: InlineItemPosition(index: UInt64(inlineItemList.count) - inlineBoxCount))
  }

  mutating func minimumContentSize() -> InlineLayoutUnit {
    var minimumContentSize = InlineLayoutUnit()

    if isContentEligibleForNonLineBuilderMinimumWidth(
      formattingContextRoot(), m_mayUseSimplifiedTextOnlyInlineLayoutInRange)
    {
      minimumContentSize = simplifiedMinimumWidth(formattingContextRoot())
    } else if m_mayUseSimplifiedTextOnlyInlineLayoutInRange {
      let simplifiedLineBuilder = TextOnlySimpleLineBuilder(
        inlineFormattingContext: formattingContext(), rootBox: lineBuilderRoot(),
        rootHorizontalConstraints: HorizontalConstraints(), inlineItemList: inlineItemList())
      minimumContentSize = computedIntrinsicWidthForConstraint(.Minimum, simplifiedLineBuilder, .No)
    } else {
      let lineBuilder = LineBuilder(
        inlineFormattingContext: formattingContext(),
        rootHorizontalConstraints: HorizontalConstraints(), inlineItemList: inlineItemList())
      minimumContentSize = computedIntrinsicWidthForConstraint(.Minimum, lineBuilder, .No)
    }

    return minimumContentSize
  }

  func maximumIntrinsicWidthLineContent() -> LineLayoutResult? {
    return m_maximumIntrinsicWidthResultForSingleLine
  }

  private enum MayCacheLayoutResult {
    case No
    case Yes
  }

  private mutating func computedIntrinsicWidthForConstraint(
    _ intrinsicWidthMode: IntrinsicWidthMode, _ lineBuilder: AbstractLineBuilder,
    _ mayCacheLayoutResultIn: MayCacheLayoutResult = .No
  ) -> InlineLayoutUnit {
    var horizontalConstraints = HorizontalConstraints()
    if intrinsicWidthMode == .Maximum {
      horizontalConstraints.logicalWidth = LayoutUnit(value: maxInlineLayoutUnit())
    }
    var layoutRange = m_inlineItemRange
    if layoutRange.isEmpty() {
      return InlineLayoutUnit()
    }

    var maximumContentWidth = InlineLayoutUnit()
    struct ContentWidthBetweenLineBreaks {
      var maximum = InlineLayoutUnit()
      var current = InlineLayoutUnit()
    }
    var contentWidthBetweenLineBreaks = ContentWidthBetweenLineBreaks()
    var previousLineEnd: InlineItemPosition? = nil
    var previousLine: PreviousLine? = nil
    var lineIndex = UInt64(0)
    lineBuilder.setIntrinsicWidthMode(intrinsicWidthMode)

    var mayCacheLayoutResult = mayCacheLayoutResultIn
    while true {
      let lineLayoutResult = lineBuilder.layoutInlineContent(
        lineInput: LineInput(
          needsLayoutRange: layoutRange,
          initialLogicalRect: InlineRect(
            top: 0, left: 0, width: horizontalConstraints.logicalWidth.float(), height: 0)),
        previousLine: previousLine)
      let floatContentWidth = { () in
        var leftWidth = LayoutUnit()
        var rightWidth = LayoutUnit()
        for floatItem in lineLayoutResult.floatContent.placedFloats {
          mayCacheLayoutResult = .No
          let marginBoxRect = BoxGeometry.marginBoxRect(box: floatItem.boxGeometry())
          if floatItem.isLeftPositioned() {
            leftWidth = max(leftWidth, marginBoxRect.right())
          } else {
            rightWidth = max(rightWidth, horizontalConstraints.logicalWidth - marginBoxRect.left())
          }
        }
        return (leftWidth + rightWidth).float()
      }

      let lineEndsWithLineBreak =
        !lineLayoutResult.inlineContent.isEmpty
        && lineLayoutResult.inlineContent.last!.isLineBreak()
      let lineContentLogicalWidth =
        lineLayoutResult.lineGeometry.logicalTopLeft.x
        + lineLayoutResult.contentGeometry.logicalWidth + floatContentWidth()
      maximumContentWidth = max(maximumContentWidth, lineContentLogicalWidth)
      contentWidthBetweenLineBreaks.current +=
        (lineContentLogicalWidth + lineLayoutResult.hangingContent.logicalWidth)
      if lineEndsWithLineBreak {
        contentWidthBetweenLineBreaks = ContentWidthBetweenLineBreaks(
          maximum: max(
            contentWidthBetweenLineBreaks.maximum, contentWidthBetweenLineBreaks.current),
          current: 0)
      }

      layoutRange.start = InlineFormattingUtils.leadingInlineItemPositionForNextLine(
        lineContentEnd: lineLayoutResult.inlineItemRange.end,
        previousLineContentEnd: previousLineEnd,
        lineHasIntrusiveOrNewlyPlacedFloat: !lineLayoutResult.floatContent.hasIntrusiveFloat
          .isEmpty
          || !lineLayoutResult.floatContent.placedFloats.isEmpty, layoutRangeEnd: layoutRange.end)
      if layoutRange.isEmpty() {
        cacheLineBreakingResultForSubsequentLayoutIfApplicable(
          mayCacheLayoutResult, lineLayoutResult)
        break
      }

      // Support single line only.
      mayCacheLayoutResult = .No
      previousLineEnd = layoutRange.start
      let hasSeenInlineContent =
        previousLine != nil
        ? previousLine!.hasInlineContent || !lineLayoutResult.inlineContent.isEmpty
        : !lineLayoutResult.inlineContent.isEmpty
      previousLine = PreviousLine(
        lineIndex: lineIndex,
        trailingOverflowingContentWidth: lineLayoutResult.contentGeometry
          .trailingOverflowingContentWidth,
        endsWithLineBreak: lineEndsWithLineBreak, hasInlineContent: hasSeenInlineContent,
        inlineBaseDirection: .LTR,
        suspendedFloats: lineLayoutResult.floatContent.suspendedFloats)
      lineIndex += 1
    }
    m_maximumContentWidthBetweenLineBreaks = max(
      contentWidthBetweenLineBreaks.current, contentWidthBetweenLineBreaks.maximum)
    return maximumContentWidth
  }

  private mutating func cacheLineBreakingResultForSubsequentLayoutIfApplicable(
    _ mayCacheLayoutResult: MayCacheLayoutResult, _ lineLayoutResult: LineLayoutResult
  ) {
    m_maximumIntrinsicWidthResultForSingleLine = nil
    if mayCacheLayoutResult == .No {
      return
    }
    m_maximumIntrinsicWidthResultForSingleLine = lineLayoutResult
  }

  private func simplifiedMinimumWidth(_ root: ElementBoxWrapper) -> InlineLayoutUnit {
    var maximumWidth = InlineLayoutUnit()

    var child = root.firstChild()
    while child != nil {
      if let inlineTextBox = child! as? InlineTextBoxWrapper {
        assert(inlineTextBox.style.whiteSpaceCollapse() != .Preserve)
        let fontCascade = inlineTextBox.style.fontCascade()
        let contentLength = UInt64(inlineTextBox.content.length())
        var index: UInt64 = 0
        let isTreatedAsSpaceCharacter = { (character: UChar) in
          return character == CharacterNames.Unicode.space
            || character == CharacterNames.Unicode.newlineCharacter
            || character == CharacterNames.Unicode.tabCharacter
        }
        while index < contentLength {
          let characterLength = TextUtil.firstUserPerceivedCharacterLength(
            inlineTextBox: inlineTextBox, startPosition: index,
            length: UInt64(contentLength - index))
          assert(characterLength != 0)
          let isCollapsedWhitespace =
            characterLength == 1
            && isTreatedAsSpaceCharacter(inlineTextBox.content[UInt32(index)])
          if !isCollapsedWhitespace {
            maximumWidth = max(
              maximumWidth,
              TextUtil.width(
                inlineTextBox: inlineTextBox, fontCascade: fontCascade, from: UInt32(index),
                toIn: UInt32(index + characterLength), contentLogicalLeft: InlineLayoutUnit(),
                useTrailingWhitespaceMeasuringOptimization: .No)
            )
          }
          index += characterLength
        }
        child = child!.nextInFlowSibling()
        continue
      }
      if child!.isAtomicInlineBox() || child!.isReplacedBox() {
        maximumWidth = max(
          maximumWidth,
          formattingContext().geometryForBox(layoutBox: child!).marginBoxWidth().float())
        child = child!.nextInFlowSibling()
        continue
      }
      let isInlineBoxWithInlineContent = child!.isInlineBox() && !child!.isLineBreakBox()
      if isInlineBoxWithInlineContent {
        let boxGeometry = formattingContext().geometryForBox(layoutBox: child!)
        maximumWidth = max(
          maximumWidth, boxGeometry.marginBorderAndPaddingStart().float(),
          boxGeometry.marginBorderAndPaddingEnd().float())
        maximumWidth = max(maximumWidth, simplifiedMinimumWidth(child as! ElementBoxWrapper))
        child = child!.nextInFlowSibling()
        continue
      }
      child = child!.nextInFlowSibling()
    }
    return maximumWidth
  }

  private func formattingContext() -> InlineFormattingContext { return m_inlineFormattingContext }

  private func formattingContextRoot() -> ElementBoxWrapper {
    return m_inlineFormattingContext.root()
  }

  private func lineBuilderRoot() -> ElementBoxWrapper {
    if m_inlineItemRange.startIndex() == 0 {
      return formattingContextRoot()
    }

    let rootBoxIndex = m_inlineItemRange.startIndex() - 1
    let inlineItems = inlineItemList()
    if rootBoxIndex >= inlineItems.count {
      fatalError("Not reached")
    }

    if let inlineBox = inlineItems[Int(rootBoxIndex)].layoutBox as? ElementBoxWrapper,
      inlineBox.isInlineBox()
    {
      // We are running a range based line building where we only need to layout the inner text content (e.g. <span>inner text content</span>)
      return inlineBox
    }

    fatalError("Not reached")
  }

  private func inlineItemList() -> InlineItemList { return m_inlineItems.content() }

  private let m_inlineFormattingContext: InlineFormattingContext
  private let m_inlineItems: InlineContentCache.InlineItems
  private var m_inlineItemRange: InlineItemRange
  private var m_mayUseSimplifiedTextOnlyInlineLayoutInRange: Bool = false

  private var m_maximumContentWidthBetweenLineBreaks: InlineLayoutUnit? = nil
  private var m_maximumIntrinsicWidthResultForSingleLine: LineLayoutResult? = nil
}
