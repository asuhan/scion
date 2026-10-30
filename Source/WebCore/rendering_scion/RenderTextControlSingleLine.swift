/**
 * Copyright (C) 2006-2023 Apple Inc. All rights reserved.
 *           (C) 2008 Torch Mobile Inc. All rights reserved. (http://www.torchmobile.com/)
 * Copyright (C) 2010-2014 Google Inc. All rights reserved.
 * Copyright (C) 2010 Nokia Corporation and/or its subsidiary(-ies).
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
 *
 */

private func resetOverriddenHeight(_ box: RenderBoxWrapper?, _ ancestor: RenderObjectWrapper?) {
  assert(CPtrToInt(box?.id()) != CPtrToInt(ancestor?.id()))
  if box == nil || box!.style().logicalHeight().isAuto() {
    return  // Null box or its height was not overridden.
  }
  box!.mutableStyle().setLogicalHeight(LengthWrapper(type: .Auto))
  var renderer: RenderObjectWrapper? = box
  while CPtrToInt(renderer?.id()) != CPtrToInt(ancestor?.id()) {
    assert(renderer == nil)
    renderer!.setNeedsLayout(markParents: .MarkOnlyThis)
    renderer = renderer!.parent()
  }
}

class RenderTextControlSingleLineWrapper: RenderTextControlWrapper {
  init(type: `Type`, element: HTMLInputElementWrapper, style: RenderStyleWrapper) {
    super.init(type: type, element: element, style: style)
    assert(isRenderTextControlSingleLine())
  }

  override init(p: UnsafeMutableRawPointer) { super.init(p: p) }

  private func containerElement() -> HTMLElementWrapper? {
    assert(isNativeImpl())
    return inputElement().containerElement()
  }

  private func innerBlockElement() -> HTMLElementWrapper? {
    assert(isNativeImpl())
    return inputElement().innerBlockElement()
  }

  private func inputElement() -> HTMLInputElementWrapper {
    assert(isNativeImpl())
    return textFormControlElement() as! HTMLInputElementWrapper
  }

  override func hasControlClip() -> Bool {
    assert(isNativeImpl())
    let shouldClipInnerContent = { [self] () -> Bool in
      // Apply control clip for text fields with decorations.
      var innerRenderBox: RenderBoxWrapper? = nil
      if let containerElement = inputElement().containerElement() {
        innerRenderBox = containerElement.renderBox()
      }

      if innerRenderBox == nil, let placeholderElement = inputElement().placeholderElement() {
        innerRenderBox = placeholderElement.renderBox()
      }

      if innerRenderBox == nil, let innerTextElement = inputElement().innerTextElement() {
        innerRenderBox = innerTextElement.renderBox()
      }

      return innerRenderBox != nil
    }
    return shouldClipInnerContent()
  }

  override func controlClipRect(additionalOffset: LayoutPointWrapper) -> LayoutRectWrapper {
    assert(isNativeImpl())
    assert(hasControlClip())
    var clipRect = paddingBoxRect()
    if let containerElementRenderer = containerElement()?.renderBox() {
      clipRect = unionRect(a: clipRect, b: containerElementRenderer.frameRect())
    }
    clipRect.moveBy(offset: additionalOffset)
    return clipRect
  }

  override func layout() {
    // TODO(asuhan): add stack stats

    // FIXME: We should remove the height-related hacks in layout() and
    // styleDidChange(). We need them because we want to:
    // - Center the inner elements vertically if the input height is taller than
    //   the intrinsic height of the inner elements.
    // - Shrink the heights of the inner elements if the input height is smaller
    //   than the intrinsic heights of the inner elements.
    // - Make the height of the container element equal to the intrinsic height of
    //   the inner elements when the field has a strong password button.
    //
    // We don't honor padding and borders for textfields without decorations
    // and type=search if the text height is taller than the contentHeight()
    // because of compability.

    let innerTextRenderer = innerTextElement()?.renderer()
    let innerBlockRenderer = innerBlockElement()?.renderBox()
    let container = containerElement()
    let containerRenderer = container?.renderBox()

    // To ensure consistency between layouts, we need to reset any conditionally overridden height.
    resetOverriddenHeight(innerTextRenderer, self)
    resetOverriddenHeight(innerBlockRenderer, self)
    resetOverriddenHeight(containerRenderer, self)

    // Save the old size of the inner text (if we have one) as we will need to layout the placeholder
    // and update selection if it changes. One way the size may change is if text decorations are
    // toggled. For example, hiding and showing the caps lock indicator will cause a size change.
    let oldInnerTextSize = innerTextRenderer?.size() ?? LayoutSizeWrapper()

    super.layoutBlock(relayoutChildren: false)

    // Set the text block height
    let inputContentBoxLogicalHeight = logicalHeight() - borderAndPaddingLogicalHeight()
    let logicalHeightLimit = logicalHeight()
    var innerTextLogicalHeight = innerTextRenderer?.logicalHeight() ?? LayoutUnit()

    let shrinkInnerTextRendererIfNeeded = { [self] () in
      if innerTextRenderer == nil || innerTextLogicalHeight <= logicalHeightLimit {
        return
      }
      // Let the simple (non-container based) inner text overflow (and clip) to be able to center it.
      if containerRenderer == nil {
        return
      }

      if inputContentBoxLogicalHeight != innerTextLogicalHeight {
        setNeedsLayout(markParents: .MarkOnlyThis)
      }

      innerTextRenderer!.mutableStyle().setLogicalHeight(
        LengthWrapper(value: inputContentBoxLogicalHeight, type: .Fixed))
      innerTextRenderer!.setNeedsLayout(markParents: .MarkOnlyThis)
      if innerBlockRenderer != nil {
        innerBlockRenderer!.mutableStyle().setLogicalHeight(
          LengthWrapper(value: inputContentBoxLogicalHeight, type: .Fixed))
        innerBlockRenderer!.setNeedsLayout(markParents: .MarkOnlyThis)
      }
      innerTextLogicalHeight = inputContentBoxLogicalHeight
    }
    shrinkInnerTextRendererIfNeeded()

    // The container might be taller because of decoration elements.
    var oldContainerLogicalTop = LayoutUnit()
    if containerRenderer != nil {
      containerRenderer!.layoutIfNeeded()
      oldContainerLogicalTop = containerRenderer!.logicalTop()
      let containerLogicalHeight = containerRenderer!.logicalHeight()

      let autoFillStrongPasswordButtonRenderer = { () -> RenderBoxWrapper? in
        if !inputElement().hasAutoFillStrongPasswordButton() {
          return nil
        }

        return inputElement().autoFillButtonElement()?.renderBox()
      }()

      if autoFillStrongPasswordButtonRenderer != nil && innerTextRenderer != nil
        && innerBlockRenderer != nil
      {
        var newContainerHeight = innerTextLogicalHeight

        // Don't expand the container height if the AutoFill button is wrapped onto a new line.
        if autoFillStrongPasswordButtonRenderer!.logicalTop() < innerBlockRenderer!.logicalBottom()
        {
          newContainerHeight = max(
            newContainerHeight, autoFillStrongPasswordButtonRenderer!.logicalHeight())
        }

        containerRenderer!.mutableStyle().setLogicalHeight(
          LengthWrapper(value: newContainerHeight, type: .Fixed))
        setNeedsLayout(markParents: .MarkOnlyThis)
      } else if containerLogicalHeight > logicalHeightLimit {
        containerRenderer!.mutableStyle().setLogicalHeight(
          LengthWrapper(value: logicalHeightLimit, type: .Fixed))
        setNeedsLayout(markParents: .MarkOnlyThis)
      } else if containerRenderer!.logicalHeight() < contentLogicalHeight() {
        containerRenderer!.mutableStyle().setLogicalHeight(
          LengthWrapper(value: contentLogicalHeight(), type: .Fixed))
        setNeedsLayout(markParents: .MarkOnlyThis)
      } else {
        containerRenderer!.mutableStyle().setLogicalHeight(
          LengthWrapper(value: containerLogicalHeight, type: .Fixed))
      }
    }

    // If we need another layout pass, we have changed one of children's height so we need to relayout them.
    if needsLayout() {
      super.layoutBlock(relayoutChildren: true)
    }

    // Fix up the y-position of the container as it may have been flexed when the strong password or strong
    // confirmation password button wraps to the next line.
    if inputElement().hasAutoFillStrongPasswordButton() && containerRenderer != nil {
      containerRenderer!.setLogicalTop(top: oldContainerLogicalTop)
    }

    // Center the child block in the block progression direction (vertical centering for horizontal text fields).
    let centerRendererIfNeeded = { [self] (renderer: RenderBoxWrapper) in
      let height = { () in
        if let blockFlow = renderer as? RenderBlockFlowWrapper {
          let lineBox = InlineIterator.firstLineBoxFor(flow: blockFlow)
          if lineBox.bool() {
            return LayoutUnit(
              value: max(lineBox.get().logicalHeight(), lineBox.get().contentLogicalHeight()))
          }
        }
        return renderer.logicalHeight()
      }()
      let contentBoxHeight = contentLogicalHeight()
      if contentBoxHeight == height {
        return
      }
      renderer.setLogicalTop(top: renderer.logicalTop() + (contentBoxHeight / 2 - height / 2))
    }
    if container == nil && innerTextRenderer != nil {
      centerRendererIfNeeded(innerTextRenderer!)
    } else if container != nil && containerRenderer != nil {
      centerRendererIfNeeded(containerRenderer!)
    }

    let innerTextSizeChanged =
      innerTextRenderer != nil && innerTextRenderer!.size() != oldInnerTextSize

    let placeholderElement = inputElement().placeholderElement()
    if let placeholderBox = placeholderElement?.renderBox() {
      let innerTextWidth = innerTextRenderer?.logicalWidth() ?? LayoutUnit()
      placeholderBox.mutableStyle().setWidth(
        length: LengthWrapper(
          value: innerTextWidth - placeholderBox.horizontalBorderAndPaddingExtent(), type: .Fixed))
      let neededLayout = placeholderBox.needsLayout()
      let placeholderBoxHadLayout = placeholderBox.everHadLayout()
      if innerTextSizeChanged {
        // The caps lock indicator was hidden. Layout the placeholder. Its layout does not affect its parent.
        placeholderBox.setChildNeedsLayout(markParents: .MarkOnlyThis)
      }
      placeholderBox.layoutIfNeeded()
      var placeholderTopLeft = containerRenderer?.location() ?? LayoutPointWrapper()
      let innerBlockRenderer = innerBlockElement()?.renderBox()
      if innerBlockRenderer != nil {
        placeholderTopLeft += toLayoutSize(point: innerBlockRenderer!.location())
      }
      if innerTextRenderer != nil {
        placeholderTopLeft += toLayoutSize(point: innerTextRenderer!.location())
      }
      placeholderBox.setLogicalLeft(left: placeholderTopLeft.x)
      // Here the container box indicates the renderer that the placeholder content is aligned with (no parent and/or containing block relationship).
      if let containerBox = innerTextRenderer != nil
        ? innerTextRenderer : innerBlockRenderer != nil ? innerBlockRenderer : containerRenderer
      {
        let placeholderHeight = { () in
          if let blockFlow = placeholderBox as? RenderBlockFlowWrapper {
            let placeholderLineBox = InlineIterator.firstLineBoxFor(flow: blockFlow)
            if placeholderLineBox.bool() {
              return LayoutUnit(
                value: max(
                  placeholderLineBox.get().logicalHeight(),
                  placeholderLineBox.get().contentLogicalHeight()))
            }
          }
          return placeholderBox.logicalHeight()
        }
        // Center vertical align the placeholder content.
        let logicalTop =
          placeholderTopLeft.y + (containerBox.logicalHeight() / 2 - placeholderHeight() / 2)
        placeholderBox.setLogicalTop(top: logicalTop)
      }
      if !placeholderBoxHadLayout && placeholderBox.checkForRepaintDuringLayout() {
        // This assumes a shadow tree without floats. If floats are added, the
        // logic should be shared with RenderBlock::layoutBlockChild.
        placeholderBox.repaint()
      }
      // The placeholder gets layout last, after the parent text control and its other children,
      // so in order to get the correct overflow from the placeholder we need to recompute it now.
      if neededLayout {
        computeOverflow(oldClientAfterEdge: clientLogicalBottom())
      }
    }

    // TODO(asuhan): handle search field border radius adjustment for iOS

    if innerTextSizeChanged && frame().selection().isFocusedAndActive()
      && CPtrToInt(document().focusedElement()?.p) == CPtrToInt(inputElement().p)
    {
      // The caps lock indicator was hidden or shown. If it is now visible then it may be occluding
      // the current selection (say, the caret was after the last character in the text field).
      // Schedule an update and reveal of the current selection.
      frame().selection().setNeedsSelectionUpdate(revealMode: .Forced)
    }
  }

  override func nodeAtPoint(
    _ request: HitTestRequestWrapper, _ result: inout HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ hitTestAction: HitTestAction
  ) -> Bool {
    if !super.nodeAtPoint(request, &result, locationInContainer, accumulatedOffset, hitTestAction) {
      return false
    }

    // Say that we hit the inner text element if
    //  - we hit a node inside the inner text element,
    //  - we hit the <input> element (e.g. we're over the border or padding), or
    //  - we hit regions not in any decoration buttons.
    let container = containerElement()
    if result.innerNode()!.isDescendantOf(innerTextElement())
      || optEq(result.innerNode(), inputElement())
      || (container != nil && optEq(container, result.innerNode()))
    {
      var pointInParent = locationInContainer.point()
      if container != nil && innerBlockElement() != nil {
        if innerBlockElement()!.renderBox() != nil {
          pointInParent -= toLayoutSize(point: innerBlockElement()!.renderBox()!.location())
        }
        if container!.renderBox() != nil {
          pointInParent -= toLayoutSize(point: container!.renderBox()!.location())
        }
      }
      hitInnerTextElement(&result, pointInParent, accumulatedOffset)
    }
    return true
  }

  override final func scrollWidth() -> Int32 {
    assert(isNativeImpl())
    if let innerTextRenderer = innerTextElement()?.renderer() {
      // Adjust scrollWidth to include input element horizontal paddings and decoration width.
      let adjustment = clientWidth() - innerTextRenderer.clientWidth()
      return (innerTextRenderer.scrollWidth() + adjustment).int()
    }
    return super.scrollWidth()
  }

  override final func scrollHeight() -> Int32 {
    assert(isNativeImpl())
    if let innerTextRenderer = innerTextElement()?.renderer() {
      // Adjust scrollHeight to include input element vertical paddings and decoration height.
      let adjustment = clientHeight() - innerTextRenderer.clientHeight()
      return (innerTextRenderer.scrollHeight() + adjustment).int()
    }
    return super.scrollHeight()
  }

  override final func getAverageCharWidth() -> Float32 {
    assert(isNativeImpl())
    // TODO(asuhan): add iOS support
    // Since Lucida Grande is the default font, we want this to match the width
    // of MS Shell Dlg, the default font for textareas in Firefox, Safari Win and
    // IE for some encodings (in IE, the default font is encoding specific).
    // 901 is the avgCharWidth value in the OS/2 table for MS Shell Dlg.
    if style().fontCascade().firstFamily().string() == StringWrapper(ASCIILiteral("Lucida Grande"))
    {
      return scaleEmToUnits(901)
    }

    return super.getAverageCharWidth()
  }

  override final func preferredContentLogicalWidth(_ charWidth: Float32) -> LayoutUnit {
    assert(isNativeImpl())
    var factor: Int32 = 0
    let includesDecoration = inputElement().sizeShouldIncludeDecoration(&factor)
    if factor <= 0 {
      factor = 20
    }

    var result = LayoutUnit.fromFloatCeil(value: charWidth * Float32(factor))

    var maxCharWidth: Float32 = 0

    // TODO(asuhan): add iOS support
    let family = style().fontCascade().firstFamily()
    // Since Lucida Grande is the default font, we want this to match the width
    // of MS Shell Dlg, the default font for textareas in Firefox, Safari Win and
    // IE for some encodings (in IE, the default font is encoding specific).
    // 4027 is the (xMax - xMin) value in the "head" font table for MS Shell Dlg.
    if family.string() == StringWrapper(ASCIILiteral("Lucida Grande")) {
      maxCharWidth = scaleEmToUnits(4027)
    } else if style().fontCascade().hasValidAverageCharWidth() {
      maxCharWidth = style().fontCascade().primaryFont().maxCharWidth().rounded()
    }

    // For text inputs, IE adds some extra width.
    if maxCharWidth > 0 {
      result += LayoutUnit(value: maxCharWidth - charWidth)
    }

    if includesDecoration {
      result += LayoutUnit(value: inputElement().decorationWidth())
    }

    if let innerRenderer = innerTextElement()?.renderer() {
      result += innerRenderer.endPaddingWidthForCaret()
    }

    return result
  }

  override func computeControlLogicalHeight(
    lineHeight: LayoutUnit, nonContentHeight: LayoutUnit
  )
    -> LayoutUnit
  {
    assert(isNativeImpl())
    return lineHeight + nonContentHeight
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)

    // We may have set the width and the height in the old style in layout().
    // Reset them now to avoid getting a spurious layout hint.
    let innerBlock = innerBlockElement()
    if let innerBlockRenderer = innerBlock?.containerRenderer() {
      innerBlockRenderer.mutableStyle().setHeight(length: LengthWrapper())
      innerBlockRenderer.mutableStyle().setWidth(length: LengthWrapper())
    }
    let container = containerElement()
    if let containerRenderer = container?.containerRenderer() {
      containerRenderer.mutableStyle().setHeight(length: LengthWrapper())
      containerRenderer.mutableStyle().setWidth(length: LengthWrapper())
    }
    if diff == .Layout {
      if let innerTextRenderer = innerTextElement()!.renderer() {
        innerTextRenderer.setNeedsLayout(markParents: .MarkContainingBlockChain)
      }
      if let placeholder = inputElement().placeholderElement(), placeholder.renderer() != nil {
        placeholder.renderer()!.setNeedsLayout(markParents: .MarkContainingBlockChain)
      }
    }
    setHasNonVisibleOverflow(false)
  }
}

final class RenderTextControlInnerBlockWrapper: RenderBlockFlowWrapper {
  init(_ element: ElementWrapper, _ style: RenderStyleWrapper) {
    super.init(type: .TextControlInnerBlock, element: element, style: style)
    assert(isRenderTextControlInnerBlock())
  }

  override init(p: UnsafeMutableRawPointer) { super.init(p: p) }

  override func hasLineIfEmpty() -> Bool {
    assert(isNativeImpl())
    return true
  }

  override final func canBeProgramaticallyScrolled() -> Bool {
    assert(isNativeImpl())
    if let shadowHost = element()!.shadowHost() as? HTMLInputElementWrapper {
      return !shadowHost.hasAutoFillStrongPasswordButton()
    }
    return true
  }
}
