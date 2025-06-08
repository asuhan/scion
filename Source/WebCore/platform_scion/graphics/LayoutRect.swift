/*
 * Copyright (c) 2012, Google Inc. All rights reserved.
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

struct LayoutRectWrapper {
  init() {}

  init(location: LayoutPointWrapper, size: LayoutSizeWrapper) {
    self.m_location = location
    self.m_size = size
  }

  init(x: LayoutUnit, y: LayoutUnit, width: LayoutUnit, height: LayoutUnit) {
    self.init(
      location: LayoutPointWrapper(x: x, y: y),
      size: LayoutSizeWrapper(width: width, height: height))
  }

  init(r: FloatRectWrapper) {
    self.m_location = LayoutPointWrapper(size: r.location())
    self.m_size = LayoutSizeWrapper(size: r.size())
  }

  func location() -> LayoutPointWrapper { return m_location }

  func size() -> LayoutSizeWrapper { return m_size }

  func x() -> LayoutUnit { return m_location.x }

  func y() -> LayoutUnit { return m_location.y }

  func maxX() -> LayoutUnit { return x() + width() }

  func maxY() -> LayoutUnit { return y() + height() }

  func width() -> LayoutUnit { return m_size.width() }

  func height() -> LayoutUnit { return m_size.height() }

  func setX<T>(x: T) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setWidth(width: LayoutUnit) { m_size.setWidth(width: width) }

  func isEmpty() -> Bool { return m_size.isEmpty() }

  mutating func move(size: LayoutSizeWrapper) { m_location += size }

  mutating func moveBy(offset: LayoutPointWrapper) { m_location.move(dx: offset.x, dy: offset.y) }

  mutating func move(dx: LayoutUnit, dy: LayoutUnit) { m_location.move(dx: dx, dy: dy) }

  mutating func move(dx: Float32, dy: Float32) { m_location.move(dx: dx, dy: dy) }

  mutating func expand(dw: LayoutUnit, dh: LayoutUnit) { m_size.expand(width: dw, height: dh) }

  func minXMinYCorner() -> LayoutPointWrapper { return m_location }

  func unite(other: LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func uniteEvenIfEmpty(other: LayoutRectWrapper) {
    let minX = min(x(), other.x())
    let minY = min(y(), other.y())
    let maxX = max(maxX(), other.maxX())
    let maxY = max(maxY(), other.maxY())

    setLocationAndSizeFromEdges(left: minX, top: minY, right: maxX, bottom: maxY)
  }

  func transposedRect() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func FloatRect() -> FloatRectWrapper {
    return FloatRectWrapper(location: m_location.FloatPoint(), size: m_size.FloatSize())
  }

  private mutating func setLocationAndSizeFromEdges(
    left: LayoutUnit, top: LayoutUnit, right: LayoutUnit, bottom: LayoutUnit
  ) {
    m_location = LayoutPointWrapper(x: left, y: top)
    m_size.setWidth(width: right - left)
    m_size.setHeight(height: bottom - top)
  }

  private var m_location = LayoutPointWrapper()
  private var m_size = LayoutSizeWrapper()
}
