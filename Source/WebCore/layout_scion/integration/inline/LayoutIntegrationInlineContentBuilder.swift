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

private func bounds(textBox: InlineDisplay.Box, isLeading: Bool, isLeftToRightDirection: Bool)
  -> FloatRectWrapper
{
  let textContent = textBox.text().renderedContent()
  if textContent.length() == 0 {
    fatalError("Not reached")
  }
  let character = isLeading ? textContent[0] : textContent[textContent.length() - 1]
  let fontCascade = textBox.style().fontCascade()
  let glyphData = fontCascade.glyphDataForCharacter(
    c: UInt32(character), mirror: !isLeftToRightDirection)
  return (glyphData.font ?? fontCascade.primaryFont()).boundsForGlyph(glyph: glyphData.glyph)
}

private func leadingOverflow(
  firstTextBoxIndex: UInt64, boxes: InlineDisplay.Boxes, inkOverflowRect: FloatRectWrapper,
  isLeftToRightDirection: Bool
) -> Float32 {
  let firstTextBox = boxes[Int(firstTextBoxIndex)]
  assert(firstTextBox.isText())
  if (firstTextBox.layoutBox as! InlineTextBoxWrapper).canUseSimpleFontCodePath() {
    return 0
  }
  let boundsX = bounds(
    textBox: firstTextBox, isLeading: true, isLeftToRightDirection: isLeftToRightDirection
  ).x()
  if boundsX < 0 {
    return max(0, inkOverflowRect.x() - (firstTextBox.left() + boundsX))
  }
  return 0
}

private func trailingOverflow(
  lastTextBoxIndex: UInt64, boxes: InlineDisplay.Boxes, inkOverflowRect: FloatRectWrapper,
  isLeftToRightDirection: Bool
) -> Float32 {
  let lastTextBox = boxes[Int(lastTextBoxIndex)]
  assert(lastTextBox.isText())
  if (lastTextBox.layoutBox as! InlineTextBoxWrapper).canUseSimpleFontCodePath() {
    return 0
  }
  let boundsMaxX = bounds(
    textBox: lastTextBox, isLeading: false, isLeftToRightDirection: isLeftToRightDirection
  ).maxX()
  if boundsMaxX > lastTextBox.width() {
    return max(0, (lastTextBox.left() + boundsMaxX) - inkOverflowRect.maxX())
  }
  return 0
}

private func glyphOverflowInInlineDirection(
  firstTextBoxIndex: UInt64, lastTextBoxIndex: UInt64, boxes: InlineDisplay.Boxes,
  inkOverflowRect: FloatRectWrapper, isLeftToRightDirection: Bool
) -> (Float32, Float32) {
  // FIXME: This should be on the text box level and taking all characters into account (maybe consider utilizing the measuring pass if turns out to be a perf hit)
  if firstTextBoxIndex >= boxes.count || lastTextBoxIndex >= boxes.count {
    fatalError("Not reached")
  }

  return (
    leadingOverflow(
      firstTextBoxIndex: firstTextBoxIndex, boxes: boxes, inkOverflowRect: inkOverflowRect,
      isLeftToRightDirection: isLeftToRightDirection),
    trailingOverflow(
      lastTextBoxIndex: lastTextBoxIndex, boxes: boxes, inkOverflowRect: inkOverflowRect,
      isLeftToRightDirection: isLeftToRightDirection)
  )
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

      // Handle partial display content update.
      let firstDamagedLineIndex = InlineContentBuilder.firstDamagedLineIndex(
        layoutResult: layoutResult, inlineContent: inlineContent, lineDamage: lineDamage)

      let firstDamagedBoxIndex = InlineContentBuilder.firstDamagedBoxIndex(
        inlineContent: inlineContent, firstDamagedLineIndex: firstDamagedLineIndex)

      let numberOfDamagedLines = InlineContentBuilder.numberOfDamagedLines(
        layoutResult: layoutResult, inlineContent: inlineContent,
        firstDamagedLineIndex: firstDamagedLineIndex)

      let numberOfDamagedBoxes = InlineContentBuilder.numberOfDamagedBoxes(
        inlineContent: inlineContent,
        firstDamagedLineIndex: firstDamagedLineIndex,
        firstDamagedBoxIndex: firstDamagedBoxIndex,
        numberOfDamagedLines: numberOfDamagedLines)

      if firstDamagedLineIndex == nil || numberOfDamagedLines == nil || firstDamagedBoxIndex == nil
        || numberOfDamagedBoxes == nil
      {
        fatalError("Not reached")
      }

      let numberOfNewLines = UInt64(layoutResult.displayContent.lines.count)
      let numberOfNewBoxes = UInt64(layoutResult.displayContent.boxes.count)

      var damagedRect = FloatRectWrapper()

      // Repaint the damaged content boundary.
      InlineContentBuilder.adjustDamagedRectWithLineRange(
        inlineContent: inlineContent, firstLineIndex: firstDamagedLineIndex!,
        lineCount: numberOfDamagedLines!, damagedRect: &damagedRect)

      if layoutResult.range == .FullFromDamage {
        var displayContent = inlineContent.displayContent
        displayContent.remove(
          firstLineIndex: firstDamagedLineIndex!, numberOfLines: numberOfDamagedLines!,
          firstBoxIndex: firstDamagedBoxIndex!,
          numberOfBoxes: numberOfDamagedBoxes!)
        displayContent.append(newContent: layoutResult.displayContent)
      } else if layoutResult.range == .PartialFromDamage {
        var displayContent = inlineContent.displayContent
        displayContent.remove(
          firstLineIndex: firstDamagedLineIndex!, numberOfLines: numberOfDamagedLines!,
          firstBoxIndex: firstDamagedBoxIndex!,
          numberOfBoxes: numberOfDamagedBoxes!)
        displayContent.insert(
          newContent: layoutResult.displayContent, lineIndex: firstDamagedLineIndex!,
          boxIndex: firstDamagedBoxIndex!)

        InlineContentBuilder.adjustCachedBoxIndexesIfNeeded(
          displayContent: displayContent,
          firstDamagedLineIndex: firstDamagedLineIndex!, numberOfNewBoxes: numberOfNewBoxes,
          numberOfDamagedBoxes: numberOfDamagedBoxes!, numberOfDamagedLines: numberOfDamagedLines!)
      } else {
        fatalError("Not reached")
      }

      adjustDisplayLines(inlineContent: inlineContent, startIndex: firstDamagedLineIndex!)
      // Repaint the new content boundary.
      InlineContentBuilder.adjustDamagedRectWithLineRange(
        inlineContent: inlineContent, firstLineIndex: firstDamagedLineIndex!,
        lineCount: numberOfNewLines, damagedRect: &damagedRect)

      return damagedRect
    }

    private static func adjustCachedBoxIndexesIfNeeded(
      displayContent: InlineDisplay.Content, firstDamagedLineIndex: UInt64,
      numberOfNewBoxes: UInt64, numberOfDamagedBoxes: UInt64, numberOfDamagedLines: UInt64
    ) {
      if numberOfNewBoxes == numberOfDamagedBoxes {
        return
      }
      let firstCleanLineIndex = firstDamagedLineIndex + numberOfDamagedLines
      let offset = numberOfNewBoxes - numberOfDamagedBoxes
      let lines = displayContent.lines
      for line in lines[Int(firstCleanLineIndex)...] {
        let adjustedFirstBoxIndex = line.firstBoxIndex() + offset
        assert(adjustedFirstBoxIndex > 0)
        line.setFirstBoxIndex(firstBoxIndex: adjustedFirstBoxIndex)
      }
    }

    private static func firstDamagedLineIndex(
      layoutResult: InlineLayoutResult, inlineContent: InlineContent,
      lineDamage: InlineDamageWrapper?
    ) -> UInt64? {
      let displayContentFromPreviousLayout = inlineContent.displayContent
      if lineDamage == nil || lineDamage!.layoutStartPosition() == nil
        || displayContentFromPreviousLayout.lines.count == 0
      {
        return nil
      }
      let candidateLineIndex = lineDamage!.layoutStartPosition()!.lineIndex
      if candidateLineIndex >= displayContentFromPreviousLayout.lines.count {
        fatalError("Not reached")
      }
      if layoutResult.displayContent.boxes.count != 0
        && candidateLineIndex > layoutResult.displayContent.boxes[0].lineIndex
      {
        // We should never generate lines _before_ the damaged line.
        fatalError("Not reached")
      }
      return candidateLineIndex
    }

    private static func firstDamagedBoxIndex(
      inlineContent: InlineContent, firstDamagedLineIndex: UInt64?
    ) -> UInt64? {
      let displayContentFromPreviousLayout = inlineContent.displayContent
      if let firstDamagedLineIndex = firstDamagedLineIndex {
        return displayContentFromPreviousLayout.lines[Int(firstDamagedLineIndex)].firstBoxIndex()
      }
      return nil
    }

    private static func numberOfDamagedLines(
      layoutResult: InlineLayoutResult, inlineContent: InlineContent, firstDamagedLineIndex: UInt64?
    ) -> UInt64? {
      if firstDamagedLineIndex == nil {
        return nil
      }
      let displayContentFromPreviousLayout = inlineContent.displayContent
      assert(layoutResult.range != .Full)
      let candidateLineCount =
        layoutResult.range == .FullFromDamage
        ? UInt64(displayContentFromPreviousLayout.lines.count) - firstDamagedLineIndex!
        : UInt64(layoutResult.displayContent.lines.count)

      if firstDamagedLineIndex! + candidateLineCount > displayContentFromPreviousLayout.lines.count
      {
        fatalError("Not reached")
      }
      return candidateLineCount
    }

    private static func numberOfDamagedBoxes(
      inlineContent: InlineContent, firstDamagedLineIndex: UInt64?, firstDamagedBoxIndex: UInt64?,
      numberOfDamagedLines: UInt64?
    ) -> UInt64? {
      if firstDamagedLineIndex == nil || numberOfDamagedLines == nil || firstDamagedBoxIndex == nil
      {
        return nil
      }
      let displayContentFromPreviousLayout = inlineContent.displayContent
      assert(
        firstDamagedLineIndex! + numberOfDamagedLines!
          <= displayContentFromPreviousLayout.lines.count)
      var boxCount: UInt64 = 0
      for i in 0..<numberOfDamagedLines! {
        boxCount += displayContentFromPreviousLayout.lines[Int(firstDamagedLineIndex! + i)]
          .boxCount()
      }
      assert(boxCount != 0)
      return boxCount
    }

    private static func adjustDamagedRectWithLineRange(
      inlineContent: InlineContent, firstLineIndex: UInt64, lineCount: UInt64,
      damagedRect: inout FloatRectWrapper
    ) {
      let lines = inlineContent.displayContent.lines
      assert(firstLineIndex + lineCount <= lines.count)
      for i in 0..<lineCount {
        damagedRect.unite(other: lines[Int(firstLineIndex + i)].inkOverflow)
      }
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

        let firstBoxIndex = boxIndex
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
            let renderer = box.layoutBox.rendererForIntegration() as! RenderBoxWrapper
            if !renderer.hasSelfPaintingLayer() {
              var childInkOverflow = renderer.logicalVisualOverflowRectForPropagation(
                style: renderer.parent()!.style())
              childInkOverflow.move(dx: box.left(), dy: box.top())
              inkOverflowRect.unite(other: childInkOverflow.FloatRect())
            }
            var childScrollableOverflow = renderer.layoutOverflowRectForPropagation(
              style: renderer.parent()!.style())
            childScrollableOverflow.move(dx: box.left(), dy: box.top())
            scrollableOverflowRect.unite(other: childScrollableOverflow.FloatRect())
            boxIndex += 1
            continue
          }

          if box.isInlineBox() {
            if !(box.layoutBox.rendererForIntegration() as! RenderElementWrapper)
              .hasSelfPaintingLayer()
            {
              inkOverflowRect.unite(other: box.inkOverflow)
            }
          }

          boxIndex += 1
        }

        if firstTextBoxIndex != nil && lastTextBoxIndex != nil {
          let (leadingOverflow, trailingOverflow) = glyphOverflowInInlineDirection(
            firstTextBoxIndex: firstTextBoxIndex!, lastTextBoxIndex: lastTextBoxIndex!,
            boxes: boxes,
            inkOverflowRect: inkOverflowRect,
            isLeftToRightDirection: line.isLeftToRightInlineDirection())
          inkOverflowRect.inflate(
            deltaX: leadingOverflow, deltaY: 0, deltaMaxX: trailingOverflow, deltaMaxY: 0)
        }

        line.setScrollableOverflow(scrollableOverflow: scrollableOverflowRect)
        line.setInkOverflow(inkOverflowRect: inkOverflowRect)
        line.setFirstBoxIndex(firstBoxIndex: firstBoxIndex)
        line.setBoxCount(boxCount: boxIndex - firstBoxIndex)

        if lineIndex != 0 {
          let lastInkOverflow = lines[Int(lineIndex - 1)].inkOverflow
          if inkOverflowRect.y() <= lastInkOverflow.y()
            || lastInkOverflow.maxY() >= inkOverflowRect.maxY()
          {
            inlineContent.hasMultilinePaintOverlap = true
          }
        }
        if !inlineContent.hasVisualOverflow && inkOverflowRect != scrollableOverflowRect {
          inlineContent.setHasVisualOverflow()
        }
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
          isLeftToRightInlineDirection
            ? scrollableOverflowRect.shiftMaxYEdgeBy(delta: overflowValue)
            : scrollableOverflowRect.shiftYEdgeBy(delta: -overflowValue)
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
