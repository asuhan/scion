/*
 * Copyright (C) 2000 Lars Knoll (knoll@kde.org)
 *           (C) 2000 Antti Koivisto (koivisto@kde.org)
 *           (C) 2000 Dirk Mueller (mueller@kde.org)
 * Copyright (C) 2003-2023 Apple Inc. All rights reserved.
 * Copyright (C) 2014-2021 Google Inc. All rights reserved.
 * Copyright (C) 2006 Graham Dennis (graham.dennis@gmail.com)
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

typealias LayoutBoxExtent = RectEdges<LayoutUnit>

class RenderStyleWrapper {
  var p: UnsafeRawPointer?

  init(
    unicodeBidi: UnicodeBidi = .Normal,
    tabSize: TabSizeWrapper = TabSizeWrapper(numOrLength: 0, isSpaces: .LengthValueType),
    fontCascade: FontCascadeWrapper = FontCascadeWrapper(),
    direction: TextDirection = .LTR,
    whiteSpaceCollapse: WhiteSpaceCollapse = .Collapse,
    textWrapMode: TextWrapMode = .Wrap
  ) {
    nonInheritedFlags.unicodeBidi = unicodeBidi
    rareInheritedData.tabSize = tabSize
    inheritedData.fontCascade = fontCascade
    inheritedFlags.direction = direction
    inheritedFlags.whiteSpaceCollapse = whiteSpaceCollapse
    inheritedFlags.textWrapMode = textWrapMode
  }

  func pseudoElementType() -> PseudoId {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return PseudoId(rawValue: wk_interop.RenderStyle_pseudoElementType(p))!
  }

  func position() -> PositionType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func width() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func height() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func minWidth() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func maxWidth() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func minHeight() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func maxHeight() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalWidth() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalHeight() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalMinHeight() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalMaxHeight() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func fontCascade() -> FontCascadeWrapper {
    return inheritedData.fontCascade
  }

  func metricsOfPrimaryFont() -> FontMetricsWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return FontMetricsWrapper(p: wk_interop.RenderStyle_metricsOfPrimaryFont(p))
  }

  func fontDescription() -> FontCascadeDescriptionWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return FontCascadeDescriptionWrapper(p: wk_interop.RenderStyle_fontDescription(p))
  }

  func computedFontSize() -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_computedFontSize(p)
  }

  func rtlOrdering() -> Order {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return Order(rawValue: wk_interop.RenderStyle_rtlOrdering(p))!
  }

  func hasPseudoStyle(pseudo: PseudoId) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func display() -> DisplayType {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return DisplayType(rawValue: wk_interop.RenderStyle_display(p))!
  }

  func top() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func bottom() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalLeft() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalRight() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalTop() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalBottom() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Whether or not a positioned element requires normal flow x/y to be computed to determine its position.
  func hasStaticInlinePosition(horizontal: Bool) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasStaticBlockPosition(horizontal: Bool) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func floating() -> Float {
    if p == nil {
      fatalError("Not implemented")
    }
    return Float(rawValue: wk_interop.RenderStyle_floating(p))!
  }

  func overflowX() -> Overflow {
    if p == nil {
      fatalError("Not implemented")
    }
    return Overflow(rawValue: wk_interop.RenderStyle_overflowX(p))!
  }

  func isOverflowVisible() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func usedVisibility() -> Visibility {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return Visibility(rawValue: wk_interop.RenderStyle_usedVisibility(p))!
  }

  func verticalAlign() -> VerticalAlign {
    if p == nil {
      fatalError("Not implemented")
    }
    return VerticalAlign(rawValue: wk_interop.RenderStyle_verticalAlign(p))!
  }

  func verticalAlignLength() -> LengthWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LengthWrapper(p: wk_interop.RenderStyle_verticalAlignLength(p))
  }

  func lineHeight() -> LengthWrapper {
    if p == nil {
      fatalError("Not implemented")
    }
    return LengthWrapper(p: wk_interop.RenderStyle_lineHeight(p))
  }

  func computedLineHeight() -> Float32 {
    if p == nil {
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_computedLineHeight(p)
  }

  func whiteSpace() -> WhiteSpace {
    let whiteSpaceCollapse = inheritedFlags.whiteSpaceCollapse
    let textWrapMode = inheritedFlags.textWrapMode
    if whiteSpaceCollapse == .BreakSpaces && textWrapMode == .Wrap {
      return .BreakSpaces
    }
    if whiteSpaceCollapse == .Collapse && textWrapMode == .Wrap {
      return .Normal
    }
    if whiteSpaceCollapse == .Collapse && textWrapMode == .NoWrap {
      return .NoWrap
    }
    if whiteSpaceCollapse == .Preserve && textWrapMode == .NoWrap {
      return .Pre
    }
    if whiteSpaceCollapse == .PreserveBreaks && textWrapMode == .Wrap {
      return .PreLine
    }
    if whiteSpaceCollapse == .Preserve && textWrapMode == .Wrap {
      return .PreWrap
    }

    // Reachable for combinations that can't be represented with the
    // white-space syntax. Do nothing for now since this is a temporary
    // function.
    return .Normal
  }

  func autoWrap() -> Bool {
    if p == nil {
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_autoWrap(p)
  }

  func textShadowExtent() -> LayoutBoxExtent {
    if p == nil {
      fatalError("Not implemented")
    }
    let top = LayoutUnit.fromRawValue(value: wk_interop.RenderStyle_textShadowExtent_top(p))
    let right = LayoutUnit.fromRawValue(value: wk_interop.RenderStyle_textShadowExtent_right(p))
    let bottom = LayoutUnit.fromRawValue(value: wk_interop.RenderStyle_textShadowExtent_bottom(p))
    let left = LayoutUnit.fromRawValue(value: wk_interop.RenderStyle_textShadowExtent_left(p))
    return LayoutBoxExtent(top: top, right: right, bottom: bottom, left: left)
  }

  func collapseWhiteSpace(mode: WhiteSpace) -> Bool {
    // Pre and prewrap do not collapse whitespace.
    return mode != .Pre && mode != .PreWrap && mode != .BreakSpaces
  }

  func collapseWhiteSpace() -> Bool {
    return collapseWhiteSpace(mode: whiteSpace())
  }

  func marginStart() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginBefore() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginAfter() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginEnd() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func direction() -> TextDirection {
    return inheritedFlags.direction
  }

  func isLeftToRightDirection() -> Bool {
    return direction() == .LTR
  }

  func textEmphasisMark() -> TextEmphasisMark {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return TextEmphasisMark(rawValue: wk_interop.RenderStyle_textEmphasisMark(p))!
  }

  func textEmphasisPosition() -> TextEmphasisPosition {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return TextEmphasisPosition(rawValue: wk_interop.RenderStyle_textEmphasisPosition(p))
  }

  func hasTextCombine() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_hasTextCombine(p)
  }

  func tabSize() -> TabSizeWrapper {
    return rareInheritedData.tabSize
  }

  func textAlignLast() -> TextAlignLast {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return TextAlignLast(rawValue: wk_interop.RenderStyle_textAlignLast(p))!
  }

  func unicodeBidi() -> UnicodeBidi {
    return nonInheritedFlags.unicodeBidi
  }

  func textDecorationsInEffect() -> TextDecorationLine {
    if p == nil {
      fatalError("Not implemented")
    }
    return TextDecorationLine(rawValue: wk_interop.RenderStyle_textDecorationsInEffect(p))
  }

  func borderLeftWidth() -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_borderLeftWidth(p)
  }

  func borderRightWidth() -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_borderRightWidth(p)
  }

  func borderTopWidth() -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_borderTopWidth(p)
  }

  func borderBottomWidth() -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_borderBottomWidth(p)
  }

  func outlineSize() -> Float32 {
    if p == nil {
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_outlineSize(p)
  }

  func hasOutlineInVisualOverflow() -> Bool {
    if p == nil {
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_hasOutlineInVisualOverflow(p)
  }

  func clear() -> Clear {
    if p == nil {
      fatalError("Not implemented")
    }
    return Clear(rawValue: wk_interop.RenderStyle_clear(p))!
  }

  func textIndent() -> LengthWrapper {
    if p == nil {
      fatalError("Not implemented")
    }
    return LengthWrapper(p: wk_interop.RenderStyle_textIndent(p))
  }

  func textIndentLine() -> TextIndentLine {
    return rareInheritedData.textIndentLine
  }

  func textBoxEdge() -> TextEdge {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lineFitEdge() -> TextEdge {
    if p == nil {
      fatalError("Not implemented")
    }
    let packed = wk_interop.RenderStyle_lineFitEdge(p)
    let over = TextEdgeType(rawValue: UInt8(packed / 256))!
    let under = TextEdgeType(rawValue: UInt8(packed % 256))!
    return TextEdge(over: over, under: under)
  }

  func textIndentType() -> TextIndentType {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return TextIndentType(rawValue: wk_interop.RenderStyle_textIndentType(p))!
  }

  func textAlign() -> TextAlignMode {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return TextAlignMode(rawValue: wk_interop.RenderStyle_textAlign(p))!
  }

  func textDecorationSkipInk() -> TextDecorationSkipInk {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return TextDecorationSkipInk(rawValue: wk_interop.RenderStyle_textDecorationSkipInk(p))!
  }

  func whiteSpaceCollapse() -> WhiteSpaceCollapse {
    return inheritedFlags.whiteSpaceCollapse
  }

  func textWrapMode() -> TextWrapMode {
    return inheritedFlags.textWrapMode
  }

  func textWrapStyle() -> TextWrapStyle {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return TextWrapStyle(rawValue: wk_interop.RenderStyle_textWrapStyle(p))!
  }

  func marginTop() -> LengthWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LengthWrapper(p: wk_interop.RenderStyle_marginTop(p))
  }

  func marginBottom() -> LengthWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LengthWrapper(p: wk_interop.RenderStyle_marginBottom(p))
  }

  func marginLeft() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_marginLeft(p))
  }

  func marginRight() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_marginRight(p))
  }

  func paddingTop() -> LengthWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LengthWrapper(p: wk_interop.RenderStyle_paddingTop(p))
  }

  func paddingBottom() -> LengthWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LengthWrapper(p: wk_interop.RenderStyle_paddingBottom(p))
  }

  func paddingLeft() -> LengthWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LengthWrapper(p: wk_interop.RenderStyle_paddingLeft(p))
  }

  func paddingRight() -> LengthWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LengthWrapper(p: wk_interop.RenderStyle_paddingRight(p))
  }

  func paddingBefore() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingAfter() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingStart() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paddingEnd() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func widows() -> UInt16 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func orphans() -> UInt16 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAutoWidows() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func breakInside() -> BreakInside {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hangingPunctuation() -> HangingPunctuation {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return HangingPunctuation(rawValue: wk_interop.RenderStyle_hangingPunctuation(p))
  }

  func order() -> Int {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func flexBasis() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func alignContent() -> StyleContentAlignmentData {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func alignItems() -> StyleSelfAlignmentData {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func alignSelf() -> StyleSelfAlignmentData {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func flexDirection() -> FlexDirection {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func flexWrap() -> FlexWrap {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func justifyContent() -> StyleContentAlignmentData {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boxDecorationBreak() -> BoxDecorationBreak {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return BoxDecorationBreak(rawValue: wk_interop.RenderStyle_boxDecorationBreak(p))!
  }

  func textOverflow() -> TextOverflow {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return TextOverflow(rawValue: wk_interop.RenderStyle_textOverflow(p))!
  }

  func wordBreak() -> WordBreak {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return WordBreak(rawValue: wk_interop.RenderStyle_wordBreak(p))!
  }

  func overflowWrap() -> OverflowWrap {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return OverflowWrap(rawValue: wk_interop.RenderStyle_overflowWrap(p))!
  }

  func wordSpacing() -> Float32 {
    return inheritedData.fontCascade.wordSpacing()
  }

  func nbspMode() -> NBSPMode {
    if p == nil {
      return rareInheritedData.nbspMode ? .Space : .Normal
    }
    let nbspModeRaw = UInt8(wk_interop.RenderStyle_nbspMode(p) ? 1 : 0)
    return NBSPMode(rawValue: nbspModeRaw)!
  }

  func lineBreak() -> LineBreak {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LineBreak(rawValue: wk_interop.RenderStyle_lineBreak(p))!
  }

  func hyphenationLimitLines() -> Int16 {
    if p == nil {
      return rareInheritedData.hyphenationLimitLines
    }
    return RenderStyle_hyphenationLimitLines(p)
  }

  func hyphens() -> Hyphens {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return Hyphens(rawValue: wk_interop.RenderStyle_hyphens(p))!
  }

  func hyphenationLimitBefore() -> Int16 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return RenderStyle_hyphenationLimitBefore(p)
  }

  func hyphenationLimitAfter() -> Int16 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return RenderStyle_hyphenationLimitAfter(p)
  }

  func computedLocale() -> AtomStringWrapper {
    if p == nil {
      fatalError("Not implemented")
    }
    return AtomStringWrapper(p: wk_interop.RenderStyle_computedLocale(p))
  }

  func textEmphasisMarkString() -> AtomStringWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return AtomStringWrapper(p: wk_interop.RenderStyle_textEmphasisMarkString(p))
  }

  func rubyPosition() -> RubyPosition {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return RubyPosition(rawValue: wk_interop.RenderStyle_rubyPosition(p))!
  }

  func isInterCharacterRubyPosition() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_isInterCharacterRubyPosition(p)
  }

  func rubyAlign() -> RubyAlign {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return RubyAlign(rawValue: wk_interop.RenderStyle_rubyAlign(p))!
  }

  func rubyOverhang() -> RubyOverhang {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return RubyOverhang(rawValue: wk_interop.RenderStyle_rubyOverhang(p))!
  }

  func lineBoxContain() -> LineBoxContain {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LineBoxContain(rawValue: wk_interop.RenderStyle_lineBoxContain(p))
  }

  func blockEllipsis() -> BlockEllipsis {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    let blockEllipsisRaw = wk_interop.RenderStyle_blockEllipsis(p)
    let type = BlockEllipsis.Type_(rawValue: blockEllipsisRaw.type)!
    return BlockEllipsis(type: type, string: AtomStringWrapper(p: blockEllipsisRaw.string))
  }

  func initialLetterDrop() -> Int32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_initialLetterDrop(p)
  }

  func initialLetterHeight() -> Int32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_initialLetterHeight(p)
  }

  func writingMode() -> WritingMode {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return WritingMode(rawValue: wk_interop.RenderStyle_writingMode(p))!
  }

  func isHorizontalWritingMode() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_isHorizontalWritingMode(p)
  }

  func isVerticalWritingMode() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_isVerticalWritingMode(p)
  }

  func isFlippedBlocksWritingMode() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_isFlippedBlocksWritingMode(p)
  }

  func blockFlowDirection() -> FlowDirection {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return FlowDirection(rawValue: wk_interop.RenderStyle_blockFlowDirection(p))!
  }

  func computedStrokeWidth(viewportSize: IntSize) -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_computedStrokeWidth(p, viewportSize.width, viewportSize.height)
  }

  func hyphenString() -> AtomStringWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return AtomStringWrapper(p: wk_interop.RenderStyle_hyphenString(p))
  }

  func isOriginalDisplayInlineType() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_isOriginalDisplayInlineType(p)
  }

  func isOriginalDisplayListItemType() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_isOriginalDisplayListItemType(p)
  }

  static func initialTextAlign() -> TextAlignMode {
    return .Start
  }

  static func initialTextIndent() -> LengthWrapper {
    return zeroLength()
  }

  static func zeroLength() -> LengthWrapper {
    return LengthWrapper(type: .Fixed)
  }

  static func initialBoxDecorationBreak() -> BoxDecorationBreak {
    return .Slice
  }

  static func initialHyphenationLimitBefore() -> Int16 {
    return -1
  }

  static func initialHyphenationLimitAfter() -> Int16 {
    return -1
  }

  static func initialHyphenationLimitLines() -> Int16 {
    return -1
  }

  static func initialLineBoxContain() -> LineBoxContain {
    return [.Block, .Inline, .Replaced]
  }

  func letterSpacing() -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_letterSpacing(p)
  }

  func getBoxShadowHorizontalExtent(left: inout LayoutUnit, right: inout LayoutUnit) {
    left = LayoutUnit.fromRawValue(
      value: wk_interop.RenderStyle_getBoxShadowHorizontalExtentLeft(p))
    right = LayoutUnit.fromRawValue(
      value: wk_interop.RenderStyle_getBoxShadowHorizontalExtentRight(p))
  }

  func getBoxShadowVerticalExtent(top: inout LayoutUnit, bottom: inout LayoutUnit) {
    top = LayoutUnit.fromRawValue(value: wk_interop.RenderStyle_getBoxShadowVerticalExtentTop(p))
    bottom = LayoutUnit.fromRawValue(
      value: wk_interop.RenderStyle_getBoxShadowVerticalExtentBottom(p))
  }

  func lineAlign() -> LineAlign {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LineAlign(rawValue: wk_interop.RenderStyle_lineAlign(p))!
  }

  func lineSnap() -> LineSnap {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LineSnap(rawValue: wk_interop.RenderStyle_lineSnap(p))!
  }

  struct NonInheritedFlags {
    var effectiveDisplay: DisplayType = .Inline
    var clear: Clear = .None
    var unicodeBidi: UnicodeBidi = .Normal
    var floating: Float = .None
    var pseudoElementType: PseudoId = .None
  }

  struct InheritedFlags {
    var writingMode: WritingMode = .HorizontalTb
    var direction: TextDirection = .LTR
    var whiteSpaceCollapse: WhiteSpaceCollapse = .Collapse
    var textWrapMode: TextWrapMode = .NoWrap
    var textAlign: TextAlignMode = .Left
    var textWrapStyle: TextWrapStyle = .Auto
    var rtlOrdering: Order = .Logical
  }

  var nonInheritedFlags = NonInheritedFlags()

  var rareInheritedData = StyleRareInheritedData()
  var inheritedData = StyleInheritedData()
  var inheritedFlags = InheritedFlags()
}
