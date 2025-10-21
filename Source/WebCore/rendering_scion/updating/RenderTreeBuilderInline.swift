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

private func canUseAsParentForContinuation(renderer: RenderObjectWrapper?) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func nextContinuation(renderer: RenderObjectWrapper) -> RenderBoxModelObjectWrapper? {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func continuationBefore(parent: RenderInlineWrapper, beforeChild: RenderObjectWrapper?)
  -> RenderBoxModelObjectWrapper?
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

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
      // We have to split the parent flow.
      let newBox = parent.containingBlock()!.createAnonymousBlock()
      newBox.setIsContinuation()
      let oldContinuation = parent.continuation()
      if oldContinuation != nil {
        oldContinuation!.removeFromContinuationChain()
      }
      newBox.insertIntoContinuationChainAfter(afterRenderer: parent)
      let beforeChild = child.nextSibling()
      let removedChild = builder.detachFromRenderElement(
        parent: parent, child: child, willBeDestroyed: .No)
      splitFlow(
        parent: parent, beforeChild: beforeChild, newBlockBox: newBox, child: removedChild,
        oldCont: oldContinuation)
    }

    private func insertChildToContinuation(
      parent: RenderInlineWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?
    ) {
      let flow = continuationBefore(parent: parent, beforeChild: beforeChild)
      // It may or may not be the direct parent of the beforeChild.
      var beforeChildAncestor: RenderBoxModelObjectWrapper? = nil
      if beforeChild == nil {
        let continuation = nextContinuation(renderer: flow!)
        beforeChildAncestor = continuation != nil ? continuation : flow
      } else if canUseAsParentForContinuation(renderer: beforeChild!.parent()) {
        beforeChildAncestor = beforeChild!.parent() as? RenderBoxModelObjectWrapper
      } else if beforeChild!.parent() != nil {
        // In case of anonymous wrappers, the parent of the beforeChild is mostly irrelevant. What we need is the topmost wrapper.
        var parent = beforeChild!.parent()
        while parent != nil && parent!.parent() != nil && parent!.parent()!.isAnonymous() {
          // The ancestor candidate needs to be inside the continuation.
          if parent!.isContinuation() {
            break
          }
          parent = parent!.parent()
        }
        assert(parent != nil && parent!.parent() != nil)
        beforeChildAncestor = (parent!.parent() as! RenderBoxModelObjectWrapper)
      } else {
        fatalError("Not reached")
      }

      if child!.isFloatingOrOutOfFlowPositioned() {
        return builder.attachIgnoringContinuation(
          parent: beforeChildAncestor!, child: child!, beforeChild: beforeChild)
      }

      if CPtrToInt(flow?.p) == CPtrToInt(beforeChildAncestor?.p) {
        return builder.attachIgnoringContinuation(
          parent: flow!, child: child!, beforeChild: beforeChild)
      }
      // A continuation always consists of two potential candidates: an inline or an anonymous
      // block box holding block children.
      let childInline = newChildIsInline(parent: parent, child: child!)
      // The goal here is to match up if we can, so that we can coalesce and create the
      // minimal # of continuations needed for the inline.
      if childInline == beforeChildAncestor!.isInline()
        || (beforeChild != nil && beforeChild!.isInline())
      {
        return builder.attachIgnoringContinuation(
          parent: beforeChildAncestor!, child: child!, beforeChild: beforeChild)
      }
      if flow!.isInline() == childInline {
        return builder.attachIgnoringContinuation(parent: flow!, child: child!)  // Just treat like an append.
      }
      return builder.attachIgnoringContinuation(
        parent: beforeChildAncestor!, child: child!, beforeChild: beforeChild)
    }

    private func splitInlines(
      parent: RenderInlineWrapper, fromBlock: RenderBlockWrapper?, toBlock: RenderBlockWrapper?,
      middleBlock: RenderBlockWrapper?, beforeChild: RenderObjectWrapper?,
      oldCont: RenderBoxModelObjectWrapper?
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
      var pre: RenderBlockWrapper? = nil
      var block = parent.containingBlock()

      // Delete our line boxes before we do the inline split into continuations.
      block!.deleteLines()

      var createdPre: RenderBlockWrapper? = nil
      var madeNewBeforeBlock = false
      if block!.isAnonymousBlock()
        && (block!.parent() == nil || !block!.parent()!.createsAnonymousWrapper())
      {
        // We can reuse this block and make it the preBlock of the next continuation.
        pre = block
        pre!.removePositionedObjects(newContainingBlockCandidate: nil)
        // FIXME-BLOCKFLOW: The enclosing method should likely be switched over
        // to only work on RenderBlockFlow, in which case this conversion can be
        // removed.
        if let blockFlow = pre as? RenderBlockFlowWrapper {
          blockFlow.removeFloatingObjects()
        }
        block = block!.containingBlock()
      } else {
        // No anonymous block available for use. Make one.
        createdPre = block!.createAnonymousBlock()
        pre = createdPre
        madeNewBeforeBlock = true
      }

      let createdPost = pre!.createAnonymousBoxWithSameTypeAs(renderer: block!)
      let post = createdPost as! RenderBlockWrapper

      let boxFirst = madeNewBeforeBlock ? block!.firstChild() : pre!.nextSibling()
      if createdPre != nil {
        builder.attachToRenderElementInternal(
          parent: block!, child: createdPre, beforeChild: boxFirst)
      }
      builder.attachToRenderElementInternal(
        parent: block!, child: newBlockBox, beforeChild: boxFirst)
      builder.attachToRenderElementInternal(
        parent: block!, child: createdPost, beforeChild: boxFirst)
      block!.setChildrenInline(b: false)

      if madeNewBeforeBlock {
        var o = boxFirst
        while o != nil {
          let no = o
          let _ = SetForScope(
            scopedVariable: &builder.internalMovesType, newValue: IsInternalMove.Yes)
          o = no!.nextSibling()
          let childToMove = builder.detachFromRenderElement(
            parent: block!, child: no!, willBeDestroyed: .No)
          builder.attachToRenderElementInternal(parent: pre!, child: childToMove)
          no!.setNeedsLayoutAndPrefWidthsRecalc()
        }
      }

      splitInlines(
        parent: parent, fromBlock: pre, toBlock: post, middleBlock: newBlockBox,
        beforeChild: beforeChild, oldCont: oldCont)

      // We already know the newBlockBox isn't going to contain inline kids, so avoid wasting
      // time in makeChildrenNonInline by just setting this explicitly up front.
      newBlockBox.setChildrenInline(b: false)

      // We delayed adding the newChild until now so that the |newBlockBox| would be fully
      // connected, thus allowing newChild access to a renderArena should it need
      // to wrap itself in additional boxes (e.g., table construction).
      builder.attach(parent: newBlockBox, child: child!)

      // Always just do a full layout in order to ensure that line boxes (especially wrappers for images)
      // get deleted properly. Because objects moves from the pre block into the post block, we want to
      // make new line boxes instead of leaving the old line boxes around.
      pre!.setNeedsLayoutAndPrefWidthsRecalc()
      block!.setNeedsLayoutAndPrefWidthsRecalc()
      post.setNeedsLayoutAndPrefWidthsRecalc()
    }

    private let builder: RenderTreeBuilder
  }
}
