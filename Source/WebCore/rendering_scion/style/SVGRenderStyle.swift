/*
    Copyright (C) 2004, 2005, 2007 Nikolas Zimmermann <zimmermann@kde.org>
                  2004, 2005, 2010 Rob Buis <buis@kde.org>
    Copyright (C) 2005-2017 Apple Inc. All rights reserved.
    Copyright (C) Research In Motion Limited 2010. All rights reserved.
    Copyright (C) 2014 Adobe Systems Incorporated. All rights reserved.

    Based on khtml code by:
    Copyright (C) 2000-2003 Lars Knoll (knoll@kde.org)
              (C) 2000 Antti Koivisto (koivisto@kde.org)
              (C) 2000-2003 Dirk Mueller (mueller@kde.org)
              (C) 2002-2003 Apple Inc.

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    along with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

enum BaselineShift {
  case Baseline
  case Sub
  case Super
  case Length
}

enum TextAnchor {
  case Start
  case Middle
  case End
}

enum ShapeRendering {
  case Auto
  case OptimizeSpeed
  case CrispEdges
  case GeometricPrecision
}

enum GlyphOrientation {
  case Degrees0
  case Degrees90
  case Degrees180
  case Degrees270
  case Auto
}

enum AlignmentBaseline {
  case Baseline
  case BeforeEdge
  case TextBeforeEdge
  case Middle
  case Central
  case AfterEdge
  case TextAfterEdge
  case Ideographic
  case Alphabetic
  case Hanging
  case Mathematical
}

enum DominantBaseline {
  case Auto
  case UseScript
  case NoChange
  case ResetSize
  case Ideographic
  case Alphabetic
  case Hanging
  case Mathematical
  case Central
  case Middle
  case TextAfterEdge
  case TextBeforeEdge
}

enum VectorEffect {
  case None
  case NonScalingStroke
}

enum BufferedRendering {
  case Auto
  case Dynamic
  case Static
}

class SVGRenderStyle {
  // Read accessors for all the properties
  func alignmentBaseline() -> AlignmentBaseline {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func dominantBaseline() -> DominantBaseline {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func baselineShift() -> BaselineShift {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func vectorEffect() -> VectorEffect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func bufferedRendering() -> BufferedRendering {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipRule() -> WindRule {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shapeRendering() -> ShapeRendering {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func textAnchor() -> TextAnchor {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func glyphOrientationHorizontal() -> GlyphOrientation {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func glyphOrientationVertical() -> GlyphOrientation {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func baselineShiftValue() -> SVGLengthValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rx() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func ry() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func x() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func y() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // convenience
  func hasMarkers() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasStroke() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasFill() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
