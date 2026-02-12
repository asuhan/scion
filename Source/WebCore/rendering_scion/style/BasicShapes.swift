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
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

class BasicShape {
  enum `Type` {
    case Polygon
    case Path
    case Circle
    case Ellipse
    case Inset
    case Rect
    case Xywh
    case Shape
  }

  func type() -> `Type` {
    fatalError("Not reached")
  }
}

struct BasicShapeCenterCoordinate {}

class BasicShapeCircleOrEllipse: BasicShape {}

class BasicShapeCircle: BasicShapeCircleOrEllipse {
  func centerX() -> BasicShapeCenterCoordinate {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func centerY() -> BasicShapeCenterCoordinate {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func floatValueForRadiusInBox(_ boxSize: FloatSize, _ center: FloatPoint) -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

final class BasicShapeEllipse: BasicShapeCircleOrEllipse {
  func centerX() -> BasicShapeCenterCoordinate {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func centerY() -> BasicShapeCenterCoordinate {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func floatSizeForRadiusInBox(_ boxSize: FloatSize, _ center: FloatPoint) -> FloatSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

final class BasicShapePolygon: BasicShape {
  func values() -> ArraySlice<LengthWrapper> { return m_values[...] }

  func windRule() -> WindRule { return m_windRule }

  private let m_windRule: WindRule = .NonZero
  private let m_values: [LengthWrapper] = []
}

final class BasicShapeInset: BasicShape {
  func top() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func right() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func bottom() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func left() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func topLeftRadius() -> LengthSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func topRightRadius() -> LengthSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func bottomRightRadius() -> LengthSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func bottomLeftRadius() -> LengthSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
