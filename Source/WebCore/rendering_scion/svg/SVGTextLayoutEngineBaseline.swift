/*
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 * Copyright (C) 2023 Apple Inc. All rights reserved.
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

// Helper class used by SVGTextLayoutEngine to handle 'alignment-baseline' / 'dominant-baseline' and 'baseline-shift'.
struct SVGTextLayoutEngineBaseline {
  init(_ font: FontCascadeWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func calculateBaselineShift(_ style: SVGRenderStyle, _ context: SVGElementWrapper?) -> Float32 {
    if style.baselineShift() == .Length {
      let baselineShiftValueLength = style.baselineShiftValue()
      if baselineShiftValueLength.lengthType == .Percentage {
        return baselineShiftValueLength.valueAsPercentage() * font.size()
      }

      let lengthContext = SVGLengthContext(context: context)
      return baselineShiftValueLength.value(lengthContext)
    }

    switch style.baselineShift() {
    case .Baseline:
      return 0
    case .Sub:
      return -font.metricsOfPrimaryFont().height() / 2
    case .Super:
      return font.metricsOfPrimaryFont().height() / 2
    case .Length:
      fatalError("Not reached")
    }
  }

  func calculateAlignmentBaselineShift(_ isVerticalText: Bool, _ textRenderer: RenderObjectWrapper)
    -> Float32
  {
    let textRendererParent = textRenderer.parent()!

    var baseline = textRenderer.style().svgStyle().alignmentBaseline()
    if baseline == .Baseline {
      baseline = dominantBaselineToAlignmentBaseline(isVerticalText, textRendererParent)
      assert(baseline != .Baseline)
    }

    let fontMetrics = font.metricsOfPrimaryFont()
    let ascent = fontMetrics.ascent()
    let descent = fontMetrics.descent()

    // Note: http://wiki.apache.org/xmlgraphics-fop/LineLayout/AlignmentHandling
    switch baseline {
    case .BeforeEdge, .TextBeforeEdge:
      return ascent
    case .Middle:
      return (fontMetrics.xHeight() ?? 0) / 2
    case .Central:
      return (ascent - descent) / 2
    case .AfterEdge, .TextAfterEdge, .Ideographic:
      return -descent
    case .Alphabetic:
      return 0
    case .Hanging:
      return ascent * 8 / 10
    case .Mathematical:
      return ascent / 2
    case .Baseline:
      fatalError("Not reached")
    }
  }

  func calculateGlyphOrientationAngle(
    _ isVerticalText: Bool, _ style: SVGRenderStyle, _ character: UChar
  ) -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct GlyphAdvanceAndOrientation {
    let advance: Float32
    let xOrientationShift: Float32
    let yOrientationShift: Float32
  }

  func calculateGlyphAdvanceAndOrientation(
    _ isVerticalText: Bool, _ metrics: SVGTextMetrics, _ angle: Float32
  ) -> GlyphAdvanceAndOrientation {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func dominantBaselineToAlignmentBaseline(
    _ isVerticalText: Bool, _ textRenderer: RenderObjectWrapper
  ) -> AlignmentBaseline {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private let font: FontCascadeWrapper
}
