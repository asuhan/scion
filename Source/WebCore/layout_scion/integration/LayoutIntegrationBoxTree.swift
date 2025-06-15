/*
 * Copyright (C) 2020 Apple Inc. All rights reserved.
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

extension LayoutIntegration {
  struct BoxTree {
    init(rootRenderer: RenderBlockWrapper) {
      self.rootRenderer = rootRenderer
      var rootBox = self.rootRenderer.layoutBox()
      if rootBox == nil {
        rootBox = ElementBoxWrapper()
        rootBox!.p = wk_interop.BoxTree_handleNullRootBox(rootRenderer.p)
      }

      if rootRenderer is RenderBlockFlowWrapper {
        rootBox!.setIsInlineIntegrationRoot()
      }
      rootBox!.setIsFirstChildForIntegration(
        value: rootRenderer.parent() == nil
          || CPtrToInt(rootRenderer.parent()!.firstChild()?.p) == CPtrToInt(rootRenderer.p))

      if rootRenderer is RenderBlockFlowWrapper {
        buildTreeForInlineContent()
      } else if rootRenderer is RenderFlexibleBoxWrapper {
        buildTreeForFlexContent()
      } else {
        fatalError("Not implemented yet")
      }
    }

    func updateContent(textRenderer: RenderTextWrapper) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func insert(
      parent: RenderElementWrapper, child: RenderObjectWrapper, beforeChild: RenderObjectWrapper?
    ) -> BoxWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func remove(parent: RenderElementWrapper, child: RenderObjectWrapper) -> BoxWrapper {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func rootLayoutBox() -> ElementBoxWrapper {
      return rootRenderer.layoutBox()!
    }

    func contains(rendererToFind: RenderElementWrapper) -> Bool {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func buildTreeForInlineContent() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func buildTreeForFlexContent() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    var rootRenderer: RenderBlockWrapper
  }
}
