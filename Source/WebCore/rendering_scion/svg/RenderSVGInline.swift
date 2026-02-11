/*
 * Copyright (C) 2006 Oliver Hunt <ojh16@student.canterbury.ac.nz>
 * Copyright (C) 2006-2024 Apple Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

class RenderSVGInlineWrapper: RenderInlineWrapper {
  override func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func updateFromStyle() {
    super.updateFromStyle()

    if document().settings().layerBasedSVGEngineEnabled() {
      updateHasSVGTransformFlags()
    }

    // SVG text layout code expects us to be an inline-level element.
    setInline(true)
  }

  // Chapter 10.4 of the SVG Specification say that we should use the
  // object bounding box of the parent text element.
  // We search for the root text element and take its bounding box.
  // It is also necessary to take the stroke and repaint rect of
  // this element, since we need it for filters.
  override final func objectBoundingBox() -> FloatRectWrapper {
    if let textAncestor = RenderSVGTextWrapper.locateRenderSVGTextAncestor(start: self) {
      return textAncestor.objectBoundingBox()
    }

    return FloatRectWrapper()
  }

  override final func repaintRectInLocalCoordinates(
    _ repaintRectCalculation: RepaintRectCalculation = .Fast
  ) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func currentSVGLayoutLocation() -> LayoutPointWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func setCurrentSVGLayoutLocation(_ location: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func clippedOverflowRect(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ context: VisibleRectContext
  ) -> LayoutRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func rectsForRepaintingAfterLayout(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ repaintOutlineBounds: RepaintOutlineBounds
  ) -> RepaintRects {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func computeFloatVisibleRectInContainer(
    _ rect: FloatRectWrapper, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> FloatRectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func mapLocalToContainer(
    _ ancestorContainer: RenderLayerModelObjectWrapper?, _ transformState: TransformState,
    _ mode: MapCoordinatesMode, _ wasFixed: inout Bool?
  ) {
    if document().settings().layerBasedSVGEngineEnabled() {
      super.mapLocalToContainer(ancestorContainer, transformState, mode, &wasFixed)
      return
    }
    SVGRenderSupport.mapLocalToContainer(self, ancestorContainer, transformState, &wasFixed)
  }

  override final func pushMappingToContainer(
    _ ancestorToStopAt: RenderLayerModelObjectWrapper?, _ geometryMap: RenderGeometryMap
  ) -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    if document().settings().layerBasedSVGEngineEnabled() {
      super.styleDidChange(diff: diff, oldStyle: oldStyle)
      return
    }

    if diff == .Layout {
      invalidateCachedBoundaries()
    }
    super.styleDidChange(diff: diff, oldStyle: oldStyle)
    SVGResourcesCache.clientStyleChanged(self, diff, oldStyle: oldStyle, newStyle: style())
  }
}
