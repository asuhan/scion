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

  enum WillBeDestroyed {
    case No
    case Yes
  }

  enum CanCollapseAnonymousBlock {
    case No
    case Yes
  }

  func detach(
    parent: RenderElementWrapper, child: RenderObjectWrapper, willBeDestroyed: WillBeDestroyed,
    canCollapseAnonymousBlock: CanCollapseAnonymousBlock = .Yes
  ) -> RenderObjectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func destroy(
    renderer: RenderObjectWrapper, canCollapseAnonymousBlock: CanCollapseAnonymousBlock = .Yes
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func attachInternal(
    parent: RenderElementWrapper, child: RenderObjectWrapper?, beforeChild: RenderObjectWrapper?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func reportVisuallyNonEmptyContent(
    parent: RenderElementWrapper, child: RenderObjectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let view: RenderViewWrapper

  private let firstLetterBuilder: FirstLetter
  private let listBuilder: List
  private let multiColumnBuilder: MultiColumn
  private let svgBuilder: SVG
}
