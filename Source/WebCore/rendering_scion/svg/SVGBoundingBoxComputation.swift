/*
 * Copyright (C) 2021, 2022, 2023 Igalia S.L.
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

struct SVGBoundingBoxComputation: ~Copyable {
  init(_ renderer: RenderLayerModelObjectWrapper) { self.renderer = renderer }

  struct DecorationOptions: OptionSet {
    let rawValue: UInt16

    static let IncludeFillShape = DecorationOptions(
      rawValue: 1 << 0) /* corresponds to 'bool fill'     */
    static let IncludeStrokeShape = DecorationOptions(
      rawValue: 1 << 1) /* corresponds to 'bool stroke'   */
    static let IncludeMarkers = DecorationOptions(
      rawValue: 1 << 2) /* corresponds to 'bool markers'  */
    static let IncludeClippers = DecorationOptions(
      rawValue: 1 << 3) /* corresponds to 'bool clippers' */
    static let IncludeMaskers = DecorationOptions(
      rawValue: 1 << 4) /* WebKit extension - internal    */
    static let IncludeOutline = DecorationOptions(
      rawValue: 1 << 5) /* WebKit extension - internal    */
    static let IgnoreTransformations = DecorationOptions(
      rawValue: 1 << 6) /* WebKit extension - internal    */
    static let OverrideBoxWithFilterBox = DecorationOptions(
      rawValue: 1 << 7) /* WebKit extension - internal    */
    static let OverrideBoxWithFilterBoxForChildren = DecorationOptions(
      rawValue: 1 << 8) /* WebKit extension - internal    */
    static let CalculateFastRepaintRect = DecorationOptions(
      rawValue: 1 << 9) /* WebKit extension - internal    */
    static let UseFilterBoxOnEmptyRect = DecorationOptions(
      rawValue: 1 << 10) /* WebKit extension - internal    */
  }

  static let objectBoundingBoxDecoration: DecorationOptions = [.IncludeFillShape]
  private static let filterBoundingBoxDecoration: DecorationOptions = [
    .OverrideBoxWithFilterBox, .OverrideBoxWithFilterBoxForChildren,
  ]
  private static let repaintBoundingBoxDecoration: DecorationOptions = [
    .IncludeFillShape, .IncludeStrokeShape, .IncludeMarkers, .IncludeClippers, .IncludeMaskers,
    .OverrideBoxWithFilterBox, .CalculateFastRepaintRect,
  ]

  func computeDecoratedBoundingBox(_ options: DecorationOptions, _ boundingBoxValid: inout Bool)
    -> FloatRectWrapper
  {
    // SVG2: Bounding boxes algorithm (https://svgwg.org/svg2-draft/coords.html#BoundingBoxes)

    // The following algorithm defines how to compute a bounding box for a given element. The inputs to the algorithm are:
    // - element, the element we are computing a bounding box for;
    // - space, a coordinate space in which the bounding box will be computed;
    // - fill, a boolean indicating whether the bounding box includes the geometry of the element and its descendants;
    // - stroke, a boolean indicating whether the bounding box includes the stroke of the element and its descendants;
    // - markers, a boolean indicating whether the bounding box includes the markers of the element and its descendants; and
    // - clipped, a boolean indicating whether the bounding box is affected by any clipping paths applied to the element and its descendants.

    // The algorithm to compute the bounding box is as follows, depending on the type of element:
    // - a shape (RenderSVGShape)
    // - a text content element (RenderSVGText or RenderSVGInline)
    // - an "a" element within a text content element (-> creates RenderSVGInline)
    if (renderer is RenderSVGShapeWrapper) || (renderer is RenderSVGTextWrapper)
      || (renderer is RenderSVGInlineWrapper)
    {
      return handleShapeOrTextOrInline(options, &boundingBoxValid)
    }

    // - a container element (RenderSVGRoot / RenderSVGContainer)
    // - "use" (RenderSVGTransformableContainer)
    if (renderer is RenderSVGRootWrapper) || (renderer is RenderSVGContainerWrapper) {
      return handleRootOrContainer(options, &boundingBoxValid)
    }

    // - "foreignObject"
    // - "image"
    if (renderer is RenderSVGForeignObjectWrapper) || (renderer is RenderSVGImageWrapper) {
      return handleForeignObjectOrImage(options, &boundingBoxValid)
    }

    fatalError("Not reached")
  }

  func computeDecoratedBoundingBox(_ options: DecorationOptions) -> FloatRectWrapper {
    var boundingBoxValid = false
    return computeDecoratedBoundingBox(options, &boundingBoxValid)
  }

  private static func computeDecoratedBoundingBox(
    _ renderer: RenderLayerModelObjectWrapper, _ options: DecorationOptions
  ) -> FloatRectWrapper {
    let boundingBoxComputation = SVGBoundingBoxComputation(renderer)
    return boundingBoxComputation.computeDecoratedBoundingBox(options)
  }

  static func computeRepaintBoundingBox(_ renderer: RenderLayerModelObjectWrapper)
    -> FloatRectWrapper
  {
    return computeDecoratedBoundingBox(renderer, repaintBoundingBoxDecoration)
  }

  static func computeVisualOverflowRect(_ renderer: RenderLayerModelObjectWrapper)
    -> LayoutRectWrapper
  {
    var options = repaintBoundingBoxDecoration.union([.IncludeOutline, .IgnoreTransformations])
    if renderer is RenderSVGContainerWrapper {
      options.update(with: .UseFilterBoxOnEmptyRect)
    }
    let repaintBoundingBoxWithoutTransformations = computeDecoratedBoundingBox(renderer, options)
    if repaintBoundingBoxWithoutTransformations.isEmpty() {
      return LayoutRectWrapper()
    }

    var visualOverflowRect = enclosingLayoutRect(rect: repaintBoundingBoxWithoutTransformations)
    visualOverflowRect.moveBy(offset: -renderer.nominalSVGLayoutLocation())
    return visualOverflowRect
  }

  private func handleShapeOrTextOrInline(
    _ options: DecorationOptions, _ boundingBoxValid: inout Bool
  ) -> FloatRectWrapper {
    // 1. Let box be a rectangle initialized to (0, 0, 0, 0).
    var box = FloatRectWrapper()

    // 2. Let fill-shape be the equivalent path of element if it is a shape, or a shape that includes each of the
    //    glyph cells corresponding to the text within the elements otherwise.
    // 3. If fill is true, then set box to the tightest rectangle in the coordinate system space that contains fill-shape.
    //
    // Note: The values of the fill, fill-opacity and fill-rule properties do not affect fill-shape.
    if options.contains(.IncludeFillShape) {
      box = renderer.objectBoundingBox()
    }

    // 4. If stroke is true and the element's stroke is anything other than none, then set box to be the union of box
    //    and the tightest rectangle in coordinate system space that contains the stroke shape of the element, with the
    //    assumption that the element has no dash pattern.
    //
    // Note: The values of the stroke-opacity, stroke-dasharray and stroke-dashoffset do not affect the calculation of the stroke shape.
    if options.contains(.IncludeStrokeShape) {
      if options.contains(.CalculateFastRepaintRect) && (renderer is RenderSVGShapeWrapper) {
        box.unite(other: (renderer as! RenderSVGShapeWrapper).approximateStrokeBoundingBox())
      } else {
        box.unite(other: renderer.strokeBoundingBox())
      }
    }

    // 5. If markers is true, then for each marker marker rendered on the element:
    // - For each descendant graphics element child of the "marker" element that defines marker's content:
    //   - If child has an ancestor element within the "marker" that is 'display: none', has a failing conditional processing attribute,
    //     or is not an "a", "g", "svg" or "switch" element, then continue to the next descendant graphics element.
    //   - Otherwise, set box to be the union of box and the result of invoking the algorithm to compute a bounding box with child as
    //     the element, space as the target coordinate space, true for fill, stroke and markers, and clipped for clipped.
    if options.contains(.IncludeMarkers), let svgPath = renderer as? RenderSVGPathWrapper {
      var optionsForMarker: DecorationOptions = [
        .IncludeFillShape, .IncludeStrokeShape, .IncludeMarkers,
      ]
      if options.contains(.IncludeClippers) {
        optionsForMarker.update(with: .IncludeClippers)
      }
      if options.contains(.CalculateFastRepaintRect) {
        optionsForMarker.update(with: .CalculateFastRepaintRect)
      }
      box.unite(other: svgPath.computeMarkerBoundingBox(optionsForMarker))
    }

    // 6. If clipped is true and the value of clip-path on element is not none, then set box to be the tightest rectangle
    //    in coordinate system space that contains the intersection of box and the clipping path.
    adjustBoxForClippingAndEffects(options, &box)

    // 7. Return box.
    boundingBoxValid = true
    return box
  }

  private func handleRootOrContainer(_ options: DecorationOptions, _ boundingBoxValid: inout Bool)
    -> FloatRectWrapper
  {
    let uniteBoundingBoxRespectingValidity = {
      (
        boxValid: inout Bool, box: inout FloatRectWrapper, child: RenderLayerModelObjectWrapper,
        childBoundingBox: FloatRectWrapper
      ) in
      let containerChild = child as? RenderSVGContainerWrapper
      let isBoundingBoxValid = containerChild?.isObjectBoundingBoxValid() ?? true
      if !isBoundingBoxValid {
        return
      }

      if boxValid {
        box.uniteEvenIfEmpty(other: childBoundingBox)
        return
      }

      box = childBoundingBox
      boxValid = true
    }

    // 1. Let box be a rectangle initialized to (0, 0, 0, 0).
    var box = FloatRectWrapper()
    var boxValid = false

    // 2. Let parent be the container element if it is one, or the root of the "use" element's shadow tree otherwise.

    // 3. For each descendant graphics element child of parent:
    //    - If child is not rendered then continue to the next descendant graphics element.
    //    - Otherwise, set box to be the union of box and the result of invoking the algorithm to compute a bounding box with child
    //      as the element and the same values for space, fill, stroke, markers and clipped as the corresponding algorithm input values.
    for child: RenderLayerModelObjectWrapper in childrenOfType(parent: renderer) {
      if child is RenderSVGHiddenContainerWrapper {
        continue
      }
      if let shape = child as? RenderSVGShapeWrapper, shape.isRenderingDisabled() {
        continue
      }

      let childBoundingBoxComputation = SVGBoundingBoxComputation(child)
      var childBox = childBoundingBoxComputation.computeDecoratedBoundingBox(options)
      if options.contains(.OverrideBoxWithFilterBoxForChildren)
        && (child is RenderSVGContainerWrapper)
      {
        var optionsForChild: DecorationOptions = [.OverrideBoxWithFilterBox]
        if options.contains(.CalculateFastRepaintRect) {
          optionsForChild.update(with: .CalculateFastRepaintRect)
        }
        childBoundingBoxComputation.adjustBoxForClippingAndEffects(optionsForChild, &childBox)
      }

      if !options.contains(.IgnoreTransformations),
        let transform = transformationMatrixFromChild(child)
      {
        childBox = transform.mapRect(rect: childBox)
      }

      if options == SVGBoundingBoxComputation.objectBoundingBoxDecoration {
        uniteBoundingBoxRespectingValidity(&boxValid, &box, child, childBox)
      } else {
        box.unite(other: childBox)
      }
    }

    // 4. If clipped is true:
    //    - If the value of clip-path on element is not none, then set box to be the tightest rectangle in coordinate system space that
    //      contains the intersection of box and the clipping path.
    //    - If the overflow property applies to the element and does not have a value of visible, then set box to be the tightest rectangle
    //      in coordinate system space that contains the intersection of box and the element's overflow bounds.
    //    - If the clip property applies to the element and does not have a value of auto, then set box to be the tightest rectangle in coordinate
    //      system space that contains the intersection of box and the rectangle specified by clip. (TODO!)
    adjustBoxForClippingAndEffects(options, &box, [.OverrideBoxWithFilterBox])

    if options.contains(.IncludeClippers) && renderer.hasNonVisibleOverflow() {
      assert(renderer.hasLayer())

      assert(
        (renderer is RenderSVGViewportContainerWrapper)
          || (renderer is RenderSVGResourceMarkerWrapper) || (renderer is RenderSVGRootWrapper))

      var overflowClipRect = LayoutRectWrapper()
      if let svgModelObject = renderer as? RenderSVGModelObjectWrapper {
        overflowClipRect = svgModelObject.overflowClipRect(
          location: svgModelObject.currentSVGLayoutLocation())
      } else if let box = renderer as? RenderBoxWrapper {
        overflowClipRect = box.overflowClipRect(location: box.location())
      } else {
        fatalError("Not reached")
      }

      box.intersect(other: overflowClipRect.FloatRect())
    }

    // 5. Return box.
    boundingBoxValid = boxValid
    return box
  }

  private func transformationMatrixFromChild(_ child: RenderLayerModelObjectWrapper)
    -> AffineTransform?
  {
    if !child.isTransformed() || !child.hasLayer() {
      return nil
    }

    assert(child.isSVGLayerAwareRenderer())
    assert(!child.isRenderSVGRoot())

    let transform = SVGLayerTransformComputation(child).computeAccumulatedTransform(
      renderer, .TrackSVGCTMMatrix)
    return transform.isIdentity() ? nil : transform
  }

  private func handleForeignObjectOrImage(
    _ options: DecorationOptions, _ boundingBoxValid: inout Bool
  ) -> FloatRectWrapper {
    // 1. Let box be the tightest rectangle in coordinate space space that contains the positioning rectangle
    //    defined by the "x", "y", "width" and "height" geometric properties of the element.
    //
    // Note: The fill, stroke and markers input arguments to this algorithm do not affect the bounding box returned for these elements.
    var box = renderer.objectBoundingBox()

    // 2. If clipped is true and the value of clip-path on element is not none, then set box to be the tightest rectangle
    //    in coordinate system space that contains the intersection of box and the clipping path.
    adjustBoxForClippingAndEffects(options, &box)

    // 3. Return box.
    boundingBoxValid = true
    return box
  }

  private func adjustBoxForClippingAndEffects(
    _ options: DecorationOptions, _ box: inout FloatRectWrapper,
    _ optionsToCheckForFilters: DecorationOptions = SVGBoundingBoxComputation
      .filterBoundingBoxDecoration
  ) {
    let includeFilter = !options.isDisjoint(with: optionsToCheckForFilters)

    if includeFilter, let referencedFilterRenderer = renderer.svgFilterResourceFromStyle() {
      let repaintRectCalculation: RepaintRectCalculation =
        options.contains(.CalculateFastRepaintRect) ? .Fast : .Accurate

      let resourceRect = referencedFilterRenderer.resourceBoundingBox(
        renderer, repaintRectCalculation)
      if box.isEmpty() && options.contains(.UseFilterBoxOnEmptyRect) {
        box = resourceRect
      } else {
        box.intersect(other: resourceRect)
      }
    }

    if options.contains(.IncludeClippers),
      let referencedClipperRenderer = renderer.svgClipperResourceFromStyle()
    {
      let repaintRectCalculation: RepaintRectCalculation =
        options.contains(.CalculateFastRepaintRect) ? .Fast : .Accurate
      box.intersect(
        other: referencedClipperRenderer.resourceBoundingBox(renderer, repaintRectCalculation))
    }

    if options.contains(.IncludeMaskers),
      let referencedMaskerRenderer = renderer.svgMaskerResourceFromStyle()
    {
      // When masks are nested, the inner masks do not affect the outer mask dimension, so skip the computation for inner masks.
      SVGBoundingBoxComputation.s_maskBoundingBoxNestingLevel += 1
      defer {
        SVGBoundingBoxComputation.s_maskBoundingBoxNestingLevel -= 1
      }
      if SVGBoundingBoxComputation.s_maskBoundingBoxNestingLevel < 2 {
        let repaintRectCalculation: RepaintRectCalculation =
          options.contains(.CalculateFastRepaintRect) ? .Fast : .Accurate
        box.intersect(
          other: referencedMaskerRenderer.resourceBoundingBox(renderer, repaintRectCalculation))
      }
    }

    if options.contains(.IncludeOutline) {
      box.inflate(d: renderer.outlineStyleForRepaint().outlineSize())
    }
  }

  private let renderer: RenderLayerModelObjectWrapper
  private static var s_maskBoundingBoxNestingLevel: UInt32 = 0
}
