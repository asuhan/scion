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

struct InlineRect {
  init() {}

  init(
    top: InlineLayoutUnit, left: InlineLayoutUnit, width: InlineLayoutUnit, height: InlineLayoutUnit
  ) {
    self.rect = layout_scion.InlineLayoutRect(x: left, y: top, width: width, height: height)
    hasValidTop = true
    hasValidLeft = true
    hasValidWidth = true
    hasValidHeight = true
  }

  init(topLeft: InlineLayoutPoint, width: InlineLayoutUnit, height: InlineLayoutUnit) {
    self.init(top: topLeft.y, left: topLeft.x, width: width, height: height)
  }

  init(topLeft: InlineLayoutPoint, size: InlineLayoutSize) {
    self.init(top: topLeft.y, left: topLeft.x, width: size.width, height: size.height)
  }

  init(rect: FloatRectWrapper) {
    self.init(top: rect.y(), left: rect.x(), width: rect.width(), height: rect.height())
  }

  func top() -> InlineLayoutUnit {
    assert(hasValidTop)
    return rect!.y()
  }

  func left() -> InlineLayoutUnit {
    assert(hasValidLeft)
    return rect!.x()
  }

  func topLeft() -> InlineLayoutPoint {
    assert(hasValidPosition())
    return rect!.minXMinYCorner()
  }

  func bottom() -> InlineLayoutUnit {
    assert(hasValidTop && hasValidHeight)
    return rect!.maxY()
  }

  func right() -> InlineLayoutUnit {
    assert(hasValidLeft && hasValidWidth)
    return rect!.maxX()
  }

  func width() -> InlineLayoutUnit {
    assert(hasValidWidth)
    return rect!.width()
  }

  func height() -> InlineLayoutUnit {
    assert(hasValidHeight)
    return rect!.height()
  }

  func size() -> InlineLayoutSize {
    assert(hasValidSize())
    return rect!.size()
  }

  mutating func setTop(top: InlineLayoutUnit) {
    hasValidTop = true
    rect!.setY(y: top)
  }

  mutating func setBottom(bottom: InlineLayoutUnit) {
    hasValidTop = true
    hasValidHeight = true
    rect!.shiftMaxYEdgeTo(edge: bottom)
  }

  mutating func setLeft(left: InlineLayoutUnit) {
    hasValidLeft = true
    rect!.setX(x: left)
  }

  mutating func setRight(right: InlineLayoutUnit) {
    hasValidLeft = true
    hasValidWidth = true
    rect!.shiftMaxXEdgeTo(edge: right)
  }

  mutating func setWidth(width: InlineLayoutUnit) {
    hasValidWidth = true
    rect!.setWidth(width: width)
  }

  mutating func setHeight(height: InlineLayoutUnit) {
    hasValidHeight = true
    rect!.setHeight(height: height)
  }

  mutating func moveHorizontally(offset: InlineLayoutUnit) {
    assert(hasValidLeft)
    rect!.move(delta: InlineLayoutSize(width: offset, height: 0))
  }

  mutating func moveVertically(offset: InlineLayoutUnit) {
    assert(hasValidTop)
    rect!.move(delta: InlineLayoutSize(width: 0, height: offset))
  }

  mutating func moveBy(offset: InlineLayoutPoint) {
    assert(hasValidTop)
    assert(hasValidLeft)
    rect!.moveBy(delta: offset)
  }

  mutating func shiftLeftTo(left: InlineLayoutUnit) {
    assert(hasValidLeft)
    rect!.shiftXEdgeTo(edge: left)
  }

  mutating func shiftLeftBy(offset: InlineLayoutUnit) {
    assert(hasValidLeft)
    rect!.shiftXEdgeBy(delta: offset)
  }

  mutating func shiftRightBy(offset: InlineLayoutUnit) {
    assert(hasValidLeft && hasValidWidth)
    rect!.shiftMaxXEdgeBy(delta: offset)
  }

  mutating func expandToContain(other: InlineRect) {
    hasValidTop = true
    hasValidLeft = true
    hasValidWidth = true
    hasValidHeight = true
    rect!.uniteEvenIfEmpty(other: other.InlineLayoutRect())
  }

  mutating func expand(width: InlineLayoutUnit?, height: InlineLayoutUnit?) {
    assert(width == nil || hasValidWidth)
    assert(height == nil || hasValidHeight)
    rect!.expand(dw: width ?? 0, dh: height ?? 0)
  }

  mutating func expandHorizontally(delta: InlineLayoutUnit) { expand(width: delta, height: nil) }

  mutating func expandVertically(delta: InlineLayoutUnit) { expand(width: nil, height: delta) }

  mutating func expandVerticallyToContain(other: InlineRect) {
    let containTop = min(top(), other.top())
    let containBottom = max(bottom(), other.bottom())
    setTop(top: containTop)
    setBottom(bottom: containBottom)
  }

  mutating func inflate(inflate: InlineLayoutUnit) {
    assert(hasValidGeometry())
    rect!.inflate(d: inflate)
  }

  mutating func inflate(
    top: InlineLayoutUnit, right: InlineLayoutUnit, bottom: InlineLayoutUnit, left: InlineLayoutUnit
  ) {
    assert(hasValidGeometry())
    rect!.setX(x: rect!.x() - left)
    rect!.setY(y: rect!.y() - top)
    rect!.setWidth(width: rect!.width() + left + right)
    rect!.setHeight(height: rect!.height() + top + bottom)
  }

  func intersects(other: InlineRect) -> Bool {
    return rect!.intersects(other: other.InlineLayoutRect())
  }

  func isEmpty() -> Bool {
    assert(hasValidGeometry())
    return rect!.isEmpty()
  }

  func InlineLayoutRect() -> InlineLayoutRect { return rect! }

  func hasValidPosition() -> Bool { return hasValidTop && hasValidLeft }

  func hasValidSize() -> Bool { return hasValidWidth && hasValidHeight }

  func hasValidGeometry() -> Bool { return hasValidPosition() && hasValidSize() }

  private var hasValidTop = false
  private var hasValidLeft = false
  private var hasValidWidth = false
  private var hasValidHeight = false
  private var rect: InlineLayoutRect? = nil
}
