/*
 * Copyright (C) 2011 Apple Inc. All rights reserved.
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

// Allow em + 15% margin
private let textCombineMargin: Float32 = 1.15

final class RenderCombineTextWrapper: RenderTextWrapper {
  func combineTextIfNeeded() {
    assert(isNativeImpl())
    if !needsFontUpdate {
      return
    }

    // An ancestor element may trigger us to lay out again, even when we're already combined.
    if m_isCombined {
      super.setRenderedText(originalText())
    }

    m_isCombined = false
    needsFontUpdate = false

    // text-combine-upright works only in vertical typographic mode.
    if style().typographicMode() == .Horizontal {
      return
    }

    let description = originalFont().fontDescription()
    let emWidth = description.computedSize() * textCombineMargin
    var shouldUpdateFont = false

    let fontSelector = style().fontCascade().fontSelector()

    description.setOrientation(.Horizontal)  // We are going to draw combined text horizontally.

    let horizontalFont = FontCascadeWrapper(description.deepCopy(), style().fontCascade())
    horizontalFont.update(fontSelector: fontSelector)

    var glyphOverflow: GlyphOverflow? = GlyphOverflow()
    glyphOverflow!.computeBounds = true
    var combinedTextWidth = width(
      from: 0, length: text().length(), fontCascade: horizontalFont, xPos: 0, fallbackFonts: nil,
      glyphOverflow: &glyphOverflow)

    var bestFitDelta = combinedTextWidth - emWidth
    var bestFitDescription = description.deepCopy()

    m_isCombined = combinedTextWidth <= emWidth

    if m_isCombined {
      shouldUpdateFont = combineFontStyle!.setFontDescription(description: description)  // Need to change font orientation to horizontal.
    } else {
      // Need to try compressed glyphs.
      for widthVariant: FontWidthVariant in [.HalfWidth, .ThirdWidth, .QuarterWidth] {
        description.setWidthVariant(widthVariant)  // When modifying this, make sure to keep it in sync with FontPlatformData::isForTextCombine()!

        let compressedFont = FontCascadeWrapper(description.deepCopy(), style().fontCascade())
        compressedFont.update(fontSelector: fontSelector)

        glyphOverflow!.left = LayoutUnit(value: 0)
        glyphOverflow!.top = LayoutUnit(value: 0)
        glyphOverflow!.right = LayoutUnit(value: 0)
        glyphOverflow!.bottom = LayoutUnit(value: 0)
        let runWidth = width(
          from: 0, length: text().length(), fontCascade: compressedFont, xPos: 0,
          fallbackFonts: nil, glyphOverflow: &glyphOverflow)
        if runWidth <= emWidth {
          combinedTextWidth = runWidth
          m_isCombined = true

          // Replace my font with the new one.
          shouldUpdateFont = combineFontStyle!.setFontDescription(description: description)
          break
        }

        let widthDelta = runWidth - emWidth
        if widthDelta < bestFitDelta {
          bestFitDelta = widthDelta
          bestFitDescription = description
        }
      }
    }

    if !m_isCombined {
      var scaleFactor = max(0.4, emWidth / (emWidth + bestFitDelta))
      let originalSize = bestFitDescription.computedSize()
      repeat {
        let computedSize = originalSize * scaleFactor
        bestFitDescription.setComputedSize(s: computedSize)
        shouldUpdateFont = combineFontStyle!.setFontDescription(
          description: bestFitDescription.deepCopy())

        let compressedFont = FontCascadeWrapper(
          bestFitDescription.deepCopy(), style().fontCascade())
        compressedFont.update(fontSelector: fontSelector)

        glyphOverflow!.left = LayoutUnit(value: 0)
        glyphOverflow!.top = LayoutUnit(value: 0)
        glyphOverflow!.right = LayoutUnit(value: 0)
        glyphOverflow!.bottom = LayoutUnit(value: 0)
        let runWidth = width(
          from: 0, length: text().length(), fontCascade: compressedFont, xPos: 0,
          fallbackFonts: nil, glyphOverflow: &glyphOverflow)
        if runWidth <= emWidth {
          combinedTextWidth = runWidth
          m_isCombined = true
          break
        }
        scaleFactor -= 0.05
      } while scaleFactor >= 0.4
    }

    if shouldUpdateFont {
      combineFontStyle!.fontCascade().update(fontSelector: fontSelector)
    }

    if m_isCombined {
      super.setRenderedText(
        StringWrapper(characters: RenderCombineTextWrapper.objectReplacementCharacterString))
      m_combinedTextWidth = combinedTextWidth
      combinedTextAscent = glyphOverflow!.top.float()
      combinedTextDescent = glyphOverflow!.bottom.float()
      setNeedsLayout()
    }
  }

  private static let objectReplacementCharacterString = WTF.span(
    character: CharacterNames.Unicode.objectReplacementCharacter)

  func computeTextOrigin(boxRect: FloatRectWrapper) -> FloatPoint? {
    assert(isNativeImpl())
    if !m_isCombined {
      return nil
    }

    // Visually center m_combinedTextWidth/Ascent/Descent within boxRect
    var result = boxRect.minXMaxYCorner()
    let combinedTextSize = FloatSize(
      width: m_combinedTextWidth, height: combinedTextAscent + combinedTextDescent)
    result.move((boxRect.size().transposedSize() - combinedTextSize) / 2)
    result.move(dx: 0, dy: combinedTextAscent)
    return result
  }

  func isCombined() -> Bool {
    assert(isNativeImpl())
    return m_isCombined
  }

  func combinedTextWidth(_ font: FontCascadeWrapper) -> Float32 {
    assert(isNativeImpl())
    return font.size()
  }

  func originalFont() -> FontCascadeWrapper {
    assert(isNativeImpl())
    return parent()!.style().fontCascade()
  }

  func textCombineFont() -> FontCascadeWrapper {
    assert(isNativeImpl())
    return combineFontStyle!.fontCascade()
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    assert(isNativeImpl())
    // FIXME: This is pretty hackish.
    // Only cache a new font style if our old one actually changed. We do this to avoid
    // clobbering width variants and shrink-to-fit changes, since we won't recombine when
    // the font doesn't change.
    if oldStyle == nil || oldStyle!.fontCascade() != style().fontCascade() {
      combineFontStyle = RenderStyleWrapper.clone(style: style())
    }

    super.styleDidChange(diff: diff, oldStyle: oldStyle)

    if m_isCombined && selfNeedsLayout() {
      // Layouts cause the text to be recombined; therefore, only only un-combine when the style diff causes a layout.
      super.setRenderedText(originalText())  // This RenderCombineText has been combined once. Restore the original text for the next combineText().
      m_isCombined = false
    }

    needsFontUpdate = true
    combineTextIfNeeded()
  }

  override func setRenderedText(_ text: StringWrapper) {
    assert(isNativeImpl())
    super.setRenderedText(text)

    needsFontUpdate = true
    combineTextIfNeeded()
  }

  private var combineFontStyle: RenderStyleWrapper? = nil
  private var m_combinedTextWidth: Float32 = 0
  private var combinedTextAscent: Float32 = 0
  private var combinedTextDescent: Float32 = 0
  private var m_isCombined = false
  private var needsFontUpdate = false
}
