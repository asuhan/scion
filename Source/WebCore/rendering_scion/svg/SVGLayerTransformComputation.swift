/*
 * Copyright (C) 2020, 2021, 2022 Igalia S.L.
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

import Foundation

struct SVGLayerTransformComputation {
  init(_ renderer: RenderLayerModelObjectWrapper) { self.renderer = renderer }

  func computeAccumulatedTransform(
    _ stopAtRenderer: RenderLayerModelObjectWrapper?,
    _ trackingMode: TransformState.TransformMatrixTracking
  ) -> AffineTransform {
    // The mapping into parent coordinate systems stops at this renderer,
    // as mapLocalContainer exits if "ancestorContainer == this" is fulfilled.
    var ancestorContainer: RenderLayerModelObjectWrapper? = nil

    // Special handling of RenderSVGRoot, due to the way we implement the outermost <svg> element.
    // When SVGSVGElement::getCTM()/getScreenCTM() is invoked, we want to use information from the
    // anonymous RenderSVGViewportContainer (most noticeable: viewBox). Therefore we have to start
    // calling mapLocalToContainer() starting from the anonymous RenderSVGViewportContainer, and
    // not from its parent - RenderSVGRoot.
    var renderer: RenderLayerModelObjectWrapper? = renderer
    if let svgRoot = renderer as? RenderSVGRootWrapper {
      renderer = svgRoot.viewportContainer()
      if trackingMode == .TrackSVGCTMMatrix {
        ancestorContainer = svgRoot
      } else {
        assert(stopAtRenderer == nil)
      }
    } else if trackingMode == .TrackSVGCTMMatrix {
      // Only ever walk up to the anonymous RenderSVGViewportContainer (the first and only child of RenderSVGRoot).
      // Proceeding up to RenderSVGRoot would include border/padding/margin information which shouldn't be included for getCTM() (unlike getScreenCTM()).
      if stopAtRenderer == nil {
        if let svgRoot: RenderSVGRootWrapper = ancestorsOfType(descendant: renderer!).first() {
          ancestorContainer = svgRoot.viewportContainer()
        }
      } else if let enclosingLayerRenderer: RenderLayerModelObjectWrapper = ancestorsOfType(
        descendant: stopAtRenderer!
      ).first() {
        ancestorContainer = enclosingLayerRenderer
      }
    } else if trackingMode == .TrackSVGScreenCTMMatrix && stopAtRenderer != nil {
      assert(stopAtRenderer!.isComposited())
      ancestorContainer = ancestorsOfType(descendant: stopAtRenderer!).first()
    }

    let transformState = TransformState(.ApplyTransformDirection, FloatPoint())
    transformState.setTransformMatrixTracking(trackingMode)

    var unused: Bool? = nil
    renderer!.mapLocalToContainer(
      ancestorContainer, transformState, [.UseTransforms, .ApplyContainerFlip], &unused)

    if trackingMode == .TrackSVGCTMMatrix {
      if let svgRoot = self.renderer as? RenderSVGRootWrapper {
        transformState.move(-toLayoutSize(point: svgRoot.contentBoxLocation()))
      } else if ancestorContainer != nil {
        var unused: Bool? = nil
        // Continue to accumulate container offsets, excluding transforms, from the container of the current element ('ancestorContainer') up to RenderSVGRoot.
        // The resulting TransformState is aligned with the 'nominalSVGLayoutLocation()' within the local coordinate system of the 'm_renderer'. (0, 0) in local
        // coordinates is mapped to the top-left of the 'objectBoundingBoxWithoutTransforms()' of the SVG renderer.
        if let svgRoot = RenderAncestorIteratorAdapter<RenderSVGRootWrapper>.lineageOfType(
          first: ancestorContainer!
        ).first() {
          ancestorContainer!.mapLocalToContainer(
            svgRoot.viewportContainer(), transformState, [.ApplyContainerFlip], &unused)
        }
      }
    }

    transformState.flatten()

    guard let transform = transformState.releaseTrackedTransform() else { return AffineTransform() }

    let ctm = transform.toAffineTransform()

    // When we've climbed the ancestor tree up to and including RenderSVGRoot, the CTM is aligned with the top-left of the renderers bounding box (= nominal SVG layout location).
    // However, for getCTM/getScreenCTM we're supposed to align by the top-left corner of the enclosing "viewport element" -- correct for that.
    if self.renderer.isRenderSVGRoot() {
      return ctm
    }

    ctm.translate(-toFloatSize(a: self.renderer.nominalSVGLayoutLocation().FloatPoint()))
    return ctm
  }

  func calculateScreenFontSizeScalingFactor() -> Float32 {
    // Walk up the render tree, accumulating transforms
    var layer = renderer.enclosingLayer()

    var stopAtLayer: RenderLayerWrapper? = nil
    while layer != nil {
      // We can stop at compositing layers, to match the backing resolution.
      if layer!.isComposited() {
        stopAtLayer = layer
        break
      }

      layer = layer!.parent()
    }

    let ctm = computeAccumulatedTransform(stopAtLayer?.renderer(), .TrackSVGScreenCTMMatrix)
    ctm.scale(Float64(renderer.document().deviceScaleFactor()))
    if !renderer.document().isSVGDocument() {
      ctm.scale(Float64(renderer.style().usedZoom()))
    }
    return narrowPrecisionToFloat(hypot(ctm.xScale(), ctm.yScale()) / sqrtOfTwoDouble)
  }

  private let renderer: RenderLayerModelObjectWrapper
}
