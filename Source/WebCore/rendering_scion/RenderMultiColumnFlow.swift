/*
 * Copyright (C) 2012-2023 Apple Inc.  All rights reserved.
 * Copyright (C) 2014 Google Inc.  All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS IN..0TERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF  ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

class RenderMultiColumnFlowWrapper: RenderFragmentedFlowWrapper {
  init(document: Document, style: RenderStyleWrapper) {
    super.init(.MultiColumnFlow, document, style)
    setFragmentedFlowState(.InsideFlow)
    assert(isRenderMultiColumnFlow())
  }

  func multiColumnBlockFlow() -> RenderBlockFlowWrapper? {
    assert(isNativeImpl())
    return parent() as! RenderBlockFlowWrapper?
  }

  func firstMultiColumnSet() -> RenderMultiColumnSetWrapper? {
    assert(isNativeImpl())
    var sibling = nextSibling()
    while sibling != nil {
      if let multiColumnSet = sibling! as? RenderMultiColumnSetWrapper {
        return multiColumnSet
      }
      sibling = sibling!.nextSibling()
    }
    return nil
  }

  func lastMultiColumnSet() -> RenderMultiColumnSetWrapper? {
    assert(isNativeImpl())
    assert(multiColumnBlockFlow() != nil)

    var sibling = multiColumnBlockFlow()!.lastChild()
    while sibling != nil {
      if let multiColumnSet = sibling! as? RenderMultiColumnSetWrapper {
        return multiColumnSet
      }
      sibling = sibling!.previousSibling()
    }
    return nil
  }

  private func firstColumnSetOrSpanner() -> RenderBoxWrapper? {
    assert(isNativeImpl())
    if let sibling = nextSibling() {
      assert(
        sibling is RenderMultiColumnSetWrapper
          || findColumnSpannerPlaceholder(spanner: sibling as! RenderBoxWrapper?) != nil)
      return sibling as! RenderBoxWrapper?
    }
    return nil
  }

  static func nextColumnSetOrSpannerSiblingOf(child: RenderBoxWrapper?) -> RenderBoxWrapper? {
    return child?.nextSiblingBox()
  }

  static func previousColumnSetOrSpannerSiblingOf(child: RenderBoxWrapper?) -> RenderBoxWrapper? {
    if child == nil {
      return nil
    }
    if let sibling = child!.previousSiblingBox() {
      if !(sibling is RenderFragmentedFlowWrapper) {
        return sibling
      }
    }
    return nil
  }

  func findColumnSpannerPlaceholder(spanner: RenderBoxWrapper?)
    -> RenderMultiColumnSpannerPlaceholderWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    assert(isNativeImpl())
    assert(!m_inLayout)
    m_inLayout = true
    m_lastSetWorkedOn = nil
    if let first = firstColumnSetOrSpanner(),
      let multiColumnSet = first as? RenderMultiColumnSetWrapper
    {
      m_lastSetWorkedOn = multiColumnSet
      multiColumnSet.beginFlow(self)
    }
    super.layout()
    if let lastSet = lastMultiColumnSet() {
      if RenderMultiColumnFlowWrapper.nextColumnSetOrSpannerSiblingOf(child: lastSet) == nil {
        lastSet.endFlow(self, logicalHeight())
      }
      lastSet.expandToEncompassFragmentedFlowContentsIfNeeded()
    }
    m_inLayout = false
    m_lastSetWorkedOn = nil
  }

  func columnCount() -> UInt32 {
    assert(isNativeImpl())
    return m_columnCount
  }

  func columnWidth() -> LayoutUnit {
    assert(isNativeImpl())
    return m_columnWidth
  }

  func setColumnHeightAvailable(available: LayoutUnit) { columnHeightAvailable = available }

  func setInBalancingPass(balancing: Bool) {
    assert(isNativeImpl())
    self.inBalancingPass = balancing
  }

  func setNeedsHeightsRecalculation(recalculate: Bool) {
    assert(isNativeImpl())
    m_needsHeightsRecalculation = recalculate
  }

  func shouldRelayoutForPagination() -> Bool {
    assert(isNativeImpl())
    return !inBalancingPass && m_needsHeightsRecalculation
  }

  func setColumnCountAndWidth(count: UInt32, width: LayoutUnit) {
    assert(isNativeImpl())
    m_columnCount = count
    m_columnWidth = width
  }

  func progressionIsInline() -> Bool {
    assert(isNativeImpl())
    return m_progressionIsInline
  }

  func setProgressionIsInline(progressionIsInline: Bool) {
    assert(isNativeImpl())
    m_progressionIsInline = progressionIsInline
  }

  func progressionIsReversed() -> Bool {
    assert(isNativeImpl())
    return m_progressionIsReversed
  }

  func setProgressionIsReversed(reversed: Bool) {
    assert(isNativeImpl())
    m_progressionIsReversed = reversed
  }

  override final func mapFromFlowToFragment(_ transformState: TransformState)
    -> RenderFragmentContainerWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The point is physical, and the result is a physical location within the fragment.
  func physicalTranslationFromFlowToFragment(physicalPoint: LayoutPointWrapper)
    -> RenderFragmentContainerWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // This method is the inverse of the previous method and goes from fragment to flow.
  private func physicalTranslationFromFragmentToFlow(
    _ columnSet: RenderMultiColumnSetWrapper?, _ physicalPoint: LayoutPointWrapper
  ) -> LayoutSizeWrapper {
    let logicalPoint: LayoutPointWrapper = columnSet!.flipForWritingMode(position: physicalPoint)
    let translatedPoint: LayoutPointWrapper = columnSet!.translateFragmentPointToFragmentedFlow(
      logicalPoint)
    let physicalTranslatedPoint: LayoutPointWrapper = columnSet!.flipForWritingMode(
      position: translatedPoint)
    return physicalPoint - physicalTranslatedPoint
  }

  override func nodeAtPoint(
    _ request: HitTestRequestWrapper, _ result: inout HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ hitTestAction: HitTestAction
  ) -> Bool {
    // You cannot be inside an in-flow RenderFragmentedFlow without a corresponding DOM node. It's better to
    // just let the ancestor figure out where we are instead.
    if hitTestAction == .HitTestBlockBackground {
      return false
    }
    let inside = super.nodeAtPoint(
      request, &result, locationInContainer, accumulatedOffset, hitTestAction)
    if inside && result.innerNode() == nil {
      return false
    }
    return inside
  }

  override func mapAbsoluteToLocalPoint(
    _ mode: MapCoordinatesMode, _ transformState: TransformState
  ) {
    // First get the transform state's point into the block flow thread's physical coordinate space.
    parent()!.mapAbsoluteToLocalPoint(mode, transformState)
    let transformPoint = LayoutPointWrapper(size: transformState.mappedPoint())

    // Now walk through each fragment.
    var candidateColumnSet: RenderMultiColumnSetWrapper? = nil
    var candidatePoint = LayoutPointWrapper()
    var candidateContainerOffset = LayoutSizeWrapper()

    for columnSet: RenderMultiColumnSetWrapper in childrenOfType(parent: parent()!) {
      var unused: Bool? = nil
      candidateContainerOffset = columnSet.offsetFromContainer(
        parent()!, LayoutPointWrapper(), &unused)

      candidatePoint = transformPoint - candidateContainerOffset
      candidateColumnSet = columnSet

      // We really have no clue what to do with overflow. We'll just use the closest fragment to the point in that case.
      let pointOffset = isHorizontalWritingMode() ? candidatePoint.y : candidatePoint.x
      let fragmentOffset =
        isHorizontalWritingMode() ? columnSet.topLeftLocation().y : columnSet.topLeftLocation().x
      if pointOffset < fragmentOffset + columnSet.logicalHeight() {
        break
      }
    }

    // Once we have a good guess as to which fragment we hit tested through (and yes, this was just a heuristic, but it's
    // the best we could do), then we can map from the fragment into the flow thread.
    let translationOffset =
      physicalTranslationFromFragmentToFlow(candidateColumnSet, candidatePoint)
      + candidateContainerOffset
    pushOntoTransformState(transformState, mode, nil, parent(), translationOffset, false)
  }

  override func offsetFromContainer(
    _ enclosingContainer: RenderElementWrapper, _ physicalPoint: LayoutPointWrapper,
    _ offsetDependsOnPoint: inout Bool?
  ) -> LayoutSizeWrapper {
    assert(CPtrToInt(enclosingContainer.id()) == CPtrToInt(self.container()?.id()))

    if offsetDependsOnPoint != nil {
      offsetDependsOnPoint = true
    }

    var translatedPhysicalPoint = physicalPoint
    if let fragment = physicalTranslationFromFlowToFragment(physicalPoint: translatedPhysicalPoint)
    {
      translatedPhysicalPoint.moveBy(offset: fragment.topLeftLocation())
    }

    var offset = LayoutSizeWrapper(
      width: translatedPhysicalPoint.x, height: translatedPhysicalPoint.y)
    if let enclosingBox = enclosingContainer as? RenderBoxWrapper {
      offset -= toLayoutSize(point: LayoutPointWrapper(point: enclosingBox.scrollPosition()))
    }
    return offset
  }

  // FIXME: Eventually as column and fragment flow threads start nesting, this will end up changing.
  override func shouldCheckColumnBreaks() -> Bool {
    assert(isNativeImpl())
    if !parent()!.isRenderView() {
      return true
    }
    return view().frameView().pagination().behavesLikeColumns
  }

  func addFragmentToThread(_ fragmentContainer: RenderFragmentContainerWrapper) {
    assert(isNativeImpl())
    let columnSet = fragmentContainer as! RenderMultiColumnSetWrapper
    if let nextSet = columnSet.nextSiblingMultiColumnSet() {
      let it = fragmentList.find(value: nextSet)
      assert(it != fragmentList.end())
      fragmentList.insertBefore(it, columnSet)
    } else {
      fragmentList.add(value: columnSet)
    }
    fragmentContainer.isValid = true
  }

  override func willBeRemovedFromTree() {
    assert(isNativeImpl())
    // Detach all column sets from the flow thread. Cannot destroy them at this point, since they
    // are siblings of this object, and there may be pointers to this object's sibling somewhere
    // further up on the call stack.
    var columnSet = firstMultiColumnSet()
    while columnSet != nil {
      columnSet!.detachFragment()
      columnSet = columnSet!.nextSiblingMultiColumnSet()
    }
    super.willBeRemovedFromTree()
  }

  override func fragmentedFlowDescendantBoxLaidOut(descendant: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    assert(isNativeImpl())
    // We simply remain at our intrinsic height.
    return LogicalExtentComputedValues(
      extent: logicalHeight, position: logicalTop, margins: ComputedMarginValues())
  }

  override func initialLogicalWidth() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func setPageBreak(
    _ block: RenderBlockWrapper, offset: LayoutUnit, spaceShortage: LayoutUnit
  ) {
    // Only positive values are interesting (and allowed) here. Zero space shortage may be reported
    // when we're at the top of a column and the element has zero height. Ignore this, and also
    // ignore any negative values, which may occur when we set an early break in order to honor
    // widows in the next column.
    if spaceShortage <= Int32(0) {
      return
    }

    let multicolSet =
      fragmentAtBlockOffset(clampBox: block, offset: offset) as! RenderMultiColumnSetWrapper?
    multicolSet?.recordSpaceShortage(spaceShortage)
  }

  override func updateMinimumPageHeight(
    _ block: RenderBlockWrapper, offset: LayoutUnit, minHeight: LayoutUnit
  ) {
    assert(isNativeImpl())
    if !hasValidFragmentInfo() {
      return
    }

    let multicolSet =
      fragmentAtBlockOffset(clampBox: block, offset: offset) as! RenderMultiColumnSetWrapper?
    multicolSet?.updateMinimumColumnHeight(minHeight)
  }

  override func updateSpaceShortageForSizeContainment(
    block: RenderBlockWrapper, offset: LayoutUnit, shortage: LayoutUnit
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func fragmentAtBlockOffset(
    clampBox: RenderBoxWrapper?, offset: LayoutUnit, extendLastFragment: Bool = false
  ) -> RenderFragmentContainerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func setFragmentRangeForBox(
    box: RenderBoxWrapper, startFragment: RenderFragmentContainerWrapper,
    endFragment: RenderFragmentContainerWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func addForcedFragmentBreak(
    block: RenderBlockWrapper?, offset: LayoutUnit, breakChild: RenderBoxWrapper?, isBefore: Bool,
    offsetBreakAdjustment: inout LayoutUnit?
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func isPageLogicalHeightKnown() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  typealias SpannerMap = [UInt: RenderMultiColumnSpannerPlaceholderWrapper]

  var spannerMap: SpannerMap {
    get {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    set {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
  }

  // The last set we worked on. It's not to be used as the "current set". The concept of a
  // "current set" is difficult, since layout may jump back and forth in the tree, due to wrong
  // top location estimates (due to e.g. margin collapsing), and possibly for other reasons.
  private var m_lastSetWorkedOn: RenderMultiColumnSetWrapper? = nil

  private var m_columnCount: UInt32 = 1  // The default column count/width that are based off our containing block width. These values represent only the default.
  private var m_columnWidth = LayoutUnit(value: 0)  // A multi-column block that is split across variable width pages or fragments will have different column counts and widths in each. These values will be cached (eventually) for multi-column blocks.

  var columnHeightAvailable = LayoutUnit()  // Total height available to columns, or 0 if auto.
  private var m_inLayout = false  // Set while we're laying out the flow thread, during which colum set heights are unknown.
  var inBalancingPass = false  // Guard to avoid re-entering column balancing.
  private var m_needsHeightsRecalculation = false

  private var m_progressionIsInline = false
  private var m_progressionIsReversed = false
}
