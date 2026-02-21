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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func multiColumnBlockFlow() -> RenderBlockFlowWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func firstMultiColumnSet() -> RenderMultiColumnSetWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastMultiColumnSet() -> RenderMultiColumnSetWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func nextColumnSetOrSpannerSiblingOf(child: RenderBoxWrapper?) -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func previousColumnSetOrSpannerSiblingOf(child: RenderBoxWrapper?) -> RenderBoxWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func findColumnSpannerPlaceholder(spanner: RenderBoxWrapper?)
    -> RenderMultiColumnSpannerPlaceholderWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func columnCount() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func columnWidth() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setColumnHeightAvailable(available: LayoutUnit) { columnHeightAvailable = available }

  func setInBalancingPass(balancing: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setNeedsHeightsRecalculation(recalculate: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldRelayoutForPagination() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setColumnCountAndWidth(count: UInt32, width: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func progressionIsInline() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setProgressionIsInline(progressionIsInline: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func progressionIsReversed() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setProgressionIsReversed(reversed: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    _ request: HitTestRequestWrapper, _ result: HitTestResultWrapper,
    _ locationInContainer: HitTestLocationWrapper, _ accumulatedOffset: LayoutPointWrapper,
    _ action: HitTestAction
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func mapAbsoluteToLocalPoint(
    _ mode: MapCoordinatesMode, _ transformState: inout TransformState
  ) {
    // First get the transform state's point into the block flow thread's physical coordinate space.
    parent()!.mapAbsoluteToLocalPoint(mode, &transformState)
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
    assert(CPtrToInt(enclosingContainer.p) == CPtrToInt(self.container()?.p))

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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func fragmentedFlowDescendantBoxLaidOut(descendant: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func initialLogicalWidth() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  var columnHeightAvailable: LayoutUnit  // Total height available to columns, or 0 if auto.
  let inBalancingPass = false  // Guard to avoid re-entering column balancing.
}
