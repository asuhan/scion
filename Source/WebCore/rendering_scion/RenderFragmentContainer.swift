/*
 * Copyright (C) 2011 Adobe Systems Incorporated. All rights reserved.
 * Copyright (C) 2020 Google  Inc. All rights reserved.
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

class RenderFragmentContainerWrapper: RenderBlockFlowWrapper {
  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)

    if !isValid {
      return
    }

    if oldStyle != nil && oldStyle!.writingMode() != style().writingMode() {
      fragmentedFlow!.fragmentChangedWritingMode(self)
    }
  }

  func fragmentedFlowPortionRect() -> LayoutRectWrapper {
    return m_fragmentedFlowPortionRect
  }

  func setFragmentedFlowPortionRect(_ rect: LayoutRectWrapper) {
    m_fragmentedFlowPortionRect = rect
  }

  func fragmentedFlowPortionOverflowRect() -> LayoutRectWrapper {
    assert(isNativeImpl())
    return overflowRectForFragmentedFlowPortion(
      fragmentedFlowPortionRect(), isFirstPortion: isFirstFragment(),
      isLastPortion: isLastFragment())
  }

  func renderBoxFragmentInfo(box: RenderBoxWrapper) -> RenderBoxFragmentInfo? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func setRenderBoxFragmentInfo(
    _ box: RenderBoxWrapper, _ logicalLeftInset: LayoutUnit, _ logicalRightInset: LayoutUnit,
    _ containingBlockChainIsInset: Bool
  ) -> RenderBoxFragmentInfo? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func takeRenderBoxFragmentInfo(_ box: RenderBoxWrapper) -> RenderBoxFragmentInfo? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func removeRenderBoxFragmentInfo(_ box: RenderBoxWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func deleteAllRenderBoxFragmentInfo() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFirstFragment() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isLastFragment() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shouldClipFragmentedFlowContent() -> Bool {
    assert(isNativeImpl())
    return hasNonVisibleOverflow()
  }

  // These methods represent the width and height of a "page" and for a RenderFragmentContainer they are just the
  // content width and content height of a fragment. For RenderFragmentContainerSets, however, they will be the width and
  // height of a single column or page in the set.
  func pageLogicalWidth() -> LayoutUnit {
    assert(isNativeImpl())
    assert(isValid)
    return fragmentedFlow!.isHorizontalWritingMode() ? contentWidth() : contentHeight()
  }

  func pageLogicalHeight() -> LayoutUnit {
    assert(isNativeImpl())
    assert(isValid)
    return fragmentedFlow!.isHorizontalWritingMode() ? contentHeight() : contentWidth()
  }

  private func logicalTopOfFragmentedFlowContentRect(_ rect: LayoutRectWrapper) -> LayoutUnit {
    assert(isNativeImpl())
    assert(isValid)
    return fragmentedFlow!.isHorizontalWritingMode() ? rect.y() : rect.x()
  }

  private func logicalBottomOfFragmentedFlowContentRect(_ rect: LayoutRectWrapper) -> LayoutUnit {
    assert(isNativeImpl())
    assert(isValid)
    return fragmentedFlow!.isHorizontalWritingMode() ? rect.maxY() : rect.maxX()
  }

  func logicalTopForFragmentedFlowContent() -> LayoutUnit {
    assert(isNativeImpl())
    return logicalTopOfFragmentedFlowContentRect(fragmentedFlowPortionRect())
  }

  func logicalBottomForFragmentedFlowContent() -> LayoutUnit {
    assert(isNativeImpl())
    return logicalBottomOfFragmentedFlowContentRect(fragmentedFlowPortionRect())
  }

  // This method represents the logical height of the entire flow thread portion used by the fragment or set.
  // For RenderFragmentContainers it matches logicalPaginationHeight(), but for sets it is the height of all the pages
  // or columns added together.
  func logicalHeightOfAllFragmentedFlowContent() -> LayoutUnit {
    assert(isNativeImpl())
    return pageLogicalHeight()
  }

  // The top of the nearest page inside the fragment. For RenderFragmentContainers, this is just the logical top of the
  // flow thread portion we contain. For sets, we have to figure out the top of the nearest column or
  // page.
  func pageLogicalTopForOffset(offset: LayoutUnit) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Whether or not this fragment is a set.
  func isRenderFragmentContainerSet() -> Bool {
    assert(isNativeImpl())
    return false
  }

  func repaintFragmentedFlowContent(_ repaintRect: LayoutRectWrapper) {
    repaintFragmentedFlowContentRectangle(
      repaintRect, fragmentedFlowPortionRect(), contentBoxRect().location())
  }

  func collectLayerFragments(
    _ layerFragments: inout LayerFragments, layerBoundingBox: LayoutRectWrapper,
    dirtyRect: LayoutRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addLayoutOverflowForBox(_ box: RenderBoxWrapper, _ rect: LayoutRectWrapper) {
    if rect.isEmpty() {
      return
    }

    let fragmentOverflow = ensureOverflowForBox(box, false)

    fragmentOverflow?.addLayoutOverflow(rect: rect)
  }

  func addVisualOverflowForBox(_ box: RenderBoxWrapper, _ rect: LayoutRectWrapper) {
    if rect.isEmpty() {
      return
    }

    guard let fragmentOverflow = ensureOverflowForBox(box, false) else { return }

    var flippedRect = rect
    fragmentedFlow!.flipForWritingModeLocalCoordinates(&flippedRect)
    fragmentOverflow.addVisualOverflow(rect: flippedRect)
  }

  func visualOverflowRectForBox(_ box: RenderBoxWrapper) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME: This doesn't work for writing modes.
  func layoutOverflowRectForBoxForPropagation(_ box: RenderBoxWrapper) -> LayoutRectWrapper {
    // Only propagate interior layout overflow if we don't clip it.
    var rect = box.borderBoxRectInFragment(fragment: self)
    rect = rectFlowPortionForBox(box, rect)
    if !box.hasNonVisibleOverflow() {
      let overflow = ensureOverflowForBox(box, true)!
      rect.unite(other: overflow.layoutOverflowRect())
    }

    let hasTransform = box.isTransformed()
    if box.isInFlowPositioned() || hasTransform {
      if hasTransform {
        rect = box.layer()!.currentTransform().mapRect(rect)
      }

      if box.isInFlowPositioned() {
        rect.move(size: box.offsetForInFlowPosition())
      }
    }

    return rect
  }

  func visualOverflowRectForBoxForPropagation(_ box: RenderBoxWrapper) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rectFlowPortionForBox(_ box: RenderBoxWrapper, _ rect: LayoutRectWrapper)
    -> LayoutRectWrapper
  {
    var mappedRect = fragmentedFlow!.mapFromLocalToFragmentedFlow(box, rect)

    if let (startFragment, endFragment) = fragmentedFlow!.getFragmentRangeForBox(box: box) {
      if fragmentedFlow!.isHorizontalWritingMode() {
        if CPtrToInt(id()) != CPtrToInt(startFragment.id()) {
          mappedRect.shiftYEdgeTo(edge: max(logicalTopForFragmentedFlowContent(), mappedRect.y()))
        }
        if CPtrToInt(id()) != CPtrToInt(endFragment.id()) {
          mappedRect.setHeight(
            height: max(
              LayoutUnit(value: 0),
              min(logicalBottomForFragmentedFlowContent() - mappedRect.y(), mappedRect.height()))
          )
        }
      } else {
        if CPtrToInt(id()) != CPtrToInt(startFragment.id()) {
          mappedRect.shiftXEdgeTo(edge: max(logicalTopForFragmentedFlowContent(), mappedRect.x()))
        }
        if CPtrToInt(id()) != CPtrToInt(endFragment.id()) {
          mappedRect.setWidth(
            width: max(
              LayoutUnit(value: 0),
              min(logicalBottomForFragmentedFlowContent() - mappedRect.x(), mappedRect.width())))
        }
      }
    }

    return fragmentedFlow!.mapFromFragmentedFlowToLocal(box, mappedRect)
  }

  override func positionForPoint(
    _ point: LayoutPointWrapper, _ source: HitTestSource,
    _ fragment: RenderFragmentContainerWrapper?
  ) -> VisiblePosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func ensureOverflowForBox(_ box: RenderBoxWrapper, _ forceCreation: Bool)
    -> RenderOverflow?
  {
    assert(fragmentedFlow!.renderFragmentContainerList().contains(value: self))
    assert(isValid)

    let boxInfo = renderBoxFragmentInfo(box: box)
    if boxInfo == nil && !forceCreation {
      return nil
    }

    if boxInfo != nil && boxInfo!.overflow != nil {
      return boxInfo!.overflow
    }

    var borderBox = box.borderBoxRectInFragment(fragment: self)
    var clientBox = LayoutRectWrapper()
    assert(fragmentedFlow!.objectShouldFragmentInFlowFragment(box, self))

    if !borderBox.isEmpty() {
      borderBox = rectFlowPortionForBox(box, borderBox)

      clientBox = box.clientBoxRectInFragment(self)
      clientBox = rectFlowPortionForBox(box, clientBox)

      fragmentedFlow!.flipForWritingModeLocalCoordinates(&borderBox)
      fragmentedFlow!.flipForWritingModeLocalCoordinates(&clientBox)
    }

    if boxInfo != nil {
      boxInfo!.createOverflow(layoutOverflow: clientBox, visualOverflow: borderBox)
      return boxInfo!.overflow
    } else {
      return RenderOverflow(layoutRect: clientBox, visualRect: borderBox)
    }
  }

  override func computePreferredLogicalWidths() {
    assert(preferredLogicalWidthsDirty())

    if !isValid {
      super.computePreferredLogicalWidths()
      return
    }

    // FIXME: Currently, the code handles only the <length> case for min-width/max-width.
    // It should also support other values, like percentage, calc or viewport relative.
    m_maxPreferredLogicalWidth = LayoutUnit(value: 0)
    m_minPreferredLogicalWidth = m_maxPreferredLogicalWidth

    let styleToUse = style()
    if styleToUse.logicalWidth().isFixed() && styleToUse.logicalWidth().value() > 0 {
      m_maxPreferredLogicalWidth = adjustContentBoxLogicalWidthForBoxSizing(
        logicalWidth: styleToUse.logicalWidth())
      m_minPreferredLogicalWidth = m_maxPreferredLogicalWidth
    } else {
      computeIntrinsicLogicalWidths(
        minLogicalWidth: &m_minPreferredLogicalWidth, maxLogicalWidth: &m_maxPreferredLogicalWidth)
    }

    computePreferredLogicalWidths(
      style().logicalMinWidth(), style().logicalMaxWidth(), borderAndPaddingLogicalWidth())

    setPreferredLogicalWidthsDirty(shouldBeDirty: false)
  }

  override func computeIntrinsicLogicalWidths(
    minLogicalWidth: inout LayoutUnit, maxLogicalWidth: inout LayoutUnit
  ) {
    if !isValid {
      super.computeIntrinsicLogicalWidths(
        minLogicalWidth: &minLogicalWidth, maxLogicalWidth: &maxLogicalWidth)
      return
    }
    maxLogicalWidth = LayoutUnit()
    minLogicalWidth = LayoutUnit()
  }

  func overflowRectForFragmentedFlowPortion(
    _ fragmentedFlowPortionRect: LayoutRectWrapper, isFirstPortion: Bool, isLastPortion: Bool
  ) -> LayoutRectWrapper {
    assert(isValid)
    if shouldClipFragmentedFlowContent() {
      return fragmentedFlowPortionRect
    }

    let fragmentedFlowOverflow = visualOverflowRectForBox(fragmentedFlow!)
    var clipRect = LayoutRectWrapper()
    if fragmentedFlow!.isHorizontalWritingMode() {
      let minY = isFirstPortion ? fragmentedFlowOverflow.y() : fragmentedFlowPortionRect.y()
      let maxY =
        isLastPortion
        ? max(fragmentedFlowPortionRect.maxY(), fragmentedFlowOverflow.maxY())
        : fragmentedFlowPortionRect.maxY()
      let clipX = effectiveOverflowX() != .Visible
      let minX =
        clipX
        ? fragmentedFlowPortionRect.x()
        : min(fragmentedFlowPortionRect.x(), fragmentedFlowOverflow.x())
      let maxX =
        clipX
        ? fragmentedFlowPortionRect.maxX()
        : max(fragmentedFlowPortionRect.maxX(), fragmentedFlowOverflow.maxX())
      clipRect = LayoutRectWrapper(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    } else {
      let minX = isFirstPortion ? fragmentedFlowOverflow.x() : fragmentedFlowPortionRect.x()
      let maxX =
        isLastPortion
        ? max(fragmentedFlowPortionRect.maxX(), fragmentedFlowOverflow.maxX())
        : fragmentedFlowPortionRect.maxX()
      let clipY = effectiveOverflowY() != .Visible
      let minY =
        clipY
        ? fragmentedFlowPortionRect.y()
        : min(fragmentedFlowPortionRect.y(), fragmentedFlowOverflow.y())
      let maxY =
        clipY
        ? fragmentedFlowPortionRect.maxY()
        : max(fragmentedFlowPortionRect.y(), fragmentedFlowOverflow.maxY())
      clipRect = LayoutRectWrapper(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
    return clipRect
  }

  func repaintFragmentedFlowContentRectangle(
    _ repaintRect: LayoutRectWrapper, _ fragmentedFlowPortionRect: LayoutRectWrapper,
    _ fragmentLocation: LayoutPointWrapper,
    _ fragmentedFlowPortionClipRect: LayoutRectWrapper? = nil
  ) {
    assert(isValid)

    // We only have to issue a repaint in this fragment if the fragment rect intersects the repaint rect.
    var clippedRect = repaintRect

    if fragmentedFlowPortionClipRect != nil {
      var flippedFragmentedFlowPortionClipRect = fragmentedFlowPortionClipRect!
      fragmentedFlow!.flipForWritingMode(rect: &flippedFragmentedFlowPortionClipRect)
      clippedRect.intersect(other: flippedFragmentedFlowPortionClipRect)
    }

    if clippedRect.isEmpty() {
      return
    }

    var flippedFragmentedFlowPortionRect = fragmentedFlowPortionRect
    fragmentedFlow!.flipForWritingMode(rect: &flippedFragmentedFlowPortionRect)  // Put the fragment rects into physical coordinates.

    // Put the fragment rect into the fragment's physical coordinate space.
    clippedRect.setLocation(
      location: fragmentLocation
        + (clippedRect.location() - flippedFragmentedFlowPortionRect.location()))

    // Now switch to the fragment's writing mode coordinate space and let it repaint itself.
    flipForWritingMode(rect: &clippedRect)

    // Issue the repaint.
    repaintRectangle(repaintRect: clippedRect)
  }

  let fragmentedFlow: RenderFragmentedFlowWrapper? = nil

  private var m_fragmentedFlowPortionRect = LayoutRectWrapper()

  private let isValid = false
}

class CurrentRenderFragmentContainerMaintainer {
  init(_ fragment: RenderFragmentContainerWrapper) {
    self.fragment = fragment
    let fragmentedFlow = fragment.fragmentedFlow!
    // A flow thread can have only one current fragment.
    assert(fragmentedFlow.currentFragment() == nil)
    fragmentedFlow.currentFragmentMaintainer = self
  }

  deinit {
    let fragmentedFlow = fragment.fragmentedFlow!
    fragmentedFlow.currentFragmentMaintainer = nil
  }

  private let fragment: RenderFragmentContainerWrapper
}
