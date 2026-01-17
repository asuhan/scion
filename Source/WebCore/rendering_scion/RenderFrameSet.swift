/**
 * Copyright (C) 1999 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Simon Hausmann <hausmann@kde.org>
 *           (C) 2000 Stefan Schimanski (1Stein@gmx.de)
 * Copyright (C) 2004, 2005, 2006, 2008, 2013 Apple Inc.
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

private let borderStartEdgeColor = SRGBA<UInt8>(red: 170, green: 170, blue: 170)
private let borderEndEdgeColor = ColorWrapper.black
private let borderFillColor = SRGBA<UInt8>(red: 208, green: 208, blue: 208)

final class RenderFrameSetWrapper: RenderBoxWrapper {
  func frameSetElement() -> HTMLFrameSetElementWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private static let noSplit: Int32 = -1

  private struct GridAxis: ~Copyable {
    init() {
      splitBeingResized = noSplit
    }

    let sizes: [Int32] = []
    let allowBorder: [Bool] = []
    let splitBeingResized: Int32
  }

  override func layout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func paint(paintInfo: inout PaintInfoWrapper, paintOffset: LayoutPointWrapper) {
    if paintInfo.phase != .Foreground {
      return
    }

    var child = firstChild()
    if child == nil {
      return
    }

    let adjustedPaintOffset = paintOffset + location()

    let rows = m_rows.sizes.count
    let cols = m_cols.sizes.count
    let borderThickness = LayoutUnit(value: frameSetElement().border())

    var yPos = LayoutUnit()
    for r in 0..<rows {
      var xPos = LayoutUnit()
      for c in 0..<cols {
        (child as! RenderElementWrapper).paint(
          paintInfo: &paintInfo, paintOffset: adjustedPaintOffset)
        xPos += m_cols.sizes[c]
        if borderThickness.bool() && m_cols.allowBorder[c + 1] {
          paintColumnBorder(
            paintInfo,
            snappedIntRect(
              rect: LayoutRectWrapper(
                x: adjustedPaintOffset.x + xPos, y: adjustedPaintOffset.y + yPos,
                width: borderThickness,
                height: height())))
          xPos += borderThickness
        }
        child = child!.nextSibling()
        if child == nil {
          return
        }
      }
      yPos += m_rows.sizes[r]
      if borderThickness.bool() && m_rows.allowBorder[r + 1] {
        paintRowBorder(
          paintInfo,
          snappedIntRect(
            rect: LayoutRectWrapper(
              x: adjustedPaintOffset.x, y: adjustedPaintOffset.y + yPos, width: width(),
              height: borderThickness)))
        yPos += borderThickness
      }
    }
  }

  private func paintRowBorder(_ paintInfo: PaintInfoWrapper, _ borderRect: IntRect) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func paintColumnBorder(_ paintInfo: PaintInfoWrapper, _ borderRect: IntRect) {
    if !paintInfo.rect.intersects(other: LayoutRectWrapper(rect: borderRect)) {
      return
    }

    // FIXME: We should do something clever when borders from distinct framesets meet at a join.

    // Fill first.
    let context = paintInfo.context()
    context.fillRect(
      rect: FloatRectWrapper(r: borderRect),
      color: frameSetElement().hasBorderColor()
        ? style().visitedDependentColorWithColorFilter(colorProperty: .CSSPropertyBorderLeftColor)
        : ColorWrapper(borderFillColor))

    // Now stroke the edges but only if we have enough room to paint both edges with a little
    // bit of the fill color showing through.
    if borderRect.width() >= 3 {
      context.fillRect(
        rect: FloatRectWrapper(
          r: IntRect(location: borderRect.location, size: IntSize(width: 1, height: height().int()))
        ),
        color: ColorWrapper(borderStartEdgeColor))
      context.fillRect(
        rect: FloatRectWrapper(
          r: IntRect(
            location: IntPoint(x: borderRect.maxX() - 1, y: borderRect.y()),
            size: IntSize(width: 1, height: height().int()))),
        color: borderEndEdgeColor)
    }
  }

  private let m_rows = GridAxis()
  private let m_cols = GridAxis()
}
