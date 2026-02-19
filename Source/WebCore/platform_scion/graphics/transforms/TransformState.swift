/*
 * Copyright (C) 2011 Apple Inc.  All rights reserved.
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

class TransformState {
  enum TransformDirection {
    case ApplyTransformDirection
    case UnapplyInverseTransformDirection
  }
  enum TransformAccumulation {
    case FlattenTransform
    case AccumulateTransform
  }
  enum TransformMatrixTracking {
    case DoNotTrackTransformMatrix
    case TrackSVGCTMMatrix
    case TrackSVGScreenCTMMatrix
  }

  init(_ mappingDirection: TransformDirection, _ p: FloatPoint, _ quad: FloatQuad) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  init(_ mappingDirection: TransformDirection, _ p: FloatPoint) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTransformMatrixTracking(_ tracking: TransformMatrixTracking) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func transformMatrixTracking() -> TransformMatrixTracking {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func move(
    _ x: LayoutUnit, _ y: LayoutUnit, _ accumulate: TransformAccumulation = .FlattenTransform
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func move(_ offset: LayoutSizeWrapper, _ accumulate: TransformAccumulation = .FlattenTransform) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func applyTransform(
    _ transformFromContainer: AffineTransform,
    _ accumulate: TransformAccumulation = .FlattenTransform
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func applyTransform(
    _ transformFromContainer: TransformationMatrix,
    _ accumulate: TransformAccumulation = .FlattenTransform
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func flatten() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Return the coords of the point or quad in the last flattened layer
  func lastPlanarPoint() -> FloatPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lastPlanarQuad() -> FloatQuad {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Return the point or quad mapped through the current transform
  func mappedPoint() -> FloatPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func mappedQuad() -> FloatQuad {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func releaseTrackedTransform() -> TransformationMatrix? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func direction() -> TransformDirection {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
