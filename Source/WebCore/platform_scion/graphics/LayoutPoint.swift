/*
 * Copyright (c) 2012-2013, Google Inc. All rights reserved.
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

struct LayoutPointWrapper: Equatable {
  init() {}

  init(x: LayoutUnit, y: LayoutUnit) {
    self.x = x
    self.y = y
  }

  init(point: IntPoint) {
    self.x = LayoutUnit(value: point.x)
    self.y = LayoutUnit(value: point.y)
  }

  init(x: Float32, y: Float32) {
    self.x = LayoutUnit(value: x)
    self.y = LayoutUnit(value: y)
  }

  init(size: FloatPoint) {
    self.x = LayoutUnit(value: size.x)
    self.y = LayoutUnit(value: size.y)
  }

  var x = LayoutUnit()
  var y = LayoutUnit()

  mutating func setX(x: LayoutUnit) {
    self.x = x
  }

  mutating func setY(y: LayoutUnit) {
    self.y = y
  }

  mutating func move(s: LayoutSizeWrapper) {
    move(dx: s.width(), dy: s.height())
  }

  mutating func moveBy(offset: LayoutPointWrapper) {
    move(dx: offset.x, dy: offset.y)
  }

  mutating func move(dx: LayoutUnit, dy: LayoutUnit) {
    x += dx
    y += dy
  }

  mutating func move(dx: Float32, dy: Float32) {
    x += dx
    y += dy
  }

  func transposedPoint() -> LayoutPointWrapper {
    return LayoutPointWrapper(x: y, y: x)
  }

  func FloatPoint() -> FloatPoint { return layout_scion.FloatPoint(x: x.float(), y: y.float()) }

  @discardableResult
  static func += (a: inout LayoutPointWrapper, b: LayoutSizeWrapper) -> LayoutPointWrapper {
    a.move(dx: b.width(), dy: b.height())
    return a
  }

  static func + (a: LayoutPointWrapper, b: LayoutSizeWrapper) -> LayoutPointWrapper {
    return LayoutPointWrapper(x: a.x + b.width(), y: a.y + b.height())
  }

  static func + (a: LayoutPointWrapper, b: LayoutPointWrapper) -> LayoutPointWrapper {
    return LayoutPointWrapper(x: a.x + b.x, y: a.y + b.y)
  }

  static func - (a: LayoutPointWrapper, b: LayoutPointWrapper) -> LayoutSizeWrapper {
    return LayoutSizeWrapper(width: a.x - b.x, height: a.y - b.y)
  }

  static func - (a: LayoutPointWrapper, b: LayoutSizeWrapper) -> LayoutPointWrapper {
    return LayoutPointWrapper(x: a.x - b.width(), y: a.y - b.height())
  }

  prefix static func - (point: LayoutPointWrapper) -> LayoutPointWrapper {
    return LayoutPointWrapper(x: -point.x, y: -point.y)
  }
}

func toLayoutPoint(size: LayoutSizeWrapper) -> LayoutPointWrapper {
  return LayoutPointWrapper(x: size.width(), y: size.height())
}

func toLayoutSize(point: LayoutPointWrapper) -> LayoutSizeWrapper {
  return LayoutSizeWrapper(width: point.x, height: point.y)
}

func flooredIntPoint(point: LayoutPointWrapper) -> IntPoint {
  return IntPoint(x: Int32(point.x.floor()), y: Int32(point.y.floor()))
}

func roundedIntPoint(point: LayoutPointWrapper) -> IntPoint {
  return IntPoint(x: Int32(point.x.round()), y: Int32(point.y.round()))
}

func flooredLayoutPoint(p: FloatPoint) -> LayoutPointWrapper {
  return LayoutPointWrapper(
    x: LayoutUnit.fromFloatFloor(value: p.x), y: LayoutUnit.fromFloatFloor(value: p.y))
}

func ceiledLayoutPoint(p: FloatPoint) -> LayoutPointWrapper {
  return LayoutPointWrapper(
    x: LayoutUnit.fromFloatCeil(value: p.x), y: LayoutUnit.fromFloatCeil(value: p.y))
}

func roundPointToDevicePixels(
  point: LayoutPointWrapper, pixelSnappingFactor: Float32, directionalRoundingToRight: Bool = true,
  directionalRoundingToBottom: Bool = true
) -> FloatPoint {
  return FloatPoint(
    x: roundToDevicePixel(
      value: point.x, pixelSnappingFactor: pixelSnappingFactor,
      needsDirectionalRounding: !directionalRoundingToRight),
    y: roundToDevicePixel(
      value: point.y, pixelSnappingFactor: pixelSnappingFactor,
      needsDirectionalRounding: !directionalRoundingToBottom))
}
