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

class RenderFragmentedFlowWrapper: RenderBlockFlowWrapper {
  override func deleteLines() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeLogicalHeight(logicalHeight: LayoutUnit, logicalTop: LayoutUnit)
    -> LogicalExtentComputedValues
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func invalidateFragments(markingParents: MarkingBehavior = .MarkContainingBlockChain) {
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fragmentAtBlockOffset(
    clampBox: RenderBoxWrapper?, offset: LayoutUnit, extendLastFragment: Bool = false
  ) -> RenderFragmentContainerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fragmentsHaveUniformLogicalHeight() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func getFragmentRangeForBox(box: RenderBoxWrapper) -> (
    RenderFragmentContainerWrapper, RenderFragmentContainerWrapper
  )? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

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

  private let fragmentList = RenderFragmentContainerList()

  private let fragmentsInvalidated = false
}
