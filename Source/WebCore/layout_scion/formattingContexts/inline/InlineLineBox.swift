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

//   ____________________________________________________________ Line Box
// |                                    --------------------
// |                                   |                    |
// | ----------------------------------|--------------------|---------- Root Inline Box
// ||   _____    ___      ___          |                    |
// ||  |        /   \    /   \         |  Inline Level Box  |
// ||  |_____  |     |  |     |        |                    |    ascent
// ||  |       |     |  |     |        |                    |
// ||__|________\___/____\___/_________|____________________|_______ alignment_baseline
// ||
// ||                                                      descent
// ||_______________________________________________________________
// |________________________________________________________________
// The resulting rectangular area that contains the boxes that form a single line of inline-level content is called a line box.
// https://www.w3.org/TR/css-inline-3/#model
struct LineBox {
  init(
    rootLayoutBox: BoxWrapper, contentLogicalLeft: InlineLayoutUnit,
    contentLogicalWidth: InlineLayoutUnit, lineIndex: UInt64, nonSpanningInlineLevelBoxCount: UInt64
  ) {
    self.lineIndex = lineIndex
    self.rootInlineBox = InlineLevelBox.createRootInlineBox(
      layoutBox: rootLayoutBox,
      style: lineIndex == 0 ? rootLayoutBox.firstLineStyle() : rootLayoutBox.style,
      logicalLeft: contentLogicalLeft, logicalWidth: contentLogicalWidth)
    rootInlineBox.setTextEmphasis(
      textEmphasis: InlineFormattingUtils.textEmphasisForInlineBox(
        layoutBox: rootLayoutBox, rootBox: rootLayoutBox as! ElementBoxWrapper))
  }

  func hasAtomicInlineBox() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalRectForTextRun(run: Line.Run) -> InlineRect {
    assert(run.isText() || run.isSoftLineBreak())
    var ancestorInlineBox = parentInlineBox(lineRun: run)
    assert(ancestorInlineBox.isInlineBox())
    var runlogicalTop =
      ancestorInlineBox.logicalTop() - ancestorInlineBox.inlineBoxContentOffsetForTextBoxTrim
    let logicalHeight = ancestorInlineBox.primarymetricsOfPrimaryFont().intHeight()

    while ObjectIdentifier(ancestorInlineBox) != ObjectIdentifier(rootInlineBox)
      && !ancestorInlineBox.hasLineBoxRelativeAlignment()
    {
      ancestorInlineBox = parentInlineBox(inlineLevelBox: ancestorInlineBox)
      assert(ancestorInlineBox.isInlineBox())
      runlogicalTop += ancestorInlineBox.logicalTop()
    }
    return InlineRect(
      top: runlogicalTop, left: rootInlineBox.logicalLeft() + run.logicalLeft,
      width: run.logicalWidth, height: InlineLayoutUnit(logicalHeight))
  }

  func logicalRectForLineBreakBox(layoutBox: BoxWrapper) -> InlineRect {
    assert(layoutBox.isLineBreakBox())
    return logicalRectForInlineLevelBox(layoutBox: layoutBox)
  }

  func logicalRectForRootInlineBox() -> InlineRect {
    return rootInlineBox.logicalRect
  }

  func logicalBorderBoxForAtomicInlineBox(layoutBox: BoxWrapper, boxGeometry: BoxGeometry)
    -> InlineRect
  {
    assert(layoutBox.isAtomicInlineBox())
    var logicalRect = logicalRectForInlineLevelBox(layoutBox: layoutBox)
    // Inline level boxes use their margin box for vertical alignment. Let's covert them to border boxes.
    logicalRect.moveVertically(offset: boxGeometry.marginBefore().float())
    let verticalMargin = boxGeometry.marginBefore() + boxGeometry.marginAfter()
    logicalRect.expandVertically(delta: -verticalMargin.float())

    return logicalRect
  }

  func logicalBorderBoxForInlineBox(layoutBox: BoxWrapper, boxGeometry: BoxGeometry) -> InlineRect {
    var logicalRect = logicalRectForInlineLevelBox(layoutBox: layoutBox)
    // This logical rect is as tall as the "text" content is. Let's adjust with vertical border and padding.
    logicalRect.expandVertically(delta: boxGeometry.verticalBorderAndPadding().float())
    logicalRect.moveVertically(offset: (-boxGeometry.borderAndPaddingBefore()).float())
    return logicalRect
  }

  func inlineLevelBoxFor(layoutBox: BoxWrapper) -> InlineLevelBox? {
    if CPtrToInt(layoutBox.p) == CPtrToInt(rootInlineBox.layoutBox.p) {
      return rootInlineBox
    }
    if let idx = nonRootInlineLevelBoxMap[CPtrToInt(layoutBox.p)] {
      return nonRootInlineLevelBoxList[idx]
    }
    return nil
  }

  func inlineLevelBoxFor(lineRun: Line.Run) -> InlineLevelBox {
    return inlineLevelBoxFor(layoutBox: lineRun.layoutBox)!
  }

  typealias InlineLevelBoxList = [InlineLevelBox]
  func nonRootInlineLevelBoxes() -> InlineLevelBoxList {
    return nonRootInlineLevelBoxList
  }

  struct `Type`: OptionSet {
    let rawValue: UInt8
    static let InlineBox = `Type`(rawValue: InlineLevelBox.Type_.InlineBox.rawValue)
    static let LineSpanningInlineBox = `Type`(
      rawValue: InlineLevelBox.Type_.LineSpanningInlineBox.rawValue)
    static let RootInlineBox = `Type`(rawValue: InlineLevelBox.Type_.RootInlineBox.rawValue)
    static let AtomicInlineBox = `Type`(rawValue: InlineLevelBox.Type_.AtomicInlineBox.rawValue)
    static let LineBreakBox = `Type`(rawValue: InlineLevelBox.Type_.LineBreakBox.rawValue)
    static let GenericInlineLevelBox = `Type`(
      rawValue: InlineLevelBox.Type_.GenericInlineLevelBox.rawValue)
  }

  mutating func addInlineLevelBox(inlineLevelBox: InlineLevelBox) {
    boxTypes.insert(`Type`(rawValue: inlineLevelBox.type.rawValue))
    nonRootInlineLevelBoxMap.updateValue(
      nonRootInlineLevelBoxList.count, forKey: CPtrToInt(inlineLevelBox.layoutBox.p))
    nonRootInlineLevelBoxList.append(inlineLevelBox)
  }

  func parentInlineBox(inlineLevelBox: InlineLevelBox) -> InlineLevelBox {
    return inlineLevelBoxFor(layoutBox: inlineLevelBox.layoutBox.parent())!
  }

  func parentInlineBox(lineRun: Line.Run) -> InlineLevelBox {
    return inlineLevelBoxFor(layoutBox: lineRun.layoutBox.parent())!
  }

  func logicalRectForInlineLevelBox(layoutBox: BoxWrapper) -> InlineRect {
    assert(layoutBox.isInlineLevelBox() || layoutBox.isLineBreakBox())
    if let inlineBox = inlineLevelBoxFor(layoutBox: layoutBox) {
      let inlineBoxLogicalRect = inlineBox.logicalRect
      return InlineRect(
        top: inlineLevelBoxAbsoluteTop(inlineLevelBox: inlineBox),
        left: inlineBoxLogicalRect.left(), width: inlineBoxLogicalRect.width(),
        height: inlineBoxLogicalRect.height())
    }
    fatalError("Not reached")
  }

  mutating func setLogicalRect(logicalRect: InlineRect) {
    self.logicalRect = logicalRect
  }

  mutating func setHasContent(hasContent: Bool) {
    self.hasContent = hasContent
  }

  mutating func setBaselineType(baselineType: FontBaseline) {
    self.baselineType = baselineType
  }

  func inlineLevelBoxAbsoluteTop(inlineLevelBox: InlineLevelBox) -> InlineLayoutUnit {
    // Inline level boxes are relative to their parent unless the vertical alignment makes them relative to the line box (e.g. top, bottom).
    var top = inlineLevelBox.logicalTop()
    if inlineLevelBox.isRootInlineBox() || inlineLevelBox.hasLineBoxRelativeAlignment() {
      return top
    }

    // Fast path for inline level boxes on the root inline box (e.g <div><img></div>).
    if CPtrToInt(inlineLevelBox.layoutBox.parent().p) == CPtrToInt(rootInlineBox.layoutBox.p) {
      return top + rootInlineBox.logicalTop()
    }

    // Nested inline content e.g <div><span><img></span></div>
    var ancestorInlineBox = inlineLevelBox
    while ancestorInlineBox !== rootInlineBox && !ancestorInlineBox.hasLineBoxRelativeAlignment() {
      ancestorInlineBox = parentInlineBox(inlineLevelBox: ancestorInlineBox)
      assert(ancestorInlineBox.isInlineBox())
      top += ancestorInlineBox.logicalTop()
    }
    return top
  }

  var lineIndex: UInt64 = 0
  var hasContent = false
  var logicalRect = InlineRect()
  private var boxTypes = `Type`()

  var baselineType: FontBaseline = .AlphabeticBaseline
  var rootInlineBox: InlineLevelBox
  var nonRootInlineLevelBoxList = InlineLevelBoxList()

  private var nonRootInlineLevelBoxMap: [UInt: Int] = [:]
}
