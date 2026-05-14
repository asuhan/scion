/*
 * Copyright (C) 2005-2016 Apple Inc.  All rights reserved.
 * Copyright (C) 2014 Google Inc.  All rights reserved.
 *               2010 Dirk Schulze <krit@webkit.org>
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

class AffineTransform: Equatable {
  init() {
    self.transform = [1, 0, 0, 1, 0, 0]
  }

  init(a: Float64, b: Float64, c: Float64, d: Float64, e: Float64, f: Float64) {
    self.transform = [a, b, c, d, e, f]
  }

  private func map(x: Float64, y: Float64, x2: inout Float64, y2: inout Float64) {
    x2 = (transform[0] * x + transform[2] * y + transform[4])
    y2 = (transform[1] * x + transform[3] * y + transform[5])
  }

  func mapPoint(_ point: FloatPoint) -> FloatPoint {
    var x2: Float64 = 0
    var y2: Float64 = 0
    map(x: Float64(point.x), y: Float64(point.y), x2: &x2, y2: &y2)

    return FloatPoint(x: narrowPrecisionToFloat(x2), y: narrowPrecisionToFloat(y2))
  }

  // Rounds the resulting mapped rectangle out. This is helpful for bounding
  // box computations but may not be what is wanted in other contexts.
  func mapRect(rect: IntRect) -> IntRect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func mapRect(rect: FloatRectWrapper) -> FloatRectWrapper {
    if isIdentityOrTranslation() {
      var mappedRect = rect
      mappedRect.move(
        dx: narrowPrecisionToFloat(transform[4]), dy: narrowPrecisionToFloat(transform[5]))
      return mappedRect
    }

    var result = FloatQuad()
    result.setP1(mapPoint(rect.location()))
    result.setP2(mapPoint(FloatPoint(x: rect.maxX(), y: rect.y())))
    result.setP3(mapPoint(FloatPoint(x: rect.maxX(), y: rect.maxY())))
    result.setP4(mapPoint(FloatPoint(x: rect.x(), y: rect.maxY())))
    return result.boundingBox()
  }

  func isIdentity() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func a() -> Float64 { return transform[0] }
  func b() -> Float64 { return transform[1] }
  func c() -> Float64 { return transform[2] }
  func d() -> Float64 { return transform[3] }
  func e() -> Float64 { return transform[4] }
  func setE(_ e: Float64) { transform[4] = e }
  func f() -> Float64 { return transform[5] }
  func setF(_ f: Float64) { transform[5] = f }

  func makeIdentity() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func multiply(_ other: AffineTransform) -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func scale(_ s: Float64) -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func scale(_ sx: Float64, _ sy: Float64) -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func scaleNonUniform(_ sx: Float64, _ sy: Float64) -> AffineTransform {  // Same as scale(sx, sy).
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func scale(_ s: FloatSize) -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func rotate(_ a: Float64) -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func translate(_ tx: Float64, _ ty: Float64) -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func translate(_ t: FloatPoint) -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func translate(_ t: FloatSize) -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // These functions get the length of an axis-aligned unit vector
  // once it has been mapped through the transform
  func xScale() -> Float64 {
    return hypot(transform[0], transform[1])
  }

  func yScale() -> Float64 {
    return hypot(transform[2], transform[3])
  }

  func inverse() -> AffineTransform? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isIdentityOrTranslationOrFlipped() -> Bool {
    return transform[0] == 1 && transform[1] == 0 && transform[2] == 0
      && (transform[3] == 1 || transform[3] == -1)
  }

  func isIdentityOrTranslation() -> Bool {
    return transform[0] == 1 && transform[1] == 0 && transform[2] == 0 && transform[3] == 1
  }

  // result = this * t (i.e., a multRight)
  static func * (this: AffineTransform, t: AffineTransform) -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func == (_ a: AffineTransform, _ b: AffineTransform) -> Bool {
    return a.transform == b.transform
  }

  static func makeTranslation(_ delta: FloatSize) -> AffineTransform {
    return AffineTransform(
      a: 1, b: 0, c: 0, d: 1, e: Float64(delta.width), f: Float64(delta.height))
  }

  func deepCopy() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // TODO(asuhan): replace with InlineArray after upgrade to Swift 6.2
  private var transform: [Float64]

  static let identity = AffineTransform()
}
