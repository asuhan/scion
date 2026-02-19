/*
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2013 Google Inc. All rights reserved.
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

// RenderOverflow is a class for tracking content that spills out of a box.  This class is used by RenderBox and
// LegacyInlineFlowBox.
//
// There are two types of overflow: layout overflow (which is expected to be reachable via scrolling mechanisms) and
// visual overflow (which is not expected to be reachable via scrolling mechanisms).
//
// Layout overflow examples include other boxes that spill out of our box,  For example, in the inline case a tall image
// could spill out of a line box.

// Examples of visual overflow are shadows, text stroke, outline (and eventually border-image).

// This object is allocated only when some of these fields have non-default values in the owning box.
class RenderOverflow {
  init(layoutRect: LayoutRectWrapper, visualRect: LayoutRectWrapper) {
    layoutOverflow = layoutRect
    visualOverflow = visualRect
  }

  func layoutOverflowRect() -> LayoutRectWrapper { return layoutOverflow }
  func visualOverflowRect() -> LayoutRectWrapper { return visualOverflow }

  func addLayoutOverflow(rect: LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func addVisualOverflow(rect: LayoutRectWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLayoutOverflow(_ rect: LayoutRectWrapper) {
    layoutOverflow = rect
  }

  private var layoutOverflow: LayoutRectWrapper
  private let visualOverflow: LayoutRectWrapper

  var layoutClientAfterEdge = LayoutUnit()
}
