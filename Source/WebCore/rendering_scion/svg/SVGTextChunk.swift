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
      let key = InlineIterator.SVGTextBox.Key(chunk: box.get().renderer(), start: box.get().start())
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
    var firstFragment: SVGTextFragment? = nil
    var lastFragment: SVGTextFragment? = nil

    for box in boxes {
      if !box.fragments.a.isEmpty {
        firstFragment = box.fragments.a.first
        break
      }
    }

    for box in boxes.reversed() {
      if !box.fragments.a.isEmpty {
        lastFragment = box.fragments.a.last
        break
      }
    }

    assert((firstFragment == nil) == (lastFragment == nil))
    if firstFragment == nil {
      return 0
    }

    if chunkStyle.contains(.VerticalText) {
      return (lastFragment!.y + lastFragment!.height) - firstFragment!.y
    }

    return (lastFragment!.x + lastFragment!.width) - firstFragment!.x
  }

  func totalAnchorShift() -> Float32 {
    let length = totalLength()
    if chunkStyle.contains(.MiddleAnchor) {
      return -length / 2
    }
    if chunkStyle.contains(.EndAnchor) {
      return chunkStyle.contains(.RightToLeftText) ? 0 : -length
    }
    return chunkStyle.contains(.RightToLeftText) ? -length : 0
  }

  func layout(_ textBoxTransformations: SVGChunkTransformMap) {
    if hasDesiredTextLength() {
      if hasLengthAdjustSpacing() {
        processTextLengthSpacingCorrection()
      } else {
        assert(hasLengthAdjustSpacingAndGlyphs())
        buildBoxTransformations(textBoxTransformations)
      }
    }

    if hasTextAnchor() {
      processTextAnchorCorrection()
    }
  }

  private func processTextAnchorCorrection() {
    let textAnchorShift = totalAnchorShift()
    let isVerticalText = chunkStyle.contains(.VerticalText)

    for box in boxes {
      for fragment in box.fragments.a {
        if isVerticalText {
          fragment.y += textAnchorShift
        } else {
          fragment.x += textAnchorShift
        }
      }
    }
  }

  private func buildBoxTransformations(_ textBoxTransformations: SVGChunkTransformMap) {
    let spacingAndGlyphsTransform = AffineTransform()
    var foundFirstFragment = false

    for box in boxes {
      if !foundFirstFragment {
        if !boxSpacingAndGlyphsTransform(box.fragments.a[...], spacingAndGlyphsTransform) {
          continue
        }
        foundFirstFragment = true
      }

      let key = InlineIterator.SVGTextBox.Key(
        chunk: box.box.get().renderer(), start: box.box.get().start())
      textBoxTransformations.set(key, spacingAndGlyphsTransform)
    }
  }

  private func processTextLengthSpacingCorrection() {
    let textLengthShift =
      totalCharacters() > 1
      ? (desiredTextLength - totalLength()) / Float32(totalCharacters() - 1) : 0

    let isVerticalText = chunkStyle.contains(.VerticalText)
    var atCharacter: UInt32 = 0

    for box in boxes {
      for fragment in box.fragments.a {
        if isVerticalText {
          fragment.y += textLengthShift * Float32(atCharacter)
        } else {
          fragment.x += textLengthShift * Float32(atCharacter)
        }

        atCharacter += fragment.length
      }
    }
  }

  private func hasDesiredTextLength() -> Bool {
    return desiredTextLength > 0
      && (chunkStyle.contains(.LengthAdjustSpacing)
        || chunkStyle.contains(.LengthAdjustSpacingAndGlyphs))
  }

  private func hasTextAnchor() -> Bool {
    return chunkStyle.contains(.RightToLeftText)
      ? !chunkStyle.contains(.EndAnchor)
      : !chunkStyle.isDisjoint(with: [.MiddleAnchor, .EndAnchor])
  }

  private func hasLengthAdjustSpacing() -> Bool { return chunkStyle.contains(.LengthAdjustSpacing) }

  private func hasLengthAdjustSpacingAndGlyphs() -> Bool {
    return chunkStyle.contains(.LengthAdjustSpacingAndGlyphs)
  }

  private func boxSpacingAndGlyphsTransform(
    _ fragments: ArraySlice<SVGTextFragment>, _ spacingAndGlyphsTransform: AffineTransform
  ) -> Bool {
    if fragments.isEmpty {
      return false
    }

    let fragment = fragments.first!
    let scale = Float64(desiredTextLength / totalLength())

    spacingAndGlyphsTransform.translate(Float64(fragment.x), Float64(fragment.y))

    if chunkStyle.contains(.VerticalText) {
      spacingAndGlyphsTransform.scaleNonUniform(1, scale)
    } else {
      spacingAndGlyphsTransform.scaleNonUniform(scale, 1)
    }

    spacingAndGlyphsTransform.translate(Float64(-fragment.x), Float64(-fragment.y))
    return true
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
