/*
 * Copyright (C) 2003, 2006, 2009 Apple Inc. All rights reserved.
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

struct IntRect: Equatable {
  init() {
    location = IntPoint()
    size = IntSize()
  }

  init(location: IntPoint, size: IntSize) {
    self.location = location
    self.size = size
  }

  init(x: Int32, y: Int32, width: Int32, height: Int32) {
    self.location = IntPoint(x: x, y: y)
    self.size = IntSize(width: width, height: height)
  }

  init(_ r: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func x() -> Int32 { return location.x }
  func y() -> Int32 { return location.y }
  func maxX() -> Int32 { return x() + width() }
  func maxY() -> Int32 { return y() + height() }
  func width() -> Int32 { return size.width }
  func height() -> Int32 { return size.height }

  func area() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private mutating func setX(x: Int32) { location.x = x }
  private mutating func setY(y: Int32) { location.y = y }
  mutating func setWidth(width: Int32) { size.width = width }
  private mutating func setHeight(height: Int32) { size.height = height }

  func isEmpty() -> Bool { return size.isEmpty() }

  mutating func move(_ size: IntSize) { location += size }

  mutating func moveBy(offset: IntPoint) {
    location.move(dx: offset.x, dy: offset.y)
  }

  mutating func contract(dw: Int32, dh: Int32) {
    size.expand(width: -dw, height: -dh)
  }

  mutating func shiftXEdgeTo(_ edge: Int32) {
    let delta = edge - x()
    setX(x: edge)
    setWidth(width: max(0, width() - delta))
  }

  mutating func shiftYEdgeTo(_ edge: Int32) {
    let delta = edge - y()
    setY(y: edge)
    setHeight(height: max(0, height() - delta))
  }

  func minXMaxYCorner() -> IntPoint {
    return IntPoint(x: location.x, y: location.y + size.height)
  }  // typically bottomLeft

  func maxXMaxYCorner() -> IntPoint {
    return IntPoint(x: location.x + size.width, y: location.y + size.height)
  }  // typically bottomRight

  func intersects(other: IntRect) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func unite(_ other: IntRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var location: IntPoint
  var size: IntSize
}

func intersection(a: IntRect, b: IntRect) -> IntRect {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
