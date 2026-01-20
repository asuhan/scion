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
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeDecoratedBoundingBox(_ options: DecorationOptions) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let renderer: RenderLayerModelObjectWrapper
}
