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

private func createRendererIfNeeded(
  documentElementRenderer: RenderElementWrapper, name: AtomStringWrapper, pseudoId: PseudoId
) -> RenderBoxWrapper? {
  let documentElementStyle = documentElementRenderer.style()
  let style = documentElementRenderer.getCachedPseudoStyle(
    pseudoElementIdentifier: Style.PseudoElementIdentifier(pseudoId: pseudoId, nameArgument: name),
    parentStyle: documentElementStyle)
  if style == nil || style!.display() == .None {
    return nil
  }

  let document = documentElementRenderer.document()
  var renderer: RenderBoxWrapper? = nil
  if pseudoId == .ViewTransitionOld || pseudoId == .ViewTransitionNew {
    let capturedElement = document.activeViewTransition()!.namedElements().find(key: name)
    assert(capturedElement != nil)
    if pseudoId == .ViewTransitionOld && capturedElement!.oldImage == nil {
      return nil
    }
    if pseudoId == .ViewTransitionNew && !capturedElement!.newElement.bool() {
      return nil
    }

    let rendererViewTransition = CreateRenderer.RenderViewTransitionCapture(
      type: .ViewTransitionCapture, document: document,
      style: RenderStyleWrapper.clone(style: style!))
    if pseudoId == .ViewTransitionOld {
      rendererViewTransition.setImage(oldImage: capturedElement!.oldImage ?? nil)
    }
    rendererViewTransition.setCapturedSize(
      size: capturedElement!.oldSize, overflowRect: capturedElement!.oldOverflowRect,
      layerToLayoutOffset: capturedElement!.oldLayerToLayoutOffset)
    renderer = rendererViewTransition
  } else {
    renderer = CreateRenderer.RenderBlockFlow(
      type: .BlockFlow, document: document, style: RenderStyleWrapper.clone(style: style!),
      flags: .IsViewTransitionContainer)
  }

  renderer!.initializeStyle()
  return renderer
}

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
      if let viewTransitionRoot = documentElementRenderer.view().viewTransitionRoot() {
        updater.builder!.destroy(renderer: viewTransitionRoot)
      }
    }

    private func buildPseudoElementGroup(
      name: AtomStringWrapper, documentElementRenderer: RenderElementWrapper,
      beforeChild: RenderObjectWrapper? = nil
    ) {
      let viewTransitionGroup = createRendererIfNeeded(
        documentElementRenderer: documentElementRenderer, name: name, pseudoId: .ViewTransitionGroup
      )
      let viewTransitionImagePair =
        viewTransitionGroup != nil
        ? createRendererIfNeeded(
          documentElementRenderer: documentElementRenderer, name: name,
          pseudoId: .ViewTransitionImagePair) : nil
      let viewTransitionOld =
        viewTransitionImagePair != nil
        ? createRendererIfNeeded(
          documentElementRenderer: documentElementRenderer, name: name, pseudoId: .ViewTransitionOld
        ) : nil
      let viewTransitionNew =
        viewTransitionImagePair != nil
        ? createRendererIfNeeded(
          documentElementRenderer: documentElementRenderer, name: name, pseudoId: .ViewTransitionNew
        ) : nil

      if viewTransitionOld != nil {
        updater.builder!.attach(parent: viewTransitionImagePair!, child: viewTransitionOld!)
      }

      if viewTransitionNew != nil {
        updater.builder!.attach(parent: viewTransitionImagePair!, child: viewTransitionNew!)
      }

      if viewTransitionImagePair != nil {
        updater.builder!.attach(parent: viewTransitionGroup!, child: viewTransitionImagePair!)
      }

      if viewTransitionGroup != nil {
        updater.builder!.attach(
          parent: documentElementRenderer.view().viewTransitionRoot()!, child: viewTransitionGroup!,
          beforeChild: beforeChild)
      }
    }

    private func updatePseudoElementGroup(
      groupStyle: RenderStyleWrapper, group: RenderElementWrapper,
      documentElementRenderer: RenderElementWrapper, minimalStyleDifference: StyleDifference
    ) {
      let name = groupStyle.pseudoElementNameArgument()

      let newGroupStyle = RenderStyleWrapper.clone(style: groupStyle)
      group.setStyle(style: newGroupStyle, minimalStyleDifference: minimalStyleDifference)

      // Create / remove ::view-transtion-image-pair itself.
      var imagePair = group.firstChild() as! RenderElementWrapper?
      if imagePair != nil {
        assert(imagePair!.style().pseudoElementType() == .ViewTransitionImagePair)
        let shouldDeleteRenderer = ViewTransition.updateRenderer(
          renderer: imagePair!, documentElementRenderer: documentElementRenderer, name: name,
          minimalStyleDifference: minimalStyleDifference)
        if shouldDeleteRenderer == .Yes {
          updater.builder!.destroy(renderer: imagePair!)
          return
        }
      } else if let newImagePair = createRendererIfNeeded(
        documentElementRenderer: documentElementRenderer, name: name,
        pseudoId: .ViewTransitionImagePair)
      {
        imagePair = newImagePair
        updater.builder!.attach(parent: group, child: newImagePair)
      } else {
        return
      }

      let imagePairFirstChild = imagePair!.firstChild()
      // Build the ::view-transition-image-pair children if needed.
      if imagePairFirstChild == nil {
        if let viewTransitionOld = createRendererIfNeeded(
          documentElementRenderer: documentElementRenderer, name: name, pseudoId: .ViewTransitionOld
        ) {
          updater.builder!.attach(parent: imagePair!, child: viewTransitionOld)
        }
        if let viewTransitionNew = createRendererIfNeeded(
          documentElementRenderer: documentElementRenderer, name: name, pseudoId: .ViewTransitionNew
        ) {
          updater.builder!.attach(parent: imagePair!, child: viewTransitionNew)
        }
        return
      }

      // Update pre-existing ::view-transition-image-pair children.
      var shouldDeleteViewTransitionOld: ShouldDeleteRenderer = .No

      var viewTransitionOld: RenderObjectWrapper? = nil
      var viewTransitionNew: RenderObjectWrapper? = nil

      var newViewTransitionOld: RenderBoxWrapper? = nil
      var newViewTransitionNew: RenderBoxWrapper? = nil
      if imagePairFirstChild!.style().pseudoElementType() == .ViewTransitionOld {
        viewTransitionOld = imagePairFirstChild
        shouldDeleteViewTransitionOld = ViewTransition.updateRenderer(
          renderer: viewTransitionOld!, documentElementRenderer: documentElementRenderer,
          name: name, minimalStyleDifference: minimalStyleDifference
        )
        viewTransitionNew = viewTransitionOld!.nextSibling()
        assert(
          viewTransitionNew == nil
            || viewTransitionNew!.style().pseudoElementType() == .ViewTransitionNew)
      } else {
        assert(imagePairFirstChild!.style().pseudoElementType() == .ViewTransitionNew)
        viewTransitionNew = imagePairFirstChild
        newViewTransitionOld = createRendererIfNeeded(
          documentElementRenderer: documentElementRenderer, name: name, pseudoId: .ViewTransitionOld
        )
      }

      var shouldDeleteViewTransitionNew: ShouldDeleteRenderer = .No
      if viewTransitionNew == nil {
        newViewTransitionNew = createRendererIfNeeded(
          documentElementRenderer: documentElementRenderer, name: name, pseudoId: .ViewTransitionNew
        )
      } else {
        shouldDeleteViewTransitionNew = ViewTransition.updateRenderer(
          renderer: viewTransitionNew!, documentElementRenderer: documentElementRenderer,
          name: name, minimalStyleDifference: minimalStyleDifference
        )
      }

      if shouldDeleteViewTransitionNew == .Yes {
        updater.builder!.destroy(renderer: viewTransitionNew!)
      } else if newViewTransitionNew != nil {
        updater.builder!.attach(parent: imagePair!, child: newViewTransitionNew!)
      }

      if shouldDeleteViewTransitionOld == .Yes {
        updater.builder!.destroy(renderer: viewTransitionOld!)
      } else if newViewTransitionOld != nil {
        updater.builder!.attach(
          parent: imagePair!, child: newViewTransitionOld!, beforeChild: viewTransitionNew)
      }
    }

    private enum ShouldDeleteRenderer {
      case No
      case Yes
    }

    private static func updateRenderer(
      renderer: RenderObjectWrapper, documentElementRenderer: RenderElementWrapper,
      name: AtomStringWrapper, minimalStyleDifference: StyleDifference
    ) -> ShouldDeleteRenderer {
      let documentElementStyle = documentElementRenderer.style()
      let style = documentElementRenderer.getCachedPseudoStyle(
        pseudoElementIdentifier: Style.PseudoElementIdentifier(
          pseudoId: renderer.style().pseudoElementType(), nameArgument: name),
        parentStyle: documentElementStyle)
      if style == nil || style!.display() == .None {
        return .Yes
      }

      let newStyle = RenderStyleWrapper.clone(style: style!)
      (renderer as! RenderElementWrapper).setStyle(
        style: newStyle, minimalStyleDifference: minimalStyleDifference)
      return .No
    }

    private let updater: RenderTreeUpdater
  }
}
