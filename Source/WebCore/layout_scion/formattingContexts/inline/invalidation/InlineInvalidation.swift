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

struct DamagedContent {
  let layoutBox: BoxWrapper
  // Only text type of boxes may have offset. No offset also simply points to the end of the layout box.
  let offset: UInt64?
  enum `Type` {
    case Insertion
    case Removal
  }
  let type: `Type`
}

struct InvalidatedLine {
  let index: UInt64
  let leadingInlineItemPosition: InlineItemPosition
  let damagedLineIndex: UInt64
}

private func isSameLayoutBox(_ a: BoxWrapper, _ b: BoxWrapper) -> Bool {
  return CPtrToInt(a.p) == CPtrToInt(b.p)
}

private func damagedLineIndex(
  _ damagedContent: DamagedContent, _ displayBoxes: InlineDisplay.Boxes
) -> UInt64? {
  assert(!displayBoxes.isEmpty)

  if displayBoxes.count == 1 {
    // Let's return the first line on empty content (when only root inline display box is present).
    return UInt64(displayBoxes.last!.lineIndex)
  }

  let lastDisplayBoxIndexForLayoutBox = { () -> Int? in
    for index in stride(from: displayBoxes.count - 1, through: 0, by: -1) {
      if isSameLayoutBox(damagedContent.layoutBox, displayBoxes[index].layoutBox) {
        return index
      }
    }
    // FIXME: When the damaged layout box does not generate even one display box (all collapsed), we should
    // look at previous/next content to damage lines.
    return nil
  }
  guard let lastDisplayBoxIndex = lastDisplayBoxIndexForLayoutBox() else {
    // FIXME: Completely collapsed content should not trigger full invalidation.
    return nil
  }

  let candidateLineIndex = { (damagedDisplayBoxIndex: Int) -> UInt64? in
    if damagedDisplayBoxIndex == 0 || damagedDisplayBoxIndex >= displayBoxes.count {
      fatalError("Not reached")
    }
    let damagedDisplayBox = displayBoxes[damagedDisplayBoxIndex]
    assert(isSameLayoutBox(damagedDisplayBox.layoutBox, damagedContent.layoutBox))
    // In case of content deletion, we may need to damage the "previous" line.
    if damagedContent.type == .Insertion || damagedDisplayBox.lineIndex == 0 {
      return UInt64(damagedDisplayBox.lineIndex)
    }
    if !displayBoxes[damagedDisplayBoxIndex - 1].isRootInlineBox() {
      // There's more content in front, it's safe to stay on the current line.
      assert(displayBoxes[damagedDisplayBoxIndex - 1].lineIndex == damagedDisplayBox.lineIndex)
      return UInt64(damagedDisplayBox.lineIndex)
    }
    let damagedContentIsFirstContentOnLine =
      !damagedDisplayBox.isText()
      || (damagedContent.offset != nil
        && (damagedContent.offset! == 0
          || UInt64(damagedDisplayBox.text().start) == damagedContent.offset!))
    return UInt64(
      damagedContentIsFirstContentOnLine
        ? damagedDisplayBox.lineIndex - 1 : damagedDisplayBox.lineIndex)
  }

  var leadingIndexForDisplayBox = lastDisplayBoxIndex
  if damagedContent.layoutBox.isLineBreakBox() || damagedContent.layoutBox.isReplacedBox() {
    return candidateLineIndex(leadingIndexForDisplayBox)
  }

  if damagedContent.layoutBox is InlineTextBoxWrapper {
    guard let offset = damagedContent.offset else {
      return candidateLineIndex(leadingIndexForDisplayBox)
    }

    if offset > displayBoxes[leadingIndexForDisplayBox].text().end() {
      // Protect against text updater providing bogus damage offset (offset is _after_ the last display box here).
      // Let's just fallback to full invalidation.
      return nil
    }

    var index = leadingIndexForDisplayBox
    while index > 0 {
      let displayBox = displayBoxes[index]
      if displayBox.isRootInlineBox()
        || (displayBox.isInlineBox() && !displayBox.isFirstForLayoutBox)
      {
        // Multi line damage includes line leading root inline display boxes (and maybe line spanning inline boxes).
        index -= 1
        continue
      }
      if !isSameLayoutBox(displayBox.layoutBox, damagedContent.layoutBox) {
        // We should always be able to find the damaged offset within this layout box.
        break
      }
      assert(displayBox.isTextOrSoftLineBreak())
      // Find out which display box has the damaged offset position.
      let startOffset = UInt64(displayBox.text().start)
      if startOffset <= offset {
        // FIXME: Add support for leading inline box deletion too.
        return candidateLineIndex(index)
      }
      leadingIndexForDisplayBox = index
      index -= 1
    }
    // In some cases leading content does not produce a display box (collapsed whitespace), let's just use the first display box.
    assert(leadingIndexForDisplayBox != 0)
    return candidateLineIndex(leadingIndexForDisplayBox)
  }
  // TODO(asuhan): ASSERT_NOT_IMPLEMENTED_YET()
  return nil
}

private func leadingContentDisplayForLineIndex(
  _ lineIndex: UInt64, _ displayBoxes: InlineDisplay.Boxes
) -> InlineDisplay.Box? {
  let rootInlineBoxIndexOnLine = { () -> Int in
    for index in stride(from: displayBoxes.count - 1, through: 0, by: -1) {
      let displayBox = displayBoxes[index]
      if UInt64(displayBox.lineIndex) == lineIndex && displayBox.isRootInlineBox() {
        return index
      }
    }
    fatalError("Not reached")
  }

  var firstContentDisplayBoxIndex = rootInlineBoxIndexOnLine() + 1
  while firstContentDisplayBoxIndex < displayBoxes.count {
    let displayBox = displayBoxes[firstContentDisplayBoxIndex]
    if displayBox.isRootInlineBox() {
      return nil
    }
    if !displayBox.isNonRootInlineBox() || displayBox.isFirstForLayoutBox {
      return displayBox
    }
    firstContentDisplayBoxIndex += 1
  }
  return nil
}

private func inlineItemPositionForDisplayBox(
  _ displayBox: InlineDisplay.Box, _ inlineItemList: InlineItemList
) -> InlineItemPosition? {
  assert(!inlineItemList.isEmpty)

  let lastInlineItemIndexForDisplayBox = { () -> Int? in
    for index in stride(from: inlineItemList.count - 1, through: 0, by: -1) {
      if isSameLayoutBox(inlineItemList[index].layoutBox, displayBox.layoutBox)
        && !inlineItemList[index].isInlineBoxEnd()
      {
        return index
      }
    }
    return nil
  }()

  guard var inlineItemIndex = lastInlineItemIndexForDisplayBox else {
    return nil
  }

  // This is our last InlineItem associated with this layout box. Let's find out
  // which previous InlineItem is at the beginning of this display box.
  if !displayBox.isTextOrSoftLineBreak() {
    return InlineItemPosition(index: UInt64(inlineItemIndex), offset: 0)
  }
  // 1. A display box could consist of one or more InlineItems.
  // 2. A display box could start at any offset inside an InlineItem.
  let startOffset = displayBox.text().start
  while true {
    let inlineTextItemRange = { () -> (begin: UInt32, end: UInt32) in
      if let inlineTextItem = inlineItemList[inlineItemIndex] as? InlineTextItemWrapper {
        return (inlineTextItem.start(), inlineTextItem.end())
      }
      if let inlineSoftBreakItem = inlineItemList[inlineItemIndex]
        as? InlineSoftLineBreakItemWrapper
      {
        let startPosition = inlineSoftBreakItem.position()
        return (startPosition, startPosition + 1)
      }
      fatalError("Not reached")
    }
    let textRange = inlineTextItemRange()
    if textRange.begin <= startOffset && textRange.end > startOffset {
      return InlineItemPosition(
        index: UInt64(inlineItemIndex), offset: UInt64(startOffset - textRange.begin))
    }
    if inlineItemIndex == 0 {
      break
    }
    inlineItemIndex -= 1
  }
  return nil
}

private func inlineItemPositionForDamagedContentPosition(
  _ damagedContent: DamagedContent, _ candidatePosition: InlineItemPosition,
  _ inlineItemList: InlineItemList
) -> InlineItemPosition? {
  assert(candidatePosition.index < inlineItemList.count)
  if !candidatePosition.bool() {
    return candidatePosition
  }
  if !(damagedContent.layoutBox is InlineTextBoxWrapper) {
    assert(damagedContent.offset == nil)
    return candidatePosition
  }
  let candidateInlineItem = inlineItemList[Int(candidatePosition.index)]
  if !isSameLayoutBox(candidateInlineItem.layoutBox, damagedContent.layoutBox)
    || (!(candidateInlineItem is InlineTextItemWrapper)
      && !(candidateInlineItem is InlineSoftLineBreakItemWrapper))
  {
    return candidatePosition
  }
  guard let damagedOffset = damagedContent.offset else {
    // When damage points to "after" the layout box, whatever InlineItem we found is surely before the damage.
    return candidatePosition
  }

  let startPosition = { (inlineItem: InlineItemWrapper) -> UInt64 in
    if let inlineTextItem = inlineItem as? InlineTextItemWrapper {
      return UInt64(inlineTextItem.start())
    }
    return UInt64((inlineItem as! InlineSoftLineBreakItemWrapper).position())
  }

  let contentOffset = startPosition(candidateInlineItem) + candidatePosition.offset
  if contentOffset < damagedOffset {
    // The damaged content is after the start of this inline item.
    return candidatePosition
  }
  // When the inline item's entire content is being removed, we need to find the previous inline item that belongs to this damaged layout box.
  if contentOffset == damagedOffset && damagedContent.type != .Removal {
    return candidatePosition
  }

  // The damage offset is before the first display box we managed to find for this layout box.
  // Let's adjust the candidate position by moving it over to the damaged offset.
  var index = Int(candidatePosition.index)
  while index > 0 {
    index -= 1
    let previousInlineItem = inlineItemList[index]
    if !isSameLayoutBox(candidateInlineItem.layoutBox, previousInlineItem.layoutBox) {
      // We should stay on the same layout box.
      fatalError("Not reached")
    }
    if startPosition(previousInlineItem) <= damagedOffset {
      return InlineItemPosition(index: UInt64(index), offset: 0)
    }
  }
  return nil
}

private func isValidInlineItemPositionForLine(
  _ inlineItemPosition: InlineItemPosition, _ lineIndex: UInt64
) -> Bool {
  // It's clearly not correct when starting position is 0 while the damaged line is not the first one.
  if !inlineItemPosition.bool() && lineIndex != 0 {
    return false
  }
  // FIXME: Consider checking for the case when we are on the first line with a non-zero inlineItemPosition.
  return true
}

private func leadingInlineItemPositionOnLastLine(
  _ inlineItemList: InlineItemList, _ displayBoxes: InlineDisplay.Boxes
) -> InlineItemPosition? {
  assert(!displayBoxes.isEmpty)
  let lastLineIndex = UInt64(displayBoxes.last!.lineIndex)
  guard
    let leadingContentDisplayBoxOnInvalidatedLine = leadingContentDisplayForLineIndex(
      lastLineIndex, displayBoxes)
  else {
    return nil
  }

  guard
    let inlineItemPositionForLeadingDisplayBox = inlineItemPositionForDisplayBox(
      leadingContentDisplayBoxOnInvalidatedLine, inlineItemList)
  else {
    return nil
  }

  if !isValidInlineItemPositionForLine(inlineItemPositionForLeadingDisplayBox, lastLineIndex) {
    fatalError("Not reached")
  }

  return inlineItemPositionForLeadingDisplayBox
}

private func invalidatedLineByDamagedBox(
  _ damagedContent: DamagedContent, _ inlineItemList: InlineItemList,
  _ displayBoxes: InlineDisplay.Boxes
) -> InvalidatedLine? {
  assert(!displayBoxes.isEmpty)
  // 1. Find the root inline box based on the damaged layout box (this is our damaged line)
  // 2. Find the first content display box on this damaged line
  // 3. Find the associated InlineItem with partial text offset if applicable
  guard let damagedLine = damagedLineIndex(damagedContent, displayBoxes) else {
    return nil
  }

  // We can't be sure whether a newly inserted content introduces a new breaking opportunity, so let's just initiate layout from the previous line.
  let lineToInvalidate =
    damagedContent.type == .Removal ? damagedLine : damagedLine == 0 ? 0 : damagedLine - 1
  guard
    let leadingContentDisplayBoxOnInvalidatedLine = leadingContentDisplayForLineIndex(
      lineToInvalidate, displayBoxes)
  else {
    // This is a completely empty line (e.g. <div><span> </span></div> where the whitespace is collapsed).
    return nil
  }
  if let inlineItemPositionForLeadingDisplayBox = inlineItemPositionForDisplayBox(
    leadingContentDisplayBoxOnInvalidatedLine, inlineItemList)
  {
    if !isValidInlineItemPositionForLine(inlineItemPositionForLeadingDisplayBox, lineToInvalidate) {
      fatalError("Not implemented")
    }
    // In some rare cases, the leading display box's inline item position is after the actual damage (e.g. when collapsed leading content is removed).
    if let adjustedPosition = inlineItemPositionForDamagedContentPosition(
      damagedContent, inlineItemPositionForLeadingDisplayBox, inlineItemList)
    {
      return InvalidatedLine(
        index: lineToInvalidate, leadingInlineItemPosition: adjustedPosition,
        damagedLineIndex: damagedLine)
    }
  }
  return nil
}

private func trailingDisplayBoxesAfterDamagedLine(
  _ damagedLineIndex: UInt64, _ displayContent: InlineDisplay.Content
) -> InlineDamageWrapper.TrailingDisplayBoxList {
  var trailingDisplayBoxes: InlineDamageWrapper.TrailingDisplayBoxList = []
  let lines = displayContent.lines[...]
  let boxes = displayContent.boxes[...]
  for lineIndex in Int(damagedLineIndex + 1)..<lines.count {
    let lastDisplayBoxIndexForLine = Int(
      lines[lineIndex].firstBoxIndex() + lines[lineIndex].boxCount() - 1)
    if lastDisplayBoxIndexForLine >= boxes.count {
      fatalError("Not reached")
    }
    trailingDisplayBoxes.append(boxes[lastDisplayBoxIndexForLine])
  }
  return trailingDisplayBoxes
}

private func isSupportedContent(_ layoutBox: BoxWrapper) -> Bool {
  return layoutBox is InlineTextBoxWrapper || layoutBox.isLineBreakBox()
    || layoutBox.isReplacedBox() || layoutBox.isInlineBox()
}

struct InlineInvalidation {
  init(
    inlineDamage: InlineDamageWrapper, inlineItemList: InlineItemList,
    displayContent: InlineDisplay.Content
  ) {
    m_inlineDamage = inlineDamage
    m_inlineItemList = inlineItemList
    m_displayContent = displayContent
  }

  func rootStyleWillChange(formattingContextRoot: ElementBoxWrapper, newStyle: RenderStyleWrapper)
    -> Bool
  {
    assert(formattingContextRoot.establishesInlineFormattingContext())

    if m_inlineDamage.isInlineItemListDirty() {
      return true
    }

    let inlineItemListNeedsUpdate = { () in
      let oldStyle = formattingContextRoot.style

      if TextBreakingPositionContext(style: oldStyle)
        != TextBreakingPositionContext(style: newStyle)
      {
        return true
      }

      if oldStyle.fontCascade() != newStyle.fontCascade() {
        return true
      }

      let newFirstLineStyle = newStyle.getCachedPseudoStyle(
        pseudoElementIdentifier: Style.PseudoElementIdentifier(pseudoId: .FirstLine))
      let oldFirstLineStyle = oldStyle.getCachedPseudoStyle(
        pseudoElementIdentifier: Style.PseudoElementIdentifier(pseudoId: .FirstLine))
      if newFirstLineStyle != nil && oldFirstLineStyle != nil
        && oldFirstLineStyle!.fontCascade() != newFirstLineStyle!.fontCascade()
      {
        return true
      }

      if (newFirstLineStyle != nil && newFirstLineStyle!.fontCascade() != oldStyle.fontCascade())
        || (oldFirstLineStyle != nil && oldFirstLineStyle!.fontCascade() != newStyle.fontCascade())
      {
        return true
      }

      if oldStyle.direction() != newStyle.direction()
        || oldStyle.unicodeBidi() != newStyle.unicodeBidi()
        || oldStyle.tabSize() != newStyle.tabSize()
        || oldStyle.textSecurity() != newStyle.textSecurity()
      {
        return true
      }

      return false
    }

    if inlineItemListNeedsUpdate() {
      m_inlineDamage.setInlineItemListDirty()
    }

    return true
  }

  func styleWillChange(layoutBox: BoxWrapper, newStyle: RenderStyleWrapper, diff: StyleDifference)
    -> Bool
  {
    if diff == .Layout {
      m_inlineDamage.resetLayoutPosition()
      m_inlineDamage.setDamageReason(.StyleChange)
    }

    if m_inlineDamage.isInlineItemListDirty() {
      return true
    }

    if layoutBox.isInlineTextBox() {
      // Either the root or parent inline box takes care of this style change.
      return true
    }

    let inlineItemListNeedsUpdate = { () in
      let oldStyle = layoutBox.style

      let hasInlineItemTypeChanged =
        oldStyle.hasOutOfFlowPosition() != newStyle.hasOutOfFlowPosition()
        || oldStyle.isFloating() != newStyle.isFloating()
        || oldStyle.display() != newStyle.display()
      if hasInlineItemTypeChanged {
        return true
      }

      if !layoutBox.isInlineBox() {
        return false
      }

      let contentMayNeedNewBreakingPositionsAndMeasuring =
        TextBreakingPositionContext(style: oldStyle) != TextBreakingPositionContext(style: newStyle)
        || oldStyle.fontCascade() != newStyle.fontCascade()
      if contentMayNeedNewBreakingPositionsAndMeasuring {
        return true
      }

      let bidiContextChanged =
        oldStyle.unicodeBidi() != newStyle.unicodeBidi()
        || oldStyle.direction() != newStyle.direction()
      if bidiContextChanged {
        return true
      }

      return false
    }

    if inlineItemListNeedsUpdate() {
      m_inlineDamage.setInlineItemListDirty()
    }

    return true
  }

  func textInserted(newOrDamagedInlineTextBox: InlineTextBoxWrapper, offset: UInt64? = nil) -> Bool
  {
    m_inlineDamage.setInlineItemListDirty()

    if setFullLayoutIfNeeded(newOrDamagedInlineTextBox) {
      return false
    }

    let displayBoxes = self.displayBoxes()
    var invalidatedLine: InvalidatedLine? = nil
    let damageReason: InlineDamageWrapper.Reason =
      offset != nil
      ? .ContentChange : newOrDamagedInlineTextBox.nextInFlowSibling() != nil ? .Insert : .Append
    switch damageReason {
    case .ContentChange:
      // Existing text box got modified. Dirty all the way up to the damaged position's line.
      invalidatedLine = invalidatedLineByDamagedBox(
        DamagedContent(layoutBox: newOrDamagedInlineTextBox, offset: offset!, type: .Insertion),
        m_inlineItemList, displayBoxes)
    case .Append:
      // New text box got appended. Let's dirty the last line.
      if let leadingInlineItemPosition = leadingInlineItemPositionOnLastLine(
        m_inlineItemList, displayBoxes)
      {
        let lastLineIndex = UInt64(displayBoxes.last!.lineIndex)
        invalidatedLine = InvalidatedLine(
          index: lastLineIndex, leadingInlineItemPosition: leadingInlineItemPosition,
          damagedLineIndex: lastLineIndex)
      }
    case .Insert:
      invalidatedLine = InvalidatedLine(
        index: 0, leadingInlineItemPosition: InlineItemPosition(), damagedLineIndex: 0)
      // New text box got inserted. Let's damage existing content starting from the previous sibling.
      if let previousSibling = newOrDamagedInlineTextBox.previousInFlowSibling() {
        invalidatedLine = invalidatedLineByDamagedBox(
          DamagedContent(layoutBox: previousSibling, offset: nil, type: .Insertion),
          m_inlineItemList, displayBoxes)
      }
    default:
      fatalError("Not reached")
    }

    if let invalidatedLine = invalidatedLine {
      return updateInlineDamage(invalidatedLine, damageReason, offset != nil ? .No : .Yes)
    }

    m_inlineDamage.resetLayoutPosition()
    return false
  }

  func textWillBeRemoved(damagedInlineTextBox: InlineTextBoxWrapper, offset: UInt64? = nil) -> Bool
  {
    m_inlineDamage.setInlineItemListDirty()

    if setFullLayoutIfNeeded(damagedInlineTextBox) {
      return false
    }

    if let invalidatedLine = invalidatedLineByDamagedBox(
      DamagedContent(layoutBox: damagedInlineTextBox, offset: offset ?? 0, type: .Removal),
      m_inlineItemList, displayBoxes())
    {
      return updateInlineDamage(invalidatedLine, .Remove, .No)
    }

    m_inlineDamage.resetLayoutPosition()
    return false
  }

  func inlineLevelBoxInserted(layoutBox: BoxWrapper) -> Bool {
    m_inlineDamage.setInlineItemListDirty()

    if setFullLayoutIfNeeded(layoutBox) {
      return false
    }

    let displayBoxes = self.displayBoxes()
    var invalidatedLine: InvalidatedLine? = nil
    if layoutBox.nextInFlowSibling() == nil {
      // New box got appended. Let's dirty the last line.
      if m_inlineDamage.reasons() == .Append {
        // Series of append operations always produces the same damage position.
        return m_inlineDamage.layoutStartPosition() != nil
      }
      assert(m_inlineDamage.reasons().isEmpty)
      if let leadingInlineItemPosition = leadingInlineItemPositionOnLastLine(
        m_inlineItemList, displayBoxes)
      {
        let lastLineIndex = UInt64(displayBoxes.last!.lineIndex)
        invalidatedLine = InvalidatedLine(
          index: lastLineIndex, leadingInlineItemPosition: leadingInlineItemPosition,
          damagedLineIndex: lastLineIndex)
      }
    } else {
      invalidatedLine = InvalidatedLine(
        index: 0, leadingInlineItemPosition: InlineItemPosition(), damagedLineIndex: 0)
      // New box got inserted. Let's damage existing content starting from the previous sibling.
      if let previousSibling = layoutBox.previousInFlowSibling() {
        invalidatedLine = invalidatedLineByDamagedBox(
          DamagedContent(layoutBox: previousSibling, offset: nil, type: .Insertion),
          m_inlineItemList, displayBoxes)
      }
    }
    if let invalidatedLine = invalidatedLine {
      return updateInlineDamage(
        invalidatedLine, layoutBox.nextInFlowSibling() == nil ? .Append : .Insert, .Yes)
    }

    m_inlineDamage.resetLayoutPosition()
    return false
  }

  func inlineLevelBoxWillBeRemoved(layoutBox: BoxWrapper) -> Bool {
    m_inlineDamage.setInlineItemListDirty()

    if setFullLayoutIfNeeded(layoutBox) {
      return false
    }

    if let invalidatedLine = invalidatedLineByDamagedBox(
      DamagedContent(layoutBox: layoutBox, offset: nil, type: .Removal), m_inlineItemList,
      displayBoxes())
    {
      return updateInlineDamage(invalidatedLine, .Remove, .Yes)
    }

    m_inlineDamage.resetLayoutPosition()
    return false
  }

  func inlineLevelBoxContentWillChange(layoutBox: BoxWrapper) -> Bool {
    // FIXME: Add support for partial layout when inline box content change may trigger size change.
    m_inlineDamage.resetLayoutPosition()
    return true
  }

  func restartForPagination(lineIndex: UInt64, pageTopAdjustment: LayoutUnit) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func mayOnlyNeedPartialLayout(inlineDamage: InlineDamageWrapper?) -> Bool {
    if let inlineDamage = inlineDamage {
      return inlineDamage.layoutStartPosition() != nil
    }
    return false
  }

  static func resetInlineDamage(inlineDamage: InlineDamageWrapper) {
    inlineDamage.setInlineItemListDirty()
    inlineDamage.resetLayoutPosition()
  }

  private enum ShouldApplyRangeLayout {
    case No
    case Yes
  }

  private func updateInlineDamage(
    _ invalidatedLine: InvalidatedLine, _ reason: InlineDamageWrapper.Reason,
    _ shouldApplyRangeLayout: ShouldApplyRangeLayout = .No,
    _ pageTopAdjustment: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) -> Bool {
    let isValidDamage = { () in
      // Check for consistency.
      if !invalidatedLine.leadingInlineItemPosition.bool() {
        // We have to start at the first line if damage points to the leading inline item.
        return invalidatedLine.index == 0
      }
      return true
    }
    if !isValidDamage() {
      fatalError("Not reached")
    }

    let partialContentTop =
      LayoutUnit(
        value: invalidatedLine.index != 0
          ? m_displayContent.lines[Int(invalidatedLine.index - 1)].lineBoxLogicalRect.maxY() : 0)
      + pageTopAdjustment

    let layoutStartPosition = InlineDamageWrapper.LayoutPosition(
      lineIndex: invalidatedLine.index,
      inlineItemPosition: invalidatedLine.leadingInlineItemPosition,
      partialContentTop: partialContentTop)

    m_inlineDamage.setDamageReason(reason)
    m_inlineDamage.setLayoutStartPosition(layoutStartPosition)

    if shouldApplyRangeLayout == .Yes {
      m_inlineDamage.setTrailingDisplayBoxes(
        trailingDisplayBoxesAfterDamagedLine(invalidatedLine.index, m_displayContent))
    }
    return true
  }

  private func setFullLayoutIfNeeded(_ layoutBox: BoxWrapper) -> Bool {
    if !isSupportedContent(layoutBox) {
      fatalError("Not reached")
    }

    if displayBoxes().isEmpty {
      fatalError("Not reached")
    }

    if m_inlineItemList.isEmpty {
      // We must be under memory pressure.
      m_inlineDamage.resetLayoutPosition()
      return true
    }

    if m_inlineDamage.reasons().contains(.StyleChange) {
      m_inlineDamage.resetLayoutPosition()
      return true
    }

    return false
  }

  private func displayBoxes() -> InlineDisplay.Boxes { return m_displayContent.boxes }

  private let m_inlineDamage: InlineDamageWrapper
  private let m_inlineItemList: InlineItemList
  private let m_displayContent: InlineDisplay.Content
}
