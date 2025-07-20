/*
 * Copyright (C) 2019 Apple Inc. All rights reserved.
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
  class InlineContent {
    init(lineLayout: LayoutIntegration.LineLayout) {
      self.lineLayout = lineLayout
    }

    func hasContent() -> Bool {
      assert(displayContent.boxes.isEmpty || displayContent.boxes[0].isRootInlineBox())
      return displayContent.boxes.count > 1
    }

    func setHasVisualOverflow() { hasVisualOverflow = true }

    func boxesForRect(rect: LayoutRectWrapper) -> ArraySlice<InlineDisplay.Box> {
      if displayContent.boxes.isEmpty {
        return [][...]
      }

      let lines = displayContent.lines[...]
      let boxes = displayContent.boxes[...]

      // FIXME: Do the flips.
      if formattingContextRoot().style().isFlippedBlocksWritingMode() {
        return boxes[...]
      }

      if lines.first!.inkOverflow.maxY() > rect.y()
        && lines.last!.inkOverflow.y() < rect.maxY()
      {
        return boxes[...]
      }

      // The optimization below relies on line paint bounds not exeeding those of the neighboring lines
      if hasMultilinePaintOverlap {
        return boxes[...]
      }

      let height = lines.last!.lineBoxBottom() - lines.first!.lineBoxTop()
      let averageLineHeight = height / Float32(lines.count)

      var startLine = InlineContent.approximateLine(
        y: rect.y(), averageLineHeight: averageLineHeight, lines: lines)
      while startLine != 0 {
        if lines[Int(startLine - 1)].inkOverflow.maxY() < rect.y() {
          break
        }
        startLine -= 1
      }

      var endLine = InlineContent.approximateLine(
        y: rect.maxY(), averageLineHeight: averageLineHeight, lines: lines)
      while endLine < lines.count - 1 {
        if lines[Int(endLine + 1)].inkOverflow.y() > rect.maxY() {
          break
        }
        endLine += 1
      }

      let firstBox = lines[Int(startLine)].firstBoxIndex()
      let lastBox = lines[Int(endLine)].firstBoxIndex() + lines[Int(endLine)].boxCount() - 1

      return boxes[Int(firstBox)...Int(lastBox)]
    }

    private static func approximateLine(
      y: LayoutUnit, averageLineHeight: Float32, lines: ArraySlice<InlineDisplay.Line>
    ) -> UInt64 {
      return UInt64(min(Int(max(y, LayoutUnit(value: 0)) / averageLineHeight), lines.count - 1))
    }

    func shrinkToFit() {
      // TODO(asuhan): implement this
    }

    func formattingContextRoot() -> RenderBlockFlowWrapper {
      return lineLayout!.flow()
    }

    func indexForBox(box: InlineDisplay.Box) -> UInt64 {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func firstBoxForLayoutBox(layoutBox: BoxWrapper) -> InlineDisplay.Box? {
      if let index = firstBoxIndexForLayoutBox(layoutBox: layoutBox) {
        return displayContent.boxes[Int(index)]
      }
      return nil
    }

    func traverseNonRootInlineBoxes(
      layoutBox: BoxWrapper, function: (_ inlineBox: InlineDisplay.Box) -> Void
    ) {
      for index in nonRootInlineBoxIndexesForLayoutBox(layoutBox: layoutBox) {
        function(displayContent.boxes[Int(index)])
      }
    }

    func firstBoxIndexForLayoutBox(layoutBox: BoxWrapper) -> UInt64? {
      let boxes = displayContent.boxes

      if boxes.count < InlineContent.cacheThreshold {
        for (i, box) in boxes.enumerated() {
          if CPtrToInt(box.layoutBox.p) == CPtrToInt(layoutBox.p) {
            return UInt64(i)
          }
        }
        return nil
      }

      if firstBoxIndexCache == nil {
        firstBoxIndexCache = [:]
        for (i, box) in boxes.enumerated() {
          if box.isRootInlineBox() {
            continue
          }
          let replacedValue = firstBoxIndexCache!.updateValue(
            UInt64(i), forKey: CPtrToInt(box.layoutBox.p))
          assert(replacedValue == nil)
        }
      }

      return firstBoxIndexCache![CPtrToInt(layoutBox.p)]
    }

    func nonRootInlineBoxIndexesForLayoutBox(layoutBox: BoxWrapper) -> ArraySlice<UInt64> {
      assert(layoutBox.isElementBox())

      if inlineBoxIndexCache == nil {
        inlineBoxIndexCache = [:]
        for (i, box) in displayContent.boxes.enumerated() {
          if !box.isNonRootInlineBox() {
            continue
          }
          let layoutBoxKey = CPtrToInt(box.layoutBox.p)
          if var indices = inlineBoxIndexCache![layoutBoxKey] {
            indices.append(UInt64(i))
          } else {
            inlineBoxIndexCache![layoutBoxKey] = [UInt64(i)]
          }
        }
      }

      if let indices = inlineBoxIndexCache![CPtrToInt(layoutBox.p)] {
        return indices
      }

      return InlineContent.emptyUInt64Slice
    }

    func releaseCaches() {
      firstBoxIndexCache = nil
      inlineBoxIndexCache = nil
    }

    var clearGapBeforeFirstLine: Float32 = 0
    var clearGapAfterLastLine: Float32 = 0
    var firstLinePaginationOffset: Float32 = 0

    var isPaginated = false
    var hasMultilinePaintOverlap = false

    var displayContent = InlineDisplay.Content()
    private var firstBoxIndexCache: [UInt: UInt64]? = nil
    private var inlineBoxIndexCache: [UInt: ArraySlice<UInt64>]? = nil
    private static let emptyUInt64Slice: ArraySlice<UInt64> = [][...]
    private static let cacheThreshold = 16

    private var lineLayout: LayoutIntegration.LineLayout? = nil
    var hasVisualOverflow = false
  }
}
