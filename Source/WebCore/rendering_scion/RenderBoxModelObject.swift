/*
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 1999 Antti Koivisto (koivisto@kde.org)
 * Copyright (C) 2003-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2010-2018 Google Inc. All rights reserved.
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
 *
 */

import wk_interop

// Modes for some of the line-related functions.
enum LinePositionMode: UInt8 {
  case PositionOnContainingLine
  case PositionOfInteriorLineBoxes
}

enum LineDirectionMode: UInt8 {
  case HorizontalLine
  case VerticalLine
}

enum BackgroundBleedAvoidance {
  case BackgroundBleedNone
  case BackgroundBleedShrinkBackground
  case BackgroundBleedUseTransparencyLayer
  case BackgroundBleedBackgroundOverBorder
}

enum BaseBackgroundColorUsage {
  case BaseBackgroundColorUse
  case BaseBackgroundColorOnly
  case BaseBackgroundColorSkip
}

class RenderBoxModelObjectWrapper: RenderLayerModelObjectWrapper {
  // These functions are used during layout. Table cells and the MathML
  // code override them to include some extra intrinsic padding.
  func padding() -> RectEdges<LayoutUnit> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingBottom() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingLeft() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingRight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingStart() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBoxModelObject_paddingStart(p))
  }

  func paddingEnd() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBoxModelObject_paddingEnd(p))
  }

  func borderWidths() -> RectEdges<LayoutUnit> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderBottom() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderLeft() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderRight() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderStart() -> LayoutUnit {
    return LayoutUnit.fromRawValue(value: wk_interop.RenderBoxModelObject_borderStart(p))
  }

  func borderAndPaddingBefore() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginTop() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginLeft() -> LayoutUnit {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginStart(otherStyle: RenderStyleWrapper? = nil) -> LayoutUnit {
    return LayoutUnit.fromRawValue(
      value: wk_interop.RenderBoxModelObject_marginStart(p, otherStyle?.p))
  }

  func borderShapeForContentClipping(
    borderBoxRect: LayoutRectWrapper, includeLeftEdge: Bool = true, includeRightEdge: Bool = true
  ) -> BorderShape {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func baselinePosition(
    baselineType: FontBaseline, firstLine: Bool, direction: LineDirectionMode,
    linePositionMode: LinePositionMode = .PositionOnContainingLine
  ) -> LayoutUnit {
    return LayoutUnit.fromRawValue(
      value: wk_interop.RenderBoxModelObject_baselinePosition(
        p, baselineType.rawValue, firstLine, direction.rawValue, linePositionMode.rawValue))
  }

  func continuation() -> RenderBoxModelObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func inlineContinuation() -> RenderInlineWrapper? {
    if let raw = wk_interop.RenderBoxModelObject_inlineContinuation(p) {
      return RenderInlineWrapper(p: raw)
    }
    return nil
  }

  func fixedBackgroundPaintsInLocalCoordinates() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func chooseInterpolationQuality(
    context: GraphicsContextWrapper, image: ImageWrapper, layer: FillLayerWrapper,
    size: LayoutSizeWrapper
  ) -> InterpolationQuality {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func decodingModeForImageDraw(image: ImageWrapper, paintInfo: PaintInfoWrapper) -> DecodingMode {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintMaskForTextFillBox(
    context: GraphicsContextWrapper, paintRect: FloatRectWrapper,
    inlineBox: InlineIterator.InlineBoxIterator, scrolledPaintRect: LayoutRectWrapper
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFirstLetterRemainingText(remainingText: RenderTextFragmentWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum ScaleByUsedZoom {
    case No
    case Yes
  }

  func calculateImageIntrinsicDimensions(
    image: StyleImage, positioningAreaSize: LayoutSizeWrapper, scaleByUsedZoom: ScaleByUsedZoom
  )
    -> LayoutSizeWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
