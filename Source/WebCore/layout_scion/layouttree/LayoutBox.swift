/*
 * Copyright (C) 2018 Apple Inc. All rights reserved.
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

class BoxWrapper: Hashable {
  var p: UnsafeRawPointer?

  enum NodeType {
    case Text
    case GenericElement
    case ReplacedElement
    case DocumentElement
    case Body
    case TableWrapperBox  // The table generates a principal block container box called the table wrapper box that contains the table box and any caption boxes.
    case TableBox  // The table box is a block-level box that contains the table's internal table boxes.
    case Image
    case IFrame
    case LineBreak
    case WordBreakOpportunity
    case ListMarker
    case InputButton  // Buttons are implicit flex boxes with no flex display type.
  }

  enum IsAnonymous {
    case No
    case Yes
  }

  struct ElementAttributes {
    let nodeType: NodeType = .Text
    let isAnonymous: IsAnonymous = .No
  }

  struct BaseTypeFlag: OptionSet {
    let rawValue: UInt8

    static let InlineTextBoxFlag = BaseTypeFlag(rawValue: 1 << 0)
    static let ElementBoxFlag = BaseTypeFlag(rawValue: 1 << 1)
    static let InitialContainingBlockFlag = BaseTypeFlag(rawValue: 1 << 2)
  }

  init(
    _ elementAttributes: ElementAttributes, _ style: RenderStyleWrapper,
    firstLineStyle: RenderStyleWrapper?, _ baseTypeFlags: BaseTypeFlag
  ) {
    self.m_nodeType = elementAttributes.nodeType
    self.m_isAnonymous = elementAttributes.isAnonymous == .Yes
    self.m_baseTypeFlags = baseTypeFlags
    self.style = style
    if firstLineStyle != nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  init(wrapperStyle: RenderStyleWrapper = RenderStyleWrapper()) {
    self.m_nodeType = .Text
    self.m_isAnonymous = false
    self.m_baseTypeFlags = []
    self.style = wrapperStyle
  }

  func establishesFormattingContext() -> Bool {
    if p != nil {
      return wk_interop.Box_establishesFormattingContext(p)
    }
    // We need the final tree structure to tell whether a box establishes a certain formatting context.
    assert(!Phase.isInTreeBuilding())
    return establishesInlineFormattingContext()
      || establishesBlockFormattingContext()
      || establishesTableFormattingContext()
      || establishesFlexFormattingContext()
      || establishesGridFormattingContext()
      || establishesIndependentFormattingContext()
  }

  func establishesBlockFormattingContext() -> Bool {
    if p != nil {
      return wk_interop.Box_establishesBlockFormattingContext(p)
    }
    if isInlineIntegrationRoot() {
      return true
    }

    // ICB always creates a new (inital) block formatting context.
    if self is InitialContainingBlock {
      return true
    }

    if isTableWrapperBox() {
      return true
    }

    // A block box that establishes an independent formatting context establishes a new block formatting context for its contents.
    if isBlockBox() && establishesIndependentFormattingContext() {
      return true
    }

    // 9.4.1 Block formatting contexts
    // Floats, absolutely positioned elements, block containers (such as inline-blocks, table-cells, and table-captions)
    // that are not block boxes, and block boxes with 'overflow' other than 'visible' (except when that value has been propagated to the viewport)
    // establish new block formatting contexts for their contents.
    if isFloatingPositioned() {
      // Not all floating or out-of-positioned block level boxes establish BFC.
      // See [9.7 Relationships between 'display', 'position', and 'float'] for details.
      return isBlockContainer()
    }

    if isBlockContainer() && !isBlockBox() {
      return true
    }

    if isBlockBox() && !isOverflowVisible() {
      return true
    }

    return false
  }

  func establishesInlineFormattingContext() -> Bool {
    if p != nil {
      return wk_interop.Box_establishesInlineFormattingContext(p)
    }
    if isInlineIntegrationRoot() {
      return true
    }

    // 9.4.2 Inline formatting contexts
    // An inline formatting context is established by a block container box that contains no block-level boxes.
    if !isBlockContainer() {
      return false
    }

    guard let elementBox = self as? ElementBoxWrapper else { return false }

    // FIXME ???
    if elementBox.firstInFlowChild() == nil {
      return false
    }

    // It's enough to check the first in-flow child since we can't have both block and inline level sibling boxes.
    return elementBox.firstInFlowChild()!.isInlineLevelBox()
  }

  func establishesTableFormattingContext() -> Bool {
    return isTableBox()
  }

  func establishesFlexFormattingContext() -> Bool {
    return isFlexBox()
  }

  private func establishesGridFormattingContext() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func establishesIndependentFormattingContext() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isInFlow() -> Bool { return !isFloatingOrOutOfFlowPositioned() }

  func isPositioned() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isPositioned(p)
  }

  func isInFlowPositioned() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isInFlowPositioned(p)
  }

  func isOutOfFlowPositioned() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isOutOfFlowPositioned(p)
  }

  func isFixedPositioned() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isFixedPositioned(p)
  }

  func isFloatingPositioned() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isFloatingPositioned(p)
  }

  func hasFloatClear() -> Bool {
    return style.clear() != .None && (isBlockLevelBox() || isLineBreakBox())
  }

  func isFloatAvoider() -> Bool {
    if isFloatingPositioned() || hasFloatClear() {
      return true
    }

    return establishesTableFormattingContext() || establishesIndependentFormattingContext()
      || establishesBlockFormattingContext()
  }

  func isFloatingOrOutOfFlowPositioned() -> Bool {
    return isFloatingPositioned() || isOutOfFlowPositioned()
  }

  func isContainingBlockForInFlow() -> Bool {
    return isBlockContainer() || establishesFormattingContext()
  }

  func isContainingBlockForFixedPosition() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isContainingBlockForOutOfFlowPosition() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isContainingBlockForOutOfFlowPosition(p)
  }

  func isAnonymous() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isAnonymous(p)
  }

  // Block level elements generate block level boxes.
  func isBlockLevelBox() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isBlockLevelBox(p)
  }

  // A block-level box that is also a block container.
  func isBlockBox() -> Bool {
    // A block-level box that is also a block container.
    return isBlockLevelBox() && isBlockContainer()
  }

  // A block-level box is also a block container box unless it is a table box or the principal box of a replaced element.
  func isBlockContainer() -> Bool {
    if p != nil {
      return wk_interop.Box_isBlockContainer(p)
    }
    let display = style.display()
    return display == .Block
      || display == .FlowRoot
      || display == .ListItem
      || display == .RubyBlock
      || isInlineBlockBox()
      || isTableCell()
      || isTableCaption()  // TODO && !replaced element
  }

  func isInlineLevelBox() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isInlineLevelBox(p)
  }

  func isInlineBox() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isInlineBox(p)
  }

  func isAtomicInlineBox() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isAtomicInlineBox(p)
  }

  func isInlineBlockBox() -> Bool {
    if p != nil {
      return wk_interop.Box_isInlineBlockBox(p)
    }
    return style.display() == .InlineBlock
  }

  func isInlineTableBox() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isInlineTableBox(p)
  }

  func isInitialContainingBlock() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isInitialContainingBlock(p)
  }

  func isSizeContainmentBox() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRubyAnnotationBox() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isRubyAnnotationBox(p)
  }

  func isDocumentBox() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isBodyBox() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRuby() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isRuby(p)
  }

  func isRubyBase() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isRubyBase(p)
  }

  func isRubyInlineBox() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isRubyInlineBox(p)
  }

  func isTableWrapperBox() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isTableBox() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isTableCaption() -> Bool { return style.display() == .TableCaption }

  func isTableCell() -> Bool { return style.display() == .TableCell }

  func isFlexBox() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFlexItem() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isLineBreakBox() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isLineBreakBox(p)
  }

  func isWordBreakOpportunity() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isWordBreakOpportunity(p)
  }

  func isListMarkerBox() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isListMarkerBox(p)
  }

  func isReplacedBox() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isReplacedBox(p)
  }

  func isInlineIntegrationRoot() -> Bool {
    if p != nil {
      return wk_interop.Box_isInlineIntegrationRoot(p)
    }
    return m_isInlineIntegrationRoot
  }

  func isFirstChildForIntegration() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isFirstChildForIntegration(p)
  }

  func parent() -> ElementBoxWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    let unwrapped = wk_interop.Box_parent(p)
    assert(unwrapped != nil)
    let parentWrapped =
      wk_interop.Box_isInitialContainingBlock(unwrapped)
      ? InitialContainingBlock() : ElementBoxWrapper()
    parentWrapped.p = unwrapped
    let styleUnwrapped = wk_interop.Box_style(unwrapped)
    parentWrapped.style = convert_render_style(p: styleUnwrapped!)
    return parentWrapped
  }

  func nextSibling() -> BoxWrapper? {
    if p == nil {
      return nil
    }
    let unwrapped = wk_interop.Box_nextSibling(p)
    if unwrapped == nil {
      return nil
    }
    // TODO(asuhan): decide the type correctly
    let child =
      wk_interop.Box_isInlineTextBox(unwrapped)
      ? convert_inline_text_box(p: unwrapped!)
      : (wk_interop.Box_isElementBox(unwrapped)
        ? ElementBoxWrapper() : BoxWrapper())
    child.p = unwrapped
    let styleUnwrapped = wk_interop.Box_style(unwrapped)
    child.style = convert_render_style(p: styleUnwrapped!)
    return child
  }

  func nextInFlowSibling() -> BoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextInFlowOrFloatingSibling() -> BoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func previousInFlowSibling() -> BoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isDescendantOf(ancestor: ElementBoxWrapper) -> Bool {
    if ancestor.isInitialContainingBlock() {
      return true
    }
    for containingBlock in containingBlockChain(layoutBox: self) {
      if CPtrToInt(containingBlock.p) == CPtrToInt(ancestor.p) {
        return true
      }
    }
    return false
  }

  func isElementBox() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isElementBox(p)
  }

  func isInlineTextBox() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isInlineTextBox(p)
  }

  func isPaddingApplicable() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isOverflowVisible() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func firstLineStyle() -> RenderStyleWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    let unwrapped = wk_interop.Box_firstLineStyle(p)
    return convert_render_style(p: unwrapped!)
  }

  func setIsInlineIntegrationRoot() {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    wk_interop.Box_setIsInlineIntegrationRoot(p)
  }

  func setIsFirstChildForIntegration(value: Bool) {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    wk_interop.Box_setIsFirstChildForIntegration(p, value)
  }

  func associatedRubyAnnotationBox() -> ElementBoxWrapper? {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    if let unwrapped = wk_interop.Box_associatedRubyAnnotationBox(p) {
      let box = ElementBoxWrapper()
      box.p = unwrapped
      let styleUnwrapped = wk_interop.Box_style(unwrapped)
      box.style = convert_render_style(p: styleUnwrapped!)
      return box
    }
    return nil
  }

  func rendererForIntegration() -> RenderObjectWrapper? {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    let unwrapped = wk_interop.Box_rendererForIntegration(p)
    if unwrapped == nil {
      return nil
    }
    return RenderObjectWrapper.createFromRawPointer(p: unwrapped!)
  }

  func shape() -> ShapeWrapper? {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    if let unwrapped = wk_interop.Box_shape(p) {
      return ShapeWrapper(p: unwrapped)
    }
    return nil
  }

  func setShape(shape: ShapeWrapper) {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    wk_interop.Box_setShape(p, shape.p)
  }

  static func == (lhs: BoxWrapper, rhs: BoxWrapper) -> Bool {
    return lhs.p == rhs.p
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(p)
  }

  private let m_nodeType: NodeType
  private let m_isAnonymous: Bool

  private let m_baseTypeFlags: BaseTypeFlag
  private let m_isInlineIntegrationRoot = false

  var style: RenderStyleWrapper

  // Primary LayoutState gets a direct cache.
  #if ASSERT_ENABLED
    var m_primaryLayoutState: LayoutStateWrapper? = nil
  #endif
  var m_cachedGeometryForPrimaryLayoutState: BoxGeometry? = nil
}
