/*
 * Copyright (C) 2004-2016 Apple Inc.  All rights reserved.
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

import Foundation

struct FloatPoint {
  init() {}

  init(x: Float32, y: Float32) {
    self.x = x
    self.y = y
  }

  init(p: IntPoint) {
    self.x = Float32(p.x)
    self.y = Float32(p.y)
  }

  init(_ size: FloatSize) {
    x = size.width
    y = size.height
  }

  static func zero() -> FloatPoint { return FloatPoint() }

  func isZero() -> Bool { return x == 0 && y == 0 }

  mutating func setX(x: Float32) { self.x = x }

  mutating func setY(y: Float32) { self.y = y }

  mutating func set(x: Float32, y: Float32) {
    self.x = x
    self.y = y
  }

  mutating func move(dx: Float32, dy: Float32) {
    x += dx
    y += dy
  }

  mutating func move(_ a: FloatSize) {
    x += a.width
    y += a.height
  }

  mutating func moveBy(a: FloatPoint) {
    x += a.x
    y += a.y
  }

  mutating func scale(_ scale: Float32) {
    x *= scale
    y *= scale
  }

  mutating func scale(scaleX: Float32, scaleY: Float32) {
    x *= scaleX
    y *= scaleY
  }

  func slopeAngleRadians() -> Float32 {
    return atan2f(y, x)
  }

  func lengthSquared() -> Float32 {
    return x * x + y * y
  }

  func transposedPoint() -> FloatPoint {
    return FloatPoint(x: y, y: x)
  }

  @discardableResult
  static func += (a: inout FloatPoint, b: FloatSize) -> FloatPoint {
    a.move(dx: b.width, dy: b.height)
    return a
  }

  @discardableResult
  static func += (a: inout FloatPoint, b: FloatPoint) -> FloatPoint {
    a.move(dx: b.x, dy: b.y)
    return a
  }

  static func + (a: FloatPoint, b: FloatPoint) -> FloatPoint {
    return FloatPoint(x: a.x + b.x, y: a.y + b.y)
  }

  static func + (a: FloatPoint, b: FloatSize) -> FloatPoint {
    return FloatPoint(x: a.x + b.width, y: a.y + b.height)
  }

  static func - (a: FloatPoint, b: FloatPoint) -> FloatSize {
    return FloatSize(width: a.x - b.x, height: a.y - b.y)
  }

  static func - (a: FloatPoint, b: FloatSize) -> FloatPoint {
    return FloatPoint(x: a.x - b.width, y: a.y - b.height)
  }

  prefix static func - (a: FloatPoint) -> FloatPoint {
    return FloatPoint(x: -a.x, y: -a.y)
  }

  static func == (lhs: FloatPoint, rhs: FloatPoint) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
  }

  var x: Float32 = 0
  var y: Float32 = 0
}

func roundedIntPoint(_ p: FloatPoint) -> IntPoint {
  return IntPoint(x: clampToInteger(value: roundf(p.x)), y: clampToInteger(value: roundf(p.y)))
}

func flooredIntPoint(_ p: FloatPoint) -> IntPoint {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func toFloatSize(a: FloatPoint) -> FloatSize {
  return FloatSize(width: a.x, height: a.y)
}
