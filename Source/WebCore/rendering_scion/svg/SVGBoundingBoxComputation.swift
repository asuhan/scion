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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    adjustBoxForClippingAndEffects(options, box)

    // 7. Return box.
    boundingBoxValid = true
    return box
  }

  private func handleRootOrContainer(_ options: DecorationOptions, _ boundingBoxValid: inout Bool)
    -> FloatRectWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func handleForeignObjectOrImage(
    _ options: DecorationOptions, _ boundingBoxValid: inout Bool
  ) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func adjustBoxForClippingAndEffects(
    _ options: DecorationOptions, _ box: FloatRectWrapper,
    _ optionsToCheckForFilters: DecorationOptions = SVGBoundingBoxComputation
      .filterBoundingBoxDecoration
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let renderer: RenderLayerModelObjectWrapper
}
