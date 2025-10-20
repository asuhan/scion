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

private func getInlineRun(start: RenderObjectWrapper?, boundary: RenderObjectWrapper?) -> (
  RenderObjectWrapper?, RenderObjectWrapper?
) {
  // Beginning at |start| we find the largest contiguous run of inlines that
  // we can. We denote the run with start and end points, |inlineRunStart|
  // and |inlineRunEnd|. Note that these two values may be the same if
  // we encounter only one inline.
  //
  // We skip any non-inlines we encounter as long as we haven't found any
  // inlines yet.
  //
  // |boundary| indicates a non-inclusive boundary point. Regardless of whether |boundary|
  // is inline or not, we will not include it in a run with inlines before it. It's as though we encountered
  // a non-inline.

  // Start by skipping as many non-inlines as we can.
  var curr = start
  var sawInline = false
  var inlineRunStart: RenderObjectWrapper? = nil
  var inlineRunEnd: RenderObjectWrapper? = nil
  repeat {
    while curr != nil && !(curr!.isInline() || curr!.isFloatingOrOutOfFlowPositioned()) {
      curr = curr!.nextSibling()
    }

    inlineRunStart = curr
    inlineRunEnd = curr

    if curr == nil {
      break  // No more inline children to be found.
    }

    sawInline = curr!.isInline()

    curr = curr!.nextSibling()
    while curr != nil && (curr!.isInline() || curr!.isFloatingOrOutOfFlowPositioned())
      && (CPtrToInt(curr!.p) != CPtrToInt(boundary?.p))
    {
      inlineRunEnd = curr
      if curr!.isInline() {
        sawInline = true
      }
      curr = curr!.nextSibling()
    }
  } while !sawInline
  return (inlineRunStart, inlineRunEnd)
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
    move(
      from: from, to: to, child: child, beforeChild: nil,
      normalizeAfterInsertion: normalizeAfterInsertion)
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
    assert(CPtrToInt(parent.view().p) == CPtrToInt(view.p))

    var beforeChild = beforeChild
    if let beforeChildText = beforeChild as? RenderTextWrapper {
      if let wrapperInline = beforeChildText.inlineWrapperForDisplayContents() {
        beforeChild = wrapperInline
      }
    } else if let beforeChildBox = beforeChild as? RenderBoxWrapper {
      // Adjust the beforeChild if it happens to be a spanner and the its actual location is inside the fragmented flow.
      if let enclosingFragmentedFlow = parent.enclosingFragmentedFlow(),
        let spannerPlaceholder = RenderTreeBuilder.columnSpannerPlaceholderForBeforeChild(
          beforeChildBox: beforeChildBox, enclosingFragmentedFlow: enclosingFragmentedFlow)
      {
        beforeChild = spannerPlaceholder
      }
    }

    if let text = parent as? RenderSVGTextWrapper {
      svgBuilder.attach(parent: text, child: child, beforeChild: beforeChild)
      return
    }

    if parent.style().display() == .Ruby || parent.style().display() == .RubyBlock {
      let parentCandidate = rubyBuilder.findOrCreateParentForStyleBasedRubyChild(
        parent: parent, child: child!, beforeChild: &beforeChild)
      if CPtrToInt(parentCandidate.p) == CPtrToInt(parent.p) {
        rubyBuilder.attachForStyleBasedRuby(
          parent: parentCandidate, child: child, beforeChild: beforeChild)
        return
      }
      insertRecursiveIfNeeded(parentCandidate: parentCandidate)
      return
    }

    if let parentBlockFlow = parent as? RenderBlockFlowWrapper {
      blockFlowBuilder.attach(parent: parentBlockFlow, child: child, beforeChild: beforeChild)
      return
    }

    if let row = parent as? RenderTableRowWrapper {
      let parentCandidate = tableBuilder.findOrCreateParentForChild(
        parent: row, child: child!, beforeChild: &beforeChild)
      if CPtrToInt(parentCandidate.p) == CPtrToInt(parent.p) {
        tableBuilder.attach(parent: row, child: child, beforeChild: beforeChild)
        return
      }
      insertRecursiveIfNeeded(parentCandidate: parentCandidate)
      return
    }

    if let tableSection = parent as? RenderTableSectionWrapper {
      let parentCandidate = tableBuilder.findOrCreateParentForChild(
        parent: tableSection, child: child!, beforeChild: &beforeChild)
      if CPtrToInt(parent.p) == CPtrToInt(parentCandidate.p) {
        tableBuilder.attach(parent: tableSection, child: child, beforeChild: beforeChild)
        return
      }
      insertRecursiveIfNeeded(parentCandidate: parentCandidate)
      return
    }

    if let table = parent as? RenderTableWrapper {
      let parentCandidate = tableBuilder.findOrCreateParentForChild(
        parent: table, child: child!, beforeChild: &beforeChild)
      if CPtrToInt(parentCandidate.p) == CPtrToInt(parent.p) {
        tableBuilder.attach(parent: table, child: child, beforeChild: beforeChild)
        return
      }
      insertRecursiveIfNeeded(parentCandidate: parentCandidate)
      return
    }

    if let button = parent as? RenderButtonWrapper {
      formControlsBuilder.attach(parent: button, child: child, beforeChild: beforeChild)
      return
    }

    if let menuList = parent as? RenderMenuListWrapper {
      formControlsBuilder.attach(parent: menuList, child: child, beforeChild: beforeChild)
      return
    }

    if let container = parent as? LegacyRenderSVGContainer {
      svgBuilder.attach(parent: container, child: child, beforeChild: beforeChild)
      return
    }

    if let svgInline = parent as? RenderSVGInlineWrapper {
      svgBuilder.attach(parent: svgInline, child: child, beforeChild: beforeChild)
      return
    }

    if let svgRoot = parent as? RenderSVGRootWrapper {
      svgBuilder.attach(parent: svgRoot, child: child, beforeChild: beforeChild)
      return
    }

    if let svgRoot = parent as? LegacyRenderSVGRootWrapper {
      svgBuilder.attach(parent: svgRoot, child: child, beforeChild: beforeChild)
      return
    }

    if let gridParent = parent as? RenderGridWrapper {
      attachToRenderGrid(parent: gridParent, child: child, beforeChild: beforeChild)
      return
    }

    if let parentBlock = parent as? RenderBlockWrapper {
      blockBuilder.attach(parent: parentBlock, child: child, beforeChild: beforeChild)
      return
    }

    if let inlineParent = parent as? RenderInlineWrapper {
      inlineBuilder.attach(parent: inlineParent, child: child, beforeChild: beforeChild)
      return
    }

    attachToRenderElement(parent: parent, child: child, beforeChild: beforeChild)
  }

  private func insertRecursiveIfNeeded(parentCandidate: RenderElementWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private static func columnSpannerPlaceholderForBeforeChild(
    beforeChildBox: RenderBoxWrapper, enclosingFragmentedFlow: RenderFragmentedFlowWrapper?
  )
    -> RenderMultiColumnSpannerPlaceholderWrapper?
  {
    if let multiColumnFlow = enclosingFragmentedFlow as? RenderMultiColumnFlowWrapper {
      return multiColumnFlow.findColumnSpannerPlaceholder(spanner: beforeChildBox)
    }
    return nil
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

  func attachToRenderGrid(
    parent: RenderGridWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func attachToRenderElement(
    parent: RenderElementWrapper, child: RenderObjectWrapper?,
    beforeChild: RenderObjectWrapper? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func move(
    from: RenderBoxModelObjectWrapper, to: RenderBoxModelObjectWrapper, child: RenderObjectWrapper,
    beforeChild: RenderObjectWrapper?, normalizeAfterInsertion: NormalizeAfterInsertion
  ) {
    // We assume that callers have cleared their positioned objects list for child moves so the
    // positioned renderer maps don't become stale. It would be too slow to do the map lookup on each call.
    assert(
      normalizeAfterInsertion == .No || !(from is RenderBlockWrapper)
        || !(from as! RenderBlockWrapper).hasPositionedObjects())

    if normalizeAfterInsertion == .Yes && from is RenderBlockWrapper && child.isRenderBox() {
      RenderBlockWrapper.removePercentHeightDescendantIfNeeded(
        descendant: child as! RenderBoxWrapper)
    }
    if normalizeAfterInsertion == .Yes && (to.isRenderBlock() || to.isRenderInline()) {
      // Takes care of adding the new child correctly if toBlock and fromBlock
      // have different kind of children (block vs inline).
      let childToMove = detachFromRenderElement(parent: from, child: child, willBeDestroyed: .No)
      attach(parent: to, child: childToMove, beforeChild: beforeChild)
    } else {
      let _ = SetForScope(scopedVariable: &internalMovesType, newValue: IsInternalMove.Yes)
      let childToMove = detachFromRenderElement(parent: from, child: child, willBeDestroyed: .No)
      attachToRenderElementInternal(parent: to, child: childToMove, beforeChild: beforeChild)
    }

    // When moving a subtree out of a BFC we need to make sure that the line boxes generated for the inline tree are not accessible anymore from the renderers.
    // Let's find the BFC root and nuke the inline tree (At some point we are going to destroy the subtree instead of moving these renderers around.)
    if child is RenderInlineWrapper {
      RenderTreeBuilder.findBFCRootAndDestroyInlineTree(from: from)
    }
  }

  private static func findBFCRootAndDestroyInlineTree(from: RenderBoxModelObjectWrapper) {
    var containingBlock: RenderBoxModelObjectWrapper? = from
    while containingBlock != nil {
      containingBlock!.setNeedsLayout()
      if let blockFlow = containingBlock as? RenderBlockFlowWrapper {
        blockFlow.deleteLines()
        break
      }
      containingBlock = containingBlock!.containingBlock()
    }
  }

  // Move all of the kids from |startChild| up to but excluding |endChild|. 0 can be passed as the |endChild| to denote
  // that all the kids from |startChild| onwards should be moved.
  private func moveChildren(
    from: RenderBoxModelObjectWrapper, to: RenderBoxModelObjectWrapper,
    startChild: RenderObjectWrapper?, endChild: RenderObjectWrapper?,
    normalizeAfterInsertion: NormalizeAfterInsertion
  ) {
    moveChildren(
      from: from, to: to, startChild: startChild, endChild: endChild, beforeChild: nil,
      normalizeAfterInsertion: normalizeAfterInsertion)
  }

  private func moveChildren(
    from: RenderBoxModelObjectWrapper, to: RenderBoxModelObjectWrapper,
    startChild: RenderObjectWrapper?, endChild: RenderObjectWrapper?,
    beforeChild: RenderObjectWrapper?, normalizeAfterInsertion: NormalizeAfterInsertion
  ) {
    // This condition is rarely hit since this function is usually called on
    // anonymous blocks which can no longer carry positioned objects (see r120761)
    // or when fullRemoveInsert is false.
    if normalizeAfterInsertion == .Yes, let blockFlow = from as? RenderBlockFlowWrapper {
      blockFlow.removePositionedObjects(newContainingBlockCandidate: nil)
      RenderBlockWrapper.removePercentHeightDescendantIfNeeded(descendant: blockFlow)
      removeFloatingObjects(renderer: blockFlow)
    }

    assert(beforeChild == nil || CPtrToInt(to.p) == CPtrToInt(beforeChild?.parent()?.p))
    var child = startChild
    while child != nil && CPtrToInt(child!.p) != CPtrToInt(endChild?.p) {
      // Save our next sibling as moveChildTo will clear it.
      var nextSibling = child!.nextSibling()

      // FIXME: This logic here fails to detect the first letter in certain cases
      // and skips a valid sibling renderer (see webkit.org/b/163737).
      // Check to make sure we're not saving the firstLetter as the nextSibling.
      // When the |child| object will be moved, its firstLetter will be recreated,
      // so saving it now in nextSibling would leave us with a stale object.
      if child is RenderTextFragmentWrapper && nextSibling is RenderTextWrapper {
        var firstLetterObj: RenderObjectWrapper? = nil
        if let block = (child as! RenderTextFragmentWrapper).blockForAccompanyingFirstLetter() {
          firstLetterObj = block.getFirstLetter().firstLetter
        }

        // This is the first letter, skip it.
        if CPtrToInt(firstLetterObj?.p) == CPtrToInt(nextSibling?.p) {
          nextSibling = nextSibling!.nextSibling()
        }
      }

      move(
        from: from, to: to, child: child!, beforeChild: beforeChild,
        normalizeAfterInsertion: normalizeAfterInsertion)
      child = nextSibling
    }
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
    moveAllChildren(
      from: from, to: to, beforeChild: nil, normalizeAfterInsertion: normalizeAfterInsertion)
  }

  private func moveAllChildren(
    from: RenderBoxModelObjectWrapper, to: RenderBoxModelObjectWrapper,
    beforeChild: RenderObjectWrapper?, normalizeAfterInsertion: NormalizeAfterInsertion
  ) {
    moveChildren(
      from: from, to: to, startChild: from.firstChild(), endChild: nil, beforeChild: beforeChild,
      normalizeAfterInsertion: normalizeAfterInsertion)
  }

  func removeFloatingObjects(renderer: RenderBlockWrapper) {
    if renderer.renderTreeBeingDestroyed() {
      return
    }

    let blockFlow = renderer as? RenderBlockFlowWrapper
    if blockFlow == nil {
      return
    }

    let floatingObjects = blockFlow!.floatingObjectSet()
    if floatingObjects == nil {
      return
    }
    // Here we remove the floating objects from the descendants as well.
    for floatingObject in floatingObjects! {
      floatingObject.renderer!.removeFloatingOrPositionedChildFromBlockLists()
    }
  }

  func createAnonymousWrappersForInlineContent(
    parent: RenderBlockWrapper, insertionPoint: RenderObjectWrapper? = nil
  ) {
    // makeChildrenNonInline takes a block whose children are *all* inline and it
    // makes sure that inline children are coalesced under anonymous
    // blocks. If |insertionPoint| is defined, then it represents the insertion point for
    // the new block child that is causing us to have to wrap all the inlines. This
    // means that we cannot coalesce inlines before |insertionPoint| with inlines following
    // |insertionPoint|, because the new child is going to be inserted in between the inlines,
    // splitting them.
    assert(parent.isInlineBlockOrInlineTable() || !parent.isInline())
    assert(insertionPoint == nil || CPtrToInt(insertionPoint!.parent()?.p) == CPtrToInt(parent.p))

    parent.setChildrenInline(b: false)

    var child = parent.firstChild()
    if child == nil {
      return
    }

    parent.deleteLines()

    while child != nil {
      let (inlineRunStart, inlineRunEnd) = getInlineRun(start: child, boundary: insertionPoint)

      if inlineRunStart == nil {
        break
      }

      child = inlineRunEnd!.nextSibling()

      let block = parent.createAnonymousBlock()!
      attachToRenderElementInternal(parent: parent, child: block, beforeChild: inlineRunStart)
      moveChildren(
        from: parent, to: block, startChild: inlineRunStart, endChild: child,
        normalizeAfterInsertion: .No)
    }
    var c = parent.firstChild()
    while c != nil {
      assert(!c!.isInline())
      c = c!.nextSibling()
    }
    parent.repaint()
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
  let tableBuilder: Table
  let rubyBuilder: Ruby
  private let formControlsBuilder: FormControls
  private let blockBuilder: Block
  private let blockFlowBuilder: BlockFlow
  private let inlineBuilder: Inline
  private let svgBuilder: SVG
  private let continuationBuilder: Continuation
  private var internalMovesType: IsInternalMove = .No
  private var tearDownType: TearDownType = .Root
  private let subtreeDestroyRoot: RenderElementWrapper? = nil
  let anonymousDestroyRoot: RenderObjectWrapper? = nil
}
