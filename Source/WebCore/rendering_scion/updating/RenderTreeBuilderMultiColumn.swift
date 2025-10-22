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
      // TODO(asuhan): implement this
      fatalError("Not implemented")
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
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func multiColumnDescendantInserted(
      flow: RenderMultiColumnFlowWrapper, newDescendant: RenderObjectWrapper
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func multiColumnRelativeWillBeRemoved(
      flow: RenderMultiColumnFlowWrapper, relative: RenderObjectWrapper,
      canCollapseAnonymousBlock: RenderTreeBuilder.CanCollapseAnonymousBlock
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    static func adjustBeforeChildForMultiColumnSpannerIfNeeded(beforeChild: RenderObjectWrapper)
      -> RenderObjectWrapper
    {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func createFragmentedFlow(flow: RenderBlockWrapper) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private func destroyFragmentedFlow(flow: RenderBlockWrapper) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }
}
