/*
 * Copyright (C) Research In Motion Limited 2010-2012. All rights reserved.
 * Copyright (C) Apple 2023-2024. All rights reserved.
 * Copyright (C) Google 2014-2017. All rights reserved.
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

// SVGTextLayoutEngine performs the second layout phase for SVG text.
//
// The InlineBox tree was created, containing the text chunk information, necessary to apply
// certain SVG specific text layout properties (text-length adjustments and text-anchor).
// The second layout phase uses the SVGTextLayoutAttributes stored in the individual
// RenderSVGInlineText renderers to compute the final positions for each character
// which are stored in the SVGInlineTextBox objects.

struct SVGTextLayoutEngine {
  init(_ layoutAttributes: RenderSVGTextWrapper.LayoutAttributesRef) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func beginTextPathLayout(_ textPath: RenderSVGTextPath, _ lineLayout: inout SVGTextLayoutEngine) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func endTextPathLayout() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layoutInlineTextBox(_ textBox: InlineIterator.SVGTextBoxIterator) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func finishLayout() -> SVGTextFragmentMap {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  let layoutAttributes: RenderSVGTextWrapper.LayoutAttributesRef
}
