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

func caretWidth() -> Int32 {
  // This value should be kept in sync with UIKit. See <rdar://problem/15580601>.
  return 1
  // This value should be kept in sync with UIKit. See <rdar://problem/15580601>.
}

func computeCaretRectForEmptyElement(
  renderer: RenderBoxModelObjectWrapper, logicalWidth: LayoutUnit, textIndentOffset: LayoutUnit,
  caretRectMode: CaretRectMode
) -> LayoutRectWrapper {
  assert(renderer.firstChild() == nil || renderer.firstChild()!.isPseudoElement())
  // FIXME: This does not take into account either :first-line or :first-letter
  // However, as soon as some content is entered, the line boxes will be
  // constructed and this kludge is not called any more. So only the caret size
  // of an empty :first-line'd block is wrong. I think we can live with that.
  let currentStyle = renderer.elementFirstLineStyle()
  var alignment: CaretAlignment = .AlignLeft
  switch currentStyle.textAlign() {
  case .Left, .WebKitLeft:
    break
  case .Center, .WebKitCenter:
    alignment = .AlignCenter
    break
  case .Right, .WebKitRight:
    alignment = .AlignRight
    break
  case .Justify, .Start:
    if !currentStyle.isLeftToRightDirection() {
      alignment = .AlignRight
    }
    break
  case .End:
    if currentStyle.isLeftToRightDirection() {
      alignment = .AlignRight
    }
    break
  }
  var x = renderer.borderAndPaddingLogicalLeft()
  let maxX = logicalWidth - renderer.borderAndPaddingLogicalRight()
  switch alignment {
  case .AlignLeft:
    if currentStyle.isLeftToRightDirection() {
      x += textIndentOffset
    }
    break
  case .AlignCenter:
    x = (x + maxX) / Int32(2)
    if currentStyle.isLeftToRightDirection() {
      x += textIndentOffset / Int32(2)
    } else {
      x -= textIndentOffset / Int32(2)
    }
    break
  case .AlignRight:
    x = maxX - caretWidth()
    if !currentStyle.isLeftToRightDirection() {
      x -= textIndentOffset
    }
    break
  }
  x = min(x, max(maxX - caretWidth(), LayoutUnit(value: 0)))
  let lineHeight = renderer.lineHeight(
    firstLine: true,
    direction: currentStyle.isHorizontalWritingMode() ? .HorizontalLine : .VerticalLine,
    linePositionMode: .PositionOfInteriorLineBoxes)
  let height = min(
    lineHeight, LayoutUnit(value: Float64(currentStyle.metricsOfPrimaryFont().height())))
  let y =
    renderer.borderAndPaddingBefore()
    + (lineHeight > height ? (lineHeight - height) / Int32(2) : LayoutUnit())
  var rect = LayoutRectWrapper(x: x, y: y, width: LayoutUnit(value: caretWidth()), height: height)
  if caretRectMode == .ExpandToEndOfLine {
    rect.shiftMaxXEdgeTo(edge: logicalWidth)
  }
  return currentStyle.isHorizontalWritingMode() ? rect : rect.transposedRect()
}

func computeCaretRectForLinePosition(
  lineBox: InlineIterator.LineBoxIterator, logicalLeftPosition: Float32,
  caretRectMode: CaretRectMode
) -> LayoutRectWrapper {
  let root = lineBox.get().formattingContextRoot()
  let lineSelectionRect = LineSelection.logicalRect(lineBox: lineBox.get())
  let height: Int32 = Int32(lineSelectionRect.height())
  let top: Int32 = Int32(lineSelectionRect.y())
  // Distribute the caret's width to either side of the offset.
  var left: Float32 = logicalLeftPosition
  let caretWidthLeftOfOffset: Int32 = caretWidth() / 2
  left -= Float32(caretWidthLeftOfOffset)
  let caretWidthRightOfOffset: Int32 = caretWidth() - caretWidthLeftOfOffset
  left = left.rounded()
  let lineLeft: Float32 = lineSelectionRect.x()
  let lineRight: Float32 = lineSelectionRect.maxX()
  var rightAligned: Bool = false
  switch root.style().textAlign() {
  case .Right, .WebKitRight:
    rightAligned = true
    break
  case .Left, .WebKitLeft, .Center, .WebKitCenter:
    break
  case .Justify, .Start:
    rightAligned = !(root.style().isLeftToRightDirection())
    break
  case .End:
    rightAligned = root.style().isLeftToRightDirection()
    break
  }
  let leftEdge: Float32 = min(0, lineLeft)
  let rightEdge: Float32 = max(root.logicalWidth().toFloat(), lineRight)
  if rightAligned {
    left = max(left, leftEdge)
    left = min(left, lineRight - Float32(caretWidth()))
  } else {
    left = min(left, rightEdge - Float32(caretWidthRightOfOffset))
    left = max(left, lineLeft)
  }
  var rect = IntRect(x: Int32(left), y: top, width: caretWidth(), height: height)
  if caretRectMode == .ExpandToEndOfLine {
    rect.shiftMaxXEdgeTo(Int32(lineRight))
  }
  return LayoutRectWrapper(
    rect: root.style().isHorizontalWritingMode() ? rect : rect.transposedRect())
}

func computeCaretRectForText(boxAndOffset: InlineBoxAndOffset, caretRectMode: CaretRectMode)
  -> LayoutRectWrapper
{
  if !boxAndOffset.box.bool() {
    return LayoutRectWrapper()
  }
  let textBox = InlineIterator.TextBoxIterator(
    InlineIterator.TextBox(boxAndOffset.box.get().m_pathVariant))
  let positionForOffset = { (offset: UInt32) -> Float32 in
    assert(offset >= textBox.get().start())
    assert(offset <= textBox.get().end())
    if textBox.get().isLineBreak() {
      return textBox.get().logicalLeftIgnoringInlineDirection()
    }
    let (startOffset, endOffset) = { () -> (UInt32, UInt32) in
      if textBox.get().direction() == .RTL {
        return (textBox.get().selectableRange().clamp(offset: offset), textBox.get().length())
      }
      return (0, textBox.get().selectableRange().clamp(offset: offset))
    }()
    var selectionRect = LayoutRectWrapper(
      x: textBox.get().logicalLeftIgnoringInlineDirection(), y: 0, width: 0, height: 0)
    let textRun = textBox.get().textRun(mode: .Editing)
    textBox.get().fontCascade().adjustSelectionRectForText(
      canUseSimplifiedTextMeasuring: (textBox.get().renderer().canUseSimplifiedTextMeasuring()
        ?? false), run: textRun, selectionRect: &selectionRect, from: startOffset, to: endOffset)
    return snapRectToDevicePixelsWithWritingDirection(
      rect: selectionRect,
      deviceScaleFactor: textBox.get().renderer().document().deviceScaleFactor(), ltr: textRun.ltr()
    ).maxX()
  }
  return computeCaretRectForLinePosition(
    lineBox: textBox.get().lineBox(), logicalLeftPosition: positionForOffset(boxAndOffset.offset),
    caretRectMode: caretRectMode)
}

func computeCaretRectForLineBreak(boxAndOffset: InlineBoxAndOffset, caretRectMode: CaretRectMode)
  -> LayoutRectWrapper
{
  assert(!(boxAndOffset.offset != 0))
  if !boxAndOffset.box.bool() {
    return LayoutRectWrapper()
  }
  let lineBox = boxAndOffset.box.get().lineBox()
  return computeCaretRectForLinePosition(
    lineBox: lineBox, logicalLeftPosition: lineBox.get().contentLogicalLeft(),
    caretRectMode: caretRectMode)
}

func computeCaretRectForSVGInlineText(boxAndOffset: InlineBoxAndOffset, _ arg1: CaretRectMode)
  -> LayoutRectWrapper
{
  fatalError("Not implemented")
}

func computeCaretRectForBox(
  renderer: RenderBoxWrapper, boxAndOffset: InlineBoxAndOffset, caretRectMode: CaretRectMode
) -> LayoutRectWrapper {
  // VisiblePositions at offsets inside containers either a) refer to the positions before/after
  // those containers (tables and select elements) or b) refer to the position inside an empty block.
  // They never refer to children.
  // FIXME: Paint the carets inside empty blocks differently than the carets before/after elements.
  var rect = LayoutRectWrapper(
    location: renderer.location(),
    size: LayoutSizeWrapper(width: LayoutUnit(value: caretWidth()), height: renderer.height()))
  let ltr: Bool =
    boxAndOffset.box.bool()
    ? boxAndOffset.box.get().isLeftToRightDirection() : renderer.style().isLeftToRightDirection()
  if (!(boxAndOffset.offset != 0)) != ltr {
    rect.move(
      size: LayoutSizeWrapper(width: renderer.width() - caretWidth(), height: LayoutUnit(value: 0)))
  }
  if boxAndOffset.box.bool() {
    let lineBox = boxAndOffset.box.get().lineBox()
    let top: Float32 = lineBox.get().contentLogicalTop()
    rect.setY(y: LayoutUnit(value: top))
    rect.setHeight(height: lineBox.get().contentLogicalBottom() - top)
  }
  // If height of box is smaller than font height, use the latter one,
  // otherwise the caret might become invisible.
  //
  // Also, if the box is not a replaced element, always use the font height.
  // This prevents the "big caret" bug described in:
  // <rdar://problem/3777804> Deleting all content in a document can result in giant tall-as-window insertion point
  //
  // FIXME: ignoring :first-line, missing good reason to take care of
  let fontHeight: Float32 = renderer.style().metricsOfPrimaryFont().height()
  if fontHeight > rect.height()
    || (!renderer.isReplacedOrInlineBlock() && !renderer.isRenderTable())
  {
    rect.setHeight(height: fontHeight)
  }
  // Move to local coords
  rect.moveBy(offset: -renderer.location())
  // FIXME: Border/padding should be added for all elements but this workaround
  // is needed because we use offsets inside an "atomic" element to represent
  // positions before and after the element in deprecated editing offsets.
  if renderer.element() != nil
    && !((editingIgnoresContent(node: renderer.element()!)
      || isRenderedTable(node: renderer.element())))
  {
    rect.setX(x: rect.x() + renderer.borderLeft() + renderer.paddingLeft())
    rect.setY(y: rect.y() + renderer.paddingTop() + renderer.borderTop())
  }
  if caretRectMode == .ExpandToEndOfLine {
    rect.shiftMaxXEdgeTo(edge: renderer.x() + renderer.width())
  }
  return renderer.isHorizontalWritingMode() ? rect : rect.transposedRect()
}

func computeCaretRectForBlock(
  renderer: RenderBlockWrapper, boxAndOffset: InlineBoxAndOffset, caretRectMode: CaretRectMode
) -> LayoutRectWrapper {
  // Do the normal calculation in most cases.
  if renderer.firstChild() != nil && !(renderer.firstChild()!.isPseudoElement()) {
    return computeCaretRectForBox(
      renderer: renderer, boxAndOffset: boxAndOffset, caretRectMode: caretRectMode)
  }
  return computeCaretRectForEmptyElement(
    renderer: renderer, logicalWidth: renderer.logicalWidth(),
    textIndentOffset: renderer.textIndentOffset(), caretRectMode: caretRectMode)
}

func computeCaretRectForInline(renderer: RenderInlineWrapper) -> LayoutRectWrapper {
  if renderer.firstChild() != nil {
    // This condition is possible if the RenderInline is at an editing boundary,
    // i.e. the VisiblePosition is:
    //   <RenderInline editingBoundary=true>|<RenderText> </RenderText></RenderInline>
    // FIXME: need to figure out how to make this return a valid rect, note that
    // there are no line boxes created in the above case.
    return LayoutRectWrapper()
    // This condition is possible if the RenderInline is at an editing boundary,
    // i.e. the VisiblePosition is:
    //   <RenderInline editingBoundary=true>|<RenderText> </RenderText></RenderInline>
    // FIXME: need to figure out how to make this return a valid rect, note that
    // there are no line boxes created in the above case.
  }
  var caretRect = computeCaretRectForEmptyElement(
    renderer: renderer, logicalWidth: renderer.borderAndPaddingLogicalWidth(),
    textIndentOffset: LayoutUnit(value: 0), caretRectMode: .Normal)
  let firstInlineBox = InlineIterator.firstInlineBoxFor(renderInline: renderer)
  if firstInlineBox.bool() {
    caretRect.moveBy(
      offset: LayoutPointWrapper(
        size: firstInlineBox.get().visualRectIgnoringBlockDirection().location()))
  }
  return caretRect
}

func computeLocalCaretRect(
  renderer: RenderObjectWrapper, boxAndOffset: InlineBoxAndOffset,
  caretRectMode: CaretRectMode = .Normal
) -> LayoutRectWrapper {
  if renderer is RenderSVGInlineTextWrapper {
    return computeCaretRectForSVGInlineText(boxAndOffset: boxAndOffset, caretRectMode)
  }
  if renderer is RenderTextWrapper {
    return computeCaretRectForText(boxAndOffset: boxAndOffset, caretRectMode: caretRectMode)
  }
  if renderer is RenderLineBreakWrapper {
    return computeCaretRectForLineBreak(boxAndOffset: boxAndOffset, caretRectMode: caretRectMode)
  }
  if let block = renderer as? RenderBlockWrapper {
    return computeCaretRectForBlock(
      renderer: block, boxAndOffset: boxAndOffset, caretRectMode: caretRectMode)
  }
  if let box = renderer as? RenderBoxWrapper {
    return computeCaretRectForBox(
      renderer: box, boxAndOffset: boxAndOffset, caretRectMode: caretRectMode)
  }
  if let renderInline = renderer as? RenderInlineWrapper {
    return computeCaretRectForInline(renderer: renderInline)
  }
  return LayoutRectWrapper()
}
