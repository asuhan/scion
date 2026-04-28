/*
 * Copyright (C) 2008-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2016-2021 Google Inc. All rights reserved.
 * Copyright (C) 2012 Nokia Corporation and/or its subsidiary(-ies)
 * Copyright (C) 2013 Xidorn Quan (quanxunzhen@gmail.com)
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1.  Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 * 2.  Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in the
 *     documentation and/or other materials provided with the distribution.
 * 3.  Neither the name of Apple Inc. ("Apple") nor the names of
 *     its contributors may be used to endorse or promote products derived
 *     from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE AND ITS CONTRIBUTORS "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL APPLE OR ITS CONTRIBUTORS BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
 * THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

private func determinant(_ a: FloatSize, _ b: FloatSize) -> Float32 {
  return a.width * b.height - a.height * b.width
}

private func clampToIntRange(_ value: Float32) -> Float32 {
  if value.isInfinite || abs(value) > Float32(Int32.max) {
    return Float32(value.sign == .minus ? Int32.min : Int32.max)
  }

  return value
}

private func rightMostCornerToVector(_ rect: FloatRectWrapper, _ vector: FloatSize) -> FloatPoint {
  // Return the corner of the rectangle that if it is to the left of the vector
  // would mean all of the rectangle is to the left of the vector.
  // The vector here represents the side between two points in a clockwise convex polygon.
  //
  //  Q  XXX
  // QQQ XXX   If the lower left corner of X is left of the vector that goes from the top corner of Q to
  //  QQQ      the right corner of Q, then all of X is left of the vector, and intersection impossible.
  //   Q
  //
  var point = FloatPoint()
  if vector.width >= 0 {
    point.setY(y: rect.maxY())
  } else {
    point.setY(y: rect.y())
  }
  if vector.height >= 0 {
    point.setX(x: rect.x())
  } else {
    point.setX(x: rect.maxX())
  }
  return point
}

// FIXME: Seems like this would be better as a struct.

// A FloatQuad is a collection of 4 points, often representing the result of
// mapping a rectangle through transforms. When initialized from a rect, the
// points are in clockwise order from top left.
struct FloatQuad {
  init() { self.init(FloatPoint(), FloatPoint(), FloatPoint(), FloatPoint()) }

  init(_ p1: FloatPoint, _ p2: FloatPoint, _ p3: FloatPoint, _ p4: FloatPoint) {
    m_p1 = p1
    m_p2 = p2
    m_p3 = p3
    m_p4 = p4
  }

  init(inRect: FloatRectWrapper) {
    m_p1 = inRect.location()
    m_p2 = FloatPoint(x: inRect.maxX(), y: inRect.y())
    m_p3 = FloatPoint(x: inRect.maxX(), y: inRect.maxY())
    m_p4 = FloatPoint(x: inRect.x(), y: inRect.maxY())
  }

  func p1() -> FloatPoint { return m_p1 }
  func p2() -> FloatPoint { return m_p2 }
  func p3() -> FloatPoint { return m_p3 }
  func p4() -> FloatPoint { return m_p4 }

  // Tests whether any part of the rectangle intersects with this quad.
  // This only works for convex quads.
  func intersectsRect(_ rect: FloatRectWrapper) -> Bool {
    // For each side of the quad clockwise we check if the rectangle is to the left of it
    // since only content on the right can onlap with the quad.
    // This only works if the quad is convex.
    var v1 = FloatSize()
    var v2 = FloatSize()
    var v3 = FloatSize()
    var v4 = FloatSize()

    // Ensure we use clockwise vectors.
    if !isCounterclockwise() {
      v1 = m_p2 - m_p1
      v2 = m_p3 - m_p2
      v3 = m_p4 - m_p3
      v4 = m_p1 - m_p4
    } else {
      v1 = m_p4 - m_p1
      v2 = m_p1 - m_p2
      v3 = m_p2 - m_p3
      v4 = m_p3 - m_p4
    }

    var p = rightMostCornerToVector(rect, v1)
    if determinant(v1, p - m_p1) < 0 {
      return false
    }

    p = rightMostCornerToVector(rect, v2)
    if determinant(v2, p - m_p2) < 0 {
      return false
    }

    p = rightMostCornerToVector(rect, v3)
    if determinant(v3, p - m_p3) < 0 {
      return false
    }

    p = rightMostCornerToVector(rect, v4)
    if determinant(v4, p - m_p4) < 0 {
      return false
    }

    // If not all of the rectangle is outside one of the quad's four sides, then that means at least
    // a part of the rectangle is overlapping the quad.
    return true
  }

  func boundingBox() -> FloatRectWrapper {
    let left = clampToIntRange(min(m_p1.x, m_p2.x, m_p3.x, m_p4.x))
    let top = clampToIntRange(min(m_p1.y, m_p2.y, m_p3.y, m_p4.y))

    let right = clampToIntRange(max(m_p1.x, m_p2.x, m_p3.x, m_p4.x))
    let bottom = clampToIntRange(max(m_p1.y, m_p2.y, m_p3.y, m_p4.y))

    return FloatRectWrapper(x: left, y: top, width: right - left, height: bottom - top)
  }

  func enclosingBoundingBox() -> IntRect { return enclosingIntRect(rect: boundingBox()) }

  func move(_ offset: LayoutSizeWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Tests whether points are in clock-wise, or counter clock-wise order.
  // Note that output is undefined when all points are colinear.
  private func isCounterclockwise() -> Bool {
    // Return if the two first vectors are turning clockwise. If the quad is convex then all following vectors will turn the same way.
    return determinant(m_p2 - m_p1, m_p3 - m_p2) < 0
  }

  private let m_p1: FloatPoint
  private let m_p2: FloatPoint
  private let m_p3: FloatPoint
  private let m_p4: FloatPoint
}
