/*
 * Copyright (C) 2003, 2006, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2010 Google Inc. All rights reserved.
 * Copyright (C) 2013 Xidorn Quan (quanxunzhen@gmail.com)
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

struct RoundedRectRadii {
  func areRenderableInRect(rect: LayoutRectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func makeRenderableInRect(rect: LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func expand(size: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func scale(factor: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shrink(
    topWidth: LayoutUnit, bottomWidth: LayoutUnit, leftWidth: LayoutUnit, rightWidth: LayoutUnit
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var topLeft = LayoutSizeWrapper()
  var topRight = LayoutSizeWrapper()
  var bottomLeft = LayoutSizeWrapper()
  var bottomRight = LayoutSizeWrapper()
}

struct RoundedRect {
  typealias Radii = RoundedRectRadii

  init(rect: LayoutRectWrapper, radii: Radii = Radii()) {
    self.rect = rect
    self.radii = radii
  }

  func isRounded() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func move(size: LayoutSizeWrapper) { rect.move(size: size) }

  func inflateWithRadii(amount: LayoutUnit) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isRenderable() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func adjustRadii() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func contains(otherRect: LayoutRectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pixelSnappedRoundedRectForPainting(deviceScaleFactor: Float32) -> FloatRoundedRect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var rect = LayoutRectWrapper()
  var radii = Radii()
}
