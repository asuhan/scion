/*
 * Copyright (C) 2024 Apple Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

final class RenderViewTransitionCaptureWrapper: RenderReplacedWrapper {
  convenience init(type: RenderObjectWrapper.`Type`, document: Document, style: RenderStyleWrapper)
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setImage(oldImage: ImageBufferWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func setCapturedSize(
    size: LayoutSizeWrapper, overflowRect: LayoutRectWrapper,
    layerToLayoutOffset: LayoutPointWrapper
  ) -> Bool {
    if m_overflowRect == overflowRect && intrinsicSize() == size
      && m_layerToLayoutOffset == layerToLayoutOffset
    {
      return false
    }
    imageIntrinsicSize = size
    setIntrinsicSize(size)
    m_overflowRect = overflowRect
    m_layerToLayoutOffset = layerToLayoutOffset
    return true
  }

  override final func paintReplaced(
    _ paintInfo: inout PaintInfoWrapper, _ paintOffset: LayoutPointWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func intrinsicSizeChanged() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    super.layout()
    // Move the overflow rect of the captured renderer into layout coords, and then scale/position so that the intrinsic size subset covers
    // our replaced content rect.
    localOverflowRect = m_overflowRect
    localOverflowRect.moveBy(offset: -m_layerToLayoutOffset)
    scale = FloatSize(
      width: replacedContentRect().width().toFloat() / intrinsicSize().width().toFloat(),
      height: replacedContentRect().height().toFloat() / intrinsicSize().height().toFloat())
    localOverflowRect.scale(xScale: scale.width, yScale: scale.height)
    localOverflowRect.moveBy(offset: replacedContentRect().location())

    addVisualOverflow(rect: localOverflowRect)
  }

  // Inset of the scaled capture from the visualOverflowRect()
  func captureContentInset() -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Rect covered by the captured contents, in RenderLayer coordinates of the captured renderer
  func captureOverflowRect() -> LayoutRectWrapper { return m_overflowRect }

  func canUseExistingLayers() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func updateFromStyle() {
    super.updateFromStyle()

    if effectiveOverflowX() != .Visible || effectiveOverflowY() != .Visible {
      setHasNonVisibleOverflow()
    }
  }

  // The overflow rect that the captured image represents, in RenderLayer coordinates
  // of the captured renderer (see layerToLayoutOffset in ViewTransition.cpp).
  // The intrisic size subset of the image is stored as the intrinsic size of the RenderReplaced.
  var m_overflowRect = LayoutRectWrapper()
  // The offset between coordinates used by RenderLayer, and RenderObject
  // for the captured renderer
  var m_layerToLayoutOffset = LayoutPointWrapper()
  // The overflow rect of the snapshot (replaced content), scaled and positioned
  // so that the intrinsic size of the image fits the replaced content rect.
  var localOverflowRect = LayoutRectWrapper()
  var imageIntrinsicSize = LayoutSizeWrapper()
  // Scale factor between the intrinsic size and the replaced content rect size.
  var scale = FloatSize()
}
