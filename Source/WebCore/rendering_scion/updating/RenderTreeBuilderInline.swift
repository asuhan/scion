/*
 * Copyright (C) 2018-2024 Apple Inc. All rights reserved.
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

private func inFlowPositionedInlineAncestor(renderer: RenderElementWrapper) -> RenderElementWrapper?
{
  var ancestor: RenderElementWrapper? = renderer
  while ancestor != nil && ancestor!.isRenderInline() {
    if ancestor!.isInFlowPositioned() {
      return ancestor
    }
    ancestor = ancestor!.parent()
  }
  return nil
}

extension RenderTreeBuilder {
  class Inline {
    init(builder: RenderTreeBuilder) {
      self.builder = builder
    }

    func attach(
      parent: RenderInlineWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?
    ) {
      var beforeChildOrPlaceholder = beforeChild
      if let fragmentedFlow = parent.enclosingFragmentedFlow() {
        beforeChildOrPlaceholder = builder.multiColumnBuilder!.resolveMovedChild(
          enclosingFragmentedFlow: fragmentedFlow, beforeChild: beforeChild)
      }
      if parent.continuation() != nil {
        insertChildToContinuation(
          parent: parent, child: child, beforeChild: beforeChildOrPlaceholder)
        return
      }
      attachIgnoringContinuation(
        parent: parent, child: child!, beforeChild: beforeChildOrPlaceholder)
    }

    func attachIgnoringContinuation(
      parent: RenderInlineWrapper, child: RenderObjectWrapper, beforeChild: RenderObjectWrapper?
    ) {
      var beforeChild = beforeChild
      // Make sure we don't append things after :after-generated content if we have it.
      if beforeChild == nil && parent.isAfterContent(obj: parent.lastChild()) {
        beforeChild = parent.lastChild()
      }

      let childInline = newChildIsInline(parent: parent, child: child)
      // This code is for the old block-inside-inline model that uses continuations.
      if !childInline && !child.isFloatingOrOutOfFlowPositioned() {
        // We are placing a block inside an inline. We have to perform a split of this
        // inline into continuations. This involves creating an anonymous block box to hold
        // |newChild|. We then make that block box a continuation of this inline. We take all of
        // the children after |beforeChild| and put them in a clone of this object.
        let newStyle = RenderStyleWrapper.createAnonymousStyleWithDisplay(
          parentStyle: parent.containingBlock() != nil
            ? parent.containingBlock()!.style() : parent.style(), display: .Block)

        // If inside an inline affected by in-flow positioning the block needs to be affected by it too.
        // Giving the block a layer like this allows it to collect the x/y offsets from inline parents later.
        if let positionedAncestor = inFlowPositionedInlineAncestor(renderer: parent) {
          newStyle.setPosition(v: positionedAncestor.style().position())
        }

        let newBox = CreateRenderer.RenderBlockFlow(
          type: .BlockFlow, document: parent.document(), style: newStyle)
        newBox.initializeStyle()
        newBox.setIsContinuation()
        let oldContinuation = parent.continuation()
        if oldContinuation != nil {
          oldContinuation!.removeFromContinuationChain()
        }
        newBox.insertIntoContinuationChainAfter(afterRenderer: parent)

        splitFlow(
          parent: parent, beforeChild: beforeChild, newBlockBox: newBox, child: child,
          oldCont: oldContinuation)
        return
      }

      builder.attachToRenderElement(parent: parent, child: child, beforeChild: beforeChild)
      child.setNeedsLayoutAndPrefWidthsRecalc()
    }

    // Make this private once all the mutation code is in RenderTreeBuilder.
    func childBecameNonInline(parent: RenderInlineWrapper, child: RenderElementWrapper) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func insertChildToContinuation(
      parent: RenderInlineWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func newChildIsInline(parent: RenderInlineWrapper, child: RenderObjectWrapper) -> Bool {
      // inline parent generates inline-table.
      return child.isInline()
        || (builder.tableBuilder!.childRequiresTable(parent: parent, child: child)
          && parent.style().display() == .Inline)
    }

    private func splitFlow(
      parent: RenderInlineWrapper, beforeChild: RenderObjectWrapper?,
      newBlockBox: RenderBlockWrapper, child: RenderObjectWrapper?,
      oldCont: RenderBoxModelObjectWrapper?
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private let builder: RenderTreeBuilder
  }
}
