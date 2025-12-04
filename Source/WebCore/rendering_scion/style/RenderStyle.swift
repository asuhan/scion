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

enum CSSPropertyID {
  case CSSPropertyColor
  case CSSPropertyDisplay
  case CSSPropertyBackgroundColor
  case CSSPropertyTextDecorationColor
  case CSSPropertyTextEmphasisColor
  case CSSPropertyWebkitTextFillColor
  case CSSPropertyBorderBottomColor
  case CSSPropertyBorderLeftColor
  case CSSPropertyBorderRightColor
  case CSSPropertyBorderTopColor
}

struct PseudoStyleCache {
  let styles: [RenderStyleWrapper]
}

func isSkippedContentRoot(style: RenderStyleWrapper, element: ElementWrapper?) -> Bool {
  if style.contentVisibility() == .Visible {
    return false
  }
  // FIXME (https://bugs.webkit.org/show_bug.cgi?id=265020): check more display types.
  // FIXME: try to avoid duplication with shouldApplySizeOrStyleContainment.
  let displayType = style.display()
  if (displayType != .TableCaption && style.isDisplayTableOrTablePart()) || displayType == .Contents
  {
    return false
  }
  if style.contentVisibility() == .Hidden {
    return true
  }
  assert(style.contentVisibility() == .Auto)
  return element != nil && !element!.isRelevantToUser()
}

class RenderStyleWrapper: Equatable {
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

  static func create() -> RenderStyleWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func clone(style: RenderStyleWrapper) -> RenderStyleWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func cloneIncludingPseudoElements(style: RenderStyleWrapper) -> RenderStyleWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func createAnonymousStyleWithDisplay(parentStyle: RenderStyleWrapper, display: DisplayType)
    -> RenderStyleWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func createStyleInheritingFromPseudoStyle(pseudoStyle: RenderStyleWrapper)
    -> RenderStyleWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func == (this: RenderStyleWrapper, other: RenderStyleWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func inheritFrom(inheritParent: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func copyContentFrom(other: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func copyPseudoElementsFrom(other: RenderStyleWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func resolvedJustifyContentPosition(normalValueBehavior: StyleContentAlignmentData)
    -> ContentPosition
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func resolvedJustifyContentDistribution(normalValueBehavior: StyleContentAlignmentData)
    -> ContentDistribution
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func resolvedAlignContentPosition(normalValueBehavior: StyleContentAlignmentData)
    -> ContentPosition
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func resolvedAlignContentDistribution(normalValueBehavior: StyleContentAlignmentData)
    -> ContentDistribution
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func resolvedAlignSelf(parentStyle: RenderStyleWrapper?, normalValueBehaviour: ItemPosition)
    -> StyleSelfAlignmentData
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func resolvedJustifySelf(parentStyle: RenderStyleWrapper?, normalValueBehaviour: ItemPosition)
    -> StyleSelfAlignmentData
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pseudoElementType() -> PseudoId {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return PseudoId(rawValue: wk_interop.RenderStyle_pseudoElementType(p))!
  }

  func setPseudoElementType(pseudoElementType: PseudoId) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pseudoElementNameArgument() -> AtomStringWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func getCachedPseudoStyle(pseudoElementIdentifier: Style.PseudoElementIdentifier)
    -> RenderStyleWrapper?
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func addCachedPseudoStyle(pseudo: RenderStyleWrapper?) -> RenderStyleWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func cachedPseudoStyles() -> PseudoStyleCache? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFloating() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func position() -> PositionType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasOutOfFlowPosition() -> Bool {
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

  func logicalMinWidth() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalMaxWidth() -> LengthWrapper {
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

  func border() -> BorderData {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderLeft() -> BorderValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderRight() -> BorderValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderTop() -> BorderValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderBottom() -> BorderValue {
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

  func hasBorder() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasVisibleBorderDecoration() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasVisibleBorder() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBackgroundImage() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasUsedAppearance() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBackground() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func imageOutsets(image: NinePieceImage) -> LayoutBoxExtent {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBorderImageOutsets() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderImageOutsets() -> LayoutBoxExtent {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func maskBorderOutsets() -> LayoutBoxExtent {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func filterOutsets() -> IntOutsets {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func hasDisplayAffectedByAnimations() -> Bool {
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

  func left() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func right() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_hasStaticInlinePosition(p, horizontal)
  }

  func hasStaticBlockPosition(horizontal: Bool) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasViewportConstrainedPosition() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func floating() -> Float {
    if p == nil {
      fatalError("Not implemented")
    }
    return Float(rawValue: wk_interop.RenderStyle_floating(p))!
  }

  static func usedFloat(renderer: RenderObjectWrapper) -> UsedFloat {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderImage() -> NinePieceImage {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderRadii() -> BorderDataRadii {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBorderRadius() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasOutline() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overflowX() -> Overflow {
    if p == nil {
      fatalError("Not implemented")
    }
    return Overflow(rawValue: wk_interop.RenderStyle_overflowX(p))!
  }

  func overflowY() -> Overflow {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isOverflowVisible() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overscrollBehaviorX() -> OverscrollBehavior {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overscrollBehaviorY() -> OverscrollBehavior {
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

  func preserveNewline() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func textShadow() -> ShadowData? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func opacity() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasOpacity() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func usedAppearance() -> StyleAppearance {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func marginStartUsing(otherStyle: RenderStyleWrapper) -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginEndUsing(otherStyle: RenderStyleWrapper) -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginBeforeUsing(otherStyle: RenderStyleWrapper) -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginAfterUsing(otherStyle: RenderStyleWrapper) -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func direction() -> TextDirection {
    return inheritedFlags.direction
  }

  func isLeftToRightDirection() -> Bool {
    return direction() == .LTR
  }

  func aspectRatioType() -> AspectRatioType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func aspectRatioWidth() -> Float64 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func aspectRatioHeight() -> Float64 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func logicalAspectRatio() -> Float64 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boxSizingForAspectRatio() -> BoxSizing {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAspectRatio() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boxAlign() -> BoxAlignment {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boxOrient() -> BoxOrient {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridColumnTrackSizes() -> ArraySlice<GridTrackSize> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridRowTrackSizes() -> ArraySlice<GridTrackSize> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridAutoRepeatColumns() -> ArraySlice<GridTrackSize> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridAutoRepeatRows() -> ArraySlice<GridTrackSize> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridAutoRepeatColumnsInsertionPoint() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridAutoRepeatRowsInsertionPoint() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isGridAutoFlowDirectionColumn() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isGridAutoFlowAlgorithmDense() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func columnCount() -> UInt16 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func columnSpan() -> ColumnSpan {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func setFloating(v: Float) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func getRoundedInnerBorderFor(
    borderRect: LayoutRectWrapper, topWidth: LayoutUnit, bottomWidth: LayoutUnit,
    leftWidth: LayoutUnit, rightWidth: LayoutUnit,
    includeLogicalLeftEdge: Bool = true,
    includeLogicalRightEdge: Bool = true
  ) -> RoundedRect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func getRoundedInnerBorderFor(
    borderRect: LayoutRectWrapper, topWidth: LayoutUnit, bottomWidth: LayoutUnit,
    leftWidth: LayoutUnit, rightWidth: LayoutUnit, radii: BorderData.Radii?,
    isHorizontalWritingMode: Bool, includeLogicalLeftEdge: Bool, includeLogicalRightEdge: Bool
  ) -> RoundedRect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func clip() -> LengthBox {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasClip() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func textDecorationLine() -> TextDecorationLine {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func textDecorationStyle() -> TextDecorationStyle {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderLeftWidth() -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_borderLeftWidth(p)
  }

  func borderLeftStyle() -> BorderStyle {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderLeftIsTransparent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderRightWidth() -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_borderRightWidth(p)
  }

  func borderRightStyle() -> BorderStyle {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderRightIsTransparent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderTopWidth() -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_borderTopWidth(p)
  }

  func borderTopStyle() -> BorderStyle {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderTopIsTransparent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderBottomWidth() -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_borderBottomWidth(p)
  }

  func borderBottomStyle() -> BorderStyle {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderBottomIsTransparent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outlineSize() -> Float32 {
    if p == nil {
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_outlineSize(p)
  }

  func outlineStyleIsAuto() -> OutlineIsAuto {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasOutlineInVisualOverflow() -> Bool {
    if p == nil {
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_hasOutlineInVisualOverflow(p)
  }

  func clipLeft() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipRight() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipTop() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipBottom() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clear() -> Clear {
    if p == nil {
      fatalError("Not implemented")
    }
    return Clear(rawValue: wk_interop.RenderStyle_clear(p))!
  }

  static func usedClear(renderer: RenderObjectWrapper) -> UsedClear {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func textIndent() -> LengthWrapper {
    if p == nil {
      fatalError("Not implemented")
    }
    return LengthWrapper(p: wk_interop.RenderStyle_textIndent(p))
  }

  func textDecorationThickness() -> TextDecorationThickness {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func marginTrim() -> MarginTrimType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func usedZoom() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func backgroundClip() -> FillBox {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func backgroundSizeType() -> FillSizeType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func backgroundSizeLength() -> LengthSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func backgroundLayers() -> FillLayerWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func maskLayers() -> FillLayerWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func maskBorder() -> NinePieceImage {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func emptyCells() -> EmptyCell {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func listStyleType() -> ListStyleType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func listStyleImage() -> StyleImage? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func insideDefaultButton() -> Bool {
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

  func hasAutoOrphans() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func breakInside() -> BreakInside {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func breakBefore() -> BreakBetween {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func breakAfter() -> BreakBetween {
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

  func containsLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func contentVisibility() -> ContentVisibility {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // usedContentVisibility will return ContentVisibility::Hidden in a content-visibility: hidden subtree (overriding
  // content-visibility: auto at all times), ContentVisibility::Auto in a content-visibility: auto subtree (when the
  // content is not user relevant and thus skipped), and ContentVisibility::Visible otherwise.
  func usedContentVisibility() -> ContentVisibility {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Returns true for skipped content roots and skipped content itself.
  func hasSkippedContent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func containIntrinsicLogicalWidthHasAuto() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func containIntrinsicLogicalHeightHasAuto() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAutoLengthContainIntrinsicSize() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func order() -> Int {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func flexGrow() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func flexShrink() -> Float32 {
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

  func isRowFlexDirection() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isColumnFlexDirection() -> Bool {
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

  func gridSubgridRows() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridSubgridColumns() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridMasonryRows() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridMasonryColumns() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boxShadow() -> ShadowData? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boxShadowExtent() -> LayoutBoxExtent {
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

  func boxReflect() -> StyleReflection? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boxSizing() -> BoxSizing {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marqueeBehavior() -> MarqueeBehavior {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marqueeDirection() -> MarqueeDirection {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func usedUserSelect() -> UserSelect {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func resize() -> Resize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasInlineColumnAxis() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func columnProgression() -> ColumnProgression {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func columnWidth() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAutoColumnWidth() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAutoColumnCount() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func specifiesColumns() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func columnGap() -> GapLength {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rowGap() -> GapLength {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func transform() -> TransformOperations {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasTransform() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func transformOriginX() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func transformOriginY() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func transformOriginZ() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func transformBox() -> TransformBox {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func rotate() -> RotateTransformOperation? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func scale() -> ScaleTransformOperation? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func translate() -> TranslateTransformOperation? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func textOrientation() -> TextOrientation {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  struct TransformOperationOption: OptionSet {
    let rawValue: UInt8

    static let TransformOrigin = TransformOperationOption(rawValue: 1 << 0)
    static let Translate = TransformOperationOption(rawValue: 1 << 1)
    static let Rotate = TransformOperationOption(rawValue: 1 << 2)
    static let Scale = TransformOperationOption(rawValue: 1 << 3)
    static let Offset = TransformOperationOption(rawValue: 1 << 4)
  }

  static let allTransformOperations: TransformOperationOption = [
    .TransformOrigin, .Translate, .Rotate, .Scale, .Offset,
  ]

  static let individualTransformOperations: TransformOperationOption = [
    .Translate, .Rotate, .Scale, .Offset,
  ]

  func hasMask() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func backfaceVisibility() -> BackfaceVisibility {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func perspective() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasPerspective() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func perspectiveOriginX() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func perspectiveOriginY() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func scrollbarGutter() -> ScrollbarGutter {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func isFlippedLinesWritingMode() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_isFlippedLinesWritingMode(p)
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

  func imageRendering() -> ImageRendering {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func filter() -> FilterOperations {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasFilter() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func appleColorFilter() -> FilterOperations {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAppleColorFilter() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBackdropFilter() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func blendMode() -> BlendMode {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBlendMode() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isolation() -> Isolation {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasIsolation() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setDisplay(value: DisplayType) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setPosition(v: PositionType) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMaskBorder(image: NinePieceImage) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func printColorAdjust() -> PrintColorAdjust {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func usedZIndex() -> Int32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAutoUsedZIndex() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setUsedZIndex(index: Int32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTransform(operations: TransformOperations) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTransformOriginX(length: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTransformOriginY(length: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLineBoxContain(c: LineBoxContain) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func paintTypesForPaintOrder(order: PaintOrder) -> ArraySlice<PaintType> {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computedStrokeWidth(viewportSize: IntSize) -> Float32 {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_computedStrokeWidth(p, viewportSize.width, viewportSize.height)
  }

  func clipPath() -> PathOperation? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func contentData() -> ContentData? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hyphenString() -> AtomStringWrapper {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return AtomStringWrapper(p: wk_interop.RenderStyle_hyphenString(p))
  }

  func isDisplayInlineType() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isOriginalDisplayInlineType() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_isOriginalDisplayInlineType(p)
  }

  func isDisplayBlockLevel() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isDisplayTableOrTablePart() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isOriginalDisplayListItemType() -> Bool {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return wk_interop.RenderStyle_isOriginalDisplayListItemType(p)
  }

  func visitedDependentColor(colorProperty: CSSPropertyID, paintBehavior: PaintBehavior = [])
    -> ColorWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func visitedDependentColorWithColorFilter(
    colorProperty: CSSPropertyID, paintBehavior: PaintBehavior = []
  ) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func colorByApplyingColorFilter(color: ColorWrapper) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func colorWithColorFilter(color: StyleColorWrapper) -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func initialDisplay() -> DisplayType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  func usedPointerEvents() -> PointerEvents {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func usedTransformStyle3D() -> TransformStyle3D {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func preserves3D() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setUnicodeBidi(v: UnicodeBidi) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTextWrapMode(v: TextWrapMode) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  @discardableResult
  func setFontDescription(description: FontCascadeDescriptionWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func capStyle() -> LineCap {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func paintOrder() -> PaintOrder {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func joinStyle() -> LineJoin {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computedStrokeColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func strokeMiterLimit() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasExplicitlySetColor() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func quotes() -> QuotesData? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func willChange() -> WillChangeData? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Resolves the currentColor keyword, but must not be used for the "color" property which has a different semantic.
  func colorResolvingCurrentColor(color: StyleColorWrapper, visitedLink: Bool = false)
    -> ColorWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func initialMinSize() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func initialMaxSize() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func offsetPath() -> PathOperation? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func offsetDistance() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func offsetPosition() -> LengthPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func offsetAnchor() -> LengthPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func offsetRotate() -> OffsetRotation {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func blockStepSize() -> LengthWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

func collapsedBorderStyle(style: BorderStyle) -> BorderStyle {
  if style == .Outset {
    return .Groove
  }
  if style == .Inset {
    return .Ridge
  }
  return style
}

func pseudoElementRendererIsNeeded(style: RenderStyleWrapper?) -> Bool {
  return style != nil && style!.display() != .None && style!.contentData() != nil
}
