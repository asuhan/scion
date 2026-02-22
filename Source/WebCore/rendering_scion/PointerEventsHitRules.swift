/*
    Copyright (C) 2007 Rob Buis <buis@kde.org>

    This library is free software; you can redistribute it and/or
    modify it under the terms of the GNU Library General Public
    License as published by the Free Software Foundation; either
    version 2 of the License, or (at your option) any later version.

    This library is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
    Library General Public License for more details.

    You should have received a copy of the GNU Library General Public License
    aint with this library; see the file COPYING.LIB.  If not, write to
    the Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
    Boston, MA 02110-1301, USA.
*/

struct PointerEventsHitRules {
  enum HitTestingTargetType {
    case SVGImage
    case SVGPath
    case SVGText
  }

  init(
    _ hitTestingTargetType: HitTestingTargetType, _ request: HitTestRequestWrapper,
    _ pointerEvents: PointerEvents
  ) {
    var pointerEvents = pointerEvents
    if request.svgClipContent() {
      pointerEvents = .Fill
    }

    if hitTestingTargetType == .SVGPath {
      switch pointerEvents
      {
      case .VisiblePainted, .Auto:  // "auto" is like "visiblePainted" when in SVG content
        requireFill = true
        requireStroke = true
        fallthrough
      case .Visible:
        requireVisible = true
        canHitFill = true
        canHitStroke = true
      case .VisibleFill:
        requireVisible = true
        canHitFill = true
      case .VisibleStroke:
        requireVisible = true
        canHitStroke = true
      case .Painted:
        requireFill = true
        requireStroke = true
        fallthrough
      case .All:
        canHitFill = true
        canHitStroke = true
      case .Fill:
        canHitFill = true
      case .Stroke:
        canHitStroke = true
      case .BoundingBox:
        canHitFill = true
        canHitBoundingBox = true
      case .None:
        // nothing to do here, defaults are all false.
        break
      }
    } else {
      switch pointerEvents
      {
      case .VisiblePainted, .Auto:  // "auto" is like "visiblePainted" when in SVG content
        requireVisible = true
        requireFill = true
        requireStroke = true
        canHitFill = true
        canHitStroke = true
      case .VisibleFill, .VisibleStroke, .Visible:
        requireVisible = true
        canHitFill = true
        canHitStroke = true
      case .Painted:
        requireFill = true
        requireStroke = true
        canHitFill = true
        canHitStroke = true
      case .Fill, .Stroke, .All:
        canHitFill = true
        canHitStroke = true
      case .BoundingBox:
        canHitFill = true
        canHitBoundingBox = true
      case .None:
        // nothing to do here, defaults are all false.
        break
      }
    }
  }

  var requireVisible: Bool = false
  var requireFill: Bool = false
  var requireStroke: Bool = false
  var canHitStroke: Bool = false
  var canHitFill: Bool = false
  var canHitBoundingBox: Bool = false
}
