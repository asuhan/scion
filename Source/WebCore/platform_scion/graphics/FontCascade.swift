/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2008 Holger Hans Peter Freyther
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

import wk_interop

class FontCascadeWrapper {
  var p: UnsafeRawPointer?

  init(p: UnsafeRawPointer? = nil) {
    self.p = p
  }

  init(_ description: FontCascadeDescriptionWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  init(_ description: FontCascadeDescriptionWrapper, _ other: FontCascadeWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fontDescription() -> FontCascadeDescriptionWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return FontCascadeDescriptionWrapper(p: wk_interop.FontCascade_fontDescription(p!))
  }

  func size() -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return font_cascade_size(p: p!)
  }

  func update(fontSelector: FontSelectorWrapper? = nil) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  enum CustomFontNotReadyAction {
    case DoNotPaintIfFontNotReady
    case UseFallbackIfFontNotReady
  }

  func dashesForIntersectionsWithRect(
    run: TextRunWrapper, textOrigin: FloatPoint, lineExtents: FloatRectWrapper
  ) -> DashArray {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func widthOfTextRange(
    run: TextRunWrapper, from: UInt32, to: UInt32, fallbackFonts: Set<UInt>?,
    outWidthBeforeRange: inout Float32, outWidthAfterRange: inout Float32
  ) -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func width(run: TextRunWrapper) -> Float32 {
    if p != nil && run.p != nil {
      return font_cascade_width(fontCascadePtr: p!, textRunPtr: run.p!)
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func widthForTextUsingSimplifiedMeasuring(
    text: StringWrapperView, textDirection: TextDirection = .LTR
  ) -> Float32 {
    if p != nil && text.p != nil {
      return font_cascade_width_for_text_using_simplified_measuring(
        fontCascadePtr: p!, textPtr: text.p!, textDirection: textDirection == .LTR)
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func widthForSimpleTextWithFixedPitch(
    text: StringWrapperView, whitespaceIsCollapsed: Bool
  ) -> Float32 {
    if p != nil && text.p != nil {
      return font_cascade_width_for_simple_text_with_fixed_pitch(
        fontCascadePtr: p!, textPtr: text.p!, whitespaceIsCollapsed: whitespaceIsCollapsed)
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func letterSpacing() -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.FontCascade_letterSpacing(p)
  }

  func canTakeFixedPitchFastContentMeasuring() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return font_cascade_canTakeFixedPitchFastContentMeasuring(p: p!)
  }

  func enableKerning() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return font_cascade_enableKerning(p: p!)
  }

  func requiresShaping() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return font_cascade_requiresShaping(p: p!)
  }

  func primaryFontSpaceWidth() -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return font_cascade_primaryFontSpaceWidth(p: p!)
  }

  func widthOfSpaceString() -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return font_cascade_widthOfSpaceString(p: p!)
  }

  func adjustSelectionRectForText(
    canUseSimplifiedTextMeasuring: Bool, run: TextRunWrapper, selectionRect: LayoutRectWrapper,
    from: UInt32 = 0, to: UInt32? = nil
  ) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isSmallCaps() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.FontCascade_isSmallCaps(p!)
  }

  func wordSpacing() -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return font_cascade_wordSpacing(p: p!)
  }

  func metricsOfPrimaryFont() -> FontMetricsWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return FontMetricsWrapper(p: wk_interop.FontCascade_metricsOfPrimaryFont(p))
  }

  func emphasisMarkAscent(mark: AtomStringWrapper) -> Int {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func emphasisMarkDescent(mark: AtomStringWrapper) -> Int {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func floatEmphasisMarkHeight(mark: AtomStringWrapper) -> Float32 {
    if p == nil || mark.p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.FontCascade_floatEmphasisMarkHeight(p, mark.p)
  }

  func primaryFont() -> FontWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return FontWrapper(p: wk_interop.FontCascade_primaryFont(p))
  }

  func glyphDataForCharacter(c: UInt32, mirror: Bool, variant: FontVariant = .AutoVariant)
    -> GlyphData
  {
    let glyphDataRaw =
      wk_interop.FontCascade_glyphDataForCharacter(p, c, mirror, variant.rawValue)
    let fontIsNil = CPtrToInt(glyphDataRaw.font) == 0
    return GlyphData(
      glyph: glyphDataRaw.glyph, font: fontIsNil ? nil : FontWrapper(p: glyphDataRaw.font),
      colorGlyphType: ColorGlyphType(rawValue: glyphDataRaw.color_glyph_type)!)
  }

  static func expansionOpportunityCount(
    stringView: StringWrapperView, direction: TextDirection,
    expansionBehavior: ExpansionBehaviorWrapper
  ) -> (UInt64, Bool) {
    if stringView.p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    let raw = wk_interop.FontCascade_expansionOpportunityCount(
      stringView.p, direction.rawValue, expansionBehavior.left.rawValue,
      expansionBehavior.right.rawValue)
    return (UInt64(raw.count), raw.isAfterExpansion)
  }

  enum CodePath {
    case Auto
    case Simple
    case Complex
    case SimpleWithGlyphOverflow
  }

  func codePath(_ run: TextRunWrapper, from: UInt32? = nil, to: UInt32? = nil) -> CodePath {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fontSelector() -> FontSelectorWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isLoadingCustomFonts() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }
}

struct GlyphOverflow {
  func isEmpty() -> Bool {
    return !left.bool() && !right.bool() && !top.bool() && !bottom.bool()
  }

  var left = LayoutUnit()
  var right = LayoutUnit()
  var top = LayoutUnit()
  var bottom = LayoutUnit()
}
