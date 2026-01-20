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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private let renderer: RenderLayerModelObjectWrapper
}
