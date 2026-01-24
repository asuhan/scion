/*
 * Copyright (C) 2011 University of Szeged
 * Copyright (C) 2011 Renata Hodovan <reni@webkit.org>
 * Copyright (C) 2020, 2021, 2022 Igalia S.L.
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

final class RenderSVGRect: RenderSVGShapeWrapper {
  private func rectElement() -> SVGRectElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func updateShapeFromElement() {
    // Before creating a new object we need to clear the cached bounding box
    // to avoid using garbage.
    clearPath()
    shapeType = .Empty
    fillBoundingBox = FloatRectWrapper()
    m_strokeBoundingBox = nil
    m_approximateStrokeBoundingBox = nil

    let rectElement = rectElement()
    let lengthContext = SVGLengthContext(context: rectElement)
    let boundingBoxSize = FloatSize(
      width: lengthContext.valueForLength(style().width(), .Width),
      height: lengthContext.valueForLength(style().height(), .Height))

    // Spec: "A negative value is illegal. A value of zero disables rendering of the element."
    if boundingBoxSize.isEmpty() {
      return
    }

    let svgStyle = style().svgStyle()
    if lengthContext.valueForLength(svgStyle.rx(), .Width) > 0
      || lengthContext.valueForLength(svgStyle.ry(), .Height) > 0
    {
      shapeType = .RoundedRectangle
    } else {
      shapeType = .Rectangle
    }

    if shapeType != .Rectangle || hasNonScalingStroke() {
      // Fallback to path-based approach.
      fillBoundingBox = ensurePath().boundingRect()
      return
    }

    fillBoundingBox = FloatRectWrapper(
      location: FloatPoint(
        x: lengthContext.valueForLength(svgStyle.x(), .Width),
        y: lengthContext.valueForLength(svgStyle.y(), .Height)),
      size: boundingBoxSize)

    var strokeBoundingBox = fillBoundingBox
    if svgStyle.hasStroke() {
      strokeBoundingBox.inflate(d: strokeWidth() / 2)
    }

    m_strokeBoundingBox = strokeBoundingBox
  }

  override func isEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func isRenderingDisabled() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func fillShape(_ context: GraphicsContextWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func strokeShape(_ context: GraphicsContextWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
