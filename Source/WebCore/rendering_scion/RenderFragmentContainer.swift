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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func isFirstFragment() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isLastFragment() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // These methods represent the width and height of a "page" and for a RenderFragmentContainer they are just the
  // content width and content height of a fragment. For RenderFragmentContainerSets, however, they will be the width and
  // height of a single column or page in the set.
  func pageLogicalWidth() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pageLogicalHeight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalTopForFragmentedFlowContent() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // This method represents the logical height of the entire flow thread portion used by the fragment or set.
  // For RenderFragmentContainers it matches logicalPaginationHeight(), but for sets it is the height of all the pages
  // or columns added together.
  func logicalHeightOfAllFragmentedFlowContent() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  override func positionForPoint(
    _ point: LayoutPointWrapper, _ source: HitTestSource,
    _ fragment: RenderFragmentContainerWrapper?
  ) -> VisiblePosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
