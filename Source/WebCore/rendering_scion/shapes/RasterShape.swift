/*
 * Copyright (C) 2013 Adobe Systems Incorporated. All rights reserved.
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

struct RasterShapeIntervals {
  init(size: Int32, offset: Int32 = 0) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func initializeBounds() {
    m_bounds = IntRect()
    for y in minY()..<maxY() {
      let intervalAtY = intervalAt(y)
      if intervalAtY.isEmpty() {
        continue
      }
      m_bounds.unite(IntRect(x: intervalAtY.x1(), y: y, width: intervalAtY.width(), height: 1))
    }
  }

  func intervalAt(_ y: Int32) -> IntShapeInterval {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func minY() -> Int32 { return -m_offset }
  private func maxY() -> Int32 { return -m_offset + Int32(m_intervals.count) }

  private var m_bounds: IntRect
  private let m_intervals: [IntShapeInterval]
  private let m_offset: Int32
}

final class RasterShape: ShapeWrapper {
  init(_ intervals: RasterShapeIntervals, _ marginRectSize: IntSize) {
    super.init()
    m_intervals = intervals
    m_marginRectSize = marginRectSize
    m_intervals!.initializeBounds()
  }

  private var m_intervals: RasterShapeIntervals? = nil
  private var m_marginRectSize = IntSize()
}
