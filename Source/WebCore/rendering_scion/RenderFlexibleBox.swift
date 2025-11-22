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

// FIXME: consider adding this check to RenderBox::hasIntrinsicAspectRatio(). We could even make it
// virtual returning false by default. RenderReplaced will overwrite it with the current implementation
// plus this extra check. See wkb.ug/231955.
private func isSVGRootWithIntrinsicAspectRatio(flexItem: RenderBoxWrapper) -> Bool {
  if !flexItem.isRenderOrLegacyRenderSVGRoot() {
    return false
  }
  // It's common for some replaced elements, such as SVGs, to have intrinsic aspect ratios but no intrinsic sizes.
  // That's why it isn't enough just to check for intrinsic sizes in those cases.
  return (flexItem as! RenderReplacedWrapper).computeIntrinsicAspectRatio() > 0
}

private func flexItemHasAspectRatio(flexItem: RenderBoxWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

// This is a RAII class that is used to temporarily set the flex basis as the child size in the main axis.
struct ScopedFlexBasisAsFlexItemMainSize: ~Copyable {
  init(flexItem: RenderBoxWrapper, flexBasis: LengthWrapper, mainAxisIsInlineAxis: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  deinit {
    if mainAxisIsInlineAxis {
      flexItem.clearOverridingLogicalWidthLength()
    } else {
      flexItem.clearOverridingLogicalHeightLength()
    }
  }

  private let flexItem: RenderBoxWrapper
  private let mainAxisIsInlineAxis: Bool
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

  private func cachedFlexItemIntrinsicContentLogicalHeight(flexItem: RenderBoxWrapper) -> LayoutUnit
  {
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

    let crossAxisOffset: LayoutUnit
    var crossAxisExtent: LayoutUnit
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

  private func crossAxisContentExtent() -> LayoutUnit {
    return isHorizontalFlow() ? contentHeight() : contentWidth()
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

  private func computeMainAxisExtentForFlexItem(
    flexItem: RenderBoxWrapper, sizeType: RenderBoxWrapper.SizeType, size: LengthWrapper
  ) -> LayoutUnit? {
    // If we have a horizontal flow, that means the main size is the width.
    // That's the logical width for horizontal writing modes, and the logical
    // height in vertical writing modes. For a vertical flow, main size is the
    // height, so it's the inverse. So we need the logical width if we have a
    // horizontal flow and horizontal writing mode, or vertical flow and vertical
    // writing mode. Otherwise we need the logical height.
    if !mainAxisIsFlexItemInlineAxis(flexItem: flexItem) {
      // We don't have to check for "auto" here - computeContentLogicalHeight
      // will just return a null Optional for that case anyway. It's safe to access
      // scrollbarLogicalHeight here because ComputeNextFlexLine will have
      // already forced layout on the child. We previously did a layout out the child
      // if necessary (see ComputeNextFlexLine and the call to
      // flexItemHasIntrinsicMainAxisSize) so we can be sure that the two height
      // calls here will return up-to-date data.
      let height = flexItem.computeContentLogicalHeight(
        heightType: sizeType, height: size,
        intrinsicContentHeight: cachedFlexItemIntrinsicContentLogicalHeight(flexItem: flexItem))
      if height == nil {
        return nil
      }
      // Tables interpret overriding sizes as the size of captions + rows. However the specified height of a table
      // only includes the size of the rows. That's why we need to add the size of the captions here so that the table
      // layout algorithm behaves appropiately.
      var captionsHeight = LayoutUnit()
      if let table = flexItem as? RenderTableWrapper,
        flexItemMainSizeIsDefinite(flexItem: flexItem, flexBasis: size)
      {
        captionsHeight = table.sumCaptionsLogicalHeight()
      }
      return height! + flexItem.scrollbarLogicalHeight() + captionsHeight
    }

    // computeLogicalWidth always re-computes the intrinsic widths. However, when
    // our logical width is auto, we can just use our cached value. So let's do
    // that here. (Compare code in RenderBlock::computePreferredLogicalWidths)
    if flexItem.style().logicalWidth().isAuto() && !flexItemHasAspectRatio(flexItem: flexItem) {
      if size.isMinContent() {
        if flexItem.needsPreferredWidthsRecalculation() {
          flexItem.setPreferredLogicalWidthsDirty(shouldBeDirty: true, markParents: .MarkOnlyThis)
        }
        return flexItem.minPreferredLogicalWidth() - flexItem.borderAndPaddingLogicalWidth()
      }
      if size.isMaxContent() {
        if flexItem.needsPreferredWidthsRecalculation() {
          flexItem.setPreferredLogicalWidthsDirty(shouldBeDirty: true, markParents: .MarkOnlyThis)
        }
        return flexItem.maxPreferredLogicalWidth() - flexItem.borderAndPaddingLogicalWidth()
      }
    }

    let mainAxisWidth =
      isColumnFlow()
      ? availableLogicalHeight(heightType: .ExcludeMarginBorderPadding) : contentLogicalWidth()
    return flexItem.computeLogicalWidthInFragmentUsing(
      widthType: sizeType, logicalWidth: size, availableLogicalWidth: mainAxisWidth, cb: self,
      fragment: nil)
      - flexItem.borderAndPaddingLogicalWidth()
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

  private func flexItemHasComputableAspectRatio(flexItem: RenderBoxWrapper) -> Bool {
    if !flexItemHasAspectRatio(flexItem: flexItem) {
      return false
    }
    return flexItem.intrinsicSize().height().bool() || flexItem.style().hasAspectRatio()
      || isSVGRootWithIntrinsicAspectRatio(flexItem: flexItem)
  }

  private func flexItemHasComputableAspectRatioAndCrossSizeIsConsideredDefinite(
    flexItem: RenderBoxWrapper
  ) -> Bool {
    return flexItemHasComputableAspectRatio(flexItem: flexItem)
      && (flexItemCrossSizeIsDefinite(
        flexItem: flexItem,
        length: crossSizeLengthForFlexItem(sizeType: .MainOrPreferredSize, flexItem: flexItem))
        || flexItemCrossSizeShouldUseContainerCrossSize(flexItem: flexItem))
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

  // FIXME: computeMainSizeFromAspectRatioUsing may need to return an std::optional<LayoutUnit> in the future
  // rather than returning indefinite sizes as 0/-1.
  private func computeMainSizeFromAspectRatioUsing(
    flexItem: RenderBoxWrapper, crossSizeLength: LengthWrapper
  ) -> LayoutUnit {
    assert(flexItemHasAspectRatio(flexItem: flexItem))

    var crossSize = LayoutUnit()
    // crossSize is border-box size if box-sizing is border-box, and content-box otherwise.
    if crossSizeLength.isFixed() {
      crossSize = LayoutUnit(value: crossSizeLength.value())
    } else if crossSizeLength.isAuto() {
      assert(flexItemCrossSizeShouldUseContainerCrossSize(flexItem: flexItem))
      crossSize = computeCrossSizeForFlexItemUsingContainerCrossSize(flexItem: flexItem)
    } else {
      assert(crossSizeLength.isPercentOrCalculated())
      if let flexItemSize = mainAxisIsFlexItemInlineAxis(flexItem: flexItem)
        ? flexItem.computePercentageLogicalHeight(height: crossSizeLength)
        : adjustBorderBoxLogicalWidthForBoxSizing(
          computedLogicalWidth: valueForLength(
            length: crossSizeLength, maximumValue: contentWidth()),
          originalType: crossSizeLength.type())
      {
        crossSize = flexItemSize
      } else {
        return LayoutUnit(value: UInt64(0))
      }
    }

    var ratio: Float64 = 0
    var borderAndPadding = LayoutUnit()
    if flexItem.isRenderOrLegacyRenderSVGRoot() {
      ratio = (flexItem as! RenderReplacedWrapper).computeIntrinsicAspectRatio()
    } else {
      let flexItemIntrinsicSize = flexItem.intrinsicSize()
      if flexItem.style().aspectRatioType() == .Ratio
        || (flexItem.style().aspectRatioType() == .AutoAndRatio && flexItemIntrinsicSize.isEmpty())
      {
        ratio = flexItem.style().aspectRatioWidth() / flexItem.style().aspectRatioHeight()
        if flexItem.style().boxSizingForAspectRatio() == .ContentBox {
          crossSize -=
            isHorizontalFlow()
            ? flexItem.verticalBorderAndPaddingExtent()
            : flexItem.horizontalBorderAndPaddingExtent()
        } else {
          borderAndPadding =
            isHorizontalFlow()
            ? flexItem.horizontalBorderAndPaddingExtent()
            : flexItem.verticalBorderAndPaddingExtent()
        }
      } else {
        if let replacedElement = flexItem as? RenderReplacedWrapper {
          ratio = replacedElement.computeIntrinsicAspectRatio()
        } else {
          assert(flexItemIntrinsicSize.height().bool())
          ratio = Float64(
            flexItemIntrinsicSize.width().toFloat() / flexItemIntrinsicSize.height().toFloat())
        }
        crossSize = adjustForBoxSizing(box: flexItem, value: crossSize)
      }
    }
    let zero = LayoutUnit(value: UInt64(0))
    if isHorizontalFlow() {
      return max(zero, LayoutUnit(value: crossSize * ratio) - borderAndPadding)
    }
    return max(zero, LayoutUnit(value: crossSize / ratio) - borderAndPadding)
  }

  private func adjustForBoxSizing(box: RenderBoxWrapper, value: LayoutUnit) -> LayoutUnit {
    // We need to substract the border and padding extent from the cross axis.
    // Furthermore, the sizing calculations that floor the content box size at zero when applying box-sizing are also ignored.
    // https://drafts.csswg.org/css-flexbox/#algo-main-item.
    var value = value
    if box.style().boxSizing() == .BorderBox {
      value -=
        isHorizontalFlow()
        ? box.verticalBorderAndPaddingExtent() : box.horizontalBorderAndPaddingExtent()
    }
    return value
  }

  // https://drafts.csswg.org/css-flexbox/#algo-main-item
  func computeFlexBaseSizeForFlexItem(
    flexItem: RenderBoxWrapper, mainAxisBorderAndPadding: LayoutUnit, relayoutChildren: Bool
  ) -> LayoutUnit {
    let flexBasis = flexBasisForFlexItem(flexItem: flexItem)
    let _ = ScopedFlexBasisAsFlexItemMainSize(
      flexItem: flexItem,
      flexBasis: flexBasis.isContent() ? LengthWrapper(type: .MaxContent) : flexBasis,
      mainAxisIsInlineAxis: mainAxisIsFlexItemInlineAxis(flexItem: flexItem))
    // FIXME: While we are supposed to ignore min/max here, clients of maybeCacheFlexItemMainIntrinsicSize may expect min/max constrained size.
    let _ = SetForScope(scopedVariable: &isComputingFlexBaseSizes, newValue: true)

    maybeCacheFlexItemMainIntrinsicSize(flexItem: flexItem, relayoutChildren: relayoutChildren)

    // 9.2.3 A.
    if flexItemMainSizeIsDefinite(flexItem: flexItem, flexBasis: flexBasis) {
      return max(
        LayoutUnit(value: UInt64(0)),
        computeMainAxisExtentForFlexItem(
          flexItem: flexItem, sizeType: .MainOrPreferredSize, size: flexBasis)!)
    }

    // 9.2.3 B.
    if flexItemHasComputableAspectRatioAndCrossSizeIsConsideredDefinite(flexItem: flexItem) {
      let crossSizeLength = crossSizeLengthForFlexItem(
        sizeType: .MainOrPreferredSize, flexItem: flexItem)
      return adjustFlexItemSizeForAspectRatioCrossAxisMinAndMax(
        flexItem: flexItem,
        flexItemSize: computeMainSizeFromAspectRatioUsing(
          flexItem: flexItem, crossSizeLength: crossSizeLength))
    }

    // FIXME: 9.2.3 C.
    // FIXME: 9.2.3 D.

    // 9.2.3 E.
    var mainAxisExtent = LayoutUnit()
    if !mainAxisIsFlexItemInlineAxis(flexItem: flexItem) {
      assert(!flexItem.needsLayout())
      let maybeMainAxisExtent = intrinsicSizeAlongMainAxis[CPtrToInt(flexItem.p)]
      assert(maybeMainAxisExtent != nil)
      mainAxisExtent = maybeMainAxisExtent!
    } else {
      // We don't need to add scrollbarLogicalWidth here because the preferred
      // width includes the scrollbar, even for overflow: auto.
      mainAxisExtent = flexItem.maxPreferredLogicalWidth()
    }
    return mainAxisExtent - mainAxisBorderAndPadding
  }

  private func maybeCacheFlexItemMainIntrinsicSize(
    flexItem: RenderBoxWrapper, relayoutChildren: Bool
  ) {
    if !flexItemHasIntrinsicMainAxisSize(flexItem: flexItem) {
      return
    }

    // If this condition is true, then computeMainAxisExtentForFlexItem will call
    // flexItem.intrinsicContentLogicalHeight() and flexItem.scrollbarLogicalHeight(),
    // so if the child has intrinsic min/max/preferred size, run layout on it now to make sure
    // its logical height and scroll bars are up to date.
    updateBlockChildDirtyBitsBeforeLayout(relayoutChildren: relayoutChildren, child: flexItem)
    // Don't resolve percentages in children. This is especially important for the min-height calculation,
    // where we want percentages to be treated as auto. For flex-basis itself, this is not a problem because
    // by definition we have an indefinite flex basis here and thus percentages should not resolve.
    if flexItem.needsLayout() || !intrinsicSizeAlongMainAxis.keys.contains(CPtrToInt(flexItem.p)) {
      if isHorizontalWritingMode() == flexItem.isHorizontalWritingMode() {
        flexItem.setOverridingContainingBlockContentLogicalHeight(logicalHeight: nil)
      } else {
        flexItem.setOverridingContainingBlockContentLogicalWidth(logicalWidth: nil)
      }
      flexItem.setChildNeedsLayout(markParents: .MarkOnlyThis)
      flexItem.layoutIfNeeded()
      cacheFlexItemMainSize(flexItem: flexItem)
      flexItem.clearOverridingContainingBlockContentSize()
    }
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

  private func flexItemCrossSizeIsDefinite(flexItem: RenderBoxWrapper, length: LengthWrapper)
    -> Bool
  {
    if length.isAuto() {
      return false
    }

    if length.isPercentOrCalculated() {
      if !mainAxisIsFlexItemInlineAxis(flexItem: flexItem) || hasDefiniteHeight == .Definite {
        return true
      }
      if hasDefiniteHeight == .Indefinite {
        return false
      }
      let definite = flexItem.computePercentageLogicalHeight(height: length) != nil
      hasDefiniteHeight = definite ? .Definite : .Indefinite
      return definite
    }
    // FIXME: Eventually we should support other types of sizes here.
    // Requires updating computeMainSizeFromAspectRatioUsing.
    return length.isFixed()
  }

  private func flexItemHasIntrinsicMainAxisSize(flexItem: RenderBoxWrapper) -> Bool {
    if mainAxisIsFlexItemInlineAxis(flexItem: flexItem) {
      return false
    }

    let flexBasis = flexBasisForFlexItem(flexItem: flexItem)
    let minSize = mainSizeLengthForFlexItem(sizeType: .MinSize, flexItem: flexItem)
    let maxSize = mainSizeLengthForFlexItem(sizeType: .MaxSize, flexItem: flexItem)
    // FIXME: we must run flexItemMainSizeIsDefinite() because it might end up calling computePercentageLogicalHeight()
    // which has some side effects like calling addPercentHeightDescendant() for example so it is not possible to skip
    // the call for example by moving it to the end of the conditional expression. This is error-prone and we should
    // refactor computePercentageLogicalHeight() at some point so that it only computes stuff without those side effects.
    if !flexItemMainSizeIsDefinite(flexItem: flexItem, flexBasis: flexBasis)
      || minSize.isIntrinsic()
      || maxSize.isIntrinsic()
    {
      return true
    }

    if shouldApplyMinSizeAutoForFlexItem(flexItem: flexItem) {
      return true
    }

    return false
  }

  private func mainAxisOverflowForFlexItem(flexItem: RenderBoxWrapper) -> Overflow {
    if isHorizontalFlow() {
      return flexItem.style().overflowX()
    }
    return flexItem.style().overflowY()
  }

  private func cacheFlexItemMainSize(flexItem: RenderBoxWrapper) {
    assert(!flexItem.needsLayout())
    var mainSize = LayoutUnit()
    if mainAxisIsFlexItemInlineAxis(flexItem: flexItem) {
      mainSize = flexItem.maxPreferredLogicalWidth()
    } else {
      let flexBasis = flexBasisForFlexItem(flexItem: flexItem)
      if flexBasis.isPercentOrCalculated()
        && !flexItemMainSizeIsDefinite(flexItem: flexItem, flexBasis: flexBasis)
      {
        let mainContentWithBordersAndPadding =
          cachedFlexItemIntrinsicContentLogicalHeight(flexItem: flexItem)
          + flexItem.borderAndPaddingLogicalHeight()
        mainSize = mainContentWithBordersAndPadding + flexItem.scrollbarLogicalHeight()
      } else {
        mainSize = flexItem.logicalHeight()
      }
    }

    intrinsicSizeAlongMainAxis.updateValue(mainSize, forKey: CPtrToInt(flexItem.p))
    relaidOutFlexItems.add(value: flexItem)
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
    if isHorizontalFlow() {
      return style().marginTrim().contains(.BlockEnd)
    }
    return style().marginTrim().contains(.InlineEnd)
  }

  private func trimCrossAxisMarginStart(flexLayoutItem: FlexLayoutItem) {
    if isHorizontalFlow() {
      setTrimmedMarginForChild(child: flexLayoutItem.renderer, marginTrimType: .BlockStart)
    } else {
      setTrimmedMarginForChild(child: flexLayoutItem.renderer, marginTrimType: .InlineStart)
    }
    marginTrimItems.itemsOnFirstFlexLine.add(value: flexLayoutItem.renderer)
  }

  private func trimCrossAxisMarginEnd(flexLayoutItem: FlexLayoutItem) {
    if isHorizontalFlow() {
      setTrimmedMarginForChild(child: flexLayoutItem.renderer, marginTrimType: .BlockEnd)
    } else {
      setTrimmedMarginForChild(child: flexLayoutItem.renderer, marginTrimType: .InlineEnd)
    }
    marginTrimItems.itemsOnLastFlexLine.add(value: flexLayoutItem.renderer)
  }

  private func hasAutoMarginsInCrossAxis(flexItem: RenderBoxWrapper) -> Bool {
    if isHorizontalFlow() {
      return flexItem.style().marginTop().isAuto() || flexItem.style().marginBottom().isAuto()
    }
    return flexItem.style().marginLeft().isAuto() || flexItem.style().marginRight().isAuto()
  }

  private func repositionLogicalHeightDependentFlexItems(
    lineStates: inout FlexLineStates, gapBetweenLines: LayoutUnit
  ) {
    let crossAxisStartEdge =
      lineStates.isEmpty ? LayoutUnit(value: UInt64(0)) : lineStates[0].crossAxisOffset
    // If we have a single line flexbox, the line height is all the available space. For flex-direction: row,
    // this means we need to use the height, so we do this after calling updateLogicalHeight.
    if !isMultiline() && !lineStates.isEmpty {
      lineStates[0].crossAxisExtent = crossAxisContentExtent()
    }

    alignFlexLines(lineStates: &lineStates, gapBetweenLines: gapBetweenLines)

    alignFlexItems(lineStates: &lineStates)

    if style().flexWrap() == .Reverse {
      flipForWrapReverse(lineStates: lineStates, crossAxisStartEdge: crossAxisStartEdge)
    }

    // direction:rtl + flex-direction:column means the cross-axis direction is
    // flipped.
    flipForRightToLeftColumn(lineStates: lineStates)
  }

  private func computeFlexItemMarginValue(margin: LengthWrapper) -> LayoutUnit {
    // When resolving the margins, we use the content size for resolving percent and calc (for percents in calc expressions) margins.
    // Fortunately, percent margins are always computed with respect to the block's width, even for margin-top and margin-bottom.
    let availableSize = contentLogicalWidth()
    return minimumValueForLength(length: margin, maximumValue: availableSize)
  }

  private func prepareOrderIteratorAndMargins() {
    let populator = OrderIteratorPopulator(iterator: orderIterator!)

    var flexItem = firstChildBox()
    while flexItem != nil {
      if !populator.collectChild(child: flexItem!) {
        flexItem = flexItem!.nextSiblingBox()
        continue
      }

      // Before running the flex algorithm, 'auto' has a margin of 0.
      // Also, if we're not auto sizing, we don't do a layout that computes the start/end margins.
      if isHorizontalFlow() {
        flexItem!.setMarginLeft(
          margin: computeFlexItemMarginValue(margin: flexItem!.style().marginLeft()))
        flexItem!.setMarginRight(
          margin: computeFlexItemMarginValue(margin: flexItem!.style().marginRight()))
      } else {
        flexItem!.setMarginTop(
          margin: computeFlexItemMarginValue(margin: flexItem!.style().marginTop()))
        flexItem!.setMarginBottom(
          margin: computeFlexItemMarginValue(margin: flexItem!.style().marginBottom()))
      }

      flexItem = flexItem!.nextSiblingBox()
    }
  }

  private func computeFlexItemMinMaxSizes(flexItem: RenderBoxWrapper) -> (LayoutUnit, LayoutUnit) {
    let maxLength = mainSizeLengthForFlexItem(sizeType: .MaxSize, flexItem: flexItem)
    var maxExtent: LayoutUnit? = nil
    if maxLength.isSpecifiedOrIntrinsic() {
      maxExtent = computeMainAxisExtentForFlexItem(
        flexItem: flexItem, sizeType: .MaxSize, size: maxLength)
    }

    let minLength = mainSizeLengthForFlexItem(sizeType: .MinSize, flexItem: flexItem)
    // Intrinsic sizes in child's block axis are handled by the min-size:auto code path.
    if minLength.isSpecified()
      || (minLength.isIntrinsic() && mainAxisIsFlexItemInlineAxis(flexItem: flexItem))
    {
      var minExtent =
        computeMainAxisExtentForFlexItem(flexItem: flexItem, sizeType: .MinSize, size: minLength)
        ?? LayoutUnit(value: UInt64(0))
      // We must never return a min size smaller than the min preferred size for tables.
      if flexItem.isRenderTable() && mainAxisIsFlexItemInlineAxis(flexItem: flexItem) {
        minExtent = max(minExtent, flexItem.minPreferredLogicalWidth())
      }
      return (minExtent, maxExtent ?? LayoutUnit.max())
    }

    if shouldApplyMinSizeAutoForFlexItem(flexItem: flexItem) {
      // FIXME: If the min value is expected to be valid here, we need to come up with a non optional version of computeMainAxisExtentForFlexItem and
      // ensure it's valid through the virtual calls of computeIntrinsicLogicalContentHeightUsing.
      var contentSize = LayoutUnit()
      let flexItemCrossSizeLength = crossSizeLengthForFlexItem(
        sizeType: .MainOrPreferredSize, flexItem: flexItem)

      let canComputeSizeThroughAspectRatio =
        flexItem.isRenderReplaced() && flexItemHasComputableAspectRatio(flexItem: flexItem)
        && flexItemCrossSizeIsDefinite(flexItem: flexItem, length: flexItemCrossSizeLength)

      if canComputeSizeThroughAspectRatio {
        contentSize = computeMainSizeFromAspectRatioUsing(
          flexItem: flexItem, crossSizeLength: flexItemCrossSizeLength)
      } else {
        contentSize =
          computeMainAxisExtentForFlexItem(
            flexItem: flexItem, sizeType: .MinSize, size: LengthWrapper(type: .MinContent))
          ?? LayoutUnit(value: UInt64(0))
      }

      if flexItemHasAspectRatio(flexItem: flexItem)
        && (!crossSizeLengthForFlexItem(sizeType: .MinSize, flexItem: flexItem).isAuto()
          || !crossSizeLengthForFlexItem(sizeType: .MaxSize, flexItem: flexItem).isAuto())
      {
        contentSize = adjustFlexItemSizeForAspectRatioCrossAxisMinAndMax(
          flexItem: flexItem, flexItemSize: contentSize)
      }
      assert(contentSize >= Int32(0))
      contentSize = min(contentSize, maxExtent ?? contentSize)

      let mainSize = mainSizeLengthForFlexItem(sizeType: .MainOrPreferredSize, flexItem: flexItem)
      if flexItemMainSizeIsDefinite(flexItem: flexItem, flexBasis: mainSize) {
        let resolvedMainSize =
          computeMainAxisExtentForFlexItem(
            flexItem: flexItem, sizeType: .MainOrPreferredSize, size: mainSize)
          ?? LayoutUnit(value: 0)
        assert(resolvedMainSize >= Int32(0))
        let specifiedSize = min(resolvedMainSize, maxExtent ?? resolvedMainSize)
        return (min(specifiedSize, contentSize), maxExtent ?? LayoutUnit.max())
      }

      if flexItem.isRenderReplaced()
        && flexItemHasComputableAspectRatioAndCrossSizeIsConsideredDefinite(flexItem: flexItem)
      {
        var transferredSize = computeMainSizeFromAspectRatioUsing(
          flexItem: flexItem, crossSizeLength: flexItemCrossSizeLength)
        transferredSize = adjustFlexItemSizeForAspectRatioCrossAxisMinAndMax(
          flexItem: flexItem, flexItemSize: transferredSize)
        return (min(transferredSize, contentSize), maxExtent ?? LayoutUnit.max())
      }

      return (contentSize, maxExtent ?? LayoutUnit.max())
    }

    return (LayoutUnit(value: UInt64(0)), maxExtent ?? LayoutUnit.max())
  }

  private func adjustFlexItemSizeForAspectRatioCrossAxisMinAndMax(
    flexItem: RenderBoxWrapper, flexItemSize: LayoutUnit
  ) -> LayoutUnit {
    let crossMin = crossSizeLengthForFlexItem(sizeType: .MinSize, flexItem: flexItem)
    let crossMax = crossSizeLengthForFlexItem(sizeType: .MaxSize, flexItem: flexItem)
    var flexItemSize = flexItemSize

    if flexItemCrossSizeIsDefinite(flexItem: flexItem, length: crossMax) {
      let maxValue = computeMainSizeFromAspectRatioUsing(
        flexItem: flexItem, crossSizeLength: crossMax)
      flexItemSize = min(maxValue, flexItemSize)
    }

    if flexItemCrossSizeIsDefinite(flexItem: flexItem, length: crossMin) {
      let minValue = computeMainSizeFromAspectRatioUsing(
        flexItem: flexItem, crossSizeLength: crossMin)
      flexItemSize = max(minValue, flexItemSize)
    }

    return flexItemSize
  }

  private func constructFlexLayoutItem(flexItem: RenderBoxWrapper, relayoutChildren: Bool)
    -> FlexLayoutItem
  {
    let everHadLayout = flexItem.everHadLayout()
    flexItem.clearOverridingContentSize()
    if let flexibleBox = flexItem as? RenderFlexibleBoxWrapper {
      flexibleBox.resetHasDefiniteHeight()
    }

    if everHadLayout && flexItem.hasTrimmedMargin(marginTrimType: nil) {
      flexItem.clearTrimmedMarginsMarkings()
    }

    if flexItem.needsPreferredWidthsRecalculation() {
      flexItem.setPreferredLogicalWidthsDirty(shouldBeDirty: true, markParents: .MarkOnlyThis)
    }

    let borderAndPadding =
      isHorizontalFlow()
      ? flexItem.horizontalBorderAndPaddingExtent() : flexItem.verticalBorderAndPaddingExtent()
    let innerFlexBaseSize = computeFlexBaseSizeForFlexItem(
      flexItem: flexItem, mainAxisBorderAndPadding: borderAndPadding,
      relayoutChildren: relayoutChildren)
    let margin =
      isHorizontalFlow() ? flexItem.horizontalMarginExtent() : flexItem.verticalMarginExtent()
    return FlexLayoutItem(
      flexItem: flexItem, flexBaseContentSize: innerFlexBaseSize,
      mainAxisBorderAndPadding: borderAndPadding, mainAxisMargin: margin,
      minMaxSizes: computeFlexItemMinMaxSizes(flexItem: flexItem),
      everHadLayout: everHadLayout)
  }

  private func freezeInflexibleItems(
    flexSign: FlexSign, flexLayoutItems: inout FlexLayoutItems,
    remainingFreeSpace: inout LayoutUnit, totalFlexGrow: inout Float64,
    totalFlexShrink: inout Float64, totalWeightedFlexShrink: inout Float64
  ) {
    // Per https://drafts.csswg.org/css-flexbox/#resolve-flexible-lengths step 2,
    // we freeze all items with a flex factor of 0 as well as those with a min/max
    // size violation.
    var newInflexibleItems: [FlexLayoutItem] = []
    for (i, flexLayoutItem) in flexLayoutItems.enumerated() {
      assert(!flexLayoutItem.renderer.isOutOfFlowPositioned())
      assert(!flexLayoutItem.frozen)
      let flexFactor =
        (flexSign == .PositiveFlexibility)
        ? flexLayoutItem.style().flexGrow() : flexLayoutItem.style().flexShrink()
      if flexFactor == 0
        || (flexSign == .PositiveFlexibility
          && flexLayoutItem.flexBaseContentSize > flexLayoutItem.hypotheticalMainContentSize)
        || (flexSign == .NegativeFlexibility
          && flexLayoutItem.flexBaseContentSize < flexLayoutItem.hypotheticalMainContentSize)
      {
        flexLayoutItems[i].flexedContentSize = flexLayoutItem.hypotheticalMainContentSize
        newInflexibleItems.append(flexLayoutItems[i])
      }
    }
    freezeViolations(
      violations: &newInflexibleItems, availableFreeSpace: &remainingFreeSpace,
      totalFlexGrow: &totalFlexGrow, totalFlexShrink: &totalFlexShrink,
      totalWeightedFlexShrink: &totalWeightedFlexShrink)
  }

  // Returns true if we successfully ran the algorithm and sized the flex items.
  private func resolveFlexibleLengths(
    flexSign: FlexSign, flexLayoutItems: inout FlexLayoutItems, initialFreeSpace: LayoutUnit,
    remainingFreeSpace: inout LayoutUnit, totalFlexGrow: inout Float64,
    totalFlexShrink: inout Float64, totalWeightedFlexShrink: inout Float64
  ) -> Bool {
    var totalViolation = LayoutUnit()
    var usedFreeSpace = LayoutUnit()
    var minViolations: [FlexLayoutItem] = []
    var maxViolations: [FlexLayoutItem] = []

    let sumFlexFactors = (flexSign == .PositiveFlexibility) ? totalFlexGrow : totalFlexShrink
    if sumFlexFactors > 0 && sumFlexFactors < 1 {
      let fractional = LayoutUnit(value: initialFreeSpace * sumFlexFactors)
      if fractional.abs() < remainingFreeSpace.abs() {
        remainingFreeSpace = fractional
      }
    }

    for (i, flexLayoutItem) in flexLayoutItems.enumerated() {
      // This check also covers out-of-flow children.
      if flexLayoutItem.frozen {
        continue
      }

      let flexItemStyle = flexLayoutItem.style()
      var flexItemSize = flexLayoutItem.flexBaseContentSize
      var extraSpace: Float64 = 0
      if remainingFreeSpace > 0 && totalFlexGrow > 0 && flexSign == .PositiveFlexibility
        && totalFlexGrow.isFinite
      {
        extraSpace = Float64(remainingFreeSpace * flexItemStyle.flexGrow()) / totalFlexGrow
      } else if remainingFreeSpace < Int32(0) && totalWeightedFlexShrink > 0
        && flexSign == .NegativeFlexibility && totalWeightedFlexShrink.isFinite
        && flexItemStyle.flexShrink() != 0
      {
        extraSpace =
          Float64(
            remainingFreeSpace * flexItemStyle.flexShrink() * flexLayoutItem.flexBaseContentSize)
          / totalWeightedFlexShrink
      }
      if extraSpace.isFinite {
        flexItemSize += LayoutUnit.fromFloatRound(value: Float32(extraSpace))
      }

      let adjustedFlexItemSize = flexLayoutItem.constrainSizeByMinMax(size: flexItemSize)
      assert(adjustedFlexItemSize >= Int32(0))
      flexLayoutItems[i].flexedContentSize = adjustedFlexItemSize
      usedFreeSpace += adjustedFlexItemSize - flexLayoutItems[i].flexBaseContentSize

      let violation = adjustedFlexItemSize - flexItemSize
      if violation > 0 {
        minViolations.append(flexLayoutItems[i])
      } else if violation < Int32(0) {
        maxViolations.append(flexLayoutItems[i])
      }
      totalViolation += violation
    }

    if totalViolation.bool() {
      if totalViolation < Int32(0) {
        freezeViolations(
          violations: &maxViolations,
          availableFreeSpace: &remainingFreeSpace, totalFlexGrow: &totalFlexGrow,
          totalFlexShrink: &totalFlexShrink, totalWeightedFlexShrink: &totalWeightedFlexShrink)
      } else {
        freezeViolations(
          violations: &minViolations,
          availableFreeSpace: &remainingFreeSpace, totalFlexGrow: &totalFlexGrow,
          totalFlexShrink: &totalFlexShrink, totalWeightedFlexShrink: &totalWeightedFlexShrink)
      }
    } else {
      remainingFreeSpace -= usedFreeSpace
    }

    return !totalViolation.bool()
  }

  private func freezeViolations(
    violations: inout [FlexLayoutItem], availableFreeSpace: inout LayoutUnit,
    totalFlexGrow: inout Float64, totalFlexShrink: inout Float64,
    totalWeightedFlexShrink: inout Float64
  ) {
    for (i, violation) in violations.enumerated() {
      assert(!violation.frozen)
      let flexItemStyle = violation.style()
      let flexItemSize = violation.flexedContentSize
      availableFreeSpace -= flexItemSize - violation.flexBaseContentSize
      totalFlexGrow -= Float64(flexItemStyle.flexGrow())
      totalFlexShrink -= Float64(flexItemStyle.flexShrink())
      totalWeightedFlexShrink -= Float64(flexItemStyle.flexShrink() * violation.flexBaseContentSize)
      // totalWeightedFlexShrink can be negative when we exceed the precision of
      // a double when we initially calcuate totalWeightedFlexShrink. We then
      // subtract each child's weighted flex shrink with full precision, now
      // leading to a negative result. See
      // css3/flexbox/large-flex-shrink-assert.html
      totalWeightedFlexShrink = max(totalWeightedFlexShrink, 0)
      violations[i].frozen = true
    }
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

  private func alignFlexLines(lineStates: inout FlexLineStates, gapBetweenLines: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func alignFlexItems(lineStates: inout FlexLineStates) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func flipForRightToLeftColumn(lineStates: FlexLineStates) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func flipForWrapReverse(lineStates: FlexLineStates, crossAxisStartEdge: LayoutUnit) {
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

  // This is used to cache the preferred size for orthogonal flow children so we
  // don't have to relayout to get it
  private var intrinsicSizeAlongMainAxis: [UInt: LayoutUnit] = [:]

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
  var isComputingFlexBaseSizes = false
}
