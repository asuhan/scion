/*
 * Copyright (C) 2004-2022 Apple Inc. All rights reserved.
 * Copyright (C) 2015-2018 Google Inc. All rights reserved.
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

struct Position {
  init() {
    self.m_anchorNode = nil
    self.m_anchorType = UInt32(AnchorType.PositionIsOffsetInAnchor.rawValue)
    self.isLegacyEditingPosition = false
  }

  func anchorType() -> AnchorType {
    return AnchorType(rawValue: Int32(m_anchorType))!
  }

  mutating func clear() {
    m_anchorNode = nil
    offset = 0
    m_anchorType = UInt32(AnchorType.PositionIsOffsetInAnchor.rawValue)
    isLegacyEditingPosition = false
  }

  func protectedContainerNode() -> NodeWrapper? {
    return containerNode()
  }

  func offsetInContainerNode() -> Int32 {
    assert(anchorType() == .PositionIsOffsetInAnchor)
    return Int32(offset)
  }

  func deprecatedEditingOffset() -> Int32 {
    if isLegacyEditingPosition
      || (Int32(m_anchorType) != Int32(AnchorType.PositionIsAfterAnchor.rawValue)
        && Int32(m_anchorType) != Int32(AnchorType.PositionIsAfterChildren.rawValue))
    {
      return Int32(offset)
    }
    return offsetForPositionAfterAnchor()
  }

  func anchorNode() -> NodeWrapper? {
    return m_anchorNode
  }

  func protectedAnchorNode() -> NodeWrapper? {
    return m_anchorNode
  }

  func deprecatedNode() -> NodeWrapper? {
    return m_anchorNode
  }

  func protectedDeprecatedNode() -> NodeWrapper? {
    return m_anchorNode
  }

  func document() -> Document? {
    return m_anchorNode != nil ? m_anchorNode!.document() : nil
  }

  func treeScope() -> TreeScopeWrapper? {
    return m_anchorNode != nil ? m_anchorNode!.treeScope() : nil
  }

  func rootEditableElement() -> ElementWrapper? {
    let container: NodeWrapper? = containerNode()
    return container != nil ? container!.rootEditableElement() : nil
  }

  func isNull() -> Bool {
    return m_anchorNode == nil
  }

  func isNotNull() -> Bool {
    return m_anchorNode != nil
  }

  func isOrphan() -> Bool {
    return m_anchorNode != nil && !m_anchorNode!.isConnected()
  }

  init(anchorNode: NodeWrapper?, offset: UInt32, _ arg2: LegacyEditingPositionFlag) {
    self.m_anchorNode = anchorNode
    self.offset = offset
    self.m_anchorType = UInt32(
      Position.anchorTypeForLegacyEditingPosition(anchorNode: m_anchorNode, offset: self.offset)
        .rawValue)
    self.isLegacyEditingPosition = true
    assert(
      m_anchorNode == nil || !m_anchorNode!.isShadowRoot()
        || CPtrToInt(m_anchorNode?.p) == CPtrToInt(containerNode()?.p))
    assert(m_anchorNode == nil || !m_anchorNode!.isPseudoElement())
  }

  init(anchorNode: NodeWrapper?, anchorType: AnchorType) {
    self.m_anchorNode = anchorNode
    self.offset = 0
    self.m_anchorType = UInt32(anchorType.rawValue)
    self.isLegacyEditingPosition = false
    assert(
      m_anchorNode == nil || !m_anchorNode!.isShadowRoot()
        || CPtrToInt(m_anchorNode?.p) == CPtrToInt(containerNode()?.p))
    assert(m_anchorNode == nil || !m_anchorNode!.isPseudoElement())
    assert(anchorType != .PositionIsOffsetInAnchor)
    assert(
      !(((anchorType == .PositionIsBeforeChildren || anchorType == .PositionIsAfterChildren)
        && (m_anchorNode! is TextWrapper || editingIgnoresContent(node: m_anchorNode!)))))
  }

  init(anchorNode: NodeWrapper?, offset: UInt32, anchorType: AnchorType) {
    self.m_anchorNode = anchorNode
    self.offset = offset
    self.m_anchorType = UInt32(anchorType.rawValue)
    self.isLegacyEditingPosition = false
    assert(anchorType == .PositionIsOffsetInAnchor)
  }

  init(textNode: TextWrapper?, offset: UInt32) {
    self.m_anchorNode = textNode
    self.offset = offset
    self.m_anchorType = UInt32(AnchorType.PositionIsOffsetInAnchor.rawValue)
    self.isLegacyEditingPosition = false
    assert(m_anchorNode != nil)
  }

  mutating func moveToPosition(node: NodeWrapper?, offset: UInt32) {
    assert(!editingIgnoresContent(node: node!))
    assert(anchorType() == .PositionIsOffsetInAnchor || isLegacyEditingPosition)
    m_anchorNode = node
    self.offset = offset
    if isLegacyEditingPosition {
      m_anchorType = UInt32(
        Position.anchorTypeForLegacyEditingPosition(anchorNode: m_anchorNode, offset: self.offset)
          .rawValue)
    }
  }

  mutating func moveToOffset(offset: UInt32) {
    assert(anchorType() == .PositionIsOffsetInAnchor || isLegacyEditingPosition)
    self.offset = offset
    if isLegacyEditingPosition {
      m_anchorType = UInt32(
        Position.anchorTypeForLegacyEditingPosition(anchorNode: m_anchorNode, offset: self.offset)
          .rawValue)
    }
  }

  func containerNode() -> NodeWrapper? {
    if m_anchorNode == nil {
      return nil
    }
    switch anchorType() {
    case .PositionIsBeforeChildren, .PositionIsAfterChildren, .PositionIsOffsetInAnchor:
      return m_anchorNode
    case .PositionIsBeforeAnchor, .PositionIsAfterAnchor:
      return m_anchorNode!.parentNode()
    }
  }

  func containerText() -> TextWrapper? {
    switch anchorType() {
    case .PositionIsOffsetInAnchor:
      return m_anchorNode as? TextWrapper
    case .PositionIsBeforeAnchor, .PositionIsAfterAnchor:
      return nil
    case .PositionIsBeforeChildren, .PositionIsAfterChildren:
      assert(m_anchorNode == nil || !(m_anchorNode! is TextWrapper))
      return nil
    }
  }

  func protectedContainerText() -> TextWrapper? {
    return containerText()
  }

  func containerOrParentElement() -> ElementWrapper? {
    let container: NodeWrapper? = containerNode()
    if container == nil {
      return nil
    }
    if let element = container! as? ElementWrapper {
      return element
    }
    return container!.parentElement()
  }

  func computeOffsetInContainerNode() -> Int32 {
    if m_anchorNode == nil {
      return 0
    }
    switch anchorType() {
    case .PositionIsBeforeChildren:
      return 0
    case .PositionIsAfterChildren:
      return Int32(m_anchorNode!.length())
    case .PositionIsOffsetInAnchor:
      return Int32(offset)
    case .PositionIsBeforeAnchor:
      return Int32(m_anchorNode!.computeNodeIndex())
    case .PositionIsAfterAnchor:
      return Int32(m_anchorNode!.computeNodeIndex() + 1)
    }
  }

  func offsetForPositionAfterAnchor() -> Int32 {
    assert(
      Int32(m_anchorType) == Int32(AnchorType.PositionIsAfterAnchor.rawValue)
        || Int32(m_anchorType) == Int32(AnchorType.PositionIsAfterChildren.rawValue))
    assert(!isLegacyEditingPosition)
    let anchorNode: NodeWrapper? = self.anchorNode()
    assert(anchorNode != nil)
    return anchorNode != nil ? lastOffsetForEditing(node: anchorNode!) : 0
  }

  func parentAnchoredEquivalent() -> Position {
    let anchorNode: NodeWrapper? = self.anchorNode()
    if anchorNode == nil {
      return Position()
    }
    // FIXME: This should only be necessary for legacy positions, but is also needed for positions before and after Tables
    if !(offset != 0)
      && (Int32(m_anchorType) != Int32(AnchorType.PositionIsAfterAnchor.rawValue)
        && Int32(m_anchorType) != Int32(AnchorType.PositionIsAfterChildren.rawValue))
    {
      if anchorNode!.parentNode() != nil
        && (editingIgnoresContent(node: anchorNode!) || isRenderedTable(node: anchorNode))
      {
        return positionInParentBeforeNode(node: anchorNode)
      }
      return Position(anchorNode: anchorNode, offset: 0, anchorType: .PositionIsOffsetInAnchor)
    }
    if !anchorNode!.isCharacterDataNode()
      && (Int32(m_anchorType) == Int32(AnchorType.PositionIsAfterAnchor.rawValue)
        || Int32(m_anchorType) == Int32(AnchorType.PositionIsAfterChildren.rawValue)
        || UInt32(offset) == anchorNode!.countChildNodes())
      && (editingIgnoresContent(node: anchorNode!) || isRenderedTable(node: anchorNode))
      && containerNode() != nil
    {
      return positionInParentAfterNode(node: anchorNode)
    }
    return Position(
      anchorNode: containerNode(), offset: UInt32(UInt32(computeOffsetInContainerNode())),
      anchorType: .PositionIsOffsetInAnchor)
  }

  func firstNode() -> NodeWrapper? {
    let container: NodeWrapper? = containerNode()
    if container == nil {
      return nil
    }
    if container! is CharacterDataWrapper {
      return container
    }
    if let node = computeNodeAfterPosition() {
      return node
    }
    if !(computeOffsetInContainerNode() != 0) {
      return container
    }
    return nextSkippingChildren(container!)
  }

  func computeNodeBeforePosition() -> NodeWrapper? {
    if m_anchorNode == nil {
      return nil
    }
    switch anchorType() {
    case .PositionIsBeforeChildren:
      return nil
    case .PositionIsAfterChildren:
      return m_anchorNode!.lastChild()
    case .PositionIsOffsetInAnchor:
      return offset != 0 ? m_anchorNode!.traverseToChildAt(offset - 1) : nil
    case .PositionIsBeforeAnchor:
      return m_anchorNode!.previousSibling()
    case .PositionIsAfterAnchor:
      return m_anchorNode
    }
  }

  func computeNodeAfterPosition() -> NodeWrapper? {
    if m_anchorNode == nil {
      return nil
    }
    switch anchorType() {
    case .PositionIsBeforeChildren:
      return m_anchorNode!.firstChild()
    case .PositionIsAfterChildren:
      return nil
    case .PositionIsOffsetInAnchor:
      return m_anchorNode!.traverseToChildAt(offset)
    case .PositionIsBeforeAnchor:
      return m_anchorNode
    case .PositionIsAfterAnchor:
      return m_anchorNode!.nextSibling()
    }
  }

  static func anchorTypeForLegacyEditingPosition(anchorNode: NodeWrapper?, offset: UInt32)
    -> AnchorType
  {
    if anchorNode != nil && editingIgnoresContent(node: anchorNode!) {
      if offset == 0 {
        return .PositionIsBeforeAnchor
      }
      return .PositionIsAfterAnchor
    }
    return .PositionIsOffsetInAnchor
  }

  func anchorElementAncestor() -> ElementWrapper? {
    var node: NodeWrapper? = anchorNode()
    while node != nil {
      if let element = node! as? ElementWrapper {
        return element
      }
      node = node!.parentNode()
    }
    return nil
  }

  func previous(moveType: PositionMoveType = .CodePoint) -> Position {
    var node: NodeWrapper? = protectedDeprecatedNode()
    if node == nil {
      return self
    }
    // FIXME: Negative offsets shouldn't be allowed. We should catch this earlier.
    assert(deprecatedEditingOffset() >= 0)
    var offset: UInt32 = UInt32(deprecatedEditingOffset())
    if anchorType() == .PositionIsBeforeAnchor {
      node = containerNode()
      if node == nil {
        return self
      }
      offset = UInt32(computeOffsetInContainerNode())
    }
    if offset > 0 {
      if let child = node!.traverseToChildAt(offset - 1) {
        return lastPositionInOrAfterNode(child)
      }
      // There are two reasons child might be 0:
      //   1) The node is node like a text node that is not an element, and therefore has no children.
      //      Going backward one character at a time is correct.
      //   2) The old offset was a bogus offset like (<br>, 1), and there is no child.
      //      Going from 1 to 0 is correct.
      switch moveType {
      case .CodePoint:
        return makeDeprecatedLegacyPosition(node, offset - 1)
      case .Character:
        do {
          let previousOffset: Int32 = Position.uncheckedPreviousOffset(n: node, current: offset)
          return makeDeprecatedLegacyPosition(node, UInt32(previousOffset))
        }
      case .BackwardDeletion:
        do {
          let previousOffset: Int32 = Position.uncheckedPreviousOffsetForBackwardDeletion(
            n: node, current: offset)
          return makeDeprecatedLegacyPosition(node, UInt32(previousOffset))
        }
      }
      // There are two reasons child might be 0:
      //   1) The node is node like a text node that is not an element, and therefore has no children.
      //      Going backward one character at a time is correct.
      //   2) The old offset was a bogus offset like (<br>, 1), and there is no child.
      //      Going from 1 to 0 is correct.
    }
    let parent: ContainerNodeWrapper? = node!.parentNode()
    if parent == nil {
      return self
    }
    if positionBeforeOrAfterNodeIsCandidate(node: node!) {
      return positionBeforeNode(anchorNode: node)
    }
    let previousSibling: NodeWrapper? = node!.previousSibling()
    if previousSibling != nil && positionBeforeOrAfterNodeIsCandidate(node: previousSibling!) {
      return positionAfterNode(anchorNode: previousSibling)
    }
    return makeContainerOffsetPosition(node: parent, offset: node!.computeNodeIndex())
  }

  func next(moveType: PositionMoveType = .CodePoint) -> Position {
    assert(moveType != .BackwardDeletion)
    var node: NodeWrapper? = protectedDeprecatedNode()
    if node == nil {
      return self
    }
    // FIXME: Negative offsets shouldn't be allowed. We should catch this earlier.
    assert(deprecatedEditingOffset() >= 0)
    var offset: UInt32 = UInt32(deprecatedEditingOffset())
    if anchorType() == .PositionIsAfterAnchor {
      node = containerNode()
      if node == nil {
        return self
      }
      offset = UInt32(computeOffsetInContainerNode())
    }
    let child: NodeWrapper? = node!.traverseToChildAt(offset)
    if child != nil
      || (!node!.hasChildNodes() && offset < UInt32(UInt32(lastOffsetForEditing(node: node!))))
    {
      if child != nil {
        return firstPositionInOrBeforeNode(child)
      }
      // There are two reasons child might be 0:
      //   1) The node is node like a text node that is not an element, and therefore has no children.
      //      Going forward one character at a time is correct.
      //   2) The new offset is a bogus offset like (<br>, 1), and there is no child.
      //      Going from 0 to 1 is correct.
      let nextOffset: UInt32 =
        moveType == .Character
        ? UInt32(Position.uncheckedNextOffset(n: node, current: offset)) : offset + 1
      return makeDeprecatedLegacyPosition(node, nextOffset)
    }
    let parent: ContainerNodeWrapper? = node!.parentNode()
    if parent == nil {
      return self
    }
    if isRenderedTable(node: node) || editingIgnoresContent(node: node!) {
      return positionAfterNode(anchorNode: node)
    }
    let nextSibling: NodeWrapper? = node!.nextSibling()
    if nextSibling != nil && positionBeforeOrAfterNodeIsCandidate(node: nextSibling!) {
      return positionBeforeNode(anchorNode: nextSibling)
    }
    return makeContainerOffsetPosition(node: parent, offset: node!.computeNodeIndex() + 1)
  }

  static func uncheckedPreviousOffset(n: NodeWrapper?, current: UInt32) -> Int32 {
    return Int32(
      n!.renderer() != nil ? UInt32(n!.renderer()!.previousOffset(Int32(current))) : current - 1)
  }

  static func uncheckedPreviousOffsetForBackwardDeletion(n: NodeWrapper?, current: UInt32) -> Int32
  {
    return Int32(
      n!.renderer() != nil
        ? UInt32(n!.renderer()!.previousOffsetForBackwardDeletion(Int32(current))) : current - 1)
  }

  static func uncheckedNextOffset(n: NodeWrapper?, current: UInt32) -> Int32 {
    return Int32(
      n!.renderer() != nil ? UInt32(n!.renderer()!.nextOffset(Int32(current))) : current + 1)
  }

  func atFirstEditingPositionForNode() -> Bool {
    if isNull() {
      return true
    }
    // FIXME: Position before anchor shouldn't be considered as at the first editing position for node
    // since that position resides outside of the node.
    switch Int32(m_anchorType) {
    case Int32(AnchorType.PositionIsOffsetInAnchor.rawValue):
      return !(offset != 0)
    case Int32(AnchorType.PositionIsBeforeChildren.rawValue),
      Int32(AnchorType.PositionIsBeforeAnchor.rawValue):
      return true
    case Int32(AnchorType.PositionIsAfterChildren.rawValue),
      Int32(AnchorType.PositionIsAfterAnchor.rawValue):
      return !(lastOffsetForEditing(node: protectedDeprecatedNode()!) != 0)
    default:
      break
    }
    assertionFailure()
    return false
  }

  func atLastEditingPositionForNode() -> Bool {
    if isNull() {
      return true
    }
    // FIXME: Position after anchor shouldn't be considered as at the first editing position for node since that position resides outside of the node.
    return Int32(m_anchorType) == Int32(AnchorType.PositionIsAfterAnchor.rawValue)
      || Int32(m_anchorType) == Int32(AnchorType.PositionIsAfterChildren.rawValue)
      || offset >= UInt32(UInt32(lastOffsetForEditing(node: protectedDeprecatedNode()!)))
    // FIXME: Position after anchor shouldn't be considered as at the first editing position for node since that position resides outside of the node.
  }

  func atEditingBoundary() -> Bool {
    let nextPosition = downstream(.CanCrossEditingBoundary)
    if atFirstEditingPositionForNode() && nextPosition.isNotNull()
      && !(nextPosition.deprecatedNode()!.hasEditableStyle())
    {
      return true
    }
    let prevPosition = upstream(.CanCrossEditingBoundary)
    if atLastEditingPositionForNode() && prevPosition.isNotNull()
      && !(prevPosition.deprecatedNode()!.hasEditableStyle())
    {
      return true
    }
    return nextPosition.isNotNull() && !(nextPosition.deprecatedNode()!.hasEditableStyle())
      && prevPosition.isNotNull() && !(prevPosition.deprecatedNode()!.hasEditableStyle())
  }

  func parentEditingBoundary() -> NodeWrapper? {
    if m_anchorNode == nil {
      return nil
    }
    let documentElement: ElementWrapper? = m_anchorNode!.document().documentElement()
    if documentElement == nil {
      return nil
    }
    var boundary: NodeWrapper? = m_anchorNode
    while CPtrToInt(boundary?.p) != CPtrToInt(documentElement?.p)
      && boundary!.nonShadowBoundaryParentNode() != nil
      && m_anchorNode!.hasEditableStyle() == boundary!.parentNode()!.hasEditableStyle()
    {
      boundary = boundary!.nonShadowBoundaryParentNode()
    }
    return boundary
  }

  func atStartOfTree() -> Bool {
    if isNull() {
      return true
    }
    let container: NodeWrapper? = containerNode()
    if container != nil && container!.parentNode() != nil {
      return false
    }
    switch Int32(m_anchorType) {
    case Int32(AnchorType.PositionIsOffsetInAnchor.rawValue):
      return !(offset != 0)
    case Int32(AnchorType.PositionIsBeforeAnchor.rawValue):
      return m_anchorNode!.previousSibling() == nil
    case Int32(AnchorType.PositionIsAfterAnchor.rawValue):
      return false
    case Int32(AnchorType.PositionIsBeforeChildren.rawValue):
      return true
    case Int32(AnchorType.PositionIsAfterChildren.rawValue):
      return !(lastOffsetForEditing(node: protectedAnchorNode()!) != 0)
    default:
      break
    }
    assertionFailure()
    return false
  }

  func atEndOfTree() -> Bool {
    if isNull() {
      return true
    }
    let container: NodeWrapper? = containerNode()
    if container != nil && container!.parentNode() != nil {
      return false
    }
    switch Int32(m_anchorType) {
    case Int32(AnchorType.PositionIsOffsetInAnchor.rawValue):
      return offset >= UInt32(UInt32(lastOffsetForEditing(node: protectedAnchorNode()!)))
    case Int32(AnchorType.PositionIsBeforeAnchor.rawValue):
      return false
    case Int32(AnchorType.PositionIsAfterAnchor.rawValue):
      return m_anchorNode!.nextSibling() == nil
    case Int32(AnchorType.PositionIsBeforeChildren.rawValue):
      return !(lastOffsetForEditing(node: protectedAnchorNode()!) != 0)
    case Int32(AnchorType.PositionIsAfterChildren.rawValue):
      return true
    default:
      break
    }
    assertionFailure()
    return false
  }

  func previousCharacterPosition(affinity: Affinity) -> Position {
    if isNull() {
      return Position()
    }
    let fromRootEditableElement: ElementWrapper? = deprecatedNode()!.rootEditableElement()
    let atStartOfLine: Bool = isStartOfLine(p: VisiblePosition(self, affinity))
    let rendered: Bool = isCandidate()
    var currentPosition = self
    while !currentPosition.atStartOfTree() {
      currentPosition = currentPosition.previous()
      if CPtrToInt(currentPosition.deprecatedNode()!.rootEditableElement()?.p)
        != CPtrToInt(fromRootEditableElement?.p)
      {
        return self
      }
      if atStartOfLine || !rendered {
        if currentPosition.isCandidate() {
          return currentPosition
        }
      } else if rendersInDifferentPosition(position: currentPosition) {
        return currentPosition
      }
    }
    return self
  }

  func upstream(_ rule: EditingBoundaryCrossingRule = .CannotCrossEditingBoundary) -> Position {
    let startNode: NodeWrapper? = deprecatedNode()
    if startNode == nil {
      return Position()
    }
    // iterate backward from there, looking for a qualified position
    let boundary: NodeWrapper? = enclosingVisualBoundary(node: startNode)
    // FIXME: PositionIterator should respect Before and After positions.
    let anchorNode: NodeWrapper? = m_anchorNode
    var lastVisible = PositionIterator(
      pos: Int32(m_anchorType) == Int32(AnchorType.PositionIsAfterAnchor.rawValue)
        ? makeDeprecatedLegacyPosition(anchorNode, UInt32(caretMaxOffset(node: anchorNode!))) : self
    )
    var currentPosition = lastVisible
    let startEditable: Bool = startNode!.hasEditableStyle()
    var lastNode: NodeWrapper? = startNode
    var boundaryCrossed: Bool = false
    while !currentPosition.atStart() {
      let currentNode = currentPosition.node()!
      // Don't check for an editability change if we haven't moved to a different node,
      // to avoid the expense of computing hasEditableStyle().
      if CPtrToInt(currentNode.p) != CPtrToInt(lastNode?.p) {
        // Don't change editability.
        let currentEditable: Bool = currentNode.hasEditableStyle()
        if startEditable != currentEditable {
          if rule == .CannotCrossEditingBoundary {
            break
          }
          boundaryCrossed = true
        }
        lastNode = currentNode
      }
      // There is no caret position in non-text svg elements.
      if currentNode.isSVGElement() && !(currentNode is SVGTextElementWrapper) {
        currentPosition.decrement()
        continue
      }
      // If we've moved to a position that is visually distinct, return the last saved position. There
      // is code below that terminates early if we're *about* to move to a visually distinct position.
      if endsOfNodeAreVisuallyDistinctPositions(node: currentNode)
        && CPtrToInt(currentNode.p) != CPtrToInt(boundary?.p)
      {
        return lastVisible.toPosition()
      }
      // skip position in unrendered or invisible node
      let renderer: RenderObjectWrapper? = currentNode.renderer()
      if renderer == nil || renderer!.style().visibility() != .Visible {
        currentPosition.decrement()
        continue
      }
      if rule == .CanCrossEditingBoundary && boundaryCrossed {
        lastVisible = currentPosition
        break
      }
      // track last visible streamer position
      if isStreamer(pos: currentPosition) {
        lastVisible = currentPosition
      }
      // Don't move past a position that is visually distinct.  We could rely on code above to terminate and
      // return lastVisible on the next iteration, but we terminate early to avoid doing a computeNodeIndex() call.
      if endsOfNodeAreVisuallyDistinctPositions(node: currentNode)
        && currentPosition.atStartOfNode()
      {
        return lastVisible.toPosition()
      }
      // Return position after tables and nodes which have content that can be ignored.
      if editingIgnoresContent(node: currentNode) || isRenderedTable(node: currentNode) {
        if currentPosition.atEndOfNode() {
          return positionAfterNode(anchorNode: currentNode)
        }
        currentPosition.decrement()
        continue
      }
      // return current position if it is in rendered text
      if let textRenderer = renderer! as? RenderTextWrapper {
        let (firstTextBox, orderCache) = InlineIterator.firstTextBoxInLogicalOrderFor(textRenderer)
        if !firstTextBox.bool() {
          currentPosition.decrement()
          continue
        }
        if CPtrToInt(currentNode.p) != CPtrToInt(startNode?.p) {
          // This assertion fires in layout tests in the case-transform.html test because
          // of a mix-up between offsets in the text in the DOM tree with text in the
          // render tree which can have a different length due to case transformation.
          // Until we resolve that, disable this so we can run the layout tests!
          //ASSERT(currentOffset >= renderer->caretMaxOffset());
          return makeDeprecatedLegacyPosition(currentNode, UInt32(renderer!.caretMaxOffset()))
          // This assertion fires in layout tests in the case-transform.html test because
          // of a mix-up between offsets in the text in the DOM tree with text in the
          // render tree which can have a different length due to case transformation.
          // Until we resolve that, disable this so we can run the layout tests!
          //ASSERT(currentOffset >= renderer->caretMaxOffset());
        }
        let textOffset: UInt32 = UInt32(currentPosition.offsetInLeafNode())
        var box = firstTextBox
        while box.bool() {
          if textOffset > box.get().start() && textOffset <= box.get().end() {
            return currentPosition.toPosition()
          }
          let nextBox = InlineIterator.nextTextBoxInLogicalOrder(box, orderCache)
          if textOffset == box.get().end() + 1 && nextBox.bool()
            && box.get().lineBox() != nextBox.get().lineBox()
          {
            return currentPosition.toPosition()
          }
          box = nextBox
        }
      }
      currentPosition.decrement()
    }
    return lastVisible.toPosition()
  }

  func downstream(_ rule: EditingBoundaryCrossingRule = .CannotCrossEditingBoundary) -> Position {
    let startNode: NodeWrapper? = deprecatedNode()
    if startNode == nil {
      return Position()
    }
    // iterate forward from there, looking for a qualified position
    let boundary: NodeWrapper? = enclosingVisualBoundary(node: startNode)
    // FIXME: PositionIterator should respect Before and After positions.
    let anchorNode: NodeWrapper? = m_anchorNode
    var lastVisible = PositionIterator(
      pos: Int32(m_anchorType) == Int32(AnchorType.PositionIsAfterAnchor.rawValue)
        ? makeDeprecatedLegacyPosition(anchorNode, UInt32(caretMaxOffset(node: anchorNode!))) : self
    )
    var currentPosition = lastVisible
    let startEditable: Bool = startNode!.hasEditableStyle()
    var lastNode: NodeWrapper? = startNode
    var boundaryCrossed: Bool = false
    while !currentPosition.atEnd() {
      let currentNode = currentPosition.node()!
      // Don't check for an editability change if we haven't moved to a different node,
      // to avoid the expense of computing hasEditableStyle().
      if CPtrToInt(currentNode.p) != CPtrToInt(lastNode?.p) {
        // Don't change editability.
        let currentEditable: Bool = currentNode.hasEditableStyle()
        if startEditable != currentEditable {
          if rule == .CannotCrossEditingBoundary {
            break
          }
          boundaryCrossed = true
        }
        lastNode = currentNode
      }
      // stop before going above the body, up into the head
      // return the last visible streamer position
      if currentNode is HTMLBodyElement && currentPosition.atEndOfNode() {
        break
      }
      // There is no caret position in non-text svg elements.
      if currentNode.isSVGElement() && !(currentNode is SVGTextElementWrapper) {
        currentPosition.increment()
        continue
      }
      // Do not move to a visually distinct position.
      if endsOfNodeAreVisuallyDistinctPositions(node: currentNode)
        && CPtrToInt(currentNode.p) != CPtrToInt(boundary?.p)
      {
        return lastVisible.toPosition()
      }
      // Do not move past a visually disinct position.
      // Note: The first position after the last in a node whose ends are visually distinct
      // positions will be [boundary->parentNode(), originalBlock->computeNodeIndex() + 1].
      if boundary != nil && CPtrToInt(boundary!.parentNode()?.p) == CPtrToInt(currentNode.p) {
        return lastVisible.toPosition()
      }
      // skip position in unrendered or invisible node
      let renderer: RenderObjectWrapper? = currentNode.renderer()
      if renderer == nil || renderer!.style().visibility() != .Visible {
        currentPosition.increment()
        continue
      }
      if rule == .CanCrossEditingBoundary && boundaryCrossed {
        lastVisible = currentPosition
        break
      }
      // track last visible streamer position
      if isStreamer(pos: currentPosition) {
        lastVisible = currentPosition
      }
      // Return position before tables and nodes which have content that can be ignored.
      if editingIgnoresContent(node: currentNode) || isRenderedTable(node: currentNode) {
        if currentPosition.atStartOfNode() {
          return positionBeforeNode(anchorNode: currentNode)
        }
        currentPosition.increment()
        continue
      }
      // return current position if it is in rendered text
      if let textRenderer = renderer! as? RenderTextWrapper {
        let (firstTextBox, orderCache) = InlineIterator.firstTextBoxInLogicalOrderFor(textRenderer)
        if !firstTextBox.bool() {
          currentPosition.increment()
          continue
        }
        if CPtrToInt(currentNode.p) != CPtrToInt(startNode?.p) {
          assert(currentPosition.atStartOfNode())
          return makeContainerOffsetPosition(
            node: currentNode, offset: UInt32(textRenderer.caretMinOffset()))
        }
        let textOffset: UInt32 = UInt32(currentPosition.offsetInLeafNode())
        var box = firstTextBox
        while box.bool() {
          if !(box.get().length() != 0) && textOffset == box.get().start() {
            return currentPosition.toPosition()
          }
          if textOffset >= box.get().start() && textOffset < box.get().end() {
            return currentPosition.toPosition()
          }
          let nextBox = InlineIterator.nextTextBoxInLogicalOrder(box, orderCache)
          if textOffset == box.get().end() && nextBox.bool()
            && box.get().lineBox() != nextBox.get().lineBox()
          {
            return currentPosition.toPosition()
          }
          box = nextBox
        }
      }
      currentPosition.increment()
    }
    return lastVisible.toPosition()
  }

  static func positionCountBetweenPositions(a: Position, b: Position) -> UInt32 {
    if a.isNull() || b.isNull() {
      return (2_147_483_647 * 2 + 1)
    }
    var endPos = Position()
    var pos = Position()
    if a > b {
      endPos = a
      pos = b
    } else if a < b {
      endPos = b
      pos = a
    } else {
      return 0
    }
    var posCount: UInt32 = 0
    while !pos.atEndOfTree() && pos != endPos {
      pos = pos.next()
      posCount += 1
    }
    return posCount
  }

  static func hasRenderedNonAnonymousDescendantsWithHeight(renderer: RenderElementWrapper) -> Bool {
    let stop: RenderObjectWrapper? = renderer.nextInPreOrderAfterChildren()
    var o: RenderObjectWrapper? = renderer.firstChild()
    while o != nil && CPtrToInt(o?.id()) != CPtrToInt(stop?.id()) {
      if o!.nonPseudoNode() == nil {
        o = o!.nextInPreOrder()
        continue
      }
      if let renderText = o! as? RenderTextWrapper {
        if boundingBoxLogicalHeight(o: o, rect: renderText.linesBoundingBox()) != 0 {
          return true
        }
        o = o!.nextInPreOrder()
        continue
      }
      if let renderLineBreak = o! as? RenderLineBreakWrapper {
        if boundingBoxLogicalHeight(o: o, rect: renderLineBreak.linesBoundingBox()) != 0 {
          return true
        }
        o = o!.nextInPreOrder()
        continue
      }
      if let renderBox = o! as? RenderBoxWrapper {
        if roundToInt(value: renderBox.logicalHeight()) != 0 {
          return true
        }
        o = o!.nextInPreOrder()
        continue
      }
      if let renderInline = o! as? RenderInlineWrapper {
        if isEmptyInline(renderInline)
          && boundingBoxLogicalHeight(o: o, rect: renderInline.linesBoundingBox()) != 0
        {
          return true
        }
        o = o!.nextInPreOrder()
        continue
      }
      o = o!.nextInPreOrder()
    }
    return false
  }

  static func nodeIsUserSelectNone(node: NodeWrapper?) -> Bool {
    if node == nil {
      return false
    }
    return node!.renderer() != nil && (node!.renderer()!.style().usedUserSelect() == .None)
  }

  static func nodeIsUserSelectAll(node: NodeWrapper?) -> Bool {
    if node == nil {
      return false
    }
    let renderer: RenderObjectWrapper? = node!.renderer()
    return renderer != nil && renderer!.style().usedUserSelect() == .All
  }

  static func rootUserSelectAllForNode(node: NodeWrapper?) -> NodeWrapper? {
    if node == nil || !Position.nodeIsUserSelectAll(node: node) {
      return nil
    }
    var parent: ContainerNodeWrapper? = node!.parentNode()
    if parent == nil {
      return node
    }
    var candidateRoot: NodeWrapper? = node
    while parent != nil {
      if parent!.renderer() == nil {
        parent = parent!.parentNode()
        continue
      }
      if !Position.nodeIsUserSelectAll(node: parent) {
        break
      }
      candidateRoot = parent
      parent = candidateRoot!.parentNode()
    }
    return candidateRoot
  }

  func isCandidate() -> Bool {
    if isNull() {
      return false
    }
    let node: NodeWrapper? = deprecatedNode()
    let renderer: RenderObjectWrapper? = node!.renderer()
    if renderer == nil {
      return false
    }
    if renderer!.style().visibility() != .Visible {
      return false
    }
    if renderer!.isBRForRenderObject() {
      // FIXME: The condition should be m_anchorType == PositionIsBeforeAnchor, but for now we still need to support legacy positions.
      return !(offset != 0)
        && Int32(m_anchorType) != Int32(AnchorType.PositionIsAfterAnchor.rawValue)
        && !(Position.nodeIsUserSelectNone(node: node!.parentNode()))
      // FIXME: The condition should be m_anchorType == PositionIsBeforeAnchor, but for now we still need to support legacy positions.
    }
    if let renderText = renderer! as? RenderTextWrapper {
      return !Position.nodeIsUserSelectNone(node: node) && renderText.containsCaretOffset(offset)
    }
    if positionBeforeOrAfterNodeIsCandidate(node: node!) {
      return
        ((atFirstEditingPositionForNode()
        && Int32(m_anchorType) == Int32(AnchorType.PositionIsBeforeAnchor.rawValue))
        || (atLastEditingPositionForNode()
          && Int32(m_anchorType) == Int32(AnchorType.PositionIsAfterAnchor.rawValue)))
        && !(Position.nodeIsUserSelectNone(node: node!.parentNode()))
    }
    if m_anchorNode! is HTMLHtmlElement {
      return false
    }
    if let block = renderer! as? RenderBlockWrapper {
      if block is RenderBlockFlowWrapper || block is RenderGridWrapper
        || block is RenderFlexibleBoxWrapper
      {
        if block.logicalHeight().bool() || m_anchorNode! is HTMLBodyElement
          || m_anchorNode!.isRootEditableElement()
        {
          if !Position.hasRenderedNonAnonymousDescendantsWithHeight(renderer: block) {
            return atFirstEditingPositionForNode() && !Position.nodeIsUserSelectNone(node: node)
          }
          return m_anchorNode!.hasEditableStyle() && !Position.nodeIsUserSelectNone(node: node)
            && atEditingBoundary()
        }
        return false
      }
    }
    return m_anchorNode!.hasEditableStyle() && !Position.nodeIsUserSelectNone(node: node)
      && atEditingBoundary()
  }

  func isRenderedCharacter() -> Bool {
    let text: TextWrapper? = deprecatedNode() as? TextWrapper
    let renderer: RenderTextWrapper? = text != nil ? text!.renderer() : nil
    return renderer != nil && renderer!.containsRenderedCharacterOffset(offset)
  }

  func rendersInDifferentPosition(position: Position) -> Bool {
    if isNull() || position.isNull() {
      return false
    }
    let node: NodeWrapper? = deprecatedNode()
    let renderer: RenderObjectWrapper? = node!.renderer()
    if renderer == nil {
      return false
    }
    let positionNode: NodeWrapper? = position.deprecatedNode()
    let positionRenderer: RenderObjectWrapper? = positionNode!.renderer()
    if positionRenderer == nil {
      return false
    }
    if renderer!.style().visibility() != .Visible
      || positionRenderer!.style().visibility() != .Visible
    {
      return false
    }
    if CPtrToInt(node?.p) == CPtrToInt(positionNode?.p) {
      if node! is HTMLBRElementWrapper {
        return false
      }
      if offset == UInt32(UInt32(position.deprecatedEditingOffset())) {
        return false
      }
      if !(node! is TextWrapper) {
        return true
      }
    }
    if node! is HTMLBRElementWrapper && position.isCandidate() {
      return true
    }
    if positionNode! is HTMLBRElementWrapper && isCandidate() {
      return true
    }
    if !inSameEnclosingBlockFlowElement(a: node, b: positionNode) {
      return true
    }
    let textRenderer: RenderTextWrapper? = renderer! as? RenderTextWrapper
    if textRenderer != nil && !textRenderer!.containsCaretOffset(offset) {
      return false
    }
    let textPositionRenderer: RenderTextWrapper? = positionRenderer! as? RenderTextWrapper
    if textPositionRenderer != nil && !textPositionRenderer!.containsCaretOffset(position.offset) {
      return false
    }
    let thisRenderedOffset: UInt32 =
      textRenderer != nil ? textRenderer!.countRenderedCharacterOffsetsUntil(offset) : offset
    let positionRenderedOffset: UInt32 =
      textPositionRenderer != nil
      ? textPositionRenderer!.countRenderedCharacterOffsetsUntil(position.offset) : position.offset
    if CPtrToInt(renderer?.id()) == CPtrToInt(positionRenderer?.id())
      && thisRenderedOffset == positionRenderedOffset
    {
      return false
    }
    let box1 = inlineBoxAndOffset(affinity: .Downstream).box
    let box2 = position.inlineBoxAndOffset(affinity: .Downstream).box
    if !box1.bool() || !box2.bool() {
      return false
    }
    if box1.get().lineBox() != box2.get().lineBox() {
      return true
    }
    if CPtrToInt(nextRenderedEditable(node: node)?.p) == CPtrToInt(positionNode?.p)
      && thisRenderedOffset == UInt32(UInt32(caretMaxOffset(node: positionNode!)))
      && !(positionRenderedOffset != 0)
    {
      return false
    }
    if CPtrToInt(previousRenderedEditable(node: node)?.p) == CPtrToInt(positionNode?.p)
      && !(thisRenderedOffset != 0)
      && positionRenderedOffset == UInt32(UInt32(caretMaxOffset(node: positionNode!)))
    {
      return false
    }
    return true
  }

  func leadingWhitespacePosition(affinity: Affinity, considerNonCollapsibleWhitespace: Bool = false)
    -> Position
  {
    assert(isEditablePosition(position: self))
    if isNull() {
      return Position()
    }
    if upstream().deprecatedNode()! is HTMLBRElementWrapper {
      return Position()
    }
    let prev = previousCharacterPosition(affinity: affinity)
    let node: NodeWrapper? = deprecatedNode()
    let previousNode: NodeWrapper? = prev.deprecatedNode()
    if prev != self && inSameEnclosingBlockFlowElement(a: node, b: previousNode) {
      if let previousText = previousNode! as? TextWrapper {
        let c: UInt16 = previousText.data()[UInt32(prev.deprecatedEditingOffset())]
        if considerNonCollapsibleWhitespace
          ? (isASCIIWhitespace(character: c) || Int32(c) == Int32(noBreakSpace))
          : deprecatedIsCollapsibleWhitespace(c: c)
        {
          if isEditablePosition(position: prev) {
            return prev
          }
        }
      }
    }
    return Position()
  }

  func trailingWhitespacePosition(_ arg0: Affinity, considerNonCollapsibleWhitespace: Bool = false)
    -> Position
  {
    assert(isEditablePosition(position: self))
    if isNull() {
      return Position()
    }
    let v = VisiblePosition(self)
    let c: UInt16 = UInt16(v.characterAfter())
    // The space must not be in another paragraph and it must be editable.
    if !isEndOfParagraph(pos: v) && v.next(rule: .CannotCrossEditingBoundary).isNotNull() {
      if considerNonCollapsibleWhitespace
        ? (isASCIIWhitespace(character: c) || Int32(c) == Int32(noBreakSpace))
        : deprecatedIsCollapsibleWhitespace(c: c)
      {
        return self
      }
    }
    return Position()
  }

  func inlineBoxAndOffset(affinity: Affinity) -> InlineBoxAndOffset {
    return inlineBoxAndOffset(affinity: affinity, primaryDirection: primaryDirection())
  }

  func inlineBoxAndOffset(affinity: Affinity, primaryDirection: TextDirection) -> InlineBoxAndOffset
  {
    var caretOffset: UInt32 = UInt32(UInt32(deprecatedEditingOffset()))
    let node: NodeWrapper? = protectedDeprecatedNode()
    if node == nil {
      return InlineBoxAndOffset(box: InlineIterator.LeafBoxIterator(), offset: caretOffset)
    }
    let renderer: RenderObjectWrapper? = node!.renderer()
    if renderer == nil {
      return InlineBoxAndOffset(box: InlineIterator.LeafBoxIterator(), offset: caretOffset)
    }
    var box = InlineIterator.LeafBoxIterator()
    if let lineBreakRenderer = renderer! as? RenderLineBreakWrapper, lineBreakRenderer.isBR() {
      if !(caretOffset != 0) {
        box = InlineIterator.boxFor(lineBreakRenderer)
      }
    } else if let textRenderer = renderer! as? RenderTextWrapper {
      var textBox = InlineIterator.firstTextBoxFor(textRenderer)
      var candidate = InlineIterator.TextBoxIterator()
      while textBox.bool() {
        let caretMinOffset: UInt32 = textBox.get().minimumCaretOffset()
        let caretMaxOffset: UInt32 = textBox.get().maximumCaretOffset()
        if caretOffset < caretMinOffset || caretOffset > caretMaxOffset
          || (caretOffset == caretMaxOffset && textBox.get().isLineBreak())
        {
          textBox.traverseNextTextBox()
          continue
        }
        if caretOffset > caretMinOffset && caretOffset < caretMaxOffset {
          return InlineBoxAndOffset(box: textBox, offset: caretOffset)
        }
        if (caretOffset == caretMaxOffset) != (affinity == .Downstream) {
          break
        }
        if (caretOffset == caretMinOffset) != (affinity == .Upstream) {
          break
        }
        if caretOffset == caretMaxOffset {
          let nextOnLine = textBox.get().nextOnLine()
          if nextOnLine.bool() && nextOnLine.get().isLineBreak() {
            break
          }
        }
        candidate = textBox
        textBox.traverseNextTextBox()
      }
      if candidate.bool() && !candidate.get().nextTextBox().bool() && affinity == .Downstream {
        textBox = searchAheadForBetterMatch(renderer: textRenderer)
        if textBox.bool() {
          caretOffset = textBox.get().minimumCaretOffset()
        }
      }
      box = textBox.bool() ? textBox : candidate
    } else {
      let node: NodeWrapper? = deprecatedNode()
      if canHaveChildrenForEditing(node: node!) {
        let renderBlockFlow: RenderBlockFlowWrapper? = renderer! as? RenderBlockFlowWrapper
        if renderBlockFlow != nil
          && Position.hasRenderedNonAnonymousDescendantsWithHeight(renderer: renderBlockFlow!)
        {
          // Try a visually equivalent position with possibly opposite editability. This helps in case |this| is in
          // an editable block but surrounded by non-editable positions. It acts to negate the logic at the beginning
          // of RenderObject::createVisiblePosition().
          var equivalent = downstreamIgnoringEditingBoundaries(position: self)
          if equivalent == self {
            equivalent = upstreamIgnoringEditingBoundaries(position: self)
            // FIXME: Can returning nullptr really be correct here?
            if equivalent == self
              || downstreamIgnoringEditingBoundaries(position: equivalent) == self
            {
              return InlineBoxAndOffset(box: InlineIterator.LeafBoxIterator(), offset: caretOffset)
            }
          }
          return equivalent.inlineBoxAndOffset(
            affinity: .Upstream, primaryDirection: primaryDirection)
        }
      }
      if let renderBox = renderer! as? RenderBoxWrapper {
        box = InlineIterator.boxFor(renderBox)
        if box.bool() && caretOffset > box.get().minimumCaretOffset()
          && caretOffset < box.get().maximumCaretOffset()
        {
          return InlineBoxAndOffset(box: box, offset: caretOffset)
        }
      }
    }
    if !box.bool() {
      return InlineBoxAndOffset(box: InlineIterator.LeafBoxIterator(), offset: caretOffset)
    }
    var level: UInt8 = box.get().bidiLevel()
    if box.get().direction() == primaryDirection {
      if caretOffset == box.get().rightmostCaretOffset() {
        let nextBox = box.get().nextOnLine()
        if !nextBox.bool() || Int32(nextBox.get().bidiLevel()) >= Int32(level) {
          return InlineBoxAndOffset(box: box, offset: caretOffset)
        }
        level = nextBox.get().bidiLevel()
        let previousRun = box.get().previousOnLine()
        while previousRun.bool() {
          if Int32(previousRun.get().bidiLevel()) <= Int32(level) {
            break
          }
          previousRun.traversePreviousOnLine()
        }
        if previousRun.bool() && Int32(previousRun.get().bidiLevel()) == Int32(level) {
          return InlineBoxAndOffset(box: box, offset: caretOffset)
        }
        // For example, abc 123 ^ CBA
        while nextBox.bool() {
          if Int32(nextBox.get().bidiLevel()) < Int32(level) {
            break
          }
          box = nextBox
          nextBox.traverseNextOnLine()
        }
        caretOffset = box.get().rightmostCaretOffset()
      } else {
        let previousRun = box.get().previousOnLine()
        if !previousRun.bool() || Int32(previousRun.get().bidiLevel()) >= Int32(level) {
          return InlineBoxAndOffset(box: box, offset: caretOffset)
        }
        level = previousRun.get().bidiLevel()
        let nextBox = box.get().nextOnLine()
        while nextBox.bool() {
          if Int32(nextBox.get().bidiLevel()) <= Int32(level) {
            break
          }
          nextBox.traverseNextOnLine()
        }
        if nextBox.bool() && Int32(nextBox.get().bidiLevel()) == Int32(level) {
          return InlineBoxAndOffset(box: box, offset: caretOffset)
        }
        while previousRun.bool() {
          if Int32(previousRun.get().bidiLevel()) < Int32(level) {
            break
          }
          box = previousRun
          previousRun.traversePreviousOnLine()
        }
        caretOffset = box.get().leftmostCaretOffset()
      }
      return InlineBoxAndOffset(box: box, offset: caretOffset)
    }
    if caretOffset == box.get().leftmostCaretOffset() {
      let previousRun = box.get().previousOnLineIgnoringLineBreak()
      if !previousRun.bool() || Int32(previousRun.get().bidiLevel()) < Int32(level) {
        // Left edge of a secondary box. Set to the right edge of the entire box.
        do {
          let nextBox = box.get().nextOnLineIgnoringLineBreak()
          while nextBox.bool() {
            if Int32(nextBox.get().bidiLevel()) < Int32(level) {
              break
            }
            box = nextBox
            nextBox.traverseNextOnLineIgnoringLineBreak()
          }
        }
        caretOffset = box.get().rightmostCaretOffset()
      } else if Int32(previousRun.get().bidiLevel()) > Int32(level) {
        // Right edge of a "tertiary" box. Set to the left edge of that box.
        let tertiaryRun = box.get().previousOnLineIgnoringLineBreak()
        while tertiaryRun.bool() {
          if Int32(tertiaryRun.get().bidiLevel()) <= Int32(level) {
            break
          }
          box = tertiaryRun
          tertiaryRun.traversePreviousOnLineIgnoringLineBreak()
        }
        caretOffset = box.get().leftmostCaretOffset()
      }
    } else {
      let nextBox = box.get().nextOnLineIgnoringLineBreak()
      if !nextBox.bool() || Int32(nextBox.get().bidiLevel()) < Int32(level) {
        // Right edge of a secondary box. Set to the left edge of the entire box.
        do {
          let previousRun = box.get().previousOnLineIgnoringLineBreak()
          while previousRun.bool() {
            if Int32(previousRun.get().bidiLevel()) < Int32(level) {
              break
            }
            box = previousRun
            previousRun.traversePreviousOnLineIgnoringLineBreak()
          }
        }
        caretOffset = box.get().leftmostCaretOffset()
      } else if Int32(nextBox.get().bidiLevel()) > Int32(level) {
        // Left edge of a "tertiary" box. Set to the right edge of that box.
        do {
          let tertiaryRun = box.get().nextOnLineIgnoringLineBreak()
          while tertiaryRun.bool() {
            if Int32(tertiaryRun.get().bidiLevel()) <= Int32(level) {
              break
            }
            box = tertiaryRun
            tertiaryRun.traverseNextOnLineIgnoringLineBreak()
          }
        }
        caretOffset = box.get().rightmostCaretOffset()
      }
    }
    return InlineBoxAndOffset(box: box, offset: caretOffset)
  }

  func primaryDirection() -> TextDirection {
    if m_anchorNode == nil || m_anchorNode!.renderer() == nil {
      return .LTR
    }
    if let blockFlow = RenderAncestorIteratorAdapter<RenderBlockFlowWrapper>.lineageOfType(
      first: m_anchorNode!.renderer()!
    ).first() {
      return blockFlow.style().direction()
    }
    return .LTR
  }

  func equals(other: Position) -> Bool {
    if m_anchorNode == nil {
      return (m_anchorNode == nil) == (other.m_anchorNode == nil)
    }
    if other.m_anchorNode == nil {
      return false
    }
    switch anchorType() {
    case .PositionIsBeforeChildren:
      assert(!(m_anchorNode! is TextWrapper))
      switch other.anchorType() {
      case .PositionIsBeforeChildren:
        assert(!(other.m_anchorNode! is TextWrapper))
        return CPtrToInt(m_anchorNode?.p) == CPtrToInt(other.m_anchorNode?.p)
      case .PositionIsAfterChildren:
        assert(!(other.m_anchorNode! is TextWrapper))
        return CPtrToInt(m_anchorNode?.p) == CPtrToInt(other.m_anchorNode?.p)
          && !m_anchorNode!.hasChildNodes()
      case .PositionIsOffsetInAnchor:
        return CPtrToInt(m_anchorNode?.p) == CPtrToInt(other.m_anchorNode?.p)
          && !(other.offset != 0)
      case .PositionIsBeforeAnchor:
        return CPtrToInt(m_anchorNode!.firstChild()?.p) == CPtrToInt(other.m_anchorNode?.p)
      case .PositionIsAfterAnchor:
        return false
      }
    case .PositionIsAfterChildren:
      assert(!(m_anchorNode! is TextWrapper))
      switch other.anchorType() {
      case .PositionIsBeforeChildren:
        assert(!(other.m_anchorNode! is TextWrapper))
        return CPtrToInt(m_anchorNode?.p) == CPtrToInt(other.m_anchorNode?.p)
          && !m_anchorNode!.hasChildNodes()
      case .PositionIsAfterChildren:
        assert(!(other.m_anchorNode! is TextWrapper))
        return CPtrToInt(m_anchorNode?.p) == CPtrToInt(other.m_anchorNode?.p)
      case .PositionIsOffsetInAnchor:
        return CPtrToInt(m_anchorNode?.p) == CPtrToInt(other.m_anchorNode?.p)
          && m_anchorNode!.countChildNodes() == UInt32(offset)
      case .PositionIsBeforeAnchor:
        return false
      case .PositionIsAfterAnchor:
        return CPtrToInt(m_anchorNode!.lastChild()?.p) == CPtrToInt(other.m_anchorNode?.p)
      }
    case .PositionIsOffsetInAnchor:
      switch other.anchorType() {
      case .PositionIsBeforeChildren:
        assert(!(other.m_anchorNode! is TextWrapper))
        return CPtrToInt(m_anchorNode?.p) == CPtrToInt(other.m_anchorNode?.p) && !(offset != 0)
      case .PositionIsAfterChildren:
        assert(!(other.m_anchorNode! is TextWrapper))
        return CPtrToInt(m_anchorNode?.p) == CPtrToInt(other.m_anchorNode?.p)
          && offset == other.m_anchorNode!.countChildNodes()
      case .PositionIsOffsetInAnchor:
        return CPtrToInt(m_anchorNode?.p) == CPtrToInt(other.m_anchorNode?.p)
          && offset == other.offset
      case .PositionIsBeforeAnchor:
        return CPtrToInt(m_anchorNode!.traverseToChildAt(offset)?.p)
          == CPtrToInt(other.m_anchorNode?.p)
      case .PositionIsAfterAnchor:
        return offset != 0
          && CPtrToInt(m_anchorNode!.traverseToChildAt(offset - 1)?.p)
            == CPtrToInt(other.m_anchorNode?.p)
      }
    case .PositionIsBeforeAnchor:
      switch other.anchorType() {
      case .PositionIsBeforeChildren:
        assert(!(other.m_anchorNode! is TextWrapper))
        return CPtrToInt(m_anchorNode?.p) == CPtrToInt(other.m_anchorNode!.firstChild()?.p)
      case .PositionIsAfterChildren:
        assert(!(other.m_anchorNode! is TextWrapper))
        return false
      case .PositionIsOffsetInAnchor:
        return CPtrToInt(m_anchorNode?.p)
          == CPtrToInt(other.m_anchorNode!.traverseToChildAt(other.offset)?.p)
      case .PositionIsBeforeAnchor:
        return CPtrToInt(m_anchorNode?.p) == CPtrToInt(other.m_anchorNode?.p)
      case .PositionIsAfterAnchor:
        return CPtrToInt(m_anchorNode!.previousSibling()?.p) == CPtrToInt(other.m_anchorNode?.p)
      }
    case .PositionIsAfterAnchor:
      switch other.anchorType() {
      case .PositionIsBeforeChildren:
        assert(!(other.m_anchorNode! is TextWrapper))
        return false
      case .PositionIsAfterChildren:
        assert(!(other.m_anchorNode! is TextWrapper))
        return CPtrToInt(m_anchorNode?.p) == CPtrToInt(other.m_anchorNode!.lastChild()?.p)
      case .PositionIsOffsetInAnchor:
        return other.offset != 0
          && CPtrToInt(m_anchorNode?.p)
            == CPtrToInt(other.m_anchorNode!.traverseToChildAt(other.offset - 1)?.p)
      case .PositionIsBeforeAnchor:
        return CPtrToInt(m_anchorNode!.nextSibling()?.p) == CPtrToInt(other.m_anchorNode?.p)
      case .PositionIsAfterAnchor:
        return CPtrToInt(m_anchorNode?.p) == CPtrToInt(other.m_anchorNode?.p)
      }
    }
  }

  static func == (a: Position, b: Position) -> Bool {
    return CPtrToInt(a.anchorNode()?.p) == CPtrToInt(b.anchorNode()?.p)
      && a.deprecatedEditingOffset() == b.deprecatedEditingOffset()
      && a.anchorType() == b.anchorType()
  }

  static func < (a: Position, b: Position) -> Bool {
    return is_lt(documentOrder(a: a, b: b))
  }

  static func > (a: Position, b: Position) -> Bool {
    return is_gt(documentOrder(a: a, b: b))
  }

  static func <= (a: Position, b: Position) -> Bool {
    return is_lteq(documentOrder(a: a, b: b))
  }

  static func >= (a: Position, b: Position) -> Bool {
    return is_gteq(documentOrder(a: a, b: b))
  }

  private var m_anchorNode: NodeWrapper? = nil
  private var offset: UInt32 = 0
  private var m_anchorType: UInt32 = 0
  private var isLegacyEditingPosition: Bool = false
}

// Positions cross to C++ by value; see editing/EditingScion.h. The stored properties are private,
// as in C++, where positionToRaw() is a friend.
extension Position {
  init(raw: PositionRaw) {
    self.m_anchorNode = raw.anchorNode.map { createNodeWrapper($0) }
    self.offset = raw.offset
    self.m_anchorType = UInt32(raw.anchorType)
    self.isLegacyEditingPosition = raw.isLegacyEditingPosition
  }

  func raw() -> PositionRaw {
    return PositionRaw(
      anchorNode: m_anchorNode?.p, offset: offset, anchorType: UInt8(m_anchorType),
      isLegacyEditingPosition: isLegacyEditingPosition)
  }
}

extension Position: Equatable {}

func hasInlineRun(renderer: RenderObjectWrapper) -> Bool {
  if let renderBox = renderer as? RenderBoxWrapper, InlineIterator.boxFor(renderBox).bool() {
    return true
  }
  if let renderText = renderer as? RenderTextWrapper,
    InlineIterator.firstTextBoxFor(renderText).bool()
  {
    return true
  }
  if let renderLineBreak = renderer as? RenderLineBreakWrapper,
    InlineIterator.boxFor(renderLineBreak).bool()
  {
    return true
  }
  return false
}

func nextRenderedEditable(node: NodeWrapper?) -> NodeWrapper? {
  var node = node
  while true {
    node = nextLeafNode(node: node)
    if node == nil {
      break
    }
    let renderer: RenderObjectWrapper? = node!.renderer()
    if renderer == nil || !node!.hasEditableStyle() {
      continue
    }
    if hasInlineRun(renderer: renderer!) {
      return node
    }
  }
  return nil
}

func previousRenderedEditable(node: NodeWrapper?) -> NodeWrapper? {
  var node = node
  while true {
    node = previousLeafNode(node: node)
    if node == nil {
      break
    }
    let renderer: RenderObjectWrapper? = node!.renderer()
    if renderer == nil || !node!.hasEditableStyle() {
      continue
    }
    if hasInlineRun(renderer: renderer!) {
      return node
    }
  }
  return nil
}

func makeContainerOffsetPosition(node: NodeWrapper?, offset: UInt32) -> Position {
  return Position(anchorNode: node, offset: offset, anchorType: .PositionIsOffsetInAnchor)
}

func makeDeprecatedLegacyPosition(_ node: NodeWrapper?, _ offset: UInt32) -> Position {
  return Position(anchorNode: node, offset: offset, .On)
}

func positionBeforeNode(anchorNode: NodeWrapper?) -> Position {
  assert(anchorNode != nil)
  return Position(anchorNode: anchorNode, anchorType: .PositionIsBeforeAnchor)
}

func positionAfterNode(anchorNode: NodeWrapper?) -> Position {
  assert(anchorNode != nil)
  return Position(anchorNode: anchorNode, anchorType: .PositionIsAfterAnchor)
}

func firstPositionInNode(anchorNode: NodeWrapper?) -> Position {
  if anchorNode!.isCharacterDataNode() {
    return Position(anchorNode: anchorNode, offset: 0, anchorType: .PositionIsOffsetInAnchor)
  }
  return Position(anchorNode: anchorNode, anchorType: .PositionIsBeforeChildren)
}

func lastPositionInNode(anchorNode: NodeWrapper?) -> Position {
  if anchorNode!.isCharacterDataNode() {
    return Position(
      anchorNode: anchorNode, offset: anchorNode!.length(), anchorType: .PositionIsOffsetInAnchor)
  }
  return Position(anchorNode: anchorNode, anchorType: .PositionIsAfterChildren)
}

func offsetIsBeforeLastNodeOffset(offset: UInt32, anchorNode: NodeWrapper?) -> Bool {
  if let characterData = anchorNode! as? CharacterDataWrapper {
    return offset < characterData.length()
  }
  var currentOffset: UInt32 = 0
  var node: NodeWrapper? = anchorNode!.firstChild()
  while node != nil && currentOffset < offset {
    currentOffset += 1
    node = node!.nextSibling()
  }
  return offset < currentOffset
}

func endsOfNodeAreVisuallyDistinctPositions(node: NodeWrapper?) -> Bool {
  if node == nil || node!.renderer() == nil {
    return false
  }
  if !(node!.renderer()!.isInline()) {
    return true
  }
  // Don't include inline tables.
  if node! is HTMLTableElementWrapper {
    return false
  }
  if !(node!.renderer()!.isReplacedOrInlineBlock()) || !canHaveChildrenForEditing(node: node!)
    || !((node!.renderer()! as! RenderBoxWrapper).height()).bool()
  {
    return false
  }
  // There is a VisiblePosition inside an empty inline-block container.
  if !node!.hasChildNodes() {
    return true
  }
  return
    !(Position.hasRenderedNonAnonymousDescendantsWithHeight(
      renderer: node!.renderer()! as! RenderElementWrapper))
}

func enclosingVisualBoundary(node: NodeWrapper?) -> NodeWrapper? {
  var node = node
  while node != nil && !endsOfNodeAreVisuallyDistinctPositions(node: node) {
    node = node!.parentNode()
  }
  return node
}

func isStreamer(pos: PositionIterator) -> Bool {
  let node: NodeWrapper? = pos.node()
  if node == nil {
    return true
  }
  if isAtomicNode(node: node) {
    return true
  }
  return pos.atStartOfNode()
}

func boundingBoxLogicalHeight(o: RenderObjectWrapper?, rect: IntRect) -> Int32 {
  return o!.style().isHorizontalWritingMode() ? rect.height() : rect.width()
}

func inSameEnclosingBlockFlowElement(a: NodeWrapper?, b: NodeWrapper?) -> Bool {
  return a != nil && b != nil
    && CPtrToInt(deprecatedEnclosingBlockFlowElement(node: a)?.p)
      == CPtrToInt(deprecatedEnclosingBlockFlowElement(node: b)?.p)
}

func isNonTextLeafChild(object: RenderObjectWrapper) -> Bool {
  if let renderElement = object as? RenderElementWrapper {
    return renderElement.firstChild() == nil
  }
  return false
}

func searchAheadForBetterMatch(renderer: RenderTextWrapper) -> InlineIterator.TextBoxIterator {
  let container: RenderBlockWrapper? = renderer.containingBlock()
  var next: RenderObjectWrapper? = renderer
  while true {
    next = next!.nextInPreOrder(stayWithin: container)
    if next == nil {
      break
    }
    if next is RenderBlockWrapper {
      return InlineIterator.TextBoxIterator()
    }
    if next!.isBRForRenderObject() {
      return InlineIterator.TextBoxIterator()
    }
    if isNonTextLeafChild(object: next!) {
      return InlineIterator.TextBoxIterator()
    }
    if let renderText = next! as? RenderTextWrapper {
      let box = InlineIterator.firstTextBoxInLogicalOrderFor(renderText).0
      if box.bool() {
        return box
      }
    }
  }
  return InlineIterator.TextBoxIterator()
}

func downstreamIgnoringEditingBoundaries(position: Position) -> Position {
  var position = position
  var lastPosition = Position()
  while position != lastPosition {
    lastPosition = position
    position = position.downstream(.CanCrossEditingBoundary)
  }
  return position
}

func upstreamIgnoringEditingBoundaries(position: Position) -> Position {
  var position = position
  var lastPosition = Position()
  while position != lastPosition {
    lastPosition = position
    position = position.upstream(.CanCrossEditingBoundary)
  }
  return position
}

func commonInclusiveAncestor(a: Position, b: Position) -> NodeWrapper? {
  fatalError("Not implemented")
}

func positionInParentBeforeNode(node: NodeWrapper?) -> Position {
  var currentNode: NodeWrapper? = node
  var ancestor: ContainerNodeWrapper? = node!.parentNode()
  while ancestor != nil && editingIgnoresContent(node: ancestor!) {
    currentNode = ancestor
    ancestor = ancestor!.parentNode()
  }
  assert(ancestor != nil)
  return Position(
    anchorNode: ancestor, offset: currentNode!.computeNodeIndex(),
    anchorType: .PositionIsOffsetInAnchor)
}

func positionInParentAfterNode(node: NodeWrapper?) -> Position {
  var currentNode: NodeWrapper? = node
  var ancestor: ContainerNodeWrapper? = node!.parentNode()
  while ancestor != nil && editingIgnoresContent(node: ancestor!) {
    currentNode = ancestor
    ancestor = ancestor!.parentNode()
  }
  assert(ancestor != nil)
  return Position(
    anchorNode: ancestor, offset: currentNode!.computeNodeIndex() + 1,
    anchorType: .PositionIsOffsetInAnchor)
}

func makeContainerOffsetPosition(point: BoundaryPoint) -> Position {
  return makeContainerOffsetPosition(node: point.container, offset: point.offset)
}

func makeDeprecatedLegacyPosition(point: BoundaryPoint) -> Position {
  return makeDeprecatedLegacyPosition(point.container, point.offset)
}

func makeBoundaryPoint(position: Position) -> BoundaryPoint? {
  let container: NodeWrapper? = position.containerNode()
  if container == nil {
    return nil
  }
  return BoundaryPoint(
    container: container!, offset: UInt32(UInt32(position.computeOffsetInContainerNode())))
}

func documentOrder(a: Position, b: Position) -> PartialOrdering {
  fatalError("Not implemented")
}
