/*
 * Copyright (C) 2004, 2005, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2008 Rob Buis <buis@kde.org>
 * Copyright (C) 2005, 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2006 Apple Inc.
 * Copyright (C) 2009 Google, Inc.
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 * Copyright (C) 2009 Jeff Schiller <codedread@gmail.com>
 * Copyright (C) 2011 Renata Hodovan <reni@webkit.org>
 * Copyright (C) 2011 University of Szeged
 * Copyright (C) 2020, 2021, 2022, 2023, 2024 Igalia S.L.
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

private func markerForType(
  _ type: SVGMarkerType, _ markerStart: RenderSVGResourceMarkerWrapper?,
  _ markerMid: RenderSVGResourceMarkerWrapper?, _ markerEnd: RenderSVGResourceMarkerWrapper?
) -> RenderSVGResourceMarkerWrapper? {
  switch type {
  case .StartMarker:
    return markerStart
  case .MidMarker:
    return markerMid
  case .EndMarker:
    return markerEnd
  }
}

final class RenderSVGPathWrapper: RenderSVGShapeWrapper {
  func computeMarkerBoundingBox(_ options: SVGBoundingBoxComputation.DecorationOptions)
    -> FloatRectWrapper
  {
    if markerPositions.isEmpty {
      return FloatRectWrapper()
    }

    let recursionTracking = SVGVisitedRendererTracking(RenderSVGPathWrapper.s_visitedSet)
    if recursionTracking.isVisiting(self) {
      return FloatRectWrapper()
    }

    let _ = SVGVisitedRendererTracking.Scope(recursionTracking, self)

    let markerStart = svgMarkerStartResourceFromStyle()
    let markerMid = svgMarkerMidResourceFromStyle()
    let markerEnd = svgMarkerEndResourceFromStyle()
    if markerStart == nil && markerMid == nil && markerEnd == nil {
      return FloatRectWrapper()
    }

    var boundaries = FloatRectWrapper()
    for markerPosition in markerPositions {
      if let marker = markerForType(markerPosition.type, markerStart, markerMid, markerEnd) {
        boundaries.unite(
          other: marker.computeMarkerBoundingBox(
            options,
            marker.markerTransformation(
              markerPosition.origin, angle: markerPosition.angle, strokeWidth: strokeWidth()))
        )
      }
    }

    return boundaries
  }

  private static let s_visitedSet = SVGVisitedRendererTracking.VisitedSet()

  override func updateShapeFromElement() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func strokeShape(_ context: GraphicsContextWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func drawMarkers(_ paintInfo: PaintInfoWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func isRenderingDisabled() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let markerPositions: [MarkerPosition] = []
}
