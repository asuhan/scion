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

func marginLeftInInlineDirection(boxGeometry: BoxGeometry, isLeftToRightDirection: Bool)
  -> LayoutUnit
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func marginRightInInlineDirection(boxGeometry: BoxGeometry, isLeftToRightDirection: Bool)
  -> LayoutUnit
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func borderLeftInInlineDirection(boxGeometry: BoxGeometry, isLeftToRightDirection: Bool)
  -> LayoutUnit
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func borderRightInInlineDirection(boxGeometry: BoxGeometry, isLeftToRightDirection: Bool)
  -> LayoutUnit
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func paddingLeftInInlineDirection(boxGeometry: BoxGeometry, isLeftToRightDirection: Bool)
  -> LayoutUnit
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func paddingRightInInlineDirection(boxGeometry: BoxGeometry, isLeftToRightDirection: Bool)
  -> LayoutUnit
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func isFirstLastBox(inlineBox: InlineLevelBox) -> InlineDisplay.Box.PositionWithinInlineLevelBox {
  var positionWithinInlineLevelBox = InlineDisplay.Box.PositionWithinInlineLevelBox()
  if inlineBox.isFirstBox() {
    positionWithinInlineLevelBox = positionWithinInlineLevelBox.union(.First)
  }
  if inlineBox.isLastBox() {
    positionWithinInlineLevelBox = positionWithinInlineLevelBox.union(.Last)
  }
  return positionWithinInlineLevelBox
}

func inflateWithOutline(
  style: RenderStyleWrapper, inkOverflow: inout FloatRectWrapper, hasVisualOverflow: inout Bool
) {
  if !style.hasOutlineInVisualOverflow() {
    return
  }
  inkOverflow.inflate(d: style.outlineSize())
  hasVisualOverflow = true
}

func inflateWithBoxShadow(
  style: RenderStyleWrapper, inkOverflow: inout FloatRectWrapper, hasVisualOverflow: inout Bool
) {
  var topBoxShadow = LayoutUnit()
  var bottomBoxShadow = LayoutUnit()
  style.getBoxShadowVerticalExtent(top: &topBoxShadow, bottom: &bottomBoxShadow)

  var leftBoxShadow = LayoutUnit()
  var rightBoxShadow = LayoutUnit()
  style.getBoxShadowHorizontalExtent(left: &leftBoxShadow, right: &rightBoxShadow)
  if !topBoxShadow.bool() && !bottomBoxShadow.bool() && !leftBoxShadow.bool()
    && !rightBoxShadow.bool()
  {
    return
  }
  inkOverflow.inflate(
    deltaX: -leftBoxShadow.toFloat(), deltaY: -topBoxShadow.toFloat(),
    deltaMaxX: rightBoxShadow.toFloat(),
    deltaMaxY: bottomBoxShadow.toFloat())
  hasVisualOverflow = true
}

@discardableResult
func computeInkOverflowForInlineLevelBox(
  style: RenderStyleWrapper, inkOverflow: inout FloatRectWrapper
)
  -> Bool
{
  var hasVisualOverflow = false

  inflateWithOutline(style: style, inkOverflow: &inkOverflow, hasVisualOverflow: &hasVisualOverflow)

  inflateWithBoxShadow(
    style: style, inkOverflow: &inkOverflow, hasVisualOverflow: &hasVisualOverflow)

  return hasVisualOverflow
}

func inflateWithAnnotation(
  inlineBox: InlineLevelBox, inkOverflow: inout FloatRectWrapper, hasVisualOverflow: inout Bool
) {
  if !inlineBox.hasTextEmphasis() {
    return
  }
  inkOverflow.inflate(
    deltaX: 0, deltaY: inlineBox.textEmphasisAbove() ?? 0, deltaMaxX: 0,
    deltaMaxY: inlineBox.textEmphasisBelow() ?? 0)
  hasVisualOverflow = true
}

func computeInkOverflowForInlineBox(
  inlineBox: InlineLevelBox, style: RenderStyleWrapper, inkOverflow: inout FloatRectWrapper
) -> Bool {
  assert(inlineBox.isInlineBox())
  var hasVisualOverflow = computeInkOverflowForInlineLevelBox(
    style: style, inkOverflow: &inkOverflow)

  inflateWithAnnotation(
    inlineBox: inlineBox, inkOverflow: &inkOverflow, hasVisualOverflow: &hasVisualOverflow)

  return hasVisualOverflow
}

@discardableResult
func createDisplayBoxNodeForContainerAndPushToAncestorStack(
  elementBox: ElementBoxWrapper, displayBoxIndex: UInt64, parentDisplayBoxNodeIndex: UInt64,
  displayBoxTree: DisplayBoxTree, ancestorStack: AncestorStack
) -> UInt64 {
  let displayBoxNodeIndex = displayBoxTree.append(
    parentNodeIndex: parentDisplayBoxNodeIndex, childDisplayBoxIndex: displayBoxIndex)
  ancestorStack.push(displayBoxNodeIndexForContainer: displayBoxNodeIndex, elementBox: elementBox)
  return displayBoxNodeIndex
}

struct DisplayBoxTree {
  struct Node {
    // Associated display box index in DisplayBoxes.
    var displayBoxIndex: UInt64 = 0
    // Child indexes in displayBoxNodes.
    var children: [UInt64] = []
  }

  func root() -> Node {
    return displayBoxNodes.first!
  }

  func at(index: UInt64) -> Node {
    return displayBoxNodes[Int(index)]
  }

  @discardableResult
  func append(parentNodeIndex: UInt64, childDisplayBoxIndex: UInt64) -> UInt64 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var displayBoxNodes: [Node] = []
}

struct AncestorStack {
  func unwind(elementBox: ElementBoxWrapper) -> UInt64? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func push(displayBoxNodeIndexForContainer: UInt64, elementBox: ElementBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

struct IsFirstLastIndex {
  var first: UInt64? = nil
  var last: UInt64? = nil
}

typealias IsFirstLastIndexesMap = [BoxWrapper: IsFirstLastIndex]

func outOfFlowBox(
  i: UInt64, indexListOfOutOfFlowBoxes: [UInt64], lineRuns: Line.RunList, visualOrderList: [Int32],
  isLeftToRightDirection: Bool
)
  -> BoxWrapper
{
  let outOfFlowBoxListSize = UInt64(indexListOfOutOfFlowBoxes.count)
  let outOfFlowRunIndex = indexListOfOutOfFlowBoxes[
    Int(
      InlineDisplayContentBuilder.runIndex(
        i: i, listSize: outOfFlowBoxListSize, isLeftToRightDirection: isLeftToRightDirection))]
  return
    (visualOrderList.isEmpty
    ? lineRuns[Int(outOfFlowRunIndex)] : lineRuns[Int(visualOrderList[Int(outOfFlowRunIndex)])])
    .layoutBox
}

internal func setGeometryForOutOfFlowBoxes(
  indexListOfOutOfFlowBoxes: [UInt64], firstOutOfFlowIndexWithPreviousInflowSibling: UInt64?,
  lineRuns: Line.RunList, visualOrderList: [Int32], formattingContext: InlineFormattingContext,
  lineBox: LineBox, constraints: ConstraintsForInlineContent
) {
  let isLeftToRightDirection = formattingContext.root().style.isLeftToRightDirection()
  let outOfFlowBoxListSize = UInt64(indexListOfOutOfFlowBoxes.count)

  // Set geometry on "before inflow content" boxes first, followed by the "after inflow content" list.
  let beforeAfterBoundary = firstOutOfFlowIndexWithPreviousInflowSibling ?? outOfFlowBoxListSize
  // These out of flow boxes "sit" on the line start (they are before any inflow content e.g. <div><div class=out-of-flow></div>some text<div>)
  var logicalTopLeft = LayoutPointWrapper(
    x: constraints.horizontal.logicalLeft, y: LayoutUnit(value: lineBox.logicalRect.top()))
  for i in 0..<beforeAfterBoundary {
    formattingContext.geometryForBox(
      layoutBox: outOfFlowBox(
        i: i, indexListOfOutOfFlowBoxes: indexListOfOutOfFlowBoxes, lineRuns: lineRuns,
        visualOrderList: visualOrderList,
        isLeftToRightDirection: isLeftToRightDirection)
    ).setTopLeft(topLeft: logicalTopLeft)
  }
  // These out of flow boxes are all _after_ an inflow content and get "wrapped" to the next line.
  logicalTopLeft.setY(y: LayoutUnit(value: lineBox.logicalRect.bottom()))
  for i in beforeAfterBoundary..<outOfFlowBoxListSize {
    formattingContext.geometryForBox(
      layoutBox: outOfFlowBox(
        i: i, indexListOfOutOfFlowBoxes: indexListOfOutOfFlowBoxes, lineRuns: lineRuns,
        visualOrderList: visualOrderList,
        isLeftToRightDirection: isLeftToRightDirection)
    ).setTopLeft(topLeft: logicalTopLeft)
  }
}

func logicalBottomForTextDecorationContent(
  boxes: InlineDisplay.Boxes, isHorizontalWritingMode: Bool
) -> Float32 {
  var logicalBottom: Float32? = nil
  for displayBox in boxes {
    if displayBox.isRootInlineBox() {
      continue
    }
    if !displayBox.style().textDecorationsInEffect().contains(.Underline) {
      continue
    }
    if displayBox.isText() || displayBox.style().textDecorationSkipInk() == .None {
      let contentLogicalBottom = isHorizontalWritingMode ? displayBox.bottom() : displayBox.right()
      logicalBottom =
        logicalBottom != nil ? max(logicalBottom!, contentLogicalBottom) : contentLogicalBottom
    }
  }
  // This function is not called unless there's at least one run on the line with TextDecorationLine::Underline.
  assert(logicalBottom != nil)
  return logicalBottom ?? 0
}

struct InlineDisplayContentBuilder {
  static func runIndex(i: UInt64, listSize: UInt64, isLeftToRightDirection: Bool) -> UInt64 {
    if isLeftToRightDirection {
      return i
    }
    let lastIndex = listSize - 1
    return lastIndex - i
  }

  init(
    formattingContext: InlineFormattingContext, constraints: ConstraintsForInlineContent,
    lineBox: LineBox, displayLine: InlineDisplay.Line
  ) {
    self.formattingContext = formattingContext
    self.constraints = constraints
    self.lineBox = lineBox
    self.displayLine = displayLine
    let initialContainingBlockGeometry = formattingContext.geometryForBox(
      layoutBox: FormattingContext.initialContainingBlock(layoutBox: root()),
      escapeReason: .InkOverflowNeedsInitialContiningBlockForStrokeWidth)
    initialContaingBlockSize = ceiledIntSize(
      s: LayoutSizeWrapper(
        width: initialContainingBlockGeometry.contentBoxWidth(),
        height: initialContainingBlockGeometry.contentBoxHeight()))
  }

  mutating func build(lineLayoutResult: LineLayoutResult) -> InlineDisplay.Boxes {
    var boxes = InlineDisplay.Boxes()
    boxes.reserveCapacity(
      lineLayoutResult.inlineContent.count + lineBox.nonRootInlineLevelBoxes().count + 1)

    let contentNeedsBidiReordering = !lineLayoutResult.directionality.visualOrderList.isEmpty
    if contentNeedsBidiReordering {
      processBidiContent(lineLayoutResult: lineLayoutResult, boxes: &boxes)
    } else {
      processNonBidiContent(lineLayoutResult: lineLayoutResult, boxes: &boxes)
    }
    processRubyContent(displayBoxes: boxes, lineLayoutResult: lineLayoutResult)

    collectInkOverflowForTextDecorations(boxes: boxes)
    collectInkOverflowForInlineBoxes(boxes: boxes)
    return boxes
  }

  private mutating func processNonBidiContent(
    lineLayoutResult: LineLayoutResult, boxes: inout InlineDisplay.Boxes
  ) {
    var hasContent = false
    for lineRun in lineLayoutResult.inlineContent {
      hasContent = hasContent || lineRun.isContentful()
    }
    assert(lineLayoutResult.directionality.inlineBaseDirection == .LTR || !hasContent)
    let writingMode = root().style.writingMode()
    let contentStartInVisualOrder = displayLine.topLeft()
    var blockLevelOutOfFlowBoxList: [UInt64] = []
    appendRootInlineBoxDisplayBox(
      rootInlineBoxVisualRect: flipRootInlineBoxRectToVisualForWritingMode(
        rootInlineBoxLogicalRect: lineBox.logicalRectForRootInlineBox(), writingMode: writingMode),
      lineHasContent: lineBox.rootInlineBox.hasContent, boxes: &boxes)

    for (index, lineRun) in lineLayoutResult.inlineContent.enumerated() {
      if lineRun.isWordBreakOpportunity() || lineRun.isInlineBoxEnd() {
        continue
      }
      let layoutBox = lineRun.layoutBox

      if lineRun.isOpaque() {
        if layoutBox.style.isOriginalDisplayInlineType() {
          formattingContext.geometryForBox(layoutBox: layoutBox).setTopLeft(
            topLeft:
              LayoutPointWrapper(
                x: LayoutUnit(
                  value: lineBox.logicalRect.left() + lineBox.logicalRectForRootInlineBox().left()
                    + lineRun.logicalLeft),
                y: LayoutUnit(value: lineBox.logicalRect.top())
              ))
          continue
        }
        blockLevelOutOfFlowBoxList.append(UInt64(index))
        continue
      }

      let logicalRect = logicalRectNonBidi(lineRun: lineRun)
      let visualRectRelativeToRoot = visualRectRelativeToRootNonBidi(
        logicalRect: logicalRect, writingMode: writingMode,
        contentStartInVisualOrder: contentStartInVisualOrder)
      createDisplayBoxForRun(
        lineRun: lineRun, boxes: &boxes, visualRectRelativeToRoot: visualRectRelativeToRoot)
      updateAssociatedBoxGeometry(lineRun: lineRun, logicalRect: logicalRect)
    }
    setGeometryForBlockLevelOutOfFlowBoxes(
      indexListOfOutOfFlowBoxes: blockLevelOutOfFlowBoxList,
      lineRuns: lineLayoutResult.inlineContent)
  }

  private func logicalRectNonBidi(lineRun: Line.Run) -> InlineRect {
    let layoutBox = lineRun.layoutBox
    if lineRun.isText() || lineRun.isSoftLineBreak() {
      return lineBox.logicalRectForTextRun(run: lineRun)
    }
    if lineRun.isHardLineBreak() {
      return lineBox.logicalRectForLineBreakBox(layoutBox: layoutBox)
    }

    let boxGeometry = formattingContext.geometryForBox(layoutBox: layoutBox)
    if lineRun.isAtomicInlineBox() || lineRun.isListMarker() {
      return lineBox.logicalBorderBoxForAtomicInlineBox(
        layoutBox: layoutBox, boxGeometry: boxGeometry)
    }
    if lineRun.isInlineBoxStart() || lineRun.isLineSpanningInlineBoxStart() {
      return lineBox.logicalBorderBoxForInlineBox(layoutBox: layoutBox, boxGeometry: boxGeometry)
    }
    fatalError("Not reached")
  }

  private mutating func createDisplayBoxForRun(
    lineRun: Line.Run, boxes: inout InlineDisplay.Boxes, visualRectRelativeToRoot: InlineRect
  ) {
    if lineRun.isText() {
      appendTextDisplayBox(lineRun: lineRun, textRunRect: visualRectRelativeToRoot, boxes: &boxes)
    } else if lineRun.isSoftLineBreak() {
      appendSoftLineBreakDisplayBox(
        lineRun: lineRun, softLineBreakRunRect: visualRectRelativeToRoot, boxes: &boxes)
    } else if lineRun.isHardLineBreak() {
      appendHardLineBreakDisplayBox(
        lineRun: lineRun, lineBreakBoxRect: visualRectRelativeToRoot, boxes: &boxes)
    } else if lineRun.isAtomicInlineBox() || lineRun.isListMarker() {
      appendAtomicInlineLevelDisplayBox(
        lineRun: lineRun, borderBoxRect: visualRectRelativeToRoot, boxes: &boxes)
    } else if lineRun.isInlineBoxStart() || lineRun.isLineSpanningInlineBoxStart() {
      // Do not generate display boxes for inline boxes on non-contentful lines (e.g. <span></span>)
      if lineBox.hasContent {
        appendInlineBoxDisplayBox(
          lineRun: lineRun, inlineBox: lineBox.inlineLevelBoxFor(lineRun: lineRun),
          inlineBoxBorderBox: visualRectRelativeToRoot, boxes: &boxes)
      }
    } else {
      fatalError("Not reached")
    }
  }

  private func updateAssociatedBoxGeometry(lineRun: Line.Run, logicalRect: InlineRect) {
    if lineRun.isText() || lineRun.isSoftLineBreak() {
      return
    }
    if !lineBox.hasContent && lineRun.isLineSpanningInlineBoxStart() {
      // When a spanning inline box (e.g. <div>text<span><br></span></div>) lands on an empty line
      // (empty here means no content at all including line breaks, not just visually empty) then we
      // don't extend the spanning line box over to this line.
      return
    }
    let boxGeometry = formattingContext.geometryForBox(layoutBox: lineRun.layoutBox)
    let borderBoxLogicalTopLeft = toLayoutPoint(
      point: lineBox.logicalRect.topLeft() + logicalRect.topLeft())
    if lineRun.isInlineBoxStart() || lineRun.isLineSpanningInlineBoxStart() {
      // Inline boxes need special (stretchy) box geometry handling.
      setInlineBoxGeometry(
        boxGeometry: boxGeometry,
        logicalRect: InlineRect(
          topLeft: borderBoxLogicalTopLeft.FloatPoint(), size: logicalRect.size()),
        isFirstInlineBoxFragment: lineBox.inlineLevelBoxFor(lineRun: lineRun).isFirstBox())
      return
    }
    boxGeometry.setTopLeft(topLeft: borderBoxLogicalTopLeft)
    boxGeometry.setContentBoxSize(
      size: LayoutSizeWrapper(
        width: logicalRect.width() - boxGeometry.horizontalBorderAndPadding(),
        height: logicalRect.height() - boxGeometry.verticalBorderAndPadding()))
  }

  private mutating func processBidiContent(
    lineLayoutResult: LineLayoutResult, boxes: inout InlineDisplay.Boxes
  ) {
    assert(
      lineLayoutResult.directionality.visualOrderList.count <= lineLayoutResult.inlineContent.count)

    let ancestorStack = AncestorStack()
    let displayBoxTree = DisplayBoxTree()
    ancestorStack.push(displayBoxNodeIndexForContainer: 0, elementBox: root())

    let writingMode = root().style.writingMode()
    let isHorizontalWritingMode = isHorizontalWritingMode(writingMode: writingMode)

    let lineLogicalTop = isHorizontalWritingMode ? displayLine.top() : displayLine.left()
    let lineLogicalLeft = isHorizontalWritingMode ? displayLine.left() : displayLine.top()
    // Note that hangable punctuation does not contribute to contentLogicalLeftIgnoringInlineDirection() as it is considered more of an overflow.
    let contentStartInInlineDirectionVisualOrder =
      lineLogicalLeft + displayLine.contentLogicalLeftIgnoringInlineDirection
      - (rootStyle().isLeftToRightDirection()
        ? lineLayoutResult.hangingContent.hangablePunctuationStartWidth : 0)
    var hasInlineBox = false
    createDisplayBoxesInVisualOrder(
      lineLayoutResult: lineLayoutResult,
      boxes: &boxes,
      contentStartInInlineDirectionVisualOrder: contentStartInInlineDirectionVisualOrder,
      lineLogicalTop: lineLogicalTop,
      lineLogicalLeft: lineLogicalLeft,
      displayBoxTree: displayBoxTree,
      ancestorStack: ancestorStack,
      writingMode: writingMode,
      isHorizontalWritingMode: isHorizontalWritingMode,
      hasInlineBox: &hasInlineBox)

    handleInlineBoxes(
      boxes: boxes, displayBoxTree: displayBoxTree, lineLogicalTop: lineLogicalTop,
      contentStartInInlineDirectionVisualOrder: contentStartInInlineDirectionVisualOrder,
      hasInlineBox: hasInlineBox)

    handleTrailingOpenInlineBoxes(lineLayoutResult: lineLayoutResult, boxes: &boxes)
  }

  private mutating func createDisplayBoxesInVisualOrder(
    lineLayoutResult: LineLayoutResult, boxes: inout InlineDisplay.Boxes,
    contentStartInInlineDirectionVisualOrder: Float32,
    lineLogicalTop: Float32,
    lineLogicalLeft: Float32,
    displayBoxTree: DisplayBoxTree,
    ancestorStack: AncestorStack,
    writingMode: WritingMode,
    isHorizontalWritingMode: Bool,
    hasInlineBox: inout Bool
  ) {
    var blockLevelOutOfFlowBoxList: [UInt64] = []
    var rootInlineBoxVisualRectInInlineDirection = lineBox.logicalRectForRootInlineBox()
    rootInlineBoxVisualRectInInlineDirection.setLeft(
      left: displayLine.contentLogicalLeftIgnoringInlineDirection)
    appendRootInlineBoxDisplayBox(
      rootInlineBoxVisualRect: flipRootInlineBoxRectToVisualForWritingMode(
        rootInlineBoxLogicalRect: rootInlineBoxVisualRectInInlineDirection,
        writingMode: root().style.writingMode()),
      lineHasContent: lineBox.rootInlineBox.hasContent, boxes: &boxes)

    var contentRightInInlineDirectionVisualOrder = contentStartInInlineDirectionVisualOrder
    let inlineContent = lineLayoutResult.inlineContent
    for (index, logicalIndex) in lineLayoutResult.directionality.visualOrderList.enumerated() {
      assert(inlineContent[Int(logicalIndex)].bidiLevel != InlineItemWrapper.opaqueBidiLevel)
      let lineRun = inlineContent[Int(logicalIndex)]
      let needsDisplayBoxOrGeometrySetting =
        !lineRun.isWordBreakOpportunity() && !lineRun.isInlineBoxEnd()
      if !needsDisplayBoxOrGeometrySetting {
        continue
      }

      let layoutBox = lineRun.layoutBox
      let parentDisplayBoxNodeIndex = ensureDisplayBoxForContainer(
        elementBox: layoutBox.parent(), displayBoxTree: displayBoxTree,
        ancestorStack: ancestorStack, boxes: boxes)
      hasInlineBox =
        hasInlineBox || parentDisplayBoxNodeIndex != 0 || lineRun.isInlineBoxStart()
        || lineRun.isLineSpanningInlineBoxStart()

      if lineRun.isOpaque() {
        if layoutBox.style.isOriginalDisplayInlineType() {
          // Note that out-of-flow handling (render tree integraton) really only needs logical coords (not even "content in inline diretion visual order").
          formattingContext.geometryForBox(layoutBox: layoutBox).setTopLeft(
            topLeft: LayoutPointWrapper(
              x: LayoutUnit(
                value: lineBox.logicalRect.left() + lineBox.logicalRectForRootInlineBox().left()
                  + lineRun.logicalLeft),
              y: LayoutUnit(value: lineBox.logicalRect.top()))
          )
          continue
        }
        blockLevelOutOfFlowBoxList.append(UInt64(index))
        continue
      }

      let logicalRect = logicalRectBidi(lineRun: lineRun)

      var visualRectRelativeToRoot = visualRectRelativeToRootBidi(
        logicalRect: logicalRect,
        contentRightInInlineDirectionVisualOrder: contentRightInInlineDirectionVisualOrder,
        lineLogicalTop: lineLogicalTop, writingMode: writingMode,
        isHorizontalWritingMode: isHorizontalWritingMode)

      if lineRun.isText() {
        let wordSpacingMargin =
          lineRun.isWordSeparator() ? layoutBox.style.fontCascade().wordSpacing() : 0
        if isHorizontalWritingMode {
          visualRectRelativeToRoot.moveHorizontally(offset: wordSpacingMargin)
        } else {
          visualRectRelativeToRoot.moveVertically(offset: wordSpacingMargin)
        }
        appendTextDisplayBox(lineRun: lineRun, textRunRect: visualRectRelativeToRoot, boxes: &boxes)
        contentRightInInlineDirectionVisualOrder += logicalRect.width() + wordSpacingMargin
        displayBoxTree.append(
          parentNodeIndex: parentDisplayBoxNodeIndex, childDisplayBoxIndex: UInt64(boxes.count - 1))
        continue
      }
      if lineRun.isSoftLineBreak() {
        assert(
          (isHorizontalWritingMode && visualRectRelativeToRoot.width() == 0)
            || (!isHorizontalWritingMode && visualRectRelativeToRoot.height() == 0))
        appendSoftLineBreakDisplayBox(
          lineRun: lineRun, softLineBreakRunRect: visualRectRelativeToRoot, boxes: &boxes)
        displayBoxTree.append(
          parentNodeIndex: parentDisplayBoxNodeIndex, childDisplayBoxIndex: UInt64(boxes.count - 1))
        continue
      }
      if lineRun.isHardLineBreak() {
        assert(
          (isHorizontalWritingMode && visualRectRelativeToRoot.width() == 0)
            || (!isHorizontalWritingMode && visualRectRelativeToRoot.height() == 0))
        appendHardLineBreakDisplayBox(
          lineRun: lineRun, lineBreakBoxRect: visualRectRelativeToRoot, boxes: &boxes)

        let boxGeometry = formattingContext.geometryForBox(layoutBox: layoutBox)
        boxGeometry.setTopLeft(
          topLeft:
            LayoutPointWrapper(
              x: LayoutUnit(value: lineLogicalLeft + contentRightInInlineDirectionVisualOrder),
              y: LayoutUnit(value: lineLogicalTop + logicalRect.top())))
        boxGeometry.setContentBoxSize(size: toLayoutSize(size: logicalRect.size()))

        displayBoxTree.append(
          parentNodeIndex: parentDisplayBoxNodeIndex, childDisplayBoxIndex: UInt64(boxes.count - 1))
        continue
      }
      if lineRun.isAtomicInlineBox() || lineRun.isListMarker() {
        let isLeftToRightDirection = layoutBox.parent().style.isLeftToRightDirection()
        let boxGeometry = formattingContext.geometryForBox(layoutBox: layoutBox)
        let boxMarginLeft = marginLeftInInlineDirection(
          boxGeometry: boxGeometry, isLeftToRightDirection: isLeftToRightDirection)
        isHorizontalWritingMode
          ? visualRectRelativeToRoot.moveHorizontally(offset: boxMarginLeft.float())
          : visualRectRelativeToRoot.moveVertically(offset: boxMarginLeft.float())

        appendAtomicInlineLevelDisplayBox(
          lineRun: lineRun, borderBoxRect: visualRectRelativeToRoot, boxes: &boxes)
        boxGeometry.setTopLeft(
          topLeft:
            LayoutPointWrapper(
              x: LayoutUnit(value: lineLogicalLeft + contentRightInInlineDirectionVisualOrder),
              y: LayoutUnit(value: lineLogicalTop + logicalRect.top())))

        contentRightInInlineDirectionVisualOrder +=
          boxMarginLeft.float() + logicalRect.width()
          + marginRightInInlineDirection(
            boxGeometry: boxGeometry, isLeftToRightDirection: isLeftToRightDirection
          ).float()
        displayBoxTree.append(
          parentNodeIndex: parentDisplayBoxNodeIndex, childDisplayBoxIndex: UInt64(boxes.count - 1))
        continue
      }
      if lineRun.isInlineBoxStart() || lineRun.isLineSpanningInlineBoxStart() {
        // FIXME: While we should only get here with empty inline boxes, there are
        // some cases where the inline box has some content on the paragraph level (at bidi split) but line breaking renders it empty
        // or their content is completely collapsed.
        // Such inline boxes should also be handled here.
        if !lineBox.hasContent {
          // FIXME: It's expected to not have any inline boxes on empty lines. They make the line taller. We should reconsider this.
          setInlineBoxGeometry(
            boxGeometry: formattingContext.geometryForBox(layoutBox: layoutBox),
            logicalRect: InlineRect(topLeft: InlineLayoutPoint(), size: InlineLayoutSize()),
            isFirstInlineBoxFragment: true)
          continue
        }
        if isEmptyInlineBox(
          lineRun: lineRun, inlineContent: inlineContent, logicalIndex: UInt64(logicalIndex))
        {
          appendInlineDisplayBoxAtBidiBoundary(layoutBox: layoutBox, boxes: boxes)
          createDisplayBoxNodeForContainerAndPushToAncestorStack(
            elementBox: layoutBox as! ElementBoxWrapper, displayBoxIndex: UInt64(boxes.count - 1),
            parentDisplayBoxNodeIndex: parentDisplayBoxNodeIndex,
            displayBoxTree: displayBoxTree, ancestorStack: ancestorStack)
        }
        continue
      }
      fatalError("Not reached")
    }
    setGeometryForBlockLevelOutOfFlowBoxes(
      indexListOfOutOfFlowBoxes: blockLevelOutOfFlowBoxList, lineRuns: inlineContent,
      visualOrderList: lineLayoutResult.directionality.visualOrderList)
  }

  private func logicalRectBidi(lineRun: Line.Run) -> InlineRect {
    if lineRun.isText() || lineRun.isSoftLineBreak() {
      return lineBox.logicalRectForTextRun(run: lineRun)
    }
    let layoutBox = lineRun.layoutBox
    if lineRun.isHardLineBreak() {
      return lineBox.logicalRectForLineBreakBox(layoutBox: layoutBox)
    }
    if lineRun.isInlineBoxStart() || lineRun.isLineSpanningInlineBoxStart() {
      // Computed at a later stage.
      return InlineRect(topLeft: InlineLayoutPoint(), size: InlineLayoutSize())
    }
    let boxGeometry = formattingContext.geometryForBox(layoutBox: layoutBox)
    assert(lineRun.isAtomicInlineBox() || lineRun.isListMarker())
    return lineBox.logicalBorderBoxForAtomicInlineBox(
      layoutBox: layoutBox, boxGeometry: boxGeometry)
  }

  private func isEmptyInlineBox(
    lineRun: Line.Run, inlineContent: Line.RunList, logicalIndex: UInt64
  )
    -> Bool
  {
    // FIXME: Maybe we should not tag ruby bases with annotation boxes only contentful?
    if !lineBox.inlineLevelBoxFor(lineRun: lineRun).hasContent {
      return true
    }
    let layoutBox = lineRun.layoutBox
    if !layoutBox.isRubyBase() {
      return false
    }
    let rubyBaseLayoutBox = layoutBox as? ElementBoxWrapper
    if rubyBaseLayoutBox == nil {
      return false
    }
    // Let's create empty inline boxes for ruby bases with annotation only.
    if rubyBaseLayoutBox!.firstChild() == nil
      || (rubyBaseLayoutBox!.firstChild() === rubyBaseLayoutBox!.lastChild()
        && rubyBaseLayoutBox!.firstChild()!.isRubyAnnotationBox())
    {
      return true
    }
    // Let's check if we actually don't have a contentful run inside this ruby base.
    for nextLogicalRunIndex in (logicalIndex + 1)..<UInt64(inlineContent.count) {
      let lineRun = inlineContent[Int(nextLogicalRunIndex)]
      if lineRun.isInlineBoxEnd() && lineRun.layoutBox === rubyBaseLayoutBox {
        break
      }
      if lineRun.isContentful() {
        return false
      }
    }
    return true
  }

  private func visualRectRelativeToRootBidi(
    logicalRect: InlineRect, contentRightInInlineDirectionVisualOrder: Float32,
    lineLogicalTop: Float32,
    writingMode: WritingMode, isHorizontalWritingMode: Bool
  )
    -> InlineRect
  {
    var visualRect = flipLogicalRectToVisualForWritingModeWithinLine(
      logicalRect: logicalRect, lineLogicalRect: lineBox.logicalRect, writingMode: writingMode)
    if isHorizontalWritingMode {
      visualRect.setLeft(left: contentRightInInlineDirectionVisualOrder)
      visualRect.moveVertically(offset: lineLogicalTop)
      return visualRect
    }
    visualRect.setTop(top: contentRightInInlineDirectionVisualOrder)
    visualRect.moveHorizontally(offset: lineLogicalTop)
    return visualRect
  }

  private mutating func handleInlineBoxes(
    boxes: InlineDisplay.Boxes,
    displayBoxTree: DisplayBoxTree,
    lineLogicalTop: Float32,
    contentStartInInlineDirectionVisualOrder: Float32,
    hasInlineBox: Bool
  ) {
    if !hasInlineBox {
      return
    }

    var isFirstLastIndexesMap = IsFirstLastIndexesMap()
    assert(boxes[0].isRootInlineBox())
    for index in 1..<boxes.count {
      if !boxes[index].isNonRootInlineBox() {
        continue
      }
      let layoutBox = boxes[index].layoutBox
      let inlineLevelBox = lineBox.inlineLevelBoxFor(layoutBox: layoutBox)!
      let isFirstBox = inlineLevelBox.isFirstBox()
      let isLastBox = inlineLevelBox.isLastBox()
      if !isFirstBox && !isLastBox {
        continue
      }
      if isFirstBox {
        let isFirstLastIndexes = isFirstLastIndexesMap[layoutBox]!
        if isFirstLastIndexes.first == nil || isLastBox {
          isFirstLastIndexesMap[layoutBox] = IsFirstLastIndex(
            first: isFirstLastIndexes.first ?? UInt64(index),
            last: isLastBox ? UInt64(index) : isFirstLastIndexes.last)
          continue
        }
      }
      if isLastBox {
        assert(!isFirstBox)
        isFirstLastIndexesMap[layoutBox] = IsFirstLastIndex(first: UInt64(0), last: UInt64(index))
        continue
      }
    }

    var contentRightInInlineDirectionVisualOrder = contentStartInInlineDirectionVisualOrder

    for childDisplayBoxNodeIndex in displayBoxTree.root().children {
      adjustVisualGeometryForDisplayBox(
        displayBoxNodeIndex: childDisplayBoxNodeIndex,
        contentRightInInlineDirectionVisualOrder: &contentRightInInlineDirectionVisualOrder,
        lineBoxLogicalTop: lineLogicalTop,
        displayBoxTree: displayBoxTree, boxes: boxes, isFirstLastIndexesMap: isFirstLastIndexesMap)
    }
  }

  private mutating func handleTrailingOpenInlineBoxes(
    lineLayoutResult: LineLayoutResult, boxes: inout InlineDisplay.Boxes
  ) {
    for lineRun in lineLayoutResult.inlineContent.reversed() {
      if !lineRun.isInlineBoxStart() || lineRun.bidiLevel != InlineItemWrapper.opaqueBidiLevel {
        break
      }
      // These are trailing inline box start runs (without the closing inline box end <span> <-line breaks here</span>).
      // They don't participate in visual reordering (see createDisplayBoxesInVisualOrder above) as we don't find them
      // empty at inline item list building time (see setBidiLevelForOpaqueInlineItems) due to trailing whitespace.
      // Non-empty inline boxes are normally get their display boxes generated when we process their content runs, but
      // these trailing runs have their content on the subsequent line(s).
      let inlineBox = lineBox.inlineLevelBoxFor(lineRun: lineRun)
      appendInlineBoxDisplayBox(
        lineRun: lineRun, inlineBox: inlineBox,
        inlineBoxBorderBox: InlineRect(
          top: InlineLayoutUnit(), left: displayLine.right(), width: InlineLayoutUnit(),
          height: InlineLayoutUnit()), boxes: &boxes)
      setInlineBoxGeometry(
        boxGeometry: formattingContext.geometryForBox(layoutBox: lineRun.layoutBox),
        logicalRect: InlineRect(
          top: InlineLayoutUnit(), left: lineBox.logicalRect.right(), width: InlineLayoutUnit(),
          height: InlineLayoutUnit()), isFirstInlineBoxFragment: inlineBox.isFirstBox())
    }
  }

  private func collectInkOverflowForInlineBoxes(boxes: InlineDisplay.Boxes) {
    if !contentHasInkOverflow {
      return
    }
    // Visit the inline boxes and propagate ink overflow to their parents -except to the root inline box.
    // (e.g. <span style="font-size: 10px;">Small font size<span style="font-size: 300px;">Larger font size. This overflows the top most span.</span></span>).
    var accumulatedInkOverflowRect = InlineRect(
      topLeft: InlineLayoutPoint(), size: InlineLayoutSize())
    for displayBox in boxes.reversed() {
      let mayHaveInkOverflow =
        displayBox.isText() || displayBox.isAtomicInlineBox()
        || displayBox.isGenericInlineLevelBox() || displayBox.isNonRootInlineBox()
      if !mayHaveInkOverflow {
        continue
      }
      if displayBox.isNonRootInlineBox() && !accumulatedInkOverflowRect.isEmpty() {
        displayBox.adjustInkOverflow(childBorderBox: accumulatedInkOverflowRect.InlineLayoutRect())
      }

      // We stop collecting ink overflow for at root inline box (i.e. don't inflate the root inline box with the inline content here).
      let parentBoxIsRoot = displayBox.layoutBox.parent() == root()
      if parentBoxIsRoot {
        accumulatedInkOverflowRect = InlineRect(
          topLeft: InlineLayoutPoint(), size: InlineLayoutSize())
      } else if accumulatedInkOverflowRect.isEmpty() {
        accumulatedInkOverflowRect = InlineRect(rect: displayBox.inkOverflow)
      } else {
        accumulatedInkOverflowRect.expandToContain(other: InlineRect(rect: displayBox.inkOverflow))
      }
    }
  }

  private mutating func collectInkOverflowForTextDecorations(boxes: InlineDisplay.Boxes) {
    if !hasSeenTextDecoration {
      return
    }

    var logicalBottomForTextDecoration: Float32? = nil
    let writingMode = root().style.writingMode()
    let isHorizontalWritingMode = isHorizontalWritingMode(writingMode: writingMode)

    for displayBox in boxes {
      if !displayBox.isText() {
        continue
      }

      let parentStyle = displayBox.layoutBox.parent().style
      let textDecorations = parentStyle.textDecorationsInEffect()
      if textDecorations.isEmpty {
        continue
      }

      let decorationOverflow = decorationOverflow(
        textDecorations: textDecorations, parentStyle: parentStyle,
        isHorizontalWritingMode: isHorizontalWritingMode, boxes: boxes, displayBox: displayBox,
        logicalBottomForTextDecoration: &logicalBottomForTextDecoration)

      if !decorationOverflow.isEmpty() {
        contentHasInkOverflow = true
        displayBox.adjustInkOverflow(
          childBorderBox:
            inflatedVisualOverflowRect(
              displayBox: displayBox, writingMode: writingMode,
              decorationOverflow: decorationOverflow
            ))
      }
    }
  }

  private func decorationOverflow(
    textDecorations: TextDecorationLine, parentStyle: RenderStyleWrapper,
    isHorizontalWritingMode: Bool, boxes: InlineDisplay.Boxes, displayBox: InlineDisplay.Box,
    logicalBottomForTextDecoration: inout Float32?
  )
    -> GlyphOverflow
  {
    if !textDecorations.contains(.Underline) {
      return visualOverflowForDecorations(style: parentStyle)
    }

    if logicalBottomForTextDecoration == nil {
      logicalBottomForTextDecoration = logicalBottomForTextDecorationContent(
        boxes: boxes, isHorizontalWritingMode: isHorizontalWritingMode)
    }
    let textRunLogicalOffsetFromLineBottom =
      logicalBottomForTextDecoration!
      - (isHorizontalWritingMode ? displayBox.bottom() : displayBox.right())
    return visualOverflowForDecorations(
      style: parentStyle,
      textUnderlinePositionUnder: TextUnderlinePositionUnder(
        textRunLogicalHeight: displayBox.height(),
        textRunOffsetFromBottomMost: textRunLogicalOffsetFromLineBottom))
  }

  private func inflatedVisualOverflowRect(
    displayBox: InlineDisplay.Box, writingMode: WritingMode, decorationOverflow: GlyphOverflow
  )
    -> FloatRectWrapper
  {
    var inkOverflowRect = displayBox.inkOverflow
    switch writingModeToBlockFlowDirection(writingMode: writingMode) {
    case .TopToBottom, .BottomToTop:
      inkOverflowRect.inflate(
        deltaX: decorationOverflow.left.float(), deltaY: decorationOverflow.top.float(),
        deltaMaxX: decorationOverflow.right.float(), deltaMaxY: decorationOverflow.bottom.float())
    case .LeftToRight:
      inkOverflowRect.inflate(
        deltaX: decorationOverflow.bottom.float(), deltaY: decorationOverflow.right.float(),
        deltaMaxX: decorationOverflow.top.float(), deltaMaxY: decorationOverflow.left.float())
    case .RightToLeft:
      inkOverflowRect.inflate(
        deltaX: decorationOverflow.top.float(), deltaY: decorationOverflow.right.float(),
        deltaMaxX: decorationOverflow.bottom.float(), deltaMaxY: decorationOverflow.left.float())
    }
    return inkOverflowRect
  }

  private mutating func appendTextDisplayBox(
    lineRun: Line.Run, textRunRect: InlineRect, boxes: inout InlineDisplay.Boxes
  ) {
    assert(lineRun.textContent != nil && lineRun.layoutBox as? InlineTextBoxWrapper != nil)

    let inlineTextBox = lineRun.layoutBox as! InlineTextBoxWrapper
    let style = lineIndex() == 0 ? inlineTextBox.firstLineStyle() : inlineTextBox.style
    let content = inlineTextBox.content
    let text = lineRun.textContent
    let isContentful = true

    hasSeenTextDecoration =
      hasSeenTextDecoration
      || (lineIndex() == 0
        ? !inlineTextBox.parent().firstLineStyle().textDecorationsInEffect().isEmpty
        : !inlineTextBox.parent().style.textDecorationsInEffect().isEmpty)

    if inlineTextBox.isCombined {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    boxes.append(
      InlineDisplay.Box(
        lineIndex: lineIndex(),
        type: lineRun.isWordSeparator() ? .WordSeparator : .Text,
        layoutBox: inlineTextBox,
        bidiLevel: lineRun.bidiLevel,
        physicalRect: textRunRect.InlineLayoutRect(),
        inkOverflow: inkOverflow(
          inlineTextBox: inlineTextBox,
          textRunRect: textRunRect, style: style
        ).InlineLayoutRect(),
        expansion: lineRun.expansion,
        text: InlineDisplay.Box.Text(
          start: text!.start, length: text!.length, originalContent: content,
          adjustedContentToRender: InlineDisplayContentBuilder.adjustedContentToRender(text: text),
          hasHyphen: text!.needsHyphen),
        hasContent: isContentful,
        isFullyTruncated: isLineFullyTruncatedInBlockDirection()))
  }

  private func inkOverflow(
    inlineTextBox: InlineTextBoxWrapper, textRunRect: InlineRect, style: RenderStyleWrapper
  ) -> InlineRect {
    var inkOverflow = textRunRect

    InlineDisplayContentBuilder.addLetterSpacingOverflow(
      textRunRect: textRunRect, style: style, inkOverflow: &inkOverflow)
    addStrokeOverflow(inkOverflow: &inkOverflow, style: style)
    InlineDisplayContentBuilder.addTextShadow(inkOverflow: &inkOverflow, style: style)
    InlineDisplayContentBuilder.addGlyphOverflow(inlineTextBox: inlineTextBox)

    return inkOverflow
  }

  private static func addLetterSpacingOverflow(
    textRunRect: InlineRect, style: RenderStyleWrapper, inkOverflow: inout InlineRect
  ) {
    let letterSpacing = style.fontCascade().letterSpacing()
    if letterSpacing >= 0 {
      return
    }
    // Large negative letter spacing can produce text boxes with negative width (when glyphs position order gets completely backwards (123 turns into 321 starting at an offset))
    // Such spacing should go to ink overflow.
    let textRunWidth = textRunRect.width()
    if textRunWidth < 0 {
      inkOverflow.setWidth(width: InlineLayoutUnit())
      inkOverflow.shiftLeftTo(left: textRunWidth)
    }
    // Last letter's negative spacing shrinks logical rect. Push it to ink overflow.
    inkOverflow.expand(width: -letterSpacing, height: nil)
  }

  private func addStrokeOverflow(inkOverflow: inout InlineRect, style: RenderStyleWrapper) {
    inkOverflow.inflate(
      inflate: ceilf(style.computedStrokeWidth(viewportSize: initialContaingBlockSize!)))
  }

  private static func addTextShadow(inkOverflow: inout InlineRect, style: RenderStyleWrapper) {
    let textShadow = style.textShadowExtent()
    inkOverflow.inflate(
      top: -textShadow.top.float(), right: textShadow.right.float(),
      bottom: textShadow.bottom.float(),
      left: -textShadow.left.float())
  }

  private static func addGlyphOverflow(inlineTextBox: InlineTextBoxWrapper) {
    if inlineTextBox.canUseSimpleFontCodePath() {
      // canUseSimpleFontCodePath maps to CodePath::Simple (and content with potential glyph overflow would says CodePath::SimpleWithGlyphOverflow).
      return
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private static func adjustedContentToRender(text: Line.Run.Text?) -> StringWrapper {
    if text!.needsHyphen {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return StringWrapper()
  }

  private func appendSoftLineBreakDisplayBox(
    lineRun: Line.Run, softLineBreakRunRect: InlineRect, boxes: inout InlineDisplay.Boxes
  ) {
    assert(lineRun.textContent != nil && lineRun.layoutBox.isInlineTextBox())

    let layoutBox = lineRun.layoutBox
    let text = lineRun.textContent

    boxes.append(
      InlineDisplay.Box(
        lineIndex: lineIndex(), type: .SoftLineBreak, layoutBox: lineRun.layoutBox,
        bidiLevel: lineRun.bidiLevel,
        physicalRect: softLineBreakRunRect.InlineLayoutRect(),
        inkOverflow: softLineBreakRunRect.InlineLayoutRect(),
        expansion: lineRun.expansion,
        text: InlineDisplay.Box.Text(
          start: text!.start, length: text!.length,
          originalContent: (layoutBox as! InlineTextBoxWrapper).content),
        hasContent: true, isFullyTruncated: isLineFullyTruncatedInBlockDirection()
      ))
  }

  private func appendHardLineBreakDisplayBox(
    lineRun: Line.Run, lineBreakBoxRect: InlineRect, boxes: inout InlineDisplay.Boxes
  ) {
    boxes.append(
      InlineDisplay.Box(
        lineIndex: lineIndex(), type: .LineBreakBox, layoutBox: lineRun.layoutBox,
        bidiLevel: lineRun.bidiLevel,
        physicalRect: lineBreakBoxRect.InlineLayoutRect(),
        inkOverflow: lineBreakBoxRect.InlineLayoutRect(),
        expansion: lineRun.expansion, text: nil,
        hasContent: true, isFullyTruncated: isLineFullyTruncatedInBlockDirection()
      ))
  }

  private mutating func appendAtomicInlineLevelDisplayBox(
    lineRun: Line.Run, borderBoxRect: InlineRect, boxes: inout InlineDisplay.Boxes
  ) {
    assert(lineRun.layoutBox.isAtomicInlineBox())
    let layoutBox = lineRun.layoutBox

    var inkOverflow = borderBoxRect.InlineLayoutRect()
    let style = lineIndex() == 0 ? layoutBox.firstLineStyle() : layoutBox.style
    computeInkOverflowForInlineLevelBox(style: style, inkOverflow: &inkOverflow)
    // Atomic inline box contribute to their inline box parents ink overflow at all times (e.g. <span><img></span>).
    contentHasInkOverflow =
      contentHasInkOverflow || CPtrToInt(layoutBox.parent().p) != CPtrToInt(root().p)

    boxes.append(
      InlineDisplay.Box(
        lineIndex: lineIndex(), type: .AtomicInlineBox, layoutBox: layoutBox,
        bidiLevel: lineRun.bidiLevel,
        physicalRect: borderBoxRect.InlineLayoutRect(),
        inkOverflow: inkOverflow,
        expansion: lineRun.expansion, text: nil,
        hasContent: true, isFullyTruncated: isLineFullyTruncatedInBlockDirection()
      ))
  }

  private mutating func appendRootInlineBoxDisplayBox(
    rootInlineBoxVisualRect: InlineRect, lineHasContent: Bool, boxes: inout InlineDisplay.Boxes
  ) {
    boxes.append(
      InlineDisplay.Box(
        lineIndex: lineIndex(), type: .RootInlineBox, layoutBox: root(),
        bidiLevel: UBiDiLevel.UBIDI_DEFAULT_LTR,
        physicalRect: rootInlineBoxVisualRect.InlineLayoutRect(),
        inkOverflow: rootInlineBoxVisualRect.InlineLayoutRect(),
        expansion: InlineDisplay.Box.Expansion(), text: nil,
        hasContent: lineHasContent, isFullyTruncated: isLineFullyTruncatedInBlockDirection()
      ))
  }

  private mutating func appendInlineBoxDisplayBox(
    lineRun: Line.Run, inlineBox: InlineLevelBox, inlineBoxBorderBox: InlineRect,
    boxes: inout InlineDisplay.Boxes
  ) {
    assert(lineRun.layoutBox.isInlineBox())
    assert(inlineBox.isInlineBox())
    assert(
      (inlineBox.isFirstBox() && lineRun.isInlineBoxStart())
        || (!inlineBox.isFirstBox() && lineRun.isLineSpanningInlineBoxStart()))

    let layoutBox = lineRun.layoutBox
    hasSeenRubyBase = hasSeenRubyBase || layoutBox.isRubyBase()

    let style = lineIndex() == 0 ? layoutBox.firstLineStyle() : layoutBox.style
    var inkOverflow = inlineBoxBorderBox.InlineLayoutRect()
    contentHasInkOverflow =
      computeInkOverflowForInlineBox(inlineBox: inlineBox, style: style, inkOverflow: &inkOverflow)
      || contentHasInkOverflow
    boxes.append(
      InlineDisplay.Box(
        lineIndex: lineIndex(), type: .NonRootInlineBox, layoutBox: layoutBox,
        bidiLevel: lineRun.bidiLevel,
        physicalRect: inlineBoxBorderBox.InlineLayoutRect(),
        inkOverflow: inkOverflow,
        expansion: InlineDisplay.Box.Expansion(), text: nil,
        hasContent: inlineBox.hasContent, isFullyTruncated: isLineFullyTruncatedInBlockDirection(),
        positionWithinInlineLevelBox: isFirstLastBox(inlineBox: inlineBox)
      ))
  }

  private func appendInlineDisplayBoxAtBidiBoundary(
    layoutBox: BoxWrapper, boxes: InlineDisplay.Boxes
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func processRubyContent(
    displayBoxes: InlineDisplay.Boxes, lineLayoutResult: LineLayoutResult
  ) {
    if root().isRubyAnnotationBox() {
      RubyFormattingContext.applyAnnotationAlignmentOffset(
        displayBoxes: displayBoxes,
        alignmentOffset: lineLayoutResult.ruby.annotationAlignmentOffset,
        inlineFormattingContext: formattingContext)
    }

    if !hasSeenRubyBase {
      return
    }

    var lineSpanningRubyBaseList: Set<BoxWrapper> = []
    for lineRun in lineLayoutResult.inlineContent {
      if lineRun.isLineSpanningInlineBoxStart() && lineRun.layoutBox.isRubyBase() {
        lineSpanningRubyBaseList.insert(lineRun.layoutBox)
      }
    }

    let rubyBasesMayHaveCollapsed = !lineLayoutResult.directionality.visualOrderList.isEmpty
    RubyFormattingContext.applyAlignmentOffsetList(
      displayBoxes: displayBoxes,
      alignmentOffsetList: lineLayoutResult.ruby.baseAlignmentOffsetList,
      rubyBasesMayNeedResizing: rubyBasesMayHaveCollapsed ? .Yes : .No,
      inlineFormattingContext: formattingContext)

    var interlinearRubyColumnRangeList: [Range<UInt64>] = []
    var rubyBaseStartIndexListWithAnnotation: [UInt64] = []
    var index: UInt64 = 1
    while index < displayBoxes.count {
      let displayBox = displayBoxes[Int(index)]
      if !displayBox.isNonRootInlineBox() || !displayBox.layoutBox.isRubyBase() {
        index += 1
        continue
      }
      if lineSpanningRubyBaseList.contains(displayBox.layoutBox) {
        // FIXME: Base content split across multiple lines don't affect annotation atm.
        index += 1
        continue
      }
      index =
        processRubyBase(
          rubyBaseStart: index, displayBoxes: displayBoxes,
          interlinearRubyColumnRangeList: &interlinearRubyColumnRangeList,
          rubyBaseStartIndexListWithAnnotation: &rubyBaseStartIndexListWithAnnotation) + 1
    }
    RubyFormattingContext.applyRubyOverhang(
      parentFormattingContext: formattingContext, lineLogicalHeight: lineBox.logicalRect.height(),
      displayBoxes: displayBoxes, interlinearRubyColumnRangeList: interlinearRubyColumnRangeList)

    let lineBoxLogicalRect = lineBox.logicalRect
    let writingMode = root().style.writingMode()
    for baseIndex in rubyBaseStartIndexListWithAnnotation.reversed() {
      let annotationBox = displayBoxes[Int(baseIndex)].layoutBox.associatedRubyAnnotationBox()!
      insertRubyAnnotationBox(
        annotationBox: annotationBox, insertionPosition: baseIndex + 1,
        borderBoxRect: annotationBorderBoxVisualRect(
          annotationBox: annotationBox, lineBoxLogicalRect: lineBoxLogicalRect,
          writingMode: writingMode), boxes: displayBoxes)
    }
  }

  private func annotationBorderBoxVisualRect(
    annotationBox: ElementBoxWrapper, lineBoxLogicalRect: InlineRect, writingMode: WritingMode
  ) -> InlineRect {
    var borderBoxLogicalRect = InlineRect(
      rect: BoxGeometry.borderBoxRect(
        box: formattingContext.geometryForBox(layoutBox: annotationBox)
      ).FloatRect())
    borderBoxLogicalRect.setTop(top: borderBoxLogicalRect.top() - lineBoxLogicalRect.top())
    var visualRect = flipLogicalRectToVisualForWritingModeWithinLine(
      logicalRect: borderBoxLogicalRect, lineLogicalRect: lineBoxLogicalRect,
      writingMode: writingMode)
    let isHorizontalWritingMode = isHorizontalWritingMode(writingMode: writingMode)
    if isHorizontalWritingMode {
      visualRect.moveVertically(offset: lineBoxLogicalRect.top())
    } else {
      visualRect.moveHorizontally(offset: lineBoxLogicalRect.top())
    }
    return visualRect
  }

  private func insertRubyAnnotationBox(
    annotationBox: BoxWrapper, insertionPosition: UInt64, borderBoxRect: InlineRect,
    boxes: InlineDisplay.Boxes
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func processRubyBase(
    rubyBaseStart: UInt64, displayBoxes: InlineDisplay.Boxes,
    interlinearRubyColumnRangeList: inout [Range<UInt64>],
    rubyBaseStartIndexListWithAnnotation: inout [UInt64]
  ) -> UInt64 {
    let rubyBaseDisplayBox = displayBoxes[Int(rubyBaseStart)]
    let rubyBaseLayoutBox = rubyBaseDisplayBox.layoutBox
    assert(rubyBaseDisplayBox.isInlineBox())
    var baseBorderBoxLogicalRect = BoxGeometry.borderBoxRect(
      box: formattingContext.geometryForBox(layoutBox: rubyBaseLayoutBox))

    let annotationBox = rubyBaseLayoutBox.associatedRubyAnnotationBox()
    if annotationBox == nil {
      rubyBaseStartIndexListWithAnnotation.append(rubyBaseStart)
    }

    var rubyBaseEnd = UInt64(displayBoxes.count)
    let rubyBox = rubyBaseLayoutBox.parent()
    let rubyBoxParent = rubyBox.parent()
    var index = rubyBaseStart + 1
    while index < displayBoxes.count {
      let baseContentLayoutBox = displayBoxes[Int(index)].layoutBox
      if baseContentLayoutBox.isRubyBase() {
        index = processRubyBase(
          rubyBaseStart: index, displayBoxes: displayBoxes,
          interlinearRubyColumnRangeList: &interlinearRubyColumnRangeList,
          rubyBaseStartIndexListWithAnnotation: &rubyBaseStartIndexListWithAnnotation)
        if RubyFormattingContext.hasInterlinearAnnotation(rubyBaseLayoutBox: baseContentLayoutBox) {
          let interlinearAnnotationBox = baseContentLayoutBox.associatedRubyAnnotationBox()!
          if isNestedRubyBase(
            baseContentLayoutBox: baseContentLayoutBox, rubyBaseLayoutBox: rubyBaseLayoutBox)
          {
            let nestedAnnotationMarginBoxRect = BoxGeometry.marginBoxRect(
              box: formattingContext.geometryForBox(layoutBox: interlinearAnnotationBox))
            baseBorderBoxLogicalRect.expandToContain(rect: nestedAnnotationMarginBoxRect)
          }
        }

        if index == displayBoxes.count {
          rubyBaseEnd = index
          break
        }
      }

      let layoutBox = displayBoxes[Int(index)].layoutBox
      if layoutBox.parent() === rubyBox || layoutBox.parent() === rubyBoxParent {
        rubyBaseEnd = index
        break
      }
      index += 1
    }

    if RubyFormattingContext.hasInterlinearAnnotation(rubyBaseLayoutBox: rubyBaseLayoutBox) {
      interlinearRubyColumnRangeList.append(rubyBaseStart..<rubyBaseEnd)
    }

    if let annotationBox = annotationBox {
      if RubyFormattingContext.hasInterCharacterAnnotation(rubyBaseLayoutBox: rubyBaseLayoutBox) {
        let letterSpacing = LayoutUnit(value: rubyBaseLayoutBox.style.letterSpacing())
        // FIXME: Consult the LineBox to see if letter spacing indeed applies.
        baseBorderBoxLogicalRect.setWidth(
          width: max(LayoutUnit(value: 0), baseBorderBoxLogicalRect.width() - letterSpacing))
      }

      // FIXME: There is a confusion here. The functions expect margin box.
      let borderBoxLogicalTopLeft = RubyFormattingContext.placeAnnotationBox(
        rubyBaseLayoutBox: rubyBaseLayoutBox,
        rubyBaseMarginBoxLogicalRect: baseBorderBoxLogicalRect,
        inlineFormattingContext: formattingContext)
      let contentBoxLogicalSize = RubyFormattingContext.sizeAnnotationBox(
        rubyBaseLayoutBox: rubyBaseLayoutBox,
        rubyBaseMarginBoxLogicalRect: baseBorderBoxLogicalRect,
        inlineFormattingContext: formattingContext)
      let annotationBoxGeometry = formattingContext.geometryForBox(layoutBox: annotationBox)
      annotationBoxGeometry.setTopLeft(topLeft: toLayoutPoint(point: borderBoxLogicalTopLeft))
      annotationBoxGeometry.setContentBoxSize(size: toLayoutSize(size: contentBoxLogicalSize))
    }
    return rubyBaseEnd
  }

  private func isNestedRubyBase(baseContentLayoutBox: BoxWrapper, rubyBaseLayoutBox: BoxWrapper)
    -> Bool
  {
    var ancestor = baseContentLayoutBox.parent()
    while ancestor !== root() {
      if ancestor.isRubyBase() {
        return ancestor === rubyBaseLayoutBox
      }
      ancestor = ancestor.parent()
    }
    return false
  }

  private func setInlineBoxGeometry(
    boxGeometry: BoxGeometry, logicalRect: InlineRect, isFirstInlineBoxFragment: Bool
  ) {
    var enclosingLogicalRect = Rect(
      topLeft: toLayoutPoint(point: logicalRect.topLeft()),
      size: LayoutSizeWrapper(
        width: LayoutUnit.fromFloatCeil(value: logicalRect.width()),
        height: LayoutUnit.fromFloatCeil(value: logicalRect.height())))
    if !isFirstInlineBoxFragment {
      enclosingLogicalRect.expandToContain(rect: BoxGeometry.borderBoxRect(box: boxGeometry))
    }

    boxGeometry.setTopLeft(topLeft: enclosingLogicalRect.topLeft())
    boxGeometry.setContentBoxWidth(
      width: enclosingLogicalRect.width() - boxGeometry.horizontalBorderAndPadding())
    boxGeometry.setContentBoxHeight(
      height: enclosingLogicalRect.height() - boxGeometry.verticalBorderAndPadding())
  }

  private mutating func adjustVisualGeometryForDisplayBox(
    displayBoxNodeIndex: UInt64, contentRightInInlineDirectionVisualOrder: inout InlineLayoutUnit,
    lineBoxLogicalTop: InlineLayoutUnit, displayBoxTree: DisplayBoxTree, boxes: InlineDisplay.Boxes,
    isFirstLastIndexesMap: IsFirstLastIndexesMap
  ) {
    let writingMode = root().style.writingMode()
    let isHorizontalWritingMode = isHorizontalWritingMode(writingMode: writingMode)
    // Non-inline box display boxes just need a horizontal adjustment while
    // inline box type of display boxes need
    // 1. horizontal adjustment and margin/border/padding start offsetting on the first box
    // 2. right edge computation including descendant content width and margin/border/padding end offsetting on the last box
    var displayBox = boxes[Int(displayBoxTree.at(index: displayBoxNodeIndex).displayBoxIndex)]
    let layoutBox = displayBox.layoutBox

    if !displayBox.isNonRootInlineBox() {
      if displayBox.isAtomicInlineBox() || displayBox.isGenericInlineLevelBox() {
        let isLeftToRightDirection = layoutBox.parent().style.isLeftToRightDirection()
        let boxGeometry = formattingContext.geometryForBox(layoutBox: layoutBox)
        let boxMarginLeft = marginLeftInInlineDirection(
          boxGeometry: boxGeometry, isLeftToRightDirection: isLeftToRightDirection)

        let borderBoxLeft = contentRightInInlineDirectionVisualOrder + boxMarginLeft
        boxGeometry.setLeft(left: LayoutUnit(value: borderBoxLeft))
        setLeftForWritingMode(box: displayBox, logicalLeft: borderBoxLeft, writingMode: writingMode)

        contentRightInInlineDirectionVisualOrder += boxGeometry.marginBoxWidth()
      } else {
        let wordSpacingMargin =
          displayBox.isWordSeparator() ? layoutBox.style.fontCascade().wordSpacing() : 0
        setLeftForWritingMode(
          box: displayBox,
          logicalLeft: contentRightInInlineDirectionVisualOrder + wordSpacingMargin,
          writingMode: writingMode)
        contentRightInInlineDirectionVisualOrder +=
          (isHorizontalWritingMode ? displayBox.width() : displayBox.height()) + wordSpacingMargin
      }
      return
    }

    let boxGeometry = formattingContext.geometryForBox(layoutBox: layoutBox)
    let isLeftToRightDirection = layoutBox.style.isLeftToRightDirection()
    let isFirstLastIndexes = isFirstLastIndexesMap[layoutBox]!
    let isFirstBox =
      isFirstLastIndexes.first != nil && isFirstLastIndexes.first! == displayBoxNodeIndex
    let isLastBox =
      isFirstLastIndexes.last != nil && isFirstLastIndexes.last! == displayBoxNodeIndex
    let logicalRect = lineBox.logicalBorderBoxForInlineBox(
      layoutBox: layoutBox, boxGeometry: boxGeometry)
    beforeInlineBoxContent(
      displayBox: displayBox, boxGeometry: boxGeometry,
      logicalRect: logicalRect, writingMode: writingMode,
      isHorizontalWritingMode: isHorizontalWritingMode,
      isLeftToRightDirection: isLeftToRightDirection, isFirstBox: isFirstBox, isLastBox: isLastBox,
      contentRightInInlineDirectionVisualOrder: &contentRightInInlineDirectionVisualOrder)

    for childDisplayBoxNodeIndex in displayBoxTree.at(index: displayBoxNodeIndex).children {
      adjustVisualGeometryForDisplayBox(
        displayBoxNodeIndex: childDisplayBoxNodeIndex,
        contentRightInInlineDirectionVisualOrder: &contentRightInInlineDirectionVisualOrder,
        lineBoxLogicalTop: lineBoxLogicalTop, displayBoxTree: displayBoxTree, boxes: boxes,
        isFirstLastIndexesMap: isFirstLastIndexesMap)
    }

    afterInlineBoxContent(
      layoutBox: layoutBox, boxGeometry: boxGeometry,
      writingMode: writingMode,
      isLeftToRightDirection: isLeftToRightDirection, isFirstBox: isFirstBox, isLastBox: isLastBox,
      contentRightInInlineDirectionVisualOrder: &contentRightInInlineDirectionVisualOrder,
      displayBox: &displayBox)

    let inlineBox = lineBox.inlineLevelBoxFor(layoutBox: layoutBox)
    var inkOverflow = displayBox.visualRectIgnoringBlockDirection()
    assert(inlineBox != nil)
    contentHasInkOverflow =
      computeInkOverflowForInlineBox(
        inlineBox: inlineBox!,
        style: lineIndex() == 0 ? layoutBox.firstLineStyle() : layoutBox.style,
        inkOverflow: &inkOverflow)
      || contentHasInkOverflow
    displayBox.adjustInkOverflow(childBorderBox: inkOverflow)

    let inlineBoxLeftInInlineDirectionVisualOrder =
      isHorizontalWritingMode ? displayBox.left() : displayBox.top()
    let logicalWidthForBiDiFragment =
      isHorizontalWritingMode ? displayBox.width() : displayBox.height()
    let logicalTopRelativeToRoot = lineBox.logicalRect.top() + logicalRect.top()
    setInlineBoxGeometry(
      boxGeometry: boxGeometry,
      logicalRect: InlineRect(
        top: logicalTopRelativeToRoot, left: inlineBoxLeftInInlineDirectionVisualOrder,
        width: logicalWidthForBiDiFragment, height: logicalRect.height()),
      isFirstInlineBoxFragment: isFirstBox)
    if inlineBox!.hasContent {
      displayBox.setHasContent()
    }
  }

  private func beforeInlineBoxContent(
    displayBox: InlineDisplay.Box, boxGeometry: BoxGeometry,
    logicalRect: InlineRect,
    writingMode: WritingMode, isHorizontalWritingMode: Bool, isLeftToRightDirection: Bool,
    isFirstBox: Bool, isLastBox: Bool,
    contentRightInInlineDirectionVisualOrder: inout InlineLayoutUnit
  ) {
    var visualRect = flipLogicalRectToVisualForWritingModeWithinLine(
      logicalRect: InlineRect(
        top: logicalRect.top(), left: contentRightInInlineDirectionVisualOrder,
        width: InlineLayoutUnit(), height: logicalRect.height()),
      lineLogicalRect: lineBox.logicalRect, writingMode: writingMode)
    isHorizontalWritingMode
      ? visualRect.moveVertically(offset: displayLine.top())
      : visualRect.moveHorizontally(offset: displayLine.left())
    displayBox.setRect(
      rect: visualRect.InlineLayoutRect(), inkOverflow: visualRect.InlineLayoutRect())

    let shouldApplyLeftSide =
      (isLeftToRightDirection && isFirstBox) || (!isLeftToRightDirection && isLastBox)
    if !shouldApplyLeftSide {
      return
    }

    contentRightInInlineDirectionVisualOrder += marginLeftInInlineDirection(
      boxGeometry: boxGeometry, isLeftToRightDirection: isLeftToRightDirection)
    setLeftForWritingMode(
      box: displayBox, logicalLeft: contentRightInInlineDirectionVisualOrder,
      writingMode: writingMode)
    contentRightInInlineDirectionVisualOrder +=
      borderLeftInInlineDirection(
        boxGeometry: boxGeometry, isLeftToRightDirection: isLeftToRightDirection)
      + paddingLeftInInlineDirection(
        boxGeometry: boxGeometry, isLeftToRightDirection: isLeftToRightDirection)
  }

  private func afterInlineBoxContent(
    layoutBox: BoxWrapper,
    boxGeometry: BoxGeometry, writingMode: WritingMode,
    isLeftToRightDirection: Bool,
    isFirstBox: Bool,
    isLastBox: Bool,
    contentRightInInlineDirectionVisualOrder: inout InlineLayoutUnit,
    displayBox: inout InlineDisplay.Box
  ) {
    let shouldApplyRightSide =
      (isLeftToRightDirection && isLastBox) || (!isLeftToRightDirection && isFirstBox)
    if !shouldApplyRightSide {
      return setRightForWritingMode(
        displayBox: displayBox, logicalRight: contentRightInInlineDirectionVisualOrder,
        writingMode: writingMode)
    }

    contentRightInInlineDirectionVisualOrder +=
      borderRightInInlineDirection(
        boxGeometry: boxGeometry, isLeftToRightDirection: isLeftToRightDirection)
      + paddingRightInInlineDirection(
        boxGeometry: boxGeometry, isLeftToRightDirection: isLeftToRightDirection)
    contentRightInInlineDirectionVisualOrder +=
      layoutBox.isRubyBase()
      ? RubyFormattingContext.baseEndAdditionalLogicalWidth(
        rubyBaseLayoutBox: layoutBox, baseDisplayBox: displayBox,
        baseContentWidth: contentRightInInlineDirectionVisualOrder - displayBox.left(),
        inlineFormattingContext: formattingContext) : 0
    setRightForWritingMode(
      displayBox: displayBox, logicalRight: contentRightInInlineDirectionVisualOrder,
      writingMode: writingMode)
    contentRightInInlineDirectionVisualOrder += marginRightInInlineDirection(
      boxGeometry: boxGeometry, isLeftToRightDirection: isLeftToRightDirection)
  }

  private func ensureDisplayBoxForContainer(
    elementBox: ElementBoxWrapper, displayBoxTree: DisplayBoxTree, ancestorStack: AncestorStack,
    boxes: InlineDisplay.Boxes
  ) -> UInt64 {
    assert(elementBox.isInlineBox() || elementBox === root())
    if let lowestCommonAncestorIndex = ancestorStack.unwind(elementBox: elementBox) {
      return lowestCommonAncestorIndex
    }
    let enclosingDisplayBoxNodeIndexForContainer = ensureDisplayBoxForContainer(
      elementBox: elementBox.parent(), displayBoxTree: displayBoxTree, ancestorStack: ancestorStack,
      boxes: boxes)
    appendInlineDisplayBoxAtBidiBoundary(layoutBox: elementBox, boxes: boxes)
    return createDisplayBoxNodeForContainerAndPushToAncestorStack(
      elementBox: elementBox, displayBoxIndex: UInt64(boxes.count - 1),
      parentDisplayBoxNodeIndex: enclosingDisplayBoxNodeIndexForContainer,
      displayBoxTree: displayBoxTree,
      ancestorStack: ancestorStack)
  }

  private func visualRectRelativeToRootNonBidi(
    logicalRect: InlineRect, writingMode: WritingMode, contentStartInVisualOrder: FloatPoint
  )
    -> InlineRect
  {
    var visualRect = flipLogicalRectToVisualForWritingModeWithinLine(
      logicalRect: logicalRect, lineLogicalRect: lineBox.logicalRect, writingMode: writingMode)
    visualRect.moveBy(offset: contentStartInVisualOrder)
    return visualRect
  }

  private func flipLogicalRectToVisualForWritingModeWithinLine(
    logicalRect: InlineRect, lineLogicalRect: InlineRect, writingMode: WritingMode
  ) -> InlineRect {
    switch writingModeToBlockFlowDirection(writingMode: writingMode) {
    case .TopToBottom:
      return logicalRect
    case .BottomToTop:
      let bottomOffset = lineLogicalRect.height() - logicalRect.bottom()
      return InlineRect(
        top: bottomOffset, left: logicalRect.left(), width: logicalRect.width(),
        height: logicalRect.height())
    case .LeftToRight:
      // Flip content such that the top (visual left) is now relative to the line bottom instead of the line top.
      let bottomOffset = lineLogicalRect.height() - logicalRect.bottom()
      return InlineRect(
        top: logicalRect.left(), left: bottomOffset, width: logicalRect.height(),
        height: logicalRect.width())
    case .RightToLeft:
      // See InlineFormattingUtils for more info.
      return InlineRect(
        top: logicalRect.left(), left: logicalRect.top(), width: logicalRect.height(),
        height: logicalRect.width())
    }
  }

  private func flipRootInlineBoxRectToVisualForWritingMode(
    rootInlineBoxLogicalRect: InlineRect, writingMode: WritingMode
  ) -> InlineRect {
    switch writingModeToBlockFlowDirection(writingMode: writingMode) {
    case .TopToBottom, .BottomToTop:
      var visualRect = rootInlineBoxLogicalRect
      visualRect.moveBy(offset: InlineLayoutPoint(x: displayLine.left(), y: displayLine.top()))
      return visualRect
    case .LeftToRight, .RightToLeft:
      // See InlineFormattingUtils for more info.
      var visualRect = InlineRect(
        top: rootInlineBoxLogicalRect.left(), left: rootInlineBoxLogicalRect.top(),
        width: rootInlineBoxLogicalRect.height(), height: rootInlineBoxLogicalRect.width())
      visualRect.moveBy(offset: InlineLayoutPoint(x: displayLine.left(), y: displayLine.top()))
      return visualRect
    }
  }

  private func setLeftForWritingMode(
    box: InlineDisplay.Box, logicalLeft: InlineLayoutUnit, writingMode: WritingMode
  ) {
    switch writingModeToBlockFlowDirection(writingMode: writingMode) {
    case .TopToBottom, .BottomToTop:
      box.setLeft(physicalLeft: logicalLeft)
    case .LeftToRight, .RightToLeft:
      box.setTop(physicalTop: logicalLeft)
    }
  }

  private func setRightForWritingMode(
    displayBox: InlineDisplay.Box, logicalRight: InlineLayoutUnit, writingMode: WritingMode
  ) {
    switch writingModeToBlockFlowDirection(writingMode: writingMode) {
    case .TopToBottom, .BottomToTop:
      displayBox.setRight(physicalRight: logicalRight)
    case .LeftToRight, .RightToLeft:
      displayBox.setBottom(physicalBottom: logicalRight)
    }
  }

  private func setGeometryForBlockLevelOutOfFlowBoxes(
    indexListOfOutOfFlowBoxes: [UInt64], lineRuns: Line.RunList, visualOrderList: [Int32] = []
  ) {
    if indexListOfOutOfFlowBoxes.isEmpty {
      return
    }

    // Block level boxes are placed either at the start of the line or "under" depending whether they have previous inflow sibling.
    // Here we figure out if a particular out of flow box has an inflow sibling or not.
    // 1. Find the first inflow content. Any out of flow box after this gets moved _under_ the line box.
    // 2. Loop through the out of flow boxes (indexListOfOutOfFlowBoxes) and set their vertical geometry depending whether they are before or after the first inflow content.
    // Note that there's an extra layer of directionality here: in case of right to left inline direction, the before inflow content check starts from the right edge and progresses in a leftward manner
    // and not in visual order. However this is not logical order either (which is more about bidi than inline direction). So LTR starts at the left while RTL starts at the right and in
    // both cases jumping from run to run in bidi order.
    let isLeftToRightDirection = root().style.isLeftToRightDirection()

    var firstContentfulInFlowRunIndex: UInt64? = nil
    let contentListSize = UInt64(visualOrderList.isEmpty ? lineRuns.count : visualOrderList.count)
    for i in 0..<contentListSize {
      let index = InlineDisplayContentBuilder.runIndex(
        i: i, listSize: contentListSize, isLeftToRightDirection: isLeftToRightDirection)
      let lineRun =
        visualOrderList.isEmpty ? lineRuns[Int(index)] : lineRuns[Int(visualOrderList[Int(index)])]
      if lineRun.layoutBox.isInFlow()
        && Line.Run.isContentfulOrHasDecoration(run: lineRun, formattingContext: formattingContext)
      {
        firstContentfulInFlowRunIndex = index
        break
      }
    }

    if firstContentfulInFlowRunIndex == nil {
      setGeometryForOutOfFlowBoxes(
        indexListOfOutOfFlowBoxes: indexListOfOutOfFlowBoxes,
        firstOutOfFlowIndexWithPreviousInflowSibling: nil, lineRuns: lineRuns,
        visualOrderList: visualOrderList,
        formattingContext: formattingContext, lineBox: lineBox, constraints: constraints)
      return
    }

    var firstOutOfFlowIndexWithPreviousInflowSibling: UInt64? = nil
    let outOfFlowBoxListSize = UInt64(indexListOfOutOfFlowBoxes.count)
    for i in 0..<outOfFlowBoxListSize {
      let outOfFlowIndex = Int(
        InlineDisplayContentBuilder.runIndex(
          i: i, listSize: outOfFlowBoxListSize, isLeftToRightDirection: isLeftToRightDirection))
      let hasPreviousInflowSibling =
        (isLeftToRightDirection
          && indexListOfOutOfFlowBoxes[outOfFlowIndex] > firstContentfulInFlowRunIndex!)
        || (!isLeftToRightDirection
          && indexListOfOutOfFlowBoxes[outOfFlowIndex] < firstContentfulInFlowRunIndex!)
      if hasPreviousInflowSibling {
        firstOutOfFlowIndexWithPreviousInflowSibling = UInt64(outOfFlowIndex)
        break
      }
    }
    setGeometryForOutOfFlowBoxes(
      indexListOfOutOfFlowBoxes: indexListOfOutOfFlowBoxes,
      firstOutOfFlowIndexWithPreviousInflowSibling: firstOutOfFlowIndexWithPreviousInflowSibling,
      lineRuns: lineRuns,
      visualOrderList: visualOrderList,
      formattingContext: formattingContext, lineBox: lineBox, constraints: constraints)
  }

  private func isLineFullyTruncatedInBlockDirection() -> Bool {
    return lineIsFullyTruncatedInBlockDirection
  }

  private func lineIndex() -> UInt64 { return lineBox.lineIndex }

  private func root() -> ElementBoxWrapper {
    return formattingContext.root()
  }

  private func rootStyle() -> RenderStyleWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var formattingContext: InlineFormattingContext
  var constraints: ConstraintsForInlineContent
  var lineBox: LineBox
  var displayLine: InlineDisplay.Line
  private var initialContaingBlockSize: IntSize? = nil
  // FIXME: This should take DisplayLine::isFullyTruncatedInBlockDirection() for non-prefixed line-clamp.
  private var lineIsFullyTruncatedInBlockDirection = false
  var contentHasInkOverflow = false
  var hasSeenRubyBase = false
  var hasSeenTextDecoration = false
}
