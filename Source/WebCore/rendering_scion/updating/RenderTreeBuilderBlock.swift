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

private func canMergeContiguousAnonymousBlocks(
  rendererToBeRemoved: RenderObjectWrapper, previous: RenderObjectWrapper?,
  next: RenderObjectWrapper?, anonymousDestroyRoot: RenderObjectWrapper?
) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
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
      let prev = oldChild.previousSibling()
      let next = oldChild.nextSibling()
      let canMergeAnonymousBlocks =
        canCollapseAnonymousBlock == .Yes
        && canMergeContiguousAnonymousBlocks(
          rendererToBeRemoved: oldChild, previous: prev, next: next,
          anonymousDestroyRoot: builder.anonymousDestroyRoot)

      let takenChild = builder.detachFromRenderElement(
        parent: parent, child: oldChild, willBeDestroyed: willBeDestroyed)

      if canMergeAnonymousBlocks && prev != nil && next != nil {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }

      if canCollapseAnonymousBlock == .Yes && parent.canDropAnonymousBlockChild() {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
      }

      if parent.firstChild() == nil {
        // TODO(asuhan): implement this
        fatalError("Not implemented")
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

    private let builder: RenderTreeBuilder
  }
}
