/*
 * Copyright (C) 2014-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

// Find point where lines through the two pairs of points intersect. Returns nil if the lines don't intersect.
func findIntersection(p1: FloatPoint, p2: FloatPoint, d1: FloatPoint, d2: FloatPoint) -> FloatPoint?
{
  let pxLength = p2.x - p1.x
  let pyLength = p2.y - p1.y

  let dxLength = d2.x - d1.x
  let dyLength = d2.y - d1.y

  let denom = pxLength * dyLength - pyLength * dxLength
  if denom == 0 {
    return nil
  }

  let param = ((d1.x - p1.x) * dyLength - (d1.y - p1.y) * dxLength) / denom

  return FloatPoint(x: p1.x + param * pxLength, y: p1.y + param * pyLength)
}

func ellipseContainsPoint(center: FloatPoint, radii: FloatSize, point: FloatPoint) -> Bool {
  if radii.width <= 0 || radii.height <= 0 {
    return false
  }

  // First, offset the query point so that the ellipse is effectively centered at the origin.
  var transformedPoint = point
  transformedPoint.move(dx: -center.x, dy: -center.y)

  // If the point lies outside of the bounding box determined by the radii of the ellipse, it can't possibly
  // be contained within the ellipse, so bail early.
  if transformedPoint.x < -radii.width || transformedPoint.x > radii.width
    || transformedPoint.y < -radii.height || transformedPoint.y > radii.height
  {
    return false
  }

  // Let (x, y) represent the translated point, and let (Rx, Ry) represent the radii of an ellipse centered at the origin.
  // (x, y) is contained within the ellipse if, after scaling the ellipse to be a unit circle, the identically scaled
  // point lies within that unit circle. In other words, the squared distance (x/Rx)^2 + (y/Ry)^2 of the transformed point
  // to the origin is no greater than 1. This is equivalent to checking whether or not the point (xRy, yRx) lies within a
  // circle of radius RxRy.
  transformedPoint.scale(scaleX: radii.height, scaleY: radii.width)
  let transformedRadius = radii.width * radii.height

  // We can bail early if |xRy| + |yRx| <= RxRy to avoid additional multiplications, since that means the Manhattan distance
  // of the transformed point is less than the radius, so the point must lie within the transformed circle.
  return abs(transformedPoint.x) + abs(transformedPoint.y) <= transformedRadius
    || transformedPoint.lengthSquared() <= transformedRadius * transformedRadius
}
