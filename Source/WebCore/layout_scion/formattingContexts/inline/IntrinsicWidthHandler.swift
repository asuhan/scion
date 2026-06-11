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

  private func formattingContext() -> InlineFormattingContext { return m_inlineFormattingContext }

  private func formattingContextRoot() -> ElementBoxWrapper {
    return m_inlineFormattingContext.root()
  }

  private let m_inlineFormattingContext: InlineFormattingContext
  private let m_inlineItems: InlineContentCache.InlineItems
  private var m_inlineItemRange: InlineItemRange
  private var m_mayUseSimplifiedTextOnlyInlineLayoutInRange: Bool = false
}
