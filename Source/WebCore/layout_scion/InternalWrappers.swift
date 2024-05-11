/*
 * Copyright (C) 2025 Apple Inc. All rights reserved.
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

import wk_interop

@_cdecl("TextUtil_width_item")
public func TextUtil_width_item(
  inlineTextItemPtr: UnsafeRawPointer, fontCascadePtr: UnsafeRawPointer,
  contentLogicalLeft: Float32
)
  -> InlineLayoutUnit
{
  let inlineTextItem = InlineTextItemWrapper()
  let fontCascade = FontCascadeWrapper()
  return TextUtil.width(
    inlineTextItem: inlineTextItem, fontCascade: fontCascade, contentLogicalLeft: contentLogicalLeft
  )
}

@_cdecl("TextUtil_width_item_slice")
public func TextUtil_width_item_slice(
  inlineTextItemPtr: UnsafeRawPointer, fontCascadePtr: UnsafeRawPointer, from: UInt32, to: UInt32,
  contentLogicalLeft: Float32, useTrailingWhitespaceMeasuringOptimization: Bool
)
  -> InlineLayoutUnit
{
  let inlineTextItem = InlineTextItemWrapper()
  let fontCascade = FontCascadeWrapper()
  return TextUtil.width(
    inlineTextItem: inlineTextItem, fontCascade: fontCascade, from: from, to: to,
    contentLogicalLeft: contentLogicalLeft,
    useTrailingWhitespaceMeasuringOptimization: useTrailingWhitespaceMeasuringOptimization
      ? .Yes : .No)
}

@_cdecl("TextUtil_width_box")
public func TextUtil_width_box(
  inlineTextBoxPtr: UnsafeRawPointer, fontCascadePtr: UnsafeRawPointer, from: UInt32, to: UInt32,
  contentLogicalLeft: Float32, useTrailingWhitespaceMeasuringOptimization: Bool,
  spacingStatePtr: UnsafeRawPointer?
)
  -> InlineLayoutUnit
{
  let inlineTextBox = convert_inline_text_box(p: inlineTextBoxPtr)
  let fontCascade = FontCascadeWrapper(p: fontCascadePtr)
  return TextUtil.width(
    inlineTextBox: inlineTextBox, fontCascade: fontCascade, from: from, toIn: to,
    contentLogicalLeft: contentLogicalLeft,
    useTrailingWhitespaceMeasuringOptimization: useTrailingWhitespaceMeasuringOptimization
      ? .Yes : .No, spacingStatePtr: spacingStatePtr)
}

func convert_render_style(p: UnsafeRawPointer) -> RenderStyleWrapper {
  let unicodeBidi = UnicodeBidi(rawValue: RenderStyle_unicodeBidi(p))!
  let tabSize = TabSizeWrapper(
    numOrLength: RenderStyle_tabSizeValue(p),
    isSpaces: RenderStyle_tabSizeIsSpaces(p) ? .SpaceValueType : .LengthValueType)
  let fontCascade = FontCascadeWrapper(p: RenderStyle_fontCascade(p))
  let direction = RenderStyle_direction(p) ? TextDirection.RTL : TextDirection.LTR
  let whiteSpaceCollapse = WhiteSpaceCollapse(rawValue: RenderStyle_whiteSpaceCollapse(p))!
  let textWrapMode = RenderStyle_textWrapMode(p) ? TextWrapMode.NoWrap : TextWrapMode.Wrap
  let style = RenderStyleWrapper(
    unicodeBidi: unicodeBidi,
    tabSize: tabSize,
    fontCascade: fontCascade,
    direction: direction,
    whiteSpaceCollapse: whiteSpaceCollapse,
    textWrapMode: textWrapMode)
  style.p = p
  return style
}

func convert_inline_text_box(p: UnsafeRawPointer) -> InlineTextBoxWrapper {
  return InlineTextBoxWrapper(
    content: inline_text_box_content(p: p), isCombined: inline_text_box_is_combined(p: p),
    canUseSimplifiedContentMeasuring: inline_text_box_can_use_simplified_content_measuring(p: p),
    canUseSimpleFontCodePath: inline_text_box_can_use_simple_font_code_path(p: p),
    hasPositionDependentContentWidth: inline_text_box_has_position_dependent_content_width(p: p),
    hasStrongDirectionalityContent: inline_text_box_has_strong_directionality_content(p: p),
    style: inline_text_box_style(p: p))
}

func font_cascade_size(p: UnsafeRawPointer) -> Float32 {
  return FontCascade_size(p)
}

func font_cascade_canTakeFixedPitchFastContentMeasuring(p: UnsafeRawPointer) -> Bool {
  return FontCascade_canTakeFixedPitchFastContentMeasuring(p)
}

func font_cascade_enableKerning(p: UnsafeRawPointer) -> Bool {
  return FontCascade_enableKerning(p)
}

func font_cascade_requiresShaping(p: UnsafeRawPointer) -> Bool {
  return FontCascade_requiresShaping(p)
}

func font_cascade_primaryFontSpaceWidth(p: UnsafeRawPointer) -> Float32 {
  return FontCascade_primaryFontSpaceWidth(p)
}

func font_cascade_widthOfSpaceString(p: UnsafeRawPointer) -> Float32 {
  return FontCascade_widthOfSpaceString(p)
}

func font_cascade_wordSpacing(p: UnsafeRawPointer) -> Float32 {
  return FontCascade_wordSpacing(p)
}

func font_cascade_width_for_text_using_simplified_measuring(
  fontCascadePtr: UnsafeRawPointer, textPtr: UnsafeRawPointer, textDirection: Bool
) -> Float32 {
  return FontCascade_widthForTextUsingSimplifiedMeasuring(fontCascadePtr, textPtr, textDirection)
}

func font_cascade_width_for_simple_text_with_fixed_pitch(
  fontCascadePtr: UnsafeRawPointer, textPtr: UnsafeRawPointer, whitespaceIsCollapsed: Bool
) -> Float32 {
  return FontCascade_widthForSimpleTextWithFixedPitch(
    fontCascadePtr, textPtr, whitespaceIsCollapsed)
}

func font_cascade_width(fontCascadePtr: UnsafeRawPointer, textRunPtr: UnsafeRawPointer) -> Float32 {
  return FontCascade_width(fontCascadePtr, textRunPtr)
}

func inline_text_box_content(p: UnsafeRawPointer) -> StringWrapper {
  return StringWrapper(p: InlineTextBox_content(p))
}

func inline_text_box_is_combined(p: UnsafeRawPointer) -> Bool {
  return InlineTextBox_isCombined(p)
}

func inline_text_box_can_use_simplified_content_measuring(p: UnsafeRawPointer) -> Bool {
  return InlineTextBox_canUseSimplifiedContentMeasuring(p)
}

func inline_text_box_can_use_simple_font_code_path(p: UnsafeRawPointer) -> Bool {
  return InlineTextBox_canUseSimpleFontCodePath(p)
}

func inline_text_box_has_position_dependent_content_width(p: UnsafeRawPointer) -> Bool {
  return InlineTextBox_hasPositionDependentContentWidth(p)
}

func inline_text_box_has_strong_directionality_content(p: UnsafeRawPointer) -> Bool {
  return InlineTextBox_hasStrongDirectionalityContent(p)
}

func inline_text_box_style(p: UnsafeRawPointer) -> RenderStyleWrapper {
  return convert_render_style(p: InlineTextBox_style(p))
}

func string_length(p: UnsafeRawPointer) -> UInt32 {
  return String_length(p)
}

func string_subscript(p: UnsafeRawPointer, index: UInt32) -> UInt16 {
  return String_subscript(p, index)
}

func text_run_set_tab_size(
  textRunPtr: UnsafeMutableRawPointer, allow: Bool, tabSize: TabSizeWrapper
) {
  TextRun_setTabSize(textRunPtr, allow, tabSize.value, tabSize.isSpaces == .SpaceValueType)
}

func text_run_set_text_spacing_state(
  textRunPtr: UnsafeMutableRawPointer, spacingStatePtr: UnsafeRawPointer?
) {
  TextRun_setTextSpacingState(textRunPtr, spacingStatePtr)
}

func string_view_from_string(p: UnsafeRawPointer) -> UnsafeRawPointer {
  return StringView_fromString(p)
}

func string_view_substring(s: StringWrapperView, start: UInt32, length: UInt32) -> StringWrapperView
{
  return StringWrapperView(p: StringView_substring(s.p!, start, length))
}

func text_run_from_string_view(
  p: UnsafeRawPointer, xpos: Float32, expansion: Float32, direction: Bool, directionalOverride: Bool
) -> UnsafeMutableRawPointer {
  return TextRun_fromStringView(p, xpos, expansion, direction, directionalOverride)
}
