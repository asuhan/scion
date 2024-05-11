/*
 * Copyright (C) 2021 Apple Inc. All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 * 1. Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY APPLE INC. AND ITS CONTRIBUTORS ``AS IS''
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
 * THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 * PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL APPLE INC. OR ITS CONTRIBUTORS
 * BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 * INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
 * CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF
 * THE POSSIBILITY OF SUCH DAMAGE.
 */

import Foundation

class InlineLevelBox {
  enum LineSpanningInlineBox: UInt8 {
    case No
    case Yes
  }

  static func createInlineBox(
    layoutBox: BoxWrapper, style: RenderStyleWrapper, logicalLeft: InlineLayoutUnit,
    logicalWidth: InlineLayoutUnit, isLineSpanning: LineSpanningInlineBox = .No
  ) -> InlineLevelBox {
    return InlineLevelBox(
      layoutBox: layoutBox, style: style, logicalLeft: logicalLeft,
      logicalSize: InlineLayoutSize(width: logicalWidth, height: 0),
      type: isLineSpanning == .Yes ? .LineSpanningInlineBox : .InlineBox,
      positionWithinLayoutBox: PositionWithinLayoutBox())
  }

  static func createRootInlineBox(
    layoutBox: BoxWrapper, style: RenderStyleWrapper, logicalLeft: InlineLayoutUnit,
    logicalWidth: InlineLayoutUnit
  ) -> InlineLevelBox {
    return InlineLevelBox(
      layoutBox: layoutBox, style: style, logicalLeft: logicalLeft,
      logicalSize: InlineLayoutSize(width: logicalWidth, height: 0), type: .RootInlineBox,
      positionWithinLayoutBox: PositionWithinLayoutBox())
  }

  static func createAtomicInlineBox(
    layoutBox: BoxWrapper, style: RenderStyleWrapper, logicalLeft: InlineLayoutUnit,
    logicalWidth: InlineLayoutUnit
  )
    -> InlineLevelBox
  {
    return InlineLevelBox(
      layoutBox: layoutBox, style: style, logicalLeft: logicalLeft,
      logicalSize: InlineLayoutSize(width: logicalWidth, height: 0), type: .AtomicInlineBox)
  }

  static func createLineBreakBox(
    layoutBox: BoxWrapper, style: RenderStyleWrapper, logicalLeft: InlineLayoutUnit
  ) -> InlineLevelBox {
    return InlineLevelBox(
      layoutBox: layoutBox, style: style, logicalLeft: logicalLeft, logicalSize: InlineLayoutSize(),
      type: .LineBreakBox)
  }

  static func createGenericInlineLevelBox(
    layoutBox: BoxWrapper, style: RenderStyleWrapper, logicalLeft: InlineLayoutUnit
  ) -> InlineLevelBox {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct AscentAndDescent {
    var ascent = InlineLayoutUnit()
    var descent = InlineLayoutUnit()

    func height() -> InlineLayoutUnit {
      return ascent + descent
    }

    static func == (lhs: AscentAndDescent, rhs: AscentAndDescent) -> Bool {
      return lhs.ascent == rhs.ascent && lhs.descent == rhs.descent
    }

    // FIXME: Remove this.
    // We need floor/ceil to match legacy layout integral positioning.
    mutating func round() {
      ascent = floorf(ascent)
      descent = ceilf(descent)
    }
  }

  func ascent() -> InlineLayoutUnit {
    return ascentAndDescent.ascent
  }

  func descent() -> InlineLayoutUnit {
    return ascentAndDescent.descent
  }

  func setHasContent() { hasContent = true }

  struct VerticalAlignment {
    var type = VerticalAlign.Baseline
    var baselineOffset: InlineLayoutUnit? = nil
  }

  func verticalAlign() -> VerticalAlignment {
    return style.verticalAlignment
  }

  func hasLineBoxRelativeAlignment() -> Bool {
    let verticalAlignment = verticalAlign().type
    return verticalAlignment == .Top || verticalAlignment == .Bottom
  }

  func preferredLineHeight() -> InlineLayoutUnit {
    if isPreferredLineHeightFontMetricsBased() {
      return primarymetricsOfPrimaryFont().lineSpacing()
    }

    if style.lineHeight.isPercentOrCalculated() {
      return minimumValueForLength(length: style.lineHeight, maximumValue: fontSize()).float()
    }
    return style.lineHeight.value()
  }

  func isPreferredLineHeightFontMetricsBased() -> Bool { return style.lineHeight.isNormal() }

  func mayStretchLineBox() -> Bool {
    if isRootInlineBox() {
      return style.lineBoxContain.contains(.Block) || style.lineBoxContain.contains(.Inline)
        || (hasContent
          && (style.lineBoxContain.contains(.InitialLetter) || style.lineBoxContain.contains(.Font)
            || style.lineBoxContain.contains(.Glyphs)))
    }

    if isAtomicInlineBox() {
      return style.lineBoxContain.contains(.Replaced)
    }

    if isInlineBox() || isLineBreakBox() {
      // Either the inline box itself is included or its text content thorugh Glyph and Font.
      return style.lineBoxContain.contains(.Inline) || style.lineBoxContain.contains(.InlineBox)
        || (hasContent
          && (style.lineBoxContain.contains(.Font) || style.lineBoxContain.contains(.Glyphs)))
    }

    return true
  }

  func primarymetricsOfPrimaryFont() -> FontMetricsWrapper {
    return style.primaryFontMetrics
  }

  func fontSize() -> InlineLayoutUnit {
    return style.primaryFontSize
  }

  func lineFitEdge() -> TextEdge {
    return style.lineFitEdge
  }

  func hasTextEmphasis() -> Bool {
    return (hasContent || isAtomicInlineBox()) && textEmphasis != nil
  }

  func textEmphasisAbove() -> InlineLayoutUnit? {
    return hasTextEmphasis() ? textEmphasis!.above : nil
  }

  func textEmphasisBelow() -> InlineLayoutUnit? {
    return hasTextEmphasis() ? textEmphasis!.below : nil
  }

  func isInlineBox() -> Bool {
    return type == .InlineBox || isRootInlineBox() || isLineSpanningInlineBox()
  }

  func isRootInlineBox() -> Bool { return type == .RootInlineBox }

  func isLineSpanningInlineBox() -> Bool { return type == .LineSpanningInlineBox }

  func isAtomicInlineBox() -> Bool { return type == .AtomicInlineBox }

  func isListMarker() -> Bool { return isAtomicInlineBox() && layoutBox.isListMarkerBox() }

  func isLineBreakBox() -> Bool { return type == .LineBreakBox }

  enum Type_: UInt8 {
    case InlineBox = 1
    case LineSpanningInlineBox = 2
    case RootInlineBox = 4
    case AtomicInlineBox = 8
    case LineBreakBox = 16
    case GenericInlineLevelBox = 32
  }

  struct PositionWithinLayoutBox: OptionSet {
    let rawValue: UInt8
    static let First = PositionWithinLayoutBox(rawValue: 1 << 0)
    static let Last = PositionWithinLayoutBox(rawValue: 1 << 1)
  }

  init(
    layoutBox: BoxWrapper, style: RenderStyleWrapper, logicalLeft: InlineLayoutUnit,
    logicalSize: InlineLayoutSize, type: Type_,
    positionWithinLayoutBox: PositionWithinLayoutBox = PositionWithinLayoutBox.First
  ) {
    self.layoutBox = layoutBox
    self.logicalRect = InlineRect(
      top: InlineLayoutUnit(), left: logicalLeft, width: logicalSize.width,
      height: logicalSize.height)
    // Normally we set inline box's has-content state as we come across child content, but ruby annotations are not visible to inline layout.
    self.hasContent = layoutBox.isRubyBase() && layoutBox.associatedRubyAnnotationBox() != nil
    self.isFirstWithinLayoutBox = positionWithinLayoutBox.contains(PositionWithinLayoutBox.First)
    self.isLastWithinLayoutBox = positionWithinLayoutBox.contains(PositionWithinLayoutBox.Last)
    self.type = type
    self.style = Style(
      primaryFontMetrics: style.fontCascade().metricsOfPrimaryFont(),
      lineHeight: style.lineHeight(), lineFitEdge: style.lineFitEdge(),
      lineBoxContain: style.lineBoxContain(),
      primaryFontSize: InlineLayoutUnit(style.fontCascade().fontDescription().computedSize()),
      verticalAlignment: VerticalAlignment())
    self.style.verticalAlignment.type = style.verticalAlign()
    if self.style.verticalAlignment.type == .Length {
      self.style.verticalAlignment.baselineOffset = floatValueForLength(
        length: style.verticalAlignLength(), maximumValue: LayoutUnit(value: preferredLineHeight()))
    }
  }

  func isFirstBox() -> Bool {
    return isFirstWithinLayoutBox
  }

  func isLastBox() -> Bool {
    return isLastWithinLayoutBox
  }

  func logicalTop() -> InlineLayoutUnit { return logicalRect.top() }

  func logicalBottom() -> InlineLayoutUnit { return logicalRect.bottom() }

  func logicalLeft() -> InlineLayoutUnit { return logicalRect.left() }

  func logicalRight() -> InlineLayoutUnit { return logicalRect.right() }

  func logicalWidth() -> InlineLayoutUnit { return logicalRect.width() }

  func logicalHeight() -> InlineLayoutUnit { return logicalRect.height() }

  // FIXME: Remove legacy rounding.
  func setLogicalWidth(logicalWidth: InlineLayoutUnit) { logicalRect.setWidth(width: logicalWidth) }

  func setLogicalHeight(logicalHeight: InlineLayoutUnit) {
    logicalRect.setHeight(height: logicalHeight)
  }

  func setLogicalTop(logicalTop: InlineLayoutUnit) { logicalRect.setTop(top: logicalTop) }

  func setLogicalLeft(logicalLeft: InlineLayoutUnit) { logicalRect.setLeft(left: logicalLeft) }

  func setAscentAndDescent(ascentAndDescent: AscentAndDescent) {
    self.ascentAndDescent = ascentAndDescent
  }

  func setLayoutBounds(layoutBounds: AscentAndDescent) {
    self.layoutBounds = layoutBounds
  }

  func setInlineBoxContentOffsetForTextBoxTrim(offset: InlineLayoutUnit) {
    inlineBoxContentOffsetForTextBoxTrim = offset
  }

  func setIsFirstBox() {
    isFirstWithinLayoutBox = true
  }

  func setIsLastBox() {
    isLastWithinLayoutBox = true
  }

  func setTextEmphasis(textEmphasis: (InlineLayoutUnit, InlineLayoutUnit)) {
    let (above, below) = textEmphasis
    if above == 0 && below == 0 {
      return
    }
    if above != 0 {
      self.textEmphasis = TextEmphasis(above: above, below: 0)
      return
    }
    self.textEmphasis = TextEmphasis(above: 0, below: below)
  }

  struct Style {
    var primaryFontMetrics: FontMetricsWrapper
    var lineHeight: LengthWrapper
    var lineFitEdge = TextEdge()
    var lineBoxContain = LineBoxContain()
    var primaryFontSize = InlineLayoutUnit()
    var verticalAlignment = VerticalAlignment()
  }

  struct TextEmphasis {
    var above = InlineLayoutUnit()
    var below = InlineLayoutUnit()
  }

  var layoutBox = BoxWrapper()
  // This is the combination of margin and border boxes. Inline level boxes are vertically aligned using their margin boxes.
  var logicalRect = InlineRect()
  // See https://www.w3.org/TR/css-inline-3/#layout-bounds
  var layoutBounds = AscentAndDescent()
  var ascentAndDescent = AscentAndDescent()
  var inlineBoxContentOffsetForTextBoxTrim = InlineLayoutUnit()
  var hasContent = false
  var isFirstWithinLayoutBox = false
  var isLastWithinLayoutBox = false
  var type: Type_ = .InlineBox
  var style: Style
  var textEmphasis: TextEmphasis? = nil
}
