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

struct LayoutRectWrapper: Equatable {
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

  init(x: Float32, y: Float32, width: Float32, height: Float32) {
    self.init(
      location: LayoutPointWrapper(x: x, y: y),
      size: LayoutSizeWrapper(width: width, height: height))
  }

  init(topLeft: LayoutPointWrapper, bottomRight: LayoutPointWrapper) {
    self.m_location = topLeft
    self.m_size = LayoutSizeWrapper(
      width: bottomRight.x - topLeft.x, height: bottomRight.y - topLeft.y)
  }

  init(rect: IntRect) {
    self.init(
      location: LayoutPointWrapper(point: rect.location),
      size: LayoutSizeWrapper(size: rect.size))
  }

  init(r: FloatRectWrapper) {
    self.m_location = LayoutPointWrapper(size: r.location())
    self.m_size = LayoutSizeWrapper(size: r.size())
  }

  func location() -> LayoutPointWrapper { return m_location }

  func size() -> LayoutSizeWrapper { return m_size }

  mutating func setLocation(location: LayoutPointWrapper) { m_location = location }

  mutating func setSize(size: LayoutSizeWrapper) { m_size = size }

  func x() -> LayoutUnit { return m_location.x }

  func y() -> LayoutUnit { return m_location.y }

  func maxX() -> LayoutUnit { return x() + width() }

  func maxY() -> LayoutUnit { return y() + height() }

  func width() -> LayoutUnit { return m_size.width() }

  func height() -> LayoutUnit { return m_size.height() }

  mutating func setX(x: LayoutUnit) { m_location.setX(x: x) }

  mutating func setY(y: LayoutUnit) { m_location.setY(y: y) }

  func setWidth(width: LayoutUnit) { m_size.setWidth(width: width) }

  func setWidth(width: Float32) { m_size.setWidth(width: width) }

  func setWidth(width: Int32) { m_size.setWidth(width: width) }

  func setHeight(height: LayoutUnit) { m_size.setHeight(height: height) }

  func setHeight(height: Float32) { m_size.setHeight(height: height) }

  func isEmpty() -> Bool { return m_size.isEmpty() }

  // NOTE: The result is rounded to integer values, and thus may be not the exact
  // center point.
  func center() -> LayoutPointWrapper {
    return LayoutPointWrapper(x: x() + width() / 2, y: y() + height() / 2)
  }

  mutating func move(size: LayoutSizeWrapper) { m_location += size }

  mutating func moveBy(offset: LayoutPointWrapper) { m_location.move(dx: offset.x, dy: offset.y) }

  mutating func move(dx: LayoutUnit, dy: LayoutUnit) { m_location.move(dx: dx, dy: dy) }

  mutating func move(dx: Float32, dy: Float32) { m_location.move(dx: dx, dy: dy) }

  mutating func move(dx: Int32, dy: Int32) { m_location.move(dx: dx, dy: dy) }

  mutating func expand(size: LayoutSizeWrapper) { m_size += size }

  mutating func expand(dw: LayoutUnit, dh: LayoutUnit) { m_size.expand(width: dw, height: dh) }

  mutating func expand(box: LayoutBoxExtent) {
    m_location.move(dx: -box.left, dy: -box.top)
    m_size.expand(width: box.left + box.right, height: box.top + box.bottom)
  }

  mutating func expandToInfiniteY() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func expandToInfiniteX() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func shiftXEdgeBy(delta: LayoutUnit) {
    move(dx: delta, dy: LayoutUnit(value: 0))
    setWidth(width: max(LayoutUnit(value: 0), width() - delta))
  }

  mutating func shiftYEdgeBy(delta: LayoutUnit) {
    move(dx: LayoutUnit(value: 0), dy: delta)
    setHeight(height: max(LayoutUnit(value: 0), height() - delta))
  }

  mutating func contract(size: LayoutSizeWrapper) { m_size -= size }

  func contract(box: LayoutBoxExtent) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func contract(dw: LayoutUnit, dh: LayoutUnit) { m_size.expand(width: -dw, height: -dh) }

  func contract(dw: Int32, dh: Int32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func shiftXEdgeTo(edge: Float32) {
    shiftXEdgeTo(edge: LayoutUnit(value: edge))
  }

  mutating func shiftYEdgeTo(edge: Float32) {
    shiftYEdgeTo(edge: LayoutUnit(value: edge))
  }

  mutating func shiftXEdgeTo(edge: LayoutUnit) {
    let delta = edge - x()
    setX(x: edge)
    setWidth(width: max(LayoutUnit(value: 0), width() - delta))
  }

  mutating func shiftMaxXEdgeTo(edge: LayoutUnit) {
    let delta = edge - maxX()
    setWidth(width: max(LayoutUnit(value: 0), width() + delta))
  }

  mutating func shiftYEdgeTo(edge: LayoutUnit) {
    let delta = edge - y()
    setY(y: edge)
    setHeight(height: max(LayoutUnit(value: 0), height() - delta))
  }

  mutating func shiftMaxYEdgeTo(edge: LayoutUnit) {
    let delta = edge - maxY()
    setHeight(height: max(LayoutUnit(value: 0), height() + delta))
  }

  func minXMinYCorner() -> LayoutPointWrapper { return m_location }  // typically topLeft
  func maxXMinYCorner() -> LayoutPointWrapper {
    return LayoutPointWrapper(x: m_location.x + m_size.width(), y: m_location.y)
  }  // typically topRight
  func minXMaxYCorner() -> LayoutPointWrapper {
    return LayoutPointWrapper(x: m_location.x, y: m_location.y + m_size.height())
  }  // typically bottomLeft
  func maxXMaxYCorner() -> LayoutPointWrapper {
    return LayoutPointWrapper(x: m_location.x + m_size.width(), y: m_location.y + m_size.height())
  }  // typically bottomRight

  func intersects(other: LayoutRectWrapper) -> Bool {
    // Checking emptiness handles negative widths as well as zero.
    return !isEmpty() && !other.isEmpty()
      && x() < other.maxX() && other.x() < maxX()
      && y() < other.maxY() && other.y() < maxY()
  }

  func contains(other: LayoutRectWrapper) -> Bool {
    return x() <= other.x() && maxX() >= other.maxX() && y() <= other.y() && maxY() >= other.maxY()
  }

  // This checks to see if the rect contains x,y in the traditional sense.
  // Equivalent to checking if the rect contains a 1x1 rect below and to the right of (px,py).
  private func contains(px: LayoutUnit, py: LayoutUnit) -> Bool {
    return px >= x() && px < maxX() && py >= y() && py < maxY()
  }

  func contains(point: LayoutPointWrapper) -> Bool { return contains(px: point.x, py: point.y) }

  mutating func intersect(other: LayoutRectWrapper) {
    var newLocation = LayoutPointWrapper(x: max(x(), other.x()), y: max(y(), other.y()))
    var newMaxPoint = LayoutPointWrapper(x: min(maxX(), other.maxX()), y: min(maxY(), other.maxY()))

    // Return a clean empty rectangle for non-intersecting cases.
    if newLocation.x >= newMaxPoint.x || newLocation.y >= newMaxPoint.y {
      newLocation = LayoutPointWrapper(x: 0, y: 0)
      newMaxPoint = LayoutPointWrapper(x: 0, y: 0)
    }

    m_location = newLocation
    m_size = newMaxPoint - newLocation
  }

  func edgeInclusiveIntersect(_ other: LayoutRectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func unite(other: LayoutRectWrapper) {
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

  mutating func uniteEvenIfEmpty(other: LayoutRectWrapper) {
    let minX = min(x(), other.x())
    let minY = min(y(), other.y())
    let maxX = max(maxX(), other.maxX())
    let maxY = max(maxY(), other.maxY())

    setLocationAndSizeFromEdges(left: minX, top: minY, right: maxX, bottom: maxY)
  }

  mutating func uniteIfNonZero(_ other: LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  mutating func checkedUnite(other: LayoutRectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func inflateX(dx: LayoutUnit) {
    m_location.setX(x: m_location.x - dx)
    m_size.setWidth(width: m_size.width() + dx + dx)
  }

  mutating func inflateY(dy: LayoutUnit) {
    m_location.setY(y: m_location.y - dy)
    m_size.setHeight(height: m_size.height() + dy + dy)
  }

  mutating func inflateX(dx: Float32) {
    inflateX(dx: LayoutUnit(value: dx))
  }

  mutating func inflateY(dy: Float32) {
    inflateY(dy: LayoutUnit(value: dy))
  }

  mutating func inflate(d: LayoutUnit) {
    inflateX(dx: d)
    inflateY(dy: d)
  }

  mutating func inflate(d: Float32) {
    inflateX(dx: d)
    inflateY(dy: d)
  }

  mutating func scale(_ scaleValue: Float32) {
    scale(xScale: scaleValue, yScale: scaleValue)
  }

  mutating func scale(xScale: Float32, yScale: Float32) {
    if isInfinite() {
      return
    }
    m_location.scale(sx: xScale, sy: yScale)
    m_size.scale(widthScale: xScale, heightScale: yScale)
  }

  func transposedRect() -> LayoutRectWrapper {
    return LayoutRectWrapper(location: m_location.transposedPoint(), size: m_size.transposedSize())
  }

  func isInfinite() -> Bool {
    return self == LayoutRectWrapper.infiniteRect()
  }

  static func infiniteRect() -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func FloatRect() -> FloatRectWrapper {
    return FloatRectWrapper(location: m_location.FloatPoint(), size: m_size.FloatSize())
  }

  static func == (lhs: LayoutRectWrapper, rhs: LayoutRectWrapper) -> Bool {
    return lhs.m_location == rhs.m_location && lhs.m_size == rhs.m_size
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

func intersection(a: LayoutRectWrapper, b: LayoutRectWrapper) -> LayoutRectWrapper {
  var c = a
  c.intersect(other: b)
  return c
}

func unionRect(a: LayoutRectWrapper, b: LayoutRectWrapper) -> LayoutRectWrapper {
  var c = a
  c.unite(other: b)
  return c
}

// Integral snapping functions.
func snappedIntRect(rect: LayoutRectWrapper) -> IntRect {
  return IntRect(
    location: roundedIntPoint(point: rect.location()),
    size: snappedIntSize(rect.size(), rect.location()))
}

func snappedIntRect(left: LayoutUnit, top: LayoutUnit, width: LayoutUnit, height: LayoutUnit)
  -> IntRect
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func enclosingIntRect(rect: LayoutRectWrapper) -> IntRect {
  // Empty rects with fractional x, y values turn into non-empty rects when converting to enclosing.
  // We need to ensure that empty rects stay empty after the conversion, because the selection code expects them to be empty.
  let location = flooredIntPoint(point: rect.minXMinYCorner())
  let maxPoint = IntPoint(
    x: rect.width().bool() ? rect.maxX().ceil() : location.x,
    y: rect.height().bool() ? rect.maxY().ceil() : location.y)
  return IntRect(location: location, size: maxPoint - location)
}

func enclosingLayoutRect(rect: FloatRectWrapper) -> LayoutRectWrapper {
  let location = flooredLayoutPoint(p: rect.minXMinYCorner())
  let maxPoint = ceiledLayoutPoint(p: rect.maxXMaxYCorner())

  return LayoutRectWrapper(location: location, size: maxPoint - location)
}

func encloseRectToDevicePixels(rect: LayoutRectWrapper, pixelSnappingFactor: Float32)
  -> FloatRectWrapper
{
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

// Device pixel snapping functions.
func snapRectToDevicePixels(rect: LayoutRectWrapper, pixelSnappingFactor: Float32)
  -> FloatRectWrapper
{
  return FloatRectWrapper(
    location: FloatPoint(
      x: roundToDevicePixel(value: rect.x(), pixelSnappingFactor: pixelSnappingFactor),
      y: roundToDevicePixel(value: rect.y(), pixelSnappingFactor: pixelSnappingFactor)),
    size: snapSizeToDevicePixel(
      size: rect.size(), location: rect.location(), pixelSnappingFactor: pixelSnappingFactor))
}

// FIXME: This needs to take vertical centering into account too.
func snapRectToDevicePixelsWithWritingDirection(
  rect: LayoutRectWrapper, deviceScaleFactor: Float32, ltr: Bool
) -> FloatRectWrapper {
  if !ltr {
    let snappedTopRight = roundPointToDevicePixels(
      point: rect.maxXMinYCorner(), pixelSnappingFactor: deviceScaleFactor,
      directionalRoundingToRight: ltr)
    let snappedSize = snapSizeToDevicePixel(
      size: rect.size(), location: rect.maxXMinYCorner(), pixelSnappingFactor: deviceScaleFactor)
    return FloatRectWrapper(
      x: snappedTopRight.x - snappedSize.width, y: snappedTopRight.y,
      width: snappedSize.width,
      height: snappedSize.height)
  }
  return snapRectToDevicePixels(rect: rect, pixelSnappingFactor: deviceScaleFactor)
}
