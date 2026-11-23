/*
 * Copyright (C) 2004-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2013-2015 Google Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import wk_interop

func previousLeafWithSameEditability(node: NodeWrapper?, editableType: EditableType) -> NodeWrapper?
{
  var node = node
  let editable: Bool = hasEditableStyle(node: node!, editableType: editableType)
  node = previousLeafNode(node: node)
  while node != nil {
    if editable == hasEditableStyle(node: node!, editableType: editableType) {
      return node
    }
    node = previousLeafNode(node: node)
  }
  return nil
}

func nextLeafWithSameEditability(node: NodeWrapper?, editableType: EditableType) -> NodeWrapper? {
  var node = node
  if node == nil {
    return nil
  }
  let editable: Bool = hasEditableStyle(node: node!, editableType: editableType)
  node = nextLeafNode(node: node)
  while node != nil {
    if editable == hasEditableStyle(node: node!, editableType: editableType) {
      return node
    }
    node = nextLeafNode(node: node)
  }
  return nil
}

func previousLineCandidatePosition(
  node: NodeWrapper?, visiblePosition: VisiblePosition, editableType: EditableType
) -> Position {
  let highestRoot: ContainerNodeWrapper? = highestEditableRoot(
    position: visiblePosition.deepEquivalent(), editableType: editableType)
  var previousNode: NodeWrapper? = previousLeafWithSameEditability(
    node: node, editableType: editableType)
  while previousNode != nil
    && (previousNode!.renderer() == nil
      || inSameLine(
        a: VisiblePosition(firstPositionInOrBeforeNode(previousNode)), b: visiblePosition))
  {
    previousNode = previousLeafWithSameEditability(node: previousNode, editableType: editableType)
  }
  while previousNode != nil && !previousNode!.isShadowRoot() {
    if CPtrToInt(
      highestEditableRoot(
        position: firstPositionInOrBeforeNode(previousNode), editableType: editableType)?.p)
      != CPtrToInt(highestRoot?.p)
    {
      break
    }
    let pos =
      previousNode!.hasBrTagName()
      ? positionBeforeNode(anchorNode: previousNode)
      : makeDeprecatedLegacyPosition(previousNode, UInt32(caretMaxOffset(node: previousNode!)))
    if pos.isCandidate() {
      return pos
    }
    previousNode = previousLeafWithSameEditability(node: previousNode, editableType: editableType)
  }
  return Position()
}

func nextLineCandidatePosition(
  node: NodeWrapper?, visiblePosition: VisiblePosition, editableType: EditableType
) -> Position {
  let highestRoot: ContainerNodeWrapper? = highestEditableRoot(
    position: visiblePosition.deepEquivalent(), editableType: editableType)
  var nextNode: NodeWrapper? = nextLeafWithSameEditability(node: node, editableType: editableType)
  while nextNode != nil
    && (nextNode!.renderer() == nil
      || inSameLine(a: VisiblePosition(firstPositionInOrBeforeNode(nextNode)), b: visiblePosition))
  {
    nextNode = nextLeafWithSameEditability(node: nextNode, editableType: .ContentIsEditable)
  }
  while nextNode != nil && !nextNode!.isShadowRoot() {
    if CPtrToInt(
      highestEditableRoot(
        position: firstPositionInOrBeforeNode(nextNode), editableType: editableType)?.p)
      != CPtrToInt(highestRoot?.p)
    {
      break
    }
    var pos = Position()
    pos = makeDeprecatedLegacyPosition(nextNode, UInt32(caretMinOffset(node: nextNode!)))
    if pos.isCandidate() {
      return pos
    }
    nextNode = nextLeafWithSameEditability(node: nextNode, editableType: editableType)
  }
  return Position()
}

func isTextOrLineBreakBox(box: InlineIterator.LeafBoxIterator) -> Bool {
  return box.bool() && (box.get().isText() || box.get().renderer().isBRForRenderObject())
}

func previousTextOrLineBreakBox(
  box: InlineIterator.LeafBoxIterator, orderCache: inout InlineIterator.LineLogicalOrderCache
) -> InlineIterator.LeafBoxIterator {
  var box = box
  while box.bool() {
    box = InlineIterator.previousLeafOnLineInLogicalOrder(box, orderCache)
    if isTextOrLineBreakBox(box: box) {
      return box
    }
  }
  return InlineIterator.LeafBoxIterator()
}

func nextTextOrLineBreakBox(
  box: InlineIterator.LeafBoxIterator, orderCache: inout InlineIterator.LineLogicalOrderCache
) -> InlineIterator.LeafBoxIterator {
  var box = box
  while box.bool() {
    box = InlineIterator.nextLeafOnLineInLogicalOrder(box, orderCache)
    if isTextOrLineBreakBox(box: box) {
      return box
    }
  }
  return InlineIterator.LeafBoxIterator()
}

func startTextOrLineBreakBox(
  lineBox: InlineIterator.LineBoxIterator, orderCache: inout InlineIterator.LineLogicalOrderCache
) -> InlineIterator.LeafBoxIterator {
  let box = InlineIterator.firstLeafOnLineInLogicalOrder(lineBox, orderCache)
  if isTextOrLineBreakBox(box: box) {
    return box
  }
  return nextTextOrLineBreakBox(box: box, orderCache: &orderCache)
}

func endTextOrLineBreakBox(
  lineBox: InlineIterator.LineBoxIterator, orderCache: inout InlineIterator.LineLogicalOrderCache
) -> InlineIterator.LeafBoxIterator {
  let box = InlineIterator.lastLeafOnLineInLogicalOrder(lineBox, orderCache)
  if isTextOrLineBreakBox(box: box) {
    return box
  }
  return previousTextOrLineBreakBox(box: box, orderCache: &orderCache)
}

func logicallyPreviousBox(
  visiblePosition: VisiblePosition, startBox: InlineIterator.LeafBoxIterator,
  orderCache: inout InlineIterator.LineLogicalOrderCache, previousBoxInDifferentLine: inout Bool
) -> InlineIterator.LeafBoxIterator {
  var startBox = startBox
  let previousBox = previousTextOrLineBreakBox(box: startBox, orderCache: &orderCache)
  if previousBox.bool() {
    return previousBox
  }
  let previousLineBox = startBox.get().lineBox().get().previous()
  if previousLineBox.bool() {
    // FIXME: Why isn't previousBoxInDifferentLine set here?
    let previousBox = endTextOrLineBreakBox(lineBox: previousLineBox, orderCache: &orderCache)
    if previousBox.bool() {
      return previousBox
    }
  }
  while true {
    let startNode: NodeWrapper? = startBox.get().renderer().nonPseudoNode()
    if startNode == nil {
      break
    }
    let position = previousLineCandidatePosition(
      node: startNode, visiblePosition: visiblePosition, editableType: .ContentIsEditable)
    if position.isNull() {
      break
    }
    let renderedPosition = RenderedPosition(position: position, affinity: .Downstream)
    let previousLineBox = renderedPosition.lineBox()
    if !previousLineBox.bool() {
      break
    }
    if previousLineBox != startBox.get().lineBox() {
      let previousBox = endTextOrLineBreakBox(lineBox: previousLineBox, orderCache: &orderCache)
      if previousBox.bool() {
        previousBoxInDifferentLine = true
        return previousBox
      }
    }
    startBox = InlineIterator.firstLeafOnLineInLogicalOrder(previousLineBox, orderCache)
  }
  return InlineIterator.LeafBoxIterator()
}

func logicallyNextBox(
  visiblePosition: VisiblePosition, startBox: InlineIterator.LeafBoxIterator,
  orderCache: inout InlineIterator.LineLogicalOrderCache, nextBoxInDifferentLine: inout Bool
) -> InlineIterator.LeafBoxIterator {
  fatalError("Not implemented")
}

func wordBreakIteratorForMinOffsetBoundary(
  visiblePosition: VisiblePosition, textBox: InlineIterator.TextBoxIterator,
  previousBoxLength: inout UInt32, previousBoxInDifferentLine: inout Bool, string: inout [UInt16]
) -> UnsafeMutableRawPointer? {
  fatalError("Not implemented")
}

func wordBreakIteratorForMaxOffsetBoundary(
  visiblePosition: VisiblePosition, textBox: InlineIterator.TextBoxIterator,
  nextBoxInDifferentLine: inout Bool, string: inout [UInt16]
) -> UnsafeMutableRawPointer? {
  fatalError("Not implemented")
}

func isLogicalStartOfWord(iter: UnsafeMutableRawPointer?, position: Int32, hardLineBreak: Bool)
  -> Bool
{
  fatalError("Not implemented")
}

func islogicalEndOfWord(iter: UnsafeMutableRawPointer?, position: Int32, hardLineBreak: Bool)
  -> Bool
{
  fatalError("Not implemented")
}

func visualWordPosition(
  visiblePosition: VisiblePosition, direction: CursorMovementDirection,
  skipsSpaceWhenMovingRight: Bool
) -> VisiblePosition {
  fatalError("Not implemented")
}

func leftWordPosition(visiblePosition: VisiblePosition, skipsSpaceWhenMovingRight: Bool)
  -> VisiblePosition
{
  var leftWordBreak = visualWordPosition(
    visiblePosition: visiblePosition, direction: .MoveLeft,
    skipsSpaceWhenMovingRight: skipsSpaceWhenMovingRight)
  leftWordBreak = visiblePosition.honorEditingBoundaryAtOrBefore(position: leftWordBreak)
  // FIXME: How should we handle a non-editable position?
  if leftWordBreak.isNull() && isEditablePosition(position: visiblePosition.deepEquivalent()) {
    let blockDirection = directionOfEnclosingBlock(position: visiblePosition.deepEquivalent())
    leftWordBreak =
      blockDirection == .LTR
      ? startOfEditableContent(visiblePosition: visiblePosition)
      : endOfEditableContent(visiblePosition: visiblePosition)
  }
  return leftWordBreak
}

func rightWordPosition(visiblePosition: VisiblePosition, skipsSpaceWhenMovingRight: Bool)
  -> VisiblePosition
{
  var rightWordBreak = visualWordPosition(
    visiblePosition: visiblePosition, direction: .MoveRight,
    skipsSpaceWhenMovingRight: skipsSpaceWhenMovingRight)
  rightWordBreak = visiblePosition.honorEditingBoundaryAtOrBefore(position: rightWordBreak)
  // FIXME: How should we handle a non-editable position?
  if rightWordBreak.isNull() && isEditablePosition(position: visiblePosition.deepEquivalent()) {
    let blockDirection = directionOfEnclosingBlock(position: visiblePosition.deepEquivalent())
    rightWordBreak =
      blockDirection == .LTR
      ? endOfEditableContent(visiblePosition: visiblePosition)
      : startOfEditableContent(visiblePosition: visiblePosition)
  }
  return rightWordBreak
}

func prepend(buffer: inout [UInt16], string: StringWrapperView) {
  fatalError("Not implemented")
}

func prependRepeatedCharacter(buffer: inout [UInt16], character: UInt16, count: UInt32) {
  fatalError("Not implemented")
}

func appendRepeatedCharacter(buffer: inout [UInt16], character: UInt16, count: UInt32) {
  let oldSize: UInt32 = UInt32(UInt64(buffer.count))
  buffer.append(contentsOf: repeatElement(0, count: Int(UInt64(oldSize + count)) - buffer.count))
  var i: UInt32 = 0
  while i < count {
    buffer[Int(UInt64(oldSize + i))] = character
    i += 1
  }
}

func suffixLengthForRange(forwardsScanRange: SimpleRange, string: inout [UInt16]) -> UInt32 {
  fatalError("Not implemented")
}

func prefixLengthForRange(backwardsScanRange: SimpleRange, string: inout [UInt16]) -> UInt32 {
  var prefixLength: UInt32 = 0
  var backwardsIterator = SimplifiedBackwardsTextIterator(range: backwardsScanRange)
  while !backwardsIterator.atEnd() {
    let text = backwardsIterator.text()
    let i: Int32 = Int32(startOfLastWordBoundaryContext(text))
    prepend(buffer: &string, string: text.substring(start: UInt32(i)))
    prefixLength += text.length() - UInt32(i)
    if i > 0 {
      break
    }
    backwardsIterator.advance()
  }
  return prefixLength
}

func backwardSearchForBoundaryWithTextIterator(
  it: inout SimplifiedBackwardsTextIterator, string: inout [UInt16], suffixLength: UInt32,
  searchFunction: (StringWrapperView, UInt32, BoundarySearchContextAvailability, inout Bool) ->
    UInt32
) -> UInt32 {
  fatalError("Not implemented")
}

func forwardSearchForBoundaryWithTextIterator(
  it: inout EditingTextIterator, string: inout [UInt16], prefixLength: UInt32,
  searchFunction: (StringWrapperView, UInt32, BoundarySearchContextAvailability, inout Bool) ->
    UInt32
) -> UInt32 {
  fatalError("Not implemented")
}

func previousBoundary(
  position: VisiblePosition,
  searchFunction: (StringWrapperView, UInt32, BoundarySearchContextAvailability, inout Bool) ->
    UInt32, needsContextAtParagraphStart: NeedsContextAtParagraphStart = .No
) -> VisiblePosition {
  fatalError("Not implemented")
}

func nextBoundary(
  c: VisiblePosition,
  searchFunction: (StringWrapperView, UInt32, BoundarySearchContextAvailability, inout Bool) ->
    UInt32
) -> VisiblePosition {
  fatalError("Not implemented")
}

func startWordBoundary(
  text: StringWrapperView, offset: UInt32, mayHaveMoreContext: BoundarySearchContextAvailability,
  needMoreContext: inout Bool
) -> UInt32 {
  fatalError("Not implemented")
}

func startOfWord(c: VisiblePosition, side: WordSide = .RightWordIfOnBoundary) -> VisiblePosition {
  // FIXME: This returns a null VP for c at the start of the document
  // and side == LeftWordIfOnBoundary
  var p = c
  if side == .RightWordIfOnBoundary {
    // at paragraph end, the startofWord is the current position
    if isEndOfParagraph(pos: c) {
      return c
    }
    p = c.next()
    if p.isNull() {
      return c
    }
  }
  return previousBoundary(position: p, searchFunction: startWordBoundary)
}

func endWordBoundary(
  text: StringWrapperView, offset: UInt32, mayHaveMoreContext: BoundarySearchContextAvailability,
  needMoreContext: inout Bool
) -> UInt32 {
  assert(offset <= text.length())
  if mayHaveMoreContext.rawValue != 0
    && endOfFirstWordBoundaryContext(text.substring(start: offset)) == text.length() - offset
  {
    needMoreContext = true
    return text.length()
  }
  needMoreContext = false
  var end: Int32? = 0
  findEndWordBoundary(text, Int32(offset), &end)
  return UInt32(end!)
}

func endOfWord(c: VisiblePosition, side: WordSide = .RightWordIfOnBoundary) -> VisiblePosition {
  var p = c
  if side == .LeftWordIfOnBoundary {
    if isStartOfParagraph(pos: c) {
      return c
    }
    p = c.previous()
    if p.isNull() {
      return c
    }
  } else if isEndOfParagraph(pos: c) {
    return c
  }
  return nextBoundary(c: p, searchFunction: endWordBoundary)
}

func previousWordPositionBoundary(
  text: StringWrapperView, offset: UInt32, mayHaveMoreContext: BoundarySearchContextAvailability,
  needMoreContext: inout Bool
) -> UInt32 {
  if mayHaveMoreContext.rawValue != 0
    && !(startOfLastWordBoundaryContext(text.left(length: offset)) != 0)
  {
    needMoreContext = true
    return 0
  }
  needMoreContext = false
  return UInt32(findNextWordFromIndex(text, Int32(offset), false))
}

func previousWordPosition(position: VisiblePosition) -> VisiblePosition {
  return position.honorEditingBoundaryAtOrBefore(
    position: previousBoundary(position: position, searchFunction: previousWordPositionBoundary))
}

func nextWordPositionBoundary(
  text: StringWrapperView, offset: UInt32, mayHaveMoreContext: BoundarySearchContextAvailability,
  needMoreContext: inout Bool
) -> UInt32 {
  if mayHaveMoreContext.rawValue != 0
    && endOfFirstWordBoundaryContext(text.substring(start: offset)) == text.length() - offset
  {
    needMoreContext = true
    return text.length()
  }
  needMoreContext = false
  return UInt32(findNextWordFromIndex(text, Int32(offset), true))
}

func nextWordPosition(position: VisiblePosition) -> VisiblePosition {
  return position.honorEditingBoundaryAtOrAfter(
    otherPosition: nextBoundary(c: position, searchFunction: nextWordPositionBoundary))
}

func isStartOfWord(p: VisiblePosition) -> Bool {
  return p.isNotNull() && p == startOfWord(c: p, side: .RightWordIfOnBoundary)
}

func startPositionForLine(c: VisiblePosition, mode: LineEndpointComputationMode) -> VisiblePosition
{
  if c.isNull() {
    return VisiblePosition()
  }
  let lineBox = RenderedPosition(position: c).lineBox()
  if !lineBox.bool() {
    // There are VisiblePositions at offset 0 in blocks without
    // RootInlineBoxes, like empty editable blocks and bordered blocks.
    let p = c.deepEquivalent()
    if p.deprecatedNode()!.renderer() != nil && p.deprecatedNode()!.renderer()!.isRenderBlock()
      && !(p.deprecatedEditingOffset() != 0)
    {
      return c
    }
    return VisiblePosition()
  }
  let orderCache = InlineIterator.LineLogicalOrderCache()
  var startNode: NodeWrapper? = nil
  var startBox =
    mode == .UseLogicalOrdering
    ? InlineIterator.firstLeafOnLineInLogicalOrderWithNode(lineBox, orderCache)
    : lineBox.get().firstLeafBox()
  // Generated content (e.g. list markers and CSS :before and :after pseudoelements) have no corresponding DOM element,
  // and so cannot be represented by a VisiblePosition. Use whatever follows instead.
  while true {
    if !startBox.bool() {
      return VisiblePosition()
    }
    startNode = startBox.get().renderer().nonPseudoNode()
    if startNode != nil {
      break
    }
    if mode == .UseLogicalOrdering {
      startBox = InlineIterator.nextLeafOnLineInLogicalOrder(startBox, orderCache)
    } else {
      startBox.traverseNextOnLine()
    }
  }
  let startTextNode: TextWrapper? = startNode! as? TextWrapper
  return VisiblePosition(
    startTextNode != nil
      ? Position(
        textNode: startTextNode,
        offset: InlineIterator.TextBox(startBox.get().m_pathVariant).start())
      : positionBeforeNode(anchorNode: startNode))
}

func startOfLine(
  c: VisiblePosition, mode: LineEndpointComputationMode, reachedBoundary: inout Bool?
) -> VisiblePosition {
  if reachedBoundary != nil {
    reachedBoundary! = false
  }
  // TODO: this is the current behavior that might need to be fixed.
  // Please refer to https://bugs.webkit.org/show_bug.cgi?id=49107 for detail.
  let visPos = startPositionForLine(c: c, mode: mode)
  if mode == .UseLogicalOrdering {
    if let editableRoot = highestEditableRoot(position: c.deepEquivalent()) {
      if !(editableRoot.contains(visPos.deepEquivalent().containerNode())) {
        let newPosition = VisiblePosition(firstPositionInNode(anchorNode: editableRoot))
        if reachedBoundary != nil {
          reachedBoundary! = c == newPosition
        }
        return newPosition
      }
    }
  }
  return c.honorEditingBoundaryAtOrBefore(position: visPos, reachedBoundary: &reachedBoundary)
}

func startOfLine(currentPosition: VisiblePosition) -> VisiblePosition {
  var ignored: Bool? = nil
  return startOfLine(c: currentPosition, mode: .UseInlineBoxOrdering, reachedBoundary: &ignored)
}

func logicalStartOfLine(currentPosition: VisiblePosition, reachedBoundary: inout Bool?)
  -> VisiblePosition
{
  return startOfLine(
    c: currentPosition, mode: .UseLogicalOrdering, reachedBoundary: &reachedBoundary)
}

func logicalStartOfLine(currentPosition: VisiblePosition) -> VisiblePosition {
  var ignored: Bool? = nil
  return logicalStartOfLine(currentPosition: currentPosition, reachedBoundary: &ignored)
}

func endPositionForLine(c: VisiblePosition, mode: LineEndpointComputationMode) -> VisiblePosition {
  if c.isNull() {
    return VisiblePosition()
  }
  let lineBox = RenderedPosition(position: c).lineBox()
  if !lineBox.bool() {
    // There are VisiblePositions at offset 0 in blocks without
    // RootInlineBoxes, like empty editable blocks and bordered blocks.
    let p = c.deepEquivalent()
    if p.deprecatedNode()!.renderer() != nil && p.deprecatedNode()!.renderer()!.isRenderBlock()
      && !(p.deprecatedEditingOffset() != 0)
    {
      return c
    }
    return VisiblePosition()
  }
  let orderCache = InlineIterator.LineLogicalOrderCache()
  var endNode: NodeWrapper? = nil
  var endBox =
    mode == .UseLogicalOrdering
    ? InlineIterator.lastLeafOnLineInLogicalOrder(lineBox, orderCache) : lineBox.get().lastLeafBox()
  // Generated content (e.g. list markers and CSS :before and :after pseudoelements) have no corresponding DOM element,
  // and so cannot be represented by a VisiblePosition. Use whatever precedes instead.
  while true {
    if !endBox.bool() {
      return VisiblePosition()
    }
    endNode = endBox.get().renderer().nonPseudoNode()
    if endNode != nil {
      break
    }
    if mode == .UseLogicalOrdering {
      endBox = InlineIterator.previousLeafOnLineInLogicalOrder(endBox, orderCache)
    } else {
      endBox.traversePreviousOnLine()
    }
  }
  var pos = Position()
  if endNode! is HTMLBRElementWrapper {
    pos = positionBeforeNode(anchorNode: endNode)
  } else if let endTextNode = endNode! as? TextWrapper, endBox.get().isText() {
    let endTextBox = InlineIterator.TextBox(endBox.get().m_pathVariant)
    var endOffset: Int32 = Int32(endTextBox.start())
    if !endTextBox.isLineBreak() {
      endOffset += Int32(endTextBox.length())
    }
    pos = Position(textNode: endTextNode, offset: UInt32(endOffset))
  } else {
    pos = positionAfterNode(anchorNode: endNode)
  }
  return VisiblePosition(pos, .Upstream)
}

func inSameLogicalLine(a: VisiblePosition, b: VisiblePosition) -> Bool {
  return a.isNotNull()
    && logicalStartOfLine(currentPosition: a) == logicalStartOfLine(currentPosition: b)
}

func endOfLine(c: VisiblePosition, mode: LineEndpointComputationMode, reachedBoundary: inout Bool?)
  -> VisiblePosition
{
  if reachedBoundary != nil {
    reachedBoundary! = false
  }
  // TODO: this is the current behavior that might need to be fixed.
  // Please refer to https://bugs.webkit.org/show_bug.cgi?id=49107 for detail.
  var visPos = endPositionForLine(c: c, mode: mode)
  if mode == .UseLogicalOrdering {
    // Make sure the end of line is at the same line as the given input position. For a wrapping line, the logical end
    // position for the not-last-2-lines might incorrectly hand back the logical beginning of the next line.
    // For example, <div contenteditable dir="rtl" style="line-break:before-white-space">abcdefg abcdefg abcdefg
    // a abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg abcdefg </div>
    // In this case, use the previous position of the computed logical end position.
    if !inSameLogicalLine(a: c, b: visPos) {
      visPos = visPos.previous()
    }
    if let editableRoot = highestEditableRoot(position: c.deepEquivalent()) {
      if !(editableRoot.contains(visPos.deepEquivalent().containerNode())) {
        let newPosition = VisiblePosition(lastPositionInNode(anchorNode: editableRoot))
        if reachedBoundary != nil {
          reachedBoundary! = c == newPosition
        }
        return newPosition
      }
    }
    return c.honorEditingBoundaryAtOrAfter(otherPosition: visPos, reachedBoundary: &reachedBoundary)
  }
  // Make sure the end of line is at the same line as the given input position. Else use the previous position to
  // obtain end of line. This condition happens when the input position is before the space character at the end
  // of a soft-wrapped non-editable line. In this scenario, endPositionForLine would incorrectly hand back a position
  // in the next line instead. This fix is to account for the discrepancy between lines with webkit-line-break:after-white-space style
  // versus lines without that style, which would break before a space by default.
  if !inSameLine(a: c, b: visPos) {
    visPos = c.previous()
    if visPos.isNull() {
      return VisiblePosition()
    }
    visPos = endPositionForLine(c: visPos, mode: .UseInlineBoxOrdering)
  }
  return c.honorEditingBoundaryAtOrAfter(otherPosition: visPos, reachedBoundary: &reachedBoundary)
}

func endOfLine(currentPosition: VisiblePosition) -> VisiblePosition {
  var ignored: Bool? = nil
  return endOfLine(c: currentPosition, mode: .UseInlineBoxOrdering, reachedBoundary: &ignored)
}

func logicalEndOfLine(currentPosition: VisiblePosition, reachedBoundary: inout Bool?)
  -> VisiblePosition
{
  return endOfLine(c: currentPosition, mode: .UseLogicalOrdering, reachedBoundary: &reachedBoundary)
}

func logicalEndOfLine(currentPosition: VisiblePosition) -> VisiblePosition {
  var ignored: Bool? = nil
  return logicalEndOfLine(currentPosition: currentPosition, reachedBoundary: &ignored)
}

func inSameLine(a: VisiblePosition, b: VisiblePosition) -> Bool {
  return a.isNotNull() && startOfLine(currentPosition: a) == startOfLine(currentPosition: b)
}

func isStartOfLine(p: VisiblePosition) -> Bool {
  return p.isNotNull() && p == startOfLine(currentPosition: p)
}

func isEndOfLine(p: VisiblePosition) -> Bool {
  return p.isNotNull() && p == endOfLine(currentPosition: p)
}

func isLogicalEndOfLine(p: VisiblePosition) -> Bool {
  return p.isNotNull() && p == logicalEndOfLine(currentPosition: p)
}

func absoluteLineDirectionPointToLocalPointInBlock(
  lineBox: inout InlineIterator.LineBoxIterator, lineDirectionPoint: LayoutUnit
) -> LayoutPointWrapper {
  let root = lineBox.get().formattingContextRoot()
  let absoluteBlockPoint =
    root.localToAbsolute(localPoint: FloatPoint())
    - toFloatSize(a: FloatPoint(p: root.scrollPosition()))
  if root.isHorizontalWritingMode() {
    return LayoutPointWrapper(
      x: lineDirectionPoint - absoluteBlockPoint.x, y: contentStartInBlockDirection(lineBox.get()))
  }
  return LayoutPointWrapper(
    x: contentStartInBlockDirection(lineBox.get()), y: lineDirectionPoint - absoluteBlockPoint.y)
}

func rootEditableOrDocumentElement(node: NodeWrapper, editableType: EditableType) -> ElementWrapper?
{
  if hasEditableStyle(node: node, editableType: editableType) {
    return editableRootForPosition(
      position: firstPositionInOrBeforeNode(node), editableType: editableType)
  }
  return node.document().documentElement()
}

func previousLinePosition(
  visiblePosition: VisiblePosition, lineDirectionPoint: LayoutUnit,
  editableType: EditableType = .ContentIsEditable
) -> VisiblePosition {
  let p = visiblePosition.deepEquivalent()
  let node: NodeWrapper? = p.protectedDeprecatedNode()
  if node == nil {
    return VisiblePosition()
  }
  node!.protectedDocument().updateLayoutIgnorePendingStylesheets()
  let renderer: RenderObjectWrapper? = node!.renderer()
  if renderer == nil {
    return VisiblePosition()
  }
  var lineBox = InlineIterator.LineBoxIterator()
  let box = visiblePosition.inlineBoxAndOffset().box
  if box.bool() {
    lineBox = box.get().lineBox().get().previous()
    // We want to skip zero height boxes.
    // This could happen in case it is a LegacyRootInlineBox with trailing floats.
    if !lineBox.bool() || !(lineBox.get().logicalHeight() != 0)
      || !lineBox.get().firstLeafBox().bool()
    {
      lineBox = InlineIterator.LineBoxIterator()
    }
  }
  if !lineBox.bool() {
    let position = previousLineCandidatePosition(
      node: node, visiblePosition: visiblePosition, editableType: editableType)
    if position.isNotNull() {
      let renderedPosition = RenderedPosition(position: VisiblePosition(position))
      lineBox = renderedPosition.lineBox()
      if !lineBox.bool() {
        return VisiblePosition(position)
      }
    }
  }
  if lineBox.bool() {
    // FIXME: Can be wrong for multi-column layout and with transforms.
    let pointInLine = absoluteLineDirectionPointToLocalPointInBlock(
      lineBox: &lineBox, lineDirectionPoint: lineDirectionPoint)
    let box = closestBoxForHorizontalPosition(
      lineBox.get(), (lineBox.get().isHorizontal() ? pointInLine.x : pointInLine.y).toFloat(),
      isEditablePosition(position: p))
    if !box.bool() {
      return VisiblePosition()
    }
    let renderer = box.get().renderer()
    let node: NodeWrapper? = renderer.node()
    if node != nil && editingIgnoresContent(node: node!) {
      return VisiblePosition(positionInParentBeforeNode(node: node))
    }
    // FIXME: The HitTestSource state should be propagated down from calls into JavaScript bindings.
    // For the time being, just err on the side of passing in `Bindings`.
    return renderer.positionForPoint(pointInLine, .Script, nil)
    // FIXME: The HitTestSource state should be propagated down from calls into JavaScript bindings.
    // For the time being, just err on the side of passing in `Bindings`.
  }
  // Could not find a previous line. This means we must already be on the first line.
  // Move to the start of the content in this block, which effectively moves us
  // to the start of the line we're on.
  let rootElement: ElementWrapper? = rootEditableOrDocumentElement(
    node: node!, editableType: editableType)
  if rootElement == nil {
    return VisiblePosition()
  }
  return VisiblePosition(firstPositionInNode(anchorNode: rootElement))
}

func nextLinePosition(
  visiblePosition: VisiblePosition, lineDirectionPoint: LayoutUnit,
  editableType: EditableType = .ContentIsEditable
) -> VisiblePosition {
  let p = visiblePosition.deepEquivalent()
  var node: NodeWrapper? = p.protectedDeprecatedNode()
  if node == nil {
    return VisiblePosition()
  }
  node!.protectedDocument().updateLayoutIgnorePendingStylesheets()
  if node!.renderer() == nil {
    return VisiblePosition()
  }
  var lineBox = InlineIterator.LineBoxIterator()
  let box = visiblePosition.inlineBoxAndOffset().box
  if box.bool() {
    lineBox = box.get().lineBox().get().next()
    // We want to skip zero height boxes.
    // This could happen in case it is a LegacyRootInlineBox with trailing floats.
    if !lineBox.bool() || !(lineBox.get().logicalHeight() != 0)
      || !lineBox.get().firstLeafBox().bool()
    {
      lineBox = InlineIterator.LineBoxIterator()
    }
  }
  if !lineBox.bool() {
    // FIXME: We need do the same in previousLinePosition.
    if let child = node!.traverseToChildAt(UInt32(p.deprecatedEditingOffset())) {
      node = child
    } else {
      node = node!.lastDescendant()
    }
    let position = nextLineCandidatePosition(
      node: node, visiblePosition: visiblePosition, editableType: editableType)
    if position.isNotNull() {
      let renderedPosition = RenderedPosition(position: VisiblePosition(position))
      lineBox = renderedPosition.lineBox()
      if !lineBox.bool() {
        return VisiblePosition(position)
      }
    }
  }
  if lineBox.bool() {
    // FIXME: Can be wrong for multi-column layout and with transforms.
    let pointInLine = absoluteLineDirectionPointToLocalPointInBlock(
      lineBox: &lineBox, lineDirectionPoint: lineDirectionPoint)
    let box = closestBoxForHorizontalPosition(
      lineBox.get(), (lineBox.get().isHorizontal() ? pointInLine.x : pointInLine.y).toFloat(),
      isEditablePosition(position: p))
    if !box.bool() {
      return VisiblePosition()
    }
    let renderer = box.get().renderer()
    let node: NodeWrapper? = renderer.node()
    if node != nil && editingIgnoresContent(node: node!) {
      return VisiblePosition(positionInParentBeforeNode(node: node))
    }
    // FIXME: The HitTestSource state should be propagated down from calls into JavaScript bindings.
    // For the time being, just err on the side of passing in `Bindings`.
    return renderer.positionForPoint(pointInLine, .Script, nil)
    // FIXME: The HitTestSource state should be propagated down from calls into JavaScript bindings.
    // For the time being, just err on the side of passing in `Bindings`.
  }
  // Could not find a next line. This means we must already be on the last line.
  // Move to the end of the content in this block, which effectively moves us
  // to the end of the line we're on.
  let rootElement: ElementWrapper? = rootEditableOrDocumentElement(
    node: node!, editableType: editableType)
  if rootElement == nil {
    return VisiblePosition()
  }
  return VisiblePosition(lastPositionInNode(anchorNode: rootElement))
}

func startSentenceBoundary(
  text: StringWrapperView, _ arg1: UInt32, _ arg2: BoundarySearchContextAvailability,
  _ arg3: inout Bool
) -> UInt32 {
  // FIXME: The following function can return -1; we don't handle that.
  return UInt32(ubrk_preceding(sentenceBreakIterator(text), Int32(text.length())))
  // FIXME: The following function can return -1; we don't handle that.
}

func startOfSentence(position: VisiblePosition) -> VisiblePosition {
  return previousBoundary(
    position: position, searchFunction: startSentenceBoundary, needsContextAtParagraphStart: .Yes)
}

func endSentenceBoundary(
  text: StringWrapperView, _ arg1: UInt32, _ arg2: BoundarySearchContextAvailability,
  _ arg3: inout Bool
) -> UInt32 {
  return UInt32(ubrk_next(sentenceBreakIterator(text)))
}

func endOfSentence(position: VisiblePosition) -> VisiblePosition {
  // FIXME: This includes the space after the punctuation that marks the end of the sentence.
  return nextBoundary(c: position, searchFunction: endSentenceBoundary)
  // FIXME: This includes the space after the punctuation that marks the end of the sentence.
}

func previousSentencePositionBoundary(
  text: StringWrapperView, _ arg1: UInt32, _ arg2: BoundarySearchContextAvailability,
  _ arg3: inout Bool
) -> UInt32 {
  // FIXME: This is identical to startSentenceBoundary. I'm pretty sure that's not right.
  // FIXME: The following function can return -1; we don't handle that.
  return UInt32(ubrk_preceding(sentenceBreakIterator(text), Int32(text.length())))
  // FIXME: This is identical to startSentenceBoundary. I'm pretty sure that's not right.
  // FIXME: The following function can return -1; we don't handle that.
}

func previousSentencePosition(position: VisiblePosition) -> VisiblePosition {
  return position.honorEditingBoundaryAtOrBefore(
    position: previousBoundary(position: position, searchFunction: previousSentencePositionBoundary)
  )
}

func nextSentencePositionBoundary(
  text: StringWrapperView, _ arg1: UInt32, _ arg2: BoundarySearchContextAvailability,
  _ arg3: inout Bool
) -> UInt32 {
  // FIXME: This is identical to endSentenceBoundary.
  // That isn't right. This function needs to move to the equivalent position in the following sentence.
  return UInt32(ubrk_following(sentenceBreakIterator(text), 0))
  // FIXME: This is identical to endSentenceBoundary.
  // That isn't right. This function needs to move to the equivalent position in the following sentence.
}

func nextSentencePosition(position: VisiblePosition) -> VisiblePosition {
  return position.honorEditingBoundaryAtOrAfter(
    otherPosition: nextBoundary(c: position, searchFunction: nextSentencePositionBoundary))
}

func findStartOfParagraph(
  startNode: NodeWrapper?, highestRoot: NodeWrapper?, startBlock: NodeWrapper?, offset: inout Int32,
  type: inout AnchorType, boundaryCrossingRule: EditingBoundaryCrossingRule
) -> NodeWrapper? {
  var node: NodeWrapper? = startNode
  var n: NodeWrapper? = startNode
  let startNodeIsEditable: Bool = startNode!.hasEditableStyle()
  while n != nil {
    if boundaryCrossingRule == .CannotCrossEditingBoundary && !Position.nodeIsUserSelectAll(node: n)
      && n!.hasEditableStyle() != startNodeIsEditable
    {
      break
    }
    if boundaryCrossingRule == .CanSkipOverEditingBoundary {
      while n != nil && n!.hasEditableStyle() != startNodeIsEditable {
        n = previousPostOrder(n!, startBlock)
      }
      if n == nil || !n!.isDescendantOf(highestRoot) {
        break
      }
    }
    let r: RenderObjectWrapper? = n!.renderer()
    if r == nil {
      n = previousPostOrder(n!, startBlock)
      continue
    }
    let style = r!.style()
    if style.visibility() != .Visible {
      n = previousPostOrder(n!, startBlock)
      continue
    }
    if r!.isBRForRenderObject() || isBlock(node: n!) {
      break
    }
    if let renderText = r! as? RenderTextWrapper, renderText.hasRenderedText() {
      assert(n! is TextWrapper)
      type = .PositionIsOffsetInAnchor
      if style.preserveNewline() {
        let text = renderText.text()
        var i: Int32 = Int32(text.length())
        let o: Int32 = offset
        if CPtrToInt(n?.p) == CPtrToInt(startNode?.p) && o < i {
          i = max(0, o)
        }
        while true {
          i -= 1
          if !(i >= 0) {
            break
          }
          if Int32(text[UInt32(i)]) == Int32(10 /* '\n' */) {
            offset = i + 1
            return n
          }
        }
      }
      node = n
      offset = 0
      n = previousPostOrder(n!, startBlock)
    } else if editingIgnoresContent(node: n!) || isRenderedTable(node: n) {
      node = n
      type = .PositionIsBeforeAnchor
      n = n!.previousSibling() != nil ? n!.previousSibling() : previousPostOrder(n!, startBlock)
    } else {
      n = previousPostOrder(n!, startBlock)
    }
  }
  return node
}

func findEndOfParagraph(
  startNode: NodeWrapper?, highestRoot: NodeWrapper?, stayInsideBlock: NodeWrapper?,
  offset: inout Int32, type: inout AnchorType, boundaryCrossingRule: EditingBoundaryCrossingRule
) -> NodeWrapper? {
  var node: NodeWrapper? = startNode
  var n: NodeWrapper? = startNode
  let startNodeIsEditable: Bool = startNode!.hasEditableStyle()
  while n != nil {
    if boundaryCrossingRule == .CannotCrossEditingBoundary && !Position.nodeIsUserSelectAll(node: n)
      && n!.hasEditableStyle() != startNodeIsEditable
    {
      break
    }
    if boundaryCrossingRule == .CanSkipOverEditingBoundary {
      while n != nil && n!.hasEditableStyle() != startNodeIsEditable {
        n = next(n!, stayInsideBlock)
      }
      if n == nil || !n!.isDescendantOf(highestRoot) {
        break
      }
    }
    let r: RenderObjectWrapper? = n!.renderer()
    if r == nil {
      n = next(n!, stayInsideBlock)
      continue
    }
    let style = r!.style()
    if style.visibility() != .Visible {
      n = next(n!, stayInsideBlock)
      continue
    }
    // FIXME: This is wrong when startNode is a block. We should return a position after the block.
    if r!.isBRForRenderObject() || n! is HTMLBRElementWrapper || isBlock(node: n!) {
      break
    }
    // FIXME: We avoid returning a position where the renderer can't accept the caret.
    if let renderText = r! as? RenderTextWrapper, renderText.hasRenderedText() {
      assert(n! is TextWrapper)
      type = .PositionIsOffsetInAnchor
      if style.preserveNewline() {
        let text = renderText.text()
        let o: Int32 = CPtrToInt(n?.p) == CPtrToInt(startNode?.p) ? offset : 0
        let length: Int32 = Int32(text.length())
        var i: Int32 = o
        while i < length {
          if Int32(text[UInt32(i)]) == Int32(10 /* '\n' */) {
            offset = i
            return n
          }
          i += 1
        }
      }
      node = n
      offset = r!.caretMaxOffset()
      n = next(n!, stayInsideBlock)
    } else if editingIgnoresContent(node: n!) || isRenderedTable(node: n) {
      node = n
      type = .PositionIsAfterAnchor
      n = nextSkippingChildren(n!, stayInsideBlock)
    } else {
      n = next(n!, stayInsideBlock)
    }
  }
  return node
}

func startOfParagraph(
  c: VisiblePosition,
  boundaryCrossingRule: EditingBoundaryCrossingRule = .CannotCrossEditingBoundary
) -> VisiblePosition {
  let p = c.deepEquivalent()
  let startNode: NodeWrapper? = p.protectedDeprecatedNode()
  if startNode == nil {
    return VisiblePosition()
  }
  if isRenderedAsNonInlineTableImageOrHR(node: startNode) {
    return VisiblePosition(positionBeforeNode(anchorNode: startNode))
  }
  let startBlock: ElementWrapper? = enclosingBlock(node: startNode)
  let highestRoot: ContainerNodeWrapper? = highestEditableRoot(position: p)
  var offset: Int32 = p.deprecatedEditingOffset()
  var type = p.anchorType()
  let node: NodeWrapper? = findStartOfParagraph(
    startNode: startNode, highestRoot: highestRoot, startBlock: startBlock, offset: &offset,
    type: &type, boundaryCrossingRule: boundaryCrossingRule)
  if let textNode = node as? TextWrapper {
    return VisiblePosition(Position(textNode: textNode, offset: UInt32(offset)))
  }
  if type == .PositionIsOffsetInAnchor {
    assert(type == .PositionIsOffsetInAnchor || !(offset != 0))
    return VisiblePosition(Position(anchorNode: node, offset: UInt32(offset), anchorType: type))
  }
  return VisiblePosition(Position(anchorNode: node, anchorType: type))
}

func endOfParagraph(
  c: VisiblePosition,
  boundaryCrossingRule: EditingBoundaryCrossingRule = .CannotCrossEditingBoundary
) -> VisiblePosition {
  if c.isNull() {
    return VisiblePosition()
  }
  let p = c.deepEquivalent()
  let startNode: NodeWrapper? = p.protectedDeprecatedNode()
  if isRenderedAsNonInlineTableImageOrHR(node: startNode) {
    return VisiblePosition(positionAfterNode(anchorNode: startNode))
  }
  let stayInsideBlock: ElementWrapper? = enclosingBlock(node: startNode)
  let highestRoot: ContainerNodeWrapper? = highestEditableRoot(position: p)
  var offset: Int32 = p.deprecatedEditingOffset()
  var type = p.anchorType()
  let node: NodeWrapper? = findEndOfParagraph(
    startNode: startNode, highestRoot: highestRoot, stayInsideBlock: stayInsideBlock,
    offset: &offset, type: &type, boundaryCrossingRule: boundaryCrossingRule)
  if let textNode = node as? TextWrapper {
    return VisiblePosition(Position(textNode: textNode, offset: UInt32(offset)))
  }
  if type == .PositionIsOffsetInAnchor {
    return VisiblePosition(Position(anchorNode: node, offset: UInt32(offset), anchorType: type))
  }
  return VisiblePosition(Position(anchorNode: node, anchorType: type))
}

func startOfNextParagraph(visiblePosition: VisiblePosition) -> VisiblePosition {
  let paragraphEnd = endOfParagraph(
    c: visiblePosition, boundaryCrossingRule: .CanSkipOverEditingBoundary)
  let afterParagraphEnd = paragraphEnd.next(rule: .CannotCrossEditingBoundary)
  // The position after the last position in the last cell of a table
  // is not the start of the next paragraph.
  if isFirstPositionAfterTable(position: afterParagraphEnd) != nil {
    return afterParagraphEnd.next(rule: .CannotCrossEditingBoundary)
  }
  return afterParagraphEnd
}

func inSameParagraph(
  a: VisiblePosition, b: VisiblePosition,
  boundaryCrossingRule: EditingBoundaryCrossingRule = .CannotCrossEditingBoundary
) -> Bool {
  return a.isNotNull()
    && startOfParagraph(c: a, boundaryCrossingRule: boundaryCrossingRule)
      == startOfParagraph(c: b, boundaryCrossingRule: boundaryCrossingRule)
}

func isStartOfParagraph(
  pos: VisiblePosition,
  boundaryCrossingRule: EditingBoundaryCrossingRule = .CannotCrossEditingBoundary
) -> Bool {
  return pos.isNotNull()
    && pos == startOfParagraph(c: pos, boundaryCrossingRule: boundaryCrossingRule)
}

func isEndOfParagraph(
  pos: VisiblePosition,
  boundaryCrossingRule: EditingBoundaryCrossingRule = .CannotCrossEditingBoundary
) -> Bool {
  return pos.isNotNull()
    && pos == endOfParagraph(c: pos, boundaryCrossingRule: boundaryCrossingRule)
}

func isBlankParagraph(position: VisiblePosition) -> Bool {
  return isStartOfParagraph(pos: position)
    && startOfParagraph(c: position.next()) != startOfParagraph(c: position)
}

func previousParagraphPosition(p: VisiblePosition, x: LayoutUnit) -> VisiblePosition {
  var pos = p
  repeat {
    let n = previousLinePosition(visiblePosition: pos, lineDirectionPoint: x)
    if n.isNull() || n == pos {
      break
    }
    pos = n
  } while inSameParagraph(a: p, b: pos)
  return pos
}

func nextParagraphPosition(p: VisiblePosition, x: LayoutUnit) -> VisiblePosition {
  var pos = p
  repeat {
    let n = nextLinePosition(visiblePosition: pos, lineDirectionPoint: x)
    if n.isNull() || n == pos {
      break
    }
    pos = n
  } while inSameParagraph(a: p, b: pos)
  return pos
}

func startOfBlock(
  visiblePosition: VisiblePosition, rule: EditingBoundaryCrossingRule = .CannotCrossEditingBoundary
) -> VisiblePosition {
  let position = visiblePosition.deepEquivalent()
  var startBlock: NodeWrapper? = nil
  if position.containerNode() == nil {
    return VisiblePosition()
  }
  startBlock = enclosingBlock(node: position.protectedContainerNode(), rule: rule)
  if startBlock == nil {
    return VisiblePosition()
  }
  return VisiblePosition(firstPositionInNode(anchorNode: startBlock))
}

func endOfBlock(
  visiblePosition: VisiblePosition, rule: EditingBoundaryCrossingRule = .CannotCrossEditingBoundary
) -> VisiblePosition {
  let position = visiblePosition.deepEquivalent()
  var endBlock: NodeWrapper? = nil
  if position.containerNode() == nil {
    return VisiblePosition()
  }
  endBlock = enclosingBlock(node: position.protectedContainerNode(), rule: rule)
  if endBlock == nil {
    return VisiblePosition()
  }
  return VisiblePosition(lastPositionInNode(anchorNode: endBlock))
}

func inSameBlock(a: VisiblePosition, b: VisiblePosition) -> Bool {
  return !a.isNull()
    && CPtrToInt(enclosingBlock(node: a.deepEquivalent().protectedContainerNode())?.p)
      == CPtrToInt(enclosingBlock(node: b.deepEquivalent().protectedContainerNode())?.p)
}

func isStartOfBlock(pos: VisiblePosition) -> Bool {
  return pos.isNotNull()
    && pos == startOfBlock(visiblePosition: pos, rule: .CanCrossEditingBoundary)
}

func isEndOfBlock(pos: VisiblePosition) -> Bool {
  return pos.isNotNull() && pos == endOfBlock(visiblePosition: pos, rule: .CanCrossEditingBoundary)
}

func startOfDocument(node: NodeWrapper?) -> VisiblePosition {
  if node == nil || node!.document().documentElement() == nil {
    return VisiblePosition()
  }
  // The canonicalization of the position at (documentElement, 0) can turn the visible
  // position to null, even when there's a valid candidate to be had, because the root HTML element
  // is not content editable.  So we construct directly from the valid candidate.
  let documentElement: ElementWrapper? = node!.document().documentElement()
  let firstCandidate = nextCandidate(position: makeDeprecatedLegacyPosition(documentElement, 0))
  if firstCandidate.isNull() {
    return VisiblePosition()
  }
  return VisiblePosition(firstCandidate)
}

func startOfDocument(c: VisiblePosition) -> VisiblePosition {
  return startOfDocument(node: c.deepEquivalent().protectedDeprecatedNode())
}

func endOfDocument(node: NodeWrapper?) -> VisiblePosition {
  if node == nil || node!.document().documentElement() == nil {
    return VisiblePosition()
  }
  // (As above, in startOfDocument.)  The canonicalization can reject valid visible positions
  // when descending from the root element, so we construct the visible position directly from a
  // valid candidate.
  let documentElement: ElementWrapper? = node!.document().documentElement()
  let lastPosition = makeDeprecatedLegacyPosition(
    documentElement, documentElement!.countChildNodes())
  let lastCandidate = previousCandidate(position: lastPosition)
  if lastCandidate.isNull() {
    return VisiblePosition()
  }
  return VisiblePosition(lastCandidate)
}

func endOfDocument(c: VisiblePosition) -> VisiblePosition {
  return endOfDocument(node: c.deepEquivalent().protectedDeprecatedNode())
}

func isStartOfDocument(p: VisiblePosition) -> Bool {
  return p.isNotNull() && p.previous(rule: .CanCrossEditingBoundary).isNull()
}

func isEndOfDocument(p: VisiblePosition) -> Bool {
  return p.isNotNull() && p.next(rule: .CanCrossEditingBoundary).isNull()
}

func startOfEditableContent(visiblePosition: VisiblePosition) -> VisiblePosition {
  let highestRoot: ContainerNodeWrapper? = highestEditableRoot(
    position: visiblePosition.deepEquivalent())
  return highestRoot != nil
    ? VisiblePosition(firstPositionInNode(anchorNode: highestRoot)) : VisiblePosition()
}

func endOfEditableContent(visiblePosition: VisiblePosition) -> VisiblePosition {
  let highestRoot: ContainerNodeWrapper? = highestEditableRoot(
    position: visiblePosition.deepEquivalent())
  return highestRoot != nil
    ? VisiblePosition(lastPositionInNode(anchorNode: highestRoot)) : VisiblePosition()
}

func isEndOfEditableOrNonEditableContent(p: VisiblePosition) -> Bool {
  return p.isNotNull() && p.next().isNull()
}

func leftBoundaryOfLine(c: VisiblePosition, direction: TextDirection, reachedBoundary: inout Bool?)
  -> VisiblePosition
{
  return direction == .LTR
    ? logicalStartOfLine(currentPosition: c, reachedBoundary: &reachedBoundary)
    : logicalEndOfLine(currentPosition: c, reachedBoundary: &reachedBoundary)
}

func rightBoundaryOfLine(c: VisiblePosition, direction: TextDirection, reachedBoundary: inout Bool?)
  -> VisiblePosition
{
  return direction == .LTR
    ? logicalEndOfLine(currentPosition: c, reachedBoundary: &reachedBoundary)
    : logicalStartOfLine(currentPosition: c, reachedBoundary: &reachedBoundary)
}

func directionIsDownstream(direction: SelectionDirection) -> Bool {
  if direction == .Backward {
    return false
  }
  if direction == .Forward {
    return true
  }
  // FIXME: this code doesn't take into account the original direction of the element.
  // I'm not fixing this now because I'm afraid there is some code in UIKit relying on
  // this wrong behavior.
  return direction == .Right
  // FIXME: this code doesn't take into account the original direction of the element.
  // I'm not fixing this now because I'm afraid there is some code in UIKit relying on
  // this wrong behavior.
}

func atBoundaryOfGranularity(
  vp: VisiblePosition, granularity: TextGranularity, direction: SelectionDirection
) -> Bool {
  if granularity == .CharacterGranularity {
    return true
  }
  var boundary = VisiblePosition()
  let useDownstream: Bool = directionIsDownstream(direction: direction)
  switch granularity {
  case .WordGranularity:
    if (useDownstream && isStartOfParagraph(pos: vp))
      || (!useDownstream && isEndOfParagraph(pos: vp))
    {
      return false
    }
    boundary =
      useDownstream
      ? endOfWord(c: vp, side: .LeftWordIfOnBoundary)
      : startOfWord(c: vp, side: .RightWordIfOnBoundary)
    break
  case .SentenceGranularity:
    do {
      let boundaryInDirection = useDownstream ? endOfSentence : startOfSentence
      if vp == boundaryInDirection(vp) {
        boundary = vp
        break
      }
      let position =
        useDownstream ? previousSentencePosition(position: vp) : nextSentencePosition(position: vp)
      boundary = boundaryInDirection(position)
      break
    }
  case .LineGranularity:
    boundary = vp
    boundary.setAffinity(affinity: useDownstream ? .Upstream : .Downstream)
    boundary =
      useDownstream ? endOfLine(currentPosition: boundary) : startOfLine(currentPosition: boundary)
    break
  case .ParagraphGranularity:
    boundary = useDownstream ? endOfParagraph(c: vp) : startOfParagraph(c: vp)
    break
  case .DocumentGranularity:
    boundary = useDownstream ? endOfDocument(c: vp) : startOfDocument(c: vp)
    break
  default:
    assertionFailure()
    break
  }
  return vp == boundary
}

func withinTextUnitOfGranularity(
  vp: VisiblePosition, granularity: TextGranularity, direction: SelectionDirection
) -> Bool {
  if granularity == .CharacterGranularity || granularity == .DocumentGranularity {
    return true
  }
  let useDownstream: Bool = directionIsDownstream(direction: direction)
  var prevBoundary = VisiblePosition()
  var nextBoundary = VisiblePosition()
  switch granularity {
  case .WordGranularity:
    prevBoundary = startOfWord(
      c: vp, side: (useDownstream ? .RightWordIfOnBoundary : .LeftWordIfOnBoundary))
    nextBoundary = endOfWord(
      c: vp, side: (useDownstream ? .RightWordIfOnBoundary : .LeftWordIfOnBoundary))
    if endOfWord(c: prevBoundary, side: .RightWordIfOnBoundary) != nextBoundary {
      return false
    }
    break
  case .SentenceGranularity:
    prevBoundary = startOfSentence(position: vp)
    nextBoundary = endOfSentence(position: vp)
    break
  case .LineGranularity:
    prevBoundary = startOfLine(currentPosition: vp)
    nextBoundary = endOfLine(currentPosition: vp)
    if prevBoundary == nextBoundary {
      nextBoundary = nextLinePosition(
        visiblePosition: nextBoundary, lineDirectionPoint: LayoutUnit(value: 0))
      nextBoundary.setAffinity(affinity: .Upstream)
      if !inSameLine(a: prevBoundary, b: nextBoundary) {
        nextBoundary = vp.next()
      }
    }
    break
  case .ParagraphGranularity:
    prevBoundary = startOfParagraph(c: vp)
    nextBoundary = endOfParagraph(c: vp)
    break
  default:
    assertionFailure()
    break
  }
  if prevBoundary == nextBoundary {
    return false
  }
  if vp == prevBoundary {
    return useDownstream
  }
  if vp == nextBoundary {
    return !useDownstream
  }
  return (prevBoundary < vp && vp < nextBoundary)
}

func nextCharacterBoundaryInDirection(
  vp: VisiblePosition, direction: SelectionDirection, rule: EditingBoundaryCrossingRule
) -> VisiblePosition {
  return directionIsDownstream(direction: direction) ? vp.next(rule: rule) : vp.previous(rule: rule)
}

func nextWordBoundaryInDirection(vp: VisiblePosition, direction: SelectionDirection)
  -> VisiblePosition
{
  let useDownstream: Bool = directionIsDownstream(direction: direction)
  let withinUnitOfGranularity: Bool = withinTextUnitOfGranularity(
    vp: vp, granularity: .WordGranularity, direction: direction)
  var result = VisiblePosition()
  if useDownstream {
    if withinUnitOfGranularity {
      result = endOfWord(c: vp, side: .RightWordIfOnBoundary)
    } else {
      var start = startOfWord(c: vp, side: .RightWordIfOnBoundary)
      if start > vp && start != endOfWord(c: start) {
        result = start
      } else {
        // Do same thing as backwards traveling below.
        start = vp
        while true {
          result = startOfWord(c: nextWordPosition(position: start), side: .RightWordIfOnBoundary)
          if result == start {
            break
          }
          // We failed to find a word boundary.
          if result.isNull() || result < start {
            return VisiblePosition()
          }
          // We consider successs also the case where start is before element and result is after.
          // This covers moving past images like words.
          if result != endOfWord(c: result)
            || (CPtrToInt(result.deepEquivalent().anchorNode()?.p)
              == CPtrToInt(start.deepEquivalent().anchorNode()?.p)
              && result.deepEquivalent().anchorType() == .PositionIsAfterAnchor
              && start.deepEquivalent().anchorType() == .PositionIsBeforeAnchor)
          {
            break
          }
          start = result
        }
      }
    }
  } else {
    if withinUnitOfGranularity {
      result = startOfWord(c: vp, side: .LeftWordIfOnBoundary)
    } else {
      // This is complicated because:
      //   When given "Blah blah.|", endOfWord is "Blah blah|.", and previousWordPosition is "Blah| blah."
      //   When given "Blah blah. |", endOfWord is "Blah blah.| ", and previousWordPosition is "Blah |blah. ".
      var end = endOfWord(c: vp, side: .LeftWordIfOnBoundary)
      if end < vp && end != startOfWord(c: end) {
        result = end
      } else {
        end = vp
        while true {
          result = endOfWord(c: previousWordPosition(position: end), side: .RightWordIfOnBoundary)
          if result == end {
            break
          }
          if result.isNull() || result > end {
            return VisiblePosition()
          }
          if result != startOfWord(c: result) {
            break
          }
          end = result
        }
      }
    }
  }
  if result == vp {
    return VisiblePosition()
  }
  return result
}

func nextSentenceBoundaryInDirection(vp: VisiblePosition, direction: SelectionDirection)
  -> VisiblePosition
{
  let useDownstream: Bool = directionIsDownstream(direction: direction)
  var result = vp
  repeat {
    if withinTextUnitOfGranularity(
      vp: result, granularity: .SentenceGranularity, direction: direction)
    {
      result = useDownstream ? endOfSentence(position: result) : startOfSentence(position: result)
    } else {
      let nextPosition =
        useDownstream
        ? nextSentencePosition(position: result) : previousSentencePosition(position: result)
      if nextPosition.isNull() || nextPosition == result {
        return VisiblePosition()
      }
      var newResult =
        useDownstream
        ? startOfSentence(position: nextPosition) : endOfSentence(position: nextPosition)
      if areVisiblePositionsInSameTreeScope(a: newResult, b: result)
        && (useDownstream ? newResult < result : newResult > result)
      {
        newResult =
          useDownstream
          ? endOfSentence(position: nextPosition) : startOfSentence(position: nextPosition)
      }
      if newResult == result {
        break
      }
      result = newResult
    }
  } while areVisiblePositionsInSameTreeScope(a: result, b: vp)
    && (useDownstream ? (result < vp) : (result > vp))
  if result == vp {
    return VisiblePosition()
  }
  return result
}

func nextLineBoundaryInDirection(vp: VisiblePosition, direction: SelectionDirection)
  -> VisiblePosition
{
  let useDownstream: Bool = directionIsDownstream(direction: direction)
  var result = vp
  if useDownstream {
    result.setAffinity(affinity: .Downstream)
    result =
      isEndOfLine(p: result)
      ? startOfLine(
        currentPosition: nextLinePosition(
          visiblePosition: result,
          lineDirectionPoint: LayoutUnit(
            value: result.lineDirectionPointForBlockDirectionNavigation())))
      : endOfLine(currentPosition: result)
  } else {
    result.setAffinity(affinity: .Upstream)
    result =
      isStartOfLine(p: result)
      ? endOfLine(
        currentPosition: previousLinePosition(
          visiblePosition: result,
          lineDirectionPoint: LayoutUnit(
            value: result.lineDirectionPointForBlockDirectionNavigation())))
      : startOfLine(currentPosition: result)
  }
  return result
}

func nextParagraphBoundaryInDirection(position: VisiblePosition, direction: SelectionDirection)
  -> VisiblePosition
{
  let useDownstream: Bool = directionIsDownstream(direction: direction)
  let lineDirection: Int32 = position.lineDirectionPointForBlockDirectionNavigation()
  if atBoundaryOfGranularity(vp: position, granularity: .ParagraphGranularity, direction: direction)
  {
    return useDownstream
      ? startOfParagraph(c: nextParagraphPosition(p: position, x: LayoutUnit(value: lineDirection)))
      : endOfParagraph(
        c: previousParagraphPosition(p: position, x: LayoutUnit(value: lineDirection)))
  }
  assert(
    withinTextUnitOfGranularity(
      vp: position, granularity: .ParagraphGranularity, direction: direction))
  return useDownstream ? endOfParagraph(c: position) : startOfParagraph(c: position)
}

func nextDocumentBoundaryInDirection(vp: VisiblePosition, direction: SelectionDirection)
  -> VisiblePosition
{
  return directionIsDownstream(direction: direction) ? endOfDocument(c: vp) : startOfDocument(c: vp)
}

func positionOfNextBoundaryOfGranularity(
  vp: VisiblePosition, granularity: TextGranularity, direction: SelectionDirection
) -> VisiblePosition {
  switch granularity {
  case .CharacterGranularity:
    return nextCharacterBoundaryInDirection(
      vp: vp, direction: direction, rule: .CanCrossEditingBoundary)
  case .WordGranularity:
    return nextWordBoundaryInDirection(vp: vp, direction: direction)
  case .SentenceGranularity:
    return nextSentenceBoundaryInDirection(vp: vp, direction: direction)
  case .LineGranularity:
    return nextLineBoundaryInDirection(vp: vp, direction: direction)
  case .ParagraphGranularity:
    return nextParagraphBoundaryInDirection(position: vp, direction: direction)
  case .DocumentGranularity:
    return nextDocumentBoundaryInDirection(vp: vp, direction: direction)
  default:
    assertionFailure()
    return VisiblePosition()
  }
}

func enclosingTextUnitOfGranularity(
  vp: VisiblePosition, granularity: TextGranularity, direction: SelectionDirection
) -> SimpleRange? {
  fatalError("Not implemented")
}

func distanceBetweenPositions(a: VisiblePosition, b: VisiblePosition) -> Int {
  fatalError("Not implemented")
}

func charactersAroundPosition(
  position: VisiblePosition, oneAfter: inout UInt32, oneBefore: inout UInt32,
  twoBefore: inout UInt32
) {
  fatalError("Not implemented")
}

func wordRangeFromPosition(position: VisiblePosition) -> SimpleRange? {
  fatalError("Not implemented")
}

func closestWordBoundaryForPosition(position: VisiblePosition) -> VisiblePosition {
  var result = VisiblePosition()
  if atBoundaryOfGranularity(vp: position, granularity: .LineGranularity, direction: .Forward) {
    // Don't cross line boundaries.
    result = position
  } else if withinTextUnitOfGranularity(
    vp: position, granularity: .WordGranularity, direction: .Forward)
  {
    // The position lies within a word.
    if let wordRange = enclosingTextUnitOfGranularity(
      vp: position, granularity: .WordGranularity, direction: .Forward)
    {
      result = VisiblePosition(makeDeprecatedLegacyPosition(point: wordRange.start))
      if distanceBetweenPositions(a: position, b: result) > 1 {
        result = VisiblePosition(makeDeprecatedLegacyPosition(point: wordRange.end))
      }
    }
  } else if atBoundaryOfGranularity(
    vp: position, granularity: .WordGranularity, direction: .Backward)
  {
    // The position is at the end of a word.
    result = position
  } else {
    // The position is not within a word.
    // Go to the next boundary.
    result = positionOfNextBoundaryOfGranularity(
      vp: position, granularity: .WordGranularity, direction: .Forward)
    // If there is no such boundary we go to the end of the element.
    if result.isNull() {
      result = endOfEditableContent(visiblePosition: position)
    }
  }
  return result
}

func rangeExpandedByCharactersInDirectionAtWordBoundary(
  position: VisiblePosition, numberOfCharactersToExpand: Int32, direction: SelectionDirection
) -> SimpleRange? {
  fatalError("Not implemented")
}

func rangeExpandedAroundPositionByCharacters(
  position: VisiblePosition, numberOfCharactersToExpand: Int32
) -> SimpleRange? {
  fatalError("Not implemented")
}

func rangeExpandedAroundRangeByCharacters(
  selection: VisibleSelectionWrapper, numberOfCharactersToExpandBackwards: UInt64,
  numberOfCharactersToExpandForwards: UInt64
) -> SimpleRange? {
  fatalError("Not implemented")
}

func wordBoundaryForPositionWithoutCrossingLine(position: VisiblePosition) -> (
  VisiblePosition, WithinWordBoundary
) {
  if atBoundaryOfGranularity(vp: position, granularity: .LineGranularity, direction: .Forward) {
    return (position, .No)
  }
  if withinTextUnitOfGranularity(vp: position, granularity: .WordGranularity, direction: .Forward) {
    var adjustedPosition = position
    if let wordRange = enclosingTextUnitOfGranularity(
      vp: position, granularity: .WordGranularity, direction: .Forward)
    {
      adjustedPosition = VisiblePosition(makeDeprecatedLegacyPosition(point: wordRange.start))
      if distanceBetweenPositions(a: position, b: adjustedPosition) > 1 {
        adjustedPosition = VisiblePosition(makeDeprecatedLegacyPosition(point: wordRange.end))
      }
    }
    return (adjustedPosition, .Yes)
  }
  if atBoundaryOfGranularity(vp: position, granularity: .WordGranularity, direction: .Backward) {
    return (position, .No)
  }
  let nextWordBoundary = positionOfNextBoundaryOfGranularity(
    vp: position, granularity: .WordGranularity, direction: .Forward)
  return (
    nextWordBoundary.isNotNull()
      ? nextWordBoundary : endOfEditableContent(visiblePosition: position), .No
  )
}
