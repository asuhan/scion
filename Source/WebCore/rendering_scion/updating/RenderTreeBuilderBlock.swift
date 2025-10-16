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

private func canDropAnonymousBlock(anonymousBlock: RenderBlockWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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

extension RenderTreeBuilder {
  class Block {
    init(builder: RenderTreeBuilder) {
      self.builder = builder
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
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func dropAnonymousBoxChild(parent: RenderBlockWrapper, child: RenderBlockWrapper) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private let builder: RenderTreeBuilder
  }
}
