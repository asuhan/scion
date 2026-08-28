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

import Foundation

struct InlineQuirks {
  init(inlineFormattingContext: InlineFormattingContext) {
    self.inlineFormattingContext = inlineFormattingContext
  }

  func trailingNonBreakingSpaceNeedsAdjustment(isInIntrinsicWidthMode: Bool, lineHasOverflow: Bool)
    -> Bool
  {
    if isInIntrinsicWidthMode || !lineHasOverflow {
      return false
    }
    let rootStyle = formattingContext().root().style
    return rootStyle.nbspMode() == .Space && rootStyle.textWrapMode() != .NoWrap
      && rootStyle.whiteSpaceCollapse() != .BreakSpaces
  }

  func initialLineHeight() -> InlineLayoutUnit {
    assert(!formattingContext().layoutState().inStandardsMode)
    return 0
  }

  func inlineBoxAffectsLineBox(inlineLevelBox: InlineLevelBox) -> Bool {
    assert(!formattingContext().layoutState().inStandardsMode)
    assert(inlineLevelBox.isInlineBox())
    // Inline boxes (e.g. root inline box or <span>) affects line boxes either through the strut or actual content.
    if inlineLevelBox.hasContent {
      return true
    }
    if inlineLevelBox.isRootInlineBox() {
      // This root inline box has no direct text content and we are in non-standards mode.
      // Now according to legacy line layout, we need to apply the following list-item specific quirk:
      // We do not create markers for list items when the list-style-type is none, while other browsers do.
      // The side effect of having no marker is that in quirks mode we have to specifically check for list-item
      // and make sure it is treated as if it had content and stretched the line.
      // see LegacyInlineFlowBox c'tor.
      return inlineLevelBox.layoutBox.style.isOriginalDisplayListItemType()
    }
    // Non-root inline boxes (e.g. <span>).
    let boxGeometry = formattingContext().geometryForBox(layoutBox: inlineLevelBox.layoutBox)
    if boxGeometry.horizontalBorderAndPadding().bool() {
      // Horizontal border and padding make the inline box stretch the line (e.g. <span style="padding: 10px;"></span>).
      return true
    }
    return false
  }

  static func lineBreakBoxAffectsParentInlineBox(lineBox: LineBox) -> Bool {
    // In quirks mode linebreak boxes (<br>) stop affecting the line box when (assume <br> is nested e.g. <span style="font-size: 100px"><br></span>)
    // 1. the root inline box has content <div>content<br>/div>
    // 2. there's at least one atomic inline level box on the line e.g <div><img><br></div> or <div><span><img></span><br></div>
    // 3. there's at least one inline box with content e.g. <div><span>content</span><br></div>
    if lineBox.rootInlineBox.hasContent {
      return false
    }
    if lineBox.hasAtomicInlineBox() {
      return false
    }
    // At this point we either have only the <br> on the line or inline boxes with or without content.
    let inlineLevelBoxes = lineBox.nonRootInlineLevelBoxes()
    assert(!inlineLevelBoxes.isEmpty)
    if inlineLevelBoxes.count == 1 {
      return true
    }
    for inlineLevelBox in lineBox.nonRootInlineLevelBoxes() {
      // Filter out empty inline boxes e.g. <div><span></span><span></span><br></div>
      if inlineLevelBox.isInlineBox() && inlineLevelBox.hasContent {
        return false
      }
    }
    return true
  }

  func initialLetterAlignmentOffset(floatBox: BoxWrapper, lineBoxStyle: RenderStyleWrapper)
    -> LayoutUnit?
  {
    assert(floatBox.isFloatingPositioned())
    if !floatBox.style.lineBoxContain().contains(.InitialLetter) {
      return nil
    }
    let primaryFontMetrics = lineBoxStyle.fontCascade().metricsOfPrimaryFont()
    let floatBoxGeometry = formattingContext().geometryForBox(layoutBox: floatBox)
    let lineHeight =
      lineBoxStyle.lineHeight().isNormal()
      ? InlineLayoutUnit(primaryFontMetrics.intAscent() + primaryFontMetrics.intDescent())
      : lineBoxStyle.computedLineHeight()
    return LayoutUnit(
      value: InlineLayoutUnit(primaryFontMetrics.intAscent())
        + (lineHeight - InlineLayoutUnit(primaryFontMetrics.intHeight())) / 2
        - InlineLayoutUnit(primaryFontMetrics.intCapHeight())
        - floatBoxGeometry.marginBorderAndPaddingBefore().float())
  }

  func adjustedRectForLineGridLineAlign(rect: InlineRect) -> InlineRect? {
    let rootBoxStyle = formattingContext().root().style
    let parentBlockLayoutState = formattingContext().layoutState().parentBlockLayoutState

    if rootBoxStyle.lineAlign() == .None {
      return nil
    }
    if let lineGrid = parentBlockLayoutState.lineGrid {
      // This implement the legacy -webkit-line-align property.
      // It snaps line edges to a grid defined by an ancestor box.
      let offset = (lineGrid.layoutOffset.width() + lineGrid.gridOffset.width()).float()
      let columnWidth = lineGrid.columnWidth
      let leftShift = fmodf(columnWidth - fmodf(rect.left() + offset, columnWidth), columnWidth)
      let rightShift = -fmodf(rect.right() + offset, columnWidth)

      var adjustedRect = rect
      adjustedRect.shiftLeftBy(offset: leftShift)
      adjustedRect.shiftRightBy(offset: rightShift)

      if adjustedRect.isEmpty() {
        return nil
      }

      return adjustedRect
    }

    return nil
  }

  func adjustmentForLineGridLineSnap(lineBox: LineBox) -> InlineLayoutUnit? {
    let rootBoxStyle = formattingContext().root().style
    let inlineLayoutState = formattingContext().layoutState()

    if rootBoxStyle.lineSnap() == .None {
      return nil
    }
    if inlineLayoutState.parentBlockLayoutState.lineGrid == nil {
      return nil
    }

    // This implement the legacy -webkit-line-snap property.
    // It snaps line baselines to a grid defined by an ancestor box.

    let lineGrid = inlineLayoutState.parentBlockLayoutState.lineGrid!

    let gridLineHeight = lineGrid.rowHeight
    if roundToInt(value: gridLineHeight.float()) == 0 {
      return nil
    }

    let gridFontMetrics = lineGrid.primaryFont!.fontMetrics()
    let lineGridFontAscent = gridFontMetrics.intAscent(baselineType: lineBox.baselineType)
    let lineGridFontHeight = gridFontMetrics.intHeight()
    let lineGridHalfLeading = (gridLineHeight - lineGridFontHeight) / 2

    var firstLineTop = lineGrid.topRowOffset + lineGrid.gridOffset.height()

    if lineGrid.paginationOrigin != nil && lineGrid.pageLogicalTop > firstLineTop {
      firstLineTop = lineGrid.paginationOrigin!.height() + lineGrid.pageLogicalTop
    }

    var firstTextTop = firstLineTop + lineGridHalfLeading
    var firstBaselinePosition = firstTextTop + lineGridFontAscent

    let rootInlineBoxTop = lineBox.logicalRect.top() + lineBox.logicalRectForRootInlineBox().top()

    let ascent = lineBox.rootInlineBox.ascent()
    let logicalHeight = ascent + lineBox.rootInlineBox.descent()
    let gridRelativeHeight = ascent + lineGrid.layoutOffset.height()
    let currentBaselinePosition = rootInlineBoxTop + gridRelativeHeight

    if rootBoxStyle.lineSnap() == .Contain {
      if logicalHeight <= Float32(lineGridFontHeight) {
        firstTextTop += (Float32(lineGridFontHeight) - logicalHeight) / 2
      } else {
        let numberOfLinesWithLeading = LayoutUnit(
          value: ceilf((logicalHeight - Float32(lineGridFontHeight)) / gridLineHeight))
        let totalHeight = lineGridFontHeight + numberOfLinesWithLeading * gridLineHeight
        firstTextTop += (totalHeight - logicalHeight) / 2
      }
      firstBaselinePosition = LayoutUnit(value: firstTextTop + ascent)
    }

    // If we're above the first line, just push to the first line.
    if currentBaselinePosition < firstBaselinePosition {
      return firstBaselinePosition - currentBaselinePosition
    }

    // Otherwise we're in the middle of the grid somewhere. Just push to the next line.
    let baselineOffset = currentBaselinePosition - firstBaselinePosition
    let remainder = roundToInt(value: baselineOffset) % roundToInt(value: gridLineHeight)
    if remainder == 0 {
      return nil
    }

    return (gridLineHeight - remainder).float()
  }

  func formattingContext() -> InlineFormattingContext {
    return inlineFormattingContext
  }

  var inlineFormattingContext: InlineFormattingContext
}
