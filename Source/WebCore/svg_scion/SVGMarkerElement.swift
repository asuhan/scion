/*
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2006, 2007 Rob Buis <buis@kde.org>
 * Copyright (C) Research In Motion Limited 2009-2010. All rights reserved.
 * Copyright (C) 2018-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2024 Igalia S.L.
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

final class SVGMarkerElementWrapper: SVGElementWrapper, SVGFitToViewBox {
  func viewBoxToViewTransform(_ viewWidth: Float32, _ viewHeight: Float32) -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func markerWidth() -> SVGLengthValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func markerHeight() -> SVGLengthValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func viewBox() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasEmptyViewBox() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
