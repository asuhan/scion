/*
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
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

// A SVGTextFragment describes a text fragment of a RenderSVGInlineText which can be rendered at once.
class SVGTextFragment {
  init() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // The first rendered character starts at RenderSVGInlineText::characters() + characterOffset.
  var characterOffset: UInt32
  var metricsListOffset: UInt32
  var length: UInt32
  var isTextOnPath: Bool

  var x: Float32
  var y: Float32
  var width: Float32
  var height: Float32

  // Includes rotation/glyph-orientation-(horizontal|vertical) transforms, as well as orientation related shifts
  // (see SVGTextLayoutEngine, which builds this transformation).
  let transform: AffineTransform

  // Contains lengthAdjust related transformations, which are not allowd to influence the SVGTextQuery code.
  var lengthAdjustTransform: AffineTransform
}
