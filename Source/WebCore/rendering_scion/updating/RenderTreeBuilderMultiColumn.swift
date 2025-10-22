/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 *           (C) 2007 David Smith (catfish.man@gmail.com)
 * Copyright (C) 2003-2015, 2017 Apple Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

private func findSetRendering(
  fragmentedFlow: RenderMultiColumnFlowWrapper, renderer: RenderObjectWrapper
) -> RenderMultiColumnSetWrapper? {
  // Find the set inside which the specified renderer would be rendered.
  var multicolSet = fragmentedFlow.firstMultiColumnSet()
  while multicolSet != nil {
    if multicolSet!.containsRendererInFragmentedFlow(renderer: renderer) {
      return multicolSet
    }
    multicolSet = multicolSet!.nextSiblingMultiColumnSet()
  }
  return nil
}

private func spannerPlaceholderCandidate(
  renderer: RenderObjectWrapper, stayWithin: RenderMultiColumnFlowWrapper
) -> RenderObjectWrapper? {
  // Spanner candidate is a next sibling/ancestor's next child within the flow thread and
  // it is in the same inflow/out-of-flow layout context.
  if renderer.isOutOfFlowPositioned() {
    return nil
  }

  assert(renderer.isDescendantOf(ancestor: stayWithin))
  var current: RenderObjectWrapper? = renderer
  while true {
    // Skip to the first in-flow sibling.
    var nextSibling = current!.nextSibling()
    while nextSibling != nil && nextSibling!.isOutOfFlowPositioned() {
      nextSibling = nextSibling!.nextSibling()
    }
    if nextSibling != nil {
      return nextSibling
    }
    // No sibling candidate, jump to the parent and check its siblings.
    current = current!.parent()
    if current == nil || CPtrToInt(current?.p) == CPtrToInt(stayWithin.p)
      || current!.isOutOfFlowPositioned()
    {
      return nil
    }
  }
}

private func isValidColumnSpanner(
  fragmentedFlow: RenderMultiColumnFlowWrapper, descendant: RenderObjectWrapper
) -> Bool {
  // We assume that we're inside the flow thread. This function is not to be called otherwise.
  assert(descendant.isDescendantOf(ancestor: fragmentedFlow))
  // First make sure that the renderer itself has the right properties for becoming a spanner.
  let descendantBox: RenderBoxWrapper? = descendant as? RenderBoxWrapper
  if descendantBox == nil {
    return false
  }

  if descendantBox!.isFloatingOrOutOfFlowPositioned() {
    return false
  }

  if descendantBox!.style().columnSpan() != .All {
    return false
  }

  let parent = descendantBox!.parent()
  if !(parent is RenderBlockFlowWrapper) || parent!.childrenInline() {
    // Needs to be block-level.
    return false
  }

  // We need to have the flow thread as the containing block. A spanner cannot break out of the flow thread.
  let enclosingFragmentedFlow = descendantBox!.enclosingFragmentedFlow()
  if CPtrToInt(enclosingFragmentedFlow?.p) != CPtrToInt(fragmentedFlow.p) {
    return false
  }

  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

extension RenderTreeBuilder {
  class MultiColumn {
    init(builder: RenderTreeBuilder) {
      self.builder = builder
    }

    func updateAfterDescendants(flow: RenderBlockFlowWrapper) {
      let needsFragmentedFlow = flow.requiresColumns(
        desiredColumnCount: Int32(flow.style().columnCount()))
      let hasFragmentedFlow = flow.multiColumnFlowForBlockFlow() != nil

      if !hasFragmentedFlow && needsFragmentedFlow {
        createFragmentedFlow(flow: flow)
        return
      }
      if hasFragmentedFlow && !needsFragmentedFlow {
        destroyFragmentedFlow(flow: flow)
        return
      }
    }

    // Some renderers (column spanners) are moved out of the flow thread to live among column
    // sets. If |child| is such a renderer, resolve it to the placeholder that lives at the original
    // location in the tree.
    func resolveMovedChild(
      enclosingFragmentedFlow: RenderFragmentedFlowWrapper, beforeChild: RenderObjectWrapper?
    ) -> RenderObjectWrapper? {
      if beforeChild == nil {
        return nil
      }

      let beforeChildRenderBox = beforeChild as? RenderBoxWrapper
      if beforeChildRenderBox == nil {
        return beforeChild
      }

      let renderMultiColumnFlow = enclosingFragmentedFlow as? RenderMultiColumnFlowWrapper

      if renderMultiColumnFlow == nil {
        return beforeChild
      }

      // We only need to resolve for column spanners.
      if beforeChild!.style().columnSpan() != .All {
        return beforeChild
      }

      // The renderer for the actual DOM node that establishes a spanner is moved from its original
      // location in the render tree to becoming a sibling of the column sets. In other words, it's
      // moved out from the flow thread (and becomes a sibling of it). When we for instance want to
      // create and insert a renderer for the sibling node immediately preceding the spanner, we need
      // to map that spanner renderer to the spanner's placeholder, which is where the new inserted
      // renderer belongs.
      if let placeholder = renderMultiColumnFlow!.findColumnSpannerPlaceholder(
        spanner: beforeChildRenderBox)
      {
        return placeholder
      }

      // This is an invalid spanner, or its placeholder hasn't been created yet. This happens when
      // moving an entire subtree into the flow thread, when we are processing the insertion of this
      // spanner's preceding sibling, and we obviously haven't got as far as processing this spanner
      // yet.
      return beforeChild
    }

    func restoreColumnSpannersForContainer(
      container: RenderElementWrapper, multiColumnFlow: RenderMultiColumnFlowWrapper
    ) {
      let spanners = multiColumnFlow.spannerMap
      var placeholdersToRestore: [RenderMultiColumnSpannerPlaceholderWrapper] = []
      for spannerAndPlaceholder in spanners {
        let placeholder = spannerAndPlaceholder.value
        if !placeholder.isDescendantOf(ancestor: container) {
          continue
        }
        placeholdersToRestore.append(placeholder)
      }
      for placeholder in placeholdersToRestore {
        let spanner = placeholder.spanner()
        if spanner == nil {
          fatalError("Not reached")
        }
        // Move the spanner back to its original position.
        let spannerOriginalParent = placeholder.parent()!
        // Detaching the spanner takes care of removing the placeholder (and merges the RenderMultiColumnSets).
        let spannerToReInsert = builder.detach(
          parent: spanner!.parent()!, child: spanner!, willBeDestroyed: .No)
        let _ = SetForScope(
          scopedVariable: &MultiColumn.gRestoringColumnSpannersForContainer, newValue: true)
        builder.attach(parent: spannerOriginalParent, child: spannerToReInsert!)
      }
    }

    func multiColumnDescendantInserted(
      flow: RenderMultiColumnFlowWrapper, newDescendant: RenderObjectWrapper
    ) {
      if MultiColumn.gShiftingSpanner || MultiColumn.gRestoringColumnSpannersForContainer
        || newDescendant.isRenderFragmentedFlow()
      {
        return
      }

      var subtreeRoot: RenderObjectWrapper? = newDescendant
      var descendant: RenderObjectWrapper? = subtreeRoot
      while descendant != nil {
        // Skip nested multicolumn flows.
        if descendant is RenderMultiColumnFlowWrapper {
          descendant = descendant!.nextSibling()
          continue
        }
        if let placeholder = descendant as? RenderMultiColumnSpannerPlaceholderWrapper {
          // A spanner's placeholder has been inserted. The actual spanner renderer is moved from
          // where it would otherwise occur (if it weren't a spanner) to becoming a sibling of the
          // column sets.
          assert(flow.spannerMap[CPtrToInt(placeholder.spanner()?.p)] == nil)
          flow.spannerMap.updateValue(placeholder, forKey: CPtrToInt(placeholder.spanner()?.p))
          assert(placeholder.firstChild() == nil)  // There should be no children here, but if there are, we ought to skip them.
        } else {
          descendant = processPossibleSpannerDescendant(
            flow: flow, subtreeRoot: &subtreeRoot, descendant: descendant!)
        }
        if descendant != nil {
          descendant = descendant!.nextInPreOrder(stayWithin: subtreeRoot)
        }
      }
    }

    func multiColumnRelativeWillBeRemoved(
      flow: RenderMultiColumnFlowWrapper, relative: RenderObjectWrapper,
      canCollapseAnonymousBlock: RenderTreeBuilder.CanCollapseAnonymousBlock
    ) {
      flow.invalidateFragments()
      if let placeholder = relative as? RenderMultiColumnSpannerPlaceholderWrapper {
        // Remove the map entry for this spanner, but leave the actual spanner renderer alone. Also
        // keep the reference to the spanner, since the placeholder may be about to be re-inserted
        // in the tree.
        assert(relative.isDescendantOf(ancestor: flow))
        flow.spannerMap.removeValue(forKey: CPtrToInt(placeholder.spanner()?.p))
        return
      }
      if relative.style().columnSpan() == .All {
        if CPtrToInt(relative.parent()?.p) != CPtrToInt(flow.parent()?.p) {
          return  // not a valid spanner.
        }

        handleSpannerRemoval(
          flow: flow, spanner: relative, canCollapseAnonymousBlock: canCollapseAnonymousBlock)
      }
      // Note that we might end up with empty column sets if all column content is removed. That's no
      // big deal though (and locating them would be expensive), and they will be found and re-used if
      // content is added again later.
    }

    static func adjustBeforeChildForMultiColumnSpannerIfNeeded(beforeChild: RenderObjectWrapper)
      -> RenderObjectWrapper
    {
      let beforeChildBox = beforeChild as? RenderBoxWrapper
      if beforeChildBox == nil {
        return beforeChild
      }

      let nextSibling = beforeChildBox!.nextSibling()
      if nextSibling == nil {
        return beforeChild
      }

      let renderMultiColumnSet = nextSibling as? RenderMultiColumnSetWrapper
      if renderMultiColumnSet == nil {
        return beforeChild
      }

      let multiColumnFlow = renderMultiColumnSet!.multiColumnFlowForMultiColumnSet()
      if multiColumnFlow == nil {
        return beforeChild
      }

      return multiColumnFlow!.findColumnSpannerPlaceholder(spanner: beforeChildBox)!
    }

    private func createFragmentedFlow(flow: RenderBlockFlowWrapper) {
      flow.setChildrenInline(b: false)  // Do this to avoid wrapping inline children that are just going to move into the flow thread.
      flow.deleteLines()
      // If this soon-to-be multicolumn flow is already part of a multicolumn context, we need to move back the descendant spanners
      // to their original position before moving subtrees around.
      if let enclosingflow = flow.enclosingFragmentedFlow() as? RenderMultiColumnFlowWrapper {
        restoreColumnSpannersForContainer(container: flow, multiColumnFlow: enclosingflow)
      }

      let fragmentedFlow = CreateRenderer.RenderMultiColumnFlow(
        document: flow.document(),
        style: RenderStyleWrapper.createAnonymousStyleWithDisplay(
          parentStyle: flow.style(), display: .Block))
      fragmentedFlow.initializeStyle()
      builder.blockBuilder!.attach(parent: flow, child: fragmentedFlow, beforeChild: nil)

      // Reparent children preceding the fragmented flow into the fragmented flow.
      builder.moveChildren(
        from: flow, to: fragmentedFlow, startChild: flow.firstChild(), endChild: fragmentedFlow,
        normalizeAfterInsertion: .Yes)
      if flow.isFieldset() {
        // Keep legends out of the flow thread.
        for box: RenderBoxWrapper in childrenOfType(parent: fragmentedFlow) {
          if box.isLegend() {
            builder.move(from: fragmentedFlow, to: flow, child: box, normalizeAfterInsertion: .Yes)
          }
        }
      }

      flow.setMultiColumnFlow(fragmentedFlow: fragmentedFlow)
    }

    private func destroyFragmentedFlow(flow: RenderBlockFlowWrapper) {
      let multiColumnFlow = flow.multiColumnFlowForBlockFlow()!
      multiColumnFlow.deleteLines()

      // Move spanners back to their original DOM position in the tree, and destroy the placeholders.
      let spanners = multiColumnFlow.spannerMap
      var placeholdersToDelete: [RenderMultiColumnSpannerPlaceholderWrapper] = []
      for spannerAndPlaceholder in spanners {
        placeholdersToDelete.append(spannerAndPlaceholder.value)
      }
      var parentAndSpannerList: [(RenderElementWrapper, RenderObjectWrapper)] = []
      for placeholder in placeholdersToDelete {
        var spannerOriginalParent = placeholder.parent()
        if CPtrToInt(spannerOriginalParent?.p) == CPtrToInt(multiColumnFlow.p) {
          spannerOriginalParent = flow
        }
        // Detaching the spanner takes care of removing the placeholder (and merges the RenderMultiColumnSets).
        let spanner = placeholder.spanner()
        parentAndSpannerList.append(
          (
            spannerOriginalParent!,
            builder.detach(
              parent: spanner!.parent()!, child: spanner!, willBeDestroyed: .No,
              canCollapseAnonymousBlock: .No)!
          ))
      }
      var columnSet = multiColumnFlow.firstMultiColumnSet()
      while columnSet != nil {
        builder.destroy(renderer: columnSet!)
        columnSet = multiColumnFlow.firstMultiColumnSet()
      }

      flow.clearMultiColumnFlow()
      let hasInitialBlockChild = MultiColumn.hasInitialBlockChild(flow: flow)
      flow.setChildrenInline(b: !hasInitialBlockChild)
      builder.moveAllChildren(from: multiColumnFlow, to: flow, normalizeAfterInsertion: .Yes)
      builder.destroy(renderer: multiColumnFlow)
      for (parent, spanner) in parentAndSpannerList {
        builder.attach(parent: parent, child: spanner)
      }
    }

    private static func hasInitialBlockChild(flow: RenderBlockFlowWrapper) -> Bool {
      if !flow.isFieldset() {
        return false
      }
      // We don't move the legend under the multicolumn flow (see MultiColumn::createFragmentedFlow), so when the multicolumn context is destroyed
      // the fieldset already has a legend block level box.
      for box: RenderBoxWrapper in childrenOfType(parent: flow) {
        if box.isLegend() {
          return true
        }
      }
      return false
    }

    func processPossibleSpannerDescendant(
      flow: RenderMultiColumnFlowWrapper, subtreeRoot: inout RenderObjectWrapper?,
      descendant: RenderObjectWrapper
    ) -> RenderObjectWrapper? {
      let multicolContainer = flow.multiColumnBlockFlow()
      let nextRendererInFragmentedFlow = spannerPlaceholderCandidate(
        renderer: descendant, stayWithin: flow)
      var insertBeforeMulticolChild: RenderObjectWrapper? = nil
      var nextDescendant: RenderObjectWrapper? = descendant

      if multicolContainer == nil {
        return nil
      }

      if isValidColumnSpanner(fragmentedFlow: flow, descendant: descendant) {
        // This is a spanner (column-span:all). Such renderers are moved from where they would
        // otherwise occur in the render tree to becoming a direct child of the multicol container,
        // so that they live among the column sets. This simplifies the layout implementation, and
        // basically just relies on regular block layout done by the RenderBlockFlow that
        // establishes the multicol container.
        let container = descendant.parent() as! RenderBlockFlowWrapper
        var setToSplit: RenderMultiColumnSetWrapper? = nil
        if nextRendererInFragmentedFlow != nil {
          setToSplit = findSetRendering(fragmentedFlow: flow, renderer: descendant)
          if setToSplit != nil {
            setToSplit!.setNeedsLayout()
            insertBeforeMulticolChild = setToSplit!.nextSibling()
          }
        }
        // Moving a spanner's renderer so that it becomes a sibling of the column sets requires us
        // to insert an anonymous placeholder in the tree where the spanner's renderer otherwise
        // would have been. This is needed for a two reasons: We need a way of separating inline
        // content before and after the spanner, so that it becomes separate line boxes. Secondly,
        // this placeholder serves as a break point for column sets, so that, when encountered, we
        // end flowing one column set and move to the next one.
        let placeholder = RenderMultiColumnSpannerPlaceholderWrapper.createAnonymous(
          fragmentedFlow: flow, spanner: descendant as! RenderBoxWrapper,
          parentStyle: container.style())
        builder.attach(parent: container, child: placeholder, beforeChild: descendant.nextSibling())
        let takenDescendant = builder.detach(
          parent: container, child: descendant, willBeDestroyed: .No)

        // This is a guard to stop an ancestor flow thread from processing the spanner.
        let _ = SetForScope(scopedVariable: &MultiColumn.gShiftingSpanner, newValue: true)
        builder.blockBuilder!.attach(
          parent: multicolContainer!, child: takenDescendant!,
          beforeChild: insertBeforeMulticolChild
        )

        // The spanner has now been moved out from the flow thread, but we don't want to
        // examine its children anyway. They are all part of the spanner and shouldn't trigger
        // creation of column sets or anything like that. Continue at its original position in
        // the tree, i.e. where the placeholder was just put.
        if CPtrToInt(subtreeRoot?.p) == CPtrToInt(descendant.p) {
          subtreeRoot = placeholder
        }
        nextDescendant = placeholder
      } else {
        // This is regular multicol content, i.e. not part of a spanner.
        if let placeholder = nextRendererInFragmentedFlow
          as? RenderMultiColumnSpannerPlaceholderWrapper
        {
          // Inserted right before a spanner. Is there a set for us there?
          if let previous = placeholder.spanner()!.previousSibling() {
            if previous is RenderMultiColumnSetWrapper {
              return nextDescendant  // There's already a set there. Nothing to do.
            }
          }
          insertBeforeMulticolChild = placeholder.spanner()
        } else if let lastSet = flow.lastMultiColumnSet() {
          // This child is not an immediate predecessor of a spanner, which means that if this
          // child precedes a spanner at all, there has to be a column set created for us there
          // already. If it doesn't precede any spanner at all, on the other hand, we need a
          // column set at the end of the multicol container. We don't really check here if the
          // child inserted precedes any spanner or not (as that's an expensive operation). Just
          // make sure we have a column set at the end. It's no big deal if it remains unused.

          // Legends are siblings of RenderMultiColumnSets not because they are spanners, but because they don't participate in multi-column context.
          let hasMultiColumnSet = lastSet.nextSibling() == nil || lastSet.nextSibling()!.isLegend()
          if hasMultiColumnSet {
            return nextDescendant
          }
        }
      }
      // Need to create a new column set when there's no set already created. We also always insert
      // another column set after a spanner. Even if it turns out that there are no renderers
      // following the spanner, there may be bottom margins there, which take up space.
      let newSet = CreateRenderer.RenderMultiColumnSet(
        fragmentedFlow: flow,
        style: RenderStyleWrapper.createAnonymousStyleWithDisplay(
          parentStyle: multicolContainer!.style(), display: .Block))
      newSet.initializeStyle()
      builder.blockBuilder!.attach(
        parent: multicolContainer!, child: newSet, beforeChild: insertBeforeMulticolChild)
      flow.invalidateFragments()

      // We cannot handle immediate column set siblings at the moment (and there's no need for
      // it, either). There has to be at least one spanner separating them.
      assert(
        RenderMultiColumnFlowWrapper.previousColumnSetOrSpannerSiblingOf(child: newSet) == nil
          || !RenderMultiColumnFlowWrapper.previousColumnSetOrSpannerSiblingOf(child: newSet)!
            .isRenderMultiColumnSet()
      )
      assert(
        RenderMultiColumnFlowWrapper.nextColumnSetOrSpannerSiblingOf(child: newSet) == nil
          || !RenderMultiColumnFlowWrapper.nextColumnSetOrSpannerSiblingOf(child: newSet)!
            .isRenderMultiColumnSet()
      )

      return nextDescendant
    }

    private func handleSpannerRemoval(
      flow: RenderMultiColumnFlowWrapper, spanner: RenderObjectWrapper,
      canCollapseAnonymousBlock: RenderTreeBuilder.CanCollapseAnonymousBlock
    ) {
      // The placeholder may already have been removed, but if it hasn't, do so now.
      if let placeholderIndex = flow.spannerMap.index(forKey: CPtrToInt(spanner.p)) {
        let placeholder = flow.spannerMap[placeholderIndex].value
        flow.spannerMap.remove(at: placeholderIndex)
        builder.destroy(renderer: placeholder, canCollapseAnonymousBlock: canCollapseAnonymousBlock)
      }

      if let next = spanner.nextSibling(), let previous = spanner.previousSibling(),
        previous.isRenderMultiColumnSet() && next.isRenderMultiColumnSet()
      {
        // Merge two sets that no longer will be separated by a spanner.
        builder.destroy(renderer: next)
        previous.setNeedsLayout()
      }
    }

    private let builder: RenderTreeBuilder

    private static var gRestoringColumnSpannersForContainer = false
    private static var gShiftingSpanner = false
  }
}
