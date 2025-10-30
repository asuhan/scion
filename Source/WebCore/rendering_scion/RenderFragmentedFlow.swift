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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func offsetFromLogicalTopOfFirstFragment(currentBlock: RenderBlockWrapper?) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
