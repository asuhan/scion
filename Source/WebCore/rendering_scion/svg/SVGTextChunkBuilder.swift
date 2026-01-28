/*
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 * Copyright (C) 2015 Apple Inc. All rights reserved.
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

// SVGTextChunkBuilder performs the third layout phase for SVG text.
//
// Phase one built the layout information from the SVG DOM stored in the RenderSVGInlineText objects (SVGTextLayoutAttributes).
// Phase two performed the actual per-character layout, computing the final positions for each character, stored in the SVGInlineTextBox objects (SVGTextFragment).
// Phase three performs all modifications that have to be applied to each individual text chunk (text-anchor & textLength).

struct SVGTextChunkBuilder {
  init() {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func totalCharacters() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func totalLength() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func totalAnchorShift() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func transformationForTextBox(_ textBox: InlineIterator.SVGTextBoxIterator) -> AffineTransform {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  mutating func buildTextChunks(
    _ lineLayoutBoxes: ArraySlice<InlineIterator.SVGTextBoxIterator>,
    _ chunkStarts: HashSet<InlineIterator.SVGTextBox.Key>, _ fragmentMap: SVGTextFragmentMap
  ) {
    if lineLayoutBoxes.isEmpty {
      return
    }

    let limit = lineLayoutBoxes.count
    var first = limit

    for (i, lineLayoutBox) in lineLayoutBoxes.enumerated() {
      if !chunkStarts.contains(value: (lineLayoutBox.get().renderer(), lineLayoutBox.get().start()))
      {
        continue
      }

      if first == limit {
        first = i
      } else {
        assert(first != i)
        textChunks.append(SVGTextChunk(lineLayoutBoxes, UInt32(first), UInt32(i), fragmentMap))
        first = i
      }
    }

    if first != limit {
      textChunks.append(SVGTextChunk(lineLayoutBoxes, UInt32(first), UInt32(limit), fragmentMap))
    }
  }

  mutating func layoutTextChunks(
    _ lineLayoutBoxes: ArraySlice<InlineIterator.SVGTextBoxIterator>,
    _ chunkStarts: HashSet<InlineIterator.SVGTextBox.Key>, _ fragmentMap: SVGTextFragmentMap
  ) {
    buildTextChunks(lineLayoutBoxes, chunkStarts, fragmentMap)
    if textChunks.isEmpty {
      return
    }

    for chunk in textChunks {
      chunk.layout(textBoxTransformations)
    }

    textChunks.removeAll()
  }

  private var textChunks: [SVGTextChunk] = []
  private let textBoxTransformations: SVGChunkTransformMap
}
