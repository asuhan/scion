/*
 * Copyright (C) 2004, 2005, 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2004, 2005, 2007, 2008, 2009 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009-2023 Google, Inc.
 * Copyright (C) Research In Motion Limited 2011. All rights reserved.
 * Copyright (C) 2020, 2021, 2022, 2023, 2024 Igalia S.L.
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

final class RenderSVGRootWrapper: RenderReplacedWrapper {
  func svgSVGElement() -> SVGSVGElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isEmbeddedThroughFrameContainingSVGDocument() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func computeIntrinsicRatioInformation() -> (FloatSize, FloatSize) {
    assert(!shouldApplySizeContainment())

    // https://www.w3.org/TR/SVG/coords.html#IntrinsicSizing
    let intrinsicSize = calculateIntrinsicSize()
    var intrinsicRatio = FloatSize()

    if style().aspectRatioType() == .Ratio {
      intrinsicRatio = FloatSize.narrowPrecision(
        width: style().aspectRatioLogicalWidth(), height: style().aspectRatioLogicalHeight())
      return (intrinsicSize, intrinsicRatio)
    }

    var intrinsicRatioValue: LayoutSizeWrapper? = nil
    if !intrinsicSize.isEmpty() {
      intrinsicRatioValue = LayoutSizeWrapper(
        width: intrinsicSize.width, height: intrinsicSize.height)
    } else {
      let viewBoxSize = svgSVGElement().viewBox().size()
      if !viewBoxSize.isEmpty() {
        // The viewBox can only yield an intrinsic ratio, not an intrinsic size.
        intrinsicRatioValue = LayoutSizeWrapper(
          width: viewBoxSize.width, height: viewBoxSize.height)
      }
    }

    if intrinsicRatioValue != nil {
      intrinsicRatio = intrinsicRatioValue!.FloatSize()
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

  func shouldApplyViewportClip() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func viewportContainer() -> RenderSVGViewportContainerWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func requiresLayer() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func computeReplacedLogicalWidth(
    shouldComputePreferred: ShouldComputePreferred = .ComputeActual
  )
    -> LayoutUnit
  {
    // When we're embedded through SVGImage (border-image/background-image/<html:img>/...) we're forced to resize to a specific size.
    if !containerSize.isEmpty() {
      return LayoutUnit(value: containerSize.width)
    }

    if isEmbeddedThroughFrameContainingSVGDocument() {
      return containingBlock()!.availableLogicalWidth()
    }

    // Standalone SVG / SVG embedded via SVGImage (background-image/border-image/etc) / Inline SVG.
    var result = super.computeReplacedLogicalWidth(shouldComputePreferred: shouldComputePreferred)
    if svgSVGElement().hasIntrinsicWidth() {
      return result
    }

    // Percentage units are not scaled, Length(100, %) resolves to 100% of the unzoomed RenderView content size.
    // However for SVGs purposes we need to always include zoom in the RenderSVGRoot boundaries.
    result *= style().usedZoom()
    return result
  }

  override func computeReplacedLogicalHeight(estimatedUsedWidth: LayoutUnit? = nil) -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func updateLayerTransform() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func calculateIntrinsicSize() -> FloatSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let didTransformToRootUpdate = false
  let isLayoutSizeChanged = false

  let containerSize = IntSize()
}
