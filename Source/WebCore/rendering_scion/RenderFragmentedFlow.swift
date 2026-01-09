/*
 * Copyright (C) 2011 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

typealias RenderFragmentContainerList = ListSet<RenderFragmentContainerWrapper, UInt>
typealias FragmentIntervalTree = IntervalTree<LayoutUnit, RenderFragmentContainerWrapper>

private func clamp(fragment: RenderFragmentContainerWrapper?, clampBox: RenderBoxWrapper?)
  -> RenderFragmentContainerWrapper?
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

class RenderFragmentedFlowWrapper: RenderBlockFlowWrapper {
  override func deleteLines() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func updateLogicalWidth() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    var computedValues = LogicalExtentComputedValues(
      extent: LayoutUnit(value: 0), position: logicalTop)

    let maxFlowSize = RenderFragmentedFlowWrapper.maxLogicalHeight()
    for fragment in fragmentList {
      assert(!fragment.needsLayout() || fragment.isRenderFragmentContainerSet())

      let distanceToMaxSize = maxFlowSize - computedValues.extent
      computedValues.extent += min(
        distanceToMaxSize, fragment.logicalHeightOfAllFragmentedFlowContent())

      // If we reached the maximum size there's no point in going further.
      if computedValues.extent == maxFlowSize {
        return computedValues
      }
    }
    return computedValues
  }

  func hasFragments() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fragmentChangedWritingMode(_ fragment: RenderFragmentContainerWrapper?) {}

  func invalidateFragments(markingParents: MarkingBehavior = .MarkContainingBlockChain) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasValidFragmentInfo() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Called when a descendant box's layout is finished and it has been positioned within its container.
  func fragmentedFlowDescendantBoxLaidOut(descendant: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func repaintRectangleInFragments(_ repaintRect: LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pageLogicalHeightForOffsetFromFragmentedFlow(offset: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pageRemainingLogicalHeightForOffsetFromFragmentedFlow(
    offset: LayoutUnit, pageBoundaryRule: PageBoundaryRule = .IncludePageBoundary
  ) -> LayoutUnit {
    let fragment = fragmentAtBlockOffset(clampBox: nil, offset: offset, extendLastFragment: false)
    if fragment == nil {
      return LayoutUnit(value: 0)
    }

    let pageLogicalTop = fragment!.pageLogicalTopForOffset(offset: offset)
    let pageLogicalHeight = fragment!.pageLogicalHeight()
    let pageLogicalBottom = pageLogicalTop + pageLogicalHeight
    var remainingHeight = pageLogicalBottom - offset
    if pageBoundaryRule == .IncludePageBoundary {
      // If IncludePageBoundary is set, the line exactly on the top edge of a
      // fragment will act as being part of the previous fragment.
      remainingHeight = LayoutUnit.intMod(a: remainingHeight, b: pageLogicalHeight)
    } else if !remainingHeight.bool() {
      // When pageBoundaryRule is IncludePageBoundary, we shouldn't just return 0 if there's no
      // space left, because in that case we're at a column boundary, in which case we should
      // return the amount of space remaining in the *next* column. Note that the page height
      // itself may be 0, though.
      remainingHeight = pageLogicalHeight
    }
    return remainingHeight
  }

  func updateSpaceShortageForSizeContainment(
    block: RenderBlockWrapper, offset: LayoutUnit, shortage: LayoutUnit
  ) {}

  func fragmentAtBlockOffset(
    clampBox: RenderBoxWrapper?, offset: LayoutUnit, extendLastFragment: Bool = false
  ) -> RenderFragmentContainerWrapper? {
    assert(!fragmentsInvalidated)

    if fragmentList.isEmptyIgnoringNullReferences() {
      return nil
    }

    if fragmentList.computeSize() == 1 && extendLastFragment {
      return fragmentList.first()
    }

    if offset <= Int32(0) {
      return clamp(fragment: fragmentList.first(), clampBox: clampBox)
    }

    let adapter = FragmentSearchAdapter(offset: offset)
    fragmentIntervalTree.allOverlapsWithAdapter(adapter: adapter)
    if let fragment = adapter.result() {
      return clamp(fragment: fragment, clampBox: clampBox)
    }

    // If no fragment was found, the offset is in the flow thread overflow.
    // The last fragment will contain the offset if extendLastFragment is set or if the last fragment is a set.
    if extendLastFragment || fragmentList.last().isRenderFragmentContainerSet() {
      return clamp(fragment: fragmentList.last(), clampBox: clampBox)
    }

    return nil
  }

  func fragmentsHaveUniformLogicalHeight() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalWidthChangedInFragmentsForBlock(
    block: RenderBlockWrapper, relayoutChildren: inout Bool
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func contentLogicalWidthOfFirstFragment() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func contentLogicalHeightOfFirstFragment() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFragmentRangeForBox(
    box: RenderBoxWrapper, startFragment: RenderFragmentContainerWrapper?,
    endFragment: RenderFragmentContainerWrapper?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func getFragmentRangeForBox(box: RenderBoxWrapper) -> (
    RenderFragmentContainerWrapper, RenderFragmentContainerWrapper
  )? {
    if !hasValidFragmentInfo() {  // We clear the ranges when we invalidate the fragments.
      return nil
    }

    if fragmentList.computeSize() == 1 {
      return (fragmentList.first(), fragmentList.first())
    }

    if let cached = getFragmentRangeForBoxFromCachedInfo(box: box) {
      return cached
    }

    return nil
  }

  func hasCachedFragmentRangeForBox(box: RenderBoxWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addForcedFragmentBreak(
    block: RenderBlockWrapper?, offset: LayoutUnit, breakChild: RenderBoxWrapper?, isBefore: Bool,
    offsetBreakAdjustment: inout LayoutUnit?
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func applyBreakAfterContent(offsetBreak: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isPageLogicalHeightKnown() -> Bool { return true }

  func collectLayerFragments(
    layerFragments: inout LayerFragments, layerBoundingBox: LayoutRectWrapper,
    dirtyRect: LayoutRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fragmentsBoundingBox(layerBoundingBox: LayoutRectWrapper) -> LayoutRectWrapper {
    assert(!fragmentsInvalidated)

    var result = LayoutRectWrapper()
    for fragment in fragmentList {
      var fragments = LayerFragments()
      fragment.collectLayerFragments(
        layerFragments: &fragments, layerBoundingBox: layerBoundingBox,
        dirtyRect: LayoutRectWrapper.infiniteRect())
      for fragment in fragments {
        var fragmentRect = layerBoundingBox
        fragmentRect.intersect(other: fragment.paginationClip)
        fragmentRect.move(size: fragment.paginationOffset)
        result.unite(other: fragmentRect)
      }
    }

    return result
  }

  func offsetFromLogicalTopOfFirstFragment(currentBlock: RenderBlockWrapper?) -> LayoutUnit {
    // As a last resort, take the slow path.
    let zero = LayoutUnit(value: UInt64(0))
    var blockRect = LayoutRectWrapper(
      x: zero, y: zero, width: currentBlock!.width(), height: currentBlock!.height())
    var currentBlock = currentBlock
    while currentBlock != nil && !(currentBlock is RenderViewWrapper)
      && !currentBlock!.isRenderFragmentedFlow()
    {
      let containerBlock = currentBlock!.containingBlock()!
      var currentBlockLocation = currentBlock!.location()
      if let cell = currentBlock as? RenderTableCellWrapper, let section = cell.section() {
        currentBlockLocation.moveBy(offset: section.location())
      }

      if containerBlock.style().writingMode() != currentBlock!.style().writingMode() {
        // We have to put the block rect in container coordinates
        // and we have to take into account both the container and current block flipping modes
        if containerBlock.style().isFlippedBlocksWritingMode() {
          if containerBlock.isHorizontalWritingMode() {
            blockRect.setY(y: currentBlock!.height() - blockRect.maxY())
          } else {
            blockRect.setX(x: currentBlock!.width() - blockRect.maxX())
          }
        }
        currentBlock!.flipForWritingMode(rect: &blockRect)
      }
      blockRect.moveBy(offset: currentBlockLocation)
      currentBlock = containerBlock
    }

    return currentBlock!.isHorizontalWritingMode() ? blockRect.y() : blockRect.x()
  }

  func addFragmentsVisualEffectOverflow(box: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addFragmentsVisualOverflowFromTheme(block: RenderBlockWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addFragmentsOverflowFromChild(
    box: RenderBoxWrapper, child: RenderBoxWrapper, delta: LayoutSizeWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addFragmentsVisualOverflow(box: RenderBoxWrapper, visualOverflow: LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Used to estimate the maximum height of the flow thread.
  static func maxLogicalHeight() -> LayoutUnit { return LayoutUnit.max() / 2 }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME: Eventually as column and fragment flow threads start nesting, this may end up changing.
  func shouldCheckColumnBreaks() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func getFragmentRangeForBoxFromCachedInfo(box: RenderBoxWrapper) -> (
    RenderFragmentContainerWrapper, RenderFragmentContainerWrapper
  )? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private class FragmentSearchAdapter: AdapterType {
    init(offset: LayoutUnit) {
      self.offset = offset
    }

    func result() -> RenderFragmentContainerWrapper? {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    private let offset: LayoutUnit
  }

  private let fragmentList = RenderFragmentContainerList()

  private let fragmentIntervalTree = FragmentIntervalTree()

  private let fragmentsInvalidated = false
  let pageLogicalSizeChanged = false
}
