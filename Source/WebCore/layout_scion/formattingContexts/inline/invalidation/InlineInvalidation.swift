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

private func invalidatedLineByDamagedBox(
  _ damagedContent: DamagedContent, _ inlineItemList: InlineItemList,
  _ displayBoxes: InlineDisplay.Boxes
) -> InvalidatedLine? {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
