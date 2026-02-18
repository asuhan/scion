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
typealias ContainingFragmentMap = HashMap<LegacyRootInlineBox?, RenderFragmentContainerWrapper>
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
    var logicalWidth = initialLogicalWidth()
    for fragment in fragmentList {
      assert(!fragment.needsLayout() || fragment.isRenderFragmentContainerSet())
      logicalWidth = max(fragment.pageLogicalWidth(), logicalWidth)
    }
    setLogicalWidth(size: logicalWidth)

    // If the fragments have non-uniform logical widths, then insert inset information for the RenderFragmentedFlow.
    for fragment in fragmentList {
      let fragmentLogicalWidth = fragment.pageLogicalWidth()
      let logicalLeft =
        style().direction() == .LTR
        ? LayoutUnit(value: UInt64(0)) : logicalWidth - fragmentLogicalWidth
      fragment.setRenderBoxFragmentInfo(self, logicalLeft, fragmentLogicalWidth, false)
    }
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

  func validateFragments() {
    if fragmentsInvalidated {
      fragmentsInvalidated = false
      fragmentsHaveUniformLogicalWidth = true
      fragmentsHaveUniformLogicalHeight = true

      if hasFragments() {
        var previousFragmentLogicalWidth = LayoutUnit()
        let previousFragmentLogicalHeight = LayoutUnit()
        var firstFragmentVisited = false

        for fragment in fragmentList {
          assert(!fragment.needsLayout() || fragment.isRenderFragmentContainerSet())

          fragment.deleteAllRenderBoxFragmentInfo()

          let fragmentLogicalWidth = fragment.pageLogicalWidth()
          let fragmentLogicalHeight = fragment.pageLogicalHeight()

          if !firstFragmentVisited {
            firstFragmentVisited = true
          } else {
            if fragmentsHaveUniformLogicalWidth
              && previousFragmentLogicalWidth != fragmentLogicalWidth
            {
              fragmentsHaveUniformLogicalWidth = false
            }
            if fragmentsHaveUniformLogicalHeight
              && previousFragmentLogicalHeight != fragmentLogicalHeight
            {
              fragmentsHaveUniformLogicalHeight = false
            }
          }

          previousFragmentLogicalWidth = fragmentLogicalWidth
        }

        setFragmentRangeForBox(
          box: self, startFragment: fragmentList.first(), endFragment: fragmentList.last())
      }
    }

    updateLogicalWidth()  // Called to get the maximum logical width for the fragment.
    updateFragmentsFragmentedFlowPortionRect()
  }

  func invalidateFragments(markingParents: MarkingBehavior = .MarkContainingBlockChain) {
    if fragmentsInvalidated {
      assert(selfNeedsLayout())
      return
    }

    fragmentRangeMap.clear()
    breakBeforeToFragmentMap.clear()
    breakAfterToFragmentMap.clear()
    lineToFragmentMap?.clear()
    setNeedsLayout(markParents: markingParents)

    fragmentsInvalidated = true
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
    super.styleDidChange(diff: diff, oldStyle: oldStyle)

    if oldStyle != nil && oldStyle!.writingMode() != style().writingMode() {
      invalidateFragments()
    }
  }

  func repaintRectangleInFragments(_ repaintRect: LayoutRectWrapper) {
    if !shouldRepaint(repaintRect) || !hasValidFragmentInfo() {
      return
    }

    let _ = LayoutStateDisabler(context: view().frameView().layoutContext())  // We can't use layout state to repaint, since the fragments are somewhere else.

    for fragment in fragmentList {
      fragment.repaintFragmentedFlowContent(repaintRect)
    }
  }

  func pageLogicalHeightForOffsetFromFragmentedFlow(offset: LayoutUnit) -> LayoutUnit {
    if let fragment = fragmentAtBlockOffset(
      clampBox: nil, offset: offset, extendLastFragment: false)
    {
      return fragment.pageLogicalHeight()
    }

    return LayoutUnit(value: 0)
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

  func mapFromFlowToFragment(_ transformState: TransformState) -> RenderFragmentContainerWrapper? {
    if !hasValidFragmentInfo() {
      return nil
    }

    var RenderFragmentContainer = currentFragment()
    if RenderFragmentContainer == nil {
      var boxRect = LayoutRectWrapper(rect: transformState.mappedQuad().enclosingBoundingBox())
      flipForWritingMode(rect: &boxRect)

      let center = boxRect.center()
      RenderFragmentContainer = fragmentAtBlockOffset(
        clampBox: self, offset: isHorizontalWritingMode() ? center.y : center.x,
        extendLastFragment: true)
      if RenderFragmentContainer == nil {
        return nil
      }
    }

    var flippedFragmentRect = RenderFragmentContainer!.fragmentedFlowPortionRect()
    flipForWritingMode(rect: &flippedFragmentRect)

    transformState.move(
      RenderFragmentContainer!.contentBoxRect().location() - flippedFragmentRect.location())

    return RenderFragmentContainer
  }

  func logicalWidthChangedInFragmentsForBlock(
    block: RenderBlockWrapper, relayoutChildren: inout Bool
  ) {
    if !hasValidFragmentInfo() {
      return
    }

    if !fragmentRangeMap.contains(block) {
      return
    }

    let range = fragmentRangeMap.get(block)
    let rangeInvalidated = range.rangeInvalidated()
    range.clearRangeInvalidated()

    // If there will be a relayout anyway skip the next steps because they only verify
    // the state of the ranges.
    if relayoutChildren {
      return
    }

    // Not necessary for the flow thread, since we already computed the correct info for it.
    // If the fragments have changed invalidate the children.
    if CPtrToInt(block.p) == CPtrToInt(p) {
      relayoutChildren = pageLogicalSizeChanged
      return
    }

    guard let (startFragment, endFragment) = getFragmentRangeForBox(box: block) else { return }

    let it = fragmentList.find(value: startFragment)
    let end = fragmentList.end()
    while it != end {
      let fragment = *it
      assert(!fragment.needsLayout() || fragment.isRenderFragmentContainerSet())

      // We have no information computed for this fragment so we need to do it.
      guard let oldInfo = fragment.takeRenderBoxFragmentInfo(block) else {
        relayoutChildren = rangeInvalidated
        return
      }

      let oldLogicalWidth = oldInfo.logicalWidth
      let newInfo = block.renderBoxFragmentInfo(fragment: fragment)
      if newInfo == nil || newInfo!.logicalWidth != oldLogicalWidth {
        relayoutChildren = true
        return
      }

      if CPtrToInt(fragment.p) == CPtrToInt(endFragment.p) {
        break
      }
      ++it
    }
  }

  func contentLogicalWidthOfFirstFragment() -> LayoutUnit {
    guard let firstValidFragmentInFlow = firstFragment() else { return LayoutUnit(value: 0) }
    return isHorizontalWritingMode()
      ? firstValidFragmentInFlow.contentWidth() : firstValidFragmentInFlow.contentHeight()
  }

  func contentLogicalHeightOfFirstFragment() -> LayoutUnit {
    guard let firstValidFragmentInFlow = firstFragment() else { return LayoutUnit(value: 0) }
    return isHorizontalWritingMode()
      ? firstValidFragmentInFlow.contentHeight() : firstValidFragmentInFlow.contentWidth()
  }

  func firstFragment() -> RenderFragmentContainerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFragmentRangeForBox(
    box: RenderBoxWrapper, startFragment: RenderFragmentContainerWrapper,
    endFragment: RenderFragmentContainerWrapper
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

  // Check if the object should be painted in this fragment and if the fragment is part of this flow thread.
  func objectShouldFragmentInFlowFragment(
    _ object: RenderObjectWrapper, _ fragment: RenderFragmentContainerWrapper
  ) -> Bool {
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
    _ layerFragments: inout LayerFragments, layerBoundingBox: LayoutRectWrapper,
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
        &fragments, layerBoundingBox: layerBoundingBox,
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

  func clearFragmentsOverflow(_ box: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Used to estimate the maximum height of the flow thread.
  static func maxLogicalHeight() -> LayoutUnit { return LayoutUnit.max() / 2 }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func currentFragment() -> RenderFragmentContainerWrapper? {
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

  // Overridden by columns/pages to set up an initial logical width of the page width even when
  // no fragments have been generated yet.
  func initialLogicalWidth() -> LayoutUnit { return LayoutUnit(value: 0) }

  override func mapLocalToContainer(
    _ ancestorContainer: RenderLayerModelObjectWrapper?, _ transformState: TransformState,
    _ mode: MapCoordinatesMode, _ wasFixed: inout Bool?
  ) {
    if CPtrToInt(p) == CPtrToInt(ancestorContainer?.p) {
      return
    }

    guard let fragment = mapFromFlowToFragment(transformState) else { return }

    let fragmentObject: RenderObjectWrapper = fragment

    // If the repaint container is nullptr, we have to climb up to the RenderView, otherwise swap
    // it with the fragment's repaint container.
    let ancestorContainer = ancestorContainer != nil ? fragment.containerForRepaint().renderer : nil

    if let fragmentFragmentedFlow = fragment.enclosingFragmentedFlow(),
      let (startFragment, _) = fragmentFragmentedFlow.getFragmentRangeForBox(box: fragment)
    {
      let _ = CurrentRenderFragmentContainerMaintainer(startFragment)
      fragmentObject.mapLocalToContainer(ancestorContainer, transformState, mode, &wasFixed)
      return
    }

    fragmentObject.mapLocalToContainer(ancestorContainer, transformState, mode, &wasFixed)
  }

  func updateFragmentsFragmentedFlowPortionRect() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func shouldRepaint(_ r: LayoutRectWrapper) -> Bool {
    if view().printing() || r.isEmpty() {
      return false
    }

    return true
  }

  private func getFragmentRangeForBoxFromCachedInfo(box: RenderBoxWrapper) -> (
    RenderFragmentContainerWrapper, RenderFragmentContainerWrapper
  )? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private class RenderFragmentContainerRange {
    init() {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }

    func rangeInvalidated() -> Bool { return m_rangeInvalidated }
    func clearRangeInvalidated() { m_rangeInvalidated = false }

    private var m_rangeInvalidated: Bool
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

  // Map a line to its containing fragment.
  private let lineToFragmentMap: ContainingFragmentMap? = nil

  // Map a box to the list of fragments in which the box is rendered.
  private typealias RenderFragmentContainerRangeMap = HashMap<
    RenderBoxWrapper, RenderFragmentContainerRange
  >
  private let fragmentRangeMap = RenderFragmentContainerRangeMap()

  // Map a box with a fragment break to the auto height fragment affected by that break.
  private typealias RenderBoxToFragmentMap = HashMap<
    RenderBoxWrapper, RenderFragmentContainerWrapper
  >
  private let breakBeforeToFragmentMap = RenderBoxToFragmentMap()
  private let breakAfterToFragmentMap = RenderBoxToFragmentMap()

  private let fragmentIntervalTree = FragmentIntervalTree()

  var currentFragmentMaintainer: CurrentRenderFragmentContainerMaintainer? = nil

  private var fragmentsInvalidated = false
  private var fragmentsHaveUniformLogicalWidth = false
  var fragmentsHaveUniformLogicalHeight = false
  let pageLogicalSizeChanged = false
}
