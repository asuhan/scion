/*
 * Copyright (C) 2021 Apple Inc. All rights reserved.
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

// This class implements positioning and sizing for boxes participating in a block formatting context.
class BlockFormattingGeometry: FormattingGeometry {
  func inFlowContentHeightAndMargin(
    layoutBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    overriddenVerticalValues: OverriddenVerticalValues
  ) -> ContentHeightAndMargin {
    assert(layoutBox.isInFlow())

    // 10.6.2 Inline replaced elements, block-level replaced elements in normal flow, 'inline-block'
    // replaced elements in normal flow and floating replaced elements
    if layoutBox.isReplacedBox() {
      return inlineReplacedContentHeightAndMargin(
        replacedBox: layoutBox, horizontalConstraints: horizontalConstraints,
        verticalConstraints: nil, overriddenVerticalValues: overriddenVerticalValues)
    }

    var contentHeightAndMargin = ContentHeightAndMargin()
    if layoutBox.isOverflowVisible() && !layoutBox.isDocumentBox() {
      // TODO: Figure out the case for the document element. Let's just complicated-case it for now.
      contentHeightAndMargin = inFlowNonReplacedContentHeightAndMargin(
        layoutBox: layoutBox, horizontalConstraints: horizontalConstraints,
        overriddenVerticalValues: overriddenVerticalValues)
    } else {
      // 10.6.6 Complicated cases
      // Block-level, non-replaced elements in normal flow when 'overflow' does not compute to 'visible' (except if the 'overflow' property's value has been propagated to the viewport).
      contentHeightAndMargin = complicatedCases(
        layoutBox: layoutBox, horizontalConstraints: horizontalConstraints,
        overriddenVerticalValues: overriddenVerticalValues)
    }

    if layoutState().inQuirksMode() {
      if let stretchedInFlowHeight = formattingContext().formattingQuirks()
        .stretchedInFlowHeightIfApplicable(
          layoutBox: layoutBox, contentHeightAndMargin: contentHeightAndMargin)
      {
        contentHeightAndMargin.contentHeight = stretchedInFlowHeight
      }
    }

    return contentHeightAndMargin
  }

  func inFlowContentWidthAndMargin(
    layoutBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    overriddenHorizontalValues: OverriddenHorizontalValues
  ) -> ContentWidthAndMargin {
    assert(layoutBox.isInFlow())

    if !layoutBox.isReplacedBox() {
      return inFlowNonReplacedContentWidthAndMargin(
        layoutBox: layoutBox, horizontalConstraints: horizontalConstraints,
        overriddenHorizontalValues: overriddenHorizontalValues)
    }
    return inFlowReplacedContentWidthAndMargin(
      replacedBox: layoutBox, horizontalConstraints: horizontalConstraints,
      overriddenHorizontalValues: overriddenHorizontalValues)
  }

  func staticVerticalPosition(
    layoutBox: ElementBoxWrapper, containingBlockContentBoxTop: LayoutUnit
  ) -> LayoutUnit {
    // https://www.w3.org/TR/CSS22/visuren.html#block-formatting
    // In a block formatting context, boxes are laid out one after the other, vertically, beginning at the top of a containing block.
    // The vertical distance between two sibling boxes is determined by the 'margin' properties.
    // Vertical margins between adjacent block-level boxes in a block formatting context collapse.
    if let previousInFlowSibling = layoutBox.previousInFlowSibling() {
      let previousInFlowBoxGeometry = formattingContext().geometryForBox(
        layoutBox: previousInFlowSibling)
      return BoxGeometry.borderBoxRect(box: previousInFlowBoxGeometry).bottom()
        + previousInFlowBoxGeometry.marginAfter()
    }
    return containingBlockContentBoxTop
  }

  func staticHorizontalPosition(
    layoutBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints
  ) -> LayoutUnit {
    // https://www.w3.org/TR/CSS22/visuren.html#block-formatting
    // In a block formatting context, each box's left outer edge touches the left edge of the containing block (for right-to-left formatting, right edges touch).
    return horizontalConstraints.logicalLeft
      + formattingContext().geometryForBox(layoutBox: layoutBox).marginStart()
  }

  func intrinsicWidthConstraints(layoutBox: ElementBoxWrapper) -> IntrinsicWidthConstraints {
    // FIXME Check for box-sizing: border-box;
    var intrinsicWidthConstraints = constrainByMinMaxWidth(
      layoutBox: layoutBox, intrinsicWidth: computedIntrinsicWidthConstraints(layoutBox: layoutBox))
    intrinsicWidthConstraints.expand(
      horizontalValue: BlockFormattingGeometry.fixedMarginBorderAndPadding(layoutBox: layoutBox))
    return intrinsicWidthConstraints
  }

  static func fixedMarginBorderAndPadding(layoutBox: ElementBoxWrapper) -> LayoutUnit {
    let style = layoutBox.style
    return
      (FormattingGeometry.fixedValue(geometryProperty: style.marginStart()) ?? LayoutUnit(value: 0))
      + LayoutUnit(value: style.borderLeftWidth())
      + (FormattingGeometry.fixedValue(geometryProperty: style.paddingLeft())
        ?? LayoutUnit(value: 0))
      + (FormattingGeometry.fixedValue(geometryProperty: style.paddingRight())
        ?? LayoutUnit(value: 0)) + LayoutUnit(value: style.borderRightWidth())
      + (FormattingGeometry.fixedValue(geometryProperty: style.marginEnd()) ?? LayoutUnit(value: 0))
  }

  func computedIntrinsicWidthConstraints(layoutBox: ElementBoxWrapper) -> IntrinsicWidthConstraints
  {
    let logicalWidth = layoutBox.style.logicalWidth()
    // Minimum/maximum width can't be depending on the containing block's width.
    let needsResolvedContainingBlockWidth =
      logicalWidth.isCalculated() || logicalWidth.isPercent() || logicalWidth.isRelative()
    if needsResolvedContainingBlockWidth {
      return IntrinsicWidthConstraints()
    }

    if let width = FormattingGeometry.fixedValue(geometryProperty: logicalWidth) {
      return IntrinsicWidthConstraints(minimum: width, maximum: width)
    }

    if layoutBox.isReplacedBox() {
      if layoutBox.hasIntrinsicWidth() {
        let replacedWidth = layoutBox.intrinsicWidth()
        return IntrinsicWidthConstraints(minimum: replacedWidth, maximum: replacedWidth)
      }
      return IntrinsicWidthConstraints()
    }

    if !layoutBox.hasInFlowOrFloatingChild() {
      return IntrinsicWidthConstraints()
    }

    if layoutBox.isSizeContainmentBox() {
      // The intrinsic sizes of the size containment box are determined as if the element had no content,
      // following the same logic as when sizing as if empty.
      return IntrinsicWidthConstraints()
    }

    let layoutState = layoutState()
    if layoutBox.establishesFormattingContext() {
      let intrinsicWidthConstraints = LayoutContext.createFormattingContext(
        formattingContextRoot: layoutBox, layoutState: layoutState
      )
      .computedIntrinsicWidthConstraints()
      if logicalWidth.isMinContent() {
        return IntrinsicWidthConstraints(
          minimum: intrinsicWidthConstraints.minimum, maximum: intrinsicWidthConstraints.minimum)
      }
      if logicalWidth.isMaxContent() {
        return IntrinsicWidthConstraints(
          minimum: intrinsicWidthConstraints.maximum, maximum: intrinsicWidthConstraints.maximum)
      }
      return intrinsicWidthConstraints
    }

    var intrinsicWidthConstraints = IntrinsicWidthConstraints()
    let formattingState = formattingContext().formattingState()
    let children: LayoutChildIteratorAdapter<ElementBoxWrapper> = childrenOfType(parent: layoutBox)
    for child in children {
      if child.isOutOfFlowPositioned() || (child.isFloatAvoider() && !child.hasFloatClear()) {
        continue
      }
      let childIntrinsicWidthConstraints = formattingState.intrinsicWidthConstraintsForBox(
        layoutBox: child)
      assert(childIntrinsicWidthConstraints != nil)

      intrinsicWidthConstraints.minimum = max(
        intrinsicWidthConstraints.minimum, childIntrinsicWidthConstraints!.minimum)
      intrinsicWidthConstraints.maximum = max(
        intrinsicWidthConstraints.maximum, childIntrinsicWidthConstraints!.maximum)
    }
    return intrinsicWidthConstraints
  }

  func computedContentWidthAndMargin(
    layoutBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    availableWidthFloatAvoider: LayoutUnit?
  ) -> ContentWidthAndMargin {
    var horizontalConstraintsForWidth = horizontalConstraints
    if layoutBox.style.logicalWidth().isAuto() && availableWidthFloatAvoider != nil {
      // While the non-auto width values should all be resolved against the containing block's width, when
      // the width is auto the available horizontal space is shrunk by neighboring floats.
      horizontalConstraintsForWidth.logicalWidth = availableWidthFloatAvoider!
    }
    var contentWidthAndMargin = computedContentWidthAndMarginHelper(
      constraintsForWidth: horizontalConstraintsForWidth, usedWidth: nil, layoutBox: layoutBox)
    let availableWidth = horizontalConstraints.logicalWidth
    if let maxWidth = computedMaxWidth(layoutBox: layoutBox, containingBlockWidth: availableWidth) {
      let maxWidthAndMargin = computedContentWidthAndMarginHelper(
        constraintsForWidth: horizontalConstraints, usedWidth: maxWidth, layoutBox: layoutBox)
      if contentWidthAndMargin.contentWidth > maxWidthAndMargin.contentWidth {
        contentWidthAndMargin = maxWidthAndMargin
      }
    }

    let minWidth =
      computedMinWidth(layoutBox: layoutBox, containingBlockWidth: availableWidth)
      ?? LayoutUnit(value: 0)
    let minWidthAndMargin = computedContentWidthAndMarginHelper(
      constraintsForWidth: horizontalConstraints, usedWidth: minWidth, layoutBox: layoutBox)
    if contentWidthAndMargin.contentWidth < minWidthAndMargin.contentWidth {
      contentWidthAndMargin = minWidthAndMargin
    }
    return contentWidthAndMargin
  }

  func computedContentWidthAndMarginHelper(
    constraintsForWidth: HorizontalConstraints, usedWidth: LayoutUnit?, layoutBox: ElementBoxWrapper
  ) -> ContentWidthAndMargin {
    if layoutBox.isFloatingPositioned() {
      return floatingContentWidthAndMargin(
        layoutBox: layoutBox, horizontalConstraints: constraintsForWidth,
        overriddenHorizontalValues: OverriddenHorizontalValues(width: usedWidth, margin: nil))
    }

    if layoutBox.isInFlow() {
      return inFlowContentWidthAndMargin(
        layoutBox: layoutBox, horizontalConstraints: constraintsForWidth,
        overriddenHorizontalValues: OverriddenHorizontalValues(width: usedWidth, margin: nil))
    }

    fatalError("Not reached")
  }

  func inFlowNonReplacedContentHeightAndMargin(
    layoutBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    overriddenVerticalValues: OverriddenVerticalValues
  ) -> ContentHeightAndMargin {
    assert(layoutBox.isInFlow() && !layoutBox.isReplacedBox())
    assert(layoutBox.isOverflowVisible())

    // 10.6.7 'Auto' heights for block-level formatting context boxes.
    let isAutoHeight =
      overriddenVerticalValues.height == nil && computedHeight(layoutBox: layoutBox) == nil
    if isAutoHeight
      && (layoutBox.establishesFormattingContext()
        && !layoutBox.establishesInlineFormattingContext())
    {
      return computeInFlowNonReplacedContentHeightAndMargin(
        layoutBox: layoutBox,
        horizontalConstraints: horizontalConstraints,
        overriddenVerticalValues: OverriddenVerticalValues(
          height: contentHeightForFormattingContextRoot(formattingContextRoot: layoutBox)))
    }
    return computeInFlowNonReplacedContentHeightAndMargin(
      layoutBox: layoutBox, horizontalConstraints: horizontalConstraints,
      overriddenVerticalValues: overriddenVerticalValues)
  }

  func computeInFlowNonReplacedContentHeightAndMargin(
    layoutBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    overriddenVerticalValues: OverriddenVerticalValues
  ) -> ContentHeightAndMargin {

    // 10.6.3 Block-level non-replaced elements in normal flow when 'overflow' computes to 'visible'
    //
    // If 'margin-top', or 'margin-bottom' are 'auto', their used value is 0.
    // If 'height' is 'auto', the height depends on whether the element has any block-level children and whether it has padding or borders:
    // The element's height is the distance from its top content edge to the first applicable of the following:
    // 1. the bottom edge of the last line box, if the box establishes a inline formatting context with one or more lines
    // 2. the bottom edge of the bottom (possibly collapsed) margin of its last in-flow child, if the child's bottom margin
    //    does not collapse with the element's bottom margin
    // 3. the bottom border edge of the last in-flow child whose top margin doesn't collapse with the element's bottom margin
    // 4. zero, otherwise
    // Only children in the normal flow are taken into account (i.e., floating boxes and absolutely positioned boxes are ignored,
    // and relatively positioned boxes are considered without their offset). Note that the child box may be an anonymous block box.

    let boxGeometry = formattingContext().geometryForBox(layoutBox: layoutBox)
    let computedVerticalMargin = computedVerticalMargin(
      layoutBox: layoutBox, horizontalConstraints: horizontalConstraints)
    let nonCollapsedMargin = UsedVerticalMargin.NonCollapsedValues(
      before: computedVerticalMargin.before ?? LayoutUnit(value: 0),
      after: computedVerticalMargin.after ?? LayoutUnit(value: 0))
    let borderAndPaddingTop = boxGeometry.borderAndPaddingBefore()
    let height =
      overriddenVerticalValues.height != nil
      ? overriddenVerticalValues.height! : computedHeight(layoutBox: layoutBox)

    if height != nil {
      return ContentHeightAndMargin(contentHeight: height!, nonCollapsedMargin: nonCollapsedMargin)
    }

    if !layoutBox.hasInFlowChild() {
      return ContentHeightAndMargin(
        contentHeight: LayoutUnit(value: 0), nonCollapsedMargin: nonCollapsedMargin)
    }

    // 1. the bottom edge of the last line box, if the box establishes a inline formatting context with one or more lines
    if layoutBox.establishesInlineFormattingContext() {
      // FIXME: Need access to display content.
      fatalError("Not implemented yet")
    }

    // 2. the bottom edge of the bottom (possibly collapsed) margin of its last in-flow child, if the child's bottom margin...
    let marginCollapse = BlockMarginCollapse(
      layoutState: layoutState(), blockFormattingState: formattingContext().formattingState())
    let lastInFlowChild = layoutBox.lastInFlowChild()! as! ElementBoxWrapper
    if !marginCollapse.marginAfterCollapsesWithParentMarginAfter(layoutBox: lastInFlowChild) {
      let lastInFlowBoxGeometry = formattingContext().geometryForBox(layoutBox: lastInFlowChild)
      let bottomEdgeOfBottomMargin =
        BoxGeometry.borderBoxRect(box: lastInFlowBoxGeometry).bottom()
        + lastInFlowBoxGeometry.marginAfter()
      return ContentHeightAndMargin(
        contentHeight: bottomEdgeOfBottomMargin - borderAndPaddingTop,
        nonCollapsedMargin: nonCollapsedMargin)
    }

    // 3. the bottom border edge of the last in-flow child whose top margin doesn't collapse with the element's bottom margin
    var inFlowChild: ElementBoxWrapper? = lastInFlowChild
    while inFlowChild != nil
      && marginCollapse.marginBeforeCollapsesWithParentMarginAfter(layoutBox: inFlowChild!)
    {
      inFlowChild = inFlowChild!.previousInFlowSibling() as! ElementBoxWrapper?
    }
    if inFlowChild != nil {
      let inFlowBoxGeometry = formattingContext().geometryForBox(layoutBox: inFlowChild!)
      return ContentHeightAndMargin(
        contentHeight: BoxGeometry.borderBoxTop(box: inFlowBoxGeometry)
          + inFlowBoxGeometry.borderBox().height(),
        nonCollapsedMargin: nonCollapsedMargin)
    }

    // 4. zero, otherwise
    return ContentHeightAndMargin(
      contentHeight: LayoutUnit(value: 0), nonCollapsedMargin: nonCollapsedMargin)
  }

  func inFlowNonReplacedContentWidthAndMargin(
    layoutBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    overriddenHorizontalValues: OverriddenHorizontalValues
  ) -> ContentWidthAndMargin {
    assert(layoutBox.isInFlow())

    return computeInFlowNonReplacedContentWidthAndMargin(
      layoutBox: layoutBox, horizontalConstraints: horizontalConstraints,
      overriddenHorizontalValues: overriddenHorizontalValues)
  }

  func inFlowReplacedContentWidthAndMargin(
    replacedBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    overriddenHorizontalValues: OverriddenHorizontalValues
  ) -> ContentWidthAndMargin {
    assert(replacedBox.isInFlow())

    // 10.3.4 Block-level, replaced elements in normal flow
    //
    // 1. The used value of 'width' is determined as for inline replaced elements.
    // 2. Then the rules for non-replaced block-level elements are applied to determine the margins.

    // #1
    let usedWidth = inlineReplacedContentWidthAndMargin(
      replacedBox: replacedBox, horizontalConstraints: horizontalConstraints,
      verticalConstraints: nil, overriddenHorizontalValues: overriddenHorizontalValues
    ).contentWidth
    // #2
    let nonReplacedWidthAndMargin = inFlowNonReplacedContentWidthAndMargin(
      layoutBox: replacedBox, horizontalConstraints: horizontalConstraints,
      overriddenHorizontalValues: OverriddenHorizontalValues(
        width: usedWidth, margin: overriddenHorizontalValues.margin))

    return ContentWidthAndMargin(
      contentWidth: usedWidth, usedMargin: nonReplacedWidthAndMargin.usedMargin)
  }

  func computeInFlowNonReplacedContentWidthAndMargin(
    layoutBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    overriddenHorizontalValues: OverriddenHorizontalValues
  ) -> ContentWidthAndMargin {

    // 10.3.3 Block-level, non-replaced elements in normal flow
    //
    // The following constraints must hold among the used values of the other properties:
    // 'margin-left' + 'border-left-width' + 'padding-left' + 'width' + 'padding-right' + 'border-right-width' + 'margin-right' = width of containing block
    //
    // 1. If 'width' is not 'auto' and 'border-left-width' + 'padding-left' + 'width' + 'padding-right' + 'border-right-width'
    //    (plus any of 'margin-left' or 'margin-right' that are not 'auto') is larger than the width of the containing block, then
    //    any 'auto' values for 'margin-left' or 'margin-right' are, for the following rules, treated as zero.
    //
    // 2. If all of the above have a computed value other than 'auto', the values are said to be "over-constrained" and one of the used values will
    //    have to be different from its computed value. If the 'direction' property of the containing block has the value 'ltr', the specified value
    //    of 'margin-right' is ignored and the value is calculated so as to make the equality true. If the value of 'direction' is 'rtl',
    //    this happens to 'margin-left' instead.
    //
    // 3. If there is exactly one value specified as 'auto', its used value follows from the equality.
    //
    // 4. If 'width' is set to 'auto', any other 'auto' values become '0' and 'width' follows from the resulting equality.
    //
    // 5. If both 'margin-left' and 'margin-right' are 'auto', their used values are equal. This horizontally centers the element with respect to the
    //    edges of the containing block.

    let containingBlockWidth = horizontalConstraints.logicalWidth
    let containingBlockStyle = FormattingContext.containingBlock(layoutBox: layoutBox).style
    let boxGeometry = formattingContext().geometryForBox(layoutBox: layoutBox)

    var width =
      overriddenHorizontalValues.width != nil
      ? overriddenHorizontalValues.width!
      : computedWidth(layoutBox: layoutBox, containingBlockWidth: containingBlockWidth)
    let computedHorizontalMargin = computedHorizontalMargin(
      layoutBox: layoutBox, horizontalConstraints: horizontalConstraints)
    var usedHorizontalMargin = UsedHorizontalMargin()
    let borderLeft = boxGeometry.borderStart()
    let borderRight = boxGeometry.borderEnd()
    let paddingLeft = boxGeometry.paddingStart()
    let paddingRight = boxGeometry.paddingEnd()

    // #1
    if width != nil {
      let horizontalSpaceForMargin =
        containingBlockWidth
        - ((computedHorizontalMargin.start ?? LayoutUnit(value: 0)) + borderLeft + paddingLeft
          + width! + paddingRight + borderRight
          + (computedHorizontalMargin.end ?? LayoutUnit(value: 0)))
      if horizontalSpaceForMargin < 0 {
        usedHorizontalMargin = UsedHorizontalMargin(
          start: computedHorizontalMargin.start ?? LayoutUnit(value: 0),
          end: computedHorizontalMargin.end ?? LayoutUnit(value: 0))
      }
    }

    // #2
    if width != nil && computedHorizontalMargin.start != nil && computedHorizontalMargin.end != nil
    {
      if containingBlockStyle.isLeftToRightDirection() {
        usedHorizontalMargin.start = computedHorizontalMargin.start!
        usedHorizontalMargin.end =
          containingBlockWidth
          - (usedHorizontalMargin.start + borderLeft + paddingLeft + width! + paddingRight
            + borderRight)
      } else {
        usedHorizontalMargin.end = computedHorizontalMargin.end!
        usedHorizontalMargin.start =
          containingBlockWidth
          - (borderLeft + paddingLeft + width! + paddingRight + borderRight
            + usedHorizontalMargin.end)
      }
    }

    // #3
    if computedHorizontalMargin.start == nil && width != nil && computedHorizontalMargin.end != nil
    {
      usedHorizontalMargin.end = computedHorizontalMargin.end!
      usedHorizontalMargin.start =
        containingBlockWidth
        - (borderLeft + paddingLeft + width! + paddingRight + borderRight + usedHorizontalMargin.end)
    } else if computedHorizontalMargin.start != nil && width == nil
      && computedHorizontalMargin.end != nil
    {
      usedHorizontalMargin = UsedHorizontalMargin(
        start: computedHorizontalMargin.start!, end: computedHorizontalMargin.end!)
      width =
        containingBlockWidth
        - (usedHorizontalMargin.start + borderLeft + paddingLeft + paddingRight + borderRight
          + usedHorizontalMargin.end)
    } else if computedHorizontalMargin.start != nil && width != nil
      && computedHorizontalMargin.end == nil
    {
      usedHorizontalMargin.start = computedHorizontalMargin.start!
      usedHorizontalMargin.end =
        containingBlockWidth
        - (usedHorizontalMargin.start + borderLeft + paddingLeft + width! + paddingRight
          + borderRight)
    }

    // #4
    if width == nil {
      usedHorizontalMargin = UsedHorizontalMargin(
        start: computedHorizontalMargin.start ?? LayoutUnit(value: 0),
        end: computedHorizontalMargin.end ?? LayoutUnit(value: 0))
      width =
        containingBlockWidth
        - (usedHorizontalMargin.start + borderLeft + paddingLeft + paddingRight + borderRight
          + usedHorizontalMargin.end)
    }

    // #5
    if computedHorizontalMargin.start == nil && computedHorizontalMargin.end == nil {
      let horizontalSpaceForMargin =
        containingBlockWidth - (borderLeft + paddingLeft + width! + paddingRight + borderRight)
      usedHorizontalMargin = UsedHorizontalMargin(
        start: horizontalSpaceForMargin / 2, end: horizontalSpaceForMargin / 2)
    }

    let shouldApplyCenterAlignForBlockContent =
      containingBlockStyle.textAlign() == .WebKitCenter
      && (computedHorizontalMargin.start != nil || computedHorizontalMargin.end != nil)
    if shouldApplyCenterAlignForBlockContent {
      let borderBoxWidth = (borderLeft + paddingLeft + width! + paddingRight + borderRight)
      let marginStart = computedHorizontalMargin.start ?? LayoutUnit(value: 0)
      let marginEnd = computedHorizontalMargin.end ?? LayoutUnit(value: 0)
      let centeredLogicalLeftForMarginBox = max(
        (containingBlockWidth - borderBoxWidth - marginStart - marginEnd) / 2, LayoutUnit(value: 0))
      usedHorizontalMargin.start = centeredLogicalLeftForMarginBox + marginStart
      usedHorizontalMargin.end = containingBlockWidth - borderBoxWidth - marginStart + marginEnd
    }
    assert(width != nil)

    return ContentWidthAndMargin(contentWidth: width!, usedMargin: usedHorizontalMargin)
  }

  func formattingContext() -> BlockFormattingContext {
    return formattingContext as! BlockFormattingContext
  }
}
