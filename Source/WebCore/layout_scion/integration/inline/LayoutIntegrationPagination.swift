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

extension LayoutIntegration {
  static func computeFirstLineSnapAdjustment(
    line: InlineDisplay.Line, lineGrid: BlockLayoutState.LineGrid
  ) -> LayoutUnit {
    let gridLineHeight = lineGrid.rowHeight

    let gridFontMetrics = lineGrid.primaryFont!.fontMetrics()
    let lineGridFontAscent = gridFontMetrics.intAscent(baselineType: line.baselineType)
    let lineGridFontHeight = gridFontMetrics.intHeight()
    let lineGridHalfLeading = (gridLineHeight - lineGridFontHeight) / 2
    let firstLineTop = lineGrid.topRowOffset
    let firstTextTop = firstLineTop + lineGridHalfLeading
    let firstBaselinePosition = firstTextTop + lineGridFontAscent

    let baseline = LayoutUnit(value: line.baseline())
    return (lineGrid.paginationOrigin ?? LayoutSizeWrapper()).height() + firstBaselinePosition
      - baseline
  }

  static func computeAdjustmentsForPagination(
    inlineContent: InlineContent, placedFloats: PlacedFloats, allowLayoutRestart: Bool,
    blockLayoutState: BlockLayoutState, flow: RenderBlockFlowWrapper
  ) -> ([LineAdjustment], LayoutRestartLine?) {
    let lineCount = UInt64(inlineContent.displayContent.lines.count)
    var adjustments = [LineAdjustment](repeating: LineAdjustment(), count: Int(lineCount))

    var lineFloatBottomMap: [UInt64: LayoutUnit] = [:]
    for floatBox in placedFloats.list {
      if floatBox.layoutBox() == nil {
        continue
      }

      let renderer = floatBox.layoutBox()!.rendererForIntegration()! as! RenderBoxWrapper
      let isUnsplittable =
        renderer.isUnsplittableForPagination() || renderer.style().breakInside() == .Avoid

      let placedByLine = floatBox.placedByLine
      if placedByLine == 0 {
        if isUnsplittable {
          let rect = floatBox.absoluteRectWithMargin()
          flow.updateMinimumPageHeight(offset: rect.top(), minHeight: rect.height())
        }
        continue
      }

      let floatMinimumBottom = floatMinimumBottom(
        floatBox: floatBox, renderer: renderer, isUnsplittable: isUnsplittable)

      if lineFloatBottomMap[placedByLine!] == nil {
        lineFloatBottomMap[placedByLine!] = floatMinimumBottom
      } else {
        lineFloatBottomMap[placedByLine!] = max(
          floatMinimumBottom, lineFloatBottomMap[placedByLine!]!)
      }
    }

    var previousPageBreakIndex: UInt64? = nil
    var layoutRestartLine: LayoutRestartLine? = nil

    let widows = flow.style().hasAutoWidows() ? 0 : flow.style().widows()
    let orphans = flow.style().orphans()

    var accumulatedOffset = LayoutUnit(value: 0)
    var lineIndex: UInt64 = 0
    while lineIndex < lineCount {
      let line = InlineIterator.lineBoxFor(inlineContent: inlineContent, lineIndex: lineIndex)
      let floatMinimumBottom = lineFloatBottomMap[lineIndex] ?? LayoutUnit(value: 0)

      let adjustment = flow.computeLineAdjustmentForPagination(
        lineBox: line, delta: accumulatedOffset,
        floatMinimumBottom: floatMinimumBottom)
      if layoutRestartLine != nil && layoutRestartLine!.index == lineIndex {
        assert(!layoutRestartLine!.offset.bool())
        layoutRestartLine!.offset = adjustment.strut
      }

      if adjustment.isFirstAfterPageBreak {
        var remainingLines = lineCount - lineIndex
        // Ignore the last line if it is completely empty.
        if inlineContent.displayContent.lines.last!.lineBoxRect.isEmpty() {
          remainingLines -= 1
        }

        // See if there are enough lines left to meet the widow requirement.
        if remainingLines < widows && allowLayoutRestart && layoutRestartLine == nil {
          let previousPageLineCount = lineIndex - (previousPageBreakIndex ?? 0)
          let neededLines = UInt64(widows) - remainingLines
          let availableLines =
            previousPageLineCount > orphans ? previousPageLineCount - UInt64(orphans) : 0
          let linesToMove = min(neededLines, availableLines)
          if linesToMove != 0 {
            let breakIndex = lineIndex - linesToMove
            // Set the widow break and recompute the adjustments starting from that line.
            flow.setBreakAtLineToAvoidWidow(lineToBreak: Int(breakIndex + 1))
            lineIndex = breakIndex
            // We need to redo the layout starting from the break for things like intrusive floats.
            layoutRestartLine = LayoutRestartLine(index: breakIndex, offset: LayoutUnit())
            continue
          }
        }

        previousPageBreakIndex = lineIndex
      }

      accumulatedOffset += adjustment.strut

      if adjustment.isFirstAfterPageBreak {
        if lineIndex == 0 {
          accumulatedOffset += inlineContent.clearGapBeforeFirstLine
        }

        if flow.style().lineSnap() != .None && blockLayoutState.lineGrid != nil {
          accumulatedOffset += computeFirstLineSnapAdjustment(
            line: inlineContent.displayContent.lines[Int(lineIndex)],
            lineGrid: blockLayoutState.lineGrid!)
        }
      }

      adjustments[Int(lineIndex)] = LineAdjustment(
        offset: accumulatedOffset, isFirstAfterPageBreak: adjustment.isFirstAfterPageBreak)

      lineIndex += 1
    }

    flow.clearDidBreakAtLineToAvoidWidow()

    if previousPageBreakIndex == nil {
      return ([], nil)
    }

    return (adjustments, layoutRestartLine)
  }

  static func floatMinimumBottom(
    floatBox: PlacedFloats.Item, renderer: RenderBoxWrapper, isUnsplittable: Bool
  ) -> LayoutUnit {
    if isUnsplittable {
      return floatBox.absoluteRectWithMargin().bottom()
    }

    if let block = renderer as? RenderBlockFlowWrapper {
      if let firstLine = InlineIterator.firstLineBoxFor(flow: block).next() {
        return LayoutUnit(value: firstLine.logicalBottom())
      }
    }
    return LayoutUnit(value: 0)
  }

  static func adjustLinePositionsForPagination(
    inlineContent: inout InlineContent, adjustments: [LineAdjustment]
  ) {
    if adjustments.isEmpty {
      return
    }

    let writingMode = inlineContent.formattingContextRoot().style().writingMode()
    let isHorizontalWritingMode = isHorizontalWritingMode(writingMode: writingMode)

    let displayContent = inlineContent.displayContent
    for (lineIndex, line) in displayContent.lines.enumerated() {
      let adjustment = adjustments[lineIndex]
      line.moveInBlockDirection(
        offset: adjustment.offset.float(), isHorizontalWritingMode: isHorizontalWritingMode)
      if adjustment.isFirstAfterPageBreak {
        line.setIsFirstAfterPageBreak()
      }
    }
    for box in displayContent.boxes {
      let offset = adjustments[Int(box.lineIndex)].offset
      if isHorizontalWritingMode {
        box.moveVertically(offset: offset.float())
      } else {
        box.moveHorizontally(offset: offset.float())
      }
    }

    inlineContent.isPaginated = true
    inlineContent.firstLinePaginationOffset = adjustments[0].offset.float()
  }

  struct LineAdjustment {
    var offset = LayoutUnit(value: 0)
    var isFirstAfterPageBreak = false
  }

  struct LayoutRestartLine {
    var index: UInt64 = 0
    var offset = LayoutUnit()
  }
}
