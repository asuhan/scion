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

    private func destroyFragmentedFlow(flow: RenderBlockWrapper) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func processPossibleSpannerDescendant(
      flow: RenderMultiColumnFlowWrapper, subtreeRoot: inout RenderObjectWrapper?,
      descendant: RenderObjectWrapper
    ) -> RenderObjectWrapper? {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func handleSpannerRemoval(
      flow: RenderMultiColumnFlowWrapper, spanner: RenderObjectWrapper,
      canCollapseAnonymousBlock: RenderTreeBuilder.CanCollapseAnonymousBlock
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private let builder: RenderTreeBuilder

    private static var gRestoringColumnSpannersForContainer = false
    private static var gShiftingSpanner = false
  }
}
