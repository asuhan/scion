/*
 * Copyright (c) 2009, Google Inc. All rights reserved.
 * Copyright (C) 2020, 2021, 2022, 2024 Igalia S.L.
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

class RenderSVGModelObjectWrapper: RenderLayerModelObjectWrapper {
  override func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func currentSVGLayoutRect() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setCurrentSVGLayoutRect(_ layoutRect: LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func currentSVGLayoutLocation() -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func visualOverflowRectEquivalent() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasVisualOverflow() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderBoxRectInFragmentEquivalent(
    fragment: RenderFragmentContainerWrapper?,
    flags: RenderBoxWrapper.RenderBoxFragmentInfoFlags = .CacheRenderBoxFragmentInfo
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overflowClipRect(
    location: LayoutPointWrapper, fragment: RenderFragmentContainerWrapper? = nil,
    relevancy: OverlayScrollbarSizeRelevancy = .IgnoreOverlayScrollbarSize,
    phase: PaintPhase = .BlockBackground
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overflowClipRectForChildLayers(
    location: LayoutPointWrapper, fragment: RenderFragmentContainerWrapper?,
    relevancy: OverlayScrollbarSizeRelevancy
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func localRectsForRepaint(_ repaintOutlineBounds: RepaintOutlineBounds) -> RepaintRects {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeVisibleRectsInContainer(
    _ rects: inout RepaintRects, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> RepaintRects? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func addFocusRingRects(
    rects: inout [LayoutRectWrapper], additionalOffset: LayoutPointWrapper,
    paintContainer: RenderLayerModelObjectWrapper? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSVGOutline(_ paintInfo: PaintInfoWrapper, _ adjustedPaintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns false if the rect has no intersection with the applied clip rect. When the context specifies edge-inclusive
  // intersection, this return value allows distinguishing between no intersection and zero-area intersection.
  @discardableResult
  override final func applyCachedClipAndScrollPosition(
    _ rects: inout RepaintRects, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
