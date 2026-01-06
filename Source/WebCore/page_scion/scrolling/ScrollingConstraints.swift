/*
 * Copyright (C) 2012 Apple Inc. All rights reserved.
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

struct AbsolutePositionConstraints {
  let alignmentOffset: FloatSize
  let layerPositionAtLastLayout: FloatPoint
}

// ViewportConstraints classes encapsulate data and logic required to reposition elements whose layout
// depends on the viewport rect (positions fixed and sticky), when scrolling and zooming.
class ViewportConstraints {
  struct AnchorEdgeFlags: OptionSet {
    let rawValue: UInt8

    static let AnchorEdgeLeft = AnchorEdgeFlags(rawValue: 1 << 0)
    static let AnchorEdgeRight = AnchorEdgeFlags(rawValue: 1 << 1)
    static let AnchorEdgeTop = AnchorEdgeFlags(rawValue: 1 << 2)
    static let AnchorEdgeBottom = AnchorEdgeFlags(rawValue: 1 << 3)
  }

  func addAnchorEdge(edgeFlag: AnchorEdgeFlags) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setAlignmentOffset(_ offset: FloatSize) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

final class FixedPositionViewportConstraints: ViewportConstraints {
  func setViewportRectAtLastLayout(_ rect: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLayerPositionAtLastLayout(_ position: FloatPoint) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

final class StickyPositionViewportConstraints: ViewportConstraints {
  func computeStickyOffset(constrainingRect: FloatRectWrapper) -> FloatSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setStickyOffsetAtLastLayout(_ offset: FloatSize) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLayerPositionAtLastLayout(_ position: FloatPoint) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLeftOffset(offset: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setRightOffset(offset: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTopOffset(offset: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setBottomOffset(offset: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setConstrainingRectAtLastLayout(rect: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setContainingBlockRect(rect: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setStickyBoxRect(rect: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
