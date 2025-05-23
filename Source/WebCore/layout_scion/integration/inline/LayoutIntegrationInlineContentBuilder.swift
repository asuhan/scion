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

import wk_interop

private func endPaddingQuirkValue(flow: RenderBlockFlowWrapper) -> Float32 {
  // FIXME: It's the copy of the lets-adjust-overflow-for-the-caret behavior from LegacyLineLayout::addOverflowFromInlineChildren.
  var endPadding = flow.hasNonVisibleOverflow() ? flow.paddingEnd() : LayoutUnit(value: 0)
  if !endPadding.bool() {
    endPadding = flow.endPaddingWidthForCaret()
  }
  if flow.hasNonVisibleOverflow() && !endPadding.bool() && flow.element() != nil
    && flow.element()!.isRootEditableElement()
    && flow.style().isLeftToRightDirection()
  {
    endPadding = LayoutUnit(value: 1)
  }
  return endPadding.float()
}

extension LayoutIntegration {
  struct InlineContentBuilder {
    init(blockFlow: RenderBlockFlowWrapper, boxTree: BoxTree) {
      self.blockFlow = blockFlow
      self.boxTree = boxTree
    }

    func build(
      layoutResult: InlineLayoutResult, inlineContent: InlineContent,
      lineDamage: InlineDamageWrapper?
    ) -> FloatRectWrapper {
      inlineContent.releaseCaches()
      computeIsFirstIsLastBoxAndBidiReorderingForInlineContent(
        boxes: layoutResult.displayContent.boxes)

      if layoutResult.range == .Full {
        var damagedRect = FloatRectWrapper()

        for line in inlineContent.displayContent.lines {
          damagedRect.unite(other: line.inkOverflow)
        }

        inlineContent.displayContent.set(newContent: layoutResult.displayContent)
        adjustDisplayLines(inlineContent: inlineContent, startIndex: 0)

        for line in inlineContent.displayContent.lines {
          damagedRect.unite(other: line.inkOverflow)
        }
        return damagedRect
      }

      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func adjustDisplayLines(inlineContent: InlineContent, startIndex: UInt64) {
      let lines = inlineContent.displayContent.lines
      let boxes = inlineContent.displayContent.boxes

      var boxIndex = startIndex == 0 ? 0 : lines[Int(startIndex - 1)].lastBoxIndex() + 1
      let rootBoxStyle = blockFlow.style()
      let isLeftToRightInlineDirection = rootBoxStyle.isLeftToRightDirection()
      let isHorizontalWritingMode = rootBoxStyle.isHorizontalWritingMode()

      for lineIndex in startIndex..<UInt64(lines.count) {
        let line = lines[Int(lineIndex)]
        var scrollableOverflowRect = line.contentOverflow
        adjustOverflowLogicalWidthWithBlockFlowQuirk(
          line: line,
          isLeftToRightInlineDirection: isLeftToRightInlineDirection,
          isHorizontalWritingMode: isHorizontalWritingMode,
          scrollableOverflowRect: &scrollableOverflowRect)

        var inkOverflowRect = scrollableOverflowRect
        // Collect overflow from boxes.
        // Note while we compute ink overflow for all type of boxes including atomic inline level boxes (e.g. <iframe> <img>) as part of constructing
        // display boxes (see InlineDisplayContentBuilder) RenderBlockFlow expects visual overflow.
        // Visual overflow propagation is slightly different from ink overflow when it comes to renderers with self painting layers.
        // -and for now we consult atomic renderers for such visual overflow which is not how we are supposed to do in LFC.
        // (visual overflow is computed during their ::layout() call which we issue right before running inline layout in RenderBlockFlow::layoutModernLines)
        var firstTextBoxIndex: UInt64? = nil
        var lastTextBoxIndex: UInt64? = nil
        while boxIndex < boxes.count && boxes[Int(boxIndex)].lineIndex == lineIndex {
          let box = boxes[Int(boxIndex)]
          if box.isRootInlineBox() || box.isEllipsis() || box.isLineBreak() {
            boxIndex += 1
            continue
          }

          if box.isText() {
            inkOverflowRect.unite(other: box.inkOverflow)
            if box.isVisible() && box.text().renderedContent().length() != 0 {
              firstTextBoxIndex = firstTextBoxIndex ?? boxIndex
              lastTextBoxIndex = boxIndex
            }
            boxIndex += 1
            continue
          }

          if box.isAtomicInlineBox() {
            // TODO(asuhan): implement this
            fatalError("Not implemented")
          }

          if box.isInlineBox() {
            // TODO(asuhan): implement this
            fatalError("Not implemented")
          }

          boxIndex += 1
        }

        if firstTextBoxIndex != nil && lastTextBoxIndex != nil {
          // TODO(asuhan): implement this
          fatalError("Not implemented")
        }

        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }
    }

    private func adjustOverflowLogicalWidthWithBlockFlowQuirk(
      line: InlineDisplay.Line, isLeftToRightInlineDirection: Bool, isHorizontalWritingMode: Bool,
      scrollableOverflowRect: inout FloatRectWrapper
    ) {
      let scrollableOverflowLogicalWidth =
        isHorizontalWritingMode ? scrollableOverflowRect.width() : scrollableOverflowRect.height()
      if !isLeftToRightInlineDirection
        && line.contentLogicalWidth > scrollableOverflowLogicalWidth
      {
        // The only time when scrollable overflow here could be shorter than
        // the content width is when hanging RTL trailing content is applied (and ignored as scrollable overflow. See LineBoxBuilder::build.
        return
      }
      let adjustedOverflowLogicalWidth =
        line.contentLogicalWidth + endPaddingQuirkValue(flow: blockFlow)
      if adjustedOverflowLogicalWidth > scrollableOverflowLogicalWidth {
        let overflowValue = adjustedOverflowLogicalWidth - scrollableOverflowLogicalWidth
        if isHorizontalWritingMode {
          isLeftToRightInlineDirection
            ? scrollableOverflowRect.shiftMaxXEdgeBy(delta: overflowValue)
            : scrollableOverflowRect.shiftXEdgeBy(delta: -overflowValue)
        } else {
          // TODO(asuhan): implement this
          fatalError("Not implemented")
        }
      }
    }

    private func computeIsFirstIsLastBoxAndBidiReorderingForInlineContent(
      boxes: InlineDisplay.Boxes
    ) {
      if boxes.isEmpty {
        // Line clamp may produce a completely empty IFC.
        return
      }

      var lastDisplayBoxForLayoutBoxIndexes: [ObjectIdentifier: Int] = [:]

      assert(boxes[0].isRootInlineBox())
      boxes[0].isFirstForLayoutBox = true
      var lastRootInlineBoxIndex: Int = 0

      for index in 1..<boxes.count {
        let displayBox = boxes[index]
        if displayBox.isRootInlineBox() {
          lastRootInlineBoxIndex = index
          continue
        }
        let layoutBox = displayBox.layoutBox
        if layoutBox is InlineTextBoxWrapper && displayBox.bidiLevel == UBiDiLevel.UBIDI_DEFAULT_LTR
        {
          (layoutBox.rendererForIntegration() as! RenderTextWrapper).setNeedsVisualReordering()
        }

        if lastDisplayBoxForLayoutBoxIndexes.updateValue(index, forKey: ObjectIdentifier(layoutBox))
          == nil
        {
          displayBox.isFirstForLayoutBox = true
        }
      }
      for index in lastDisplayBoxForLayoutBoxIndexes.values {
        boxes[index].isLastForLayoutBox = true
      }

      boxes[lastRootInlineBoxIndex].isLastForLayoutBox = true
    }

    var blockFlow: RenderBlockFlowWrapper
    var boxTree: BoxTree
  }
}
