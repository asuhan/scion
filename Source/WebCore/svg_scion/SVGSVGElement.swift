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

import wk_interop

// TODO(asuhan): also inherit from SVGZoomAndPan
final class SVGSVGElementWrapper: SVGGraphicsElementWrapper, SVGFitToViewBox {
  func viewBox() -> FloatRectWrapper {
    var rect = [Float32](repeating: 0, count: 4)
    wk_interop.SVGSVGElement_viewBox(p, &rect)
    return FloatRectWrapper(x: rect[0], y: rect[1], width: rect[2], height: rect[3])
  }

  func hasEmptyViewBox() -> Bool {
    return wk_interop.SVGSVGElement_hasEmptyViewBox(p)
  }

  func currentTranslateValue() -> FloatPoint {
    var point = [Float32](repeating: 0, count: 2)
    wk_interop.SVGSVGElement_currentTranslateValue(p, &point)
    return FloatPoint(x: point[0], y: point[1])
  }

  func resumePausedAnimationsIfNeeded(_ visibleRect: IntRect) -> Bool {
    return wk_interop.SVGSVGElement_resumePausedAnimationsIfNeeded(
      p, visibleRect.x(), visibleRect.y(), visibleRect.width(), visibleRect.height())
  }

  func hasIntrinsicWidth() -> Bool {
    return wk_interop.SVGSVGElement_hasIntrinsicWidth(p)
  }

  func hasIntrinsicHeight() -> Bool {
    return wk_interop.SVGSVGElement_hasIntrinsicHeight(p)
  }

  func intrinsicWidth() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.SVGSVGElement_intrinsicWidth(p), owner: true)
  }

  func intrinsicHeight() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.SVGSVGElement_intrinsicHeight(p), owner: true)
  }

  func viewBoxToViewTransform(_ viewWidth: Float32, _ viewHeight: Float32) -> AffineTransform {
    var t = [Float64](repeating: 0, count: 6)
    wk_interop.SVGSVGElement_viewBoxToViewTransform(p, viewWidth, viewHeight, &t)
    return AffineTransform(a: t[0], b: t[1], c: t[2], d: t[3], e: t[4], f: t[5])
  }
}
