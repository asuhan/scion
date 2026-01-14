/*
 * Copyright (C) 2004-2016 Apple Inc.  All rights reserved.
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

struct IntPoint {
  init() {
    x = 0
    y = 0
  }

  init(x: Int32, y: Int32) {
    self.x = x
    self.y = y
  }

  func isZero() -> Bool { return x == 0 && y == 0 }

  mutating func move(dx: Int32, dy: Int32) {
    x += dx
    y += dy
  }

  mutating func scale(sx: Float32, sy: Float32) {
    self.x = Int32(lroundf(Float32(self.x) * sx))
    self.y = Int32(lroundf(Float32(self.y) * sy))
  }

  mutating func scale(_ scale: Float32) {
    self.scale(sx: scale, sy: scale)
  }

  func transposedPoint() -> IntPoint {
    return IntPoint(x: y, y: x)
  }

  @discardableResult
  static func += (a: inout IntPoint, b: IntSize) -> IntPoint {
    a.move(dx: b.width, dy: b.height)
    return a
  }

  static func - (a: IntPoint, b: IntPoint) -> IntSize {
    return IntSize(width: a.x - b.x, height: a.y - b.y)
  }

  static prefix func - (point: IntPoint) -> IntPoint {
    return IntPoint(x: -point.x, y: -point.y)
  }

  var x: Int32
  var y: Int32
}

func - (a: IntPoint, b: IntSize) -> IntPoint {
  return IntPoint(x: a.x - b.width, y: a.y - b.height)
}

func toIntSize(_ a: IntPoint) -> IntSize {
  return IntSize(width: a.x, height: a.y)
}
