/*
 * Copyright (C) 2006 Oliver Hunt <ojh16@student.canterbury.ac.nz>
 * Copyright (C) 2006-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2015 Google Inc. All rights reserved.
 * Copyright (C) 2007 Nikolas Zimmermann <zimmermann@kde.org>
 * Copyright (C) 2008 Rob Buis <buis@kde.org>
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

private let space = UChar(Character(" ").asciiValue!)
private let tab = UChar(Character("\t").asciiValue!)
private let lf = UChar(Character("\n").asciiValue!)
private let cr = UChar(Character("\r").asciiValue!)

private func applySVGWhitespaceRules(_ string: StringWrapper, _ preserveWhiteSpace: Bool)
  -> StringWrapper
{
  var newString = string
  if preserveWhiteSpace {
    // Spec: When xml:space="preserve", the SVG user agent will do the following using a
    // copy of the original character data content. It will convert all newline and tab
    // characters into space characters. Then, it will draw all space characters, including
    // leading, trailing and multiple contiguous space characters.
    newString = makeStringByReplacingAll(newString, target: tab, replacement: space)
    newString = makeStringByReplacingAll(newString, target: lf, replacement: space)
    newString = makeStringByReplacingAll(newString, target: cr, replacement: space)
    return newString
  }

  // Spec: When xml:space="default", the SVG user agent will do the following using a
  // copy of the original character data content. First, it will remove all newline
  // characters. Then it will convert all tab characters into space characters.
  // Then, it will strip off all leading and trailing space characters.
  // Then, all contiguous space characters will be consolidated.
  newString = makeStringByReplacingAll(newString, target: lf, literal: ASCIILiteral(""))
  newString = makeStringByReplacingAll(newString, target: cr, literal: ASCIILiteral(""))
  newString = makeStringByReplacingAll(newString, target: tab, literal: ASCIILiteral(" "))
  return newString
}

final class RenderSVGInlineTextWrapper: RenderTextWrapper {
  func characterStartsNewTextChunk(_ position: UInt32) -> Bool {
    assert(position >= 0)
    assert(position < text().length())

    // Each <textPath> element starts a new text chunk, regardless of any x/y values.
    if position == 0 && parent()!.isRenderSVGTextPath() && previousSibling() == nil {
      return true
    }

    guard let charData = m_layoutAttributes!.characterDataMap().m[position + 1] else {
      return false
    }

    return !SVGTextLayoutAttributes.isEmptyValue(charData.x)
      || !SVGTextLayoutAttributes.isEmptyValue(charData.y)
  }

  func layoutAttributes() -> SVGTextLayoutAttributes {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // computeScalingFactor() returns the font-size scaling factor, ignoring the text-rendering mode.
  // scalingFactor() takes it into account, and thus returns 1 whenever text-rendering is set to 'geometricPrecision'.
  // Therefore if you need access to the vanilla scaling factor, use this method directly (e.g. for non-scaling-stroke).
  static func computeScalingFactorForRenderer(_ renderer: RenderObjectWrapper) -> Float32 {
    if renderer.document().settings().layerBasedSVGEngineEnabled(),
      let layerRenderer = RenderAncestorIteratorAdapter<RenderLayerModelObjectWrapper>
        .lineageOfType(first: renderer).first()
    {
      return SVGLayerTransformComputation(layerRenderer).calculateScreenFontSizeScalingFactor()
    }
    return SVGRenderingContext.calculateScreenFontSizeScalingFactor(renderer)
  }

  func scalingFactor() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scaledFont() -> FontCascadeWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func updateScaledFont() {
    var isNewScale = false
    (isNewScale, m_scalingFactor, m_scaledFont) =
      RenderSVGInlineTextWrapper.computeNewScaledFontForStyle(self, style())
    if isNewScale {
      m_canUseSimplifiedTextMeasuring = nil
    }
  }

  static func computeNewScaledFontForStyle(
    _ renderer: RenderObjectWrapper, _ style: RenderStyleWrapper
  ) -> (Bool, Float32, FontCascadeWrapper) {
    // Alter font-size to the right on-screen value to avoid scaling the glyphs themselves, except when GeometricPrecision is specified
    var scalingFactor = RenderSVGInlineTextWrapper.computeScalingFactorForRenderer(renderer)
    if scalingFactor == 0 {
      return (false, 1, style.fontCascade())
    }

    if style.fontDescription().textRenderingMode() == .GeometricPrecision {
      scalingFactor = 1
    }

    let fontDescription = style.fontDescription()

    // FIXME: We need to better handle the case when we compute very small fonts below (below 1pt).
    fontDescription.setComputedSize(
      s: Style.computedFontSizeFromSpecifiedSizeForSVGInlineText(
        fontDescription.specifiedSize(), fontDescription.isAbsoluteSize(), scalingFactor,
        renderer.protectedDocument()))

    // SVG controls its own glyph orientation, so don't allow writing-mode
    // to affect it.
    if fontDescription.orientation() != .Horizontal {
      fontDescription.setOrientation(.Horizontal)
    }

    let scaledFont = FontCascadeWrapper(fontDescription)
    scaledFont.update(fontSelector: renderer.document().protectedFontSelector())
    return (true, scalingFactor, scaledFont)
  }

  override func setRenderedText(_ text: StringWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  override func styleDidChange(diff: StyleDifference, oldStyle: RenderStyleWrapper?) {
    super.styleDidChange(diff: diff, oldStyle: oldStyle)
    updateScaledFont()

    let newPreserves = style().whiteSpaceCollapse() == .Preserve
    let oldPreserves = oldStyle != nil ? oldStyle!.whiteSpaceCollapse() == .Preserve : false
    if oldPreserves && !newPreserves {
      setText(newContent: applySVGWhitespaceRules(originalText(), false), force: true)
      return
    }

    if !oldPreserves && newPreserves {
      setText(newContent: applySVGWhitespaceRules(originalText(), true), force: true)
      return
    }

    if diff != .Layout {
      return
    }

    // The text metrics may be influenced by style changes.
    if let textAncestor = RenderSVGTextWrapper.locateRenderSVGTextAncestor(start: self) {
      textAncestor.setNeedsLayout()
    }
  }

  override func objectBoundingBox() -> FloatRectWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private var m_scaledFont = FontCascadeWrapper()
  private var m_scalingFactor: Float32 = 0
  private let m_layoutAttributes: SVGTextLayoutAttributes? = nil
}
