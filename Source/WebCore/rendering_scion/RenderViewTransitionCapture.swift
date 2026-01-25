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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Inset of the scaled capture from the visualOverflowRect()
  func captureContentInset() -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Rect covered by the captured contents, in RenderLayer coordinates of the captured renderer
  func captureOverflowRect() -> LayoutRectWrapper { return overflowRect }

  func canUseExistingLayers() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func updateFromStyle() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The overflow rect that the captured image represents, in RenderLayer coordinates
  // of the captured renderer (see layerToLayoutOffset in ViewTransition.cpp).
  // The intrisic size subset of the image is stored as the intrinsic size of the RenderReplaced.
  let overflowRect = LayoutRectWrapper()
  // Scale factor between the intrinsic size and the replaced content rect size.
  let scale = FloatSize()
}
