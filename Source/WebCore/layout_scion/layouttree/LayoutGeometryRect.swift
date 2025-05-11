/*
 * Copyright (C) 2019 Apple Inc. All rights reserved.
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

struct Rect {
  init(top: LayoutUnit, left: LayoutUnit, width: LayoutUnit, height: LayoutUnit) {
    self.rect = LayoutRectWrapper(x: left, y: top, width: width, height: height)
    hasValidTop = true
    hasValidLeft = true
    hasValidWidth = true
    hasValidHeight = true
  }

  init(topLeft: LayoutPointWrapper, size: LayoutSizeWrapper) {
    self.init(top: topLeft.y, left: topLeft.x, width: size.width(), height: size.height())
  }

  func top() -> LayoutUnit {
    assert(hasValidTop)
    return rect.y()
  }

  func left() -> LayoutUnit {
    assert(hasValidLeft)
    return rect.x()
  }

  func topLeft() -> LayoutPointWrapper {
    assert(hasValidPosition())
    return rect.minXMinYCorner()
  }

  func bottom() -> LayoutUnit {
    assert(hasValidTop && hasValidHeight)
    return rect.maxY()
  }

  func right() -> LayoutUnit {
    assert(hasValidLeft && hasValidWidth)
    return rect.maxX()
  }

  func height() -> LayoutUnit {
    assert(hasValidHeight)
    return rect.height()
  }

  func width() -> LayoutUnit {
    assert(hasValidWidth)
    return rect.width()
  }

  func size() -> LayoutSizeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func setWidth(width: LayoutUnit) {
    hasValidWidth = true
    rect.setWidth(width: width)
  }

  mutating func expandToContain(rect: Rect) {
    assert(hasValidWidth)
    assert(hasValidHeight)
    self.rect.uniteEvenIfEmpty(other: rect.LayoutRect())
  }

  func isEmpty() -> Bool { return rect.isEmpty() }

  func LayoutRect() -> LayoutRectWrapper {
    assert(hasValidGeometry())
    return rect
  }

  func FloatRect() -> FloatRectWrapper {
    assert(hasValidGeometry())
    return rect.FloatRect()
  }

  private func hasValidPosition() -> Bool { return hasValidTop && hasValidLeft }

  private func hasValidSize() -> Bool { return hasValidWidth && hasValidHeight }

  private func hasValidGeometry() -> Bool { return hasValidPosition() && hasValidSize() }

  private var rect = LayoutRectWrapper()
  private var hasValidTop = false
  private var hasValidLeft = false
  private var hasValidWidth = false
  private var hasValidHeight = false
}
