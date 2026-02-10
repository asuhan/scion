/*
 * Copyright (C) 2006 Apple Inc.
 * Copyright (C) 2007 Nikolas Zimmermann <zimmermann@kde.org>
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

class RenderSVGBlockWrapper: RenderBlockFlowWrapper {
  override func computeOverflow(oldClientAfterEdge: LayoutUnit, recomputeFloats: Bool = false) {
    super.computeOverflow(oldClientAfterEdge: oldClientAfterEdge, recomputeFloats: recomputeFloats)

    if document().settings().layerBasedSVGEngineEnabled() {
      return
    }

    guard let textShadow = style().textShadow() else { return }

    var borderRect = borderBoxRect()
    textShadow.adjustRectForShadow(&borderRect)
    addVisualOverflow(rect: LayoutRectWrapper(rect: snappedIntRect(rect: borderRect)))
  }

  override func updateFromStyle() {
    super.updateFromStyle()

    if document().settings().layerBasedSVGEngineEnabled() {
      updateHasSVGTransformFlags()
      return
    }

    // RenderSVGlock, used by Render(SVGText|ForeignObject), is not allowed to call setHasNonVisibleOverflow(true).
    // RenderBlock assumes a layer to be present when the overflow clip functionality is requested. Both
    // Render(SVGText|ForeignObject) return 'false' on 'requiresLayer'. Fine for RenderSVGText.
    //
    // If we want to support overflow rules for <foreignObject> we can choose between two solutions:
    // a) make LegacyRenderSVGForeignObject require layers and SVG layer aware
    // b) refactor overflow logic out of RenderLayer (as suggested by dhyatt), which is a large task
    //
    // Until this is resolved, disable overflow support. Opera/FF don't support it as well at the moment (Feb 2010).
    //
    // Note: This does NOT affect overflow handling on outer/inner <svg> elements - this is handled
    // manually by LegacyRenderSVGRoot - which owns the documents enclosing root layer and thus works fine.
    setHasNonVisibleOverflow(false)
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
    if document().settings().layerBasedSVGEngineEnabled() {
      return super.clippedOverflowRect(repaintContainer, context)
    }
    return SVGRenderSupport.clippedOverflowRectForRepaint(self, repaintContainer, context)
  }

  override func rectsForRepaintingAfterLayout(
    _ repaintContainer: RenderLayerModelObjectWrapper?, _ repaintOutlineBounds: RepaintOutlineBounds
  ) -> RepaintRects {
    if document().settings().layerBasedSVGEngineEnabled() {
      return super.rectsForRepaintingAfterLayout(repaintContainer, repaintOutlineBounds)
    }

    var rects = RepaintRects(
      rect: SVGRenderSupport.clippedOverflowRectForRepaint(
        self, repaintContainer, RenderObjectWrapper.visibleRectContextForRepaint))
    if repaintOutlineBounds == .Yes {
      rects.outlineBoundsRect = outlineBoundsForRepaint(repaintContainer)
    }

    return rects
  }

  override final func computeFloatVisibleRectInContainer(
    _ rect: FloatRectWrapper, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> FloatRectWrapper? {
    assert(!document().settings().layerBasedSVGEngineEnabled())
    return SVGRenderSupport.computeFloatVisibleRectInContainer(self, rect, container, context)
  }

  override final func computeVisibleRectsInContainer(
    _ rects: RepaintRects, _ container: RenderLayerModelObjectWrapper?,
    _ context: VisibleRectContext
  ) -> RepaintRects? {
    if document().settings().layerBasedSVGEngineEnabled() {
      return computeVisibleRectsInSVGContainer(rects, container, context)
    }

    // FIXME: computeFloatVisibleRectInContainer() needs to be merged with computeVisibleRectsInContainer().
    if let adjustedRect = computeFloatVisibleRectInContainer(
      rects.clippedOverflowRect.FloatRect(), container, context)
    {
      return RepaintRects(rect: enclosingLayoutRect(rect: adjustedRect))
    }

    return nil
  }

  override final func mapLocalToContainer(
    _ ancestorContainer: RenderLayerModelObjectWrapper?, _ transformState: TransformState,
    _ mode: MapCoordinatesMode, _ wasFixed: inout Bool?
  ) {
    if document().settings().layerBasedSVGEngineEnabled() {
      mapLocalToSVGContainer(ancestorContainer!, transformState, mode, &wasFixed)
      return
    }

    SVGRenderSupport.mapLocalToContainer(self, ancestorContainer, transformState, &wasFixed)
  }

  override func pushMappingToContainer(
    _ ancestorToStopAt: RenderLayerModelObjectWrapper?, _ geometryMap: RenderGeometryMap
  ) -> RenderObjectWrapper? {
    if document().settings().layerBasedSVGEngineEnabled() {
      return super.pushMappingToContainer(ancestorToStopAt, geometryMap)
    }
    return SVGRenderSupport.pushMappingToContainer(self, ancestorToStopAt, geometryMap)
  }

  override func offsetFromContainer(
    _ container: RenderElementWrapper, _ physicalPoint: LayoutPointWrapper,
    _ offsetDependsOnPoint: inout Bool?
  ) -> LayoutSizeWrapper {
    assert(CPtrToInt(container.p) == CPtrToInt(self.container()?.p))
    assert(!isInFlowPositioned())
    assert(!isAbsolutelyPositioned())
    assert(!isInline())
    return locationOffset()
  }
}
