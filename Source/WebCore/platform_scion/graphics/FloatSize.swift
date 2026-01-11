/*
 * Copyright (C) 2003-2023 Apple Inc.  All rights reserved.
 * Copyright (C) 2014 Google Inc.  All rights reserved.
 * Copyright (C) 2005 Nokia.  All rights reserved.
 *               2008 Eric Seidel <eric@webkit.org>
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

struct FloatSize: Equatable {
  init() {}

  init(width: Float32, height: Float32) {
    self.width = width
    self.height = height
  }

  init(size: IntSize) {
    width = Float32(size.width)
    height = Float32(size.height)
  }

  static func narrowPrecision(width: Float64, height: Float64) -> FloatSize {
    return FloatSize(width: narrowPrecisionToFloat(width), height: narrowPrecisionToFloat(height))
  }

  mutating func setWidth(width: Float32) { self.width = width }
  mutating func setHeight(height: Float32) { self.height = height }

  func isEmpty() -> Bool { return width <= 0 || height <= 0 }

  func isZero() -> Bool {
    return abs(width) < Float32.ulpOfOne && abs(height) < Float32.ulpOfOne
  }

  func aspectRatioDouble() -> Float64 { return Float64(width) / Float64(height) }

  mutating func expand(width: Float32, height: Float32) {
    self.width += width
    self.height += height
  }

  mutating func scale(_ s: Float32) {
    width *= s
    height *= s
  }

  mutating func scale(scaleX: Float32, scaleY: Float32) {
    width *= scaleX
    height *= scaleY
  }

  func scaled(s: Float32) -> FloatSize {
    return FloatSize(width: width * s, height: height * s)
  }

  func expandedTo(other: FloatSize) -> FloatSize {
    return FloatSize(
      width: width > other.width ? width : other.width,
      height: height > other.height ? height : other.height)
  }

  func transposedSize() -> FloatSize {
    return FloatSize(width: height, height: width)
  }

  @discardableResult
  static func += (a: inout FloatSize, b: FloatSize) -> FloatSize {
    a.setWidth(width: a.width + b.width)
    a.setHeight(height: a.height + b.height)
    return a
  }

  @discardableResult
  static func -= (a: inout FloatSize, b: FloatSize) -> FloatSize {
    a.setWidth(width: a.width - b.width)
    a.setHeight(height: a.height - b.height)
    return a
  }

  static func + (_ a: FloatSize, _ b: FloatSize) -> FloatSize {
    return FloatSize(width: a.width + b.width, height: a.height + b.height)
  }

  static func - (_ a: FloatSize, _ b: FloatSize) -> FloatSize {
    return FloatSize(width: a.width - b.width, height: a.height - b.height)
  }

  static prefix func - (size: FloatSize) -> FloatSize {
    return FloatSize(width: -size.width, height: -size.height)
  }

  static func == (lhs: FloatSize, rhs: FloatSize) -> Bool {
    return lhs.width == rhs.width && lhs.height == rhs.height
  }

  static func / (_ a: FloatSize, b: Float32) -> FloatSize {
    return FloatSize(width: a.width / b, height: a.height / b)
  }

  var width: Float32 = 0
  var height: Float32 = 0
}
