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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldApplyMinBlockSizeAutoForFlexItem(flexItem: RenderBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func isColumnFlow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func flexBasisForFlexItem(flexItem: RenderBoxWrapper) -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func mainAxisContentExtent(contentLogicalHeight: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func transformedBlockFlowDirection() -> FlowDirection {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func flowAwareBorderBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  override func computeChildIntrinsicLogicalWidths(child: RenderObjectWrapper) -> (
    LayoutUnit, LayoutUnit
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func alignmentForFlexItem(flexItem: RenderBoxWrapper) -> ItemPosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Margins parallel with the main axis
  private func shouldTrimCrossAxisMarginStart() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  var justifyContentStartOverflow = LayoutUnit(value: 0)

  // This is SizeIsUnknown outside of layoutBlock()
  private var hasDefiniteHeight: SizeDefiniteness = .Unknown
  var inLayout = false
}
