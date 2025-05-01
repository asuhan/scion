/*
 * Copyright (C) 2003-2024 Apple Inc.  All rights reserved.
 * Copyright (C) 2005 Nokia.  All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL APPLE INC. OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

struct FloatRectWrapper {
  init() {}

  init(x: Float32, y: Float32, width: Float32, height: Float32) {
    self.m_location = FloatPoint(x: x, y: y)
    self.m_size = FloatSize(width: width, height: height)
  }

  init(location: FloatPoint, size: FloatSize) {
    self.m_location = location
    self.m_size = size
  }

  func location() -> FloatPoint { return m_location }

  func size() -> FloatSize { return m_size }

  func x() -> Float32 {
    return location().x
  }

  func y() -> Float32 {
    return location().y
  }

  func maxX() -> Float32 {
    return x() + width()
  }

  func maxY() -> Float32 {
    return y() + height()
  }

  func width() -> Float32 { return m_size.width }

  func height() -> Float32 { return m_size.height }

  mutating func setX(x: Float32) { m_location.setX(x: x) }

  mutating func setY(y: Float32) { m_location.setY(y: y) }

  mutating func setWidth(width: Float32) { m_size.setWidth(width: width) }

  mutating func setHeight(height: Float32) { m_size.setHeight(height: height) }

  func isEmpty() -> Bool { return m_size.isEmpty() }

  mutating func move(delta: FloatSize) { m_location += delta }

  mutating func moveBy(delta: FloatPoint) { m_location.move(dx: delta.x, dy: delta.y) }

  mutating func move(dx: Float32, dy: Float32) { m_location.move(dx: dx, dy: dy) }

  mutating func expand(size: FloatSize) { m_size += size }

  mutating func expand(dw: Float32, dh: Float32) { m_size.expand(width: dw, height: dh) }

  mutating func shiftXEdgeTo(edge: Float32) {
    let delta = edge - x()
    setX(x: edge)
    setWidth(width: max(0, width() - delta))
  }

  mutating func shiftMaxXEdgeTo(edge: Float32) {
    let delta = edge - maxX()
    setWidth(width: max(0, width() + delta))
  }

  mutating func shiftMaxYEdgeTo(edge: Float32) {
    let delta = edge - maxY()
    setHeight(height: max(0, height() + delta))
  }

  mutating func shiftXEdgeBy(delta: Float32) {
    move(dx: delta, dy: 0)
    setWidth(width: max(0, width() - delta))
  }

  mutating func shiftMaxXEdgeBy(delta: Float32) {
    shiftMaxXEdgeTo(edge: maxX() + delta)
  }

  func minXMinYCorner() -> FloatPoint { return m_location }

  func intersects(other: FloatRectWrapper) -> Bool {
    // Checking emptiness handles negative widths and heights as well as zero.
    return !isEmpty() && !other.isEmpty()
      && x() < other.maxX() && other.x() < maxX()
      && y() < other.maxY() && other.y() < maxY()
  }

  mutating func uniteEvenIfEmpty(other: FloatRectWrapper) {
    let minX = min(x(), other.x())
    let minY = min(y(), other.y())
    let maxX = max(maxX(), other.maxX())
    let maxY = max(maxY(), other.maxY())

    setLocationAndSizeFromEdges(left: minX, top: minY, right: maxX, bottom: maxY)
  }

  mutating func inflateX(dx: Float32) {
    m_location.setX(x: m_location.x - dx)
    m_size.setWidth(width: m_size.width + dx + dx)
  }

  mutating func inflateY(dy: Float32) {
    m_location.setY(y: m_location.y - dy)
    m_size.setHeight(height: m_size.height + dy + dy)
  }

  mutating func inflate(d: Float32) {
    inflateX(dx: d)
    inflateY(dy: d)
  }

  mutating func inflate(deltaX: Float32, deltaY: Float32, deltaMaxX: Float32, deltaMaxY: Float32) {
    setX(x: x() - deltaX)
    setY(y: y() - deltaY)
    setWidth(width: width() + deltaX + deltaMaxX)
    setHeight(height: height() + deltaY + deltaMaxY)
  }

  private mutating func setLocationAndSizeFromEdges(
    left: Float32, top: Float32, right: Float32, bottom: Float32
  ) {
    m_location.set(x: left, y: top)
    m_size.setWidth(width: right - left)
    m_size.setHeight(height: bottom - top)
  }

  private var m_location = FloatPoint()
  private var m_size = FloatSize()
}
