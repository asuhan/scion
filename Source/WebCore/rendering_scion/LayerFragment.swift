/*
 * Copyright (C) 2015 Apple Inc. All rights reserved.
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

class LayerFragment {
  func setRects(
    bounds: LayoutRectWrapper, background: ClipRect, foreground: ClipRect, bbox: LayoutRectWrapper?
  ) {
    layerBounds = bounds
    backgroundRect = background
    foregroundRect = foreground
    boundingBox = bbox
  }

  func moveBy(offset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func intersect(rect: LayoutRectWrapper) {
    backgroundRect.intersect(other: rect)
    foregroundRect.intersect(other: rect)
    if boundingBox != nil {
      boundingBox!.intersect(other: rect)
    }
  }

  func intersect(clipRect: ClipRect) {
    backgroundRect.intersect(other: clipRect)
    foregroundRect.intersect(other: clipRect)
  }

  var shouldPaintContent: Bool = false
  var boundingBox: LayoutRectWrapper? = nil

  var layerBounds = LayoutRectWrapper()
  var backgroundRect = ClipRect()
  var foregroundRect = ClipRect()

  // Unique to paginated fragments. The physical translation to apply to shift the layer when painting/hit-testing.
  var paginationOffset = LayoutSizeWrapper()

  // Also unique to paginated fragments. An additional clip that applies to the layer. It is in layer-local
  // (physical) coordinates.
  let paginationClip = LayoutRectWrapper()
}

typealias LayerFragments = [LayerFragment]
