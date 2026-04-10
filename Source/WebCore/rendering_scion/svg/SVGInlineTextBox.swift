/**
 * Copyright (C) 2007 Rob Buis <buis@kde.org>
 * Copyright (C) 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 * Copyright (C) 2023-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2014-2016 Google Inc. All rights reserved.
 * Copyright (C) 2023, 2024 Igalia S.L.
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

final class SVGInlineTextBox: LegacyInlineTextBox {
  init(_ renderer: RenderSVGInlineTextWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func textRenderer() -> RenderSVGInlineTextWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override final func virtualLogicalHeight() -> Float32 { return logicalHeight }

  func paintSelectionBackground(_ paintInfo: PaintInfoWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paint(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, lineTop: LayoutUnit,
    lineBottom: LayoutUnit
  ) {
    let painter = LegacySVGTextBoxPainter(self, paintInfo, paintOffset)
    painter.paint()
  }

  func setLogicalHeight(_ height: Float32) { logicalHeight = height }

  func calculateBoundaries() -> FloatRectWrapper {
    var textRect = FloatRectWrapper()

    let scalingFactor = textRenderer().scalingFactor()
    assert(scalingFactor != 0)

    let baseline = textRenderer().scaledFont().metricsOfPrimaryFont().ascent() / scalingFactor

    var fragmentTransform = AffineTransform()
    for fragment in textFragments {
      var fragmentRect = FloatRectWrapper(
        x: fragment.x, y: fragment.y - baseline, width: fragment.width, height: fragment.height)
      fragment.buildFragmentTransform(&fragmentTransform)
      if !fragmentTransform.isIdentity() {
        fragmentRect = fragmentTransform.mapRect(rect: fragmentRect)
      }

      textRect.unite(other: fragmentRect)
    }

    return textRect
  }

  func setTextFragments(_ fragments: [SVGTextFragment]) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func dirtyLineBoxes() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func offsetForPositionInFragment(_ fragment: SVGTextFragment, _ position: Float32) -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var logicalHeight: Float32 = 0

  private let textFragments: [SVGTextFragment]
}
