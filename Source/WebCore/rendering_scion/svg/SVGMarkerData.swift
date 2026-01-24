/*
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Library General Public
 * License as published by the Free Software Foundation; either
 * version 2 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Library General Public License for more details.
 *
 * You should have received a copy of the GNU Library General Public License
 * along with this library; see the file COPYING.LIB.  If not, write to
 * the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
 * Boston, MA 02110-1301, USA.
 */

enum SVGMarkerType {
  case StartMarker
  case MidMarker
  case EndMarker
}

struct MarkerPosition {
  let type: SVGMarkerType
  let origin: FloatPoint
  let angle: Float32
}

class MarkerPositions {
  var a: [MarkerPosition] = []
}

struct SVGMarkerData {
  init(_ positions: MarkerPositions, _ reverseStart: Bool) {
    self.positions = positions
    self.reverseStart = reverseStart
  }

  static func updateFromPathElement(_ markerData: inout SVGMarkerData, _ element: PathElement) {
    // First update the outslope for the previous element.
    if element.type != .MoveToPoint {
      markerData.updateOutslope(element.points[0])
    }

    // Record the marker for the previous element.
    if markerData.elementIndex > 0 {
      let markerType: SVGMarkerType = markerData.elementIndex == 1 ? .StartMarker : .MidMarker
      var markerTypeForOrientation: SVGMarkerType = .StartMarker
      if markerData.previousWasMoveTo {
        markerTypeForOrientation = .StartMarker
      } else if element.type == .MoveToPoint {
        markerTypeForOrientation = .EndMarker
      } else {
        markerTypeForOrientation = markerType
      }
      markerData.positions.a.append(
        MarkerPosition(
          type: markerType, origin: markerData.origin,
          angle: markerData.currentAngle(markerTypeForOrientation)))
    }

    // Update our marker data for this element.
    markerData.updateMarkerDataForPathElement(element)
    markerData.previousWasMoveTo = element.type == .MoveToPoint
    markerData.elementIndex += 1
  }

  func pathIsDone() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func currentAngle(_ type: SVGMarkerType) -> Float32 {
    // For details of this calculation, see: http://www.w3.org/TR/SVG/single-page.html#painting-MarkerElement
    let inSlope = FloatPoint(inslopePoint - inslopeOrigin)
    let outSlope = FloatPoint(outslopePoint - outslopeOrigin)

    var inAngle = Float64(rad2deg(inSlope.slopeAngleRadians()))
    let outAngle = Float64(rad2deg(outSlope.slopeAngleRadians()))

    switch type {
    case .StartMarker:
      return reverseStart
        ? narrowPrecisionToFloat(outAngle - 180) : narrowPrecisionToFloat(outAngle)
    case .MidMarker:
      // WK193015: Prevent bugs due to angles being non-continuous.
      if abs(inAngle - outAngle) > 180 {
        inAngle += 360
      }
      return narrowPrecisionToFloat((inAngle + outAngle) / 2)
    case .EndMarker:
      return narrowPrecisionToFloat(inAngle)
    }
  }

  private mutating func updateOutslope(_ point: FloatPoint) {
    outslopeOrigin = origin
    outslopePoint = point
  }

  private func updateMarkerDataForPathElement(_ element: PathElement) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let positions: MarkerPositions
  private var elementIndex: UInt32 = 0
  private let origin = FloatPoint()
  private var inslopeOrigin = FloatPoint()
  private var inslopePoint = FloatPoint()
  private var outslopeOrigin = FloatPoint()
  private var outslopePoint = FloatPoint()
  private let reverseStart: Bool
  private var previousWasMoveTo = false
}
