/*
 * Copyright (C) 2012 Adobe Systems Incorporated. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
 * COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
 * INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
 * STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED
 * OF THE POSSIBILITY OF SUCH DAMAGE.
 */

import wk_interop

struct LineSegment {
  init(logicalLeft: Float32, logicalRight: Float32) {
    self.init(logicalLeft: logicalLeft, logicalRight: logicalRight, isValid: true)
  }

  init(logicalLeft: Float32, logicalRight: Float32, isValid: Bool) {
    self.logicalLeft = logicalLeft
    self.logicalRight = logicalRight
    self.isValid = isValid
  }

  var logicalLeft: Float32 = 0
  var logicalRight: Float32 = 0
  var isValid = false
}

// A representation of a BasicShape that enables layout code to determine how to break a line up into segments
// that will fit within or around a shape. The line is defined by a pair of logical Y coordinates and the
// computed segments are returned as pairs of logical X coordinates. The BasicShape itself is defined in
// physical coordinates.

class ShapeWrapper {
  init(p: UnsafeRawPointer) {
    self.p = p
  }

  static func createShape(
    _ basicShape: BasicShape, _ borderBoxOffset: LayoutPointWrapper,
    _ logicalBoxSize: LayoutSizeWrapper, _ writingMode: WritingMode, _ margin: Float32
  ) -> ShapeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func createRasterShape(
    _ image: ImageWrapper?, _ threshold: Float32, _ imageR: LayoutRectWrapper,
    _ marginR: LayoutRectWrapper, _ writingMode: WritingMode, _ margin: Float32
  ) -> ShapeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func createBoxShape(
    _ roundedRect: RoundedRect, _ writingMode: WritingMode, _ margin: Float32
  ) -> ShapeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func getExcludedInterval(logicalTop: LayoutUnit, logicalHeight: LayoutUnit) -> LineSegment {
    let lineSegmentRaw = wk_interop.Shape_getExcludedInterval(
      p, logicalTop.rawValue(), logicalHeight.rawValue())
    var lineSegment = LineSegment(
      logicalLeft: lineSegmentRaw.logicalLeft,
      logicalRight: lineSegmentRaw.logicalRight)
    lineSegment.isValid = lineSegmentRaw.isValid
    return lineSegment
  }

  func lineOverlapsShapeMarginBounds(lineTop: LayoutUnit, lineHeight: LayoutUnit) -> Bool {
    return wk_interop.Shape_lineOverlapsShapeMarginBounds(
      p, lineTop.rawValue(), lineHeight.rawValue())
  }

  var p: UnsafeRawPointer
}
