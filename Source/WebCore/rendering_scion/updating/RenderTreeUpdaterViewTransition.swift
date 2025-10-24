/*
 * Copyright (C) 2024 Apple Inc. All rights reserved.
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

extension RenderTreeUpdater {
  class ViewTransition {
    init(updater: RenderTreeUpdater) {
      self.updater = updater
    }

    // The contents and ordering of the named elements map should remain stable during the duration of the transition.
    // We should only need to handle changes in the `display` CSS property by recreating / deleting renderers as needed.
    func updatePseudoElementTree(
      documentElementRenderer: RenderElementWrapper, minimalStyleDifference: StyleDifference
    ) {
      let document = documentElementRenderer.document()

      // Intentionally bail out early here to avoid computing the style.
      if !document.hasViewTransitionPseudoElementTree() || document.documentElement() == nil {
        destroyPseudoElementTreeIfNeeded(documentElementRenderer: documentElementRenderer)
        return
      }

      // Destroy pseudo element tree ::view-transition has display: none or no style.
      let rootStyle = documentElementRenderer.getCachedPseudoStyle(
        pseudoElementIdentifier: Style.PseudoElementIdentifier(pseudoId: .ViewTransition),
        parentStyle: documentElementRenderer.style())
      if rootStyle == nil || rootStyle!.display() == .None {
        destroyPseudoElementTreeIfNeeded(documentElementRenderer: documentElementRenderer)
        return
      }

      let activeViewTransition = document.activeViewTransition()
      assert(activeViewTransition != nil)

      let newRootStyle = RenderStyleWrapper.clone(style: rootStyle!)

      // Create ::view-transition as needed.
      if let viewTransitionRoot = documentElementRenderer.view().viewTransitionRoot() {
        viewTransitionRoot.setStyle(
          style: newRootStyle, minimalStyleDifference: minimalStyleDifference)
      } else {
        let newViewTransitionRoot = CreateRenderer.RenderBlockFlow(
          type: .BlockFlow, document: documentElementRenderer.document(), style: newRootStyle,
          flags: .IsViewTransitionContainer)
        newViewTransitionRoot.initializeStyle()
        documentElementRenderer.view().setViewTransitionRoot(renderer: newViewTransitionRoot)
        updater.builder!.attach(
          parent: documentElementRenderer.parent()!, child: newViewTransitionRoot)
      }

      // No groups. The map is constant during the duration of the transition, so we don't need to handle deletions.
      if activeViewTransition!.namedElements().isEmpty() {
        return
      }

      // Traverse named elements map to update/build all ::view-transition-group().
      var descendantsToDelete: [WeakNullableRef<RenderObjectWrapper>] = []
      var currentGroup = documentElementRenderer.view().viewTransitionRoot()!.firstChild()
      for name in activeViewTransition!.namedElements().keys() {
        assert(
          currentGroup == nil || currentGroup!.style().pseudoElementType() == .ViewTransitionGroup)
        if currentGroup != nil && name == currentGroup!.style().pseudoElementNameArgument() {
          let style = documentElementRenderer.getCachedPseudoStyle(
            pseudoElementIdentifier: Style.PseudoElementIdentifier(
              pseudoId: .ViewTransitionGroup, nameArgument: name),
            parentStyle: documentElementRenderer.style())
          if style == nil || style!.display() == .None {
            descendantsToDelete.append(WeakNullableRef(currentGroup))
          } else {
            updatePseudoElementGroup(
              groupStyle: style!, group: currentGroup as! RenderElementWrapper,
              documentElementRenderer: documentElementRenderer,
              minimalStyleDifference: minimalStyleDifference)
          }
          currentGroup = currentGroup!.nextSibling()
        } else {
          buildPseudoElementGroup(
            name: name, documentElementRenderer: documentElementRenderer, beforeChild: currentGroup)
        }
      }

      for descendant in descendantsToDelete {
        if descendant.bool() {
          updater.builder!.destroy(renderer: *descendant)
        }
      }
    }

    private func destroyPseudoElementTreeIfNeeded(documentElementRenderer: RenderElementWrapper) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func buildPseudoElementGroup(
      name: AtomStringWrapper, documentElementRenderer: RenderElementWrapper,
      beforeChild: RenderObjectWrapper? = nil
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func updatePseudoElementGroup(
      groupStyle: RenderStyleWrapper, group: RenderElementWrapper,
      documentElementRenderer: RenderElementWrapper, minimalStyleDifference: StyleDifference
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private let updater: RenderTreeUpdater
  }
}
