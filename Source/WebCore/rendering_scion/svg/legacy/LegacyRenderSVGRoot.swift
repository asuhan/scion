/*
 * Copyright (C) 2004, 2005, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2007, 2008, 2009 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009-2023 Google, Inc.
 * Copyright (C) 2009 Apple Inc. All rights reserved.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
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

final class LegacyRenderSVGRootWrapper: RenderReplacedWrapper {
  private func svgSVGElement() -> SVGSVGElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeIntrinsicRatioInformation() -> (FloatSize, FloatSize) {
    assert(!shouldApplySizeContainment())

    // https://www.w3.org/TR/SVG/coords.html#IntrinsicSizing
    let intrinsicSize = calculateIntrinsicSize()

    if style().aspectRatioType() == .Ratio {
      let intrinsicRatio = FloatSize.narrowPrecision(
        width: style().aspectRatioLogicalWidth(), height: style().aspectRatioLogicalHeight())
      return (intrinsicSize, intrinsicRatio)
    }

    var intrinsicRatioValue: FloatSize? = nil
    var intrinsicRatio = FloatSize()
    if !intrinsicSize.isEmpty() {
      intrinsicRatio = FloatSize(width: intrinsicSize.width, height: intrinsicSize.height)
    } else {
      let viewBoxSize = svgSVGElement().viewBox().size()
      if !viewBoxSize.isEmpty() {
        // The viewBox can only yield an intrinsic ratio, not an intrinsic size.
        intrinsicRatioValue = FloatSize(width: viewBoxSize.width, height: viewBoxSize.height)
      }
    }

    if intrinsicRatioValue != nil {
      intrinsicRatio = intrinsicRatioValue!
    } else if style().aspectRatioType() == .AutoAndRatio {
      intrinsicRatio = FloatSize.narrowPrecision(
        width: style().aspectRatioLogicalWidth(), height: style().aspectRatioLogicalHeight())
    }
    return (intrinsicSize, intrinsicRatio)
  }

  override final func hasIntrinsicAspectRatio() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func setNeedsTransformUpdate() { needsBoundariesOrTransformUpdate = true }

  override final func computeReplacedLogicalWidth(
    shouldComputePreferred: ShouldComputePreferred = .ComputeActual
  )
    -> LayoutUnit
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeReplacedLogicalHeight(estimatedUsedWidth: LayoutUnit? = nil) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func paintReplaced(
    _ paintInfo: inout PaintInfoWrapper, _ paintOffset: LayoutPointWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func localToParentTransform() -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func repaintRectInLocalCoordinates(
    _ repaintRectCalculation: RepaintRectCalculation = .Fast
  ) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func clippedOverflowRect(
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

  override func mapLocalToContainer(
    _ ancestorContainer: RenderLayerModelObjectWrapper?, _ transformState: TransformState,
    _ mode: MapCoordinatesMode, _ wasFixed: inout Bool?
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func pushMappingToContainer(
    _ ancestorToStopAt: RenderLayerModelObjectWrapper?, _ geometryMap: RenderGeometryMap
  ) -> RenderObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func canBeSelectionLeaf() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func calculateIntrinsicSize() -> FloatSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let isLayoutSizeChanged = false
  private var needsBoundariesOrTransformUpdate = false
}
