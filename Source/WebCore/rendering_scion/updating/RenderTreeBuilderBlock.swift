/*
 * Copyright (C) 2017 Apple Inc. All rights reserved.
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

private func moveAllChildrenToInternal(
  from: RenderBoxModelObjectWrapper, newParent: RenderElementWrapper
) {
  while from.firstChild() != nil {
    newParent.attachRendererInternal(
      child: from.detachRendererInternal(renderer: from.firstChild()!), beforeChild: from)
  }
}

private func canDropAnonymousBlock(anonymousBlock: RenderBlockWrapper) -> Bool {
  if anonymousBlock.beingDestroyed() || anonymousBlock.continuation() != nil {
    return false
  }
  return true
}

private func canMergeContiguousAnonymousBlocks(
  rendererToBeRemoved: RenderObjectWrapper, previous: RenderObjectWrapper?,
  next: RenderObjectWrapper?, anonymousDestroyRoot: RenderObjectWrapper?
) -> Bool {
  assert(!rendererToBeRemoved.renderTreeBeingDestroyed())

  if rendererToBeRemoved.isInline() {
    return false
  }

  if previous != nil
    && (!previous!.isAnonymousBlock()
      || !canDropAnonymousBlock(anonymousBlock: previous as! RenderBlockWrapper))
  {
    return false
  }

  if next != nil
    && (!next!.isAnonymousBlock()
      || !canDropAnonymousBlock(anonymousBlock: next as! RenderBlockWrapper))
  {
    return false
  }

  let boxToBeRemoved = rendererToBeRemoved as? RenderBoxModelObjectWrapper
  if boxToBeRemoved == nil || boxToBeRemoved!.continuation() == nil {
    return true
  }

  // Let's merge pre and post anonymous block containers when the continuation triggering box (rendererToBeRemoved) is going away.
  return previous != nil && next != nil
    && CPtrToInt(previous?.p) != CPtrToInt(anonymousDestroyRoot?.p)
    && CPtrToInt(next?.p) != CPtrToInt(anonymousDestroyRoot?.p)
}

private func continuationBefore(parent: RenderBlockWrapper, beforeChild: RenderObjectWrapper?)
  -> RenderBlockWrapper?
{
  if beforeChild != nil && CPtrToInt(beforeChild!.parent()?.p) == CPtrToInt(parent.p) {
    return parent
  }

  var nextToLast: RenderBlockWrapper? = parent
  var last: RenderBlockWrapper? = parent
  var current = parent.continuation() as! RenderBlockWrapper?
  while current != nil {
    if beforeChild != nil && CPtrToInt(beforeChild!.parent()?.p) == CPtrToInt(current!.p) {
      if CPtrToInt(current!.firstChild()?.p) == CPtrToInt(beforeChild?.p) {
        return last
      }
      return current
    }

    nextToLast = last
    last = current
    current = current!.continuation() as! RenderBlockWrapper?
  }

  if beforeChild == nil && last!.firstChild() == nil {
    return nextToLast
  }
  return last
}

struct ParentAndBeforeChild {
  let parent: RenderElementWrapper?
  let beforeChild: RenderObjectWrapper?
}

private func findParentAndBeforeChildForNonSibling(
  parent: RenderBlockWrapper, child: RenderObjectWrapper, beforeChild: RenderObjectWrapper
) -> ParentAndBeforeChild? {
  var beforeChildContainer = beforeChild.parent()
  while CPtrToInt(beforeChildContainer!.parent()?.p) != CPtrToInt(parent.p) {
    beforeChildContainer = beforeChildContainer!.parent()
  }

  assert(beforeChildContainer != nil)
  if beforeChildContainer == nil || !beforeChildContainer!.isAnonymous() {
    return nil
  }

  if beforeChildContainer!.isInline() && child.isInline() {
    // The before child happens to be a block level box wrapped in an anonymous inline-block in an inline context (e.g. ruby).
    // Let's attach this new child before the anonymous inline-block wrapper.
    assert(beforeChildContainer!.isInlineBlockOrInlineTable())
    return ParentAndBeforeChild(parent: parent, beforeChild: beforeChildContainer)
  }
  assert(!beforeChildContainer!.isInline() || beforeChildContainer!.isRenderTable())

  // If the requested beforeChild is not one of our children, then this is because
  // there is an anonymous container within this object that contains the beforeChild.
  let beforeChildAnonymousContainer = beforeChildContainer!
  if beforeChildAnonymousContainer.isAnonymousBlock() {
    if mayUseBeforeChildContainerAsParent(
      beforeChildAnonymousContainer: beforeChildAnonymousContainer, child: child,
      beforeChild: beforeChild)
    {
      return ParentAndBeforeChild(parent: beforeChildAnonymousContainer, beforeChild: beforeChild)
    }
    return ParentAndBeforeChild(parent: parent, beforeChild: beforeChild.parent())
  }

  assert(beforeChildAnonymousContainer.isRenderTable())
  if child.isTablePart() {
    return ParentAndBeforeChild(parent: beforeChildAnonymousContainer, beforeChild: beforeChild)
  }

  // parent needs splitting.
  return ParentAndBeforeChild(parent: nil, beforeChild: nil)
}

private func mayUseBeforeChildContainerAsParent(
  beforeChildAnonymousContainer: RenderElementWrapper, child: RenderObjectWrapper,
  beforeChild: RenderObjectWrapper
) -> Bool {
  if child.isOutOfFlowPositioned()
    && isFlexOrGridItemContainer(beforeChildAnonymousContainer: beforeChildAnonymousContainer)
  {
    // Do not try to move an out-of-flow block box under an anonymous flex/grid item. It should stay a direct child of the flex/grid container.
    // https://www.w3.org/TR/css-flexbox-1/#abspos-items
    // As it is out-of-flow, an absolutely-positioned child of a flex container does not participate in flex layout.
    // The static position of an absolutely-positioned child of a flex container is determined such that the
    // child is positioned as if it were the sole flex item in the flex container,
    return false
  }
  return child.isInline()
    || CPtrToInt(beforeChildAnonymousContainer.firstChild()?.p) != CPtrToInt(beforeChild.p)
}

private func isFlexOrGridItemContainer(beforeChildAnonymousContainer: RenderElementWrapper) -> Bool
{
  if let renderBox = beforeChildAnonymousContainer as? RenderBoxWrapper {
    return renderBox.isFlexItemIncludingDeprecated() || renderBox.isGridItem()
  }
  return false
}

extension RenderTreeBuilder {
  class Block {
    init(builder: RenderTreeBuilder) {
      self.builder = builder
    }

    func attach(
      parent: RenderBlockWrapper, child: RenderObjectWrapper, beforeChild: RenderObjectWrapper?
    ) {
      if parent.continuation() != nil && !parent.isAnonymousBlock() {
        insertChildToContinuation(parent: parent, child: child, beforeChild: beforeChild)
      } else {
        attachIgnoringContinuation(parent: parent, child: child, beforeChild: beforeChild)
      }
    }

    func attachIgnoringContinuation(
      parent: RenderBlockWrapper, child: RenderObjectWrapper, beforeChild: RenderObjectWrapper?
    ) {
      let parentAndBeforeChildMayNeedAdjustment =
        beforeChild != nil && CPtrToInt(beforeChild!.parent()?.p) != CPtrToInt(parent.p)
      var beforeChild = beforeChild
      if parentAndBeforeChildMayNeedAdjustment {
        if let parentAndBeforeChild = findParentAndBeforeChildForNonSibling(
          parent: parent, child: child, beforeChild: beforeChild!)
        {
          if parentAndBeforeChild.parent != nil {
            builder.attach(
              parent: parentAndBeforeChild.parent!, child: child,
              beforeChild: parentAndBeforeChild.beforeChild)
            return
          }
          beforeChild = builder.splitAnonymousBoxesAroundChild(
            parent: parent, originalBeforeChild: beforeChild!)
          assert(CPtrToInt(beforeChild!.parent()?.p) == CPtrToInt(parent.p))
        }
      }

      if child.isFloatingOrOutOfFlowPositioned() {
        if parent.childrenInline() || parent is RenderFlexibleBoxWrapper || parent.isRenderGrid() {
          builder.attachToRenderElement(parent: parent, child: child, beforeChild: beforeChild)
          return
        }
        // In case of sibling block box(es), let's check if we can add this out of flow/floating box under a previous sibling anonymous block.
        let previousSibling =
          beforeChild != nil ? beforeChild!.previousSibling() : parent.lastChild()
        if previousSibling == nil || !previousSibling!.isAnonymousBlock() {
          builder.attachToRenderElement(parent: parent, child: child, beforeChild: beforeChild)
          return
        }
        builder.attach(parent: previousSibling as! RenderBlockWrapper, child: child)
        return
      }

      // Parent and inflow child match.
      if (parent.childrenInline() && child.isInline())
        || (!parent.childrenInline() && !child.isInline())
      {
        return builder.attachToRenderElement(parent: parent, child: child, beforeChild: beforeChild)
      }

      // Inline parent with block child.
      if parent.childrenInline() {
        assert(!child.isInline() && !child.isFloatingOrOutOfFlowPositioned())
        // A block has to either have all of its children inline, or all of its children as blocks.
        // So, if our children are currently inline and a block child has to be inserted, we move all our
        // inline children into anonymous block boxes.
        // This is a block with inline content. Wrap the inline content in anonymous blocks.
        builder.createAnonymousWrappersForInlineContent(parent: parent, insertionPoint: beforeChild)
        if beforeChild != nil && CPtrToInt(beforeChild!.parent()?.p) != CPtrToInt(parent.p) {
          beforeChild = beforeChild!.parent()
          assert(beforeChild!.isAnonymousBlock())
          assert(CPtrToInt(beforeChild!.parent()?.p) == CPtrToInt(parent.p))
        }
        builder.attachToRenderElement(parent: parent, child: child, beforeChild: beforeChild)

        if parent.parent() is RenderBlockWrapper && parent.isAnonymousBlock() {
          removeLeftoverAnonymousBlock(anonymousBlock: parent)
        }
        return
      }

      // Block parent with inline child.
      // If we're inserting an inline child but all of our children are blocks, then we have to make sure
      // it is put into an anomyous block box. We try to use an existing anonymous box if possible, otherwise
      // a new one is created and inserted into our list of children in the appropriate position.
      let previousSibling = beforeChild != nil ? beforeChild!.previousSibling() : parent.lastChild()
      if previousSibling != nil && previousSibling!.isAnonymousBlock() {
        builder.attach(parent: previousSibling as! RenderBlockWrapper, child: child)
        return
      }

      // No suitable existing anonymous box - create a new one.
      let box = parent.createAnonymousBlock()
      builder.attachToRenderElement(parent: parent, child: box, beforeChild: beforeChild)
      builder.attach(parent: box, child: child)
    }

    func detach(
      parent: RenderBlockWrapper, oldChild: RenderObjectWrapper,
      willBeDestroyed: RenderTreeBuilder.WillBeDestroyed,
      canCollapseAnonymousBlock: RenderTreeBuilder.CanCollapseAnonymousBlock = .Yes
    ) -> RenderObjectWrapper? {
      // No need to waste time in merging or removing empty anonymous blocks.
      // We can just bail out if our document is getting destroyed.
      if parent.renderTreeBeingDestroyed() {
        return builder.detachFromRenderElement(
          parent: parent, child: oldChild, willBeDestroyed: willBeDestroyed)
      }

      // If this child is a block, and if our previous and next siblings are both anonymous blocks
      // with inline content, then we can fold the inline content back together.
      var prev = oldChild.previousSibling()
      var next = oldChild.nextSibling()
      let canMergeAnonymousBlocks =
        canCollapseAnonymousBlock == .Yes
        && canMergeContiguousAnonymousBlocks(
          rendererToBeRemoved: oldChild, previous: prev, next: next,
          anonymousDestroyRoot: builder.anonymousDestroyRoot)

      let takenChild = builder.detachFromRenderElement(
        parent: parent, child: oldChild, willBeDestroyed: willBeDestroyed)

      if canMergeAnonymousBlocks && prev != nil && next != nil {
        prev!.setNeedsLayoutAndPrefWidthsRecalc()
        let nextBlock = next as! RenderBlockWrapper
        let prevBlock = prev as! RenderBlockWrapper

        if prev!.childrenInline() != next!.childrenInline() {
          let inlineChildrenBlock = prev!.childrenInline() ? prevBlock : nextBlock
          let blockChildrenBlock = prev!.childrenInline() ? nextBlock : prevBlock

          // Place the inline children block inside of the block children block instead of deleting it.
          // In order to reuse it, we have to reset it to just be a generic anonymous block. Make sure
          // to clear out inherited column properties by just making a new style, and to also clear the
          // column span flag if it is set.
          assert(inlineChildrenBlock.continuation() == nil)
          // Cache this value as it might get changed in setStyle() call.
          inlineChildrenBlock.setStyle(
            style: RenderStyleWrapper.createAnonymousStyleWithDisplay(
              parentStyle: parent.style(), display: .Block))
          let blockToMove = builder.detachFromRenderElement(
            parent: parent, child: inlineChildrenBlock, willBeDestroyed: .No)

          // Now just put the inlineChildrenBlock inside the blockChildrenBlock.
          let beforeChild =
            CPtrToInt(prev?.p) == CPtrToInt(inlineChildrenBlock.p)
            ? blockChildrenBlock.firstChild() : nil
          builder.attachToRenderElementInternal(
            parent: blockChildrenBlock, child: blockToMove, beforeChild: beforeChild)
          next!.setNeedsLayoutAndPrefWidthsRecalc()

          // inlineChildrenBlock got reparented to blockChildrenBlock, so it is no longer a child
          // of "this". we null out prev or next so that is not used later in the function.
          if CPtrToInt(inlineChildrenBlock.p) == CPtrToInt(prevBlock.p) {
            prev = nil
          } else {
            next = nil
          }
        } else {
          // Take all the children out of the |next| block and put them in
          // the |prev| block.
          builder.moveAllChildrenIncludingFloats(
            from: nextBlock, to: prevBlock, normalizeAfterInsertion: .No)

          // Delete the now-empty block's lines and nuke it.
          nextBlock.deleteLines()
          builder.destroy(renderer: nextBlock)
        }
      }

      if canCollapseAnonymousBlock == .Yes && parent.canDropAnonymousBlockChild() {
        let child = prev != nil ? prev : next
        if canMergeAnonymousBlocks && child != nil && child!.previousSibling() == nil
          && child!.nextSibling() == nil
        {
          // The removal has knocked us down to containing only a single anonymous box. We can pull the content right back up into our box.
          dropAnonymousBoxChild(parent: parent, child: child as! RenderBlockWrapper)
        } else if (prev != nil && prev!.isAnonymousBlock())
          || (next != nil && next!.isAnonymousBlock())
        {
          // It's possible that the removal has knocked us down to a single anonymous block with floating siblings.
          let anonBlock =
            ((prev != nil && prev!.isAnonymousBlock()) ? prev! : next!) as! RenderBlockWrapper
          if canDropAnonymousBlock(anonymousBlock: anonBlock) {
            var dropAnonymousBlock = true
            let children: RenderChildIteratorAdapter<RenderObjectWrapper> = childrenOfType(
              parent: parent)
            for sibling in children {
              if CPtrToInt(sibling.p) == CPtrToInt(anonBlock.p) {
                continue
              }
              if !sibling.isFloating() {
                dropAnonymousBlock = false
                break
              }
            }
            if dropAnonymousBlock {
              dropAnonymousBoxChild(parent: parent, child: anonBlock)
            }
          }
        }
      }

      if parent.firstChild() == nil {
        // If this was our last child be sure to clear out our line boxes.
        if parent.childrenInline() {
          parent.deleteLines()
        }
      }
      return takenChild
    }

    func detach(
      parent: RenderBlockFlowWrapper, child: RenderObjectWrapper,
      willBeDestroyed: RenderTreeBuilder.WillBeDestroyed,
      canCollapseAnonymousBlock: RenderTreeBuilder.CanCollapseAnonymousBlock = .Yes
    ) -> RenderObjectWrapper? {
      if !parent.renderTreeBeingDestroyed() {
        if let fragmentedFlow = parent.multiColumnFlowForBlockFlow(),
          CPtrToInt(fragmentedFlow.p) != CPtrToInt(child.p)
        {
          builder.multiColumnBuilder!.multiColumnRelativeWillBeRemoved(
            flow: fragmentedFlow, relative: child,
            canCollapseAnonymousBlock: canCollapseAnonymousBlock)
        }
      }
      return detach(
        parent: parent, oldChild: child, willBeDestroyed: willBeDestroyed,
        canCollapseAnonymousBlock: canCollapseAnonymousBlock)
    }

    func dropAnonymousBoxChild(parent: RenderBlockWrapper, child: RenderBlockWrapper) {
      parent.setNeedsLayoutAndPrefWidthsRecalc()
      parent.setChildrenInline(b: child.childrenInline())

      // FIXME: This should really just be a moveAllChilrenTo (see webkit.org/b/182495)
      moveAllChildrenToInternal(from: child, newParent: parent)
      let _ /*toBeDeleted*/ = builder.detachFromRenderElement(
        parent: parent, child: child, willBeDestroyed: .Yes)

      // Delete the now-empty block's lines and nuke it.
      child.deleteLines()
    }

    func childBecameNonInline(parent: RenderBlockWrapper, child: RenderElementWrapper) {
      builder.createAnonymousWrappersForInlineContent(parent: parent)
      if parent.isAnonymousBlock() && parent.parent() is RenderBlockWrapper {
        removeLeftoverAnonymousBlock(anonymousBlock: parent)
      }
      // parent may be dead here
    }

    private func insertChildToContinuation(
      parent: RenderBlockWrapper, child: RenderObjectWrapper, beforeChild: RenderObjectWrapper?
    ) {
      let flow = continuationBefore(parent: parent, beforeChild: beforeChild)
      assert(beforeChild == nil || beforeChild!.parent() is RenderBlockWrapper)
      var beforeChildParent: RenderBoxModelObjectWrapper? = nil
      if beforeChild != nil {
        beforeChildParent = (beforeChild!.parent() as! RenderBoxModelObjectWrapper)
      } else {
        if let continuation = flow!.continuation() {
          beforeChildParent = continuation
        } else {
          beforeChildParent = flow
        }
      }

      if child.isFloatingOrOutOfFlowPositioned() {
        builder.attachIgnoringContinuation(
          parent: beforeChildParent!, child: child, beforeChild: beforeChild)
        return
      }

      let childIsNormal = child.isInline() || child.style().columnSpan() == .None
      let bcpIsNormal =
        beforeChildParent!.isInline() || beforeChildParent!.style().columnSpan() == .None
      let flowIsNormal = flow!.isInline() || flow!.style().columnSpan() == .None

      if CPtrToInt(flow?.p) == CPtrToInt(beforeChildParent?.p) {
        builder.attachIgnoringContinuation(parent: flow!, child: child, beforeChild: beforeChild)
        return
      }

      // The goal here is to match up if we can, so that we can coalesce and create the
      // minimal # of continuations needed for the inline.
      if childIsNormal == bcpIsNormal {
        builder.attachIgnoringContinuation(
          parent: beforeChildParent!, child: child, beforeChild: beforeChild)
        return
      }
      if flowIsNormal == childIsNormal {
        builder.attachIgnoringContinuation(parent: flow!, child: child)  // Just treat like an append.
        return
      }
      builder.attachIgnoringContinuation(
        parent: beforeChildParent!, child: child, beforeChild: beforeChild)
    }

    private func removeLeftoverAnonymousBlock(anonymousBlock: RenderBlockWrapper) {
      assert(anonymousBlock.isAnonymousBlock())
      assert(!anonymousBlock.childrenInline())
      assert(anonymousBlock.parent() != nil)

      if anonymousBlock.continuation() != nil {
        return
      }

      let parent = anonymousBlock.parent()!
      if parent is RenderButtonWrapper || parent is RenderTextControlWrapper {
        return
      }

      builder.removeFloatingObjects(renderer: anonymousBlock)
      // FIXME: This should really just be a moveAllChilrenTo (see webkit.org/b/182495)
      moveAllChildrenToInternal(from: anonymousBlock, newParent: parent)
      let _ = builder.detachFromRenderElement(
        parent: parent, child: anonymousBlock, willBeDestroyed: .Yes)
      // anonymousBlock is dead here.
    }

    private let builder: RenderTreeBuilder
  }
}
