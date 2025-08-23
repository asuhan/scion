/*
 * Copyright (C) 2024 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 * 1. Redistributions of source code must retain the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer.
 * 2. Redistributions in binary form must reproduce the above
 *    copyright notice, this list of conditions and the following
 *    disclaimer in the documentation and/or other materials
 *    provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDER "AS IS" AND ANY
 * EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER BE
 * LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY,
 * OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 * PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
 * TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
 * THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 */

private func calcRadiiFor(radii: BorderData.Radii, size: LayoutSizeWrapper) -> RoundedRect.Radii {
  // TODO(asuhan): implement this
  fatalError("Not implemented")
}

private func addRoundedRectToPath(roundedRect: FloatRoundedRect, path: inout PathWrapper) {
  if roundedRect.isRounded() {
    path.addRoundedRect(roundedRect: roundedRect)
  } else {
    path.addRect(rect: roundedRect.rect())
  }
}

// BorderShape is used to fill and clip to the shape formed by the border and padding boxes with border-radius.
// In future, this may be a more complex shape than a rounded rect, so accessors that return rounded rects
// are deprecated.
struct BorderShape {
  static func shapeForBorderRect(
    style: RenderStyleWrapper, borderRect: LayoutRectWrapper, includeLogicalLeftEdge: Bool = true,
    includeLogicalRightEdge: Bool = true
  ) -> BorderShape {
    let borderWidths = RectEdges<LayoutUnit>(
      top: LayoutUnit(value: style.borderTopWidth()),
      right: LayoutUnit(value: style.borderRightWidth()),
      bottom: LayoutUnit(value: style.borderBottomWidth()),
      left: LayoutUnit(value: style.borderLeftWidth()))
    return shapeForBorderRect(
      style: style, borderRect: borderRect, overrideBorderWidths: borderWidths,
      includeLogicalLeftEdge: includeLogicalLeftEdge,
      includeLogicalRightEdge: includeLogicalRightEdge)
  }

  // overrideBorderWidths describe custom insets from the border box, used instead of the border widths from the style.
  static func shapeForBorderRect(
    style: RenderStyleWrapper, borderRect: LayoutRectWrapper,
    overrideBorderWidths: RectEdges<LayoutUnit>, includeLogicalLeftEdge: Bool = true,
    includeLogicalRightEdge: Bool = true
  ) -> BorderShape {
    let isHorizontal = style.isHorizontalWritingMode()

    // top, right, bottom, left.
    let usedBorderWidths = RectEdges<LayoutUnit>(
      top: (isHorizontal || includeLogicalLeftEdge)
        ? overrideBorderWidths.top : LayoutUnit(value: 0),
      right: (!isHorizontal || includeLogicalRightEdge)
        ? overrideBorderWidths.right : LayoutUnit(value: 0),
      bottom: (isHorizontal || includeLogicalRightEdge)
        ? overrideBorderWidths.bottom : LayoutUnit(value: 0),
      left: (!isHorizontal || includeLogicalLeftEdge)
        ? overrideBorderWidths.left : LayoutUnit(value: 0)
    )

    if style.hasBorderRadius() {
      var radii = calcRadiiFor(radii: style.borderRadii(), size: borderRect.size())
      radii.scale(
        factor: calcBorderRadiiConstraintScaleFor(
          rect: borderRect.FloatRect(), radii: FloatRoundedRect.Radii(intRadii: radii)))

      if !includeLogicalLeftEdge {
        radii.topLeft = LayoutSizeWrapper()

        if isHorizontal {
          radii.bottomLeft = LayoutSizeWrapper()
        } else {
          radii.topRight = LayoutSizeWrapper()
        }
      }

      if !includeLogicalRightEdge {
        radii.bottomRight = LayoutSizeWrapper()

        if isHorizontal {
          radii.topRight = LayoutSizeWrapper()
        } else {
          radii.bottomLeft = LayoutSizeWrapper()
        }
      }

      if !radii.areRenderableInRect(rect: borderRect) {
        radii.makeRenderableInRect(rect: borderRect)
      }

      return BorderShape(borderRect: borderRect, borderWidths: usedBorderWidths, radii: radii)
    }

    return BorderShape(borderRect: borderRect, borderWidths: usedBorderWidths)
  }

  init(borderRect: LayoutRectWrapper, borderWidths: RectEdges<LayoutUnit>) {
    self.m_borderRect = RoundedRect(rect: borderRect)
    self.borderWidths = borderWidths
  }

  init(borderRect: LayoutRectWrapper, borderWidths: RectEdges<LayoutUnit>, radii: RoundedRectRadii)
  {
    self.m_borderRect = RoundedRect(rect: borderRect, radii: radii)
    self.borderWidths = borderWidths
    // The caller should have adjusted the radii already.
    assert(m_borderRect.isRenderable())
  }

  func borderRect() -> LayoutRectWrapper { return m_borderRect.rect }

  func deprecatedRoundedRect() -> RoundedRect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func deprecatedInnerRoundedRect() -> RoundedRect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outerShapeContains(rect: LayoutRectWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func radii() -> RoundedRectRadii {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func setRadii(radii: RoundedRectRadii) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func snappedOuterRect(deviceScaleFactor: Float32) -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isEmpty() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func move(offset: LayoutSizeWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // This will inflate the m_borderRect, and scale the radii up accordingly. Note that this changes the meaning of "inner shape" which will no longer correspond to the padding box.
  mutating func inflate(amount: LayoutUnit) {
    m_borderRect.inflateWithRadii(amount: amount)
  }

  func pathForBorderArea(deviceScaleFactor: Float32) -> PathWrapper {
    let pixelSnappedOuterRect = m_borderRect.pixelSnappedRoundedRectForPainting(
      deviceScaleFactor: deviceScaleFactor)
    let pixelSnappedInnerRect = innerEdgeRoundedRect().pixelSnappedRoundedRectForPainting(
      deviceScaleFactor: deviceScaleFactor)

    assert(pixelSnappedInnerRect.isRenderable())

    var path = PathWrapper()
    addRoundedRectToPath(roundedRect: pixelSnappedOuterRect, path: &path)
    addRoundedRectToPath(roundedRect: pixelSnappedInnerRect, path: &path)
    return path
  }

  func clipToOuterShape(context: GraphicsContextWrapper, deviceScaleFactor: Float32) {
    let pixelSnappedRect = m_borderRect.pixelSnappedRoundedRectForPainting(
      deviceScaleFactor: deviceScaleFactor)
    if pixelSnappedRect.isRounded() {
      context.clipRoundedRect(rect: pixelSnappedRect)
    } else {
      context.clip(rect: pixelSnappedRect.rect())
    }
  }

  func clipToInnerShape(context: GraphicsContextWrapper, deviceScaleFactor: Float32) {
    let pixelSnappedRect = innerEdgeRoundedRect().pixelSnappedRoundedRectForPainting(
      deviceScaleFactor: deviceScaleFactor)
    assert(pixelSnappedRect.isRenderable())
    if pixelSnappedRect.isRounded() {
      context.clipRoundedRect(rect: pixelSnappedRect)
    } else {
      context.clip(rect: pixelSnappedRect.rect())
    }
  }

  func clipOutOuterShape(context: GraphicsContextWrapper, deviceScaleFactor: Float32) {
    let pixelSnappedRect = m_borderRect.pixelSnappedRoundedRectForPainting(
      deviceScaleFactor: deviceScaleFactor)
    if pixelSnappedRect.isEmpty() {
      return
    }

    if pixelSnappedRect.isRounded() {
      context.clipOutRoundedRect(rect: pixelSnappedRect)
    } else {
      context.clipOut(rect: pixelSnappedRect.rect())
    }
  }

  func fillOuterShape(
    context: GraphicsContextWrapper, color: ColorWrapper, deviceScaleFactor: Float32
  ) {
    let pixelSnappedRect = m_borderRect.pixelSnappedRoundedRectForPainting(
      deviceScaleFactor: deviceScaleFactor)
    if pixelSnappedRect.isRounded() {
      context.fillRoundedRect(rect: pixelSnappedRect, color: color)
    } else {
      context.fillRect(rect: pixelSnappedRect.rect(), color: color)
    }
  }

  func fillInnerShape(
    context: GraphicsContextWrapper, color: ColorWrapper, deviceScaleFactor: Float32
  ) {
    let pixelSnappedRect = innerEdgeRoundedRect().pixelSnappedRoundedRectForPainting(
      deviceScaleFactor: deviceScaleFactor)
    assert(pixelSnappedRect.isRenderable())
    if pixelSnappedRect.isRounded() {
      context.fillRoundedRect(rect: pixelSnappedRect, color: color)
    } else {
      context.fillRect(rect: pixelSnappedRect.rect(), color: color)
    }
  }

  private func innerEdgeRoundedRect() -> RoundedRect {
    var roundedRect = RoundedRect(rect: innerEdgeRect())
    if m_borderRect.isRounded() {
      let innerRadii = m_borderRect.radii
      innerRadii.shrink(
        topWidth: borderWidths.top, bottomWidth: borderWidths.bottom,
        leftWidth: borderWidths.left, rightWidth: borderWidths.right)
      roundedRect.radii = innerRadii
    }

    if !roundedRect.isRenderable() {
      roundedRect.adjustRadii()
    }

    return roundedRect
  }

  private func innerEdgeRect() -> LayoutRectWrapper {
    let borderRect = m_borderRect.rect
    let width = max(
      LayoutUnit(value: 0), borderRect.width() - borderWidths.left - borderWidths.right)
    let height = max(
      LayoutUnit(value: 0), borderRect.height() - borderWidths.top - borderWidths.bottom)
    return LayoutRectWrapper(
      x: borderRect.x() + borderWidths.left,
      y: borderRect.y() + borderWidths.top,
      width: width,
      height: height
    )
  }

  private let m_borderRect: RoundedRect
  private let borderWidths: RectEdges<LayoutUnit>
}
