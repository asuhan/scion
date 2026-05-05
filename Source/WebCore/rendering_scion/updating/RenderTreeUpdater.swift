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
  let currentStyle = renderer.style()

  let pseudoStyleCache = currentStyle.cachedPseudoStyles()
  if pseudoStyleCache == nil {
    return false
  }

  for cache in pseudoStyleCache!.styles {
    let pseudoElementIdentifier = Style.PseudoElementIdentifier(
      pseudoId: cache.pseudoElementType(), nameArgument: cache.pseudoElementNameArgument())
    if let newPseudoStyle = renderer.getUncachedPseudoStyle(
      pseudoElementRequest: Style.PseudoElementRequest(
        pseudoElementIdentifier: pseudoElementIdentifier),
      parentStyle: newStyle, ownStyle: newStyle)
    {
      if newPseudoStyle != cache {
        newStyle!.addCachedPseudoStyle(pseudo: newPseudoStyle)
        return true
      }
    } else {
      return true
    }
  }
  return false
}

enum DidRepaintAndMarkContainingBlock {
  case Yes
  case No
}

private func repaintAndMarkContainingBlockDirtyBeforeTearDown(
  root: ElementWrapper, composedTreeDescendantsIterator: ComposedTreeDescendantAdapter
) -> DidRepaintAndMarkContainingBlock? {
  let destroyRootRenderer = root.containerRenderer()
  if destroyRootRenderer != nil && destroyRootRenderer!.renderTreeBeingDestroyed() {
    return nil
  }

  if destroyRootRenderer != nil {
    repaintRoot(renderer: destroyRootRenderer!)
    repaintBackdropIfApplicable(renderer: destroyRootRenderer!)
    markContainingBlockDirty(renderer: destroyRootRenderer!)
  }

  let it = composedTreeDescendantsIterator.begin()
  while it != composedTreeDescendantsIterator.end() {
    let element = *it as? ElementWrapper
    if element == nil || element!.containerRenderer() == nil {
      ++it
      continue
    }
    let renderer = element!.containerRenderer()!
    if shouldRepaint(renderer: renderer, destroyRootRenderer: destroyRootRenderer) {
      renderer.repaint()
    }
    repaintBackdropIfApplicable(renderer: renderer)
    if renderer.isOutOfFlowPositioned() {
      // FIXME: Ideally we would check if containing block is the destory root or a descendent of the destroy root.
      markContainingBlockDirty(renderer: renderer)
    }
    ++it
  }
  return destroyRootRenderer != nil ? .Yes : .No
}

private func markContainingBlockDirty(renderer: RenderElementWrapper) {
  if let container = renderer.container() {
    if !renderer.isOutOfFlowPositioned() {
      container.setChildNeedsLayout()
      container.setPreferredLogicalWidthsDirty(shouldBeDirty: true)
      return
    }
    container.setNeedsSimplifiedNormalFlowLayout()
  } else {
    fatalError("Not reached")
  }
}

private func repaintBackdropIfApplicable(renderer: RenderElementWrapper) {
  if let backdropRenderer = renderer.backdropRenderer() {
    backdropRenderer.repaint(forceRepaint: .Yes)
  }
}

private func repaintRoot(renderer: RenderElementWrapper) {
  if renderer.isBody() {
    renderer.view().repaintRootContents()
    return
  }
  // When repaint is propagated to our layer, we have to force it here on destroy as this layer will no be around to issue it _affter_ layout.
  let rendererLayerObject = renderer as? RenderLayerModelObjectWrapper
  if rendererLayerObject == nil || rendererLayerObject!.layer() == nil
    || !rendererLayerObject!.layer()!.needsFullRepaint()
  {
    renderer.repaint()
    return
  }
  renderer.repaint(forceRepaint: .Yes)
}

private func shouldRepaint(
  renderer: RenderElementWrapper, destroyRootRenderer: RenderElementWrapper?
) -> Bool {
  if !renderer.everHadLayout() {
    return false
  }
  if renderer.isOutOfFlowPositioned() {
    return true
  }
  if renderer.isFloating() || renderer.isPositioned() {
    return destroyRootRenderer == nil || !destroyRootRenderer!.hasNonVisibleOverflow()
  }
  return false
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
    assert(textNode.renderer() == nil)

    let renderTreePosition = self.renderTreePosition()
    let textRenderer = textNode.createTextRenderer(style: renderTreePosition.parent.style())

    renderTreePosition.computeNextSibling(node: textNode)

    if !renderTreePosition.parent.isChildAllowed(textRenderer!, renderTreePosition.parent.style()) {
      return
    }

    textNode.setRenderer(renderer: textRenderer)

    if textUpdate != nil && textUpdate!.inheritedDisplayContentsStyle != nil
      && textUpdate!.inheritedDisplayContentsStyle! != nil
    {
      // Wrap text renderer into anonymous inline so we can give it a style.
      // This is to support "<div style='display:contents;color:green'>text</div>" type cases
      let displayContentsAnonymousWrapper = CreateRenderer.RenderInline(
        type: .Inline, document: textNode.document(),
        style: RenderStyleWrapper.clone(style: textUpdate!.inheritedDisplayContentsStyle!!))
      displayContentsAnonymousWrapper.initializeStyle()
      builder!.attach(parent: renderTreePosition.parent, child: displayContentsAnonymousWrapper)

      textRenderer!.setInlineWrapperForDisplayContents(wrapper: displayContentsAnonymousWrapper)
      builder!.attach(parent: displayContentsAnonymousWrapper, child: textRenderer!)
      return
    }

    builder!.attach(
      parent: renderTreePosition.parent, child: textRenderer!,
      beforeChild: renderTreePosition.nextSibling())

    if let textManipulationController = document.textManipulationControllerIfExists() {
      textManipulationController.didAddOrCreateRendererForNode(node: textNode)
    }
  }

  func updateElementRenderer(element: ElementWrapper, elementUpdate: Style.ElementUpdate) {
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
    if !elementUpdate.style!.hasDisplayAffectedByAnimations()
      && elementUpdate.style!.display() == .None
    {
      return .RendererUpdateCancelingAnimations
    }
    return .RendererUpdate
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
    assert(element.needsSVGRendererUpdate())
    element.setNeedsSVGRendererUpdate(flag: false)

    let renderer = element.renderer()
    if renderer == nil {
      return
    }

    if element.document().settings().layerBasedSVGEngineEnabled() {
      renderer!.setNeedsLayout()
      return
    }

    LegacyRenderSVGResource.markForLayoutAndParentResourceInvalidation(object: renderer!)
  }

  private func updateRendererStyle(
    renderer: RenderElementWrapper, newStyle: RenderStyleWrapper,
    minimalStyleDifference: StyleDifference
  ) {
    let oldStyle = RenderStyleWrapper.clone(style: renderer.style())
    renderer.setStyle(style: newStyle, minimalStyleDifference: minimalStyleDifference)
    builder!.normalizeTreeAfterStyleChange(renderer: renderer, oldStyle: oldStyle)
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

    if !insertionPosition.parent.isChildAllowed(newRenderer!, newRenderer!.style()) {
      return
    }

    element.setRenderer(renderer: newRenderer)

    newRenderer!.initializeStyle()

    builder!.attach(
      parent: insertionPosition.parent, child: newRenderer!,
      beforeChild: insertionPosition.nextSibling())

    if let textManipulationController = document.textManipulationControllerIfExists() {
      textManipulationController.didAddOrCreateRendererForNode(node: element)
    }

    if let cache = document.axObjectCache() {
      cache.onRendererCreated(element: element)
    }
  }

  private func updateBeforeDescendants(element: ElementWrapper, update: Style.ElementUpdate?) {
    if let update = update {
      generatedContent!.updatePseudoElement(
        current: element, elementUpdate: update, pseudoId: .Before)
    }

    if let before = element.beforePseudoElement() {
      storePreviousRenderer(node: before)
    }
  }

  private func updateAfterDescendants(element: ElementWrapper, update: Style.ElementUpdate?) {
    if update != nil {
      generatedContent!.updatePseudoElement(
        current: element, elementUpdate: update!, pseudoId: .After)
    }

    let renderer = element.containerRenderer()
    if renderer == nil {
      return
    }

    var minimalStyleDifference: StyleDifference = .Equal
    if update != nil, update!.recompositeLayer {
      minimalStyleDifference = .RecompositeLayer
    }

    generatedContent!.updateBackdropRenderer(
      renderer: renderer!, minimalStyleDifference: minimalStyleDifference)
    generatedContent!.updateWritingSuggestionsRenderer(
      renderer: renderer!, minimalStyleDifference: minimalStyleDifference)
    if CPtrToInt(element.p) == CPtrToInt(element.document().documentElement()?.p) {
      viewTransition!.updatePseudoElementTree(
        documentElementRenderer: renderer!, minimalStyleDifference: minimalStyleDifference)
    }

    builder!.updateAfterDescendants(renderer: renderer!)

    if element.hasCustomStyleResolveCallbacks() && update != nil && update!.change == .Renderer {
      element.didAttachRenderers()
    }
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
    if let renderer = node.renderer() {
      assert(CPtrToInt(renderingParent().previousChildRenderer?.id()) != CPtrToInt(renderer.id()))
      renderingParent().previousChildRenderer = renderer
      if renderer.isInFlow() {
        renderingParent().hasPrecedingInFlowChild = true
      }
    }
  }

  private class Parent {
    let element: ElementWrapper? = nil
    let update: Style.ElementUpdate? = nil
    let renderTreePosition: RenderTreePosition? = nil

    var didCreateOrDestroyChildRenderer = false
    var previousChildRenderer: RenderObjectWrapper? = nil
    var hasPrecedingInFlowChild = false

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

  func renderTreePosition() -> RenderTreePosition { return renderingParent().renderTreePosition! }

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
  enum TeardownType {
    case Full
    case FullAfterSlotOrShadowRootChange
    case RendererUpdate
    case RendererUpdateCancelingAnimations
  }

  static func tearDownRenderers(
    root: ElementWrapper, teardownType: TeardownType, builder: RenderTreeBuilder
  ) {
    var teardownStack: [ElementWrapper] = []

    pushForTearDown(element: root, teardownStack: &teardownStack)

    let descendants = composedTreeDescendants(parent: root)
    let didRepaintRoot = repaintAndMarkContainingBlockDirtyBeforeTearDown(
      root: root, composedTreeDescendantsIterator: descendants)
    let needsDescendantRepaintAndLayout: NeedsRepaintAndLayout =
      (didRepaintRoot != nil || didRepaintRoot! == .Yes) ? .No : .Yes
    let it = descendants.begin()
    while it != descendants.end() {
      popForTearDown(
        depth: it.depth(), root: root, teardownType: teardownType, builder: builder,
        teardownStack: &teardownStack)

      if let text = *it as? TextWrapper {
        tearDownTextRenderer(
          text: text, root: root, builder: builder,
          needsRepaintAndLayout: needsDescendantRepaintAndLayout)
        continue
      }

      pushForTearDown(element: *it as! ElementWrapper, teardownStack: &teardownStack)
    }

    popForTearDown(
      depth: 0, root: root, teardownType: teardownType, builder: builder,
      teardownStack: &teardownStack)

    tearDownLeftoverPaginationRenderersIfNeeded(root: root, builder: builder)
  }

  private static func pushForTearDown(
    element: ElementWrapper, teardownStack: inout [ElementWrapper]
  ) {
    if element.hasCustomStyleResolveCallbacks() {
      element.willDetachRenderers()
    }
    teardownStack.append(element)
  }

  private static func popForTearDown(
    depth: UInt32, root: ElementWrapper, teardownType: TeardownType, builder: RenderTreeBuilder,
    teardownStack: inout [ElementWrapper]
  ) {
    while teardownStack.count > depth {
      let element = teardownStack.removeLast()
      let styleable = StyleableWrapper.fromElement(element: element)

      // Make sure we don't leave any renderers behind in nodes outside the composed tree.
      // See ComposedTreeIterator::ComposedTreeIterator().
      if element is HTMLSlotElementWrapper || element.shadowRootFromElement() != nil {
        tearDownLeftoverChildrenOfComposedTree(element: element, builder: builder)
      }

      switch teardownType {
      case .FullAfterSlotOrShadowRootChange:
        if CPtrToInt(element.p) == CPtrToInt(root.p) {
          // Keep animations going on the host.
          styleable.willChangeRenderer()
          break
        }
        element.clearHoverAndActiveStatusBeforeDetachingRenderer()
      case .Full:
        styleable.cancelStyleOriginatedAnimations()
        element.clearHoverAndActiveStatusBeforeDetachingRenderer()
      case .RendererUpdateCancelingAnimations:
        styleable.cancelStyleOriginatedAnimations()
      case .RendererUpdate:
        styleable.willChangeRenderer()
      }

      GeneratedContent.removeBeforePseudoElement(element: element, builder: builder)
      GeneratedContent.removeAfterPseudoElement(element: element, builder: builder)

      if !(element is PseudoElementWrapper) {
        // ::before and ::after cannot have a ::marker pseudo-element addressable via
        // CSS selectors, and as such cannot possibly have animations on them. Additionally,
        // we cannot create a Styleable with a PseudoElement.
        if let renderListItem = element.containerRenderer() as? RenderListItemWrapper {
          if renderListItem.markerRenderer() != nil {
            let styleable = StyleableWrapper(
              element: element,
              pseudoElementIdentifier: Style.PseudoElementIdentifier(pseudoId: .Marker))
            styleable.cancelStyleOriginatedAnimations()
          }
        }
      }

      if let renderer = element.containerRenderer() {
        if let backdropRenderer = renderer.backdropRenderer() {
          builder.destroyAndCleanUpAnonymousWrappers(
            rendererToDestroy: backdropRenderer, subtreeDestroyRoot: nil)
        }
        builder.destroyAndCleanUpAnonymousWrappers(
          rendererToDestroy: renderer, subtreeDestroyRoot: root.containerRenderer())
        element.setRenderer(renderer: nil)
      }

      if element.hasCustomStyleResolveCallbacks() {
        element.didDetachRenderers()
      }
    }
  }

  private enum NeedsRepaintAndLayout {
    case No
    case Yes
  }

  private static func tearDownTextRenderer(
    text: TextWrapper, root: ContainerNodeWrapper?, builder: RenderTreeBuilder,
    needsRepaintAndLayout: NeedsRepaintAndLayout = .Yes
  ) {
    let renderer = text.renderer()
    if renderer == nil {
      return
    }
    if needsRepaintAndLayout == .Yes {
      renderer!.repaint()
      if let parent = renderer!.parent() {
        parent.setChildNeedsLayout()
        parent.setPreferredLogicalWidthsDirty(shouldBeDirty: true)
      }
    }
    builder.destroyAndCleanUpAnonymousWrappers(
      rendererToDestroy: renderer!,
      subtreeDestroyRoot: root != nil ? root!.containerRenderer() : nil)
    text.setRenderer(renderer: nil)
  }

  private static func tearDownLeftoverChildrenOfComposedTree(
    element: ElementWrapper, builder: RenderTreeBuilder
  ) {
    var child = element.firstChild()
    while child != nil {
      if child!.renderer() == nil {
        child = child!.nextSibling()
        continue
      }
      if let text = child! as? TextWrapper {
        tearDownTextRenderer(
          text: text, root: element, builder: builder, needsRepaintAndLayout: .No)
        child = child!.nextSibling()
        continue
      }
      if let element = child as? ElementWrapper {
        tearDownRenderers(root: element, teardownType: .Full, builder: builder)
      }
      child = child!.nextSibling()
    }
  }

  private static func tearDownLeftoverPaginationRenderersIfNeeded(
    root: ElementWrapper, builder: RenderTreeBuilder
  ) {
    if CPtrToInt(root.p) != CPtrToInt(root.document().documentElement()?.p) {
      return
    }
    var child = root.document().renderView()!.firstChild()
    while child != nil {
      let nextSibling = child!.nextSibling()
      if (child is RenderMultiColumnFlowWrapper) || (child is RenderMultiColumnSetWrapper) {
        builder.destroyAndCleanUpAnonymousWrappers(
          rendererToDestroy: child!, subtreeDestroyRoot: root.containerRenderer())
      }
      child = nextSibling
    }
  }

  func renderView() -> RenderViewWrapper { return document.renderView()! }

  private let document: Document
  private let styleUpdate: Style.Update? = nil

  private var parentStack: [Parent] = []

  private var generatedContent: GeneratedContent? = nil
  private var viewTransition: ViewTransition? = nil

  var builder: RenderTreeBuilder? = nil
}
