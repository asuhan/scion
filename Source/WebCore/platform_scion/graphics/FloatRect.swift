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

struct FloatRectWrapper: Equatable {
  enum ContainsMode {
    case InsideOrOnStroke
    case InsideButNotOnStroke
  }

  init() {}

  init(x: Float32, y: Float32, width: Float32, height: Float32) {
    self.m_location = FloatPoint(x: x, y: y)
    self.m_size = FloatSize(width: width, height: height)
  }

  init(location: FloatPoint, size: FloatSize) {
    self.m_location = location
    self.m_size = size
  }

  init(topLeft: FloatPoint, bottomRight: FloatPoint) {
    self.m_location = topLeft
    self.m_size = FloatSize(
      width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y)
  }

  init(r: IntRect) {
    self.m_location = FloatPoint(p: r.location)
    self.m_size = FloatSize(size: r.size)
  }

  func location() -> FloatPoint { return m_location }

  func size() -> FloatSize { return m_size }

  mutating func setLocation(location: FloatPoint) { m_location = location }
  mutating func setSize(_ size: FloatSize) { m_size = size }

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

  func center() -> FloatPoint { return location() + size() / 2 }

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

  mutating func shiftYEdgeBy(delta: Float32) {
    move(dx: 0, dy: delta)
    setHeight(height: max(0, height() - delta))
  }

  mutating func shiftMaxYEdgeBy(delta: Float32) {
    shiftMaxYEdgeTo(edge: maxY() + delta)
  }

  func minXMinYCorner() -> FloatPoint { return m_location }  // typically topLeft

  func maxXMinYCorner() -> FloatPoint {
    return FloatPoint(x: m_location.x + m_size.width, y: m_location.y)
  }  // typically topRight

  func minXMaxYCorner() -> FloatPoint {
    return FloatPoint(x: m_location.x, y: m_location.y + m_size.height)
  }  // typically bottomLeft

  func maxXMaxYCorner() -> FloatPoint {
    return FloatPoint(x: m_location.x + m_size.width, y: m_location.y + m_size.height)
  }  // typically bottomRight

  func intersects(other: FloatRectWrapper) -> Bool {
    // Checking emptiness handles negative widths and heights as well as zero.
    return !isEmpty() && !other.isEmpty()
      && x() < other.maxX() && other.x() < maxX()
      && y() < other.maxY() && other.y() < maxY()
  }

  func contains(_ other: FloatRectWrapper) -> Bool {
    return x() <= other.x() && maxX() >= other.maxX() && y() <= other.y() && maxY() >= other.maxY()
  }

  func contains(_ point: FloatPoint, _ containsMode: ContainsMode = .InsideOrOnStroke) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func intersect(other: FloatRectWrapper) {
    var l = max(x(), other.x())
    var t = max(y(), other.y())
    var r = min(maxX(), other.maxX())
    var b = min(maxY(), other.maxY())

    // Return a clean empty rectangle for non-intersecting cases.
    if l >= r || t >= b {
      l = 0
      t = 0
      r = 0
      b = 0
    }

    setLocationAndSizeFromEdges(left: l, top: t, right: r, bottom: b)
  }

  mutating func unite(other: FloatRectWrapper) {
    // Handle empty special cases first.
    if other.isEmpty() {
      return
    }
    if isEmpty() {
      self = other
      return
    }

    uniteEvenIfEmpty(other: other)
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

  mutating func inflate(size: FloatSize) {
    inflateX(dx: size.width)
    inflateY(dy: size.height)
  }

  mutating func inflate(deltaX: Float32, deltaY: Float32, deltaMaxX: Float32, deltaMaxY: Float32) {
    setX(x: x() - deltaX)
    setY(y: y() - deltaY)
    setWidth(width: width() + deltaX + deltaMaxX)
    setHeight(height: height() + deltaY + deltaMaxY)
  }

  func transposedRect() -> FloatRectWrapper {
    return FloatRectWrapper(location: m_location.transposedPoint(), size: m_size.transposedSize())
  }

  static func == (lhs: FloatRectWrapper, rhs: FloatRectWrapper) -> Bool {
    return lhs.m_location == rhs.m_location && lhs.m_size == rhs.m_size
  }

  static func != (lhs: FloatRectWrapper, rhs: FloatRectWrapper) -> Bool {
    return !(lhs == rhs)
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

func intersection(_ a: FloatRectWrapper, _ b: FloatRectWrapper) -> FloatRectWrapper {
  var c = a
  c.intersect(other: b)
  return c
}

func enclosingIntRect(rect: FloatRectWrapper) -> IntRect {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
