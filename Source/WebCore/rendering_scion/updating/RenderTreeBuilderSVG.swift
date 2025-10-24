/*
 * Copyright (C) 2018 Apple Inc. All rights reserved.
 * Copyright (C) 2024 Igalia S.L.
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
  class SVG {
    init(builder: RenderTreeBuilder) {
      self.builder = builder
    }

    func updateAfterDescendants(svgRoot: RenderSVGRootWrapper) {
      // Usually the anonymous RenderSVGViewportContainer, wrapping all children of RenderSVGRoot,
      // is created when the first <svg> child element is inserted into the render tree. We'll
      // only reach this point with viewportContainer=nullptr, if the <svg> had no children -- we
      // still need to ensure the creation of the RenderSVGViewportContainer, otherwise computing
      // e.g. getCTM() would ignore the presence of a 'viewBox' induced transform (and ignore zoom/pan).
      if svgRoot.viewportContainer() != nil {
        return
      }
      createViewportContainer(parent: svgRoot)
    }

    func attach(
      parent: LegacyRenderSVGRootWrapper, child: RenderObjectWrapper?,
      beforeChild: RenderObjectWrapper?
    ) {
      builder.attachToRenderElement(parent: parent, child: child!, beforeChild: beforeChild)
      SVGResourcesCache.clientWasAddedToTree(renderer: child!)
    }

    func attach(
      parent: LegacyRenderSVGContainer, child: RenderObjectWrapper?,
      beforeChild: RenderObjectWrapper?
    ) {
      builder.attachToRenderElement(parent: parent, child: child!, beforeChild: beforeChild)
      SVGResourcesCache.clientWasAddedToTree(renderer: child!)
    }

    func attach(
      parent: RenderSVGInlineWrapper, child: RenderObjectWrapper?,
      beforeChild: RenderObjectWrapper?
    ) {
      builder.inlineBuilder!.attach(parent: parent, child: child, beforeChild: beforeChild)

      if !child!.document().settings().layerBasedSVGEngineEnabled() {
        SVGResourcesCache.clientWasAddedToTree(renderer: child!)
      }

      if let textAncestor = RenderSVGTextWrapper.locateRenderSVGTextAncestor(start: parent) {
        textAncestor.subtreeChildWasAdded(child: child)
      }
    }

    func attach(
      parent: RenderSVGTextWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?
    ) {
      builder.blockFlowBuilder!.attach(parent: parent, child: child, beforeChild: beforeChild)

      if !child!.document().settings().layerBasedSVGEngineEnabled() {
        SVGResourcesCache.clientWasAddedToTree(renderer: child!)
      }

      parent.subtreeChildWasAdded(child: child)
    }

    func attach(
      parent: RenderSVGRootWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?
    ) {
      builder.attachToRenderElement(
        parent: findOrCreateParentForChild(parent: parent), child: child!, beforeChild: beforeChild)
    }

    func detach(
      parent: LegacyRenderSVGRootWrapper, child: RenderObjectWrapper,
      willBeDestroyed: RenderTreeBuilder.WillBeDestroyed
    ) -> RenderObjectWrapper? {
      SVGResourcesCache.clientWillBeRemovedFromTree(renderer: child)
      return builder.detachFromRenderElement(
        parent: parent, child: child, willBeDestroyed: willBeDestroyed)
    }

    func detach(
      parent: LegacyRenderSVGContainer, child: RenderObjectWrapper,
      willBeDestroyed: RenderTreeBuilder.WillBeDestroyed
    ) -> RenderObjectWrapper? {
      SVGResourcesCache.clientWillBeRemovedFromTree(renderer: child)
      return builder.detachFromRenderElement(
        parent: parent, child: child, willBeDestroyed: willBeDestroyed)
    }

    func detach(
      parent: RenderSVGInlineWrapper, child: RenderObjectWrapper,
      willBeDestroyed: RenderTreeBuilder.WillBeDestroyed
    ) -> RenderObjectWrapper? {
      if !child.document().settings().layerBasedSVGEngineEnabled() {
        SVGResourcesCache.clientWillBeRemovedFromTree(renderer: child)
      }

      let textAncestor = RenderSVGTextWrapper.locateRenderSVGTextAncestor(start: parent)
      if textAncestor == nil {
        return builder.detachFromRenderElement(
          parent: parent, child: child, willBeDestroyed: willBeDestroyed)
      }

      var affectedAttributes: [SVGTextLayoutAttributes] = []
      textAncestor!.subtreeChildWillBeRemoved(child: child, affectedAttributes: &affectedAttributes)
      let takenChild = builder.detachFromRenderElement(
        parent: parent, child: child, willBeDestroyed: willBeDestroyed)
      textAncestor!.subtreeChildWasRemoved(affectedAttributes: affectedAttributes)
      return takenChild
    }

    func detach(
      parent: RenderSVGTextWrapper, child: RenderObjectWrapper,
      willBeDestroyed: RenderTreeBuilder.WillBeDestroyed
    ) -> RenderObjectWrapper? {
      if !child.document().settings().layerBasedSVGEngineEnabled() {
        SVGResourcesCache.clientWillBeRemovedFromTree(renderer: child)
      }

      var affectedAttributes: [SVGTextLayoutAttributes] = []
      parent.subtreeChildWillBeRemoved(child: child, affectedAttributes: &affectedAttributes)
      let takenChild = builder.blockBuilder!.detach(
        parent: parent, child: child, willBeDestroyed: willBeDestroyed)
      parent.subtreeChildWasRemoved(affectedAttributes: affectedAttributes)
      return takenChild
    }

    private func findOrCreateParentForChild(parent: RenderSVGRootWrapper)
      -> RenderSVGViewportContainerWrapper
    {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    @discardableResult
    private func createViewportContainer(parent: RenderSVGRootWrapper)
      -> RenderSVGViewportContainerWrapper
    {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private let builder: RenderTreeBuilder
  }
}
