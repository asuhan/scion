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

  private func detachFromRenderElement(
    parent: RenderElementWrapper, child: RenderObjectWrapper, willBeDestroyed: WillBeDestroyed
  ) -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
  private let multiColumnBuilder: MultiColumn
  private let formControlsBuilder: FormControls
  private let blockBuilder: Block
  private let svgBuilder: SVG
}
