/*
 * Copyright (C) 2011 Google Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *
 *     * Redistributions of source code must retain the above copyright
 * notice, this list of conditions and the following disclaimer.
 *     * Redistributions in binary form must reproduce the above
 * copyright notice, this list of conditions and the following disclaimer
 * in the documentation and/or other materials provided with the
 * distribution.
 *     * Neither the name of Google Inc. nor the names of its
 * contributors may be used to endorse or promote products derived from
 * this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

// RAII class which defines a scope in which overriding sizes of a box are either:
//   1) replaced by other size in one axis if size is specified
//   2) cleared in both axis if size == nil
//
// In any case the previous overriding sizes are restored on destruction (in case of
// not having a previous value it's simply cleared).
struct OverridingSizesScope: ~Copyable {
  enum Axis {
    case Inline
    case Block
    case Both
  }

  init(box: RenderBoxWrapper, axis: Axis, size: LayoutUnit? = nil) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  deinit {
    if axis == .Inline || axis == .Both {
      setOrClearOverridingWidth(size: overridingWidth)
    }

    if axis == .Block || axis == .Both {
      setOrClearOverridingHeight(size: overridingHeight)
    }
  }

  private func setOrClearOverridingWidth(size: LayoutUnit?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func setOrClearOverridingHeight(size: LayoutUnit?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let axis: Axis
  private let overridingWidth: LayoutUnit?
  private let overridingHeight: LayoutUnit?
}

class RenderFlexibleBoxWrapper: RenderBlockWrapper {
  convenience init(type: `Type`, document: Document, style: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func avoidsFloats() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layoutBlock(
    relayoutChildren: Bool, pageLogicalHeight: LayoutUnit = LayoutUnit(value: UInt64(0))
  ) {
    assert(needsLayout())

    if !relayoutChildren && simplifiedLayout() {
      return
    }

    let repainter = LayoutRepainter(renderer: self)

    resetLogicalHeightBeforeLayoutIfNeeded()
    relaidOutFlexItems.clear()

    let oldInLayout = inLayout
    inLayout = true

    if !style().marginTrim().isEmpty {
      initializeMarginTrimState()
    }

    var relayoutChildren = relayoutChildren
    if recomputeLogicalWidth() {
      relayoutChildren = true
    }

    let previousHeight = logicalHeight()
    setLogicalHeight(size: borderAndPaddingLogicalHeight() + scrollbarLogicalHeight())
    do {
      let _ = LayoutStateMaintainer(
        root: self, offset: locationOffset(),
        disablePaintOffsetCache: isTransformed() || hasReflection()
          || style().isFlippedBlocksWritingMode())

      preparePaginationBeforeBlockLayout(relayoutChildren: &relayoutChildren)

      numberOfFlexItemsOnFirstLine = 0
      numberOfFlexItemsOnLastLine = 0
      justifyContentStartOverflow = LayoutUnit(value: 0)

      beginUpdateScrollInfoAfterLayoutTransaction()

      prepareOrderIteratorAndMargins()

      // Fieldsets need to find their legend and position it inside the border of the object.
      // The legend then gets skipped during normal layout. The same is true for ruby text.
      // It doesn't get included in the normal layout process but is instead skipped.
      layoutExcludedChildren(relayoutChildren: relayoutChildren)

      let oldFlexItemRects = appendFlexItemFrameRects()

      performFlexLayout(relayoutChildren: relayoutChildren)

      endAndCommitUpdateScrollInfoAfterLayoutTransaction()

      if logicalHeight() != previousHeight {
        relayoutChildren = true
      }

      layoutPositionedObjects(relayoutChildren: relayoutChildren || isDocumentElementRenderer())

      repaintFlexItemsDuringLayoutIfMoved(oldFlexItemRects: oldFlexItemRects)
      // FIXME: css3/flexbox/repaint-rtl-column.html seems to repaint more overflow than it needs to.
      computeOverflow(
        oldClientAfterEdge: RenderBlockWrapper.layoutOverflowLogicalBottom(renderer: self))

      updateDescendantTransformsAfterLayout()
    }
    updateLayerTransform()

    // We have to reset this, because changes to our ancestors' style can affect
    // this value. Also, this needs to be before we call updateAfterLayout, as
    // that function may re-enter this one.
    resetHasDefiniteHeight()

    // Update our scroll information if we're overflow:auto/scroll/hidden now that we know if we overflow or not.
    updateScrollInfoAfterLayout()

    repainter.repaintAfterLayout()

    clearNeedsLayout()

    inLayout = oldInLayout
  }

  private func isHorizontalFlow() -> Bool {
    if isHorizontalWritingMode() {
      return !isColumnFlow()
    }
    return isColumnFlow()
  }

  func isFlexibleBoxImpl() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func usedFlexItemOverridingLogicalHeightForPercentageResolution(flexItem: RenderBoxWrapper)
    -> LayoutUnit?
  {
    if mainAxisIsFlexItemInlineAxis(flexItem: flexItem) {
      return usedFlexItemOverridingCrossSizeForPercentageResolution(flexItem: flexItem)
    }
    return usedFlexItemOverridingMainSizeForPercentageResolution(flexItem: flexItem)
  }

  func clearCachedMainSizeForFlexItem(flexItem: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clearCachedFlexItemIntrinsicContentLogicalHeight(flexItem: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private enum GapType {
    case BetweenLines
    case BetweenItems
  }

  private func computeGap(gapType: GapType) -> LayoutUnit {
    // row-gap is used for gaps between flex items in column flows or for gaps between lines in row flows.
    let usesRowGap = (gapType == .BetweenItems) == isColumnFlow()
    let gapLength = usesRowGap ? style().rowGap() : style().columnGap()
    if gapLength.isNormal {
      return LayoutUnit()
    }

    let availableSize =
      usesRowGap
      ? (availableLogicalHeightForPercentageComputation() ?? LayoutUnit(value: UInt64(0)))
      : contentLogicalWidth()
    return minimumValueForLength(length: gapLength.length, maximumValue: availableSize)
  }

  func shouldApplyMinBlockSizeAutoForFlexItem(flexItem: RenderBoxWrapper) -> Bool {
    return !mainAxisIsFlexItemInlineAxis(flexItem: flexItem)
      && shouldApplyMinSizeAutoForFlexItem(flexItem: flexItem)
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    if shouldApplySizeOrInlineSizeContainment() {
      if let width = explicitIntrinsicInnerLogicalWidth() {
        minLogicalWidth = width
        maxLogicalWidth = width
      }
      addScrollbarWidth(minLogicalWidth: &minLogicalWidth, maxLogicalWidth: &maxLogicalWidth)
      return
    }

    var flexItemMinWidth = LayoutUnit()
    var flexItemMaxWidth = LayoutUnit()
    var hadExcludedChildren = false
    if let (preferredMinWidth, preferredMaxWidth) = computePreferredWidthsForExcludedChildren() {
      flexItemMinWidth = preferredMinWidth
      flexItemMaxWidth = preferredMaxWidth
      hadExcludedChildren = true
    }

    // FIXME: We're ignoring flex-basis here and we shouldn't. We can't start
    // honoring it though until the flex shorthand stops setting it to 0. See
    // https://bugs.webkit.org/show_bug.cgi?id=116117 and
    // https://crbug.com/240765.
    var numItemsWithNormalLayout: UInt64 = 0
    var flexItem = firstChildBox()
    while flexItem != nil {
      if flexItem!.isOutOfFlowPositioned() || flexItem!.isExcludedFromNormalLayout() {
        flexItem = flexItem!.nextSiblingBox()
        continue
      }
      numItemsWithNormalLayout += 1

      // Pre-layout orthogonal children in order to get a valid value for the preferred width.
      if style().isHorizontalWritingMode() != flexItem!.style().isHorizontalWritingMode() {
        flexItem!.layoutIfNeeded()
      }

      let margin = marginIntrinsicLogicalWidthForChild(child: flexItem!)

      var (minPreferredLogicalWidth, maxPreferredLogicalWidth) = computeChildPreferredLogicalWidths(
        child: flexItem!)

      minPreferredLogicalWidth += margin
      maxPreferredLogicalWidth += margin

      if !isColumnFlow() {
        maxLogicalWidth += maxPreferredLogicalWidth
        if isMultiline() {
          // For multiline, the min preferred width is if you put a break between
          // each item.
          minLogicalWidth = max(minLogicalWidth, minPreferredLogicalWidth)
        } else {
          minLogicalWidth += minPreferredLogicalWidth
        }
      } else {
        minLogicalWidth = max(minPreferredLogicalWidth, minLogicalWidth)
        maxLogicalWidth = max(maxPreferredLogicalWidth, maxLogicalWidth)
      }

      flexItem = flexItem!.nextSiblingBox()
    }

    if !isColumnFlow() && numItemsWithNormalLayout > 1 {
      let inlineGapSize = (numItemsWithNormalLayout - 1) * computeGap(gapType: .BetweenItems)
      maxLogicalWidth += inlineGapSize
      if !isMultiline() {
        minLogicalWidth += inlineGapSize
      }
    }

    maxLogicalWidth = max(minLogicalWidth, maxLogicalWidth)

    let zero = LayoutUnit(value: UInt64(0))
    // Due to negative margins, it is possible that we calculated a negative
    // intrinsic width. Make sure that we never return a negative width.
    minLogicalWidth = max(zero, minLogicalWidth)
    maxLogicalWidth = max(zero, maxLogicalWidth)

    if hadExcludedChildren {
      minLogicalWidth = max(minLogicalWidth, flexItemMinWidth)
      maxLogicalWidth = max(maxLogicalWidth, flexItemMaxWidth)
    }

    addScrollbarWidth(minLogicalWidth: &minLogicalWidth, maxLogicalWidth: &maxLogicalWidth)
  }

  private func addScrollbarWidth(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    let scrollbarWidth = LayoutUnit(value: scrollbarLogicalWidth())
    maxLogicalWidth += scrollbarWidth
    minLogicalWidth += scrollbarWidth
  }

  private enum FlexSign {
    case PositiveFlexibility
    case NegativeFlexibility
  }

  private enum SizeDefiniteness {
    case Definite
    case Indefinite
    case Unknown
  }

  // TODO(asuhan): Use an inline capacity of 8, since flexbox containers usually have less than 8 children.
  private typealias FlexItemFrameRects = [LayoutRectWrapper]

  private struct LineState {
    init(
      crossAxisOffset: LayoutUnit, crossAxisExtent: LayoutUnit,
      baselineAlignmentState: BaselineAlignmentState?, flexLayoutItems: FlexLayoutItems
    ) {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    let flexLayoutItems: FlexLayoutItems
  }

  private typealias FlexLineStates = [LineState]
  private typealias FlexLayoutItems = [FlexLayoutItem]

  private func mainAxisIsFlexItemInlineAxis(flexItem: RenderBoxWrapper) -> Bool {
    return isHorizontalFlow() == flexItem.isHorizontalWritingMode()
  }

  private func isColumnFlow() -> Bool {
    return style().isColumnFlexDirection()
  }

  private func isMultiline() -> Bool {
    return style().flexWrap() != .NoWrap
  }

  private func flexBasisForFlexItem(flexItem: RenderBoxWrapper) -> LengthWrapper {
    var flexLength = flexItem.style().flexBasis()
    if flexLength.isAuto() {
      flexLength = mainSizeLengthForFlexItem(sizeType: .MainOrPreferredSize, flexItem: flexItem)
    }
    return flexLength
  }

  private func mainSizeLengthForFlexItem(
    sizeType: RenderBoxWrapper.SizeType, flexItem: RenderBoxWrapper
  ) -> LengthWrapper {
    switch sizeType {
    case .MinSize:
      return isHorizontalFlow() ? flexItem.style().minWidth() : flexItem.style().minHeight()
    case .MainOrPreferredSize:
      return isHorizontalFlow() ? flexItem.style().width() : flexItem.style().height()
    case .MaxSize:
      return isHorizontalFlow() ? flexItem.style().maxWidth() : flexItem.style().maxHeight()
    }
  }

  private func crossSizeLengthForFlexItem(
    sizeType: RenderBoxWrapper.SizeType, flexItem: RenderBoxWrapper
  ) -> LengthWrapper {
    switch sizeType {
    case .MinSize:
      return isHorizontalFlow() ? flexItem.style().minHeight() : flexItem.style().minWidth()
    case .MainOrPreferredSize:
      return isHorizontalFlow() ? flexItem.style().height() : flexItem.style().width()
    case .MaxSize:
      return isHorizontalFlow() ? flexItem.style().maxHeight() : flexItem.style().maxWidth()
    }
  }

  // https://drafts.csswg.org/css-flexbox/#min-size-auto
  private func shouldApplyMinSizeAutoForFlexItem(flexItem: RenderBoxWrapper) -> Bool {
    let minSize = mainSizeLengthForFlexItem(sizeType: .MinSize, flexItem: flexItem)
    // min, max and fit-content are equivalent to the automatic size for block sizes https://drafts.csswg.org/css-sizing-3/#valdef-width-min-content.
    let flexItemBlockSizeIsEquivalentToAutomaticSize =
      !mainAxisIsFlexItemInlineAxis(flexItem: flexItem)
      && (minSize.isMinContent() || minSize.isMaxContent() || minSize.isFitContent())

    return (minSize.isAuto() || flexItemBlockSizeIsEquivalentToAutomaticSize)
      && (mainAxisOverflowForFlexItem(flexItem: flexItem) == .Visible)
  }

  private func mainAxisContentExtent(contentLogicalHeight: LayoutUnit) -> LayoutUnit {
    if !isColumnFlow() {
      return contentLogicalWidth()
    }

    let borderPaddingAndScrollbar = borderAndPaddingLogicalHeight() + scrollbarLogicalHeight()
    let borderBoxLogicalHeight = contentLogicalHeight + borderPaddingAndScrollbar
    let computedValues = computeLogicalHeight(
      logicalHeight: borderBoxLogicalHeight, logicalTop: logicalTop())
    if computedValues.extent == LayoutUnit.max() {
      return computedValues.extent
    }
    return max(LayoutUnit(value: UInt64(0)), computedValues.extent - borderPaddingAndScrollbar)
  }

  private func transformedBlockFlowDirection() -> FlowDirection {
    let blockFlowDirection = style().blockFlowDirection()
    if !isColumnFlow() {
      return blockFlowDirection
    }

    switch blockFlowDirection {
    case .TopToBottom, .BottomToTop:
      return style().isLeftToRightDirection() ? .LeftToRight : .RightToLeft
    case .LeftToRight, .RightToLeft:
      return style().isLeftToRightDirection() ? .TopToBottom : .BottomToTop
    }
  }

  private func flowAwareBorderBefore() -> LayoutUnit {
    switch transformedBlockFlowDirection() {
    case .TopToBottom:
      return borderTop()
    case .BottomToTop:
      return borderBottom()
    case .LeftToRight:
      return borderLeft()
    case .RightToLeft:
      return borderRight()
    }
  }

  private func flowAwarePaddingBefore() -> LayoutUnit {
    switch transformedBlockFlowDirection() {
    case .TopToBottom:
      return paddingTop()
    case .BottomToTop:
      return paddingBottom()
    case .LeftToRight:
      return paddingLeft()
    case .RightToLeft:
      return paddingRight()
    }
  }

  private func crossAxisMarginExtentForFlexItem(flexItem: RenderBoxWrapper) -> LayoutUnit {
    if !flexItem.needsLayout() {
      return isHorizontalFlow()
        ? flexItem.verticalMarginExtent() : flexItem.horizontalMarginExtent()
    }

    var marginStart = LayoutUnit()
    var marginEnd = LayoutUnit()
    if isHorizontalFlow() {
      flexItem.computeBlockDirectionMargins(
        containingBlock: self, marginBefore: &marginStart, marginAfter: &marginEnd)
    } else {
      flexItem.computeInlineDirectionMargins(
        containingBlock: self,
        containerWidth: flexItem.containingBlockLogicalWidthForContentInFragment(fragment: nil),
        availableSpaceAdjustedWithFloats: flexItem.logicalWidth(), childWidth: LayoutUnit(),
        marginStart: &marginStart, marginEnd: &marginEnd)
    }
    return marginStart + marginEnd
  }

  private func crossAxisIsPhysicalWidth() -> Bool {
    return (isHorizontalWritingMode() && isColumnFlow())
      || (!isHorizontalWritingMode() && !isColumnFlow())
  }

  private func flexItemCrossSizeShouldUseContainerCrossSize(flexItem: RenderBoxWrapper) -> Bool {
    // 9.8 https://drafts.csswg.org/css-flexbox/#definite-sizes
    // 1. If a single-line flex container has a definite cross size, the automatic preferred outer cross size of any
    // stretched flex items is the flex container's inner cross size (clamped to the flex item's min and max cross size)
    // and is considered definite.
    if !isMultiline() && alignmentForFlexItem(flexItem: flexItem) == .Stretch
      && !hasAutoMarginsInCrossAxis(flexItem: flexItem)
      && crossSizeLengthForFlexItem(sizeType: .MainOrPreferredSize, flexItem: flexItem).isAuto()
    {
      if crossAxisIsPhysicalWidth() {
        return true
      }
      // This must be kept in sync with computeMainSizeFromAspectRatioUsing().
      let crossSize = isHorizontalFlow() ? style().height() : style().width()
      return crossSize.isFixed()
        || (crossSize.isPercent() && availableLogicalHeightForPercentageComputation() != nil)
    }
    return false
  }

  // This refers to https://drafts.csswg.org/css-flexbox-1/#definite-sizes, section 1).
  private func computeCrossSizeForFlexItemUsingContainerCrossSize(flexItem: RenderBoxWrapper)
    -> LayoutUnit
  {
    if crossAxisIsPhysicalWidth() {
      return contentWidth()
    }

    return max(
      LayoutUnit(value: UInt64(0)),
      definiteSizeValue() - crossAxisMarginExtentForFlexItem(flexItem: flexItem))
  }

  // Keep this sync'ed with flexItemCrossSizeShouldUseContainerCrossSize().
  private func definiteSizeValue() -> LayoutUnit {
    // Let's compute the definite size value for the flex item (value that we can resolve without running layout).
    let isHorizontal = isHorizontalFlow()
    let size = isHorizontal ? style().height() : style().width()
    assert(
      size.isFixed()
        || (size.isPercent() && availableLogicalHeightForPercentageComputation() != nil))
    var definiteValue = LayoutUnit(value: size.value())
    if size.isPercent() {
      definiteValue =
        availableLogicalHeightForPercentageComputation() ?? LayoutUnit(value: UInt64(0))
    }

    let maximumSize = isHorizontal ? style().maxHeight() : style().maxWidth()
    if maximumSize.isFixed() {
      definiteValue = min(definiteValue, LayoutUnit(value: maximumSize.value()))
    }

    let minimumSize = isHorizontal ? style().minHeight() : style().minWidth()
    if minimumSize.isFixed() {
      definiteValue = max(definiteValue, LayoutUnit(value: minimumSize.value()))
    }

    return definiteValue
  }

  override func computeChildIntrinsicLogicalWidths(child: RenderObjectWrapper) -> (
    LayoutUnit, LayoutUnit
  ) {
    let flexItem = child as! RenderBoxWrapper

    // If the item cross size should use the definite container cross size then set the overriding size now so
    // the intrinsic sizes are properly computed in the presence of aspect ratios. The only exception is when
    // we are both a flex item&container, because our parent might have already set our overriding size.
    if flexItemCrossSizeShouldUseContainerCrossSize(flexItem: flexItem) && !isFlexItem() {
      let axis: OverridingSizesScope.Axis =
        mainAxisIsFlexItemInlineAxis(flexItem: flexItem) ? .Block : .Inline
      let _ = OverridingSizesScope(
        box: flexItem, axis: axis,
        size: computeCrossSizeForFlexItemUsingContainerCrossSize(flexItem: flexItem))
      return super.computeChildIntrinsicLogicalWidths(child: flexItem)
    }

    let _ = OverridingSizesScope(box: flexItem, axis: .Both)
    return super.computeChildIntrinsicLogicalWidths(child: flexItem)
  }

  private func alignmentForFlexItem(flexItem: RenderBoxWrapper) -> ItemPosition {
    var align = flexItem.style().resolvedAlignSelf(
      parentStyle: style(), normalValueBehaviour: selfAlignmentNormalBehavior()
    ).position
    assert(align != .Auto && align != .Normal)
    // Left and Right are only for justify-*.
    assert(align != .Left && align != .Right)

    // We can safely return here because start/end are not affected by a reversed flex-wrap because the
    // alignment container is the flex line, and in a wrap reversed flex container the start and end within
    // a flex line are still the same. Contrary to this flex-start/flex-end depend on the flex container
    // start/end edges which are flipped in the case of wrap-reverse.
    if align == .Start {
      return .FlexStart
    }
    if align == .End {
      return .FlexEnd
    }

    if align == .SelfStart || align == .SelfEnd {
      // self-start corresponds to flex-start (and self-end to flex-end) in the majority of the cases
      // for orthogonal layouts except when the container is flipped blocks writing mode (vrl/hbt) and
      // the child is ltr or the other way around. For example:
      // 1) htb ltr child inside a vrl container: self-start corresponds to flex-end
      // 2) htb rtl child inside a vlr container: self-end corresponds to flex-start
      let isOrthogonal =
        style().isHorizontalWritingMode() != flexItem.style().isHorizontalWritingMode()
      if isOrthogonal
        && (style().isFlippedBlocksWritingMode() == flexItem.style().isLeftToRightDirection())
      {
        return align == .SelfStart ? .FlexEnd : .FlexStart
      }

      if !isOrthogonal {
        if style().isFlippedLinesWritingMode() != flexItem.style().isFlippedLinesWritingMode() {
          return align == .SelfStart ? .FlexEnd : .FlexStart
        }
        if style().isLeftToRightDirection() != flexItem.style().isLeftToRightDirection() {
          return align == .SelfStart ? .FlexEnd : .FlexStart
        }
      }

      return align == .SelfStart ? .FlexStart : .FlexEnd
    }

    if style().flexWrap() == .Reverse {
      if align == .FlexStart {
        align = .FlexEnd
      } else if align == .FlexEnd {
        align = .FlexStart
      }
    }

    return align
  }

  private func canComputePercentageFlexBasis(
    flexItem: RenderBoxWrapper, flexBasis: LengthWrapper,
    updateDescendants: UpdatePercentageHeightDescendants
  ) -> Bool {
    if !isColumnFlow() || hasDefiniteHeight == .Definite {
      return true
    }
    if hasDefiniteHeight == .Indefinite {
      return false
    }
    let definite =
      flexItem.computePercentageLogicalHeight(
        height: flexBasis, updateDescendants: updateDescendants) != nil
    if inLayout && (isHorizontalWritingMode() == flexItem.isHorizontalWritingMode()) {
      // We can reach this code even while we're not laying ourselves out, such
      // as from mainSizeForPercentageResolution.
      hasDefiniteHeight = definite ? .Definite : .Indefinite
    }
    return definite
  }

  private func flexItemMainSizeIsDefinite(flexItem: RenderBoxWrapper, flexBasis: LengthWrapper)
    -> Bool
  {
    if flexBasis.isAuto() || flexBasis.isContent() {
      return false
    }
    if !mainAxisIsFlexItemInlineAxis(flexItem: flexItem)
      && (flexBasis.isIntrinsic() || flexBasis.type() == .Intrinsic)
    {
      return false
    }
    if flexBasis.isPercentOrCalculated() {
      return canComputePercentageFlexBasis(
        flexItem: flexItem, flexBasis: flexBasis, updateDescendants: .No)
    }
    return true
  }

  private func mainAxisOverflowForFlexItem(flexItem: RenderBoxWrapper) -> Overflow {
    if isHorizontalFlow() {
      return flexItem.style().overflowX()
    }
    return flexItem.style().overflowY()
  }

  private func usedFlexItemOverridingCrossSizeForPercentageResolution(flexItem: RenderBoxWrapper)
    -> LayoutUnit?
  {
    assert(mainAxisIsFlexItemInlineAxis(flexItem: flexItem))
    if alignmentForFlexItem(flexItem: flexItem) != .Stretch {
      return nil
    }
    return flexItem.overridingLogicalHeight()
  }

  // This method is only called whenever a descendant of a flex item wants to resolve a percentage in its
  // block axis (logical height). The key here is that percentages should be generally resolved before the
  // flex item is flexed, meaning that they shouldn't be recomputed once the flex item has been flexed. There
  // are some exceptions though that are implemented here, like the case of fully inflexible items with
  // definite flex-basis, or whenever the flex container has a definite main size. See
  // https://drafts.csswg.org/css-flexbox/#definite-sizes for additional details.
  private func usedFlexItemOverridingMainSizeForPercentageResolution(flexItem: RenderBoxWrapper)
    -> LayoutUnit?
  {
    assert(!mainAxisIsFlexItemInlineAxis(flexItem: flexItem))

    // The main size of a fully inflexible item with a definite flex basis is, by definition, definite.
    if flexItem.style().flexGrow() == 0.0 && flexItem.style().flexShrink() == 0.0
      && flexItemMainSizeIsDefinite(
        flexItem: flexItem, flexBasis: flexBasisForFlexItem(flexItem: flexItem))
    {
      return flexItem.overridingLogicalHeight()
    }

    // This function implements section 9.8. Definite and Indefinite Sizes, case 2) of the flexbox spec.
    // If the flex container has a definite main size the flex item post-flexing main size is also treated
    // as definite. We make up a percentage to check whether we have a definite size.
    if !canComputePercentageFlexBasis(
      flexItem: flexItem, flexBasis: LengthWrapper(value: Int32(0), type: .Percent),
      updateDescendants: .Yes)
    {
      return nil
    }

    return flexItem.overridingLogicalHeight()

  }

  private func performFlexLayout(relayoutChildren: Bool) {
    if layoutUsingFlexFormattingContext() {
      return
    }

    var lineStates = FlexLineStates()
    let sumFlexBaseSize = LayoutUnit()
    var totalFlexGrow: Float64 = 0
    var totalFlexShrink: Float64 = 0
    var totalWeightedFlexShrink: Float64 = 0
    let sumHypotheticalMainSize = LayoutUnit()

    // Set up our master list of flex items. All of the rest of the algorithm
    // should work off this list of a subset.
    // TODO(cbiesinger): That second part is not yet true.
    var allItems = FlexLayoutItems()
    orderIterator!.first()
    var flexItem = orderIterator!.currentChild()
    while flexItem != nil {
      if orderIterator!.shouldSkipChild(child: flexItem!) {
        // Out-of-flow children are not flex items, so we skip them here.
        if flexItem!.isOutOfFlowPositioned() {
          prepareFlexItemForPositionedLayout(flexItem: flexItem!)
        }
        flexItem = orderIterator!.next()
        continue
      }
      allItems.append(
        constructFlexLayoutItem(flexItem: flexItem!, relayoutChildren: relayoutChildren))
      // constructFlexItem() might set the override containing block height so any value cached for definiteness might be incorrect.
      resetHasDefiniteHeight()
      flexItem = orderIterator!.next()
    }

    let lineBreakLength = mainAxisContentExtent(contentLogicalHeight: LayoutUnit.max())
    let gapBetweenItems = computeGap(gapType: .BetweenItems)
    let gapBetweenLines = computeGap(gapType: .BetweenLines)
    let flexAlgorithm = FlexLayoutAlgorithm(
      flexbox: self, lineBreakLength: lineBreakLength, allItems: allItems,
      gapBetweenItems: gapBetweenItems, gapBetweenLines: gapBetweenLines)
    var crossAxisOffset = flowAwareBorderBefore() + flowAwarePaddingBefore()
    var lineItems = FlexLayoutItems()
    var nextIndex: UInt64 = 0
    var numLines: UInt64 = 0
    // TODO(asuhan): call into InspectorInstrumentation
    repeat {
      let nextFlexLine = flexAlgorithm.computeNextFlexLine(nextIndex: &nextIndex)
      if nextFlexLine.lineItems.count == 0 {
        break
      }
      numLines += 1
      // TODO(asuhan): call into InspectorInstrumentation
      // Cross axis margins should only be trimmed if they are on the first/last flex line
      let shouldTrimCrossAxisStart = shouldTrimCrossAxisMarginStart() && lineStates.isEmpty
      let shouldTrimCrossAxisEnd =
        shouldTrimCrossAxisMarginEnd()
        && CPtrToInt(allItems.last!.renderer.p) == CPtrToInt(lineItems.last!.renderer.p)
      if shouldTrimCrossAxisStart || shouldTrimCrossAxisEnd {
        for flexLayoutItem in lineItems {
          if shouldTrimCrossAxisStart {
            trimCrossAxisMarginStart(flexLayoutItem: flexLayoutItem)
          }
          if shouldTrimCrossAxisEnd {
            trimCrossAxisMarginEnd(flexLayoutItem: flexLayoutItem)
          }
        }
      }
      let containerMainInnerSize = mainAxisContentExtent(
        contentLogicalHeight: sumHypotheticalMainSize)
      // availableFreeSpace is the initial amount of free space in this flexbox.
      // remainingFreeSpace starts out at the same value but as we place and lay
      // out flex items we subtract from it. Note that both values can be
      // negative.
      var remainingFreeSpace = containerMainInnerSize - sumFlexBaseSize
      let flexSign: FlexSign =
        (sumHypotheticalMainSize < containerMainInnerSize)
        ? .PositiveFlexibility : .NegativeFlexibility
      freezeInflexibleItems(
        flexSign: flexSign, flexLayoutItems: &lineItems, remainingFreeSpace: &remainingFreeSpace,
        totalFlexGrow: &totalFlexGrow, totalFlexShrink: &totalFlexShrink,
        totalWeightedFlexShrink: &totalWeightedFlexShrink)
      // The initial free space gets calculated after freezing inflexible items.
      // https://drafts.csswg.org/css-flexbox/#resolve-flexible-lengths step 3
      let initialFreeSpace = remainingFreeSpace
      while !resolveFlexibleLengths(
        flexSign: flexSign, flexLayoutItems: &lineItems, initialFreeSpace: initialFreeSpace,
        remainingFreeSpace: &remainingFreeSpace, totalFlexGrow: &totalFlexGrow,
        totalFlexShrink: &totalFlexShrink,
        totalWeightedFlexShrink: &totalWeightedFlexShrink)
      {
        assert(totalFlexGrow >= 0)
        assert(totalWeightedFlexShrink >= 0)
      }

      // Recalculate the remaining free space. The adjustment for flex factors
      // between 0..1 means we can't just use remainingFreeSpace here.
      remainingFreeSpace = containerMainInnerSize
      for flexLayoutItem in lineItems {
        assert(!flexLayoutItem.renderer.isOutOfFlowPositioned())
        remainingFreeSpace -= flexLayoutItem.flexedMarginBoxSize()
      }
      remainingFreeSpace -= (lineItems.count - 1) * gapBetweenItems

      // This will move lineItems into a newly-created LineState.
      layoutAndPlaceFlexItems(
        crossAxisOffset: &crossAxisOffset, flexLayoutItems: &lineItems,
        availableFreeSpace: remainingFreeSpace, relayoutChildren: relayoutChildren,
        lineStates: &lineStates,
        gapBetweenItems: gapBetweenItems)
    } while true

    if !lineStates.isEmpty {
      numberOfFlexItemsOnFirstLine = UInt64(lineStates.first!.flexLayoutItems.count)
      numberOfFlexItemsOnLastLine = numberOfFlexItemsOnFirstLine
    }

    if hasLineIfEmpty() {
      // Even if computeNextFlexLine returns true, the flexbox might not have
      // a line because all our children might be out of flow positioned.
      // Instead of just checking if we have a line, make sure the flexbox
      // has at least a line's worth of height to cover this case.
      let minHeight =
        borderAndPaddingLogicalHeight()
        + lineHeight(
          firstLine: true, direction: isHorizontalWritingMode() ? .HorizontalLine : .VerticalLine,
          linePositionMode: .PositionOfInteriorLineBoxes) + scrollbarLogicalHeight()
      if size().height() < minHeight {
        setLogicalHeight(size: minHeight)
      }
    }

    if !isColumnFlow() && numLines > 1 {
      setLogicalHeight(size: logicalHeight() + computeGap(gapType: .BetweenLines) * (numLines - 1))
    }

    updateLogicalHeight()
    repositionLogicalHeightDependentFlexItems(
      lineStates: &lineStates, gapBetweenLines: gapBetweenLines)
  }

  private func initializeMarginTrimState() {
    // When computeIntrinsicLogicalWidth goes through each of the children, it
    // will include the margins when computing the flexbox's min and max widths.
    // We need to trim the margins of the first and last child early so that
    // these margins do not incorrectly constribute to the box's min/max width
    let marginTrim = style().marginTrim()
    let isRowsFlexbox = isHorizontalFlow()
    if let flexItem = firstInFlowChildBox(), marginTrim.contains(.InlineStart) {
      if isRowsFlexbox {
        marginTrimItems.itemsAtFlexLineStart.add(value: flexItem)
      } else {
        marginTrimItems.itemsOnFirstFlexLine.add(value: flexItem)
      }
    }
    if let flexItem = lastInFlowChildBox(), marginTrim.contains(.InlineEnd) {
      if isRowsFlexbox {
        marginTrimItems.itemsAtFlexLineEnd.add(value: flexItem)
      } else {
        marginTrimItems.itemsOnLastFlexLine.add(value: flexItem)
      }
    }
  }

  // Margins parallel with the main axis
  private func shouldTrimCrossAxisMarginStart() -> Bool {
    if isHorizontalFlow() {
      return style().marginTrim().contains(.BlockStart)
    }
    return style().marginTrim().contains(.InlineStart)
  }

  private func shouldTrimCrossAxisMarginEnd() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func trimCrossAxisMarginStart(flexLayoutItem: FlexLayoutItem) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func trimCrossAxisMarginEnd(flexLayoutItem: FlexLayoutItem) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func hasAutoMarginsInCrossAxis(flexItem: RenderBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func repositionLogicalHeightDependentFlexItems(
    lineStates: inout FlexLineStates, gapBetweenLines: LayoutUnit
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func prepareOrderIteratorAndMargins() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func constructFlexLayoutItem(flexItem: RenderBoxWrapper, relayoutChildren: Bool)
    -> FlexLayoutItem
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func freezeInflexibleItems(
    flexSign: FlexSign, flexLayoutItems: inout FlexLayoutItems,
    remainingFreeSpace: inout LayoutUnit, totalFlexGrow: inout Float64,
    totalFlexShrink: inout Float64, totalWeightedFlexShrink: inout Float64
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns true if we successfully ran the algorithm and sized the flex items.
  private func resolveFlexibleLengths(
    flexSign: FlexSign, flexLayoutItems: inout FlexLayoutItems, initialFreeSpace: LayoutUnit,
    remainingFreeSpace: inout LayoutUnit, totalFlexGrow: inout Float64,
    totalFlexShrink: inout Float64, totalWeightedFlexShrink: inout Float64
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func prepareFlexItemForPositionedLayout(flexItem: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func layoutAndPlaceFlexItems(
    crossAxisOffset: inout LayoutUnit, flexLayoutItems: inout FlexLayoutItems,
    availableFreeSpace: LayoutUnit, relayoutChildren: Bool, lineStates: inout FlexLineStates,
    gapBetweenItems: LayoutUnit
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func appendFlexItemFrameRects() -> FlexItemFrameRects {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func repaintFlexItemsDuringLayoutIfMoved(oldFlexItemRects: FlexItemFrameRects) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func resetHasDefiniteHeight() { hasDefiniteHeight = .Unknown }

  private func layoutUsingFlexFormattingContext() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // This set is used to keep track of which children we laid out in this
  // current layout iteration. We need it because the ones in this set may
  // need an additional layout pass for correct stretch alignment handling, as
  // the first layout likely did not use the correct value for percentage
  // sizing of children.
  let relaidOutFlexItems = WeakHashSet<RenderBoxWrapper>()

  let orderIterator: OrderIterator? = nil
  var numberOfFlexItemsOnFirstLine: UInt64 = 0
  var numberOfFlexItemsOnLastLine: UInt64 = 0

  private struct MarginTrimItems {
    let itemsAtFlexLineStart = WeakHashSet<RenderBoxWrapper>()
    let itemsAtFlexLineEnd = WeakHashSet<RenderBoxWrapper>()
    let itemsOnFirstFlexLine = WeakHashSet<RenderBoxWrapper>()
    let itemsOnLastFlexLine = WeakHashSet<RenderBoxWrapper>()
  }

  private let marginTrimItems = MarginTrimItems()

  var justifyContentStartOverflow = LayoutUnit(value: 0)

  // This is SizeIsUnknown outside of layoutBlock()
  private var hasDefiniteHeight: SizeDefiniteness = .Unknown
  var inLayout = false
}
