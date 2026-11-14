/*
 * Copyright (C) 2004-2022 Apple Inc. All rights reserved.
 * Copyright (C) 2015 Google Inc. All rights reserved.
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

func canHaveChildrenForEditing(node: NodeWrapper) -> Bool {
  return !(node is TextWrapper) && !(node is HTMLPictureElementWrapper)
    && node.canContainRangeEndPoint()
}

func isAtomicNode(node: NodeWrapper?) -> Bool {
  return node != nil && (!node!.hasChildNodes() || editingIgnoresContent(node: node!))
}

func highestEditableRoot(position: Position, editableType: EditableType = .ContentIsEditable)
  -> ContainerNodeWrapper?
{
  var highestEditableRoot: ContainerNodeWrapper? = editableRootForPosition(
    position: position, editableType: editableType)
  if highestEditableRoot == nil {
    return nil
  }
  var node: ContainerNodeWrapper? = highestEditableRoot
  while !(node! is HTMLBodyElement) {
    node = node!.parentNode()
    if node == nil {
      break
    }
    // FIXME: Can this ever be a Document or DocumentFragment? If not, this should return Element* instead.
    if hasEditableStyle(node: node!, editableType: editableType) {
      highestEditableRoot = node
    }
  }
  return highestEditableRoot
}

func lowestEditableAncestor(node: NodeWrapper?) -> ElementWrapper? {
  var node = node
  while node != nil {
    if node!.hasEditableStyle() {
      return node!.rootEditableElement()
    }
    if node! is HTMLBodyElement {
      break
    }
    node = node!.parentNode()
  }
  return nil
}

func isEditableToAccessibility(node: NodeWrapper) -> Bool {
  fatalError("Not implemented")
}

func computeEditability(
  node: NodeWrapper, editableType: EditableType, shouldUpdateStyle: ShouldUpdateStyle
) -> Bool {
  if node.computeEditability(.NotEditable, shouldUpdateStyle) != .ReadOnly {
    return true
  }
  switch editableType {
  case .ContentIsEditable:
    return false
  case .HasEditableAXRole:
    return isEditableToAccessibility(node: node)
  }
}

func hasEditableStyle(node: NodeWrapper, editableType: EditableType) -> Bool {
  return computeEditability(node: node, editableType: editableType, shouldUpdateStyle: .DoNotUpdate)
}

func isEditableNode(node: NodeWrapper) -> Bool {
  return computeEditability(
    node: node, editableType: .ContentIsEditable, shouldUpdateStyle: .Update)
}

func isEditablePosition(position: Position, editableType: EditableType = .ContentIsEditable) -> Bool
{
  let node: NodeWrapper? = position.containerNode()
  return node != nil
    && computeEditability(node: node!, editableType: editableType, shouldUpdateStyle: .Update)
}

func isAtUnsplittableElement(position: Position) -> Bool {
  let node: NodeWrapper? = position.containerNode()
  return CPtrToInt(node?.p) == CPtrToInt(editableRootForPosition(position: position)?.p)
    || CPtrToInt(node?.p)
      == CPtrToInt(enclosingNodeOfType(position: position, nodeIsOfType: isTableCell)?.p)
}

func isRichlyEditablePosition(position: Position) -> Bool {
  let node: NodeWrapper? = position.containerNode()
  return node != nil && node!.hasRichlyEditableStyle()
}

func editableRootForPosition(position: Position, editableType: EditableType = .ContentIsEditable)
  -> ElementWrapper?
{
  let node: NodeWrapper? = position.containerNode()
  if node == nil {
    return nil
  }
  switch editableType {
  case .HasEditableAXRole:
    if let cache = node!.document().existingAXObjectCache() {
      return cache.rootAXEditableElement(node)
    }
  /* TRANSLATE-REVIEW: no rule for AttributedStmt */
  case .ContentIsEditable:
    return node!.rootEditableElement()
  }
  return nil
}

func unsplittableElementForPosition(position: Position) -> ElementWrapper? {
  fatalError("Not implemented")
}

func nextCandidate(position: Position) -> Position {
  var nextPosition = PositionIterator(pos: position)
  while !nextPosition.atEnd() {
    nextPosition.increment()
    if nextPosition.isCandidate() {
      return nextPosition.toPosition()
    }
  }
  return Position()
}

func nextVisuallyDistinctCandidate(
  position: Position, skipDisplayContents: SkipDisplayContents = .Yes
) -> Position {
  // FIXME: Use PositionIterator instead.
  var nextPosition = position
  let downstreamStart = nextPosition.downstream()
  while !nextPosition.atEndOfTree() {
    nextPosition = nextPosition.next(moveType: .Character)
    if nextPosition.isCandidate() && nextPosition.downstream() != downstreamStart {
      return nextPosition
    }
    if let node = nextPosition.containerNode() {
      if node.renderer() == nil {
        if skipDisplayContents == .No {
          if let element = node as? ElementWrapper, element.hasDisplayContents() {
            continue
          }
        }
        nextPosition = lastPositionInOrAfterNode(node)
      }
    }
  }
  return Position()
}

func previousCandidate(position: Position) -> Position {
  var previousPosition = PositionIterator(pos: position)
  while !previousPosition.atStart() {
    previousPosition.decrement()
    if previousPosition.isCandidate() {
      return previousPosition.toPosition()
    }
  }
  return Position()
}

func previousVisuallyDistinctCandidate(position: Position) -> Position {
  // FIXME: Use PositionIterator instead.
  var previousPosition = position
  let downstreamStart = previousPosition.downstream()
  while !previousPosition.atStartOfTree() {
    previousPosition = previousPosition.previous(moveType: .Character)
    if previousPosition.isCandidate() && previousPosition.downstream() != downstreamStart {
      return previousPosition
    }
    if let node = previousPosition.containerNode() {
      if node.renderer() == nil {
        previousPosition = firstPositionInOrBeforeNode(node)
      }
    }
  }
  return Position()
}

func firstEditablePositionAfterPositionInRoot(
  position: Position, highestRoot: ContainerNodeWrapper?
) -> Position {
  fatalError("Not implemented")
}

func deprecatedIsEditingWhitespace(c: UInt16) -> Bool {
  return Int32(c) == Int32(noBreakSpace) || Int32(c) == Int32(32 /* ' ' */)
    || Int32(c) == Int32(10 /* '\n' */) || Int32(c) == Int32(9 /* '\t' */)
}

func deprecatedIsCollapsibleWhitespace(c: UInt16) -> Bool {
  return Int32(c) == Int32(32 /* ' ' */) || Int32(c) == Int32(10 /* '\n' */)
}

func editingIgnoresContent(node: NodeWrapper) -> Bool {
  return !node.canContainRangeEndPoint()
}

func positionBeforeOrAfterNodeIsCandidate(node: NodeWrapper) -> Bool {
  return isRenderedTable(node: node) || editingIgnoresContent(node: node)
}

func firstPositionInOrBeforeNode(_ node: NodeWrapper?) -> Position {
  if node == nil {
    return Position()
  }
  return editingIgnoresContent(node: node!)
    ? positionBeforeNode(anchorNode: node) : firstPositionInNode(anchorNode: node)
}

func lastPositionInOrAfterNode(_ node: NodeWrapper?) -> Position {
  if node == nil {
    return Position()
  }
  return editingIgnoresContent(node: node!)
    ? positionAfterNode(anchorNode: node) : lastPositionInNode(anchorNode: node)
}

func lastEditablePositionBeforePositionInRoot(
  position: Position, highestRoot: ContainerNodeWrapper?
) -> Position {
  fatalError("Not implemented")
}

func isBlock(node: NodeWrapper) -> Bool {
  return node.renderer() != nil && !(node.renderer()!.isInline())
}

func isInline(node: NodeWrapper) -> Bool {
  return node.renderer() != nil && node.renderer()!.isInline()
}

func enclosingBlock(
  node: NodeWrapper?, rule: EditingBoundaryCrossingRule = .CannotCrossEditingBoundary
) -> ElementWrapper? {
  return enclosingNodeOfType(
    position: firstPositionInOrBeforeNode(node), nodeIsOfType: isBlock, rule: rule)
    as? ElementWrapper
}

func directionOfEnclosingBlock(position: Position) -> TextDirection {
  let block: ElementWrapper? = enclosingBlock(node: position.protectedContainerNode())
  if block == nil {
    return .LTR
  }
  let renderer: RenderElementWrapper? = block!.renderer() as? RenderElementWrapper
  if renderer == nil {
    return .LTR
  }
  return renderer!.style().direction()
}

func lastOffsetForEditing(node: NodeWrapper) -> Int32 {
  if node.isCharacterDataNode() || node.hasChildNodes() {
    return Int32(node.length())
  }
  // FIXME: Might be more helpful to return 1 for any node where editingIgnoresContent is true, even one that happens to have child nodes, like a select element with option node children.
  return editingIgnoresContent(node: node) ? 1 : 0
  // FIXME: Might be more helpful to return 1 for any node where editingIgnoresContent is true, even one that happens to have child nodes, like a select element with option node children.
}

func isAmbiguousBoundaryCharacter(character: UInt16) -> Bool {
  // These are characters that can behave as word boundaries, but can appear within words.
  // If they are just typed, i.e. if they are immediately followed by a caret, we want to delay text checking until the next character has been typed.
  // FIXME: this is required until <rdar://problem/6853027> is fixed and text checking can do this for us.
  return Int32(character) == Int32(39 /* '\'' */) || Int32(character) == Int32(64 /* '@' */)
    || Int32(character) == Int32(rightSingleQuotationMark)
    || Int32(character) == Int32(hebrewPunctuationGershayim)
  // These are characters that can behave as word boundaries, but can appear within words.
  // If they are just typed, i.e. if they are immediately followed by a caret, we want to delay text checking until the next character has been typed.
  // FIXME: this is required until <rdar://problem/6853027> is fixed and text checking can do this for us.
}

func stringWithRebalancedWhitespace(
  string: StringWrapper, startIsStartOfParagraph: Bool, shouldEmitNBSPbeforeEnd: Bool
) -> StringWrapper {
  fatalError("Not implemented")
}

func isTableStructureNode(node: NodeWrapper) -> Bool {
  let renderer: RenderObjectWrapper? = node.renderer()
  return renderer != nil
    && (renderer!.isRenderTableCell() || renderer!.isRenderTableRow()
      || renderer!.isRenderTableSection() || renderer!.isRenderTableCol())
}

func nonBreakingSpaceString() -> StringWrapper {
  fatalError("Not implemented")
}

func isFirstPositionAfterTable(position: VisiblePosition) -> ElementWrapper? {
  let upstream = position.deepEquivalent().upstream()
  let node: NodeWrapper? = upstream.protectedDeprecatedNode()
  if node == nil {
    return nil
  }
  let renderer: RenderObjectWrapper? = node!.renderer()
  if renderer == nil || !renderer!.isRenderTable() || !upstream.atLastEditingPositionForNode() {
    return nil
  }
  return (node as! ElementWrapper)
}

func isLastPositionBeforeTable(position: VisiblePosition) -> ElementWrapper? {
  let downstream = position.deepEquivalent().downstream()
  let node: NodeWrapper? = downstream.protectedDeprecatedNode()
  if node == nil {
    return nil
  }
  let renderer: RenderObjectWrapper? = node!.renderer()
  if renderer == nil || !renderer!.isRenderTable() || !downstream.atFirstEditingPositionForNode() {
    return nil
  }
  return (node as! ElementWrapper)
}

func visiblePositionBeforeNode(node: NodeWrapper) -> VisiblePosition {
  if node.hasChildNodes() {
    return VisiblePosition(firstPositionInOrBeforeNode(node))
  }
  assert(node.parentNode() != nil)
  assert(!(node.parentNode()!.isShadowRoot()))
  return VisiblePosition(positionInParentBeforeNode(node: node))
}

func visiblePositionAfterNode(node: NodeWrapper) -> VisiblePosition {
  if node.hasChildNodes() {
    return VisiblePosition(lastPositionInOrAfterNode(node))
  }
  assert(node.parentNode() != nil)
  assert(!(node.parentNode()!.isShadowRoot()))
  return VisiblePosition(positionInParentAfterNode(node: node))
}

func closestEditablePositionInElementForAbsolutePoint(element: ElementWrapper, point: IntPoint)
  -> VisiblePosition
{
  fatalError("Not implemented")
}

func isListHTMLElement(node: NodeWrapper?) -> Bool {
  return node != nil
    && (node! is HTMLUListElementWrapper || node! is HTMLOListElementWrapper
      || node! is HTMLDListElementWrapper)
}

func isListItem(node: NodeWrapper) -> Bool {
  return isListHTMLElement(node: node.parentNode())
    || (node.renderer() != nil && node.renderer()!.isRenderListItem())
}

func enclosingElementWithTag(position: Position, tagName: QualifiedName) -> ElementWrapper? {
  let root: ContainerNodeWrapper? = highestEditableRoot(position: position)
  var node: NodeWrapper? = position.protectedDeprecatedNode()
  while node != nil {
    if root != nil && !node!.hasEditableStyle() {
      node = node!.parentNode()
      continue
    }
    let element: ElementWrapper? = node! as? ElementWrapper
    if element == nil {
      node = node!.parentNode()
      continue
    }
    if element!.hasTagName(tagName) {
      return element
    }
    if CPtrToInt(node?.p) == CPtrToInt(root?.p) {
      return nil
    }
    node = node!.parentNode()
  }
  return nil
}

func enclosingNodeOfType(
  position: Position, nodeIsOfType: (NodeWrapper) -> Bool,
  rule: EditingBoundaryCrossingRule = .CannotCrossEditingBoundary
) -> NodeWrapper? {
  // FIXME: support CanSkipCrossEditingBoundary
  assert(rule == .CanCrossEditingBoundary || rule == .CannotCrossEditingBoundary)
  let root: ContainerNodeWrapper? =
    rule == .CannotCrossEditingBoundary ? highestEditableRoot(position: position) : nil
  var n: NodeWrapper? = position.protectedDeprecatedNode()
  while n != nil {
    // Don't return a non-editable node if the input position was editable, since
    // the callers from editing will no doubt want to perform editing inside the returned node.
    if root != nil && !n!.hasEditableStyle() {
      n = n!.parentNode()
      continue
    }
    if nodeIsOfType(n!) {
      return n
    }
    if CPtrToInt(n?.p) == CPtrToInt(root?.p) {
      return nil
    }
    n = n!.parentNode()
  }
  return nil
}

func highestEnclosingNodeOfType(
  position: Position, nodeIsOfType: (NodeWrapper) -> Bool,
  rule: EditingBoundaryCrossingRule = .CannotCrossEditingBoundary, stayWithin: NodeWrapper? = nil
) -> NodeWrapper? {
  var highest: NodeWrapper? = nil
  let root: ContainerNodeWrapper? =
    rule == .CannotCrossEditingBoundary ? highestEditableRoot(position: position) : nil
  var n: NodeWrapper? = position.containerNode()
  while n != nil && CPtrToInt(n?.p) != CPtrToInt(stayWithin?.p) {
    if root != nil && !n!.hasEditableStyle() {
      n = n!.parentNode()
      continue
    }
    if nodeIsOfType(n!) {
      highest = n
    }
    if CPtrToInt(n?.p) == CPtrToInt(root?.p) {
      break
    }
    n = n!.parentNode()
  }
  return highest
}

func hasARenderedDescendant(node: NodeWrapper?, excludedNode: NodeWrapper?) -> Bool {
  var n: NodeWrapper? = node!.firstChild()
  while n != nil {
    if CPtrToInt(n?.p) == CPtrToInt(excludedNode?.p) {
      n = nextSkippingChildren(n!, node)
      continue
    }
    if n!.renderer() != nil {
      return true
    }
    n = next(n!, node)
  }
  return false
}

func highestNodeToRemoveInPruning(node: NodeWrapper?) -> NodeWrapper? {
  var previousNode: NodeWrapper? = nil
  let rootEditableElement: ElementWrapper? = node != nil ? node!.rootEditableElement() : nil
  var currentNode: NodeWrapper? = node
  while currentNode != nil {
    if let renderer = currentNode!.renderer() {
      if !renderer.canHaveChildren()
        || hasARenderedDescendant(node: currentNode, excludedNode: previousNode)
        || CPtrToInt(rootEditableElement?.p) == CPtrToInt(currentNode?.p)
      {
        return previousNode
      }
    }
    previousNode = currentNode
    currentNode = currentNode!.parentNode()
  }
  return nil
}

func enclosingTableCell(position: Position) -> ElementWrapper? {
  return (enclosingNodeOfType(position: position, nodeIsOfType: isTableCell) as! ElementWrapper)
}

func enclosingAnchorElement(p: Position) -> ElementWrapper? {
  var node: NodeWrapper? = p.protectedDeprecatedNode()
  while node != nil {
    if let element = node! as? ElementWrapper, element.isLink() {
      return element
    }
    node = node!.parentNode()
  }
  return nil
}

func enclosingList(node: NodeWrapper?) -> HTMLElementWrapper? {
  if node == nil {
    return nil
  }
  let root: ContainerNodeWrapper? = highestEditableRoot(position: firstPositionInOrBeforeNode(node))
  var ancestor: ContainerNodeWrapper? = node!.parentNode()
  while ancestor != nil {
    let htmlElement: HTMLElementWrapper? = ancestor! as? HTMLElementWrapper
    if htmlElement != nil
      && (htmlElement! is HTMLUListElementWrapper || htmlElement! is HTMLOListElementWrapper)
    {
      return htmlElement
    }
    if CPtrToInt(ancestor?.p) == CPtrToInt(root?.p) {
      return nil
    }
    ancestor = ancestor!.parentNode()
  }
  return nil
}

func enclosingListChild(node: NodeWrapper?) -> NodeWrapper? {
  if node == nil {
    return nil
  }
  // Check for a list item element, or for a node whose parent is a list element. Such a node
  // will appear visually as a list item (but without a list marker)
  let root: ContainerNodeWrapper? = highestEditableRoot(position: firstPositionInOrBeforeNode(node))
  // FIXME: This function is inappropriately named since it starts with node instead of node->parentNode()
  var n: NodeWrapper? = node
  while n != nil && n!.parentNode() != nil {
    if n! is HTMLLIElementWrapper
      || (isListHTMLElement(node: n!.parentNode()) && CPtrToInt(n?.p) != CPtrToInt(root?.p))
    {
      return n
    }
    if CPtrToInt(n?.p) == CPtrToInt(root?.p) || isTableCell(node: n!) {
      return nil
    }
    n = n!.parentNode()
  }
  return nil
}

func enclosingEmptyListItem(position: VisiblePosition) -> NodeWrapper? {
  // Check that position is on a line by itself inside a list item
  let listChildNode: NodeWrapper? = enclosingListChild(
    node: position.deepEquivalent().protectedDeprecatedNode())
  if listChildNode == nil || !isStartOfParagraph(pos: position) || !isEndOfParagraph(pos: position)
  {
    return nil
  }
  let firstInListChild = VisiblePosition(firstPositionInOrBeforeNode(listChildNode))
  let lastInListChild = VisiblePosition(lastPositionInOrAfterNode(listChildNode))
  if firstInListChild != position || lastInListChild != position {
    return nil
  }
  return listChildNode
}

func outermostEnclosingList(node: NodeWrapper?, rootList: NodeWrapper? = nil) -> HTMLElementWrapper?
{
  var list: HTMLElementWrapper? = enclosingList(node: node)
  if list == nil {
    return nil
  }
  while let nextList = enclosingList(node: list) {
    if CPtrToInt(nextList.p) == CPtrToInt(rootList?.p) {
      break
    }
    list = nextList
  }
  return list
}

func canMergeLists(firstList: ElementWrapper?, secondList: ElementWrapper?) -> Bool {
  let first: HTMLElementWrapper? = firstList as? HTMLElementWrapper
  let second: HTMLElementWrapper? = secondList as? HTMLElementWrapper
  if first == nil || second == nil {
    return false
  }
  return first!.localName() == second!.localName() && first!.hasEditableStyle()
    && second!.hasEditableStyle()
    && CPtrToInt(first!.rootEditableElement()?.p) == CPtrToInt(second!.rootEditableElement()?.p)
    && isVisiblyAdjacent(
      first: positionInParentAfterNode(node: first),
      second: positionInParentBeforeNode(node: second))
  // make sure the list types match (ol vs. ul)
  // both lists are editable
  // don't cross editing boundaries
  // Make sure there is no visible content between this li and the previous list.
}

func previousNodeConsideringAtomicNodes(node: NodeWrapper?) -> NodeWrapper? {
  if node!.previousSibling() != nil {
    var n: NodeWrapper? = node!.previousSibling()
    while !isAtomicNode(node: n) && n!.lastChild() != nil {
      n = n!.lastChild()
    }
    return n
  }
  return node!.parentNode()
}

func nextNodeConsideringAtomicNodes(node: NodeWrapper?) -> NodeWrapper? {
  if !isAtomicNode(node: node) && node!.firstChild() != nil {
    return node!.firstChild()
  }
  if node!.nextSibling() != nil {
    return node!.nextSibling()
  }
  var n: NodeWrapper? = node
  while n != nil && n!.nextSibling() == nil {
    n = n!.parentNode()
  }
  if n != nil {
    return n!.nextSibling()
  }
  return nil
}

func previousLeafNode(node: NodeWrapper?) -> NodeWrapper? {
  var node = node
  while true {
    node = previousNodeConsideringAtomicNodes(node: node)
    if node == nil {
      break
    }
    if isAtomicNode(node: node) {
      return node
    }
  }
  return nil
}

func nextLeafNode(node: NodeWrapper?) -> NodeWrapper? {
  var node = node
  while true {
    node = nextNodeConsideringAtomicNodes(node: node)
    if node == nil {
      break
    }
    if isAtomicNode(node: node) {
      return node
    }
  }
  return nil
}

func isRenderedTable(node: NodeWrapper?) -> Bool {
  let element: HTMLElementWrapper? = node as? HTMLElementWrapper
  if element == nil {
    return false
  }
  let renderer: RenderElementWrapper? = element!.renderer() as? RenderElementWrapper
  return renderer != nil && renderer!.isRenderTable()
}

func isTableCell(node: NodeWrapper) -> Bool {
  let renderer: RenderObjectWrapper? = node.renderer()
  if renderer == nil {
    return node.hasTdTagName() || node.hasThTagName()
  }
  return renderer!.isRenderTableCell()
}

func isEmptyTableCell(node: NodeWrapper?) -> Bool {
  var node = node
  // Returns true IFF the passed in node is one of:
  //   .) a table cell with no children,
  //   .) a table cell with a single BR child, and which has no other child renderers, including :before and :after renderers
  //   .) the BR child of such a table cell
  // Find rendered node
  while node != nil && node!.renderer() == nil {
    node = node!.parentNode()
  }
  if node == nil {
    return false
  }
  // Make sure the rendered node is a table cell or <br>.
  // If it's a <br>, then the parent node has to be a table cell.
  var renderer: RenderObjectWrapper? = node!.renderer()
  if renderer!.isBRForRenderObject() {
    renderer = renderer!.parent()
    if renderer == nil {
      return false
    }
  }
  let renderTableCell: RenderTableCellWrapper? = renderer! as? RenderTableCellWrapper
  if renderTableCell == nil {
    return false
  }
  // Check that the table cell contains no child renderers except for perhaps a single <br>.
  let childRenderer: RenderObjectWrapper? = renderTableCell!.firstChild()
  if childRenderer == nil {
    return true
  }
  if !childRenderer!.isBRForRenderObject() {
    return false
  }
  return childRenderer!.nextSibling() == nil
}

func createDefaultParagraphElement(document: Document) -> HTMLElementWrapper {
  fatalError("Not implemented")
}

func createHTMLElement(document: Document, name: QualifiedName) -> HTMLElementWrapper {
  fatalError("Not implemented")
}

func createHTMLElement(document: Document, tagName: AtomStringWrapper) -> HTMLElementWrapper {
  fatalError("Not implemented")
}

func tabSpanNode(node: NodeWrapper?) -> HTMLSpanElementWrapper? {
  fatalError("Not implemented")
}

func parentTabSpanNode(node: NodeWrapper?) -> HTMLSpanElementWrapper? {
  return node is TextWrapper ? tabSpanNode(node: node!.parentNode()) : nil
}

func createTabSpanElement(document: Document, tabTextNode: TextWrapper) -> ElementWrapper {
  fatalError("Not implemented")
}

func createTabSpanElement(document: Document, tabText: StringWrapper) -> ElementWrapper {
  return createTabSpanElement(document: document, tabTextNode: document.createTextNode(tabText))
}

func createTabSpanElement(document: Document) -> ElementWrapper {
  return createTabSpanElement(
    document: document,
    tabTextNode: document.createEditingTextNode(StringWrapper(ASCIILiteral("\t"))))
}

func isNodeRendered(node: NodeWrapper) -> Bool {
  let renderer: RenderObjectWrapper? = node.renderer()
  return renderer != nil && renderer!.style().visibility() == .Visible
}

func numEnclosingMailBlockquotes(position: Position) -> UInt32 {
  var count: UInt32 = 0
  var node: NodeWrapper? = position.protectedDeprecatedNode()
  while node != nil {
    if isMailBlockquote(node: node!) {
      count += 1
    }
    node = node!.parentNode()
  }
  return count
}

func updatePositionForNodeRemoval(position: inout Position, node: NodeWrapper) {
  if position.isNull() {
    return
  }
  switch position.anchorType() {
  case .PositionIsBeforeChildren:
    if node.containsIncludingShadowDOM(position.containerNode()) {
      position = positionInParentBeforeNode(node: node)
    }
    break
  case .PositionIsAfterChildren:
    if node.containsIncludingShadowDOM(position.containerNode()) {
      position = positionInParentBeforeNode(node: node)
    }
    break
  case .PositionIsOffsetInAnchor:
    if CPtrToInt(position.containerNode()?.p) == CPtrToInt(node.parentNode()?.p)
      && UInt32(UInt32(position.offsetInContainerNode())) > node.computeNodeIndex()
    {
      position.moveToOffset(offset: UInt32(position.offsetInContainerNode() - 1))
    } else if node.containsIncludingShadowDOM(position.containerNode()) {
      position = positionInParentBeforeNode(node: node)
    }
    break
  case .PositionIsAfterAnchor:
    if node.containsIncludingShadowDOM(position.anchorNode()) {
      position = positionInParentAfterNode(node: node)
    }
    break
  case .PositionIsBeforeAnchor:
    if node.containsIncludingShadowDOM(position.anchorNode()) {
      position = positionInParentBeforeNode(node: node)
    }
    break
  }
}

func isMailBlockquote(node: NodeWrapper) -> Bool {
  fatalError("Not implemented")
}

func caretMinOffset(node: NodeWrapper) -> Int32 {
  fatalError("Not implemented")
}

func caretMaxOffset(node: NodeWrapper) -> Int32 {
  // For rendered text nodes, return the last position that a caret could occupy.
  if let text = node as? TextWrapper {
    if let renderer = text.renderer() {
      return renderer.caretMaxOffset()
    }
  }
  return lastOffsetForEditing(node: node)
}

func lineBreakExistsAtVisiblePosition(position: VisiblePosition) -> Bool {
  return lineBreakExistsAtPosition(position: position.deepEquivalent().downstream())
}

func lineBreakExistsAtPosition(position: Position) -> Bool {
  if position.isNull() {
    return false
  }
  if position.anchorNode()!.hasBrTagName() && position.atFirstEditingPositionForNode() {
    return true
  }
  if position.anchorNode()!.renderer() == nil {
    return false
  }
  let textNode: TextWrapper? = position.anchorNode()! as? TextWrapper
  if textNode == nil || !(position.anchorNode()!.renderer()!.style().preserveNewline()) {
    return false
  }
  let offset: UInt32 = UInt32(position.offsetInContainerNode())
  return offset < textNode!.length() && Int32(textNode!.data()[offset]) == Int32(10 /* '\n' */)
}

func selectionForParagraphIteration(original: VisibleSelectionWrapper) -> VisibleSelectionWrapper {
  fatalError("Not implemented")
}

func indexForVisiblePosition(visiblePosition: VisiblePosition, scope: ContainerNodeWrapper?)
  -> Int32
{
  fatalError("Not implemented")
}

func indexForVisiblePosition(
  node: NodeWrapper, visiblePosition: VisiblePosition, behaviors: TextIteratorBehavior
) -> Int32 {
  fatalError("Not implemented")
}

func visiblePositionForPositionWithOffset(position: VisiblePosition, offset: Int32)
  -> VisiblePosition
{
  let root: ContainerNodeWrapper? = nil
  let startIndex: UInt32 = UInt32(indexForVisiblePosition(visiblePosition: position, scope: root))
  if root == nil {
    return VisiblePosition()
  }
  return visiblePositionForIndex(index: Int32(startIndex + UInt32(offset)), scope: root)
}

func visiblePositionForIndex(
  index: Int32, scope: NodeWrapper?,
  behaviors: TextIteratorBehavior = [.EmitsCharactersBetweenAllVisiblePositions]
) -> VisiblePosition {
  if scope == nil {
    return VisiblePosition()
  }
  return VisiblePosition(
    makeDeprecatedLegacyPosition(
      point: resolveCharacterLocation(
        scope: makeRangeSelectingNodeContents(node: scope!), location: UInt64(index),
        behaviors: behaviors)))
}

func visiblePositionForIndexUsingCharacterIterator(node: NodeWrapper, index: Int32)
  -> VisiblePosition
{
  if index <= 0 {
    return VisiblePosition(firstPositionInOrBeforeNode(node))
  }
  let range = makeRangeSelectingNodeContents(node: node)
  var it = CharacterIterator(range: range)
  if !it.atEnd() {
    it.advance(count: index - 1)
  }
  if !it.atEnd() && it.text().length() == 1 && Int32(it.text()[0]) == Int32(10 /* '\n' */) {
    // FIXME: workaround for collapsed range (where only start position is correct) emitted for some emitted newlines.
    it.advance(count: 1)
    if !it.atEnd() {
      return VisiblePosition(makeDeprecatedLegacyPosition(point: it.range().start))
    }
  }
  return VisiblePosition(
    makeDeprecatedLegacyPosition(point: (it.atEnd() ? range : it.range()).end), .Upstream)
}

func isVisiblyAdjacent(first: Position, second: Position) -> Bool {
  return VisiblePosition(first) == VisiblePosition(second.upstream())
}

func isNodeVisiblyContainedWithin(node: NodeWrapper, range: SimpleRange) -> Bool {
  fatalError("Not implemented")
}

func isRenderedAsNonInlineTableImageOrHR(node: NodeWrapper?) -> Bool {
  if node == nil {
    return false
  }
  let renderer: RenderObjectWrapper? = node!.renderer()
  return renderer != nil && !renderer!.isInline()
    && (renderer!.isRenderTable() || renderer!.isImage() || renderer!.isHR())
}

func elementIfEquivalent(first: ElementWrapper, second: NodeWrapper) -> ElementWrapper? {
  let secondElement: ElementWrapper? = second as? ElementWrapper
  if secondElement != nil && first.hasTagName(secondElement!.tagQName())
    && first.hasEquivalentAttributes(secondElement!)
  {
    return secondElement
  }
  return nil
}

func isNonTableCellHTMLBlockElement(node: NodeWrapper?) -> Bool {
  return node!.hasListingTagName() || node!.hasOlTagName() || node!.hasPreTagName()
    || node! is HTMLTableElementWrapper || node!.hasUlTagName() || node!.hasXmpTagName()
    || node!.hasH1TagName() || node!.hasH2TagName() || node!.hasH3TagName() || node!.hasH4TagName()
    || node!.hasH5TagName()
}

func adjustedSelectionStartForStyleComputation(selection: VisibleSelectionWrapper) -> Position {
  fatalError("Not implemented")
}

func elementIfBlockFlow(node: NodeWrapper) -> ElementWrapper? {
  let element: ElementWrapper? = node as? ElementWrapper
  if element == nil {
    return nil
  }
  let renderer: RenderElementWrapper? = element!.renderer() as? RenderElementWrapper
  return renderer != nil && renderer!.isRenderBlockFlow() ? element : nil
}

func isBlockFlowElement(node: NodeWrapper) -> Bool {
  return elementIfBlockFlow(node: node) != nil
}

func deprecatedEnclosingBlockFlowElement(node: NodeWrapper?) -> ElementWrapper? {
  var node = node
  if node == nil {
    return nil
  }
  if let element = elementIfBlockFlow(node: node!) {
    return element
  }
  while true {
    node = node!.parentNode()
    if node == nil {
      break
    }
    if let element = elementIfBlockFlow(node: node!) {
      return element
    }
    if let body = node! as? HTMLBodyElement {
      return body
    }
  }
  return nil
}

func caretRendersInsideNode(node: NodeWrapper) -> Bool {
  return !isRenderedTable(node: node) && !editingIgnoresContent(node: node)
}

func rendererForCaretPainting(node: NodeWrapper?) -> RenderBlockWrapper? {
  if node == nil {
    return nil
  }
  let renderer: RenderObjectWrapper? = node!.renderer()
  if renderer == nil {
    return nil
  }
  // If caretNode is a block and caret is inside it, then caret should be painted by that block.
  if let blockFlow = renderer! as? RenderBlockFlowWrapper {
    if caretRendersInsideNode(node: node!) {
      return blockFlow
    }
  }
  return renderer!.containingBlock()
}

func localCaretRectInRendererForCaretPainting(
  caretPosition: VisiblePosition, caretPainter: inout RenderBlockWrapper?
) -> LayoutRectWrapper {
  if caretPosition.isNull() {
    return LayoutRectWrapper()
  }
  assert((caretPosition.deepEquivalent().deprecatedNode()!.renderer()) != nil)
  let decomposed = caretPosition.localCaretRect()
  var localRect = decomposed.rect
  let renderer = decomposed.renderer
  return localCaretRectInRendererForRect(
    localRect: &localRect, node: caretPosition.deepEquivalent().deprecatedNode(),
    renderer: renderer, caretPainter: &caretPainter)
}

func localCaretRectInRendererForRect(
  localRect: inout LayoutRectWrapper, node: NodeWrapper?, renderer: RenderObjectWrapper?,
  caretPainter: inout RenderBlockWrapper?
) -> LayoutRectWrapper {
  var renderer = renderer
  // Get the renderer that will be responsible for painting the caret
  // (which is either the renderer we just found, or one of its containers).
  caretPainter = rendererForCaretPainting(node: node)
  // Compute an offset between the renderer and the caretPainter.
  while CPtrToInt(renderer?.id()) != CPtrToInt(caretPainter?.id()) {
    let containerObject: RenderElementWrapper? = renderer!.container()
    if containerObject == nil {
      return LayoutRectWrapper()
    }
    var ignored: Bool? = nil
    localRect.move(
      size: renderer!.offsetFromContainer(containerObject!, localRect.location(), &ignored))
    renderer = containerObject
  }
  return localRect
}

func absoluteBoundsForLocalCaretRect(
  rendererForCaretPainting: RenderBlockWrapper?, rect: LayoutRectWrapper, insideFixed: inout Bool?
) -> IntRect {
  if insideFixed != nil {
    insideFixed! = false
  }
  if rendererForCaretPainting == nil || rect.isEmpty() {
    return IntRect()
  }
  var localRect = rect
  rendererForCaretPainting!.flipForWritingMode(rect: &localRect)
  return rendererForCaretPainting!.localToAbsoluteQuad(
    FloatQuad(inRect: localRect.FloatRect()), [.UseTransforms], &insideFixed
  ).enclosingBoundingBox()
}

func absoluteBoundsForLocalCaretRect(
  rendererForCaretPainting: RenderBlockWrapper?, rect: LayoutRectWrapper
) -> IntRect {
  var ignored: Bool? = nil
  return absoluteBoundsForLocalCaretRect(
    rendererForCaretPainting: rendererForCaretPainting, rect: rect, insideFixed: &ignored)
}
