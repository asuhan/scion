/*
 * Copyright (C) 2003, 2004, 2005, 2006, 2007 Apple Inc. All rights reserved.
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

// LegacyInlineBox represents a rectangle that occurs on a line. It corresponds to
// some RenderObject (i.e., it represents a portion of that RenderObject).
class LegacyInlineBox {
  init(_ renderer: RenderObjectWrapper) {
    self.renderer = renderer
  }

  func isLineBreak() -> Bool { return renderer.isRenderLineBreak() }

  func adjustPosition(_ dx: Float32, _ dy: Float32) { m_topLeft.move(dx: dx, dy: dy) }

  func paint(
    paintInfo: PaintInfoWrapper, paintOffset: LayoutPointWrapper, lineTop: LayoutUnit,
    lineBottom: LayoutUnit
  ) {
    fatalError("Not reached")
  }

  func isInlineFlowBox() -> Bool { return false }

  private func hasVirtualLogicalHeight() -> Bool { return m_bitfields.hasVirtualLogicalHeight }

  func virtualLogicalHeight() -> Float32 { fatalError("Not reached") }

  func isHorizontal() -> Bool { return m_bitfields.isHorizontal }

  func setIsHorizontal(_ isHorizontal: Bool) { m_bitfields.isHorizontal = isHorizontal }

  func removeFromParent() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextOnLine() -> LegacyInlineBox? { return m_nextOnLine }

  // FIXME: Hide this once all callers are using tighter types.
  func rendererObject() -> RenderObjectWrapper { return renderer }

  func parent() -> LegacyInlineFlowBox? { return m_parent }

  func root() -> LegacyRootInlineBox { return parent()?.root() ?? (self as! LegacyRootInlineBox) }

  // x() is the left side of the box in the containing block's coordinate system.
  func setX(_ x: Float32) { m_topLeft.setX(x: x) }

  func x() -> Float32 { return m_topLeft.x }

  // y() is the top side of the box in the containing block's coordinate system.
  func setY(_ y: Float32) { m_topLeft.setY(y: y) }

  func y() -> Float32 { return m_topLeft.y }

  func topLeft() -> FloatPoint { return m_topLeft }

  private func width() -> Float32 { return isHorizontal() ? logicalWidth() : logicalHeight() }

  private func height() -> Float32 { return isHorizontal() ? logicalHeight() : logicalWidth() }

  func size() -> FloatSize { return FloatSize(width: width(), height: height()) }

  // The logicalLeft position is the left edge of the line box in a horizontal line and the top edge in a vertical line.
  func logicalLeft() -> Float32 { return isHorizontal() ? m_topLeft.x : m_topLeft.y }

  func logicalRight() -> Float32 { return logicalLeft() + logicalWidth() }

  // The logicalTop position is the top edge of the line box in a horizontal line and the left edge in a vertical line.
  func logicalTop() -> Float32 { return isHorizontal() ? m_topLeft.y : m_topLeft.x }

  func logicalBottom() -> Float32 { return logicalTop() + logicalHeight() }

  // The logical width is our extent in the line's overall inline direction, i.e., width for horizontal text and height for vertical text.
  func setLogicalWidth(_ w: Float32) { m_logicalWidth = w }

  private func logicalWidth() -> Float32 { return m_logicalWidth }

  // The logical height is our extent in the block flow direction, i.e., height for horizontal text and width for vertical text.
  private func logicalHeight() -> Float32 {
    if hasVirtualLogicalHeight() {
      return virtualLogicalHeight()
    }

    let lineStyle = self.lineStyle()
    if rendererObject().isRenderTextOrLineBreak() {
      return Float32(lineStyle.metricsOfPrimaryFont().intHeight())
    }

    assert(isInlineFlowBox())
    let flowObject = boxModelObject()
    let fontMetrics = lineStyle.metricsOfPrimaryFont()
    var result = Float32(fontMetrics.intHeight())
    if parent() != nil {
      result += flowObject!.borderAndPaddingLogicalHeight()
    }
    return result
  }

  func dirtyLineBoxes() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func selectionState() -> RenderObjectWrapper.HighlightState {
    return rendererObject().selectionState()
  }

  private func lineStyle() -> RenderStyleWrapper {
    return m_bitfields.firstLine ? rendererObject().firstLineStyle() : rendererObject().style()
  }

  // Use with caution! The type is not checked!
  func boxModelObject() -> RenderBoxModelObjectWrapper? {
    if !(rendererObject() is RenderTextWrapper) {
      return rendererObject() as! RenderBoxModelObjectWrapper?
    }
    return nil
  }

  func flipForWritingMode(rect: inout LayoutRectWrapper) {
    if !rendererObject().style().isFlippedBlocksWritingMode() {
      return
    }
    root().blockFlow().flipForWritingMode(rect: &rect)
  }

  private struct InlineBoxBitfields {
    let firstLine = false
    let hasVirtualLogicalHeight = false
    var isHorizontal = true
  }

  private let m_nextOnLine: LegacyInlineBox? = nil  // The next element on the same line as us.

  private let m_parent: LegacyInlineFlowBox? = nil  // The box that contains us.

  let renderer: RenderObjectWrapper

  private var m_logicalWidth: Float32 = 0
  private var m_topLeft = FloatPoint()

  private var m_bitfields = InlineBoxBitfields()
}
