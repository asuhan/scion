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
  func isLineBreak() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

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

  func nextOnLine() -> LegacyInlineBox? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // FIXME: Hide this once all callers are using tighter types.
  func rendererObject() -> RenderObjectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func parent() -> LegacyInlineFlowBox? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func root() -> LegacyRootInlineBox {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func x() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func y() -> Float32 {
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

  func logicalBottom() -> Float32 {
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
}
