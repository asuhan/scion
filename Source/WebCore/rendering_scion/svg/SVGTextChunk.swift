/*
 * Copyright (C) Research In Motion Limited 2010. All rights reserved.
 * Copyright (C) 2015-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2017 Google Inc. All rights reserved.
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

class SVGTextFragmentArrayRef {
  var a: [SVGTextFragment] = []
}

typealias SVGChunkTransformMap = HashMap<InlineIterator.SVGTextBox.Key, AffineTransform>
typealias SVGTextFragmentMap = HashMap<InlineIterator.SVGTextBox.Key, SVGTextFragmentArrayRef>

// A SVGTextChunk describes a range of SVGTextFragments, see the SVG spec definition of a "text chunk".
struct SVGTextChunk {
  struct ChunkStyle: OptionSet {
    let rawValue: UInt8

    static let DefaultStyle = ChunkStyle(rawValue: 1 << 0)
    static let MiddleAnchor = ChunkStyle(rawValue: 1 << 1)
    static let EndAnchor = ChunkStyle(rawValue: 1 << 2)
    static let RightToLeftText = ChunkStyle(rawValue: 1 << 3)
    static let VerticalText = ChunkStyle(rawValue: 1 << 4)
    static let LengthAdjustSpacing = ChunkStyle(rawValue: 1 << 5)
    static let LengthAdjustSpacingAndGlyphs = ChunkStyle(rawValue: 1 << 6)
  }

  init(
    _ lineLayoutBoxes: ArraySlice<InlineIterator.SVGTextBoxIterator>, _ first: UInt32,
    _ limit: UInt32, _ fragmentMap: SVGTextFragmentMap
  ) {
    assert(first < limit)
    assert(limit <= lineLayoutBoxes.count)

    let firstBox = lineLayoutBoxes[Int(first)]
    let style = firstBox.get().renderer().style()
    let svgStyle = style.svgStyle()

    if !style.isLeftToRightDirection() {
      chunkStyle.update(with: .RightToLeftText)
    }

    if style.isVerticalWritingMode() {
      chunkStyle.update(with: .VerticalText)
    }

    switch svgStyle.textAnchor() {
    case .Start:
      break
    case .Middle:
      chunkStyle.update(with: .MiddleAnchor)
    case .End:
      chunkStyle.update(with: .EndAnchor)
    }

    if let textContentElement = SVGTextContentElementWrapper.elementFromRenderer(
      firstBox.get().renderer().parent())
    {
      let lengthContext = SVGLengthContext(context: textContentElement)
      desiredTextLength = textContentElement.specifiedTextLength().value(lengthContext)

      switch textContentElement.lengthAdjust() {
      case .SVGLengthAdjustUnknown:
        break
      case .SVGLengthAdjustSpacing:
        chunkStyle.update(with: .LengthAdjustSpacing)
      case .SVGLengthAdjustSpacingAndGlyphs:
        chunkStyle.update(with: .LengthAdjustSpacingAndGlyphs)
      }
    } else {
      desiredTextLength = 0
    }

    boxes = []
    for box in lineLayoutBoxes[Int(first)..<Int(limit)] {
      let key = (box.get().renderer(), box.get().start())
      if !fragmentMap.contains(key) {
        continue
      }
      boxes.append(BoxAndFragments(box: box, fragments: fragmentMap.get(key)))
    }
  }

  func totalCharacters() -> UInt32 {
    var characters: UInt32 = 0
    for box in boxes {
      for fragment in box.fragments.a {
        characters += fragment.length
      }
    }
    return characters
  }

  func totalLength() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func totalAnchorShift() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func layout(_ textBoxTransformations: SVGChunkTransformMap) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Contains all SVGInlineTextBoxes this chunk spans.
  struct BoxAndFragments {
    let box: InlineIterator.SVGTextBoxIterator
    let fragments: SVGTextFragmentArrayRef
  }
  private var boxes: [BoxAndFragments]

  private var chunkStyle: ChunkStyle = [.DefaultStyle]
  private let desiredTextLength: Float32
}
