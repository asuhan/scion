/*
 * Copyright (C) 2007, 2008 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Google, Inc.  All rights reserved.
 * Copyright (C) 2009 Dirk Schulze <krit@webkit.org>
 * Copyright (C) Research In Motion Limited 2009-2010. All rights reserved.
 * Copyright (C) 2018 Adobe Systems Incorporated. All rights reserved.
 * Copyright (C) 2020 Apple Inc. All rights reserved.
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

// SVGRendererSupport is a helper class sharing code between all SVG renderers.
class SVGRenderSupport {
  // Helper function determining wheter overflow is hidden
  static func isOverflowHidden(_ renderer: RenderElementWrapper) -> Bool {
    // LegacyRenderSVGRoot should never query for overflow state - it should always clip itself to the initial viewport size.
    assert(!renderer.isDocumentElementRenderer())

    return isNonVisibleOverflow(renderer.style().overflowX())
  }

  // Important functions used by nearly all SVG renderers centralizing coordinate transformations / repaint rect calculations
  static func clippedOverflowRectForRepaint(
    _ renderer: RenderElementWrapper, _ repaintContainer: RenderLayerModelObjectWrapper?,
    _ context: RenderObjectWrapper.VisibleRectContext
  ) -> LayoutRectWrapper {
    // Return early for any cases where we don't actually paint
    if renderer.isInsideEntirelyHiddenLayer() {
      return LayoutRectWrapper()
    }

    // Pass our local paint rect to computeFloatVisibleRectInContainer() which will
    // map to parent coords and recurse up the parent chain.
    return enclosingLayoutRect(
      rect: renderer.computeFloatRectForRepaint(
        renderer.repaintRectInLocalCoordinates(context.repaintRectCalculation()), repaintContainer))
  }

  static func checkForSVGRepaintDuringLayout(_ renderer: RenderElementWrapper)
    -> LayoutRepainter.CheckForRepaint
  {
    if !renderer.checkForRepaintDuringLayout() {
      return .No
    }
    // When a parent container is transformed in SVG, all children will be painted automatically
    // so we are able to skip redundant repaint checks.
    if let parent = renderer.parent() as? LegacyRenderSVGContainer,
      parent.isRepaintSuspendedForChildren() || parent.didTransformToRootUpdate()
    {
      return .No
    }
    return .Yes
  }

  static func calculateApproximateStrokeBoundingBox(_ renderer: RenderElementWrapper)
    -> FloatRectWrapper
  {
    let calculateApproximateScalingStrokeBoundingBox = {
      (renderer: RenderSVGShapeProto, fillBoundingBox: FloatRectWrapper) -> FloatRectWrapper in
      // Implementation of
      // https://drafts.fxtf.org/css-masking/#compute-stroke-bounding-box
      // except that we ignore whether the stroke is none.

      assert(renderer.style().svgStyle().hasStroke())

      var strokeBoundingBox = fillBoundingBox
      let strokeWidth = renderer.strokeWidth()
      if strokeWidth <= 0 {
        return strokeBoundingBox
      }

      var delta = strokeWidth / 2
      switch renderer.shapeType {
      case .Empty:
        // Spec: "A negative value is illegal. A value of zero disables rendering of the element."
        return strokeBoundingBox
      case .Ellipse, .Circle:
        break
      case .Rectangle, .RoundedRectangle:
        break
      case .Path, .Line:
        let style = renderer.style()
        if renderer.shapeType == .Path && style.joinStyle() == .Miter {
          let miter = style.strokeMiterLimit()
          if Float64(miter) < sqrtOfTwoDouble && style.capStyle() == .Square {
            delta = Float32(Float64(delta) * sqrtOfTwoDouble)
          } else {
            delta *= max(miter, 1)
          }
        } else if style.capStyle() == .Square {
          delta = Float32(Float64(delta) * sqrtOfTwoDouble)
        }
      }

      strokeBoundingBox.inflate(d: delta)
      return strokeBoundingBox
    }

    let calculateApproximateNonScalingStrokeBoundingBox = {
      (renderer: RenderSVGShapeProto, fillBoundingBox: FloatRectWrapper) -> FloatRectWrapper in
      assert(renderer.hasPath())
      assert(renderer.style().svgStyle().hasStroke())
      assert(renderer.hasNonScalingStroke())

      var strokeBoundingBox = fillBoundingBox
      let nonScalingTransform = renderer.nonScalingStrokeTransform()
      if let inverse = nonScalingTransform.inverse() {
        let usePath = renderer.nonScalingStrokePath(renderer.path(), nonScalingTransform)
        var strokeBoundingRect = calculateApproximateScalingStrokeBoundingBox(
          renderer, usePath.fastBoundingRect())
        strokeBoundingRect = inverse.mapRect(rect: strokeBoundingRect)
        strokeBoundingBox.unite(other: strokeBoundingRect)
      }
      return strokeBoundingBox
    }

    let calculate = { (renderer: RenderSVGShapeProto) -> FloatRectWrapper in
      if !renderer.style().svgStyle().hasStroke() {
        return renderer.objectBoundingBox()
      }
      if renderer.hasNonScalingStroke() {
        return calculateApproximateNonScalingStrokeBoundingBox(
          renderer, renderer.objectBoundingBox())
      }
      return calculateApproximateScalingStrokeBoundingBox(renderer, renderer.objectBoundingBox())
    }

    if let shape = renderer as? LegacyRenderSVGShapeWrapper {
      return shape.adjustStrokeBoundingBoxForMarkersAndZeroLengthLinecaps(.Fast, calculate(shape))
    }

    let shape = renderer as! RenderSVGShapeWrapper
    return shape.adjustStrokeBoundingBoxForZeroLengthLinecaps(calculate(shape))
  }

  static func styleChanged(renderer: RenderElementWrapper, oldStyle: RenderStyleWrapper?) {
    if renderer.element() != nil && renderer.element()!.isSVGElement()
      && (oldStyle == nil || renderer.style().hasBlendMode() != oldStyle!.hasBlendMode())
    {
      SVGRenderSupport.updateMaskedAncestorShouldIsolateBlending(renderer)
    }
  }

  private static func isolatesBlending(_ style: RenderStyleWrapper) -> Bool {
    return style.hasPositionedMask() || style.hasFilter() || style.hasBlendMode()
      || style.opacity() < 1
  }

  private static func updateMaskedAncestorShouldIsolateBlending(_ renderer: RenderElementWrapper) {
    let element = renderer.element()!
    assert(element.isSVGElement())
    for ancestor: SVGGraphicsElementWrapper in ancestorsOfType(descendant: element) {
      let style = ancestor.computedStyle()
      if style == nil || !isolatesBlending(style!) {
        continue
      }
      if style!.hasPositionedMask() {
        ancestor.setShouldIsolateBlending(renderer.style().hasBlendMode())
      }
      return
    }
  }

  static func findTreeRootObject(start: RenderElementWrapper) -> LegacyRenderSVGRootWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
