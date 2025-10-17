/*
 * Copyright (C) 2017-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2015 Google Inc. All rights reserved.
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

enum IsRemoval {
  case No
  case Yes
}

private func invalidateLineLayout(renderer: RenderObjectWrapper, isRemoval: IsRemoval) {
  let container = LayoutIntegration.LineLayout.blockContainer(renderer: renderer)
  if container == nil {
    return
  }
  if let inlineLayout = container!.inlineLayout(),
    shouldInvalidateLineLayoutPath(
      inlineLayout: inlineLayout, renderer: renderer, isRemoval: isRemoval, container: container!)
  {
    container!.invalidateLineLayoutPath(invalidationReason: .InsertionOrRemoval)
  }
}

private func shouldInvalidateLineLayoutPath(
  inlineLayout: LayoutIntegration.LineLayout, renderer: RenderObjectWrapper, isRemoval: IsRemoval,
  container: RenderBlockFlowWrapper
) -> Bool {
  if LayoutIntegration.LineLayout.shouldInvalidateLineLayoutPathAfterTreeMutation(
    parent: container, renderer: renderer, lineLayout: inlineLayout, isRemoval: isRemoval == .Yes)
  {
    return true
  }
  if isRemoval == .Yes {
    return !inlineLayout.removedFromTree(parent: renderer.parent()!, child: renderer)
  }
  return !inlineLayout.insertedIntoTree(parent: renderer.parent()!, child: renderer)
}

private func resetRendererStateOnDetach(
  parent: RenderElementWrapper, child: RenderObjectWrapper,
  willBeDestroyed: RenderTreeBuilder.WillBeDestroyed,
  isInternalMove: RenderTreeBuilder.IsInternalMove
) {
  if child.isFloatingOrOutOfFlowPositioned() {
    (child as! RenderBoxWrapper).removeFloatingOrPositionedChildFromBlockLists()
  } else if let parentFlexibleBox = parent as? RenderFlexibleBoxWrapper {
    if let childBox = child as? RenderBoxWrapper {
      parentFlexibleBox.clearCachedFlexItemIntrinsicContentLogicalHeight(flexItem: childBox)
      parentFlexibleBox.clearCachedMainSizeForFlexItem(flexItem: childBox)
    }
  }

  if willBeDestroyed == .No {
    child.setNeedsLayoutAndPrefWidthsRecalc()
  }

  // If we have a line box wrapper, delete it.
  if let textRenderer = child as? RenderTextWrapper {
    textRenderer.removeAndDestroyLegacyTextBoxes()
  }

  if let listItemRenderer = child as? RenderListItemWrapper, isInternalMove == .No {
    listItemRenderer.updateListMarkerNumbers()
  }

  // If child is the start or end of the selection, then clear the selection to
  // avoid problems of invalid pointers.
  if willBeDestroyed == .Yes && child.isSelectionBorder() {
    parent.frame().selection().setNeedsSelectionUpdate()
  }
}

class RenderTreeBuilder {
  init(view: RenderViewWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func attach(
    parent: RenderElementWrapper, child: RenderObjectWrapper?,
    beforeChild: RenderObjectWrapper? = nil
  ) {
    reportVisuallyNonEmptyContent(parent: parent, child: child!)
    attachInternal(parent: parent, child: child, beforeChild: beforeChild)
  }

  enum IsInternalMove {
    case No
    case Yes
  }

  enum WillBeDestroyed {
    case No
    case Yes
  }

  enum CanCollapseAnonymousBlock {
    case No
    case Yes
  }

  func detach(
    parent: RenderElementWrapper, child: RenderObjectWrapper,
    willBeDestroyed: WillBeDestroyed,
    canCollapseAnonymousBlock: CanCollapseAnonymousBlock = .Yes
  ) -> RenderObjectWrapper? {
    if let text = parent as? RenderSVGTextWrapper {
      return svgBuilder.detach(parent: text, child: child, willBeDestroyed: willBeDestroyed)
    }

    if let blockFlow = parent as? RenderBlockFlowWrapper {
      return blockBuilder.detach(
        parent: blockFlow, child: child, willBeDestroyed: willBeDestroyed,
        canCollapseAnonymousBlock: canCollapseAnonymousBlock)
    }

    if let menuList = parent as? RenderMenuListWrapper {
      return formControlsBuilder.detach(
        parent: menuList, child: child, willBeDestroyed: willBeDestroyed)
    }

    if let button = parent as? RenderButtonWrapper {
      return formControlsBuilder.detach(
        parent: button, child: child, willBeDestroyed: willBeDestroyed)
    }

    if let grid = parent as? RenderGridWrapper {
      return detachFromRenderGrid(parent: grid, child: child, willBeDestroyed: willBeDestroyed)
    }

    if let svgInline = parent as? RenderSVGInlineWrapper {
      return svgBuilder.detach(parent: svgInline, child: child, willBeDestroyed: willBeDestroyed)
    }

    if let container = parent as? LegacyRenderSVGContainer {
      return svgBuilder.detach(parent: container, child: child, willBeDestroyed: willBeDestroyed)
    }

    if let svgRoot = parent as? LegacyRenderSVGRootWrapper {
      return svgBuilder.detach(parent: svgRoot, child: child, willBeDestroyed: willBeDestroyed)
    }

    if let block = parent as? RenderBlockWrapper {
      return blockBuilder.detach(
        parent: block, oldChild: child, willBeDestroyed: willBeDestroyed,
        canCollapseAnonymousBlock: canCollapseAnonymousBlock)
    }

    return detachFromRenderElement(parent: parent, child: child, willBeDestroyed: willBeDestroyed)
  }

  enum TearDownType {
    case Root  // destroy root renderer
    case SubtreeWithRootStillAttached  // subtree teardown when renderers are still attached to the tree (common case)
    case SubtreeWithRootAlreadyDetached  // subtree teardown when destroy root gets detached first followed by destroying renderers (e.g. pseudo subtree)
  }

  func destroy(
    renderer: RenderObjectWrapper, canCollapseAnonymousBlock: CanCollapseAnonymousBlock = .Yes
  ) {
    assert(RenderTreeMutationDisallowedScope.isMutationAllowed())
    assert(renderer.parent() != nil)

    RenderTreeBuilder.notifyDescendantRenderersBeforeSubtreeTearDownIfApplicable(renderer: renderer)

    let toDestroy = detach(
      parent: renderer.parent()!, child: renderer, willBeDestroyed: .Yes,
      canCollapseAnonymousBlock: canCollapseAnonymousBlock)

    if let textFragment = renderer as? RenderTextFragmentWrapper {
      firstLetterBuilder.cleanupOnDestroy(textFragment: textFragment)
    }

    if let renderBox = renderer as? RenderBoxModelObjectWrapper {
      continuationBuilder.cleanupOnDestroy(renderer: renderBox)
    }

    // FIXME: webkit.org/b/182909.
    tearDownSubTreeIfApplicable(toDestroy: toDestroy)
  }

  private static func notifyDescendantRenderersBeforeSubtreeTearDownIfApplicable(
    renderer: RenderObjectWrapper
  ) {
    if renderer.renderTreeBeingDestroyed() {
      return
    }
    if let rendererToDelete = renderer as? RenderElementWrapper,
      rendererToDelete.firstChild() != nil
    {
      for descendant: RenderObjectWrapper in descendantsOfType(root: rendererToDelete) {
        descendant.willBeRemovedFromTree()
      }
    }
  }

  private func tearDownSubTreeIfApplicable(toDestroy: RenderObjectWrapper?) {
    let rendererToDelete = toDestroy as? RenderElementWrapper
    if rendererToDelete == nil {
      return
    }

    let _ = SetForScope(
      scopedVariable: &tearDownType, newValue: TearDownType.SubtreeWithRootAlreadyDetached)
    while rendererToDelete!.firstChild() != nil {
      let firstChild = rendererToDelete!.firstChild()!
      if let node = firstChild.node() {
        node.setRenderer(renderer: nil)
      }
      destroy(renderer: firstChild)
    }
  }

  // NormalizeAfterInsertion::Yes ensures that the destination subtree is consistent after the insertion (anonymous wrappers etc).
  enum NormalizeAfterInsertion {
    case No
    case Yes
  }

  func move(
    from: RenderBoxModelObjectWrapper, to: RenderBoxModelObjectWrapper, child: RenderObjectWrapper,
    normalizeAfterInsertion: NormalizeAfterInsertion
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateAfterDescendants(renderer: RenderElementWrapper) {
    if let svgRoot = renderer as? RenderSVGRootWrapper {
      svgBuilder.updateAfterDescendants(svgRoot: svgRoot)
      return  // A RenderSVGRoot cannot be a RenderBlock, RenderListItem or RenderBlockFlow: early return.
    }

    // Do not early return here in any case. For example, RenderListItem derives
    // from RenderBlockFlow and indirectly from RenderBlock thus fulfilling all
    // update conditions below.
    if let block = renderer as? RenderBlockWrapper {
      firstLetterBuilder.updateAfterDescendants(block: block)
    }
    if let listItem = renderer as? RenderListItemWrapper {
      listBuilder.updateItemMarker(listItemRenderer: listItem)
    }
    if let blockFlow = renderer as? RenderBlockFlowWrapper {
      multiColumnBuilder.updateAfterDescendants(flow: blockFlow)
    }
  }

  func destroyAndCleanUpAnonymousWrappers(
    rendererToDestroy: RenderObjectWrapper, subtreeDestroyRoot: RenderElementWrapper?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func normalizeTreeAfterStyleChange(renderer: RenderElementWrapper, oldStyle: RenderStyleWrapper) {
    if renderer.parent() == nil {
      return
    }

    let wasFloating = oldStyle.isFloating()
    let wasOutOfFlowPositioned = oldStyle.hasOutOfFlowPosition()
    let isFloating = renderer.style().isFloating()
    let isOutOfFlowPositioned = renderer.style().hasOutOfFlowPosition()
    var startsAffectingParent = false
    var noLongerAffectsParent = false

    let parent = renderer.parent()!
    if parent is RenderBlockWrapper {
      noLongerAffectsParent =
        (!wasFloating && isFloating) || (!wasOutOfFlowPositioned && isOutOfFlowPositioned)
    }

    if parent is RenderBlockFlowWrapper || parent is RenderInlineWrapper {
      startsAffectingParent =
        (wasFloating || wasOutOfFlowPositioned) && !isFloating && !isOutOfFlowPositioned
      assert(!startsAffectingParent || !noLongerAffectsParent)
    }

    if startsAffectingParent {
      // We have gone from not affecting the inline status of the parent flow to suddenly
      // having an impact. See if there is a mismatch between the parent flow's
      // childrenInline() state and our state.
      if renderer.isInline() != renderer.parent()!.childrenInline() {
        childFlowStateChangesAndAffectsParentBlock(child: renderer)
      }
      // WARNING: original parent might be deleted at this point.
      handleFragmentedFlowStateChange(
        renderer: renderer, wasOutOfFlowPositioned: wasOutOfFlowPositioned,
        isOutOfFlowPositioned: isOutOfFlowPositioned)
      return
    }

    if noLongerAffectsParent {
      childFlowStateChangesAndNoLongerAffectsParentBlock(child: renderer)

      if isFloating {
        if let blockFlow = renderer as? RenderBlockFlowWrapper {
          // These descendent floats can not intrude other, sibling block containers anymore.
          for descendant: RenderBoxWrapper in descendantsOfType(root: blockFlow) {
            if descendant.isFloating() {
              descendant.removeFloatingAndInvalidateForLayout()
            }
          }
          removeFloatingObjects(renderer: blockFlow)
          // Fresh floats need to be reparented if they actually belong to the previous anonymous block.
          // It copies the logic of RenderBlock::addChildIgnoringContinuation
          if blockFlow.previousSibling() != nil && blockFlow.previousSibling()!.isAnonymousBlock() {
            move(
              from: parent as! RenderBoxModelObjectWrapper,
              to: blockFlow.previousSibling() as! RenderBoxModelObjectWrapper, child: renderer,
              normalizeAfterInsertion: .No)
          }
        }
      }
    }

    handleFragmentedFlowStateChange(
      renderer: renderer, wasOutOfFlowPositioned: wasOutOfFlowPositioned,
      isOutOfFlowPositioned: isOutOfFlowPositioned)
  }

  private func handleFragmentedFlowStateChange(
    renderer: RenderElementWrapper, wasOutOfFlowPositioned: Bool, isOutOfFlowPositioned: Bool
  ) {
    if renderer.parent() == nil {
      return
    }
    // Out of flow children of RenderMultiColumnFlow are not really part of the multicolumn flow. We need to ensure that changes in positioning like this
    // trigger insertions into the multicolumn flow.
    if let enclosingFragmentedFlow = renderer.parent()!.enclosingFragmentedFlow()
      as? RenderMultiColumnFlowWrapper
    {
      let movingIntoMulticolumn = RenderTreeBuilder.movingIntoMulticolumn(
        renderer: renderer, wasOutOfFlowPositioned: wasOutOfFlowPositioned,
        isOutOfFlowPositioned: isOutOfFlowPositioned)
      if movingIntoMulticolumn {
        renderer.initializeFragmentedFlowStateOnInsertion()
        multiColumnBuilder.multiColumnDescendantInserted(
          flow: enclosingFragmentedFlow, newDescendant: renderer)
        return
      }
      let movingOutOfMulticolumn = !wasOutOfFlowPositioned && isOutOfFlowPositioned
      if movingOutOfMulticolumn {
        multiColumnBuilder.restoreColumnSpannersForContainer(
          container: renderer, multiColumnFlow: enclosingFragmentedFlow)
        return
      }

      // Style change may have moved some subtree out of the fragmented flow. Their flow states have already been updated (see adjustFragmentedFlowStateOnContainingBlockChangeIfNeeded)
      // and here is where we take care of the remaining, spanner tree mutation.
      let spannerContainingBlockSet = ObjectIdentifierHashSet<RenderElementWrapper>()
      for descendant: RenderMultiColumnSpannerPlaceholderWrapper in descendantsOfType(
        root: renderer)
      {
        if let containingBlock = descendant.containingBlock(),
          CPtrToInt(containingBlock.enclosingFragmentedFlow()?.p)
            != CPtrToInt(enclosingFragmentedFlow.p)
        {
          spannerContainingBlockSet.add(value: containingBlock)
        }
      }
      let oldEnclosingFragmentedFlow = WeakNullableRef(enclosingFragmentedFlow)
      for containingBlock in spannerContainingBlockSet {
        if !oldEnclosingFragmentedFlow.bool() {
          break
        }
        multiColumnBuilder.restoreColumnSpannersForContainer(
          container: containingBlock, multiColumnFlow: *oldEnclosingFragmentedFlow)
      }
    }
  }

  private static func movingIntoMulticolumn(
    renderer: RenderElementWrapper, wasOutOfFlowPositioned: Bool, isOutOfFlowPositioned: Bool
  ) -> Bool {
    if wasOutOfFlowPositioned && !isOutOfFlowPositioned {
      return true
    }
    if let containingBlock = renderer.containingBlock(), isOutOfFlowPositioned {
      // Sometimes the flow state could change even when the renderer stays out-of-flow (e.g when going from fixed to absolute and
      // the containing block is inside a multi-column flow).
      return containingBlock.fragmentedFlowState() == .InsideFlow
        && renderer.fragmentedFlowState() == .NotInsideFlow
    }
    return false
  }

  private func attachInternal(
    parent: RenderElementWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func childFlowStateChangesAndNoLongerAffectsParentBlock(child: RenderElementWrapper) {
    assert(child.parent() != nil)
    removeAnonymousWrappersForInlineChildrenIfNeeded(parent: child.parent()!)
  }

  private func childFlowStateChangesAndAffectsParentBlock(child: RenderElementWrapper) {
    if !child.isInline() {
      let parent = child.parent()!
      if let parentBlockRenderer = parent as? RenderBlockWrapper {
        blockBuilder.childBecameNonInline(parent: parentBlockRenderer, child: child)
      } else if let parentInlineRenderer = parent as? RenderInlineWrapper {
        inlineBuilder.childBecameNonInline(parent: parentInlineRenderer, child: child)
      }
      // WARNING: original parent might be deleted at this point.
      if let newParent = child.parent(), CPtrToInt(newParent.p) != CPtrToInt(parent.p) {
        if let gridRenderer = newParent as? RenderGridWrapper {
          // We need to re-run the grid items placement if it had gained a new item.
          gridRenderer.dirtyGrid()
        }
      }
      return
    }
    // An anonymous block must be made to wrap this inline.
    let parent = child.parent()!
    let block = (parent as! RenderBlockWrapper).createAnonymousBlock()
    attachToRenderElementInternal(parent: parent, child: block, beforeChild: child)
    let thisToMove = detachFromRenderElement(parent: parent, child: child, willBeDestroyed: .No)
    attachToRenderElementInternal(parent: block!, child: thisToMove)
  }

  func attachToRenderElementInternal(
    parent: RenderElementWrapper, child: RenderObjectWrapper?,
    beforeChild: RenderObjectWrapper? = nil
  ) {
    if parent.view().frameView().layoutContext().layoutState() != nil {
      fatalError("Layout must not mutate render tree")
    }
    assert(parent.canHaveChildren() || parent.canHaveGeneratedChildren())
    assert(child!.parent() == nil)
    assert(
      !parent.isRenderBlockFlow()
        || (!child!.isRenderTableSection() && !child!.isRenderTableRow()
          && !child!.isRenderTableCell())
    )

    var beforeChild = beforeChild
    while beforeChild != nil && beforeChild!.parent() != nil
      && CPtrToInt(beforeChild!.parent()?.p) != CPtrToInt(parent.p)
    {
      beforeChild = beforeChild!.parent()
    }

    if beforeChild != nil && beforeChild!.parent() == nil {
      fatalError("Not reached")
    }

    assert(beforeChild == nil || CPtrToInt(beforeChild!.parent()?.p) == CPtrToInt(parent.p))
    assert(
      !(beforeChild is RenderTextWrapper)
        || (beforeChild as! RenderTextWrapper).inlineWrapperForDisplayContents() == nil)

    // Take the ownership.
    let newChild = parent.attachRendererInternal(child: child, beforeChild: beforeChild)
    if parent.renderTreeBeingDestroyed() {
      fatalError("Not reached")
    }

    newChild!.insertedIntoTree()
    invalidateLineLayout(renderer: newChild!, isRemoval: .No)

    if internalMovesType == .No {
      newChild!.initializeFragmentedFlowStateOnInsertion()
      if let fragmentedFlow = newChild!.enclosingFragmentedFlow() as? RenderMultiColumnFlowWrapper {
        multiColumnBuilder.multiColumnDescendantInserted(
          flow: fragmentedFlow, newDescendant: newChild!)
      }
      if let listItemRenderer = newChild as? RenderListItemWrapper {
        listItemRenderer.updateListMarkerNumbers()
      }
    }

    newChild!.setNeedsLayoutAndPrefWidthsRecalc()
    let isOutOfFlowBox = newChild!.style().hasOutOfFlowPosition()
    if !isOutOfFlowBox {
      parent.setPreferredLogicalWidthsDirty(shouldBeDirty: true)
    }

    if !parent.normalChildNeedsLayout() {
      if isOutOfFlowBox {
        if RenderTreeBuilder.newChildIsEligibleForStaticPositionLayoutOnly(
          newChild: newChild!, parent: parent)
        {
          // FIXME: Introduce a dirty bit to bridge the gap between parent and containing block which would
          // not trigger layout but a simple traversal all the way to the direct parent and also expand it non-direct parent cases.
          parent.setOutOfFlowChildNeedsStaticPositionLayout()
        } else {
          parent.setChildNeedsLayout()
        }
      } else {
        parent.setChildNeedsLayout()
      }
    }

    if let cache = parent.document().axObjectCache() {
      cache.childrenChanged(renderer: parent, changedChild: newChild)
    }

    if parent.hasOutlineAutoAncestor()
      || parent.outlineStyleForRepaint().outlineStyleIsAuto() == .On
    {
      if !(newChild!.previousSibling() is RenderMultiColumnSetWrapper) {
        newChild!.setHasOutlineAutoAncestor()
      }
    }
  }

  private static func newChildIsEligibleForStaticPositionLayoutOnly(
    newChild: RenderObjectWrapper, parent: RenderElementWrapper
  ) -> Bool {
    // setNeedsLayoutAndPrefWidthsRecalc above already takes care of propagating dirty bits on the ancestor chain, but
    // in order to compute static position for out of flow boxes, the parent has to run normal flow layout as well (as opposed to simplified)
    if CPtrToInt(newChild.containingBlock()?.p) != CPtrToInt(parent.p) {
      return false
    }
    // FIXME: RenderVideo's setNeedsLayout pattern does not play well with this optimization: see webkit.org/b/276253
    if newChild is RenderVideoWrapper {
      return false
    }
    // Since we can't actually run static position only layout for a block container (RenderBlockFlow::layoutBlock() does not have such fine grained layout flow)
    // floats get rebuilt which assumes (see intruding floats) parent block containers do the same.
    if let renderBlock = parent as? RenderBlockWrapper {
      return !renderBlock.containsFloats()
    }
    return true
  }

  func detachFromRenderElement(
    parent: RenderElementWrapper, child: RenderObjectWrapper, willBeDestroyed: WillBeDestroyed
  ) -> RenderObjectWrapper? {
    if parent.view().frameView().layoutContext().layoutState() != nil {
      fatalError("Layout must not mutate render tree")
    }
    assert(parent.canHaveChildren() || parent.canHaveGeneratedChildren())
    assert(CPtrToInt(child.parent()?.p) == CPtrToInt(parent.p))

    if parent.renderTreeBeingDestroyed() || tearDownType == .SubtreeWithRootAlreadyDetached {
      return parent.detachRendererInternal(renderer: child)
    }

    if child.everHadLayout() {
      resetRendererStateOnDetach(
        parent: parent, child: child, willBeDestroyed: willBeDestroyed,
        isInternalMove: internalMovesType)
    }

    if tearDownType == .Root || subtreeDestroyRoot is RenderInlineWrapper {
      // In case of partial damage on the inline content (the block root is not going away), we need to initiate inline layout invalidation on leaf renderers too.
      invalidateLineLayout(renderer: child, isRemoval: .Yes)
    }

    // FIXME: Fragment state should not be such a special case.
    if internalMovesType == .No {
      child.resetFragmentedFlowStateOnRemoval()
    }

    child.willBeRemovedFromTree()
    // WARNING: There should be no code running between willBeRemovedFromTree() and the actual removal below.
    // This is needed to avoid race conditions where willBeRemovedFromTree() would dirty the tree's structure
    // and the code running here would force an untimely rebuilding, leaving |child| dangling.
    let childToTake = parent.detachRendererInternal(renderer: child)

    if let cache = parent.document().existingAXObjectCache() {
      cache.childrenChanged(renderer: parent)
    }

    return childToTake
  }

  private func detachFromRenderGrid(
    parent: RenderGridWrapper, child: RenderObjectWrapper, willBeDestroyed: WillBeDestroyed
  ) -> RenderObjectWrapper? {
    let takenChild = blockBuilder.detach(
      parent: parent, oldChild: child, willBeDestroyed: willBeDestroyed)
    // Positioned grid items do not take up space or otherwise participate in the layout of the grid,
    // for that reason we don't need to mark the grid as dirty when they are removed.
    if child.isOutOfFlowPositioned() {
      return takenChild
    }

    // The grid needs to be recomputed as it might contain auto-placed items that will change their position.
    parent.dirtyGrid()
    return takenChild
  }

  func moveAllChildrenIncludingFloats(
    from: RenderBlockWrapper, to: RenderBlockWrapper,
    normalizeAfterInsertion: NormalizeAfterInsertion
  ) {
    if from is RenderBlockFlowWrapper {
      blockFlowBuilder.moveAllChildrenIncludingFloats(
        from: from as! RenderBlockFlowWrapper, to: to,
        normalizeAfterInsertion: normalizeAfterInsertion)
      return
    }
    moveAllChildren(from: from, to: to, normalizeAfterInsertion: normalizeAfterInsertion)
  }

  func moveAllChildren(
    from: RenderBoxModelObjectWrapper, to: RenderBoxModelObjectWrapper,
    normalizeAfterInsertion: NormalizeAfterInsertion
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removeFloatingObjects(renderer: RenderBlockWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func createAnonymousWrappersForInlineContent(
    parent: RenderBlockWrapper, insertionPoint: RenderObjectWrapper? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func removeAnonymousWrappersForInlineChildrenIfNeeded(parent: RenderElementWrapper) {
    let blockParent = parent as? RenderBlockWrapper
    if blockParent == nil || !blockParent!.canDropAnonymousBlockChild() {
      return
    }

    // We have changed to floated or out-of-flow positioning so maybe all our parent's
    // children can be inline now. Bail if there are any block children left on the line,
    // otherwise we can proceed to stripping solitary anonymous wrappers from the inlines.
    // FIXME: We should also handle split inlines here - we exclude them at the moment by returning
    // if we find a continuation.
    var shouldAllChildrenBeInline: Bool? = nil
    var current = blockParent!.firstChild()
    while current != nil {
      if current!.style().isFloating() || current!.style().hasOutOfFlowPosition() {
        current = current!.nextSibling()
        continue
      }
      if !current!.isAnonymousBlock() || (current as! RenderBlockWrapper).isContinuation() {
        return
      }
      // Anonymous block not in continuation. Check if it holds a set of inline or block children and try not to mix them.
      let firstChild = current!.firstChildSlow()
      if firstChild == nil {
        current = current!.nextSibling()
        continue
      }
      let isInlineLevelBox = firstChild!.isInline()
      if shouldAllChildrenBeInline == nil {
        shouldAllChildrenBeInline = isInlineLevelBox
        current = current!.nextSibling()
        continue
      }
      // Mixing inline and block level boxes?
      if shouldAllChildrenBeInline! != isInlineLevelBox {
        return
      }
      current = current!.nextSibling()
    }

    var next: RenderObjectWrapper? = nil
    current = blockParent!.firstChild()
    while current != nil {
      next = current!.nextSibling()
      if current!.isAnonymousBlock() {
        blockBuilder.dropAnonymousBoxChild(
          parent: blockParent!, child: current as! RenderBlockWrapper)
      }
      current = next
    }
  }

  private func reportVisuallyNonEmptyContent(
    parent: RenderElementWrapper, child: RenderObjectWrapper
  ) {
    if view.frameView().hasEnoughContentForVisualMilestones() {
      return
    }

    if let textRenderer = child as? RenderTextWrapper {
      let style = parent.style()
      // FIXME: Find out how to increment the visually non empty character count when the font becomes available.
      if style.usedVisibility() == .Visible && !style.fontCascade().isLoadingCustomFonts() {
        view.frameView().incrementVisuallyNonEmptyCharacterCount(inlineText: textRenderer.text())
      }
      return
    }
    if child is RenderHTMLCanvasWrapper || child is RenderEmbeddedObjectWrapper {
      // Actual size is not known yet, report the default intrinsic size for replaced elements.
      let replacedRenderer = child as! RenderReplacedWrapper
      view.frameView().incrementVisuallyNonEmptyPixelCount(
        size: roundedIntSize(s: replacedRenderer.intrinsicSize()))
      return
    }
    if child.isRenderOrLegacyRenderSVGRoot() {
      // SVG content tends to have a fixed size construct. However this is known to be inaccurate in certain cases (box-sizing: border-box) or especially when the parent box is oversized.
      var candidateSize = IntSize()
      if let size = RenderTreeBuilder.fixedSizeForSVG(renderer: child) {
        candidateSize = size
      } else if let size = RenderTreeBuilder.fixedSizeForSVG(renderer: parent) {
        candidateSize = size
      }

      if !candidateSize.isEmpty() {
        view.frameView().incrementVisuallyNonEmptyPixelCount(size: candidateSize)
      }
      return
    }
  }

  private static func fixedSizeForSVG(renderer: RenderObjectWrapper) -> IntSize? {
    let style = renderer.style()
    if !style.width().isFixed() || !style.height().isFixed() {
      return nil
    }
    return IntSize(width: style.width().intValue(), height: style.height().intValue())
  }

  let view: RenderViewWrapper

  private let firstLetterBuilder: FirstLetter
  private let listBuilder: List
  let multiColumnBuilder: MultiColumn
  private let formControlsBuilder: FormControls
  private let blockBuilder: Block
  private let blockFlowBuilder: BlockFlow
  private let inlineBuilder: Inline
  private let svgBuilder: SVG
  private let continuationBuilder: Continuation
  private let internalMovesType: IsInternalMove = .No
  private var tearDownType: TearDownType = .Root
  private let subtreeDestroyRoot: RenderElementWrapper? = nil
  let anonymousDestroyRoot: RenderObjectWrapper? = nil
}
