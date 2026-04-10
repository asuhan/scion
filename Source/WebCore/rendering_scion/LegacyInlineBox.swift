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

  func isHorizontal() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setIsHorizontal(_ isHorizontal: Bool) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func nextOnLine() -> LegacyInlineBox? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME: Hide this once all callers are using tighter types.
  func rendererObject() -> RenderObjectWrapper { return renderer }

  func parent() -> LegacyInlineFlowBox? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func root() -> LegacyRootInlineBox {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // x() is the left side of the box in the containing block's coordinate system.
  func setX(_ x: Float32) { m_topLeft.setX(x: x) }

  func x() -> Float32 { return m_topLeft.x }

  // y() is the top side of the box in the containing block's coordinate system.
  func setY(_ y: Float32) { m_topLeft.setY(y: y) }

  func y() -> Float32 { return m_topLeft.y }

  func topLeft() -> FloatPoint { return m_topLeft }

  func size() -> FloatSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The logicalLeft position is the left edge of the line box in a horizontal line and the top edge in a vertical line.
  func logicalLeft() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalRight() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The logicalTop position is the top edge of the line box in a horizontal line and the left edge in a vertical line.
  func logicalTop() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalBottom() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The logical width is our extent in the line's overall inline direction, i.e., width for horizontal text and height for vertical text.
  func setLogicalWidth(_ w: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func dirtyLineBoxes() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func selectionState() -> RenderObjectWrapper.HighlightState {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Use with caution! The type is not checked!
  func boxModelObject() -> RenderBoxModelObjectWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func flipForWritingMode(rect: inout LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let renderer: RenderObjectWrapper
  private var m_topLeft = FloatPoint()
}
