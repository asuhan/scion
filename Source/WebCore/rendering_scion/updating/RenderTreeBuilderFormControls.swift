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

extension RenderTreeBuilder {
  class FormControls {
    init(builder: RenderTreeBuilder) {
      self.builder = builder
    }

    func attach(
      parent: RenderButtonWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?
    ) {
      builder.blockBuilder!.attach(
        parent: findOrCreateParentForChild(parent: parent), child: child!, beforeChild: beforeChild)
    }

    func attach(
      parent: RenderMenuListWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?
    ) {
      builder.blockBuilder!.attach(
        parent: findOrCreateParentForChild(parent: parent), child: child!, beforeChild: beforeChild)
      parent.didAttachChild(child: child!)
    }

    func detach(
      parent: RenderButtonWrapper, child: RenderObjectWrapper,
      willBeDestroyed: RenderTreeBuilder.WillBeDestroyed
    ) -> RenderObjectWrapper? {
      let innerRenderer = parent.innerRenderer()
      if innerRenderer == nil || CPtrToInt(child.p) == CPtrToInt(innerRenderer!.p)
        || CPtrToInt(child.parent()?.p) == CPtrToInt(parent.p)
      {
        assert(CPtrToInt(child.p) == CPtrToInt(innerRenderer!.p) || innerRenderer == nil)
        return builder.blockBuilder!.detach(
          parent: parent, oldChild: child, willBeDestroyed: willBeDestroyed)
      }
      return builder.detach(parent: innerRenderer!, child: child, willBeDestroyed: willBeDestroyed)
    }

    func detach(
      parent: RenderMenuListWrapper, child: RenderObjectWrapper,
      willBeDestroyed: RenderTreeBuilder.WillBeDestroyed
    ) -> RenderObjectWrapper? {
      let innerRenderer = parent.innerRenderer()
      if innerRenderer == nil || CPtrToInt(child.p) == CPtrToInt(innerRenderer!.p) {
        return builder.blockBuilder!.detach(
          parent: parent, oldChild: child, willBeDestroyed: willBeDestroyed)
      }
      return builder.detach(parent: innerRenderer!, child: child, willBeDestroyed: willBeDestroyed)
    }

    private func findOrCreateParentForChild(parent: RenderButtonWrapper) -> RenderBlockWrapper {
      var innerRenderer = parent.innerRenderer()
      if innerRenderer != nil {
        return innerRenderer!
      }

      innerRenderer = parent.createAnonymousBlock(display: parent.style().display())
      builder.blockBuilder!.attach(parent: parent, child: innerRenderer!, beforeChild: nil)
      parent.setInnerRenderer(innerRenderer: innerRenderer!)
      return innerRenderer!
    }

    private func findOrCreateParentForChild(parent: RenderMenuListWrapper) -> RenderBlockWrapper {
      var innerRenderer = parent.innerRenderer()
      if innerRenderer != nil {
        return innerRenderer!
      }

      innerRenderer = parent.createAnonymousBlock()
      builder.blockBuilder!.attach(parent: parent, child: innerRenderer!, beforeChild: nil)
      parent.setInnerRenderer(innerRenderer: innerRenderer!)
      return innerRenderer!
    }

    private let builder: RenderTreeBuilder
  }
}
