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

func isHeightAuto(layoutBox: BoxWrapper) -> Bool {
  // 10.5 Content height: the 'height' property
  //
  // The percentage is calculated with respect to the height of the generated box's containing block.
  // If the height of the containing block is not specified explicitly (i.e., it depends on content height),
  // and this element is not absolutely positioned, the used height is calculated as if 'auto' was specified.

  let height = layoutBox.style.logicalHeight()
  if height.isAuto() {
    return true
  }

  if height.isPercent() {
    if layoutBox.isOutOfFlowPositioned() {
      return false
    }

    return !FormattingContext.containingBlock(layoutBox: layoutBox).style.logicalHeight().isFixed()
  }

  return false
}

func usedWritingMode(layoutBox: BoxWrapper) -> WritingMode {
  // https://www.w3.org/TR/css-writing-modes-4/#logical-direction-layout
  // Flow-relative directions are calculated with respect to the writing mode of the containing block of the box.
  // For inline-level boxes, the writing mode of the parent box is used instead.
  return layoutBox.isInlineLevelBox()
    ? layoutBox.parent().style.writingMode()
    : FormattingContext.containingBlock(layoutBox: layoutBox).style.writingMode()
}

// This class implements generic positioning and sizing.
class FormattingGeometry {
  init(formattingContext: FormattingContext) {
    self.formattingContext = formattingContext
  }

  func floatingContentHeightAndMargin(
    layoutBox: BoxWrapper, horizontalConstraints: HorizontalConstraints,
    overriddenVerticalValues: OverriddenVerticalValues
  ) -> ContentHeightAndMargin {
    assert(layoutBox.isFloatingPositioned())

    if !layoutBox.isReplacedBox() {
      return complicatedCases(
        layoutBox: layoutBox, horizontalConstraints: horizontalConstraints,
        overriddenVerticalValues: overriddenVerticalValues)
    }
    return floatingReplacedContentHeightAndMargin(
      replacedBox: layoutBox as! ElementBoxWrapper, horizontalConstraints: horizontalConstraints,
      overriddenVerticalValues: overriddenVerticalValues)
  }

  func floatingContentWidthAndMargin(
    layoutBox: BoxWrapper, horizontalConstraints: HorizontalConstraints,
    overriddenHorizontalValues: OverriddenHorizontalValues
  ) -> ContentWidthAndMargin {
    assert(layoutBox.isFloatingPositioned())

    if !layoutBox.isReplacedBox() {
      return floatingNonReplacedContentWidthAndMargin(
        layoutBox: layoutBox, horizontalConstraints: horizontalConstraints,
        overriddenHorizontalValues: overriddenHorizontalValues)
    }
    return floatingReplacedContentWidthAndMargin(
      replacedBox: layoutBox as! ElementBoxWrapper, horizontalConstraints: horizontalConstraints,
      overriddenHorizontalValues: overriddenHorizontalValues)
  }

  func inlineReplacedContentHeightAndMargin(
    replacedBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    verticalConstraints: VerticalConstraints?, overriddenVerticalValues: OverriddenVerticalValues
  ) -> ContentHeightAndMargin {
    // 10.6.2 Inline replaced elements, block-level replaced elements in normal flow, 'inline-block' replaced elements in normal flow and floating replaced elements
    //
    // 1. If 'margin-top', or 'margin-bottom' are 'auto', their used value is 0.
    // 2. If 'height' and 'width' both have computed values of 'auto' and the element also has an intrinsic height, then that intrinsic height is the used value of 'height'.
    // 3. Otherwise, if 'height' has a computed value of 'auto', and the element has an intrinsic ratio then the used value of 'height' is:
    //    (used width) / (intrinsic ratio)
    // 4. Otherwise, if 'height' has a computed value of 'auto', and the element has an intrinsic height, then that intrinsic height is the used value of 'height'.
    // 5. Otherwise, if 'height' has a computed value of 'auto', but none of the conditions above are met, then the used value of 'height' must be set to
    //    the height of the largest rectangle that has a 2:1 ratio, has a height not greater than 150px, and has a width not greater than the device width.

    // #1
    let computedVerticalMargin = computedVerticalMargin(
      layoutBox: replacedBox, horizontalConstraints: horizontalConstraints)
    let usedVerticalMargin = UsedVerticalMargin.NonCollapsedValues(
      before: computedVerticalMargin.before ?? LayoutUnit(value: 0),
      after: computedVerticalMargin.after ?? LayoutUnit(value: 0))
    let style = replacedBox.style

    var height =
      overriddenVerticalValues.height != nil
      ? overriddenVerticalValues.height!
      : computedHeight(
        layoutBox: replacedBox,
        containingBlockHeight: verticalConstraints != nil ? verticalConstraints!.logicalHeight : nil
      )
    let heightIsAuto =
      overriddenVerticalValues.height == nil && isHeightAuto(layoutBox: replacedBox)
    let widthIsAuto = style.logicalWidth().isAuto()

    if heightIsAuto && widthIsAuto && replacedBox.hasIntrinsicHeight() {
      // #2
      height = replacedBox.intrinsicHeight()
    } else if heightIsAuto && replacedBox.hasIntrinsicRatio() {
      // #3
      let usedWidth = formattingContext.geometryForBox(layoutBox: replacedBox).contentBoxWidth()
      height = usedWidth / replacedBox.intrinsicRatio()
    } else if heightIsAuto && replacedBox.hasIntrinsicHeight() {
      // #4
      height = replacedBox.intrinsicHeight()
    } else if heightIsAuto {
      // #5
      height = LayoutUnit(value: 150)
    }

    assert(height != nil)

    return ContentHeightAndMargin(contentHeight: height!, nonCollapsedMargin: usedVerticalMargin)
  }

  func inlineReplacedContentWidthAndMargin(
    replacedBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    verticalConstraints: VerticalConstraints?,
    overriddenHorizontalValues: OverriddenHorizontalValues
  ) -> ContentWidthAndMargin {
    // 10.3.2 Inline, replaced elements
    //
    // A computed value of 'auto' for 'margin-left' or 'margin-right' becomes a used value of '0'.
    //
    // 1. If 'height' and 'width' both have computed values of 'auto' and the element also has an intrinsic width, then that intrinsic width is the used value of 'width'.
    //
    // 2. If 'height' and 'width' both have computed values of 'auto' and the element has no intrinsic width, but does have an intrinsic height and intrinsic ratio;
    //    or if 'width' has a computed value of 'auto', 'height' has some other computed value, and the element does have an intrinsic ratio;
    //    then the used value of 'width' is: (used height) * (intrinsic ratio)
    //
    // 3. If 'height' and 'width' both have computed values of 'auto' and the element has an intrinsic ratio but no intrinsic height or width,
    //    then the used value of 'width' is undefined in CSS 2.2. However, it is suggested that, if the containing block's width does not itself depend on the replaced
    //    element's width, then the used value of 'width' is calculated from the constraint equation used for block-level, non-replaced elements in normal flow.
    //
    // 4. Otherwise, if 'width' has a computed value of 'auto', and the element has an intrinsic width, then that intrinsic width is the used value of 'width'.
    //
    // 5. Otherwise, if 'width' has a computed value of 'auto', but none of the conditions above are met, then the used value of 'width' becomes 300px.
    //    If 300px is too wide to fit the device, UAs should use the width of the largest rectangle that has a 2:1 ratio and fits the device instead.

    let computedHorizontalMargin = computedHorizontalMargin(
      layoutBox: replacedBox, horizontalConstraints: horizontalConstraints)

    var width =
      overriddenHorizontalValues.width != nil
      ? overriddenHorizontalValues.width!
      : computedWidth(
        layoutBox: replacedBox, containingBlockWidth: horizontalConstraints.logicalWidth)
    let heightIsAuto = isHeightAuto(layoutBox: replacedBox)
    let height = computedHeight(
      layoutBox: replacedBox,
      containingBlockHeight: verticalConstraints != nil ? verticalConstraints!.logicalHeight : nil)

    if width == nil && heightIsAuto && replacedBox.hasIntrinsicWidth() {
      // #1
      width = replacedBox.intrinsicWidth()
    } else if (width == nil && heightIsAuto && !replacedBox.hasIntrinsicWidth()
      && replacedBox.hasIntrinsicHeight() && replacedBox.hasIntrinsicRatio())
      || (width == nil && height != nil && replacedBox.hasIntrinsicRatio())
    {
      // #2
      width =
        (height ?? LayoutUnit(value: replacedBox.hasIntrinsicHeight() ? 1 : 0))
        * replacedBox.intrinsicRatio()
    } else if width == nil && heightIsAuto && replacedBox.hasIntrinsicRatio()
      && !replacedBox.hasIntrinsicWidth() && !replacedBox.hasIntrinsicHeight()
    {
      // #3
      // FIXME: undefined but surely doable.
      fatalError("Not implemented yet")
    } else if width == nil && replacedBox.hasIntrinsicWidth() {
      // #4
      width = replacedBox.intrinsicWidth()
    } else if width == nil {
      // #5
      width = LayoutUnit(value: 300)
    }

    return ContentWidthAndMargin(
      contentWidth: width!,
      usedMargin: UsedHorizontalMargin(
        start: FormattingGeometry.usedMarginStart(
          overriddenHorizontalValues: overriddenHorizontalValues,
          computedHorizontalMargin: computedHorizontalMargin),
        end: FormattingGeometry.usedMarginEnd(
          overriddenHorizontalValues: overriddenHorizontalValues,
          computedHorizontalMargin: computedHorizontalMargin)))
  }

  static func usedMarginStart(
    overriddenHorizontalValues: OverriddenHorizontalValues,
    computedHorizontalMargin: ComputedHorizontalMargin
  ) -> LayoutUnit {
    if overriddenHorizontalValues.margin != nil {
      return overriddenHorizontalValues.margin!.start
    }
    return computedHorizontalMargin.start ?? LayoutUnit(value: 0)
  }

  static func usedMarginEnd(
    overriddenHorizontalValues: OverriddenHorizontalValues,
    computedHorizontalMargin: ComputedHorizontalMargin
  ) -> LayoutUnit {
    if overriddenHorizontalValues.margin != nil {
      return overriddenHorizontalValues.margin!.end
    }
    return computedHorizontalMargin.end ?? LayoutUnit(value: 0)
  }

  func inFlowPositionedPositionOffset(
    layoutBox: BoxWrapper, horizontalConstraints: HorizontalConstraints
  ) -> LayoutSizeWrapper {
    assert(layoutBox.isInFlowPositioned())

    // 9.4.3 Relative positioning
    //
    // The 'top' and 'bottom' properties move relatively positioned element(s) up or down without changing their size.
    // Top' moves the boxes down, and 'bottom' moves them up. Since boxes are not split or stretched as a result of 'top' or 'bottom', the used values are always: top = -bottom.
    //
    // 1. If both are 'auto', their used values are both '0'.
    // 2. If one of them is 'auto', it becomes the negative of the other.
    // 3. If neither is 'auto', 'bottom' is ignored (i.e., the used value of 'bottom' will be minus the value of 'top').

    let style = layoutBox.style
    let containingBlockWidth = horizontalConstraints.logicalWidth

    var top = computedValue(
      geometryProperty: style.logicalTop(), containingBlockWidth: containingBlockWidth)
    var bottom = computedValue(
      geometryProperty: style.logicalBottom(), containingBlockWidth: containingBlockWidth)

    if top == nil && bottom == nil {
      // #1
      top = LayoutUnit(value: 0)
      bottom = LayoutUnit(value: 0)
    } else if top == nil {
      // #2
      top = -bottom!
    } else if bottom == nil {
      // #3
      bottom = -top!
    } else {
      // #4
      bottom = nil
    }

    // For relatively positioned elements, 'left' and 'right' move the box(es) horizontally, without changing their size.
    // 'Left' moves the boxes to the right, and 'right' moves them to the left.
    // Since boxes are not split or stretched as a result of 'left' or 'right', the used values are always: left = -right.
    //
    // 1. If both 'left' and 'right' are 'auto' (their initial values), the used values are '0' (i.e., the boxes stay in their original position).
    // 2. If 'left' is 'auto', its used value is minus the value of 'right' (i.e., the boxes move to the left by the value of 'right').
    // 3. If 'right' is specified as 'auto', its used value is minus the value of 'left'.
    // 4. If neither 'left' nor 'right' is 'auto', the position is over-constrained, and one of them has to be ignored.
    //    If the 'direction' property of the containing block is 'ltr', the value of 'left' wins and 'right' becomes -'left'.
    //    If 'direction' of the containing block is 'rtl', 'right' wins and 'left' is ignored.

    var left = computedValue(
      geometryProperty: style.logicalLeft(), containingBlockWidth: containingBlockWidth)
    var right = computedValue(
      geometryProperty: style.logicalRight(), containingBlockWidth: containingBlockWidth)

    if left == nil && right == nil {
      // #1
      left = LayoutUnit(value: 0)
      right = LayoutUnit(value: 0)
    } else if left == nil {
      // #2
      left = -right!
    } else if right == nil {
      // #3
      right = -left!
    } else {
      // #4
      let isLeftToRightDirection = FormattingContext.containingBlock(layoutBox: layoutBox).style
        .isLeftToRightDirection()
      if isLeftToRightDirection {
        right = -left!
      } else {
        left = nil
      }
    }

    assert(bottom == nil || top! == -bottom!)
    assert(left == nil || left! == -right!)

    let topPositionOffset = top!
    let leftPositionOffset = left ?? -right!

    return LayoutSizeWrapper(width: leftPositionOffset, height: topPositionOffset)
  }

  func complicatedCases(
    layoutBox: BoxWrapper, horizontalConstraints: HorizontalConstraints,
    overriddenVerticalValues: OverriddenVerticalValues
  ) -> ContentHeightAndMargin {
    assert(!layoutBox.isReplacedBox())
    // TODO: Use complicated-case for document renderer for now (see BlockFormattingGeometry::inFlowHeightAndMargin).
    assert(
      (layoutBox.isBlockLevelBox() && layoutBox.isInFlow() && !layoutBox.isOverflowVisible())
        || layoutBox.isInlineBlockBox() || layoutBox.isFloatingPositioned()
        || layoutBox.isDocumentBox() || layoutBox.isTableBox())

    // 10.6.6 Complicated cases
    //
    // Block-level, non-replaced elements in normal flow when 'overflow' does not compute to 'visible' (except if the 'overflow' property's value has been propagated to the viewport).
    // 'Inline-block', non-replaced elements.
    // Floating, non-replaced elements.
    //
    // 1. If 'margin-top', or 'margin-bottom' are 'auto', their used value is 0.
    // 2. If 'height' is 'auto', the height depends on the element's descendants per 10.6.7.

    var height =
      overriddenVerticalValues.height != nil
      ? overriddenVerticalValues.height! : computedHeight(layoutBox: layoutBox)
    let computedVerticalMargin = computedVerticalMargin(
      layoutBox: layoutBox, horizontalConstraints: horizontalConstraints)
    // #1
    let usedVerticalMargin = UsedVerticalMargin.NonCollapsedValues(
      before: computedVerticalMargin.before ?? LayoutUnit(value: 0),
      after: computedVerticalMargin.after ?? LayoutUnit(value: 0))
    // #2
    if height == nil {
      assert(isHeightAuto(layoutBox: layoutBox))
      let elementBox = layoutBox as? ElementBoxWrapper
      if elementBox == nil || elementBox!.hasInFlowOrFloatingChild() {
        height = LayoutUnit(value: 0)
      } else if layoutBox.isDocumentBox() && !layoutBox.establishesFormattingContext() {
        var top = BoxGeometry.marginBoxRect(
          box: formattingContext.geometryForBox(layoutBox: elementBox!.firstInFlowChild()!)
        ).top()
        var bottom = BoxGeometry.marginBoxRect(
          box: formattingContext.geometryForBox(layoutBox: elementBox!.lastInFlowChild()!)
        ).bottom()
        // This is a special (quirk?) behavior since the document box is not a formatting context root and
        // all the float boxes end up at the ICB level.
        let initialContainingBlock = FormattingContext.initialContainingBlock(
          layoutBox: elementBox!)
        let floatingContext = FloatingContext(
          formattingContextRoot: formattingContext.root, layoutState: layoutState(),
          placedFloats: (layoutState().formattingStateForFormattingContext(
            formattingContextRoot: initialContainingBlock)
            as! BlockFormattingState).placedFloats!)
        if let floatBottom = floatingContext.bottom() {
          bottom = max(floatBottom, bottom)
          let floatTop = floatingContext.top()!
          top = min(floatTop, top)
        }
        height = bottom - top
      } else {
        assert(layoutBox.establishesFormattingContext())
        height = contentHeightForFormattingContextRoot(
          formattingContextRoot: layoutBox as! ElementBoxWrapper)
      }
    }

    assert(height != nil)

    return ContentHeightAndMargin(contentHeight: height!, nonCollapsedMargin: usedVerticalMargin)
  }

  func shrinkToFitWidth(formattingContextRoot: BoxWrapper, availableWidth: LayoutUnit) -> LayoutUnit
  {
    assert(formattingContextRoot.establishesFormattingContext())

    // Calculation of the shrink-to-fit width is similar to calculating the width of a table cell using the automatic table layout algorithm.
    // Roughly: calculate the preferred width by formatting the content without breaking lines other than where explicit line breaks occur,
    // and also calculate the preferred minimum width, e.g., by trying all possible line breaks. CSS 2.2 does not define the exact algorithm.
    // Thirdly, find the available width: in this case, this is the width of the containing block minus the used values of 'margin-left', 'border-left-width',
    // 'padding-left', 'padding-right', 'border-right-width', 'margin-right', and the widths of any relevant scroll bars.

    // Then the shrink-to-fit width is: min(max(preferred minimum width, available width), preferred width).
    let root = formattingContextRoot as? ElementBoxWrapper
    let hasContent = root != nil && root!.hasInFlowOrFloatingChild()
    // The used width of the containment box is determined as if performing a normal layout of the box, except that it is treated as having no content.
    let shouldIgnoreContent = formattingContextRoot.isSizeContainmentBox()
    if !hasContent || shouldIgnoreContent {
      return LayoutUnit()
    }

    let computedIntrinsicWidthConstraints = computedIntrinsicWidthConstraints(root: root!)
    return min(
      max(computedIntrinsicWidthConstraints.minimum, availableWidth),
      computedIntrinsicWidthConstraints.maximum)
  }

  func computedIntrinsicWidthConstraints(root: ElementBoxWrapper) -> IntrinsicWidthConstraints {
    let layoutState = layoutState()
    if layoutState.hasFormattingState(formattingContextRoot: root) {
      if let intrinsicWidthConstraints = layoutState.formattingStateForFormattingContext(
        formattingContextRoot: root
      ).intrinsicWidthConstraints {
        return intrinsicWidthConstraints
      }
    }
    return LayoutContext.createFormattingContext(
      formattingContextRoot: root, layoutState: layoutState
    ).computedIntrinsicWidthConstraints()
  }

  func computedBorder(layoutBox: BoxWrapper) -> BoxGeometry.Edges {
    let style = layoutBox.style
    return BoxGeometry.Edges(
      horizontal: BoxGeometry.HorizontalEdges(
        start: LayoutUnit(value: style.borderLeftWidth()),
        end: LayoutUnit(value: style.borderRightWidth())),
      vertical: BoxGeometry.VerticalEdges(
        before: LayoutUnit(value: style.borderTopWidth()),
        after: LayoutUnit(value: style.borderBottomWidth()))
    )
  }

  func computedPadding(layoutBox: BoxWrapper, containingBlockWidth: LayoutUnit) -> BoxGeometry.Edges
  {
    if !layoutBox.isPaddingApplicable() {
      return BoxGeometry.Edges()
    }

    let style = layoutBox.style
    return BoxGeometry.Edges(
      horizontal: BoxGeometry.HorizontalEdges(
        start: valueForLength(length: style.paddingStart(), maximumValue: containingBlockWidth),
        end: valueForLength(length: style.paddingEnd(), maximumValue: containingBlockWidth)),
      vertical: BoxGeometry.VerticalEdges(
        before: valueForLength(length: style.paddingBefore(), maximumValue: containingBlockWidth),
        after: valueForLength(length: style.paddingAfter(), maximumValue: containingBlockWidth)))
  }

  func computedHorizontalMargin(layoutBox: BoxWrapper, horizontalConstraints: HorizontalConstraints)
    -> ComputedHorizontalMargin
  {
    let style = layoutBox.style
    let containingBlockWidth = horizontalConstraints.logicalWidth
    if isHorizontalWritingMode(writingMode: usedWritingMode(layoutBox: layoutBox)) {
      return ComputedHorizontalMargin(
        start: computedValue(
          geometryProperty: style.marginLeft(), containingBlockWidth: containingBlockWidth),
        end: computedValue(
          geometryProperty: style.marginRight(), containingBlockWidth: containingBlockWidth))
    }
    return ComputedHorizontalMargin(
      start: computedValue(
        geometryProperty: style.marginTop(), containingBlockWidth: containingBlockWidth),
      end: computedValue(
        geometryProperty: style.marginBottom(), containingBlockWidth: containingBlockWidth))
  }

  func computedVerticalMargin(
    layoutBox: BoxWrapper, horizontalConstraints: HorizontalConstraints
  )
    -> ComputedVerticalMargin
  {
    let style = layoutBox.style
    let containingBlockWidth = horizontalConstraints.logicalWidth
    if isHorizontalWritingMode(writingMode: usedWritingMode(layoutBox: layoutBox)) {
      return ComputedVerticalMargin(
        before: computedValue(
          geometryProperty: style.marginTop(), containingBlockWidth: containingBlockWidth),
        after: computedValue(
          geometryProperty: style.marginBottom(), containingBlockWidth: containingBlockWidth))
    }
    return ComputedVerticalMargin(
      before: computedValue(
        geometryProperty: style.marginLeft(), containingBlockWidth: containingBlockWidth),
      after: computedValue(
        geometryProperty: style.marginRight(), containingBlockWidth: containingBlockWidth))
  }

  func computedValue(geometryProperty: LengthWrapper, containingBlockWidth: LayoutUnit)
    -> LayoutUnit?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func fixedValue(geometryProperty: LengthWrapper) -> LayoutUnit? {
    if !geometryProperty.isFixed() {
      return nil
    }
    return LayoutUnit(value: geometryProperty.value())
  }

  func computedMinHeight(layoutBox: BoxWrapper, containingBlockHeight: LayoutUnit? = nil)
    -> LayoutUnit?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // https://www.w3.org/TR/CSS22/visudet.html#min-max-heights
  // Specifies a percentage for determining the used value. The percentage is calculated with respect to the height of the generated box's containing block.
  // If the height of the containing block is not specified explicitly (i.e., it depends on content height), and this element is not absolutely positioned,
  // the percentage value is treated as '0' (for 'min-height') or 'none' (for 'max-height').
  func computedMaxHeight(layoutBox: BoxWrapper, containingBlockHeight: LayoutUnit? = nil)
    -> LayoutUnit?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computedMinWidth(layoutBox: BoxWrapper, containingBlockWidth: LayoutUnit) -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computedMaxWidth(layoutBox: BoxWrapper, containingBlockWidth: LayoutUnit) -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func constrainByMinMaxWidth(layoutBox: BoxWrapper, intrinsicWidth: IntrinsicWidthConstraints)
    -> IntrinsicWidthConstraints
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func contentHeightForFormattingContextRoot(formattingContextRoot: ElementBoxWrapper) -> LayoutUnit
  {
    assert(formattingContextRoot.establishesFormattingContext())
    assert(
      isHeightAuto(layoutBox: formattingContextRoot)
        || formattingContextRoot.establishesTableFormattingContext()
        || formattingContextRoot.isTableCell())
    var usedContentHeight = LayoutUnit()
    let hasContent = formattingContextRoot.hasInFlowOrFloatingChild()
    // The used height of the containment box is determined as if performing a normal layout of the box, except that it is treated as having no content.
    let shouldIgnoreContent = formattingContextRoot.isSizeContainmentBox()
    if hasContent && !shouldIgnoreContent {
      usedContentHeight = LayoutContext.createFormattingContext(
        formattingContextRoot: formattingContextRoot, layoutState: layoutState()
      ).usedContentHeight()
    }
    return usedContentHeight
  }

  func constraintsForOutOfFlowContent(elementBox: ElementBoxWrapper)
    -> ConstraintsForOutOfFlowContent
  {
    let boxGeometry = formattingContext.geometryForBox(layoutBox: elementBox)
    return ConstraintsForOutOfFlowContent(
      horizontal: HorizontalConstraints(
        logicalLeft: boxGeometry.paddingBoxLeft(), logicalWidth: boxGeometry.paddingBoxWidth()),
      vertical: VerticalConstraints(
        logicalTop: boxGeometry.paddingBoxTop(), logicalHeight: boxGeometry.paddingBoxHeight()),
      borderAndPaddingConstraints: boxGeometry.contentBoxWidth())
  }

  func constraintsForInFlowContent(
    elementBox: ElementBoxWrapper, escapeReason: FormattingContext.EscapeReason? = nil
  ) -> ConstraintsForInFlowContent {
    let boxGeometry = formattingContext.geometryForBox(
      layoutBox: elementBox, escapeReason: escapeReason)
    return ConstraintsForInFlowContent(
      horizontal: HorizontalConstraints(
        logicalLeft: boxGeometry.contentBoxLeft(), logicalWidth: boxGeometry.contentBoxWidth()),
      logicalTop: boxGeometry.contentBoxTop())
  }

  func computedHeight(layoutBox: BoxWrapper, containingBlockHeight: LayoutUnit? = nil)
    -> LayoutUnit?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computedWidth(layoutBox: BoxWrapper, containingBlockWidth: LayoutUnit) -> LayoutUnit? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layoutState() -> LayoutStateWrapper {
    return formattingContext.layoutState
  }

  func outOfFlowReplacedVerticalGeometry(
    replacedBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    verticalConstraints: VerticalConstraints, overriddenVerticalValues: OverriddenVerticalValues
  ) -> VerticalGeometry {
    assert(replacedBox.isOutOfFlowPositioned())

    // 10.6.5 Absolutely positioned, replaced elements
    //
    // The used value of 'height' is determined as for inline replaced elements.
    // If 'margin-top' or 'margin-bottom' is specified as 'auto' its used value is determined by the rules below.
    // 1. If both 'top' and 'bottom' have the value 'auto', replace 'top' with the element's static position.
    // 2. If 'bottom' is 'auto', replace any 'auto' on 'margin-top' or 'margin-bottom' with '0'.
    // 3. If at this point both 'margin-top' and 'margin-bottom' are still 'auto', solve the equation under the extra constraint that the two margins must get equal values.
    // 4. If at this point there is only one 'auto' left, solve the equation for that value.
    // 5. If at this point the values are over-constrained, ignore the value for 'bottom' and solve for that value.

    let style = replacedBox.style
    let boxGeometry = formattingContext.geometryForBox(layoutBox: replacedBox)
    let containingBlockHeight = verticalConstraints.logicalHeight
    let containingBlockWidth = horizontalConstraints.logicalWidth

    var top = computedValue(
      geometryProperty: style.logicalTop(), containingBlockWidth: containingBlockWidth)
    var bottom = computedValue(
      geometryProperty: style.logicalBottom(), containingBlockWidth: containingBlockWidth)
    let height = inlineReplacedContentHeightAndMargin(
      replacedBox: replacedBox, horizontalConstraints: horizontalConstraints,
      verticalConstraints: verticalConstraints, overriddenVerticalValues: overriddenVerticalValues
    ).contentHeight
    let computedVerticalMargin = computedVerticalMargin(
      layoutBox: replacedBox, horizontalConstraints: horizontalConstraints)
    var usedMarginBefore = computedVerticalMargin.before
    var usedMarginAfter = computedVerticalMargin.after
    let paddingTop = boxGeometry.paddingBefore()
    let paddingBottom = boxGeometry.paddingAfter()
    let borderTop = boxGeometry.borderBefore()
    let borderBottom = boxGeometry.borderAfter()

    if top == nil && bottom == nil {
      // #1
      top = staticVerticalPositionForOutOfFlowPositioned(
        layoutBox: replacedBox, verticalConstraints: verticalConstraints)
    }

    if bottom == nil {
      // #2
      usedMarginBefore = computedVerticalMargin.before ?? LayoutUnit(value: 0)
      usedMarginAfter = usedMarginBefore
    }

    if usedMarginBefore == nil && usedMarginAfter == nil {
      // #3
      let marginBeforeAndAfter =
        containingBlockHeight
        - (top! + borderTop + paddingTop + height + paddingBottom + borderBottom + bottom!)
      usedMarginBefore = marginBeforeAndAfter / 2
      usedMarginAfter = usedMarginBefore
    }

    // #4
    if top == nil {
      top =
        containingBlockHeight
        - (usedMarginBefore! + borderTop + paddingTop + height + paddingBottom + borderBottom
          + usedMarginAfter! + bottom!)
    }

    if bottom == nil {
      bottom =
        containingBlockHeight
        - (top! + usedMarginBefore! + borderTop + paddingTop + height + paddingBottom + borderBottom
          + usedMarginAfter!)
    }

    if usedMarginBefore == nil {
      usedMarginBefore =
        containingBlockHeight
        - (top! + borderTop + paddingTop + height + paddingBottom + borderBottom + usedMarginAfter!
          + bottom!)
    }

    if usedMarginAfter == nil {
      usedMarginAfter =
        containingBlockHeight
        - (top! + usedMarginBefore! + borderTop + paddingTop + height + paddingBottom + borderBottom
          + bottom!)
    }

    // #5
    let boxHeight =
      top! + usedMarginBefore! + borderTop + paddingTop + height + paddingBottom + borderBottom
      + usedMarginAfter! + bottom!
    if boxHeight > containingBlockHeight {
      bottom =
        containingBlockHeight
        - (top! + usedMarginBefore! + borderTop + paddingTop + height + paddingBottom + borderBottom
          + usedMarginAfter!)
    }

    // For out-of-flow elements the containing block is formed by the padding edge of the ancestor.
    // At this point the positioned value is in the coordinate system of the padding box. Let's convert it to border box coordinate system.
    let containingBlockPaddingVerticalEdge = verticalConstraints.logicalTop
    top! += containingBlockPaddingVerticalEdge
    bottom! += containingBlockPaddingVerticalEdge

    assert(top != nil)
    assert(bottom != nil)
    assert(usedMarginBefore != nil)
    assert(usedMarginAfter != nil)

    return VerticalGeometry(
      top: top!, bottom: bottom!,
      contentHeightAndMargin: ContentHeightAndMargin(
        contentHeight: height,
        nonCollapsedMargin: UsedVerticalMargin.NonCollapsedValues(
          before: usedMarginBefore!, after: usedMarginAfter!)))
  }

  func outOfFlowReplacedHorizontalGeometry(
    replacedBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    verticalConstraints: VerticalConstraints, overriddenHorizontalValues: OverriddenHorizontalValues
  ) -> HorizontalGeometry {
    assert(replacedBox.isOutOfFlowPositioned())

    // 10.3.8 Absolutely positioned, replaced elements
    // In this case, section 10.3.7 applies up through and including the constraint equation, but the rest of section 10.3.7 is replaced by the following rules:
    //
    // The used value of 'width' is determined as for inline replaced elements. If 'margin-left' or 'margin-right' is specified as 'auto' its used value is determined by the rules below.
    // 1. If both 'left' and 'right' have the value 'auto', then if the 'direction' property of the element establishing the static-position containing block is 'ltr',
    //   set 'left' to the static position; else if 'direction' is 'rtl', set 'right' to the static position.
    // 2. If 'left' or 'right' are 'auto', replace any 'auto' on 'margin-left' or 'margin-right' with '0'.
    // 3. If at this point both 'margin-left' and 'margin-right' are still 'auto', solve the equation under the extra constraint that the two margins must get equal values,
    //   unless this would make them negative, in which case when the direction of the containing block is 'ltr' ('rtl'), set 'margin-left' ('margin-right') to zero and
    //   solve for 'margin-right' ('margin-left').
    // 4. If at this point there is an 'auto' left, solve the equation for that value.
    // 5. If at this point the values are over-constrained, ignore the value for either 'left' (in case the 'direction' property of the containing block is 'rtl') or
    //   'right' (in case 'direction' is 'ltr') and solve for that value.

    let style = replacedBox.style
    let boxGeometry = formattingContext.geometryForBox(layoutBox: replacedBox)
    let containingBlockWidth = horizontalConstraints.logicalWidth
    let isLeftToRightDirection = FormattingContext.containingBlock(layoutBox: replacedBox).style
      .isLeftToRightDirection()

    var left = computedValue(
      geometryProperty: style.logicalLeft(), containingBlockWidth: containingBlockWidth)
    var right = computedValue(
      geometryProperty: style.logicalRight(), containingBlockWidth: containingBlockWidth)
    let computedHorizontalMargin = computedHorizontalMargin(
      layoutBox: replacedBox, horizontalConstraints: horizontalConstraints)
    var usedMarginStart = computedHorizontalMargin.start
    var usedMarginEnd = computedHorizontalMargin.end
    let width = inlineReplacedContentWidthAndMargin(
      replacedBox: replacedBox, horizontalConstraints: horizontalConstraints,
      verticalConstraints: verticalConstraints,
      overriddenHorizontalValues: overriddenHorizontalValues
    ).contentWidth
    let paddingLeft = boxGeometry.paddingStart()
    let paddingRight = boxGeometry.paddingEnd()
    let borderLeft = boxGeometry.borderStart()
    let borderRight = boxGeometry.borderEnd()

    if left == nil && right == nil {
      // #1
      let staticHorizontalPosition = staticHorizontalPositionForOutOfFlowPositioned(
        layoutBox: replacedBox, horizontalConstraints: horizontalConstraints)
      if isLeftToRightDirection {
        left = staticHorizontalPosition
      } else {
        right = staticHorizontalPosition
      }
    }

    if left == nil || right == nil {
      // #2
      usedMarginStart = computedHorizontalMargin.start ?? LayoutUnit(value: 0)
      usedMarginEnd = computedHorizontalMargin.end ?? LayoutUnit(value: 0)
    }

    if usedMarginStart == nil && usedMarginEnd == nil {
      // #3
      let marginStartAndEnd =
        containingBlockWidth
        - (left! + borderLeft + paddingLeft + width + paddingRight + borderRight + right!)
      if marginStartAndEnd >= Int32(0) {
        usedMarginStart = marginStartAndEnd / 2
        usedMarginEnd = usedMarginStart
      } else {
        if isLeftToRightDirection {
          usedMarginStart = LayoutUnit(value: 0)
          usedMarginEnd =
            containingBlockWidth
            - (left! + usedMarginStart! + borderLeft + paddingLeft + width + paddingRight
              + borderRight + right!)
        } else {
          usedMarginEnd = LayoutUnit(value: 0)
          usedMarginStart =
            containingBlockWidth
            - (left! + borderLeft + paddingLeft + width + paddingRight + borderRight
              + usedMarginEnd! + right!)
        }
      }
    }

    // #4
    if left == nil {
      left =
        containingBlockWidth
        - (usedMarginStart! + borderLeft + paddingLeft + width + paddingRight + borderRight
          + usedMarginEnd! + right!)
    }

    if right == nil {
      right =
        containingBlockWidth
        - (left! + usedMarginStart! + borderLeft + paddingLeft + width + paddingRight + borderRight
          + usedMarginEnd!)
    }

    if usedMarginStart == nil {
      usedMarginStart =
        containingBlockWidth
        - (left! + borderLeft + paddingLeft + width + paddingRight + borderRight
          + usedMarginEnd! + right!)
    }

    if usedMarginEnd == nil {
      usedMarginEnd =
        containingBlockWidth
        - (left! + usedMarginStart! + borderLeft + paddingLeft + width + paddingRight
          + borderRight + right!)
    }

    let boxWidth =
      (left! + usedMarginStart! + borderLeft + paddingLeft + width + paddingRight + borderRight
        + usedMarginEnd! + right!)
    if boxWidth > containingBlockWidth {
      // #5 Over-constrained?
      if isLeftToRightDirection {
        right =
          containingBlockWidth
          - (left! + usedMarginStart! + borderLeft + paddingLeft + width + paddingRight
            + borderRight
            + usedMarginEnd!)
      } else {
        left =
          containingBlockWidth
          - (usedMarginStart! + borderLeft + paddingLeft + width + paddingRight + borderRight
            + usedMarginEnd! + right!)
      }
    }

    assert(left != nil)
    assert(right != nil)
    assert(usedMarginStart != nil)
    assert(usedMarginEnd != nil)

    // For out-of-flow elements the containing block is formed by the padding edge of the ancestor.
    // At this point the positioned value is in the coordinate system of the padding box. Let's convert it to border box coordinate system.
    let containingBlockPaddingVerticalEdge = horizontalConstraints.logicalLeft
    left! += containingBlockPaddingVerticalEdge
    right! += containingBlockPaddingVerticalEdge

    return HorizontalGeometry(
      left: left!, right: right!,
      contentWidthAndMargin: ContentWidthAndMargin(
        contentWidth: width,
        usedMargin: UsedHorizontalMargin(
          start: usedMarginStart!, end: usedMarginEnd!)))
  }

  func outOfFlowNonReplacedVerticalGeometry(
    layoutBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    verticalConstraints: VerticalConstraints, overriddenVerticalValues: OverriddenVerticalValues
  ) -> VerticalGeometry {
    assert(layoutBox.isOutOfFlowPositioned() && !layoutBox.isReplacedBox())

    // 10.6.4 Absolutely positioned, non-replaced elements
    //
    // For absolutely positioned elements, the used values of the vertical dimensions must satisfy this constraint:
    // 'top' + 'margin-top' + 'border-top-width' + 'padding-top' + 'height' + 'padding-bottom' + 'border-bottom-width' + 'margin-bottom' + 'bottom'
    // = height of containing block

    // If all three of 'top', 'height', and 'bottom' are auto, set 'top' to the static position and apply rule number three below.

    // If none of the three are 'auto': If both 'margin-top' and 'margin-bottom' are 'auto', solve the equation under the extra
    // constraint that the two margins get equal values. If one of 'margin-top' or 'margin-bottom' is 'auto', solve the equation for that value.
    // If the values are over-constrained, ignore the value for 'bottom' and solve for that value.

    // Otherwise, pick the one of the following six rules that applies.

    // 1. 'top' and 'height' are 'auto' and 'bottom' is not 'auto', then the height is based on the content per 10.6.7,
    //     set 'auto' values for 'margin-top' and 'margin-bottom' to 0, and solve for 'top'
    // 2. 'top' and 'bottom' are 'auto' and 'height' is not 'auto', then set 'top' to the static position, set 'auto' values for
    //    'margin-top' and 'margin-bottom' to 0, and solve for 'bottom'
    // 3. 'height' and 'bottom' are 'auto' and 'top' is not 'auto', then the height is based on the content per 10.6.7, set 'auto'
    //     values for 'margin-top' and 'margin-bottom' to 0, and solve for 'bottom'
    // 4. 'top' is 'auto', 'height' and 'bottom' are not 'auto', then set 'auto' values for 'margin-top' and 'margin-bottom' to 0, and solve for 'top'
    // 5. 'height' is 'auto', 'top' and 'bottom' are not 'auto', then 'auto' values for 'margin-top' and 'margin-bottom' are set to 0 and solve for 'height'
    // 6. 'bottom' is 'auto', 'top' and 'height' are not 'auto', then set 'auto' values for 'margin-top' and 'margin-bottom' to 0 and solve for 'bottom'

    let style = layoutBox.style
    let boxGeometry = formattingContext.geometryForBox(layoutBox: layoutBox)
    let containingBlockHeight = verticalConstraints.logicalHeight
    let containingBlockWidth = horizontalConstraints.logicalWidth

    var top = computedValue(
      geometryProperty: style.logicalTop(), containingBlockWidth: containingBlockWidth)
    var bottom = computedValue(
      geometryProperty: style.logicalBottom(), containingBlockWidth: containingBlockWidth)
    var height =
      overriddenVerticalValues.height != nil
      ? overriddenVerticalValues.height!
      : computedHeight(layoutBox: layoutBox, containingBlockHeight: containingBlockHeight)
    let computedVerticalMargin = computedVerticalMargin(
      layoutBox: layoutBox, horizontalConstraints: horizontalConstraints)
    var usedVerticalMargin = UsedVerticalMargin.NonCollapsedValues()
    let paddingTop = boxGeometry.paddingBefore()
    let paddingBottom = boxGeometry.paddingAfter()
    let borderTop = boxGeometry.borderBefore()
    let borderBottom = boxGeometry.borderAfter()

    if top == nil && height == nil && bottom == nil {
      top = staticVerticalPositionForOutOfFlowPositioned(
        layoutBox: layoutBox, verticalConstraints: verticalConstraints)
    }

    if top != nil && height != nil && bottom != nil {
      if computedVerticalMargin.before == nil && computedVerticalMargin.after == nil {
        let marginBeforeAndAfter =
          containingBlockHeight
          - (top! + borderTop + paddingTop + height! + paddingBottom + borderBottom + bottom!)
        usedVerticalMargin = UsedVerticalMargin.NonCollapsedValues(
          before: marginBeforeAndAfter / 2, after: marginBeforeAndAfter / 2)
      } else if computedVerticalMargin.before == nil {
        usedVerticalMargin.after = computedVerticalMargin.after!
        usedVerticalMargin.before =
          containingBlockHeight
          - (top! + borderTop + paddingTop + height! + paddingBottom + borderBottom
            + usedVerticalMargin.after + bottom!)
      } else if computedVerticalMargin.after == nil {
        usedVerticalMargin.before = computedVerticalMargin.before!
        usedVerticalMargin.after =
          containingBlockHeight
          - (top! + usedVerticalMargin.before + borderTop + paddingTop + height! + paddingBottom
            + borderBottom + bottom!)
      } else {
        usedVerticalMargin = UsedVerticalMargin.NonCollapsedValues(
          before: computedVerticalMargin.before!, after: computedVerticalMargin.after!)
      }
      // Over-constrained?
      let boxHeight =
        top! + usedVerticalMargin.before + borderTop + paddingTop + height! + paddingBottom
        + borderBottom + usedVerticalMargin.after + bottom!
      if boxHeight != containingBlockHeight {
        bottom =
          containingBlockHeight
          - (top! + usedVerticalMargin.before + borderTop + paddingTop + height! + paddingBottom
            + borderBottom + usedVerticalMargin.after)
      }
    }

    if top == nil && height == nil && bottom != nil {
      // #1
      height = contentHeightForFormattingContextRoot(formattingContextRoot: layoutBox)
      usedVerticalMargin = UsedVerticalMargin.NonCollapsedValues(
        before: computedVerticalMargin.before ?? LayoutUnit(value: 0),
        after: computedVerticalMargin.after ?? LayoutUnit(value: 0))
      top =
        containingBlockHeight
        - (usedVerticalMargin.before + borderTop + paddingTop + height! + paddingBottom
          + borderBottom + usedVerticalMargin.after + bottom!)
    }

    if top == nil && bottom == nil && height != nil {
      // #2
      top = staticVerticalPositionForOutOfFlowPositioned(
        layoutBox: layoutBox, verticalConstraints: verticalConstraints)
      usedVerticalMargin = UsedVerticalMargin.NonCollapsedValues(
        before: computedVerticalMargin.before ?? LayoutUnit(value: 0),
        after: computedVerticalMargin.after ?? LayoutUnit(value: 0))
      bottom =
        containingBlockHeight
        - (top! + usedVerticalMargin.before + borderTop + paddingTop + height! + paddingBottom
          + borderBottom + usedVerticalMargin.after)
    }

    if height == nil && bottom == nil && top != nil {
      // #3
      height = contentHeightForFormattingContextRoot(formattingContextRoot: layoutBox)
      usedVerticalMargin = UsedVerticalMargin.NonCollapsedValues(
        before: computedVerticalMargin.before ?? LayoutUnit(value: 0),
        after: computedVerticalMargin.after ?? LayoutUnit(value: 0))
      bottom =
        containingBlockHeight
        - (top! + usedVerticalMargin.before + borderTop + paddingTop + height! + paddingBottom
          + borderBottom + usedVerticalMargin.after)
    }

    if top == nil && height != nil && bottom != nil {
      // #4
      usedVerticalMargin = UsedVerticalMargin.NonCollapsedValues(
        before: computedVerticalMargin.before ?? LayoutUnit(value: 0),
        after: computedVerticalMargin.after ?? LayoutUnit(value: 0))
      top =
        containingBlockHeight
        - (usedVerticalMargin.before + borderTop + paddingTop + height! + paddingBottom
          + borderBottom + usedVerticalMargin.after + bottom!)
    }

    if height == nil && top != nil && bottom != nil {
      // #5
      usedVerticalMargin = UsedVerticalMargin.NonCollapsedValues(
        before: computedVerticalMargin.before ?? LayoutUnit(value: 0),
        after: computedVerticalMargin.after ?? LayoutUnit(value: 0))
      height =
        containingBlockHeight
        - (top! + usedVerticalMargin.before + borderTop + paddingTop + paddingBottom + borderBottom
          + usedVerticalMargin.after + bottom!)
    }

    if bottom == nil && top != nil && height != nil {
      // #6
      usedVerticalMargin = UsedVerticalMargin.NonCollapsedValues(
        before: computedVerticalMargin.before ?? LayoutUnit(value: 0),
        after: computedVerticalMargin.after ?? LayoutUnit(value: 0))
      bottom =
        containingBlockHeight
        - (top! + usedVerticalMargin.before + borderTop + paddingTop + height! + paddingBottom
          + borderBottom + usedVerticalMargin.after)
    }

    assert(top != nil)
    assert(bottom != nil)
    assert(height != nil)

    // For out-of-flow elements the containing block is formed by the padding edge of the ancestor.
    // At this point the positioned value is in the coordinate system of the padding box. Let's convert it to border box coordinate system.
    let containingBlockPaddingVerticalEdge = verticalConstraints.logicalTop
    top! += containingBlockPaddingVerticalEdge
    bottom! += containingBlockPaddingVerticalEdge

    return VerticalGeometry(
      top: top!, bottom: bottom!,
      contentHeightAndMargin: ContentHeightAndMargin(
        contentHeight: height!, nonCollapsedMargin: usedVerticalMargin))
  }

  func outOfFlowNonReplacedHorizontalGeometry(
    layoutBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    overriddenHorizontalValues: OverriddenHorizontalValues
  ) -> HorizontalGeometry {
    assert(layoutBox.isOutOfFlowPositioned() && !layoutBox.isReplacedBox())

    // 10.3.7 Absolutely positioned, non-replaced elements
    //
    // 'left' + 'margin-left' + 'border-left-width' + 'padding-left' + 'width' + 'padding-right' + 'border-right-width' + 'margin-right' + 'right'
    // = width of containing block

    // If all three of 'left', 'width', and 'right' are 'auto': First set any 'auto' values for 'margin-left' and 'margin-right' to 0.
    // Then, if the 'direction' property of the element establishing the static-position containing block is 'ltr' set 'left' to the static
    // position and apply rule number three below; otherwise, set 'right' to the static position and apply rule number one below.
    //
    // If none of the three is 'auto': If both 'margin-left' and 'margin-right' are 'auto', solve the equation under the extra constraint that the two margins get equal values,
    // unless this would make them negative, in which case when direction of the containing block is 'ltr' ('rtl'), set 'margin-left' ('margin-right') to zero and
    // solve for 'margin-right' ('margin-left'). If one of 'margin-left' or 'margin-right' is 'auto', solve the equation for that value.
    // If the values are over-constrained, ignore the value for 'left' (in case the 'direction' property of the containing block is 'rtl') or 'right'
    // (in case 'direction' is 'ltr') and solve for that value.
    //
    // Otherwise, set 'auto' values for 'margin-left' and 'margin-right' to 0, and pick the one of the following six rules that applies.
    //
    // 1. 'left' and 'width' are 'auto' and 'right' is not 'auto', then the width is shrink-to-fit. Then solve for 'left'
    // 2. 'left' and 'right' are 'auto' and 'width' is not 'auto', then if the 'direction' property of the element establishing the static-position
    //    containing block is 'ltr' set 'left' to the static position, otherwise set 'right' to the static position.
    //    Then solve for 'left' (if 'direction is 'rtl') or 'right' (if 'direction' is 'ltr').
    // 3. 'width' and 'right' are 'auto' and 'left' is not 'auto', then the width is shrink-to-fit . Then solve for 'right'
    // 4. 'left' is 'auto', 'width' and 'right' are not 'auto', then solve for 'left'
    // 5. 'width' is 'auto', 'left' and 'right' are not 'auto', then solve for 'width'
    // 6. 'right' is 'auto', 'left' and 'width' are not 'auto', then solve for 'right'

    let style = layoutBox.style
    let boxGeometry = formattingContext.geometryForBox(layoutBox: layoutBox)
    let containingBlockWidth = horizontalConstraints.logicalWidth
    let isLeftToRightDirection = FormattingContext.containingBlock(layoutBox: layoutBox).style
      .isLeftToRightDirection()

    var left = computedValue(
      geometryProperty: style.logicalLeft(), containingBlockWidth: containingBlockWidth)
    var right = computedValue(
      geometryProperty: style.logicalRight(), containingBlockWidth: containingBlockWidth)
    var width =
      overriddenHorizontalValues.width != nil
      ? overriddenHorizontalValues.width
      : computedWidth(layoutBox: layoutBox, containingBlockWidth: containingBlockWidth)
    let computedHorizontalMargin = computedHorizontalMargin(
      layoutBox: layoutBox, horizontalConstraints: horizontalConstraints)
    var usedHorizontalMargin = UsedHorizontalMargin()
    let paddingLeft = boxGeometry.paddingStart()
    let paddingRight = boxGeometry.paddingEnd()
    let borderLeft = boxGeometry.borderStart()
    let borderRight = boxGeometry.borderEnd()
    if left == nil && width == nil && right == nil {
      // If all three of 'left', 'width', and 'right' are 'auto': First set any 'auto' values for 'margin-left' and 'margin-right' to 0.
      // Then, if the 'direction' property of the element establishing the static-position containing block is 'ltr' set 'left' to the static
      // position and apply rule number three below; otherwise, set 'right' to the static position and apply rule number one below.
      usedHorizontalMargin = UsedHorizontalMargin(
        start: computedHorizontalMargin.start ?? LayoutUnit(value: 0),
        end: computedHorizontalMargin.end ?? LayoutUnit(value: 0))

      let staticHorizontalPosition = staticHorizontalPositionForOutOfFlowPositioned(
        layoutBox: layoutBox, horizontalConstraints: horizontalConstraints)
      if isLeftToRightDirection {
        left = staticHorizontalPosition
      } else {
        right = staticHorizontalPosition
      }
    } else if left != nil && width != nil && right != nil {
      // If none of the three is 'auto': If both 'margin-left' and 'margin-right' are 'auto', solve the equation under the extra constraint that the two margins get equal values,
      // unless this would make them negative, in which case when direction of the containing block is 'ltr' ('rtl'), set 'margin-left' ('margin-right') to zero and
      // solve for 'margin-right' ('margin-left'). If one of 'margin-left' or 'margin-right' is 'auto', solve the equation for that value.
      // If the values are over-constrained, ignore the value for 'left' (in case the 'direction' property of the containing block is 'rtl') or 'right'
      // (in case 'direction' is 'ltr') and solve for that value.
      if computedHorizontalMargin.start == nil && computedHorizontalMargin.end == nil {
        let marginStartAndEnd =
          containingBlockWidth
          - (left! + borderLeft + paddingLeft + width! + paddingRight + borderRight + right!)
        if marginStartAndEnd >= Int32(0) {
          usedHorizontalMargin = UsedHorizontalMargin(
            start: marginStartAndEnd / 2, end: marginStartAndEnd / 2)
        } else {
          if isLeftToRightDirection {
            usedHorizontalMargin.start = LayoutUnit(value: 0)
            usedHorizontalMargin.end =
              containingBlockWidth
              - (left! + usedHorizontalMargin.start + borderLeft + paddingLeft + width!
                + paddingRight + borderRight + right!)
          } else {
            usedHorizontalMargin.end = LayoutUnit(value: 0)
            usedHorizontalMargin.start =
              containingBlockWidth
              - (left! + borderLeft + paddingLeft + width! + paddingRight + borderRight
                + usedHorizontalMargin.end + right!)
          }
        }
      } else if computedHorizontalMargin.start == nil {
        usedHorizontalMargin.end = computedHorizontalMargin.end!
        usedHorizontalMargin.start =
          containingBlockWidth
          - (left! + borderLeft + paddingLeft + width! + paddingRight + borderRight
            + usedHorizontalMargin.end + right!)
      } else if computedHorizontalMargin.end == nil {
        usedHorizontalMargin.start = computedHorizontalMargin.start!
        usedHorizontalMargin.end =
          containingBlockWidth
          - (left! + usedHorizontalMargin.start + borderLeft + paddingLeft + width! + paddingRight
            + borderRight + right!)
      } else {
        usedHorizontalMargin = UsedHorizontalMargin(
          start: computedHorizontalMargin.start!, end: computedHorizontalMargin.end!)
        // Overconstrained? Ignore right (left).
        if isLeftToRightDirection {
          right =
            containingBlockWidth
            - (usedHorizontalMargin.start + left! + borderLeft + paddingLeft + width! + paddingRight
              + borderRight + usedHorizontalMargin.end)
        } else {
          left =
            containingBlockWidth
            - (usedHorizontalMargin.start + borderLeft + paddingLeft + width! + paddingRight
              + borderRight + usedHorizontalMargin.end + right!)
        }
      }
    } else {
      // Otherwise, set 'auto' values for 'margin-left' and 'margin-right' to 0, and pick the one of the following six rules that applies.
      usedHorizontalMargin = UsedHorizontalMargin(
        start: computedHorizontalMargin.start ?? LayoutUnit(value: 0),
        end: computedHorizontalMargin.end ?? LayoutUnit(value: 0))
    }

    if left == nil && width == nil && right != nil {
      // #1
      // Calculate the available width by solving for 'width' after setting 'left' (in case 1) to 0
      left = LayoutUnit(value: 0)
      let availableWidth =
        containingBlockWidth
        - (left! + usedHorizontalMargin.start + borderLeft + paddingLeft + paddingRight
          + borderRight + usedHorizontalMargin.end + right!)
      width = shrinkToFitWidth(formattingContextRoot: layoutBox, availableWidth: availableWidth)
      left =
        containingBlockWidth
        - (usedHorizontalMargin.start + borderLeft + paddingLeft + width! + paddingRight
          + borderRight + usedHorizontalMargin.end + right!)
    } else if left == nil && right == nil && width != nil {
      // #2
      let staticHorizontalPosition = staticHorizontalPositionForOutOfFlowPositioned(
        layoutBox: layoutBox, horizontalConstraints: horizontalConstraints)
      if isLeftToRightDirection {
        left = staticHorizontalPosition
        right =
          containingBlockWidth
          - (left! + usedHorizontalMargin.start + borderLeft + paddingLeft + width! + paddingRight
            + borderRight + usedHorizontalMargin.end)
      } else {
        right = staticHorizontalPosition
        left =
          containingBlockWidth
          - (usedHorizontalMargin.start + borderLeft + paddingLeft + width! + paddingRight
            + borderRight + usedHorizontalMargin.end + right!)
      }
    } else if width == nil && right == nil && left != nil {
      // #3
      // Calculate the available width by solving for 'width' after setting 'right' (in case 3) to 0
      right = LayoutUnit(value: 0)
      let availableWidth =
        containingBlockWidth
        - (left! + usedHorizontalMargin.start + borderLeft + paddingLeft + paddingRight
          + borderRight + usedHorizontalMargin.end + right!)
      width = shrinkToFitWidth(formattingContextRoot: layoutBox, availableWidth: availableWidth)
      right =
        containingBlockWidth
        - (left! + usedHorizontalMargin.start + borderLeft + paddingLeft + width! + paddingRight
          + borderRight + usedHorizontalMargin.end)
    } else if left == nil && width != nil && right != nil {
      // #4
      left =
        containingBlockWidth
        - (usedHorizontalMargin.start + borderLeft + paddingLeft + width! + paddingRight
          + borderRight + usedHorizontalMargin.end + right!)
    } else if width == nil && left != nil && right != nil {
      // #5
      width =
        containingBlockWidth
        - (left! + usedHorizontalMargin.start + borderLeft + paddingLeft + paddingRight
          + borderRight + usedHorizontalMargin.end + right!)
    } else if right == nil && left != nil && width != nil {
      // #6
      right =
        containingBlockWidth
        - (left! + usedHorizontalMargin.start + borderLeft + paddingLeft + width! + paddingRight
          + borderRight + usedHorizontalMargin.end)
    }

    assert(left != nil)
    assert(right != nil)
    assert(width != nil)

    // For out-of-flow elements the containing block is formed by the padding edge of the ancestor.
    // At this point the positioned value is in the coordinate system of the padding box. Let's convert it to border box coordinate system.
    let containingBlockPaddingVerticalEdge = horizontalConstraints.logicalLeft
    left! += containingBlockPaddingVerticalEdge
    right! += containingBlockPaddingVerticalEdge

    return HorizontalGeometry(
      left: left!, right: right!,
      contentWidthAndMargin: ContentWidthAndMargin(
        contentWidth: width!, usedMargin: usedHorizontalMargin))
  }

  func floatingReplacedContentHeightAndMargin(
    replacedBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    overriddenVerticalValues: OverriddenVerticalValues
  ) -> ContentHeightAndMargin {
    assert(replacedBox.isFloatingPositioned())

    // 10.6.2 Inline replaced elements, block-level replaced elements in normal flow, 'inline-block'
    // replaced elements in normal flow and floating replaced elements
    return inlineReplacedContentHeightAndMargin(
      replacedBox: replacedBox, horizontalConstraints: horizontalConstraints,
      verticalConstraints: nil, overriddenVerticalValues: overriddenVerticalValues)
  }

  func floatingReplacedContentWidthAndMargin(
    replacedBox: ElementBoxWrapper, horizontalConstraints: HorizontalConstraints,
    overriddenHorizontalValues: OverriddenHorizontalValues
  ) -> ContentWidthAndMargin {
    assert(replacedBox.isFloatingPositioned())

    // 10.3.6 Floating, replaced elements
    //
    // 1. If 'margin-left' or 'margin-right' are computed as 'auto', their used value is '0'.
    // 2. The used value of 'width' is determined as for inline replaced elements.
    let computedHorizontalMargin = computedHorizontalMargin(
      layoutBox: replacedBox, horizontalConstraints: horizontalConstraints)

    let usedMargin = UsedHorizontalMargin(
      start: computedHorizontalMargin.start ?? LayoutUnit(value: 0),
      end: computedHorizontalMargin.end ?? LayoutUnit(value: 0))
    return inlineReplacedContentWidthAndMargin(
      replacedBox: replacedBox, horizontalConstraints: horizontalConstraints,
      verticalConstraints: nil,
      overriddenHorizontalValues: OverriddenHorizontalValues(
        width: overriddenHorizontalValues.width, margin: usedMargin))
  }

  func floatingNonReplacedContentWidthAndMargin(
    layoutBox: BoxWrapper, horizontalConstraints: HorizontalConstraints,
    overriddenHorizontalValues: OverriddenHorizontalValues
  ) -> ContentWidthAndMargin {
    assert(layoutBox.isFloatingPositioned() && !layoutBox.isReplacedBox())

    // 10.3.5 Floating, non-replaced elements
    //
    // 1. If 'margin-left', or 'margin-right' are computed as 'auto', their used value is '0'.
    // 2. If 'width' is computed as 'auto', the used value is the "shrink-to-fit" width.

    let computedHorizontalMargin = computedHorizontalMargin(
      layoutBox: layoutBox, horizontalConstraints: horizontalConstraints)

    // #1
    let usedHorizontalMargin = UsedHorizontalMargin(
      start: computedHorizontalMargin.start ?? LayoutUnit(value: 0),
      end: computedHorizontalMargin.end ?? LayoutUnit(value: 0))
    // #2
    var width =
      overriddenHorizontalValues.width != nil
      ? overriddenHorizontalValues.width
      : computedWidth(
        layoutBox: layoutBox, containingBlockWidth: horizontalConstraints.logicalWidth)
    if width == nil {
      width = shrinkToFitWidth(
        formattingContextRoot: layoutBox, availableWidth: horizontalConstraints.logicalWidth)
    }
    return ContentWidthAndMargin(contentWidth: width!, usedMargin: usedHorizontalMargin)
  }

  func staticVerticalPositionForOutOfFlowPositioned(
    layoutBox: BoxWrapper, verticalConstraints: VerticalConstraints
  ) -> LayoutUnit {
    assert(layoutBox.isOutOfFlowPositioned())

    // For the purposes of this section and the next, the term "static position" (of an element) refers, roughly, to the position an element would have
    // had in the normal flow. More precisely, the static position for 'top' is the distance from the top edge of the containing block to the top margin
    // edge of a hypothetical box that would have been the first box of the element if its specified 'position' value had been 'static' and its specified
    // 'float' had been 'none' and its specified 'clear' had been 'none'. (Note that due to the rules in section 9.7 this might require also assuming a different
    // computed value for 'display'.) The value is negative if the hypothetical box is above the containing block.

    // Start with this box's border box offset from the parent's border box.
    var top = LayoutUnit()
    if layoutBox.previousInFlowSibling() != nil
      && layoutBox.previousInFlowSibling()!.isBlockLevelBox()
    {
      // Add sibling offset
      let previousInFlowSibling = layoutBox.previousInFlowSibling()!
      let previousInFlowBoxGeometry = formattingContext.geometryForBox(
        layoutBox: previousInFlowSibling,
        escapeReason: FormattingContext.EscapeReason.OutOfFlowBoxNeedsInFlowGeometry)
      let usedVerticalMarginForPreviousBox = (formattingContext as! BlockFormattingContext)
        .formattingState().usedVerticalMargin(layoutBox: previousInFlowSibling)

      top +=
        BoxGeometry.borderBoxRect(box: previousInFlowBoxGeometry).bottom()
        + usedVerticalMarginForPreviousBox.nonCollapsedValues.after
    } else {
      top = formattingContext.geometryForBox(
        layoutBox: layoutBox.parent(),
        escapeReason: FormattingContext.EscapeReason.OutOfFlowBoxNeedsInFlowGeometry
      ).contentBoxTop()
    }

    // Resolve top all the way up to the containing block.
    let containingBlock = FormattingContext.containingBlock(layoutBox: layoutBox)
    // Start with the parent since we pretend that this box is normal flow.
    var ancestor = layoutBox.parent()
    while ancestor !== containingBlock {
      let boxGeometry = formattingContext.geometryForBox(
        layoutBox: ancestor,
        escapeReason: FormattingContext.EscapeReason.OutOfFlowBoxNeedsInFlowGeometry)
      top += BoxGeometry.borderBoxTop(box: boxGeometry)
      assert(!ancestor.isPositioned() || layoutBox.isFixedPositioned())
      ancestor = FormattingContext.containingBlock(layoutBox: ancestor)
    }
    // Move the static position relative to the padding box. This is very specific to abolutely positioned boxes.
    return top - verticalConstraints.logicalTop
  }

  func staticHorizontalPositionForOutOfFlowPositioned(
    layoutBox: BoxWrapper, horizontalConstraints: HorizontalConstraints
  ) -> LayoutUnit {
    assert(layoutBox.isOutOfFlowPositioned())
    // See staticVerticalPositionForOutOfFlowPositioned for the definition of the static position.

    // Start with this box's border box offset from the parent's border box.
    var left = formattingContext.geometryForBox(
      layoutBox: layoutBox.parent(),
      escapeReason: FormattingContext.EscapeReason.OutOfFlowBoxNeedsInFlowGeometry
    ).contentBoxLeft()

    // Resolve left all the way up to the containing block.
    let containingBlock = FormattingContext.containingBlock(layoutBox: layoutBox)
    // Start with the parent since we pretend that this box is normal flow.
    var ancestor = layoutBox.parent()
    while ancestor !== containingBlock {
      let boxGeometry = formattingContext.geometryForBox(
        layoutBox: ancestor,
        escapeReason: FormattingContext.EscapeReason.OutOfFlowBoxNeedsInFlowGeometry)
      // BoxGeometry::left is the border box left position in its containing block's coordinate system.
      left += BoxGeometry.borderBoxLeft(box: boxGeometry)
      assert(!ancestor.isPositioned() || layoutBox.isFixedPositioned())
      ancestor = FormattingContext.containingBlock(layoutBox: ancestor)
    }
    // Move the static position relative to the padding box. This is very specific to abolutely positioned boxes.
    return left - horizontalConstraints.logicalLeft
  }

  enum HeightType {
    case Min
    case Max
    case Normal
  }
  func computedHeightValue(
    layoutBox: BoxWrapper, heightType: HeightType, containingBlockHeight: LayoutUnit?
  ) -> LayoutUnit? {
    let style = layoutBox.style
    let height =
      heightType == .Normal
      ? style.logicalHeight()
      : heightType == .Min ? style.logicalMinHeight() : style.logicalMaxHeight()
    if height.isUndefined() || height.isAuto() || height.isMaxContent() || height.isMinContent()
      || height.isFitContent()
    {
      return nil
    }

    if height.isFixed() {
      return LayoutUnit(value: height.value())
    }

    var containingBlockHeightCopy = containingBlockHeight

    if containingBlockHeightCopy == nil {
      if layoutState().inQuirksMode() {
        // FIXME: computedHeightValue needs to be moved to Block/Table/etc FormattingGeometry.
        // Use heightValueOfNearestContainingBlockWithFixedHeight;
        fatalError("Not implemented yet")
      } else {
        containingBlockHeightCopy = FormattingGeometry.fixedValue(
          geometryProperty: FormattingGeometry.nonAnonymousContainingBlockLogicalHeight(
            layoutBox: layoutBox))
      }
    }

    if containingBlockHeightCopy == nil {
      return nil
    }

    return valueForLength(length: height, maximumValue: containingBlockHeightCopy!)
  }

  static func nonAnonymousContainingBlockLogicalHeight(layoutBox: BoxWrapper) -> LengthWrapper {
    // When the block level box is a direct child of an inline level box (<span><div></div></span>) and we wrap it into a continuation,
    // the containing block (anonymous wrapper) is not the box we need to check for fixed height.
    for containingBlock in containingBlockChain(layoutBox: layoutBox) {
      if containingBlock.isAnonymous() {
        continue
      }
      return containingBlock.style.logicalHeight()
    }
    fatalError("Not reached")
  }

  var formattingContext: FormattingContext
}
