/*
 * Copyright (C) 2012 Google, Inc.
 * All rights reserved.
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
 * THIS SOFTWARE IS PROVIDED BY UNIVERSITY OF SZEGED ``AS IS'' AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL UNIVERSITY OF SZEGED OR
 * CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
 * EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY
 * OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

final class LegacyRenderSVGEllipse: LegacyRenderSVGShapeWrapper {
  override func updateShapeFromElement() {
    // Before creating a new object we need to clear the cached bounding box
    // to avoid using garbage.
    clearPath()
    shapeType = .Empty
    fillBoundingBox = FloatRectWrapper()
    m_strokeBoundingBox = nil
    m_approximateStrokeBoundingBox = nil
    m_center = FloatPoint()
    m_radii = FloatSize()

    calculateRadiiAndCenter()

    // Spec: "A negative value is illegal. A value of zero disables rendering of the element."
    if m_radii.isEmpty() {
      return
    }

    if m_radii.width == m_radii.height {
      shapeType = .Circle
    } else {
      shapeType = .Ellipse
    }

    if hasNonScalingStroke() {
      // Fallback to path-based approach if shape has a non-scaling stroke.
      fillBoundingBox = ensurePath().boundingRect()
      return
    }

    fillBoundingBox = FloatRectWrapper(
      x: m_center.x - m_radii.width, y: m_center.y - m_radii.height,
      width: 2 * m_radii.width, height: 2 * m_radii.height)
    m_strokeBoundingBox = fillBoundingBox
    if style().svgStyle().hasStroke() {
      m_strokeBoundingBox!.inflate(d: strokeWidth() / 2)
    }
  }

  override func isEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func isRenderingDisabled() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func calculateRadiiAndCenter() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var m_center = FloatPoint()
  private var m_radii = FloatSize()
}
