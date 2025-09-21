/*
 * Copyright (C) 2004, 2005, 2007, 2008 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2006, 2007, 2008 Rob Buis <buis@kde.org>
 * Copyright (C) Research In Motion Limited 2009-2010. All rights reserved.
 * Copyright (C) 2011 Dirk Schulze <krit@webkit.org>
 * Copyright (C) 2022 Apple Inc. All rights reserved.
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

// TODO(asuhan): inherit from LegacyRenderSVGResourceContainer
class LegacyRenderSVGResourceClipper {
  // clipPath can be clipped too, but don't have a boundingBox or repaintRect. So we can't call
  // applyResource directly and use the rects from the object, since they are empty for RenderSVGResources
  // FIXME: We made applyClippingToContext public because we cannot call applyResource on HTML elements (it asserts on RenderObject::objectBoundingBox)
  // objectBoundingBox ia used to compute clip path geometry when clipPathUnits="objectBoundingBox".
  // clippedContentBounds is the bounds of the content to which clipping is being applied.
  @discardableResult
  func applyClippingToContext(
    context: GraphicsContextWrapper, renderer: RenderElementWrapper,
    objectBoundingBox: FloatRectWrapper, clippedContentBounds: FloatRectWrapper,
    usedZoom: Float32 = 1
  ) -> LegacyRenderSVGResource.ApplyResult {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
