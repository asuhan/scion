/*
 * Copyright (C) 2016-2021 Apple Inc. All rights reserved.
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

private func shouldCreateRenderer(element: ElementWrapper, parentRenderer: RenderElementWrapper)
  -> Bool
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

class RenderTreeUpdater {
  init(document: Document) {
    self.document = document
    self.generatedContent = GeneratedContent(updater: self)
    self.viewTransition = ViewTransition(updater: self)
    self.builder = RenderTreeBuilder(view: renderView())
  }

  private func updateRenderTree(root: ContainerNodeWrapper) {
    assert(root.renderer() != nil)
    assert(parentStack.isEmpty)

    parentStack.append(Parent(root: root))

    let descendants = composedTreeDescendants(parent: root)
    let it = descendants.begin()
    let end = descendants.end()

    // FIXME: https://bugs.webkit.org/show_bug.cgi?id=156172
    it.dropAssertions()

    while it != end {
      popParentsToDepth(depth: it.depth())

      let node = *it

      if let renderer = node.renderer() {
        renderTreePosition().invalidateNextSibling(siblingRenderer: renderer)
      } else if let element = node as? ElementWrapper, element.hasDisplayContents() {
        renderTreePosition().invalidateNextSibling()
      }

      if let text = node as? TextWrapper {
        let textUpdate = styleUpdate!.textUpdate(text: text)
        let didCreateParent = parent().update != nil && parent().update!.change == .Renderer
        let mayNeedUpdateWhitespaceOnlyRenderer =
          renderingParent().didCreateOrDestroyChildRenderer && text.containsOnlyASCIIWhitespace()
        if didCreateParent || textUpdate != nil || mayNeedUpdateWhitespaceOnlyRenderer {
          updateTextRenderer(text: text, textUpdate: textUpdate, root: nil)
        }

        storePreviousRenderer(node: text)
        it.traverseNextSkippingChildren()
        continue
      }

      let element = node as! ElementWrapper

      let needsSVGRendererUpdate = element.needsSVGRendererUpdate()
      if needsSVGRendererUpdate {
        updateSVGRenderer(element: element)
      }

      let elementUpdate = styleUpdate!.elementUpdate(element: element)

      // We hop through display: contents elements in findRenderingRoot, so
      // there may be other updates down the tree.
      if elementUpdate == nil && !element.hasDisplayContents() && !needsSVGRendererUpdate {
        storePreviousRenderer(node: element)
        it.traverseNextSkippingChildren()
        continue
      }

      if elementUpdate != nil {
        updateElementRenderer(element: element, elementUpdate: elementUpdate!)
      }

      storePreviousRenderer(node: element)

      let mayHaveRenderedDescendants = mayHaveRenderedDescendants(element: element)

      if !mayHaveRenderedDescendants {
        it.traverseNextSkippingChildren()
        continue
      }

      pushParent(element: element, update: elementUpdate)

      it.traverseNext()
    }

    popParentsToDepth(depth: 0)
  }

  private func mayHaveRenderedDescendants(element: ElementWrapper) -> Bool {
    if element.renderer() != nil {
      return !(element.isInTopLayer() && element.renderer()!.isSkippedContent())
    }
    return element.hasDisplayContents()
      && shouldCreateRenderer(element: element, parentRenderer: renderTreePosition().parent)
  }

  private func updateTextRenderer(
    text: TextWrapper, textUpdate: Style.TextUpdate?, root: ContainerNodeWrapper? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateElementRenderer(element: ElementWrapper, elementUpdate: Style.ElementUpdate) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateSVGRenderer(element: ElementWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func storePreviousRenderer(node: NodeWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private struct Parent {
    let update: Style.ElementUpdate? = nil

    let didCreateOrDestroyChildRenderer = false

    init(root: ContainerNodeWrapper) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  private func parent() -> Parent { return parentStack.last! }

  private func renderingParent() -> Parent {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func renderTreePosition() -> RenderTreePosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func pushParent(element: ElementWrapper, update: Style.ElementUpdate?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func popParentsToDepth(depth: UInt32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func renderView() -> RenderViewWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let document: Document
  private let styleUpdate: Style.Update? = nil

  private var parentStack: [Parent] = []

  private var generatedContent: GeneratedContent? = nil
  private var viewTransition: ViewTransition? = nil

  private var builder: RenderTreeBuilder? = nil
}
