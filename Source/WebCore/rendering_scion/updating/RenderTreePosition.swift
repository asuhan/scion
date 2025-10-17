/*
 * Copyright (C) 2015 Apple Inc. All rights reserved.
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

class RenderTreePosition {
  init(parent: RenderElementWrapper) {
    self.parent = parent
  }

  func nextSibling() -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeNextSibling(node: NodeWrapper) {
    assert(node.renderer() == nil)
    if hasValidNextSibling {
      assertionLimitCounter += 1
      let skipAssert =
        parent.isRenderView() || assertionLimitCounter > RenderTreePosition.oNSquaredAvoidanceLimit
      assert(
        skipAssert || CPtrToInt(nextSiblingRenderer(node: node)?.p) == CPtrToInt(m_nextSibling?.p))
      return
    }
    m_nextSibling = nextSiblingRenderer(node: node)
    hasValidNextSibling = true
  }

  func invalidateNextSibling() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func invalidateNextSibling(siblingRenderer: RenderObjectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextSiblingRenderer(node: NodeWrapper) -> RenderObjectWrapper? {
    assert(node.renderer() == nil)

    let parentElement = parent.element()
    if parentElement == nil {
      return nil
    }
    // FIXME: PlugingReplacement shadow trees are very wrong.
    if CPtrToInt(parentElement?.p) == CPtrToInt(node.p) {
      return nil
    }

    var elementStack: [ElementWrapper] = []

    // In the common case ancestor == parentElement immediately and this just pushes parentElement into stack.
    var ancestor = node.parentElementInComposedTree()
    while true {
      elementStack.append(ancestor!)
      if ancestor?.p == parentElement?.p {
        break
      }
      ancestor = ancestor!.parentElementInComposedTree()
      assert(ancestor != nil)
    }
    elementStack.reverse()

    let composedDescendants = composedTreeDescendants(parent: parentElement!)

    let it = RenderTreePosition.initializeIteratorConsideringPseudoElements(
      node: node, parentElement: parentElement!, composedDescendants: composedDescendants,
      elementStack: &elementStack)

    while it != composedDescendants.end() {
      if let renderer = RenderTreePosition.popCheckingForAfterPseudoElementRenderers(
        iteratorDepthToMatch: it.depth(), elementStack: &elementStack)
      {
        return renderer
      }

      if let renderer = (*it).renderer() {
        return renderer
      }

      if let element = *it as? ElementWrapper {
        if element.hasDisplayContents() {
          if let renderer = RenderTreePosition.pushCheckingForAfterPseudoElementRenderer(
            element: element, elementStack: &elementStack)
          {
            return renderer
          }
          it.traverseNext()
          continue
        }
      }

      it.traverseNextSkippingChildren()
    }

    return RenderTreePosition.popCheckingForAfterPseudoElementRenderers(
      iteratorDepthToMatch: 0, elementStack: &elementStack)
  }

  private static func initializeIteratorConsideringPseudoElements(
    node: NodeWrapper, parentElement: ElementWrapper,
    composedDescendants: ComposedTreeDescendantAdapter, elementStack: inout [ElementWrapper]
  ) -> ComposedTreeIterator {
    if let pseudoElement = node as? PseudoElementWrapper {
      let host = pseudoElement.hostElement()
      if node.isBeforePseudoElement() {
        if CPtrToInt(host?.p) != CPtrToInt(parentElement.p) {
          return composedDescendants.at(child: host!).traverseNext()
        }
        return composedDescendants.begin()
      }
      assert(node.isAfterPseudoElement())
      elementStack.removeLast()
      if CPtrToInt(host?.p) != CPtrToInt(parentElement.p) {
        return composedDescendants.at(child: host!).traverseNextSkippingChildren()
      }
      return composedDescendants.end()
    }
    return composedDescendants.at(child: node).traverseNextSkippingChildren()
  }

  private static func pushCheckingForAfterPseudoElementRenderer(
    element: ElementWrapper, elementStack: inout [ElementWrapper]
  ) -> RenderElementWrapper? {
    assert(!element.isPseudoElement())
    if let before = element.beforePseudoElement() {
      if let renderer = before.containerRenderer() {
        return renderer
      }
    }
    elementStack.append(element)
    return nil
  }

  private static func popCheckingForAfterPseudoElementRenderers(
    iteratorDepthToMatch: UInt32, elementStack: inout [ElementWrapper]
  ) -> RenderElementWrapper? {
    while elementStack.count > iteratorDepthToMatch {
      let element = elementStack.popLast()!
      if let after = element.afterPseudoElement() {
        if let renderer = after.containerRenderer() {
          return renderer
        }
      }
    }
    return nil
  }

  let parent: RenderElementWrapper
  private var m_nextSibling: RenderObjectWrapper? = nil
  private var hasValidNextSibling = false
  private var assertionLimitCounter = 0
  private static let oNSquaredAvoidanceLimit = 20
}
