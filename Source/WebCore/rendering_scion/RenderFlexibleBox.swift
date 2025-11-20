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

  private enum SizeDefiniteness {
    case Definite
    case Indefinite
    case Unknown
  }

  // TODO(asuhan): Use an inline capacity of 8, since flexbox containers usually have less than 8 children.
  private typealias FlexItemFrameRects = [LayoutRectWrapper]

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

  override func computeChildIntrinsicLogicalWidths(child: RenderObjectWrapper) -> (
    LayoutUnit, LayoutUnit
  ) {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func initializeMarginTrimState() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func prepareOrderIteratorAndMargins() {
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

  // This set is used to keep track of which children we laid out in this
  // current layout iteration. We need it because the ones in this set may
  // need an additional layout pass for correct stretch alignment handling, as
  // the first layout likely did not use the correct value for percentage
  // sizing of children.
  let relaidOutFlexItems = WeakHashSet<RenderBoxWrapper>()

  var numberOfFlexItemsOnFirstLine: UInt64 = 0
  var numberOfFlexItemsOnLastLine: UInt64 = 0

  var justifyContentStartOverflow = LayoutUnit(value: 0)

  // This is SizeIsUnknown outside of layoutBlock()
  private var hasDefiniteHeight: SizeDefiniteness = .Unknown
  var inLayout = false
}
