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

import Foundation
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
    assert(marginR.height() >= Int32(0))

    let imageRect = snappedIntRect(rect: imageR)
    let marginRect = snappedIntRect(rect: marginR)
    let intervals = RasterShapeIntervals(size: marginRect.height(), offset: -marginRect.y())
    // FIXME (149420): This buffer should not be unconditionally unaccelerated.
    let imageBuffer = ImageBufferWrapper.create(
      FloatSize(size: imageRect.size), .Unspecified, 1, DestinationColorSpace.SRGB(), .BGRA8)

    let createShape = { () in
      let rasterShape = RasterShape(intervals, marginRect.size)
      rasterShape.m_writingMode = writingMode
      rasterShape.m_margin = margin
      return rasterShape
    }

    if imageBuffer == nil {
      return createShape()
    }

    let graphicsContext = imageBuffer!.context()
    if image == nil {
      graphicsContext.drawImage(
        image!, FloatRectWrapper(r: IntRect(location: IntPoint(), size: imageRect.size)))
    }

    let format = PixelBufferFormat(
      alphaFormat: .Unpremultiplied, pixelFormat: .RGBA8, colorSpace: DestinationColorSpace.SRGB())
    let pixelBuffer = imageBuffer!.getPixelBuffer(
      format, IntRect(location: IntPoint(), size: imageRect.size))

    // We could get to a value where PixelBuffer could be nullptr because ImageRect.size()
    // is huge and the data size overflows. Refer rdar://problem/61793884.
    if pixelBuffer == nil {
      return createShape()
    }

    if imageRect.area() * 4 == pixelBuffer!.bytes().count {
      var pixelArrayOffset: UInt64 = 3  // Each pixel is four bytes: RGBA.
      let alphaPixelThreshold = UInt8(lroundf(clampTo(value: threshold, min: 0, max: 1) * 255.0))

      let minBufferY = max(0, marginRect.y() - imageRect.y())
      let maxBufferY = min(imageRect.height(), marginRect.maxY() - imageRect.y())

      for y in minBufferY..<maxBufferY {
        var startX: Int32 = -1
        for x in 0..<imageRect.width() {
          let alpha = pixelBuffer!.item(pixelArrayOffset)
          let alphaAboveThreshold = alpha > alphaPixelThreshold
          if startX == -1 && alphaAboveThreshold {
            startX = x
          } else if startX != -1 && (!alphaAboveThreshold || x == imageRect.width() - 1) {
            // We're creating "end-point exclusive" intervals here. The value of an interval's x1 is
            // the first index of an above-threshold pixel for y, and the value of x2 is 1+ the index
            // of the last above-threshold pixel.
            let endX = alphaAboveThreshold ? x + 1 : x
            intervals.intervalAt(y + imageRect.y()).unite(
              IntShapeInterval(startX + imageRect.x(), endX + imageRect.x()))
            startX = -1
          }
          pixelArrayOffset += 4
        }
      }
    }

    return createShape()
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

  var m_writingMode: WritingMode = .HorizontalTb
  var m_margin: Float32 = 0
}
