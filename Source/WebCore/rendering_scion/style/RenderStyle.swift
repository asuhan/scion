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
  case CSSPropertyInvalid
  case CSSPropertyColor
  case CSSPropertyDisplay
  case CSSPropertyAccentColor
  case CSSPropertyBackdropFilter
  case CSSPropertyBackgroundColor
  case CSSPropertyCaretColor
  case CSSPropertyClipPath
  case CSSPropertyColumnRuleColor
  case CSSPropertyFill
  case CSSPropertyFilter
  case CSSPropertyFloodColor
  case CSSPropertyLightingColor
  case CSSPropertyMixBlendMode
  case CSSPropertyOffsetAnchor
  case CSSPropertyOffsetDistance
  case CSSPropertyOffsetPath
  case CSSPropertyOffsetPosition
  case CSSPropertyOffsetRotate
  case CSSPropertyOpacity
  case CSSPropertyOutlineColor
  case CSSPropertyRotate
  case CSSPropertyScale
  case CSSPropertyStopColor
  case CSSPropertyStroke
  case CSSPropertyStrokeColor
  case CSSPropertyTextDecorationColor
  case CSSPropertyTextEmphasisColor
  case CSSPropertyTransform
  case CSSPropertyTranslate
  case CSSPropertyWebkitBackdropFilter
  case CSSPropertyWebkitTextFillColor
  case CSSPropertyWebkitTextStrokeColor
  case CSSPropertyBorderBlockEndColor
  case CSSPropertyBorderBlockStartColor
  case CSSPropertyBorderBottomColor
  case CSSPropertyBorderInlineEndColor
  case CSSPropertyBorderInlineStartColor
  case CSSPropertyBorderLeftColor
  case CSSPropertyBorderRightColor
  case CSSPropertyBorderTopColor
  case CSSPropertyMask
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

  private enum CloneTag { case Clone }

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

  private init(_ other: RenderStyleWrapper, _: CloneTag) {
    nonInheritedData = other.nonInheritedData.copy()
    nonInheritedFlags = other.nonInheritedFlags
    rareInheritedData = other.rareInheritedData.copy()
    inheritedData = other.inheritedData.copy()
    inheritedFlags = other.inheritedFlags
    m_svgStyle = other.m_svgStyle.copy()
  }

  func replace(_ newStyle: RenderStyleWrapper) -> RenderStyleWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func create() -> RenderStyleWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func clone(style: RenderStyleWrapper) -> RenderStyleWrapper {
    if style.p != nil {
      let cloned = RenderStyleWrapper()
      // TODO(asuhan): convert native fields
      cloned.p = wk_interop.RenderStyle_clone(style.p)
      return cloned
    }
    return RenderStyleWrapper(style, .Clone)
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

  func resolvedAlignItems(_ normalValueBehaviour: ItemPosition) -> StyleSelfAlignmentData {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func resolvedAlignSelf(parentStyle: RenderStyleWrapper?, normalValueBehaviour: ItemPosition)
    -> StyleSelfAlignmentData
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func resolvedAlignContent(normalValueBehavior: StyleContentAlignmentData)
    -> StyleContentAlignmentData
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

  func resolvedJustifyContent(normalValueBehavior: StyleContentAlignmentData)
    -> StyleContentAlignmentData
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func pseudoElementType() -> PseudoId {
    return PseudoId(rawValue: wk_interop.RenderStyle_pseudoElementType(p!))!
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
    let raw = wk_interop.RenderStyle_getCachedPseudoStyle(
      p, pseudoElementIdentifier.pseudoId.rawValue, pseudoElementIdentifier.nameArgument.p)
    if raw == nil {
      return nil
    }
    // TODO(asuhan): convert native fields
    let cachedStyle = RenderStyleWrapper()
    cachedStyle.p = raw
    return cachedStyle
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
    return wk_interop.RenderStyle_isFloating(p!)
  }

  func position() -> PositionType {
    return PositionType(rawValue: wk_interop.RenderStyle_position(p!))!
  }

  func hasOutOfFlowPosition() -> Bool { return position() == .Absolute || position() == .Fixed }

  func hasInFlowPosition() -> Bool { return position() == .Relative || position() == .Sticky }

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

  func borderBefore() -> BorderValue { return borderBefore(styleForFlow: self) }

  func borderAfter() -> BorderValue { return borderAfter(styleForFlow: self) }

  func borderStart() -> BorderValue { return borderStart(styleForFlow: self) }

  func borderEnd() -> BorderValue { return borderEnd(styleForFlow: self) }

  func borderBefore(styleForFlow: RenderStyleWrapper) -> BorderValue {
    switch styleForFlow.blockFlowDirection() {
    case .TopToBottom:
      return borderTop()
    case .BottomToTop:
      return borderBottom()
    case .LeftToRight:
      return borderLeft()
    case .RightToLeft:
      return borderRight()
    }
  }

  func borderAfter(styleForFlow: RenderStyleWrapper) -> BorderValue {
    switch styleForFlow.blockFlowDirection() {
    case .TopToBottom:
      return borderBottom()
    case .BottomToTop:
      return borderTop()
    case .LeftToRight:
      return borderRight()
    case .RightToLeft:
      return borderLeft()
    }
  }

  func borderStart(styleForFlow: RenderStyleWrapper) -> BorderValue {
    if styleForFlow.isHorizontalWritingMode() {
      return styleForFlow.isLeftToRightDirection() ? borderLeft() : borderRight()
    }
    return styleForFlow.isLeftToRightDirection() ? borderTop() : borderBottom()
  }

  func borderEnd(styleForFlow: RenderStyleWrapper) -> BorderValue {
    if styleForFlow.isHorizontalWritingMode() {
      return styleForFlow.isLeftToRightDirection() ? borderRight() : borderLeft()
    }
    return styleForFlow.isLeftToRightDirection() ? borderBottom() : borderTop()
  }

  func fontCascade() -> FontCascadeWrapper {
    return inheritedData.fontCascade
  }

  func metricsOfPrimaryFont() -> FontMetricsWrapper {
    return FontMetricsWrapper(p: wk_interop.RenderStyle_metricsOfPrimaryFont(p!))
  }

  func fontDescription() -> FontCascadeDescriptionWrapper {
    return FontCascadeDescriptionWrapper(p: wk_interop.RenderStyle_fontDescription(p!))
  }

  func computedFontSize() -> Float32 {
    return wk_interop.RenderStyle_computedFontSize(p!)
  }

  func hasBorder() -> Bool { return wk_interop.RenderStyle_hasBorder(p!) }

  func hasBorderImage() -> Bool {
    return wk_interop.RenderStyle_hasBorderImage(p!)
  }

  func hasVisibleBorderDecoration() -> Bool {
    return hasVisibleBorder() || hasBorderImage()
  }

  func hasVisibleBorder() -> Bool {
    return wk_interop.RenderStyle_hasVisibleBorder(p!)
  }

  func hasPadding() -> Bool { return wk_interop.RenderStyle_hasPadding(p!) }

  func hasBackgroundImage() -> Bool { return wk_interop.RenderStyle_hasBackgroundImage(p!) }

  func hasAnyFixedBackground() -> Bool { return wk_interop.RenderStyle_hasAnyFixedBackground(p!) }

  func hasEntirelyFixedBackground() -> Bool {
    return wk_interop.RenderStyle_hasEntirelyFixedBackground(p!)
  }

  func hasUsedAppearance() -> Bool {
    return wk_interop.RenderStyle_hasUsedAppearance(p!)
  }

  func hasBackground() -> Bool { return wk_interop.RenderStyle_hasBackground(p!) }

  func imageOutsets(image: NinePieceImage) -> LayoutBoxExtent {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBorderImageOutsets() -> Bool { return wk_interop.RenderStyle_hasBorderImageOutsets(p!) }

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
    return Order(rawValue: wk_interop.RenderStyle_rtlOrdering(p!))!
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
      return nonInheritedFlags.effectiveDisplay
    }
    return DisplayType(rawValue: wk_interop.RenderStyle_display(p!))!
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
    return wk_interop.RenderStyle_hasStaticInlinePosition(p!, horizontal)
  }

  func hasStaticBlockPosition(horizontal: Bool) -> Bool {
    return wk_interop.RenderStyle_hasStaticBlockPosition(p!, horizontal)
  }

  func hasViewportConstrainedPosition() -> Bool {
    return wk_interop.RenderStyle_hasViewportConstrainedPosition(p!)
  }

  func floating() -> Float {
    return Float(rawValue: wk_interop.RenderStyle_floating(p!))!
  }

  static func usedFloat(renderer: RenderObjectWrapper) -> UsedFloat {
    let computedValue = renderer.style().floating()
    switch computedValue {
    case .None:
      return .None
    case .Left:
      return .Left
    case .Right:
      return .Right
    case .InlineStart, .InlineEnd:
      let containingBlockDirection = renderer.containingBlock()!.style().direction()
      if containingBlockDirection == .RTL {
        return computedValue == .InlineStart ? .Right : .Left
      }
      return computedValue == .InlineStart ? .Left : .Right
    }
  }

  func borderImage() -> NinePieceImage {
    return NinePieceImage(wk_interop.RenderStyle_borderImage(p!)!)
  }

  func borderStartWidth() -> Float32 { return wk_interop.RenderStyle_borderStartWidth(p!) }

  func borderTopLeftRadius() -> LengthSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderTopRightRadius() -> LengthSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderBottomLeftRadius() -> LengthSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderBottomRightRadius() -> LengthSize {
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

  func outlineStyle() -> BorderStyle {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overflowX() -> Overflow {
    return Overflow(rawValue: wk_interop.RenderStyle_overflowX(p!))!
  }

  func overflowY() -> Overflow {
    return Overflow(rawValue: wk_interop.RenderStyle_overflowY(p!))!
  }

  func isOverflowVisible() -> Bool { return wk_interop.RenderStyle_isOverflowVisible(p!) }

  func overscrollBehaviorX() -> OverscrollBehavior {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func overscrollBehaviorY() -> OverscrollBehavior {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func visibility() -> Visibility {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func usedVisibility() -> Visibility {
    return Visibility(rawValue: wk_interop.RenderStyle_usedVisibility(p!))!
  }

  func verticalAlign() -> VerticalAlign {
    return VerticalAlign(rawValue: wk_interop.RenderStyle_verticalAlign(p!))!
  }

  func verticalAlignLength() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_verticalAlignLength(p!))
  }

  func lineHeight() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_lineHeight(p!))
  }

  func computedLineHeight() -> Float32 {
    return wk_interop.RenderStyle_computedLineHeight(p!)
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
    return wk_interop.RenderStyle_autoWrap(p!)
  }

  func preserveNewline() -> Bool { return wk_interop.RenderStyle_preserveNewline(p!) }

  func textShadow() -> ShadowData? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func textShadowExtent() -> LayoutBoxExtent {
    let top = LayoutUnit.fromRawValue(value: wk_interop.RenderStyle_textShadowExtent_top(p!))
    let right = LayoutUnit.fromRawValue(value: wk_interop.RenderStyle_textShadowExtent_right(p!))
    let bottom = LayoutUnit.fromRawValue(value: wk_interop.RenderStyle_textShadowExtent_bottom(p!))
    let left = LayoutUnit.fromRawValue(value: wk_interop.RenderStyle_textShadowExtent_left(p!))
    return LayoutBoxExtent(top: top, right: right, bottom: bottom, left: left)
  }

  func textStrokeWidth() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func opacity() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasOpacity() -> Bool { return wk_interop.RenderStyle_hasOpacity(p!) }

  func usedAppearance() -> StyleAppearance {
    return StyleAppearance(rawValue: wk_interop.RenderStyle_usedAppearance(p!))!
  }

  func collapseWhiteSpace(mode: WhiteSpace) -> Bool {
    // Pre and prewrap do not collapse whitespace.
    return mode != .Pre && mode != .PreWrap && mode != .BreakSpaces
  }

  func collapseWhiteSpace() -> Bool {
    return collapseWhiteSpace(mode: whiteSpace())
  }

  func isCollapsibleWhiteSpace(_ character: UChar) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginStart() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginBefore() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_marginBefore(p!))
  }

  func marginAfter() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_marginAfter(p!))
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

  func aspectRatioLogicalWidth() -> Float64 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func aspectRatioLogicalHeight() -> Float64 {
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

  func boxFlex() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boxFlexGroup() -> UInt32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boxLines() -> BoxLines {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boxOrient() -> BoxOrient {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boxPack() -> BoxPack {
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

  func gridTrackSizes(_ direction: GridTrackSizingDirection) -> ArraySlice<GridTrackSize> {
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

  func gridAutoRepeatColumnsType() -> AutoRepeatType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridAutoRepeatRowsType() -> AutoRepeatType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func namedGridAreaRowCount() -> UInt64 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func namedGridAreaColumnCount() -> UInt64 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridAutoFlow() -> GridAutoFlow {
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

  func gridAutoColumns() -> [GridTrackSize] {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridAutoRows() -> [GridTrackSize] {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func columnCount() -> UInt16 { return wk_interop.RenderStyle_columnCount(p!) }

  func columnRuleStyle() -> BorderStyle {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func columnRuleWidth() -> UInt16 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func columnRuleIsTransparent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func columnSpan() -> ColumnSpan {
    return wk_interop.RenderStyle_columnSpan(p!) ? .All : .None
  }

  func textEmphasisMark() -> TextEmphasisMark {
    return TextEmphasisMark(rawValue: wk_interop.RenderStyle_textEmphasisMark(p!))!
  }

  func textEmphasisPosition() -> TextEmphasisPosition {
    return TextEmphasisPosition(rawValue: wk_interop.RenderStyle_textEmphasisPosition(p!))
  }

  func hasTextCombine() -> Bool {
    return wk_interop.RenderStyle_hasTextCombine(p!)
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
    return TextAlignLast(rawValue: wk_interop.RenderStyle_textAlignLast(p!))!
  }

  func clip() -> LengthBox {
    let raw = wk_interop.RenderStyle_clip(p!)
    return LengthBox(
      top: LengthWrapper(p: raw.top), right: LengthWrapper(p: raw.right),
      bottom: LengthWrapper(p: raw.bottom), left: LengthWrapper(p: raw.left))
  }

  func hasClip() -> Bool { return wk_interop.RenderStyle_hasClip(p!) }

  func unicodeBidi() -> UnicodeBidi {
    return nonInheritedFlags.unicodeBidi
  }

  func textDecorationsInEffect() -> TextDecorationLine {
    return TextDecorationLine(rawValue: wk_interop.RenderStyle_textDecorationsInEffect(p!))
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
    return wk_interop.RenderStyle_borderLeftWidth(p!)
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
    return wk_interop.RenderStyle_borderRightWidth(p!)
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
    return wk_interop.RenderStyle_borderTopWidth(p!)
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
    return wk_interop.RenderStyle_borderBottomWidth(p!)
  }

  func borderBottomStyle() -> BorderStyle {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderBottomIsTransparent() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderBeforeWidth() -> Float32 {
    switch blockFlowDirection() {
    case .TopToBottom:
      return borderTopWidth()
    case .BottomToTop:
      return borderBottomWidth()
    case .LeftToRight:
      return borderLeftWidth()
    case .RightToLeft:
      return borderRightWidth()
    }
  }

  func borderAfterWidth() -> Float32 {
    switch blockFlowDirection() {
    case .TopToBottom:
      return borderBottomWidth()
    case .BottomToTop:
      return borderTopWidth()
    case .LeftToRight:
      return borderRightWidth()
    case .RightToLeft:
      return borderLeftWidth()
    }
  }

  func borderIsEquivalentForPainting(_ otherStyle: RenderStyleWrapper) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outlineSize() -> Float32 {
    return wk_interop.RenderStyle_outlineSize(p!)
  }

  func outlineWidth() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outlineStyleIsAuto() -> OutlineIsAuto {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasOutlineInVisualOverflow() -> Bool {
    return wk_interop.RenderStyle_hasOutlineInVisualOverflow(p!)
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
    return Clear(rawValue: wk_interop.RenderStyle_clear(p!))!
  }

  static func usedClear(renderer: RenderObjectWrapper) -> UsedClear {
    let computedValue = renderer.style().clear()
    switch computedValue {
    case .None:
      return .None
    case .Left:
      return .Left
    case .Right:
      return .Right
    case .Both:
      return .Both
    case .InlineStart, .InlineEnd:
      let containingBlockDirection = renderer.containingBlock()!.style().direction()
      if containingBlockDirection == .RTL {
        return computedValue == .InlineStart ? .Right : .Left
      }
      return computedValue == .InlineStart ? .Left : .Right
    }
  }

  func fieldSizing() -> FieldSizing {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func textIndent() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_textIndent(p!))
  }

  func textDecorationThickness() -> TextDecorationThickness {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func textIndentLine() -> TextIndentLine {
    return rareInheritedData.textIndentLine
  }

  func textBoxTrim() -> TextBoxTrim {
    return TextBoxTrim(rawValue: wk_interop.RenderStyle_textBoxTrim(p!))!
  }

  func textBoxEdge() -> TextEdge {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func lineFitEdge() -> TextEdge {
    let packed = wk_interop.RenderStyle_lineFitEdge(p!)
    let over = TextEdgeType(rawValue: UInt8(packed / 256))!
    let under = TextEdgeType(rawValue: UInt8(packed % 256))!
    return TextEdge(over: over, under: under)
  }

  func marginTrim() -> MarginTrimType {
    return MarginTrimType(rawValue: wk_interop.RenderStyle_marginTrim(p!))
  }

  func textIndentType() -> TextIndentType {
    return TextIndentType(rawValue: wk_interop.RenderStyle_textIndentType(p!))!
  }

  func textAlign() -> TextAlignMode {
    return TextAlignMode(rawValue: wk_interop.RenderStyle_textAlign(p!))!
  }

  func textTransform() -> TextTransform {
    return TextTransform(rawValue: wk_interop.RenderStyle_textTransform(p!))
  }

  func textDecorationSkipInk() -> TextDecorationSkipInk {
    return TextDecorationSkipInk(rawValue: wk_interop.RenderStyle_textDecorationSkipInk(p!))!
  }

  func usedZoom() -> Float32 { return wk_interop.RenderStyle_usedZoom(p!) }

  func whiteSpaceCollapse() -> WhiteSpaceCollapse {
    return inheritedFlags.whiteSpaceCollapse
  }

  func textWrapMode() -> TextWrapMode {
    return inheritedFlags.textWrapMode
  }

  func textWrapStyle() -> TextWrapStyle {
    return TextWrapStyle(rawValue: wk_interop.RenderStyle_textWrapStyle(p!))!
  }

  func backgroundClip() -> FillBox {
    return FillBox(rawValue: wk_interop.RenderStyle_backgroundClip(p!))!
  }

  func backgroundSizeType() -> FillSizeType {
    return FillSizeType(rawValue: wk_interop.RenderStyle_backgroundSizeType(p!))!
  }

  func backgroundSizeLength() -> LengthSize {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func backgroundLayers() -> FillLayerWrapper {
    return FillLayerWrapper(wk_interop.RenderStyle_backgroundLayers(p!))
  }

  func protectedBackgroundLayers() -> FillLayerWrapper {
    return backgroundLayers()  // TODO(asuhan): just remove this wrapper, not needed in Swift
  }

  func maskLayers() -> FillLayerWrapper {
    return FillLayerWrapper(wk_interop.RenderStyle_maskLayers(p!))
  }

  func protectedMaskLayers() -> FillLayerWrapper {
    return maskLayers()  // TODO(asuhan): just remove this wrapper, not needed in Swift
  }

  func maskBorder() -> NinePieceImage {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func borderCollapse() -> BorderCollapse {
    return BorderCollapse(rawValue: wk_interop.RenderStyle_borderCollapse(p!))!
  }

  func horizontalBorderSpacing() -> Float32 {
    return wk_interop.RenderStyle_horizontalBorderSpacing(p!)
  }

  func verticalBorderSpacing() -> Float32 {
    return wk_interop.RenderStyle_verticalBorderSpacing(p!)
  }

  func emptyCells() -> EmptyCell {
    return EmptyCell(rawValue: wk_interop.RenderStyle_emptyCells(p!))!
  }

  func captionSide() -> CaptionSide {
    return CaptionSide(rawValue: wk_interop.RenderStyle_captionSide(p!))!
  }

  func listStyleType() -> ListStyleType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func listStyleImage() -> StyleImage? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func listStylePosition() -> ListStylePosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func isFixedTableLayout() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marginTop() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_marginTop(p!))
  }

  func marginBottom() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_marginBottom(p!))
  }

  func marginLeft() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_marginLeft(p!))
  }

  func marginRight() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_marginRight(p!))
  }

  func paddingTop() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_paddingTop(p!))
  }

  func paddingBottom() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_paddingBottom(p!))
  }

  func paddingLeft() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_paddingLeft(p!))
  }

  func paddingRight() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_paddingRight(p!))
  }

  func paddingBefore() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_paddingBefore(p!))
  }

  func paddingAfter() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_paddingAfter(p!))
  }

  func paddingStart() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_paddingStart(p!))
  }

  func paddingEnd() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_paddingEnd(p!))
  }

  func insideLink() -> InsideLink {
    return InsideLink(rawValue: wk_interop.RenderStyle_insideLink(p!))!
  }

  func insideDefaultButton() -> Bool { return wk_interop.RenderStyle_insideDefaultButton(p!) }

  func widows() -> UInt16 { return wk_interop.RenderStyle_widows(p!) }

  func orphans() -> UInt16 { return wk_interop.RenderStyle_orphans(p!) }

  func hasAutoWidows() -> Bool { return wk_interop.RenderStyle_hasAutoWidows(p!) }

  func hasAutoOrphans() -> Bool { return wk_interop.RenderStyle_hasAutoOrphans(p!) }

  func breakInside() -> BreakInside {
    return BreakInside(rawValue: wk_interop.RenderStyle_breakInside(p!))!
  }

  func breakBefore() -> BreakBetween {
    return BreakBetween(rawValue: wk_interop.RenderStyle_breakBefore(p!))!
  }

  func breakAfter() -> BreakBetween {
    return BreakBetween(rawValue: wk_interop.RenderStyle_breakAfter(p!))!
  }

  func hangingPunctuation() -> HangingPunctuation {
    return HangingPunctuation(rawValue: wk_interop.RenderStyle_hangingPunctuation(p!))
  }

  func outlineOffset() -> Float32 { return wk_interop.RenderStyle_outlineOffset(p!) }

  func usedContain() -> Containment {
    return Containment(rawValue: wk_interop.RenderStyle_usedContain(p!))
  }

  func containsLayout() -> Bool { return usedContain().contains(.Layout) }

  func containsSize() -> Bool { return usedContain().contains(.Size) }

  func containsPaint() -> Bool {
    return wk_interop.RenderStyle_containsPaint(p!)
  }

  func containsLayoutOrPaint() -> Bool {
    return wk_interop.RenderStyle_containsLayoutOrPaint(p!)
  }

  func containerType() -> ContainerType {
    return ContainerType(rawValue: wk_interop.RenderStyle_containerType(p!))!
  }

  func contentVisibility() -> ContentVisibility {
    return ContentVisibility(rawValue: wk_interop.RenderStyle_contentVisibility(p!))!
  }

  // usedContentVisibility will return ContentVisibility::Hidden in a content-visibility: hidden subtree (overriding
  // content-visibility: auto at all times), ContentVisibility::Auto in a content-visibility: auto subtree (when the
  // content is not user relevant and thus skipped), and ContentVisibility::Visible otherwise.
  func usedContentVisibility() -> ContentVisibility {
    return ContentVisibility(rawValue: wk_interop.RenderStyle_usedContentVisibility(p!))!
  }

  // Returns true for skipped content roots and skipped content itself.
  func hasSkippedContent() -> Bool { return wk_interop.RenderStyle_hasSkippedContent(p!) }

  func containIntrinsicWidthType() -> ContainIntrinsicSizeType {
    return ContainIntrinsicSizeType(rawValue: wk_interop.RenderStyle_containIntrinsicWidthType(p!))!
  }

  func containIntrinsicHeightType() -> ContainIntrinsicSizeType {
    return ContainIntrinsicSizeType(
      rawValue: wk_interop.RenderStyle_containIntrinsicHeightType(p!))!
  }

  func containIntrinsicWidthHasAuto() -> Bool {
    return wk_interop.RenderStyle_containIntrinsicWidthHasAuto(p!)
  }

  func containIntrinsicHeightHasAuto() -> Bool {
    return wk_interop.RenderStyle_containIntrinsicHeightHasAuto(p!)
  }

  func containIntrinsicLogicalWidthHasAuto() -> Bool {
    return wk_interop.RenderStyle_containIntrinsicLogicalWidthHasAuto(p!)
  }

  func containIntrinsicLogicalHeightHasAuto() -> Bool {
    return wk_interop.RenderStyle_containIntrinsicLogicalHeightHasAuto(p!)
  }

  func containIntrinsicWidth() -> LengthWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func containIntrinsicHeight() -> LengthWrapper? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAutoLengthContainIntrinsicSize() -> Bool {
    return wk_interop.RenderStyle_hasAutoLengthContainIntrinsicSize(p!)
  }

  func order() -> Int32 { return wk_interop.RenderStyle_order(p!) }

  func flexGrow() -> Float32 { return wk_interop.RenderStyle_flexGrow(p!) }

  func flexShrink() -> Float32 { return wk_interop.RenderStyle_flexShrink(p!) }

  func flexBasis() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_flexBasis(p!))
  }

  func alignContent() -> StyleContentAlignmentData {
    let raw = wk_interop.RenderStyle_alignContent(p)
    return StyleContentAlignmentData(
      position: ContentPosition(rawValue: raw.position)!,
      distribution: ContentDistribution(rawValue: raw.distribution)!,
      overflow: OverflowAlignment(rawValue: raw.overflow)!)
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
    return FlexDirection(rawValue: wk_interop.RenderStyle_flexDirection(p!))!
  }

  func isRowFlexDirection() -> Bool { return wk_interop.RenderStyle_isRowFlexDirection(p!) }

  func isColumnFlexDirection() -> Bool { return wk_interop.RenderStyle_isColumnFlexDirection(p!) }

  func flexWrap() -> FlexWrap { return FlexWrap(rawValue: wk_interop.RenderStyle_flexWrap(p!))! }

  func justifyContent() -> StyleContentAlignmentData {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func justifySelf() -> StyleSelfAlignmentData {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func namedGridColumnLines() -> NamedGridLinesMap {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func namedGridRowLines() -> NamedGridLinesMap {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func orderedNamedGridColumnLines() -> OrderedNamedGridLinesMap {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func orderedNamedGridRowLines() -> OrderedNamedGridLinesMap {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func autoRepeatNamedGridColumnLines() -> NamedGridLinesMap {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func autoRepeatNamedGridRowLines() -> NamedGridLinesMap {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func autoRepeatOrderedNamedGridColumnLines() -> OrderedNamedGridLinesMap {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func autoRepeatOrderedNamedGridRowLines() -> OrderedNamedGridLinesMap {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func implicitNamedGridColumnLines() -> NamedGridLinesMap {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func implicitNamedGridRowLines() -> NamedGridLinesMap {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func masonryAutoFlow() -> MasonryAutoFlow {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridSubgridRows() -> Bool { return wk_interop.RenderStyle_gridSubgridRows(p!) }

  func gridSubgridColumns() -> Bool { return wk_interop.RenderStyle_gridSubgridColumns(p!) }

  func gridMasonryRows() -> Bool { return wk_interop.RenderStyle_gridMasonryRows(p!) }

  func gridMasonryColumns() -> Bool { return wk_interop.RenderStyle_gridMasonryColumns(p!) }

  func gridItemColumnStart() -> GridPosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridItemColumnEnd() -> GridPosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridItemRowStart() -> GridPosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func gridItemRowEnd() -> GridPosition {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boxShadow() -> ShadowData? {
    let raw = wk_interop.RenderStyle_boxShadow(p!)
    if raw == nil {
      return nil
    }
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boxShadowExtent() -> LayoutBoxExtent {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boxShadowInsetExtent() -> LayoutBoxExtent {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func boxDecorationBreak() -> BoxDecorationBreak {
    return BoxDecorationBreak(rawValue: wk_interop.RenderStyle_boxDecorationBreak(p!))!
  }

  func boxReflect() -> StyleReflection? {
    let raw = wk_interop.RenderStyle_boxReflect(p!)
    return raw != nil ? StyleReflection(raw!) : nil
  }

  func boxSizing() -> BoxSizing {
    return BoxSizing(rawValue: wk_interop.RenderStyle_boxSizing(p!))!
  }

  func marqueeBehavior() -> MarqueeBehavior {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func marqueeDirection() -> MarqueeDirection {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func userModify() -> UserModify {
    return UserModify(rawValue: wk_interop.RenderStyle_userModify(p!))!
  }

  func userDrag() -> UserDrag { return UserDrag(rawValue: wk_interop.RenderStyle_userDrag(p!))! }

  func usedUserSelect() -> UserSelect {
    if effectiveInert() {
      return .None
    }

    let value = userSelect()
    if userModify() != .ReadOnly && userDrag() != .Element {
      return value == .None ? .Text : value
    }

    return value
  }

  func userSelect() -> UserSelect {
    return UserSelect(rawValue: wk_interop.RenderStyle_userSelect(p!))!
  }

  func textOverflow() -> TextOverflow {
    return TextOverflow(rawValue: wk_interop.RenderStyle_textOverflow(p!))!
  }

  func wordBreak() -> WordBreak {
    return WordBreak(rawValue: wk_interop.RenderStyle_wordBreak(p!))!
  }

  func overflowWrap() -> OverflowWrap {
    return OverflowWrap(rawValue: wk_interop.RenderStyle_overflowWrap(p!))!
  }

  func wordSpacing() -> Float32 {
    return inheritedData.fontCascade.wordSpacing()
  }

  func nbspMode() -> NBSPMode {
    if p == nil {
      return rareInheritedData.nbspMode ? .Space : .Normal
    }
    let nbspModeRaw = UInt8(wk_interop.RenderStyle_nbspMode(p!) ? 1 : 0)
    return NBSPMode(rawValue: nbspModeRaw)!
  }

  func lineBreak() -> LineBreak {
    if p == nil {
      // TODO(asuhan): implement this
      fatalError("Not implemented")
    }
    return LineBreak(rawValue: wk_interop.RenderStyle_lineBreak(p!))!
  }

  func hyphenationLimitLines() -> Int16 {
    if p == nil {
      return rareInheritedData.hyphenationLimitLines
    }
    return RenderStyle_hyphenationLimitLines(p!)
  }

  func hyphens() -> Hyphens {
    return Hyphens(rawValue: wk_interop.RenderStyle_hyphens(p!))!
  }

  func hyphenationLimitBefore() -> Int16 {
    return RenderStyle_hyphenationLimitBefore(p!)
  }

  func hyphenationLimitAfter() -> Int16 {
    return RenderStyle_hyphenationLimitAfter(p!)
  }

  func computedLocale() -> AtomStringWrapper {
    return AtomStringWrapper(p: wk_interop.RenderStyle_computedLocale(p!))
  }

  func resize() -> Resize { return Resize(rawValue: wk_interop.RenderStyle_resize(p!))! }

  func hasInlineColumnAxis() -> Bool { return wk_interop.RenderStyle_hasInlineColumnAxis(p!) }

  func columnProgression() -> ColumnProgression {
    return ColumnProgression(rawValue: wk_interop.RenderStyle_columnProgression(p!))!
  }

  func columnWidth() -> Float32 { return wk_interop.RenderStyle_columnWidth(p!) }

  func hasAutoColumnWidth() -> Bool { return wk_interop.RenderStyle_hasAutoColumnWidth(p!) }

  func hasAutoColumnCount() -> Bool { return wk_interop.RenderStyle_hasAutoColumnCount(p!) }

  func specifiesColumns() -> Bool { return wk_interop.RenderStyle_specifiesColumns(p!) }

  func columnFill() -> ColumnFill {
    return ColumnFill(rawValue: wk_interop.RenderStyle_columnFill(p!))!
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

  func hasTransform() -> Bool { return wk_interop.RenderStyle_hasTransform(p!) }

  func transformOriginX() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_transformOriginX(p!))
  }

  func transformOriginY() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_transformOriginY(p!))
  }

  func transformOriginZ() -> Float32 { return wk_interop.RenderStyle_transformOriginZ(p!) }

  func transformBox() -> TransformBox {
    return TransformBox(rawValue: wk_interop.RenderStyle_transformBox(p!))!
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

  func affectsTransform() -> Bool { return wk_interop.RenderStyle_affectsTransform(p!) }

  func textEmphasisMarkString() -> AtomStringWrapper {
    return AtomStringWrapper(p: wk_interop.RenderStyle_textEmphasisMarkString(p!))
  }

  func rubyPosition() -> RubyPosition {
    return RubyPosition(rawValue: wk_interop.RenderStyle_rubyPosition(p!))!
  }

  func isInterCharacterRubyPosition() -> Bool {
    return wk_interop.RenderStyle_isInterCharacterRubyPosition(p!)
  }

  func rubyAlign() -> RubyAlign {
    return RubyAlign(rawValue: wk_interop.RenderStyle_rubyAlign(p!))!
  }

  func rubyOverhang() -> RubyOverhang {
    return RubyOverhang(rawValue: wk_interop.RenderStyle_rubyOverhang(p!))!
  }

  func textOrientation() -> TextOrientation {
    return TextOrientation(rawValue: wk_interop.RenderStyle_textOrientation(p!))!
  }

  func objectFit() -> ObjectFit {
    return ObjectFit(rawValue: wk_interop.RenderStyle_objectFit(p!))!
  }

  func objectPosition() -> LengthPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  // Return true if any transform related property (currently transform, translate, scale, rotate, transformStyle3D or perspective)
  // indicates that we are transforming. The usedTransformStyle3D is not used here because in many cases (such as for deciding
  // whether or not to establish a containing block), the computed value is what matters.
  func hasTransformRelatedProperty() -> Bool {
    return wk_interop.RenderStyle_hasTransformRelatedProperty(p!)
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

  func computePerspectiveOrigin(boundingBox: FloatRectWrapper) -> FloatPoint {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func applyPerspective(_ transform: TransformationMatrix, _ originTranslate: FloatPoint3D) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func computeTransformOrigin(_ boundingBox: FloatRectWrapper) -> FloatPoint3D {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func applyTransformOrigin(_ transform: TransformationMatrix, _ originTranslate: FloatPoint3D) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func unapplyTransformOrigin(_ transform: TransformationMatrix, _ originTranslate: FloatPoint3D) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasPositionedMask() -> Bool { return wk_interop.RenderStyle_hasPositionedMask(p!) }

  func hasMask() -> Bool { return wk_interop.RenderStyle_hasMask(p!) }

  func backfaceVisibility() -> BackfaceVisibility {
    return BackfaceVisibility(rawValue: wk_interop.RenderStyle_backfaceVisibility(p!))!
  }

  func perspective() -> Float32 { return wk_interop.RenderStyle_perspective(p!) }

  func usedPerspective() -> Float32 { return wk_interop.RenderStyle_usedPerspective(p!) }

  func hasPerspective() -> Bool { return wk_interop.RenderStyle_hasPerspective(p!) }

  func perspectiveOriginX() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_perspectiveOriginX(p!))
  }

  func perspectiveOriginY() -> LengthWrapper {
    return LengthWrapper(p: wk_interop.RenderStyle_perspectiveOriginY(p!))
  }

  func lineBoxContain() -> LineBoxContain {
    return LineBoxContain(rawValue: wk_interop.RenderStyle_lineBoxContain(p!))
  }

  func lineClamp() -> LineClampValue {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func blockEllipsis() -> BlockEllipsis {
    let blockEllipsisRaw = wk_interop.RenderStyle_blockEllipsis(p!)
    let type = BlockEllipsis.Type_(rawValue: blockEllipsisRaw.type)!
    return BlockEllipsis(type: type, string: AtomStringWrapper(p: blockEllipsisRaw.string))
  }

  func maxLines() -> UInt64 { return wk_interop.RenderStyle_maxLines(p!) }

  func overflowContinue() -> OverflowContinue {
    return wk_interop.RenderStyle_overflowContinue(p!) ? .Discard : .Auto
  }

  func initialLetterDrop() -> Int32 {
    return wk_interop.RenderStyle_initialLetterDrop(p!)
  }

  func initialLetterHeight() -> Int32 {
    return wk_interop.RenderStyle_initialLetterHeight(p!)
  }

  func eventListenerRegionTypes() -> EventListenerRegionType {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func effectiveInert() -> Bool { return wk_interop.RenderStyle_effectiveInert(p!) }

  func scrollMargin() -> LengthBox {
    let raw = wk_interop.RenderStyle_scrollMargin(p!)
    return LengthBox(
      top: LengthWrapper(p: raw.top), right: LengthWrapper(p: raw.right),
      bottom: LengthWrapper(p: raw.bottom), left: LengthWrapper(p: raw.left))
  }

  func scrollPadding() -> LengthBox {
    let raw = wk_interop.RenderStyle_scrollPadding(p!)
    return LengthBox(
      top: LengthWrapper(p: raw.top), right: LengthWrapper(p: raw.right),
      bottom: LengthWrapper(p: raw.bottom), left: LengthWrapper(p: raw.left))
  }

  func hasSnapPosition() -> Bool { return wk_interop.RenderStyle_hasSnapPosition(p!) }

  func scrollSnapAlign() -> ScrollSnapAlign {
    let raw = wk_interop.RenderStyle_scrollSnapAlign(p!)
    return ScrollSnapAlign(
      blockAlign: ScrollSnapAxisAlignType(rawValue: raw.blockAlign)!,
      inlineAlign: ScrollSnapAxisAlignType(rawValue: raw.inlineAlign)!)
  }

  func scrollSnapStop() -> ScrollSnapStop {
    return ScrollSnapStop(rawValue: wk_interop.RenderStyle_scrollSnapStop(p!))!
  }

  func scrollbarGutter() -> ScrollbarGutter {
    let raw = wk_interop.RenderStyle_scrollbarGutter(p!)
    return ScrollbarGutter(isAuto: raw.isAuto, bothEdges: raw.bothEdges)
  }

  func scrollbarWidth() -> ScrollbarWidth {
    return ScrollbarWidth(rawValue: wk_interop.RenderStyle_scrollbarWidth(p!))!
  }

  func textSecurity() -> TextSecurity {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func writingMode() -> WritingMode {
    return WritingMode(rawValue: wk_interop.RenderStyle_writingMode(p!))!
  }

  func isHorizontalWritingMode() -> Bool {
    return wk_interop.RenderStyle_isHorizontalWritingMode(p!)
  }

  func isVerticalWritingMode() -> Bool {
    return wk_interop.RenderStyle_isVerticalWritingMode(p!)
  }

  func isFlippedLinesWritingMode() -> Bool {
    return wk_interop.RenderStyle_isFlippedLinesWritingMode(p!)
  }

  func isFlippedBlocksWritingMode() -> Bool {
    return wk_interop.RenderStyle_isFlippedBlocksWritingMode(p!)
  }

  func blockFlowDirection() -> FlowDirection {
    return FlowDirection(rawValue: wk_interop.RenderStyle_blockFlowDirection(p!))!
  }

  func typographicMode() -> TypographicMode {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func imageOrientation() -> ImageOrientation {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func imageRendering() -> ImageRendering {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func filter() -> FilterOperations { return FilterOperations(wk_interop.RenderStyle_filter(p!)) }

  func hasFilter() -> Bool { return wk_interop.RenderStyle_hasFilter(p!) }

  func hasReferenceFilterOnly() -> Bool { return wk_interop.RenderStyle_hasReferenceFilterOnly(p!) }

  func appleColorFilter() -> FilterOperations {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasAppleColorFilter() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasBackdropFilter() -> Bool { return wk_interop.RenderStyle_hasBackdropFilter(p!) }

  func isInSubtreeWithBlendMode() -> Bool {
    return wk_interop.RenderStyle_isInSubtreeWithBlendMode(p!)
  }

  func blendMode() -> BlendMode {
    return BlendMode(rawValue: wk_interop.RenderStyle_blendMode(p!))!
  }

  func hasBlendMode() -> Bool { return wk_interop.RenderStyle_hasBlendMode(p!) }

  func isolation() -> Isolation { return wk_interop.RenderStyle_isolation(p!) ? .Isolate : .Auto }

  func hasIsolation() -> Bool { return isolation() != .Auto }

  func shouldPlaceVerticalScrollbarOnLeft() -> Bool {
    return (!isLeftToRightDirection() && isHorizontalWritingMode())
      || blockFlowDirection() == .RightToLeft
  }

  func usesStandardScrollbarStyle() -> Bool {
    return wk_interop.RenderStyle_usesStandardScrollbarStyle(p!)
  }

  func viewTransitionName() -> Style.ScopedName? {
    let raw = wk_interop.RenderStyle_viewTransitionName(p!)
    if !raw.is_valid {
      return nil
    }
    return Style.ScopedName(
      name: AtomStringWrapper(p: raw.name, true),
      scopeOrdinal: Style.ScopeOrdinal(rawValue: raw.scopeOrdinal)!, isIdentifier: raw.isIdentifier)
  }

  func setDisplay(value: DisplayType) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setPosition(v: PositionType) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setWidth(length: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setHeight(length: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLogicalWidth(_ width: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLogicalHeight(_ height: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMinWidth(_ length: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMinHeight(_ length: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setLogicalMinWidth(_ width: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setBackgroundColor(_ value: StyleColorWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTextIndent(_ length: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setTextAlign(_ v: TextAlignMode) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setDirection(_ v: TextDirection) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMaskBorder(image: NinePieceImage) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMarginTop(_ length: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMarginBottom(_ length: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMarginLeft(_ length: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMarginRight(_ length: LengthWrapper) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setMarginStart(_ margin: LengthWrapper) {
    if isHorizontalWritingMode() {
      if isLeftToRightDirection() {
        setMarginLeft(margin)
      } else {
        setMarginRight(margin)
      }
    } else {
      if isLeftToRightDirection() {
        setMarginTop(margin)
      } else {
        setMarginBottom(margin)
      }
    }
  }

  func setMarginEnd(_ margin: LengthWrapper) {
    if isHorizontalWritingMode() {
      if isLeftToRightDirection() {
        setMarginRight(margin)
      } else {
        setMarginLeft(margin)
      }
    } else {
      if isLeftToRightDirection() {
        setMarginBottom(margin)
      } else {
        setMarginTop(margin)
      }
    }
  }

  func setMarginBefore(_ margin: LengthWrapper) {
    if isHorizontalWritingMode() {
      if isFlippedBlocksWritingMode() {
        setMarginBottom(margin)
      } else {
        setMarginTop(margin)
      }
    } else {
      if isFlippedBlocksWritingMode() {
        setMarginRight(margin)
      } else {
        setMarginLeft(margin)
      }
    }
  }

  func setMarginAfter(_ margin: LengthWrapper) {
    if isHorizontalWritingMode() {
      if isFlippedBlocksWritingMode() {
        setMarginTop(margin)
      } else {
        setMarginBottom(margin)
      }
    } else {
      if isFlippedBlocksWritingMode() {
        setMarginLeft(margin)
      } else {
        setMarginRight(margin)
      }
    }
  }

  func setPaddingBox(_ box: LengthBox) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func printColorAdjust() -> PrintColorAdjust {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func usedZIndex() -> Int32 { return wk_interop.RenderStyle_usedZIndex(p!) }

  func hasAutoUsedZIndex() -> Bool { return wk_interop.RenderStyle_hasAutoUsedZIndex(p!) }

  func setUsedZIndex(index: Int32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFlexGrow(_ grow: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFlexShrink(_ shrink: Float32) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setAlignContent(_ data: StyleContentAlignmentData) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setAlignItems(_ data: StyleSelfAlignmentData) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setAlignSelfPosition(_ position: ItemPosition) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFlexDirection(_ direction: FlexDirection) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setFlexWrap(_ wrap: FlexWrap) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setJustifyContent(_ data: StyleContentAlignmentData) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func setColumnSpan(_ span: ColumnSpan) {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func inheritColumnPropertiesFrom(_ parent: RenderStyleWrapper) {
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
    switch order {
    case .Normal, .Fill:
      return RenderStyleWrapper.fill[...]
    case .FillMarkers:
      return RenderStyleWrapper.fillMarkers[...]
    case .Stroke:
      return RenderStyleWrapper.stroke[...]
    case .StrokeMarkers:
      return RenderStyleWrapper.strokeMarkers[...]
    case .Markers:
      return RenderStyleWrapper.markers[...]
    case .MarkersStroke:
      return RenderStyleWrapper.markersStroke[...]
    }
  }

  // TODO(asuhan): use fixed size arrays
  private static let fill: [PaintType] = [.Fill, .Stroke, .Markers]
  private static let fillMarkers: [PaintType] = [.Fill, .Markers, .Stroke]
  private static let stroke: [PaintType] = [.Stroke, .Fill, .Markers]
  private static let strokeMarkers: [PaintType] = [.Stroke, .Markers, .Fill]
  private static let markers: [PaintType] = [.Markers, .Fill, .Stroke]
  private static let markersStroke: [PaintType] = [.Markers, .Stroke, .Fill]

  func computedStrokeWidth(viewportSize: IntSize) -> Float32 {
    return wk_interop.RenderStyle_computedStrokeWidth(p!, viewportSize.width, viewportSize.height)
  }

  private func hasExplicitlySetStrokeWidth() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasPositiveStrokeWidth() -> Bool {
    if !hasExplicitlySetStrokeWidth() {
      return textStrokeWidth() > 0
    }

    return strokeWidth().isPositive()
  }

  private func strokeColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func visitedLinkStrokeColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func usedStrokeColorProperty() -> CSSPropertyID {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shapeOutside() -> ShapeValue? {
    let raw = wk_interop.RenderStyle_shapeOutside(p!)
    return raw != nil ? ShapeValue(raw!) : nil
  }

  func protectedShapeOutside() -> ShapeValue? {
    return shapeOutside()  // TODO(asuhan): just remove this wrapper, not needed in Swift
  }

  func shapeMargin() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func initialShapeMargin() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func shapeImageThreshold() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func initialShapeImageThreshold() -> Float32 {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func clipPath() -> PathOperation? {
    let clipPathRaw = wk_interop.RenderStyle_clipPath(p!)
    if !clipPathRaw.is_valid {
      return nil
    }
    let type = PathOperation.Type_(rawValue: clipPathRaw.type)!
    let referenceBox = CSSBoxType(rawValue: clipPathRaw.referenceBox)!
    return PathOperation(type, referenceBox)
  }

  func contentData() -> ContentData? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hyphenString() -> AtomStringWrapper {
    return AtomStringWrapper(p: wk_interop.RenderStyle_hyphenString(p!))
  }

  func isDisplayInlineType() -> Bool {
    return wk_interop.RenderStyle_isDisplayInlineType(p!)
  }

  func isOriginalDisplayInlineType() -> Bool {
    return wk_interop.RenderStyle_isOriginalDisplayInlineType(p!)
  }

  func isDisplayFlexibleBoxIncludingDeprecatedOrGridBox() -> Bool {
    return wk_interop.RenderStyle_isDisplayFlexibleBoxIncludingDeprecatedOrGridBox(p!)
  }

  func isDisplayBlockLevel() -> Bool {
    return wk_interop.RenderStyle_isDisplayBlockLevel(p!)
  }

  func isOriginalDisplayBlockType() -> Bool {
    return wk_interop.RenderStyle_isOriginalDisplayBlockType(p!)
  }

  func isDisplayTableOrTablePart() -> Bool {
    return wk_interop.RenderStyle_isDisplayTableOrTablePart(p!)
  }

  func isOriginalDisplayListItemType() -> Bool {
    return wk_interop.RenderStyle_isOriginalDisplayListItemType(p!)
  }

  func visitedDependentColor(colorProperty: CSSPropertyID, paintBehavior: PaintBehavior = [])
    -> ColorWrapper
  {
    let unvisitedColor = colorResolvingCurrentColor(colorProperty, false)
    if insideLink() != .InsideVisited {
      return unvisitedColor
    }

    if paintBehavior.contains(.DontShowVisitedLinks) {
      return unvisitedColor
    }

    if isInSubtreeWithBlendMode() {
      return unvisitedColor
    }

    let visitedColor = colorResolvingCurrentColor(colorProperty, true)

    // FIXME: Technically someone could explicitly specify the color transparent, but for now we'll just
    // assume that if the background color is transparent that it wasn't set. Note that it's weird that
    // we're returning unvisited info for a visited link, but given our restriction that the alpha values
    // have to match, it makes more sense to return the unvisited background color if specified than it
    // does to return black. This behavior matches what Firefox 4 does as well.
    if colorProperty == .CSSPropertyBackgroundColor && visitedColor == ColorWrapper.transparentBlack
    {
      return unvisitedColor
    }

    // Take the alpha from the unvisited color, but get the RGB values from the visited color.
    return visitedColor.colorWithAlpha(unvisitedColor.alphaAsFloat())
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

  static func initialZoom() -> Float32 { return 1 }

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
    return wk_interop.RenderStyle_letterSpacing(p!)
  }

  func getBoxShadowHorizontalExtent(left: inout LayoutUnit, right: inout LayoutUnit) {
    left = LayoutUnit.fromRawValue(
      value: wk_interop.RenderStyle_getBoxShadowHorizontalExtentLeft(p!))
    right = LayoutUnit.fromRawValue(
      value: wk_interop.RenderStyle_getBoxShadowHorizontalExtentRight(p!))
  }

  func getBoxShadowVerticalExtent(top: inout LayoutUnit, bottom: inout LayoutUnit) {
    top = LayoutUnit.fromRawValue(value: wk_interop.RenderStyle_getBoxShadowVerticalExtentTop(p!))
    bottom = LayoutUnit.fromRawValue(
      value: wk_interop.RenderStyle_getBoxShadowVerticalExtentBottom(p!))
  }

  func lineAlign() -> LineAlign {
    return LineAlign(rawValue: wk_interop.RenderStyle_lineAlign(p!))!
  }

  func lineSnap() -> LineSnap {
    return LineSnap(rawValue: wk_interop.RenderStyle_lineSnap(p!))!
  }

  func pointerEvents() -> PointerEvents {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
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

  private func strokeWidth() -> LengthWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasVisibleStroke() -> Bool {
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

  func svgStyle() -> SVGRenderStyle {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func fillPaintColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func hasExplicitlySetColor() -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func strokePaintColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func quotes() -> QuotesData? {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func willChange() -> WillChangeData? {
    let raw = wk_interop.RenderStyle_willChange(p!)
    return raw != nil ? WillChangeData(raw!) : nil
  }

  func diff(_ other: RenderStyleWrapper) -> (
    StyleDifference, StyleDifferenceContextSensitiveProperty
  ) {
    var changedContextSensitiveProperties = StyleDifferenceContextSensitiveProperty()

    if changeRequiresLayout(other, &changedContextSensitiveProperties) {
      return (.Layout, changedContextSensitiveProperties)
    }

    if changeRequiresPositionedLayoutOnly(other, &changedContextSensitiveProperties) {
      return (.LayoutPositionedMovementOnly, changedContextSensitiveProperties)
    }

    if changeRequiresLayerRepaint(other, &changedContextSensitiveProperties) {
      return (.RepaintLayer, changedContextSensitiveProperties)
    }

    if changeRequiresRepaint(other, &changedContextSensitiveProperties) {
      return (.Repaint, changedContextSensitiveProperties)
    }

    if changeRequiresRepaintIfText(other, &changedContextSensitiveProperties) {
      return (.RepaintIfText, changedContextSensitiveProperties)
    }

    // FIXME: RecompositeLayer should also behave as a priority bit (e.g when the style change requires layout, we know that
    // the content also needs repaint and it will eventually get repainted,
    // but a repaint type of change (e.g. color change) does not necessarily trigger recomposition).
    if changeRequiresRecompositeLayer(other, &changedContextSensitiveProperties) {
      return (.RecompositeLayer, changedContextSensitiveProperties)
    }

    // Cursors are not checked, since they will be set appropriately in response to mouse events,
    // so they don't need to cause any repaint or layout.

    // Animations don't need to be checked either.  We always set the new style on the RenderObject, so we will get a chance to fire off
    // the resulting transition properly.
    return (.Equal, changedContextSensitiveProperties)
  }

  func diffRequiresLayerRepaint(_ style: RenderStyleWrapper, isComposited: Bool) -> Bool {
    var changedContextSensitiveProperties = StyleDifferenceContextSensitiveProperty()

    if changeRequiresRepaint(style, &changedContextSensitiveProperties) {
      return true
    }

    if isComposited && changeRequiresLayerRepaint(style, &changedContextSensitiveProperties) {
      return changedContextSensitiveProperties.contains(.ClipRect)
    }

    return false
  }

  private func unresolvedColorForProperty(
    _ colorProperty: CSSPropertyID, _ visitedLink: Bool = false
  ) -> StyleColorWrapper {
    switch colorProperty {
    case .CSSPropertyAccentColor:
      return accentColor()
    case .CSSPropertyColor:
      return StyleColorWrapper(visitedLink ? visitedLinkColor() : color())
    case .CSSPropertyBackgroundColor:
      return visitedLink ? visitedLinkBackgroundColor() : backgroundColor()
    case .CSSPropertyBorderBottomColor:
      return visitedLink ? visitedLinkBorderBottomColor() : borderBottomColor()
    case .CSSPropertyBorderLeftColor:
      return visitedLink ? visitedLinkBorderLeftColor() : borderLeftColor()
    case .CSSPropertyBorderRightColor:
      return visitedLink ? visitedLinkBorderRightColor() : borderRightColor()
    case .CSSPropertyBorderTopColor:
      return visitedLink ? visitedLinkBorderTopColor() : borderTopColor()
    case .CSSPropertyFill:
      return fillPaintColor()
    case .CSSPropertyFloodColor:
      return floodColor()
    case .CSSPropertyLightingColor:
      return lightingColor()
    case .CSSPropertyOutlineColor:
      return visitedLink ? visitedLinkOutlineColor() : outlineColor()
    case .CSSPropertyStopColor:
      return stopColor()
    case .CSSPropertyStroke:
      return strokePaintColor()
    case .CSSPropertyStrokeColor:
      return visitedLink ? visitedLinkStrokeColor() : strokeColor()
    case .CSSPropertyBorderBlockEndColor, .CSSPropertyBorderBlockStartColor,
      .CSSPropertyBorderInlineEndColor, .CSSPropertyBorderInlineStartColor:
      return unresolvedColorForProperty(
        CSSProperty.resolveDirectionAwareProperty(
          id: colorProperty, direction: direction(), writingMode: writingMode()))
    case .CSSPropertyColumnRuleColor:
      return visitedLink ? visitedLinkColumnRuleColor() : columnRuleColor()
    case .CSSPropertyTextEmphasisColor:
      return visitedLink ? visitedLinkTextEmphasisColor() : textEmphasisColor()
    case .CSSPropertyWebkitTextFillColor:
      return visitedLink ? visitedLinkTextFillColor() : textFillColor()
    case .CSSPropertyWebkitTextStrokeColor:
      return visitedLink ? visitedLinkTextStrokeColor() : textStrokeColor()
    case .CSSPropertyTextDecorationColor:
      return visitedLink ? visitedLinkTextDecorationColor() : textDecorationColor()
    case .CSSPropertyCaretColor:
      return visitedLink ? visitedLinkCaretColor() : caretColor()
    default:
      fatalError("Not reached")
    }
  }

  private func colorResolvingCurrentColor(_ colorProperty: CSSPropertyID, _ visitedLink: Bool)
    -> ColorWrapper
  {
    let result = unresolvedColorForProperty(colorProperty, visitedLink)

    if result.isCurrentColor() {
      if colorProperty == .CSSPropertyTextDecorationColor {
        if hasPositiveStrokeWidth() {
          // Prefer stroke color if possible but not if it's fully transparent.
          let strokeColor = colorResolvingCurrentColor(usedStrokeColorProperty(), visitedLink)
          if strokeColor.isVisible() {
            return strokeColor
          }
        }

        return colorResolvingCurrentColor(.CSSPropertyWebkitTextFillColor, visitedLink)
      }

      return visitedLink ? visitedLinkColor() : color()
    }

    return colorResolvingCurrentColor(color: result, visitedLink: visitedLink)
  }

  // Resolves the currentColor keyword, but must not be used for the "color" property which has a different semantic.
  func colorResolvingCurrentColor(color: StyleColorWrapper, visitedLink: Bool = false)
    -> ColorWrapper
  {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  static func initialObjectPosition() -> LengthPoint {
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

  private func borderLeftColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func borderRightColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func borderTopColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func borderBottomColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func backgroundColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func color() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func columnRuleColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func outlineColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func textEmphasisColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func textFillColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func textStrokeColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func caretColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func visitedLinkColor() -> ColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func visitedLinkBackgroundColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func visitedLinkBorderLeftColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func visitedLinkBorderRightColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func visitedLinkBorderBottomColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func visitedLinkBorderTopColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func visitedLinkOutlineColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func visitedLinkColumnRuleColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func textDecorationColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func visitedLinkTextDecorationColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func visitedLinkTextEmphasisColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func visitedLinkTextFillColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func visitedLinkTextStrokeColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func visitedLinkCaretColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func stopColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func floodColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func lightingColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  private func accentColor() -> StyleColorWrapper {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func offsetPath() -> PathOperation? {
    if wk_interop.RenderStyle_offsetPath(p!) == nil {
      return nil
    }
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

  func scrollAnchoringSuppressionStyleDidChange(_ other: RenderStyleWrapper?) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func outOfFlowPositionStyleDidChange(_ other: RenderStyleWrapper?) -> Bool {
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

  func changeRequiresLayout(
    _ other: RenderStyleWrapper,
    _ changedContextSensitiveProperties: inout StyleDifferenceContextSensitiveProperty
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func changeRequiresPositionedLayoutOnly(
    _ other: RenderStyleWrapper,
    _ changedContextSensitiveProperties: inout StyleDifferenceContextSensitiveProperty
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func changeRequiresLayerRepaint(
    _ other: RenderStyleWrapper,
    _ changedContextSensitiveProperties: inout StyleDifferenceContextSensitiveProperty
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func changeRequiresRepaint(
    _ other: RenderStyleWrapper,
    _ changedContextSensitiveProperties: inout StyleDifferenceContextSensitiveProperty
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func changeRequiresRepaintIfText(
    _ other: RenderStyleWrapper,
    _ changedContextSensitiveProperties: inout StyleDifferenceContextSensitiveProperty
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  func changeRequiresRecompositeLayer(
    _ other: RenderStyleWrapper,
    _ changedContextSensitiveProperties: inout StyleDifferenceContextSensitiveProperty
  ) -> Bool {
    // TODO(asuhan): implement this
    fatalError("Not implemented")
  }

  var nonInheritedData = StyleNonInheritedData()
  var nonInheritedFlags = NonInheritedFlags()

  var rareInheritedData = StyleRareInheritedData()
  var inheritedData = StyleInheritedData()
  var inheritedFlags = InheritedFlags()

  var m_svgStyle = SVGRenderStyle()
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

func isNonVisibleOverflow(_ overflow: Overflow) -> Bool {
  return overflow == .Hidden || overflow == .Scroll || overflow == .Clip
}

func isVisibleToHitTesting(_ style: RenderStyleWrapper, _ request: HitTestRequestWrapper) -> Bool {
  return (request.userTriggered() ? style.usedVisibility() : style.visibility()) == .Visible
}
