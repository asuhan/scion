/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003, 2006, 2007, 2009 Apple Inc. All rights reserved.
 * Copyright (C) 2010, 2012 Google Inc. All rights reserved.
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

class RenderLayerModelObjectWrapper: RenderElementWrapper {
  func hasSelfPaintingLayerModelObject() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layer() -> RenderLayerWrapper? {
    if let rawLayer = wk_interop.RenderLayerModelObject_layer(p) {
      return RenderLayerWrapper(p: rawLayer)
    }
    return nil
  }

  func checkedLayer() -> RenderLayerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleWillChange(diff: StyleDifference, newStyle: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func requiresLayer() -> Bool { fatalError("Not reached") }

  // Returns true if the background is painted opaque in the given rect.
  // The query rect is given in local coordinate system.
  func backgroundIsKnownToBeOpaqueInRect(_ localRect: LayoutRectWrapper) -> Bool { return false }

  // Returns false if the rect has no intersection with the applied clip rect. When the context specifies edge-inclusive
  // intersection, this return value allows distinguishing between no intersection and zero-area intersection.
  @discardableResult
  func applyCachedClipAndScrollPosition(
    _ rects: inout RepaintRects, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> Bool { return false }

  func shouldPlaceVerticalScrollbarOnLeftForLayerModelObject() -> Bool {
    return wk_interop.RenderLayerModelObject_shouldPlaceVerticalScrollbarOnLeft(p)
  }

  // Single source of truth deciding if a SVG renderer should be painted. All SVG renderers
  // use this method to test if they should continue processing in the paint() function or stop.
  func shouldPaintSVGRenderer(_ paintInfo: PaintInfoWrapper, _ relevantPaintPhases: PaintPhase)
    -> Bool
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nominalSVGLayoutLocation() -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func currentSVGLayoutLocation() -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setCurrentSVGLayoutLocation(_ location: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func svgClipperResourceFromStyle() -> RenderSVGResourceClipperWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func svgFilterResourceFromStyle() -> RenderSVGResourceFilter? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func svgMaskerResourceFromStyle() -> RenderSVGResourceMasker? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func svgMarkerStartResourceFromStyle() -> RenderSVGResourceMarkerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func svgMarkerMidResourceFromStyle() -> RenderSVGResourceMarkerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func svgMarkerEndResourceFromStyle() -> RenderSVGResourceMarkerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSVGClippingMask(paintInfo: PaintInfoWrapper, objectBoundingBox: FloatRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintSVGMask(_ paintInfo: PaintInfoWrapper, _ adjustedPaintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func updateLayerTransform() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func applyTransform(
    transform: inout TransformationMatrix, style: RenderStyleWrapper, boundingBox: FloatRectWrapper,
    options: RenderStyleWrapper.TransformOperationOption
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

// Pixel-snapping (== 'device pixel alignment') helpers.
func rendererNeedsPixelSnapping(renderer: RenderLayerModelObjectWrapper) -> Bool {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func snapRectToDevicePixelsIfNeeded(
  rect: LayoutRectWrapper, renderer: RenderLayerModelObjectWrapper
) -> FloatRectWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

func snapRectToDevicePixelsIfNeeded(
  rect: FloatRectWrapper, renderer: RenderLayerModelObjectWrapper
) -> FloatRectWrapper {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}
