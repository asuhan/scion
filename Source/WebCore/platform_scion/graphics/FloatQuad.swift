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

private func dot(_ a: FloatSize, _ b: FloatSize) -> Float32 {
  return a.width * b.width + a.height * b.height
}

private func determinant(_ a: FloatSize, _ b: FloatSize) -> Float32 {
  return a.width * b.height - a.height * b.width
}

private func isPointInTriangle(
  _ p: FloatPoint, _ t1: FloatPoint, _ t2: FloatPoint, _ t3: FloatPoint
) -> Bool {
  // Compute vectors
  let v0 = t3 - t1
  let v1 = t2 - t1
  let v2 = p - t1

  // Compute dot products
  let dot00 = dot(v0, v0)
  let dot01 = dot(v0, v1)
  let dot02 = dot(v0, v2)
  let dot11 = dot(v1, v1)
  let dot12 = dot(v1, v2)

  // Compute barycentric coordinates
  let invDenom = 1.0 / (dot00 * dot11 - dot01 * dot01)
  let u = (dot11 * dot02 - dot01 * dot12) * invDenom
  let v = (dot00 * dot12 - dot01 * dot02) * invDenom

  // Check if point is in triangle
  return (u >= 0) && (v >= 0) && (u + v <= 1)
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

// Tests whether the line is contained by or intersected with the circle.
private func lineIntersectsCircle(
  _ center: FloatPoint, _ radius: Float32, _ p0: FloatPoint, _ p1: FloatPoint
) -> Bool {
  let x0 = p0.x - center.x
  let y0 = p0.y - center.y
  let x1 = p1.x - center.x
  let y1 = p1.y - center.y
  let radius2 = radius * radius
  if (x0 * x0 + y0 * y0) <= radius2 || (x1 * x1 + y1 * y1) <= radius2 {
    return true
  }
  if p0 == p1 {
    return false
  }

  let a = y0 - y1
  let b = x1 - x0
  let c = x0 * y1 - x1 * y0
  let distance2 = c * c / (a * a + b * b)
  // If distance between the center point and the line > the radius,
  // the line doesn't cross (or is contained by) the ellipse.
  if distance2 > radius2 {
    return false
  }

  // The nearest point on the line is between p0 and p1?
  let x = -a * c / (a * a + b * b)
  let y = -b * c / (a * a + b * b)
  return
    (((x0 <= x && x <= x1) || (x0 >= x && x >= x1))
    && ((y0 <= y && y <= y1) || (y1 <= y && y <= y0)))
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

  // Tests whether the given point is inside, or on an edge or corner of this quad.
  private func containsPoint(_ p: FloatPoint) -> Bool {
    return isPointInTriangle(p, m_p1, m_p2, m_p3) || isPointInTriangle(p, m_p1, m_p3, m_p4)
  }

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

  // Test whether any part of the circle/ellipse intersects with this quad.
  // Note that these two functions only work for convex quads.
  private func intersectsCircle(_ center: FloatPoint, _ radius: Float32) -> Bool {
    return containsPoint(center)  // The circle may be totally contained by the quad.
      || lineIntersectsCircle(center, radius, m_p1, m_p2)
      || lineIntersectsCircle(center, radius, m_p2, m_p3)
      || lineIntersectsCircle(center, radius, m_p3, m_p4)
      || lineIntersectsCircle(center, radius, m_p4, m_p1)
  }

  func intersectsEllipse(_ center: FloatPoint, _ radii: FloatSize) -> Bool {
    // Transform the ellipse to an origin-centered circle whose radius is the product of major radius and minor radius.
    // Here we apply the same transformation to the quad.
    var transformedQuad = self
    transformedQuad.move(-center.x, -center.y)
    transformedQuad.scale(radii.height, radii.width)

    return transformedQuad.intersectsCircle(FloatPoint(), radii.height * radii.width)
  }

  func boundingBox() -> FloatRectWrapper {
    let left = clampToIntRange(min(m_p1.x, m_p2.x, m_p3.x, m_p4.x))
    let top = clampToIntRange(min(m_p1.y, m_p2.y, m_p3.y, m_p4.y))

    let right = clampToIntRange(max(m_p1.x, m_p2.x, m_p3.x, m_p4.x))
    let bottom = clampToIntRange(max(m_p1.y, m_p2.y, m_p3.y, m_p4.y))

    return FloatRectWrapper(x: left, y: top, width: right - left, height: bottom - top)
  }

  func enclosingBoundingBox() -> IntRect { return enclosingIntRect(rect: boundingBox()) }

  mutating func move(_ offset: FloatSize) {
    m_p1 += offset
    m_p2 += offset
    m_p3 += offset
    m_p4 += offset
  }

  private mutating func move(_ dx: Float32, _ dy: Float32) {
    m_p1.move(dx: dx, dy: dy)
    m_p2.move(dx: dx, dy: dy)
    m_p3.move(dx: dx, dy: dy)
    m_p4.move(dx: dx, dy: dy)
  }

  private mutating func scale(_ dx: Float32, _ dy: Float32) {
    m_p1.scale(scaleX: dx, scaleY: dy)
    m_p2.scale(scaleX: dx, scaleY: dy)
    m_p3.scale(scaleX: dx, scaleY: dy)
    m_p4.scale(scaleX: dx, scaleY: dy)
  }

  // Tests whether points are in clock-wise, or counter clock-wise order.
  // Note that output is undefined when all points are colinear.
  private func isCounterclockwise() -> Bool {
    // Return if the two first vectors are turning clockwise. If the quad is convex then all following vectors will turn the same way.
    return determinant(m_p2 - m_p1, m_p3 - m_p2) < 0
  }

  private var m_p1: FloatPoint
  private var m_p2: FloatPoint
  private var m_p3: FloatPoint
  private var m_p4: FloatPoint
}
