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
  if !parentRenderer.canHaveChildren()
    && !(element.isPseudoElement() && parentRenderer.canHaveGeneratedChildren())
  {
    return false
  }
  if parentRenderer.element() != nil
    && !parentRenderer.element()!.childShouldCreateRenderer(child: element)
  {
    return false
  }
  return true
}

private func pseudoStyleCacheIsInvalid(
  renderer: RenderElementWrapper, newStyle: RenderStyleWrapper?
)
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
    var existingRenderer = text.renderer()
    let needsRenderer = textRendererIsNeeded(textNode: text)

    if existingRenderer != nil && textUpdate != nil
      && textUpdate!.inheritedDisplayContentsStyle != nil
    {
      if existingRenderer!.inlineWrapperForDisplayContents() != nil
        || textUpdate!.inheritedDisplayContentsStyle! != nil
      {
        // FIXME: We could update without teardown.
        RenderTreeUpdater.tearDownTextRenderer(text: text, root: root, builder: builder!)
        existingRenderer = nil
      }
    }

    if existingRenderer != nil {
      if needsRenderer {
        if let textUpdate = textUpdate {
          existingRenderer!.setTextWithOffset(
            newText: text.data(), offset: textUpdate.offset, force: textUpdate.length != 0)
        }
        return
      }
      RenderTreeUpdater.tearDownTextRenderer(text: text, root: root, builder: builder!)
      renderingParent().didCreateOrDestroyChildRenderer = true
      return
    }
    if !needsRenderer {
      return
    }
    createTextRenderer(textNode: text, textUpdate: textUpdate)
    renderingParent().didCreateOrDestroyChildRenderer = true
  }

  private func createTextRenderer(textNode: TextWrapper, textUpdate: Style.TextUpdate?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateElementRenderer(element: ElementWrapper, elementUpdate: Style.ElementUpdate) {
    if elementUpdate.style == nil {
      return
    }

    let elementUpdateStyle = RenderStyleWrapper.cloneIncludingPseudoElements(
      style: elementUpdate.style!)

    let shouldTearDownRenderers = RenderTreeUpdater.shouldTearDownRenderers(
      element: element, elementUpdate: elementUpdate)

    if shouldTearDownRenderers {
      if element.renderer() == nil {
        // We may be tearing down a descendant renderer cached in renderTreePosition.
        renderTreePosition().invalidateNextSibling()
      }

      // display:none cancels animations.
      let teardownType = RenderTreeUpdater.teardownType(elementUpdate: elementUpdate)

      RenderTreeUpdater.tearDownRenderers(
        root: element, teardownType: teardownType, builder: builder!)

      renderingParent().didCreateOrDestroyChildRenderer = true
    }

    let hasDisplayContents = elementUpdate.style!.display() == .Contents
    let hasDisplayNonePreventingRendererCreation =
      elementUpdate.style!.display() == .None
      && !element.rendererIsNeeded(style: elementUpdateStyle)
    let hasDisplayContentsOrNone = hasDisplayContents || hasDisplayNonePreventingRendererCreation
    if hasDisplayContentsOrNone {
      element.storeDisplayContentsOrNoneStyle(style: elementUpdateStyle)
    } else {
      element.clearDisplayContentsOrNoneStyle()
    }

    if !hasDisplayContentsOrNone {
      if !elementUpdateStyle.containIntrinsicLogicalWidthHasAuto() {
        element.clearLastRememberedLogicalWidth()
      }
      if !elementUpdateStyle.containIntrinsicLogicalHeightHasAuto() {
        element.clearLastRememberedLogicalHeight()
      }
    }

    defer {
      if !hasDisplayContentsOrNone {
        if let box = element.renderBox(),
          box.style().hasAutoLengthContainIntrinsicSize() && !box.isSkippedContentRoot()
        {
          document.observeForContainIntrinsicSize(element: element)
        } else {
          document.unobserveForContainIntrinsicSize(element: element)
        }
      }
    }

    let shouldCreateNewRenderer =
      element.renderer() == nil && !hasDisplayContentsOrNone
      && !(element.isInTopLayer() && renderTreePosition().parent.style().hasSkippedContent())
    if shouldCreateNewRenderer {
      if element.hasCustomStyleResolveCallbacks() {
        element.willAttachRenderers()
      }
      createRenderer(element: element, style: elementUpdateStyle)

      renderingParent().didCreateOrDestroyChildRenderer = true
      return
    }

    if element.containerRenderer() == nil {
      return
    }
    let renderer = element.containerRenderer()!

    if elementUpdate.recompositeLayer {
      updateRendererStyle(
        renderer: renderer, newStyle: elementUpdateStyle, minimalStyleDifference: .RecompositeLayer)
      return
    }

    if elementUpdate.change == .None {
      if pseudoStyleCacheIsInvalid(renderer: renderer, newStyle: elementUpdateStyle) {
        updateRendererStyle(
          renderer: renderer, newStyle: elementUpdateStyle, minimalStyleDifference: .Equal)
        return
      }
      return
    }

    updateRendererStyle(
      renderer: renderer, newStyle: elementUpdateStyle, minimalStyleDifference: .Equal)
  }

  private static func teardownType(elementUpdate: Style.ElementUpdate) -> TeardownType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private static func shouldTearDownRenderers(
    element: ElementWrapper, elementUpdate: Style.ElementUpdate
  ) -> Bool {
    if element.isInTopLayer() && elementUpdate.change == .Inherited
      && elementUpdate.style!.hasSkippedContent()
    {
      return true
    }
    return elementUpdate.change == .Renderer
      && (element.renderer() != nil || element.hasDisplayContents())
  }

  private func updateSVGRenderer(element: ElementWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateRendererStyle(
    renderer: RenderElementWrapper, newStyle: RenderStyleWrapper,
    minimalStyleDifference: StyleDifference
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func createRenderer(element: ElementWrapper, style: RenderStyleWrapper) {
    if !shouldCreateRenderer(element: element, parentRenderer: renderTreePosition().parent) {
      return
    }

    if !element.rendererIsNeeded(style: style) {
      return
    }

    renderTreePosition().computeNextSibling(node: element)
    let insertionPosition = renderTreePosition()
    let newRenderer = element.createElementRenderer(
      style: style, insertionPosition: insertionPosition)
    if newRenderer == nil {
      return
    }

    if !insertionPosition.parent.isChildAllowed(child: newRenderer!, style: newRenderer!.style()) {
      return
    }

    element.setRenderer(renderer: newRenderer)

    newRenderer!.initializeStyle()

    builder!.attach(
      parent: insertionPosition.parent, child: newRenderer,
      beforeChild: insertionPosition.nextSibling())

    if let textManipulationController = document.textManipulationControllerIfExists() {
      textManipulationController.didAddOrCreateRendererForNode(node: element)
    }

    if let cache = document.axObjectCache() {
      cache.onRendererCreated(element: element)
    }
  }

  private func updateBeforeDescendants(element: ElementWrapper, update: Style.ElementUpdate?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateAfterDescendants(element: ElementWrapper, update: Style.ElementUpdate?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func textRendererIsNeeded(textNode: TextWrapper) -> Bool {
    let renderingParent = renderingParent()
    let parentRenderer = renderingParent.renderTreePosition!.parent
    if !parentRenderer.canHaveChildren() {
      return false
    }
    if parentRenderer.element() != nil
      && !parentRenderer.element()!.childShouldCreateRenderer(child: textNode)
    {
      return false
    }
    if textNode.isEditingText() {
      return true
    }
    if textNode.length() == 0 {
      return false
    }
    if !textNode.containsOnlyASCIIWhitespace() {
      return true
    }
    if renderingParent.previousChildRenderer is RenderTextWrapper {
      return true
    }
    // This text node has nothing but white space. We may still need a renderer in some cases.
    if parentRenderer.isRenderTable() || parentRenderer.isRenderTableRow()
      || parentRenderer.isRenderTableSection() || parentRenderer.isRenderTableCol()
      || parentRenderer.isRenderFrameSet() || parentRenderer.isRenderGrid()
      || (parentRenderer.isRenderFlexibleBox() && !parentRenderer.isRenderButton())
    {
      return false
    }
    if parentRenderer.style().preserveNewline() {  // pre/pre-wrap/pre-line always make renderers.
      return true
    }

    let previousRenderer = renderingParent.previousChildRenderer
    if previousRenderer != nil && previousRenderer!.isBR() {  // <span><br/> <br/></span>
      return false
    }

    if parentRenderer.isRenderInline() {
      // <span><div/> <div/></span>
      if previousRenderer != nil && !previousRenderer!.isInline()
        && !previousRenderer!.isOutOfFlowPositioned()
      {
        return false
      }

      return true
    }

    if parentRenderer.isRenderBlock() && !parentRenderer.childrenInline()
      && (previousRenderer == nil || !previousRenderer!.isInline())
    {
      return false
    }

    return renderingParent.hasPrecedingInFlowChild
  }

  private func storePreviousRenderer(node: NodeWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private class Parent {
    let element: ElementWrapper? = nil
    let update: Style.ElementUpdate? = nil
    let renderTreePosition: RenderTreePosition? = nil

    var didCreateOrDestroyChildRenderer = false
    var previousChildRenderer: RenderObjectWrapper? = nil
    let hasPrecedingInFlowChild = false

    init(root: ContainerNodeWrapper) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    init(element: ElementWrapper, update: Style.ElementUpdate?) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  private func parent() -> Parent { return parentStack.last! }

  private func renderingParent() -> Parent {
    for parent in parentStack.reversed() {
      if parent.renderTreePosition != nil {
        return parent
      }
    }
    fatalError("Not reached")
  }

  private func renderTreePosition() -> RenderTreePosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func pushParent(element: ElementWrapper, update: Style.ElementUpdate?) {
    parentStack.append(Parent(element: element, update: update))

    updateBeforeDescendants(element: element, update: update)
  }

  private func popParent() {
    let parent = parentStack.last!
    if parent.element != nil {
      updateAfterDescendants(element: parent.element!, update: parent.update)
    }

    if ObjectIdentifier(parent) != ObjectIdentifier(renderingParent()) {
      renderTreePosition().invalidateNextSibling()
    }

    parentStack.removeLast()
  }

  private func popParentsToDepth(depth: UInt32) {
    assert(parentStack.count >= depth)

    while parentStack.count > depth {
      popParent()
    }
  }

  // FIXME: Use OptionSet.
  private enum TeardownType {
    case Full
    case FullAfterSlotOrShadowRootChange
    case RendererUpdate
    case RendererUpdateCancelingAnimations
  }

  private static func tearDownRenderers(
    root: ElementWrapper, teardownType: TeardownType, builder: RenderTreeBuilder
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private enum NeedsRepaintAndLayout {
    case No
    case Yes
  }

  private static func tearDownTextRenderer(
    text: TextWrapper, root: ContainerNodeWrapper?, builder: RenderTreeBuilder,
    needsRepaintAndLayout: NeedsRepaintAndLayout = .Yes
  ) {
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
