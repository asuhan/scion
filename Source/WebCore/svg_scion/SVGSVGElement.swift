/*
 * Copyright (C) 2004, 2005, 2006, 2019 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2006, 2007, 2008, 2010 Rob Buis <buis@kde.org>
 * Copyright (C) 2007-2022 Apple Inc. All rights reserved.
 * Copyright (C) 2015 Google Inc. All rights reserved.
 * Copyright (C) 2014 Adobe Systems Incorporated. All rights reserved.
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

// TODO(asuhan): also inherit from SVGZoomAndPan
final class SVGSVGElementWrapper: SVGGraphicsElementWrapper, SVGFitToViewBox {
  func viewBox() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasEmptyViewBox() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func currentTranslateValue() -> FloatPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasIntrinsicWidth() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasIntrinsicHeight() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func intrinsicWidth() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func intrinsicHeight() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
