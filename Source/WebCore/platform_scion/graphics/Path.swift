/*
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2006 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2007-2008 Torch Mobile, Inc.
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

import wk_interop

private func createFromPoints(_ points: [FloatPoint]) -> UnsafeMutableRawPointer {
  let x = points.map { $0.x }
  let y = points.map { $0.y }
  return x.withUnsafeBufferPointer { xPtr in
    y.withUnsafeBufferPointer { yPtr in
      return wk_interop.Path_create_from_points(
        UInt32(points.count), xPtr.baseAddress!, yPtr.baseAddress!)
    }
  }
}

class PathWrapper {
  init() { p = wk_interop.Path_create() }

  init(points: [FloatPoint]) { p = createFromPoints(points) }

  deinit { wk_interop.Path_destroy(p) }

  func moveTo(point: FloatPoint) {
    wk_interop.Path_moveTo(p, FloatPointRaw(x: point.x, y: point.y))
  }

  func addLineTo(point: FloatPoint) {
    wk_interop.Path_addLineTo(p, FloatPointRaw(x: point.x, y: point.y))
  }

  func addBezierCurveTo(controlPoint1: FloatPoint, controlPoint2: FloatPoint, endPoint: FloatPoint)
  {
    wk_interop.Path_addBezierCurveTo(
      p, FloatPointRaw(x: controlPoint1.x, y: controlPoint1.y),
      FloatPointRaw(x: controlPoint2.x, y: controlPoint2.y),
      FloatPointRaw(x: endPoint.x, y: endPoint.y))
  }

  func addRect(rect: FloatRectWrapper) {
    wk_interop.Path_addRect(
      p, FloatRectRaw(x: rect.x(), y: rect.y(), width: rect.width(), height: rect.height()))
  }

  func addRoundedRect(
    roundedRect: FloatRoundedRect, strategy: PathRoundedRect.Strategy = .PreferNative
  ) {
    wk_interop.Path_addRoundedRect(
      p, convertFloatRoundedRect(roundedRect), strategy == .PreferBezier)
  }

  func addRoundedRect(
    _ rect: FloatRectWrapper, _ roundingRadii: FloatSize,
    _ strategy: PathRoundedRect.Strategy = .PreferNative
  ) {
    wk_interop.Path_addRoundedRectSameRadii(
      p, toFloatRectRaw(rect), toFloatSizeRaw(roundingRadii), strategy == .PreferBezier)
  }

  func addRoundedRect(rect: RoundedRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func applyElements(_ applier: (PathElement) -> Void) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func translate(_ delta: FloatSize) {
    wk_interop.Path_translate(p, FloatSizeRaw(width: delta.width, height: delta.height))
  }

  func transform(_ transform: AffineTransform) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isEmpty() -> Bool { return wk_interop.Path_isEmpty(p) }

  func definitelySingleLine() -> Bool { return wk_interop.Path_definitelySingleLine(p) }

  func length() -> Float32 { return wk_interop.Path_length(p) }

  func traversalStateAtLength(_ length: Float32) -> PathTraversalState {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fastBoundingRect() -> FloatRectWrapper {
    return toFloatRect(wk_interop.Path_fastBoundingRect(p))
  }

  func boundingRect() -> FloatRectWrapper { return toFloatRect(wk_interop.Path_boundingRect(p)) }

  func interop() -> UnsafeMutableRawPointer { return p }

  private let p: UnsafeMutableRawPointer
}
