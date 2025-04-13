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
  var style: RenderStyleWrapper

  init(style: RenderStyleWrapper = RenderStyleWrapper()) {
    self.style = style
  }

  func establishesFormattingContext() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_establishesFormattingContext(p)
  }

  func establishesBlockFormattingContext() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func establishesInlineFormattingContext() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_establishesInlineFormattingContext(p)
  }

  func establishesTableFormattingContext() -> Bool {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // A block-level box is also a block container box unless it is a table box or the principal box of a replaced element.
  func isBlockContainer() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isBlockContainer(p)
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
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isInlineBlockBox(p)
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

  func isTableCell() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

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
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.Box_isInlineIntegrationRoot(p)
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

  func associatedRubyAnnotationBox() -> ElementBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rendererForIntegration() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  static func == (lhs: BoxWrapper, rhs: BoxWrapper) -> Bool {
    return lhs.p == rhs.p
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(p)
  }
}
