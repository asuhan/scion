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
  init() {}

  init(top: LayoutUnit, left: LayoutUnit, width: LayoutUnit, height: LayoutUnit) {
    self.rect = LayoutRectWrapper(x: left, y: top, width: width, height: height)
    #if ASSERT_ENABLED
      hasValidTop = true
      hasValidLeft = true
      hasValidWidth = true
      hasValidHeight = true
    #endif  // ASSERT_ENABLED
  }

  init(topLeft: LayoutPointWrapper, size: LayoutSizeWrapper) {
    self.init(top: topLeft.y, left: topLeft.x, width: size.width(), height: size.height())
  }

  func top() -> LayoutUnit {
    #if ASSERT_ENABLED
      assert(hasValidTop)
    #endif  // ASSERT_ENABLED
    return rect.y()
  }

  func left() -> LayoutUnit {
    #if ASSERT_ENABLED
      assert(hasValidLeft)
    #endif  // ASSERT_ENABLED
    return rect.x()
  }

  func topLeft() -> LayoutPointWrapper {
    #if ASSERT_ENABLED
      assert(hasValidPosition())
    #endif  // ASSERT_ENABLED
    return rect.minXMinYCorner()
  }

  func bottom() -> LayoutUnit {
    #if ASSERT_ENABLED
      assert(hasValidTop && hasValidHeight)
    #endif  // ASSERT_ENABLED
    return rect.maxY()
  }

  func right() -> LayoutUnit {
    #if ASSERT_ENABLED
      assert(hasValidLeft && hasValidWidth)
    #endif  // ASSERT_ENABLED
    return rect.maxX()
  }

  func height() -> LayoutUnit {
    #if ASSERT_ENABLED
      assert(hasValidHeight)
    #endif  // ASSERT_ENABLED
    return rect.height()
  }

  func width() -> LayoutUnit {
    #if ASSERT_ENABLED
      assert(hasValidWidth)
    #endif  // ASSERT_ENABLED
    return rect.width()
  }

  func size() -> LayoutSizeWrapper {
    #if ASSERT_ENABLED
      assert(hasValidSize())
    #endif  // ASSERT_ENABLED
    return rect.size()
  }

  mutating func setTopLeft(_ topLeft: LayoutPointWrapper) {
    #if ASSERT_ENABLED
      setHasValidPosition()
    #endif  // ASSERT_ENABLED
    rect.setLocation(location: topLeft)
  }

  mutating func setWidth(width: LayoutUnit) {
    #if ASSERT_ENABLED
      hasValidWidth = true
    #endif  // ASSERT_ENABLED
    rect.setWidth(width: width)
  }

  mutating func setSize(_ size: LayoutSizeWrapper) {
    #if ASSERT_ENABLED
      setHasValidSize()
    #endif  // ASSERT_ENABLED
    rect.setSize(size: size)
  }

  mutating func expandToContain(rect: Rect) {
    #if ASSERT_ENABLED
      assert(hasValidWidth)
      assert(hasValidHeight)
    #endif  // ASSERT_ENABLED
    self.rect.uniteEvenIfEmpty(other: rect.LayoutRect())
  }

  func isEmpty() -> Bool { return rect.isEmpty() }

  func LayoutRect() -> LayoutRectWrapper {
    #if ASSERT_ENABLED
      assert(hasValidGeometry())
    #endif  // ASSERT_ENABLED
    return rect
  }

  func FloatRect() -> FloatRectWrapper {
    #if ASSERT_ENABLED
      assert(hasValidGeometry())
    #endif  // ASSERT_ENABLED
    return rect.FloatRect()
  }

  #if ASSERT_ENABLED
    private func hasValidPosition() -> Bool { return hasValidTop && hasValidLeft }

    private func hasValidSize() -> Bool { return hasValidWidth && hasValidHeight }

    private func hasValidGeometry() -> Bool { return hasValidPosition() && hasValidSize() }

    private mutating func setHasValidPosition() {
      hasValidTop = true
      hasValidLeft = true
    }

    private mutating func setHasValidSize() {
      hasValidWidth = true
      hasValidHeight = true
    }

    private var hasValidTop = false
    private var hasValidLeft = false
    private var hasValidWidth = false
    private var hasValidHeight = false
  #endif  // ASSERT_ENABLED
  private var rect = LayoutRectWrapper()
}
