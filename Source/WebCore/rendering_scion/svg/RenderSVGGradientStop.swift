/*
 * Copyright (C) 2007 Eric Seidel <eric@webkit.org>
 * Copyright (C) 2009 Google, Inc.
 * Copyright (C) 2014 Apple Inc. All rights reserved.
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

// This class exists mostly so we can hear about gradient stop style changes
final class RenderSVGGradientStopWrapper: RenderElementWrapper {
  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)
    if diff == .Equal {
      return
    }

    // <stop> elements should only be allowed to make renderers under gradient elements
    // but I can imagine a few cases we might not be catching, so let's not crash if our parent isn't a gradient.
    guard let gradient = gradientElement() else { return }

    guard let renderer = gradient.renderer() else { return }

    if let gradientRenderer = renderer as? RenderSVGResourceGradient {
      gradientRenderer.invalidateGradient()
      return
    }

    (renderer as! LegacyRenderSVGResourceContainer).removeAllClientsFromCache()
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func localRectsForRepaint(_ repaintOutlineBounds: RepaintOutlineBounds) -> RepaintRects {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func objectBoundingBox() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func repaintRectInLocalCoordinates(
    _ repaintRectCalculation: RepaintRectCalculation = .Fast
  ) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func canHaveChildren() -> Bool {
    assert(isNativeImpl())
    return false
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {}

  private func gradientElement() -> SVGGradientElementWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}
