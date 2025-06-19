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

struct InlineLayoutResult {
  var displayContent = InlineDisplay.Content()
  enum Range: UInt8 {
    case Full  // Display content represents the complete inline content -result of full layout
    case FullFromDamage  // Display content represents part of the inline content starting from damaged line until the end of inline content -result of partial layout with continuous damage all the way to the end of the inline content
    case PartialFromDamage  // Display content represents part of the inline content starting from damaged line until damage stops -result of partial layout with damage that does not cover the entire inline content
  }
  var range = Range.Full
}

internal func partialRangeForDamage(inlineItemList: InlineItemList, lineDamage: InlineDamageWrapper)
  -> InlineItemRange?
{
  let layoutStartPosition = lineDamage.layoutStartPosition()!.inlineItemPosition
  if layoutStartPosition.index >= inlineItemList.count {
    fatalError("Not reached")
  }
  let damagedInlineTextItem =
    inlineItemList[Int(layoutStartPosition.index)] as? InlineTextItemWrapper
  if layoutStartPosition.offset != 0
    && (damagedInlineTextItem == nil || layoutStartPosition.offset >= damagedInlineTextItem!.length)
  {
    fatalError("Not reached")
  }
  return InlineItemRange(
    start: layoutStartPosition,
    end: InlineItemPosition(index: UInt64(inlineItemList.count), offset: UInt64(0)))
}

internal func isEmptyInlineContent(inlineItemList: InlineItemList) -> Bool {
  // Very common, pseudo before/after empty content.
  if inlineItemList.count != 1 {
    return false
  }

  let inlineTextItem = inlineItemList[0] as? InlineTextItemWrapper
  return inlineTextItem != nil && inlineTextItem!.length == 0
}

internal func mayExitFromPartialLayout(
  lineDamage: InlineDamageWrapper, lineIndex: UInt64, newContent: InlineDisplay.Boxes
) -> Bool {
  if lineDamage.layoutStartPosition()!.lineIndex == lineIndex {
    // Never stop at the damaged line. Adding trailing overflowing content could easily produce the
    // same set of display boxes for the first damaged line.
    return false
  }
  if let trailingContentFromPreviousLayout = lineDamage.trailingContentForLine(lineIndex: lineIndex)
  {
    return !newContent.isEmpty
      && ObjectIdentifier(trailingContentFromPreviousLayout) == ObjectIdentifier(newContent.last!)
  }
  return false
}

internal func computeNeedsLayoutRange(
  inlineItemList: InlineItemList, lineDamage: inout InlineDamageWrapper?
)
  -> InlineItemRange
{
  if !InlineInvalidation.mayOnlyNeedPartialLayout(inlineDamage: lineDamage) {
    return InlineItemRange(
      start: InlineItemPosition(),
      end: InlineItemPosition(index: UInt64(inlineItemList.count), offset: 0))
  }
  if let partialRange = partialRangeForDamage(
    inlineItemList: inlineItemList, lineDamage: lineDamage!)
  {
    return partialRange
  }
  // We should be able to produce partial range for partial layout.
  fatalError("Not reached")
}

internal func computePreviousLine(
  needsLayoutRange: InlineItemRange, lineDamage: InlineDamageWrapper?
) -> PreviousLine? {
  if !needsLayoutRange.start.bool() {
    return nil
  }
  if lineDamage == nil || lineDamage!.layoutStartPosition() == nil {
    fatalError("Not reached")
  }
  let lastLineIndex = lineDamage!.layoutStartPosition()!.lineIndex - 1
  // FIXME: We should be able to extract the last line information and provide it to layout as "previous line" (ends in line break and inline direction).
  return PreviousLine(
    lineIndex: lastLineIndex, trailingOverflowingContentWidth: nil, endsWithLineBreak: false,
    hasInlineContent: true, inlineBaseDirection: TextDirection.LTR, suspendedFloats: [])
}

// This class implements the layout logic for inline formatting context.
// https://www.w3.org/TR/CSS22/visuren.html#inline-formatting
class InlineFormattingContext {
  init(
    rootBlockContainer: ElementBoxWrapper, globalLayoutState: LayoutStateWrapper,
    parentBlockLayoutState: BlockLayoutState
  ) {
    self.rootBlockContainer = rootBlockContainer
    self.globalLayoutState = globalLayoutState
    self.floatingContext = FloatingContext(
      formattingContextRoot: rootBlockContainer, layoutState: globalLayoutState,
      placedFloats: parentBlockLayoutState.placedFloats)
    self.inlineFormattingUtils = InlineFormattingUtils(inlineFormattingContext: self)
    self.inlineQuirks = InlineQuirks(inlineFormattingContext: self)
    self.integrationUtils = IntegrationUtils(globalLayoutState: globalLayoutState)
    self.inlineContentCache = self.globalLayoutState.inlineContentCache(
      formattingContextRoot: rootBlockContainer)
    self.inlineLayoutState = InlineLayoutState(parentBlockLayoutState: parentBlockLayoutState)
    initializeInlineLayoutState(globalLayoutState: globalLayoutState)
  }

  func layout(
    constraints: ConstraintsForInlineContent, lineDamage: inout InlineDamageWrapper?
  )
    -> InlineLayoutResult
  {
    rebuildInlineItemListIfNeeded(lineDamage: lineDamage)

    if formattingUtils().shouldDiscardRemainingContentInBlockDirection(
      numberOfLinesWithInlineContent: 0)
    {
      // This inline content may be completely collapsed (i.e. after clamped block container)
      resetBoxGeometriesForDiscardedContent(
        discardedRange: InlineItemRange(
          start: InlineItemPosition(),
          end: InlineItemPosition(
            index: UInt64(inlineContentCache.inlineItems.content().count),
            offset: 0)
        ),
        suspendedFloats: LineLayoutResult.SuspendedFloatList())
      return InlineLayoutResult()
    }

    if !root().hasInFlowChild() && !root().hasOutOfFlowChild() {
      // Float only content does not support partial layout.
      assert(!InlineInvalidation.mayOnlyNeedPartialLayout(inlineDamage: lineDamage))
      layoutFloatContentOnly(constraints: constraints)
      return InlineLayoutResult(displayContent: InlineDisplay.Content(), range: .Full)
    }

    let inlineItemList = inlineContentCache.inlineItems.content()
    let needsLayoutRange = computeNeedsLayoutRange(
      inlineItemList: inlineItemList, lineDamage: &lineDamage)

    if needsLayoutRange.isEmpty() {
      fatalError("Not reached")
    }

    let textWrapStyle = root().style.textWrapStyle()
    if root().style.textWrapMode() == .Wrap
      && (textWrapStyle == .Balance || textWrapStyle == .Pretty)
    {
      let constrainer = InlineContentConstrainer(
        inlineFormattingContext: self, inlineItemList: inlineItemList,
        horizontalConstraints: constraints.horizontal)
      if let constrainedLineWidths = constrainer.computeParagraphLevelConstraints(
        wrapStyle: textWrapStyle)
      {
        layoutState().setAvailableLineWidthOverride(
          availableLineWidthOverride: AvailableLineWidthOverride(
            individualLineWidthOverrides: constrainedLineWidths))
      }
    }

    if TextOnlySimpleLineBuilder.isEligibleForSimplifiedTextOnlyInlineLayoutByContent(
      inlineItems: inlineContentCache.inlineItems, placedFloats: layoutState().placedFloats())
      && TextOnlySimpleLineBuilder.isEligibleForSimplifiedInlineLayoutByStyle(style: root().style)
    {
      let simplifiedLineBuilder = TextOnlySimpleLineBuilder(
        inlineFormattingContext: self, rootBox: root(),
        rootHorizontalConstraints: constraints.horizontal, inlineItemList: inlineItemList)
      return lineLayout(
        lineBuilder: simplifiedLineBuilder, inlineItemList: inlineItemList,
        needsLayoutRange: needsLayoutRange,
        previousLine: computePreviousLine(
          needsLayoutRange: needsLayoutRange, lineDamage: lineDamage), constraints: constraints,
        lineDamage: lineDamage)
    }

    if RangeBasedLineBuilder.isEligibleForRangeInlineLayout(
      inlineFormattingContext: self, inlineItems: inlineContentCache.inlineItems,
      placedFloats: layoutState().placedFloats())
    {
      let rangeBasedLineBuilder = RangeBasedLineBuilder(
        inlineFormattingContext: self,
        rootHorizontalConstraints: constraints.horizontal, inlineItemList: inlineItemList)
      return lineLayout(
        lineBuilder: rangeBasedLineBuilder, inlineItemList: inlineItemList,
        needsLayoutRange: needsLayoutRange,
        previousLine: computePreviousLine(
          needsLayoutRange: needsLayoutRange, lineDamage: lineDamage), constraints: constraints,
        lineDamage: lineDamage)
    }
    let lineBuilder = LineBuilder(
      inlineFormattingContext: self,
      rootHorizontalConstraints: constraints.horizontal, inlineItemList: inlineItemList)
    return lineLayout(
      lineBuilder: lineBuilder, inlineItemList: inlineItemList,
      needsLayoutRange: needsLayoutRange,
      previousLine: computePreviousLine(
        needsLayoutRange: needsLayoutRange, lineDamage: lineDamage), constraints: constraints,
      lineDamage: lineDamage)
  }

  func minimumMaximumContentSize(lineDamage: InlineDamageWrapper? = nil) -> (LayoutUnit, LayoutUnit)
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func root() -> ElementBoxWrapper {
    return rootBlockContainer
  }

  func formattingUtils() -> InlineFormattingUtils {
    return inlineFormattingUtils!
  }

  func quirks() -> InlineQuirks {
    return inlineQuirks!
  }

  func layoutState() -> InlineLayoutState {
    return inlineLayoutState!
  }

  enum EscapeReason {
    case InkOverflowNeedsInitialContiningBlockForStrokeWidth
  }

  func geometryForBox(layoutBox: BoxWrapper, escapeReason: EscapeReason? = nil) -> BoxGeometry {
    return globalLayoutState.geometryForBox(layoutBox: layoutBox)
  }

  func lineLayout(
    lineBuilder: AbstractLineBuilder, inlineItemList: InlineItemList,
    needsLayoutRange: InlineItemRange, previousLine: PreviousLine?,
    constraints: ConstraintsForInlineContent, lineDamage: InlineDamageWrapper? = nil
  ) -> InlineLayoutResult {
    assert(!needsLayoutRange.isEmpty())
    var previousLine_ = previousLine

    let isPartialLayout = InlineInvalidation.mayOnlyNeedPartialLayout(inlineDamage: lineDamage)
    if !isPartialLayout {
      assert(previousLine_ == nil)
      var layoutResult = InlineLayoutResult(displayContent: InlineDisplay.Content(), range: .Full)
      if createDisplayContentForLineFromCachedContent(
        constraints: constraints, layoutResult: &layoutResult)
      {
        return layoutResult
      }
      if isEmptyInlineContent(inlineItemList: inlineItemList) {
        createDisplayContentForEmptyInlineContent(
          constraints: constraints, layoutResult: &layoutResult)
        return layoutResult
      }
    }

    var layoutResult = InlineLayoutResult()
    if !needsLayoutRange.start.bool() {
      layoutResult.displayContent.boxes.reserveCapacity(inlineItemList.count)
    }

    var lineLogicalTop: InlineLayoutUnit = constraints.logicalTop.float()
    var previousLineEnd: InlineItemPosition? = nil
    var leadingInlineItemPosition = needsLayoutRange.start
    var numberOfLinesWithInlineContent: UInt64 = 0
    while true {
      let lineInitialRect = InlineRect(
        top: lineLogicalTop, left: constraints.horizontal.logicalLeft.float(),
        width: constraints.horizontal.logicalWidth.float(),
        height: formattingUtils().initialLineHeight(isFirstLine: previousLine_ == nil))
      let lineInput = LineInput(
        needsLayoutRange: InlineItemRange(
          start: leadingInlineItemPosition, end: needsLayoutRange.end),
        initialLogicalRect: lineInitialRect)
      let lineIndex = previousLine_ != nil ? previousLine_!.lineIndex + 1 : 0

      let lineLayoutResult = lineBuilder.layoutInlineContent(
        lineInput: lineInput, previousLine: previousLine_)
      var lineBoxBuilder = LineBoxBuilder(
        inlineFormattingContext: self, lineLayoutResult: lineLayoutResult)
      let lineBox = lineBoxBuilder.build(lineIndex: lineIndex)
      let lineLogicalRect = createDisplayContentForInlineContent(
        lineBox: lineBox, lineLayoutResult: lineLayoutResult, constraints: constraints,
        displayContent: &layoutResult.displayContent,
        numberOfPreviousLinesWithInlineContent: numberOfLinesWithInlineContent)
      updateBoxGeometryForPlacedFloats(placedFloats: lineLayoutResult.floatContent.placedFloats)
      updateInlineLayoutStateWithLineLayoutResult(
        lineLayoutResult: lineLayoutResult, lineLogicalRect: lineLogicalRect,
        floatingContext: floatingContext!)

      let lineContentEnd = lineLayoutResult.inlineItemRange.end
      leadingInlineItemPosition = InlineFormattingUtils.leadingInlineItemPositionForNextLine(
        lineContentEnd: lineContentEnd, previousLineContentEnd: previousLineEnd,
        lineHasIntrusiveOrNewlyPlacedFloat: !lineLayoutResult.floatContent.hasIntrusiveFloat
          .isEmpty
          || !lineLayoutResult.floatContent.placedFloats.isEmpty,
        layoutRangeEnd: needsLayoutRange.end)
      let isLastLine =
        leadingInlineItemPosition == needsLayoutRange.end
        && lineLayoutResult.floatContent.suspendedFloats.isEmpty
      if isLastLine {
        layoutResult.range =
          !isPartialLayout ? InlineLayoutResult.Range.Full : InlineLayoutResult.Range.FullFromDamage
        break
      }
      if isPartialLayout
        && mayExitFromPartialLayout(
          lineDamage: lineDamage!, lineIndex: lineIndex,
          newContent: layoutResult.displayContent.boxes)
      {
        layoutResult.range = InlineLayoutResult.Range.PartialFromDamage
        break
      }

      let lineHasInlineContent = !lineLayoutResult.inlineContent.isEmpty
      numberOfLinesWithInlineContent += lineHasInlineContent ? 1 : 0
      let hasEverSeenInlineContent =
        lineHasInlineContent || (previousLine_ != nil && previousLine_!.hasInlineContent)
      previousLine_ = PreviousLine(
        lineIndex: lineIndex,
        trailingOverflowingContentWidth: lineLayoutResult.contentGeometry
          .trailingOverflowingContentWidth,
        endsWithLineBreak: lineHasInlineContent
          && lineLayoutResult.inlineContent.last!.isLineBreak(),
        hasInlineContent: hasEverSeenInlineContent,
        inlineBaseDirection: lineLayoutResult.directionality.inlineBaseDirection,
        suspendedFloats: lineLayoutResult.floatContent.suspendedFloats)
      previousLineEnd = lineContentEnd
      lineLogicalTop = formattingUtils().logicalTopForNextLine(
        lineLayoutResult: lineLayoutResult, lineLogicalRect: lineLogicalRect,
        floatingContext: floatingContext!)
    }
    InlineDisplayLineBuilder.addLineClampTrailingLinkBoxIfApplicable(
      inlineFormattingContext: self, inlineLayoutState: layoutState(),
      displayContent: layoutResult.displayContent)
    return layoutResult
  }

  func layoutFloatContentOnly(constraints: ConstraintsForInlineContent) {
    assert(!root().hasInFlowChild())

    let placedFloats = layoutState().placedFloats()
    var builder = InlineItemsBuilder(
      inlineContentCache: inlineContentCache, root: root(),
      securityOrigin: globalLayoutState.securityOrigin())
    builder.build(startPosition: InlineItemPosition())

    for inlineItem in inlineContentCache.inlineItems.content() {
      if inlineItem.isFloat() {
        let floatBox = inlineItem.layoutBox

        integrationUtils!.layoutWithFormattingContextForBox(box: floatBox as! ElementBoxWrapper)

        let floatBoxGeometry = geometryForBox(layoutBox: floatBox)
        var staticPosition = LayoutPointWrapper(
          x: constraints.horizontal.logicalLeft, y: constraints.logicalTop)
        staticPosition.move(dx: floatBoxGeometry.marginStart(), dy: floatBoxGeometry.marginBefore())
        floatBoxGeometry.setTopLeft(topLeft: staticPosition)

        let floatBoxTopLeft = floatingContext!.positionForFloat(
          layoutBox: floatBox, boxGeometry: floatBoxGeometry,
          horizontalConstraints: constraints.horizontal)
        floatBoxGeometry.setTopLeft(topLeft: floatBoxTopLeft)
        placedFloats.append(
          newFloatItem: floatingContext!.makeFloatItem(
            floatBox: floatBox, boxGeometry: floatBoxGeometry))
        continue
      }
      fatalError("Not reached")
    }
  }

  @discardableResult
  private func createDisplayContentForInlineContent(
    lineBox: LineBox, lineLayoutResult: LineLayoutResult, constraints: ConstraintsForInlineContent,
    displayContent: inout InlineDisplay.Content, numberOfPreviousLinesWithInlineContent: UInt64 = 0
  ) -> InlineRect {
    let lineClamp = layoutState().parentBlockLayoutState.lineClamp
    let isLegacyLineClamp = lineClamp != nil && lineClamp!.isLegacy
    let numberOfVisibleLinesAllowed = lineClamp != nil ? lineClamp!.maximumLines : nil

    let numberOfLinesWithInlineContent =
      numberOfPreviousLinesWithInlineContent + (!lineLayoutResult.inlineContent.isEmpty ? 1 : 0)
    let lineIsFullyTruncatedInBlockDirection =
      numberOfVisibleLinesAllowed != nil
      && numberOfLinesWithInlineContent > numberOfVisibleLinesAllowed!
    var displayLine = InlineDisplayLineBuilder(
      inlineFormattingContext: self, constraints: constraints
    ).build(
      lineLayoutResult: lineLayoutResult, lineBox: lineBox,
      lineIsFullyTruncatedInBlockDirection: lineIsFullyTruncatedInBlockDirection)
    var inlineDisplayContentBuilder = InlineDisplayContentBuilder(
      formattingContext: self, constraints: constraints, lineBox: lineBox, displayLine: displayLine
    )
    let boxes = inlineDisplayContentBuilder.build(lineLayoutResult: lineLayoutResult)

    let truncationPolicy = InlineFormattingUtils.lineEndingTruncationPolicy(
      rootStyle: root().style, numberOfLinesWithInlineContent: numberOfLinesWithInlineContent,
      numberOfVisibleLinesAllowed: numberOfVisibleLinesAllowed)
    InlineDisplayLineBuilder.applyEllipsisIfNeeded(
      truncationPolicy: truncationPolicy, displayLine: &displayLine, displayBoxes: boxes,
      isLastLineWithInlineContent: lineLayoutResult.isFirstLast.isLastLineWithInlineContent,
      isLegacyLineClamp: isLegacyLineClamp)
    let lineHasLegacyLineClamp =
      isLegacyLineClamp && displayLine.hasEllipsis()
      && truncationPolicy == .WhenContentOverflowsInBlockDirection
    if lineHasLegacyLineClamp {
      layoutState().setLegacyClampedLineIndex(lineIndex: lineBox.lineIndex)
    }

    displayContent.boxes.append(contentsOf: boxes)
    displayContent.lines.append(displayLine)
    return InlineFormattingUtils.flipVisualRectToLogicalForWritingMode(
      visualRect: InlineRect(rect: displayContent.lines.last!.lineBoxRect),
      writingMode: root().style.writingMode())
  }

  func resetBoxGeometriesForDiscardedContent(
    discardedRange: InlineItemRange, suspendedFloats: LineLayoutResult.SuspendedFloatList
  ) {
    if discardedRange.isEmpty() && suspendedFloats.isEmpty {
      return
    }

    let inlineItemList = inlineContentCache.inlineItems.content()
    for index in discardedRange.startIndex()..<discardedRange.endIndex() {
      let inlineItem = inlineItemList[Int(index)]
      let hasBoxGeometry =
        inlineItem.isAtomicInlineBox() || inlineItem.isFloat() || inlineItem.isHardLineBreak()
        || inlineItem.isInlineBoxStart() || inlineItem.isOpaque()
      if !hasBoxGeometry {
        continue
      }
      let boxGeometry = geometryForBox(layoutBox: inlineItem.layoutBox)
      boxGeometry.reset()
    }

    for floatBox in suspendedFloats {
      let boxGeometry = geometryForBox(layoutBox: floatBox)
      boxGeometry.reset()
    }
  }

  func createDisplayContentForLineFromCachedContent(
    constraints: ConstraintsForInlineContent, layoutResult: inout InlineLayoutResult
  ) -> Bool {
    if inlineContentCache.maximumIntrinsicWidthLineContent == nil
      || inlineContentCache.maximumContentSize == nil
    {
      return false
    }

    let horizontalAvailableSpace = constraints.horizontal.logicalWidth
    if inlineContentCache.maximumContentSize! > horizontalAvailableSpace.float() {
      inlineContentCache.clearMaximumIntrinsicWidthLineContent()
      return false
    }
    if !layoutState().placedFloats().isEmpty() {
      inlineContentCache.clearMaximumIntrinsicWidthLineContent()
      return false
    }

    var lineContent = inlineContentCache.maximumIntrinsicWidthLineContent!
    let successfullyTrimmed = restoreTrimmedTrailingWhitespaceIfApplicable(
      lineContent: &lineContent, horizontalAvailableSpace: horizontalAvailableSpace)
    if let successfullyTrimmedUnwrapped = successfullyTrimmed {
      if !successfullyTrimmedUnwrapped {
        inlineContentCache.clearMaximumIntrinsicWidthLineContent()
        return false
      }
    }

    lineContent.lineGeometry.logicalTopLeft = InlineLayoutPoint(
      x: constraints.horizontal.logicalLeft.float(), y: constraints.logicalTop.float())
    lineContent.lineGeometry.logicalWidth = constraints.horizontal.logicalWidth.float()
    lineContent.contentGeometry.logicalLeft = InlineFormattingUtils.horizontalAlignmentOffset(
      rootStyle: root().style, contentLogicalRightIn: lineContent.contentGeometry.logicalWidth,
      lineLogicalWidth: lineContent.lineGeometry.logicalWidth,
      hangingTrailingWidth: lineContent.hangingContent.logicalWidth,
      runs: lineContent.inlineContent, isLastLine: true)
    var lineBoxBuilder = LineBoxBuilder(
      inlineFormattingContext: self, lineLayoutResult: lineContent)
    let lineBox = lineBoxBuilder.build(lineIndex: 0)
    createDisplayContentForInlineContent(
      lineBox: lineBox, lineLayoutResult: lineContent, constraints: constraints,
      displayContent: &layoutResult.displayContent)
    return true
  }

  func restoreTrimmedTrailingWhitespaceIfApplicable(
    lineContent: inout LineLayoutResult, horizontalAvailableSpace: LayoutUnit
  ) -> Bool? {
    // Special 'line-break: after-white-space' behavior where min/max width trims trailing whitespace, while
    // layout should preserve _overflowing_ trailing whitespace.
    if root().style.lineBreak() != .AfterWhiteSpace
      || lineContent.trimmedTrailingWhitespaceWidth == 0
    {
      return nil
    }
    if ceiledLayoutUnit(value: lineContent.contentGeometry.logicalWidth).float()
      + LayoutUnit.epsilon()
      <= horizontalAvailableSpace.float()
    {
      return nil
    }
    if !Line.restoreTrimmedTrailingWhitespace(
      trimmedTrailingWhitespaceWidth: lineContent.trimmedTrailingWhitespaceWidth,
      runs: lineContent.inlineContent)
    {
      fatalError("Not reached")
    }
    lineContent.contentGeometry.logicalWidth += lineContent.trimmedTrailingWhitespaceWidth
    lineContent.contentGeometry.logicalRightIncludingNegativeMargin +=
      lineContent.trimmedTrailingWhitespaceWidth
    lineContent.trimmedTrailingWhitespaceWidth = 0
    return true
  }

  func createDisplayContentForEmptyInlineContent(
    constraints: ConstraintsForInlineContent, layoutResult: inout InlineLayoutResult
  ) {
    var emptyLineBreakingResult = LineLayoutResult()
    emptyLineBreakingResult.lineGeometry = LineLayoutResult.LineGeometry(
      logicalTopLeft: InlineLayoutPoint(
        x: constraints.horizontal.logicalLeft.float(), y: constraints.logicalTop.float()),
      logicalWidth: constraints.horizontal.logicalWidth.float())
    var lineBoxBuilder = LineBoxBuilder(
      inlineFormattingContext: self, lineLayoutResult: emptyLineBreakingResult)
    let lineBox = lineBoxBuilder.build(lineIndex: 0)
    createDisplayContentForInlineContent(
      lineBox: lineBox, lineLayoutResult: emptyLineBreakingResult, constraints: constraints,
      displayContent: &layoutResult.displayContent)
  }

  func updateInlineLayoutStateWithLineLayoutResult(
    lineLayoutResult: LineLayoutResult, lineLogicalRect: InlineRect,
    floatingContext: FloatingContext
  ) {
    let layoutState_ = layoutState()
    if let firstLineGap = lineLayoutResult.lineGeometry.initialLetterClearGap {
      assert(layoutState_.clearGapBeforeFirstLine == 0)
      layoutState_.setClearGapBeforeFirstLine(verticalGap: firstLineGap)
    }

    if lineLayoutResult.isFirstLast.isLastLineWithInlineContent {
      layoutState_.setClearGapAfterLastLine(
        verticalGap: formattingUtils().logicalTopForNextLine(
          lineLayoutResult: lineLayoutResult, lineLogicalRect: lineLogicalRect,
          floatingContext: floatingContext
        ) - lineLogicalRect.bottom())
    }

    if lineLayoutResult.endsWithHyphen {
      layoutState_.incrementSuccessiveHyphenatedLineCount()
    } else {
      layoutState_.resetSuccessiveHyphenatedLineCount()
    }
    layoutState_.setFirstLineStartTrimForInitialLetter(
      trimmedThisMuch: lineLayoutResult.firstLineStartTrim)
  }

  func updateBoxGeometryForPlacedFloats(placedFloats: LineLayoutResult.PlacedFloatList) {
    for floatItem in placedFloats {
      if let layoutBox = floatItem.layoutBox() {
        let boxGeometry = geometryForBox(layoutBox: layoutBox)
        let usedGeometry = floatItem.boxGeometry()
        boxGeometry.setTopLeft(topLeft: BoxGeometry.borderBoxTopLeft(box: usedGeometry))
        // Adopt trimmed inline direction margin.
        boxGeometry.setHorizontalMargin(margin: usedGeometry.horizontalMargin())
      } else {
        // We should not be placing intrusive floats coming from parent BFC.
        fatalError("Not reached")
      }
    }
  }

  func initializeInlineLayoutState(globalLayoutState: LayoutStateWrapper) {
    let inlineLayoutState = layoutState()

    let limitLinesValue = root().style.hyphenationLimitLines()
    if limitLinesValue != RenderStyleWrapper.initialHyphenationLimitLines() {
      inlineLayoutState.setHyphenationLimitLines(hyphenationLimitLines: UInt64(limitLinesValue))
    }
    // FIXME: Remove when IFC takes care of running layout on inline-blocks.
    inlineLayoutState.setShouldNotSynthesizeInlineBlockBaseline()
    if globalLayoutState.inStandardsMode() {
      inlineLayoutState.setInStandardsMode()
    }
  }

  func rebuildInlineItemListIfNeeded(lineDamage: InlineDamageWrapper?) {
    let inlineItemListNeedsUpdate =
      inlineContentCache.inlineItems.isEmpty()
      || (lineDamage != nil && lineDamage!.isInlineItemListDirty())
    if !inlineItemListNeedsUpdate {
      return
    }
    var builder = InlineItemsBuilder(
      inlineContentCache: inlineContentCache, root: rootBlockContainer,
      securityOrigin: globalLayoutState.securityOrigin()
    )
    builder.build(startPosition: startPositionForInlineItemsBuilding(lineDamage: lineDamage))
    if lineDamage != nil {
      lineDamage!.setInlineItemListClean()
    }
    inlineContentCache.clearMaximumIntrinsicWidthLineContent()
  }

  func startPositionForInlineItemsBuilding(lineDamage: InlineDamageWrapper?) -> InlineItemPosition {
    if lineDamage == nil {
      assert(inlineContentCache.inlineItems.isEmpty())
      return InlineItemPosition()
    }
    if let startPosition = lineDamage!.layoutStartPosition() {
      if lineDamage!.damageReasons.contains(.Pagination) {
        // FIXME: We don't support partial rebuild with certain types of content. Let's just re-collect inline items.
        return InlineItemPosition()
      }
      return startPosition.inlineItemPosition
    }
    // Unsupported damage. Need to run full build/layout.
    return InlineItemPosition()
  }

  var rootBlockContainer: ElementBoxWrapper
  var globalLayoutState = LayoutStateWrapper(p: nil)
  var floatingContext: FloatingContext? = nil
  var inlineFormattingUtils: InlineFormattingUtils? = nil
  var inlineQuirks: InlineQuirks? = nil
  var integrationUtils: IntegrationUtils? = nil
  var inlineContentCache = InlineContentCache()
  var inlineLayoutState: InlineLayoutState? = nil
}
