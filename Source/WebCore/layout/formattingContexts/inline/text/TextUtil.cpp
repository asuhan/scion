/*
 * Copyright (C) 2018-2024 Apple Inc. All rights reserved.
 * Copyright (C) 2014 Google Inc. All rights reserved.
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

#include "config.h"
#include "TextUtil.h"

#include "BreakLines.h"
#include "FontCascade.h"
#include "InlineLineTypes.h"
#include "InlineTextItem.h"
#include "Latin1TextIterator.h"
#include "LayoutInlineTextBox.h"
#include "RenderBox.h"
#include "RenderStyleInlines.h"
#include "SurrogatePairAwareTextIterator.h"
#include "TextRun.h"
#include "TextSpacing.h"
#include "WidthIterator.h"
#include "wtf/text/AtomString.h"
#include <cstdint>
#include <unicode/ubidi.h>
#include <wtf/text/TextBreakIterator.h>

#include <optional>
#include <span>

extern "C" WEBCORE_EXPORT uint8_t RenderStyle_unicodeBidi(const void* p)
{
    return static_cast<uint8_t>(static_cast<const WebCore::RenderStyle*>(p)->unicodeBidi());
}

extern "C" WEBCORE_EXPORT float RenderStyle_tabSizeValue(const void* p)
{
    return static_cast<const WebCore::RenderStyle*>(p)->tabSize().value();
}

extern "C" WEBCORE_EXPORT bool RenderStyle_tabSizeIsSpaces(const void* p)
{
    return static_cast<const WebCore::RenderStyle*>(p)->tabSize().isSpaces();
}

extern "C" WEBCORE_EXPORT const void* RenderStyle_fontCascade(const void* p)
{
    return &static_cast<const WebCore::RenderStyle*>(p)->fontCascade();
}

extern "C" WEBCORE_EXPORT uint8_t RenderStyle_textAlign(const void* p)
{
    return static_cast<uint8_t>(static_cast<const WebCore::RenderStyle*>(p)->textAlign());
}

extern "C" WEBCORE_EXPORT bool RenderStyle_direction(const void* p)
{
    return static_cast<bool>(static_cast<const WebCore::RenderStyle*>(p)->direction());
}

extern "C" WEBCORE_EXPORT uint8_t RenderStyle_whiteSpaceCollapse(const void* p)
{
    return static_cast<uint8_t>(static_cast<const WebCore::RenderStyle*>(p)->whiteSpaceCollapse());
}

extern "C" WEBCORE_EXPORT bool RenderStyle_textWrapMode(const void* p)
{
    return static_cast<bool>(static_cast<const WebCore::RenderStyle*>(p)->textWrapMode());
}

extern "C" WEBCORE_EXPORT const void* FontCascade_fontDescription(const void* p)
{
    return &static_cast<const WebCore::FontCascade*>(p)->fontDescription();
}

extern "C" WEBCORE_EXPORT float FontCascade_size(const void* p)
{
    return static_cast<const WebCore::FontCascade*>(p)->size();
}

extern "C" WEBCORE_EXPORT float FontCascade_letterSpacing(const void* p)
{
    return static_cast<const WebCore::FontCascade*>(p)->letterSpacing();
}

extern "C" WEBCORE_EXPORT bool FontCascade_canTakeFixedPitchFastContentMeasuring(const void* p)
{
    return static_cast<const WebCore::FontCascade*>(p)->canTakeFixedPitchFastContentMeasuring();
}

extern "C" WEBCORE_EXPORT bool FontCascade_enableKerning(const void* p)
{
    return static_cast<const WebCore::FontCascade*>(p)->enableKerning();
}

extern "C" WEBCORE_EXPORT bool FontCascade_requiresShaping(const void* p)
{
    return static_cast<const WebCore::FontCascade*>(p)->requiresShaping();
}

extern "C" WEBCORE_EXPORT float FontCascade_primaryFontSpaceWidth(const void* p)
{
    return static_cast<const WebCore::FontCascade*>(p)->primaryFont().spaceWidth();
}

extern "C" WEBCORE_EXPORT float FontCascade_widthOfSpaceString(const void* p)
{
    return static_cast<const WebCore::FontCascade*>(p)->widthOfSpaceString();
}

extern "C" WEBCORE_EXPORT float FontCascade_wordSpacing(const void* p)
{
    return static_cast<const WebCore::FontCascade*>(p)->wordSpacing();
}

extern "C" WEBCORE_EXPORT float FontCascade_widthForTextUsingSimplifiedMeasuring(const void* font_cascade_ptr, const void* text_ptr, bool textDirection)
{
    const auto& text = *static_cast<const StringView*>(text_ptr);
    const auto font_cascade = static_cast<const WebCore::FontCascade*>(font_cascade_ptr);
    return font_cascade->widthForTextUsingSimplifiedMeasuring(text, static_cast<WebCore::TextDirection>(textDirection));
}

extern "C" WEBCORE_EXPORT float FontCascade_widthForSimpleTextWithFixedPitch(const void* font_cascade_ptr, const void* text_ptr, bool textDirection)
{
    const auto& text = *static_cast<const StringView*>(text_ptr);
    const auto font_cascade = static_cast<const WebCore::FontCascade*>(font_cascade_ptr);
    return font_cascade->widthForSimpleTextWithFixedPitch(text, textDirection);
}

extern "C" WEBCORE_EXPORT float FontCascade_width(const void* font_cascade_ptr, const void* text_run_ptr)
{
    const auto& text_run = *static_cast<const WebCore::TextRun*>(text_run_ptr);
    const auto font_cascade = static_cast<const WebCore::FontCascade*>(font_cascade_ptr);
    return font_cascade->width(text_run);
}

extern "C" WEBCORE_EXPORT const void* FontCascade_metricsOfPrimaryFont(const void* font_cascade_ptr)
{
    return &static_cast<const WebCore::FontCascade*>(font_cascade_ptr)->metricsOfPrimaryFont();
}

extern "C" WEBCORE_EXPORT float FontCascade_floatEmphasisMarkHeight(const void* font_cascade_ptr, const void* mark_ptr)
{
    const auto& mark = *static_cast<const AtomString*>(mark_ptr);
    return static_cast<const WebCore::FontCascade*>(font_cascade_ptr)->floatEmphasisMarkHeight(mark);
}

extern "C" WEBCORE_EXPORT bool FontCascade_isSmallCaps(const void* font_cascade_ptr)
{
    return static_cast<const WebCore::FontCascade*>(font_cascade_ptr)->isSmallCaps();
}

extern "C" WEBCORE_EXPORT const void* FontCascade_primaryFont(const void* font_cascade_ptr)
{
    return &static_cast<const WebCore::FontCascade*>(font_cascade_ptr)->primaryFont();
}

struct GlyphDataRaw {
    uint16_t glyph;
    const void* font;
    uint8_t color_glyph_type;
};

extern "C" WEBCORE_EXPORT GlyphDataRaw FontCascade_glyphDataForCharacter(const void* font_cascade_ptr, uint32_t c, bool mirror, uint8_t variant)
{
    const auto glyphData = static_cast<const WebCore::FontCascade*>(font_cascade_ptr)->glyphDataForCharacter(c, mirror, static_cast<WebCore::FontVariant>(variant));
    return { glyphData.glyph, glyphData.font.get(), static_cast<uint8_t>(glyphData.colorGlyphType) };
}

struct ExpansionOpportunityCountRaw {
    uint32_t count;
    bool isAfterExpansion;
};

extern "C" WEBCORE_EXPORT ExpansionOpportunityCountRaw FontCascade_expansionOpportunityCount(const void* string_view, uint8_t direction, uint8_t expansion_behavior_left, uint8_t expansion_behavior_right)
{
    const auto& stringView = *static_cast<const StringView*>(string_view);
    auto result = WebCore::FontCascade::expansionOpportunityCount(stringView, static_cast<WebCore::TextDirection>(direction), {
        static_cast<WebCore::ExpansionBehavior::Behavior>(expansion_behavior_left),
        static_cast<WebCore::ExpansionBehavior::Behavior>(expansion_behavior_right)
    });
    return { result.first, result.second };
}

extern "C" WEBCORE_EXPORT const void* InlineTextBox_content(const void* p)
{
    return &static_cast<const WebCore::Layout::InlineTextBox*>(p)->content();
}

extern "C" WEBCORE_EXPORT bool InlineTextBox_isCombined(const void* p)
{
    return static_cast<const WebCore::Layout::InlineTextBox*>(p)->isCombined();
}

extern "C" WEBCORE_EXPORT bool InlineTextBox_canUseSimplifiedContentMeasuring(const void* p)
{
    return static_cast<const WebCore::Layout::InlineTextBox*>(p)->canUseSimplifiedContentMeasuring();
}

extern "C" WEBCORE_EXPORT bool InlineTextBox_canUseSimpleFontCodePath(const void* p)
{
    return static_cast<const WebCore::Layout::InlineTextBox*>(p)->canUseSimpleFontCodePath();
}

extern "C" WEBCORE_EXPORT bool InlineTextBox_hasPositionDependentContentWidth(const void* p)
{
    return static_cast<const WebCore::Layout::InlineTextBox*>(p)->hasPositionDependentContentWidth();
}

extern "C" WEBCORE_EXPORT bool InlineTextBox_hasStrongDirectionalityContent(const void* p)
{
    return static_cast<const WebCore::Layout::InlineTextBox*>(p)->hasStrongDirectionalityContent();
}

extern "C" WEBCORE_EXPORT const void* InlineTextBox_style(const void* p)
{
    return &static_cast<const WebCore::Layout::InlineTextBox*>(p)->style();
}

extern "C" WEBCORE_EXPORT bool String_isNull(const void* p)
{
    return static_cast<const String*>(p)->isNull();
}

extern "C" WEBCORE_EXPORT bool String_isEmpty(const void* p)
{
    return static_cast<const String*>(p)->isEmpty();
}

extern "C" WEBCORE_EXPORT unsigned String_length(const void* p)
{
    return static_cast<const String*>(p)->length();
}

extern "C" WEBCORE_EXPORT unsigned StringView_length(const void* p)
{
    return static_cast<const StringView*>(p)->length();
}

extern "C" WEBCORE_EXPORT bool StringView_isEmpty(const void* p)
{
    return static_cast<const StringView*>(p)->isEmpty();
}

extern "C" WEBCORE_EXPORT uint16_t String_subscript(const void* p, unsigned index)
{
    return (*static_cast<const String*>(p))[index];
}

extern "C" WEBCORE_EXPORT const void* String_substring(const void* p, uint32_t position, uint32_t length)
{
    return new String(static_cast<const String*>(p)->substring(position, length));
}

extern "C" WEBCORE_EXPORT bool String_is8Bit(const void* p)
{
    return static_cast<const String*>(p)->is8Bit();
}

extern "C" WEBCORE_EXPORT void String_convertTo16Bit(const void* p)
{
    static_cast<String*>(const_cast<void*>(p))->convertTo16Bit();
}

extern "C" WEBCORE_EXPORT uint32_t String_hash(const void* p)
{
    return static_cast<String*>(const_cast<void*>(p))->hash();
}

extern "C" WEBCORE_EXPORT bool StringView_is8Bit(const void* p)
{
    return static_cast<const StringView*>(p)->is8Bit();
}

extern "C" WEBCORE_EXPORT const void* TextRun_span8(const void* p)
{
    return new std::span<const LChar>(static_cast<const WebCore::TextRun*>(p)->span8());
}

extern "C" WEBCORE_EXPORT const void* TextRun_span16(const void* p)
{
    return new std::span<const UChar>(static_cast<const WebCore::TextRun*>(p)->span16());
}

extern "C" WEBCORE_EXPORT bool TextRun_is8Bit(const void* p)
{
    return static_cast<const WebCore::TextRun*>(p)->is8Bit();
}

extern "C" WEBCORE_EXPORT bool TextRun_rtl(const void* p)
{
    return static_cast<const WebCore::TextRun*>(p)->rtl();
}

extern "C" WEBCORE_EXPORT uint32_t TextRun_length(const void* p)
{
    return static_cast<const WebCore::TextRun*>(p)->length();
}

extern "C" WEBCORE_EXPORT void TextRun_setTabSize(void* p, bool allow, float numOrLength, bool isSpaces)
{
    WebCore::TabSize tabSize(numOrLength, static_cast<WebCore::TabSizeValueType>(isSpaces));
    static_cast<WebCore::TextRun*>(p)->setTabSize(allow, tabSize);
}

extern "C" WEBCORE_EXPORT void TextRun_setTextSpacingState(void* text_run_raw, const void* spacing_state)
{
    auto text_run = static_cast<WebCore::TextRun*>(text_run_raw);
    if (!spacing_state) {
        text_run->setTextSpacingState(WebCore::TextSpacing::SpacingState {});
        return;
    }
    text_run->setTextSpacingState(*static_cast<const WebCore::TextSpacing::SpacingState*>(spacing_state));
}

extern "C" WEBCORE_EXPORT const void* TextRun_text(const void* textRun)
{
    return new StringView(static_cast<const WebCore::TextRun*>(textRun)->textAsString());
}

extern "C" WEBCORE_EXPORT uint64_t span8_size(const void* p)
{
    return static_cast<const std::span<const LChar>*>(p)->size();
}

extern "C" WEBCORE_EXPORT uint64_t span16_size(const void* p)
{
    return static_cast<const std::span<const UChar>*>(p)->size();
}

extern "C" WEBCORE_EXPORT uint16_t span8_subscript(const void* p, uint64_t index)
{
    return (*static_cast<const std::span<const LChar>*>(p))[index];
}

extern "C" WEBCORE_EXPORT uint16_t span16_subscript(const void* p, uint64_t index)
{
    return (*static_cast<const std::span<const UChar>*>(p))[index];
}

extern "C" WEBCORE_EXPORT const void* span8_data(const void* p)
{
    return static_cast<const std::span<const LChar>*>(p)->data();
}

extern "C" WEBCORE_EXPORT const void* span16_data(const void* p)
{
    return static_cast<const std::span<const UChar>*>(p)->data();
}

extern "C" bool StringBuilder_isEmpty(const void* builder)
{
    return static_cast<const StringBuilder*>(builder)->isEmpty();
}

extern "C" uint32_t StringBuilder_length(const void* builder)
{
    return static_cast<const StringBuilder*>(builder)->length();
}

extern "C" void* StringBuilder_view(const void* builder)
{
    return new StringView(*static_cast<const StringBuilder*>(builder));
}

extern "C" WEBCORE_EXPORT const void* String_span8(const void* p)
{
    return new std::span<const LChar>(static_cast<const String*>(p)->span8());
}

extern "C" WEBCORE_EXPORT const void* String_span16(const void* p)
{
    return new std::span<const UChar>(static_cast<const String*>(p)->span16());
}

extern "C" WEBCORE_EXPORT const void* StringView_span8(const void* p)
{
    return new std::span<const LChar>(static_cast<const StringView*>(p)->span8());
}

extern "C" WEBCORE_EXPORT const void* StringView_span16(const void* p)
{
    return new std::span<const UChar>(static_cast<const StringView*>(p)->span16());
}

extern "C" WEBCORE_EXPORT const void* StringView_fromString(const void* p)
{
    return new StringView(*static_cast<const String*>(p));
}

extern "C" WEBCORE_EXPORT const void* StringView_substring(const void* p, unsigned start, unsigned length)
{
    return new StringView(static_cast<const StringView*>(p)->substring(start, length));
}

extern "C" WEBCORE_EXPORT void StringView_destroy(const void* p)
{
    delete static_cast<const StringView*>(p);
}

extern "C" WEBCORE_EXPORT const void* StringView_upconvertedCharacters(const void* p)
{
    return new StringView::UpconvertedCharactersWithSize<32>(static_cast<const StringView*>(p)->upconvertedCharacters());
}

extern "C" WEBCORE_EXPORT void UpconvertedCharactersWithSize_destroy(const void* p)
{
    delete static_cast<const StringView::UpconvertedCharactersWithSize<32>*>(p);
}

extern "C" WEBCORE_EXPORT void* TextRun_fromStringView(const void* p, float xpos, float expansion, bool direction, bool directionalOverride)
{
    return new WebCore::TextRun(*static_cast<const StringView*>(p), xpos, expansion, WebCore::ExpansionBehavior::defaultBehavior(), static_cast<WebCore::TextDirection>(direction), directionalOverride);
}

extern "C" WEBCORE_EXPORT void TextRun_destroy(const void* p)
{
    delete static_cast<const WebCore::TextRun*>(p);
}

extern "C" WEBCORE_EXPORT const void* String_new()
{
    return new String();
}

extern "C" WEBCORE_EXPORT const void* String_new_copy(const void* s)
{
    return new String(*static_cast<const String*>(s));
}

extern "C" WEBCORE_EXPORT const void* String_new_span(const void* s)
{
    return new String(*static_cast<const std::span<const UChar>*>(s));
}

extern "C" WEBCORE_EXPORT void StringWrapper_destroy(const void* p)
{
    delete static_cast<const String*>(p);
}

extern "C" WEBCORE_EXPORT const void* WTF_span_from_uchar(uint16_t character)
{
    return new std::span<const UChar>(new UChar(character), 1);
}

extern "C" WEBCORE_EXPORT void CharSpanWrapper8_destroy(const void* p)
{
    delete static_cast<const std::span<const LChar>*>(p);
}

extern "C" WEBCORE_EXPORT void CharSpanWrapper16_destroy(const void* p)
{
    delete static_cast<const std::span<const UChar>*>(p);
}

extern "C" WEBCORE_EXPORT void* StringBuilder_new()
{
    return new StringBuilder();
}

extern "C" WEBCORE_EXPORT void StringBuilder_destroy(const void* p)
{
    delete static_cast<const StringBuilder*>(p);
}

extern "C" WEBCORE_EXPORT void StringBuilder_append_UChar(void* builder, uint16_t ch)
{
    static_cast<StringBuilder*>(builder)->append(static_cast<UChar>(ch));
}

extern "C" WEBCORE_EXPORT void StringBuilder_append_String(void* builder, const void* s)
{
    static_cast<StringBuilder*>(builder)->append(*static_cast<const String*>(s));
}

extern "C" WEBCORE_EXPORT void StringBuilder_append_StringView(void* builder, const void* s)
{
    static_cast<StringBuilder*>(builder)->append(*static_cast<const StringView*>(s));
}

extern "C" WEBCORE_EXPORT void StringBuilder_append_literal(void* builder, const char* s)
{
    static_cast<StringBuilder*>(builder)->append(WTF::ASCIILiteral::fromLiteralUnsafe(s));
}

extern "C" WEBCORE_EXPORT const void* StringBuilder_toString(void* builder)
{
    return new String(static_cast<StringBuilder*>(builder)->toString());
}

extern "C" WEBCORE_EXPORT const void* Length_empty_new(uint8_t type)
{
    return new WebCore::Length(static_cast<WebCore::LengthType>(type));
}

extern "C" WEBCORE_EXPORT const void* Length_new_int32(int32_t value, uint8_t type, bool has_quirk)
{
    return new WebCore::Length(value, static_cast<WebCore::LengthType>(type), has_quirk);
}

extern "C" WEBCORE_EXPORT const void* Length_new(int32_t raw_value, uint8_t type, bool has_quirk)
{
    return new WebCore::Length(WebCore::LayoutUnit::fromRawValue(raw_value), static_cast<WebCore::LengthType>(type), has_quirk);
}

extern "C" WEBCORE_EXPORT const void* Length_new_float32(float value, uint8_t type, bool has_quirk)
{
    return new WebCore::Length(value, static_cast<WebCore::LengthType>(type), has_quirk);
}

extern "C" WEBCORE_EXPORT const void* Length_new_float64(double value, uint8_t type, bool has_quirk)
{
    return new WebCore::Length(value, static_cast<WebCore::LengthType>(type), has_quirk);
}

extern "C" WEBCORE_EXPORT void Length_destroy(const void* p)
{
    delete static_cast<const WebCore::Length*>(p);
}

extern "C" WEBCORE_EXPORT const void* FloatRect_new(float x, float y, float width, float height)
{
    return new WebCore::FloatRect(x, y, width, height);
}

extern "C" WEBCORE_EXPORT void FloatRect_destroy(const void* p)
{
    delete static_cast<const WebCore::FloatRect*>(p);
}

extern "C" WEBCORE_EXPORT const void* Expansion_new(uint8_t left, uint8_t right, float horizontal_expansion)
{
    return new WebCore::InlineDisplay::Box::Expansion(
        {
            static_cast<WebCore::ExpansionBehavior::Behavior>(left),
            static_cast<WebCore::ExpansionBehavior::Behavior>(right)
        },
        horizontal_expansion);
}

extern "C" WEBCORE_EXPORT void Expansion_destroy(const void* p)
{
    delete static_cast<const WebCore::InlineDisplay::Box::Expansion*>(p);
}

extern "C" WEBCORE_EXPORT const void* Text_new(
    uint64_t start,
    uint64_t length,
    uint32_t partially_visible_content_length,
    bool has_partially_visible_content_length,
    const void* original_content,
    const void* adjusted_content_to_render,
    bool has_hyphen)
{
    auto text = new WebCore::InlineDisplay::Box::Text(
        start,
        length,
        *static_cast<const String*>(original_content),
        *static_cast<const String*>(adjusted_content_to_render),
        has_hyphen);
    if (has_partially_visible_content_length) {
        text->setPartiallyVisibleContentLength(partially_visible_content_length);
    }
    return text;
}

extern "C" WEBCORE_EXPORT void* CachedLineBreakIteratorFactory_new(
    const void* string_view,
    const void* locale,
    uint8_t mode,
    uint8_t content_analysis)
{
    return new CachedLineBreakIteratorFactory(
        *static_cast<const StringView*>(string_view),
        *static_cast<const AtomString*>(locale),
        static_cast<TextBreakIterator::LineMode::Behavior>(mode),
        static_cast<TextBreakIterator::ContentAnalysis>(content_analysis));
}

extern "C" WEBCORE_EXPORT void CachedLineBreakIteratorFactory_destroy(const void* p)
{
    delete static_cast<const CachedLineBreakIteratorFactory*>(p);
}

extern "C" WEBCORE_EXPORT void* CachedLineBreakIteratorFactory_stringView(const void* p)
{
    return new StringView(static_cast<const CachedLineBreakIteratorFactory*>(p)->stringView());
}

extern "C" WEBCORE_EXPORT uint8_t CachedLineBreakIteratorFactory_mode(const void* p)
{
    return static_cast<uint8_t>(static_cast<const CachedLineBreakIteratorFactory*>(p)->mode());
}

extern "C" WEBCORE_EXPORT void* CachedLineBreakIteratorFactory_get(void* p)
{
    return &static_cast<CachedLineBreakIteratorFactory*>(p)->get();
}

extern "C" WEBCORE_EXPORT void* CachedLineBreakIteratorFactory_priorContext(void* p)
{
    return &static_cast<CachedLineBreakIteratorFactory*>(p)->priorContext();
}

extern "C" WEBCORE_EXPORT int64_t CachedTextBreakIterator_following(const void* p, uint32_t location)
{
    const auto following_opt = static_cast<const CachedTextBreakIterator*>(p)->following(location);
    return following_opt ? *following_opt : -1;
}

extern "C" WEBCORE_EXPORT uint32_t PriorContext_length(const void* p)
{
    return static_cast<const CachedLineBreakIteratorFactory::PriorContext*>(p)->length();
}

extern "C" WEBCORE_EXPORT uint16_t PriorContext_lastCharacter(const void* p)
{
    return static_cast<const CachedLineBreakIteratorFactory::PriorContext*>(p)->lastCharacter();
}

extern "C" WEBCORE_EXPORT uint16_t PriorContext_secondToLastCharacter(const void* p)
{
    return static_cast<const CachedLineBreakIteratorFactory::PriorContext*>(p)->secondToLastCharacter();
}

extern "C" WEBCORE_EXPORT void PriorContext_set(void* p, uint16_t ch0, uint16_t ch1)
{
    static_cast<CachedLineBreakIteratorFactory::PriorContext*>(p)->set(std::array<UChar, 2>{ch0, ch1});
}

extern "C" WEBCORE_EXPORT const void* EnclosingTopAndBottom_new(float top, float bottom)
{
    return new WebCore::InlineDisplay::Line::EnclosingTopAndBottom(top, bottom);
}

extern "C" WEBCORE_EXPORT void EnclosingTopAndBottom_destroy(const void* p)
{
    delete static_cast<const WebCore::InlineDisplay::Line::EnclosingTopAndBottom*>(p);
}

extern "C" WEBCORE_EXPORT const void* InlineDisplayBox_new(
    const void* layout_box,
    const void* unflipped_visual_rect,
    const void* ink_overflow,
    uint64_t line_index,
    const void* expansion,
    uint8_t bidi_level,
    uint8_t type,
    bool has_content,
    uint8_t position_within_inline_level_box,
    bool is_fully_truncated,
    const void* text)
{
    return new WebCore::InlineDisplay::Box(
        line_index,
        static_cast<WebCore::InlineDisplay::Box::Type>(type),
        *static_cast<const WebCore::Layout::Box*>(layout_box),
        bidi_level,
        *static_cast<const WebCore::FloatRect*>(unflipped_visual_rect),
        *static_cast<const WebCore::FloatRect*>(ink_overflow),
        *static_cast<const WebCore::InlineDisplay::Box::Expansion*>(expansion),
        text ? std::make_optional(*static_cast<const WebCore::InlineDisplay::Box::Text*>(text)) : std::nullopt,
        has_content,
        is_fully_truncated,
        OptionSet<WebCore::InlineDisplay::Box::PositionWithinInlineLevelBox>::fromRaw(position_within_inline_level_box));
}

extern "C" WEBCORE_EXPORT void InlineDisplayBox_destroy(const void* p)
{
    delete static_cast<const WebCore::InlineDisplay::Box*>(p);
}

extern "C" WEBCORE_EXPORT const void* InlineDisplayLine_new(
    uint64_t first_box_index,
    uint64_t box_count,
    const void* line_box_rect,
    const void* line_box_logical_rect,
    const void* scrollable_overflow,
    const void* content_overflow,
    const void* ink_overflow,
    const void* enclosing_logical_top_and_bottom,
    float alignment_baseline,
    float content_logical_left,
    float content_logical_left_ignoring_inline_direction,
    float content_logical_width,
    uint8_t baseline_type,
    bool is_left_to_right_direction,
    bool is_horizontal,
    bool is_first_after_page_break,
    bool is_fully_truncated_in_block_direction,
    bool has_content_after_ellipsis_box,
    const void* ellipsis)
{
    auto line = new WebCore::InlineDisplay::Line(
        *static_cast<const WebCore::FloatRect*>(line_box_logical_rect),
        *static_cast<const WebCore::FloatRect*>(line_box_rect),
        *static_cast<const WebCore::FloatRect*>(content_overflow),
        *static_cast<const WebCore::InlineDisplay::Line::EnclosingTopAndBottom*>(enclosing_logical_top_and_bottom),
        alignment_baseline,
        static_cast<WebCore::FontBaseline>(baseline_type),
        content_logical_left,
        content_logical_left_ignoring_inline_direction,
        content_logical_width,
        is_left_to_right_direction,
        is_horizontal,
        is_fully_truncated_in_block_direction);
    line->setFirstBoxIndex(first_box_index);
    line->setBoxCount(box_count);
    line->setScrollableOverflow(*static_cast<const WebCore::FloatRect*>(scrollable_overflow));
    line->setInkOverflow(*static_cast<const WebCore::FloatRect*>(ink_overflow));
    if (is_first_after_page_break) {
        line->setIsFirstAfterPageBreak();
    }
    if (has_content_after_ellipsis_box) {
        line->setHasContentAfterEllipsisBox();
    }
    if (ellipsis) {
        line->setEllipsis(*static_cast<const WebCore::InlineDisplay::Line::Ellipsis*>(ellipsis));
    }
    return line;
}

extern "C" void InlineLayoutResult_displayContent_addLine(void* inline_layout_result, const void* line)
{
    const auto& displayLine = *static_cast<const WebCore::InlineDisplay::Line*>(line);
    static_cast<WebCore::Layout::InlineLayoutResult*>(inline_layout_result)->displayContent.lines.append(displayLine);
}

extern "C" void InlineLayoutResult_displayContent_addBox(void* inline_layout_result, const void* box)
{
    const auto& displayBox = *static_cast<const WebCore::InlineDisplay::Box*>(box);
    static_cast<WebCore::Layout::InlineLayoutResult*>(inline_layout_result)->displayContent.boxes.append(displayBox);
}

extern "C" void InlineLayoutResult_setRange(void* inline_layout_result, uint8_t range)
{
    static_cast<WebCore::Layout::InlineLayoutResult*>(inline_layout_result)->range = static_cast<WebCore::Layout::InlineLayoutResult::Range>(range);
}

extern "C" const void* TextUtil_ellipsisTextInInlineDirection(bool is_horizontal)
{
    const auto ellipsis_text = WebCore::Layout::TextUtil::ellipsisTextInInlineDirection(is_horizontal);
    return new AtomString(ellipsis_text);
}

extern "C" WEBCORE_EXPORT const void* Ellipsis_new(uint8_t type, float x, float y, float width, float height, const void* text)
{
    return new WebCore::InlineDisplay::Line::Ellipsis(
        static_cast<WebCore::InlineDisplay::Line::Ellipsis::Type>(type),
        WebCore::FloatRect(x, y, width, height),
        *static_cast<const AtomString*>(text));
}

extern "C" WEBCORE_EXPORT void Ellipsis_destroy(const void* p)
{
    delete static_cast<const WebCore::InlineDisplay::Line::Ellipsis*>(p);
}

struct WordBreakLeftRaw {
    uint64_t length;
    float logicalWidth;
};

extern "C" WordBreakLeftRaw TextUtil_breakWord(
    const void* inline_text_box,
    uint64_t start_position,
    uint64_t length,
    float text_width,
    float available_width,
    float content_logical_left,
    const void* font_cascade) {
    const auto& inlineTextBox = *static_cast<WebCore::Layout::InlineTextBox*>(const_cast<void*>(inline_text_box));
    const auto& fontCascade = *static_cast<const WebCore::FontCascade*>(font_cascade);
    auto raw = WebCore::Layout::TextUtil::breakWord(inlineTextBox, start_position, length, text_width, available_width, content_logical_left, fontCascade);
    return { raw.length, raw.logicalWidth };
}

extern "C" uint64_t TextUtil_firstUserPerceivedCharacterLength(const void* inline_text_box, uint64_t start_position, uint64_t length)
{
    return WebCore::Layout::TextUtil::firstUserPerceivedCharacterLength(*static_cast<const WebCore::Layout::InlineTextBox*>(inline_text_box), start_position, length);
}

struct EnclosingAscentDescentRaw {
    float ascent;
    float descent;
};

extern "C" WEBCORE_EXPORT EnclosingAscentDescentRaw TextUtil_enclosingGlyphBoundsForText(const void* text_content_raw, const void* style_raw)
{
    const auto textContent = *static_cast<const StringView*>(text_content_raw);
    const auto& style = *static_cast<const WebCore::RenderStyle*>(style_raw);
    auto enclosingAscentDescent = WebCore::Layout::TextUtil::enclosingGlyphBoundsForText(textContent, style);
    return { enclosingAscentDescent.ascent, enclosingAscentDescent.descent };
}

extern "C" WEBCORE_EXPORT float TextUtil_hyphenWidth(const void* style_raw)
{
    const auto& style = *static_cast<const WebCore::RenderStyle*>(style_raw);
    return WebCore::Layout::TextUtil::hyphenWidth(style);
}

extern "C" const void* AtomString_string(const void* p)
{
    return &static_cast<const AtomString*>(p)->string();
}

extern "C" bool AtomString_isNull(const void* p)
{
    return static_cast<const AtomString*>(p)->isNull();
}

extern "C" bool AtomString_isEmpty(const void* p)
{
    return static_cast<const AtomString*>(p)->isEmpty();
}

extern "C" void AtomString_destroy(const void* p)
{
    delete static_cast<const AtomString*>(p);
}

extern "C" const void* AtomString_nullAtom()
{
    return &nullAtom();
}

extern "C" float TextUtil_width_box(const void*, const void*, unsigned, unsigned, float, bool, const void*);

extern "C" uint8_t ubidi_getBaseDirection_scion(const uint16_t* text, int32_t length)
{
    return static_cast<uint8_t>(ubidi_getBaseDirection(reinterpret_cast<const char16_t*>(text), length));
}

namespace WebCore {
namespace Layout {

static inline InlineLayoutUnit spaceWidth(const FontCascade& fontCascade, bool canUseSimplifiedContentMeasuring)
{
    if (canUseSimplifiedContentMeasuring)
        return fontCascade.primaryFont().spaceWidth();
    return fontCascade.widthOfSpaceString();
}

InlineLayoutUnit TextUtil::width(const InlineTextBox& inlineTextBox, const FontCascade& fontCascade, unsigned from, unsigned to, InlineLayoutUnit contentLogicalLeft, UseTrailingWhitespaceMeasuringOptimization useTrailingWhitespaceMeasuringOptimization, TextSpacing::SpacingState spacingState)
{
    auto swift = TextUtil_width_box(&inlineTextBox, &fontCascade, from, to, contentLogicalLeft, static_cast<bool>(useTrailingWhitespaceMeasuringOptimization), &spacingState);
    auto cpp = widthImpl(inlineTextBox, fontCascade, from, to, contentLogicalLeft, useTrailingWhitespaceMeasuringOptimization, spacingState);
    assert(swift == cpp);
    return cpp;
}

InlineLayoutUnit TextUtil::widthImpl(const InlineTextBox& inlineTextBox, const FontCascade& fontCascade, unsigned from, unsigned to, InlineLayoutUnit contentLogicalLeft, UseTrailingWhitespaceMeasuringOptimization useTrailingWhitespaceMeasuringOptimization, TextSpacing::SpacingState spacingState)
{
    if (from == to)
        return 0;

    if (inlineTextBox.isCombined())
        return fontCascade.size();

    auto text = inlineTextBox.content();
    ASSERT(to <= text.length());
    auto hasKerningOrLigatures = fontCascade.enableKerning() || fontCascade.requiresShaping();
    // The "non-whitespace" + "whitespace" pattern is very common for inline content and since most of the "non-whitespace" runs end up with
    // their "whitespace" pair on the line (notable exception is when trailing whitespace is trimmed).
    // Including the trailing whitespace here enables us to cut the number of text measures when placing content on the line.
    auto extendedMeasuring = useTrailingWhitespaceMeasuringOptimization == UseTrailingWhitespaceMeasuringOptimization::Yes && hasKerningOrLigatures && to < text.length() && text[to] == space;
    if (extendedMeasuring)
        ++to;
    auto width = 0.f;
    auto useSimplifiedContentMeasuring = inlineTextBox.canUseSimplifiedContentMeasuring();
    if (useSimplifiedContentMeasuring) {
        auto view = StringView(text).substring(from, to - from);
        if (fontCascade.canTakeFixedPitchFastContentMeasuring())
            width = fontCascade.widthForSimpleTextWithFixedPitch(view, inlineTextBox.style().collapseWhiteSpace());
        else
            width = fontCascade.widthForTextUsingSimplifiedMeasuring(view);
    } else {
        auto& style = inlineTextBox.style();
        auto directionalOverride = style.unicodeBidi() == UnicodeBidi::Override;
        auto run = WebCore::TextRun { StringView(text).substring(from, to - from), contentLogicalLeft, { }, ExpansionBehavior::defaultBehavior(), directionalOverride ? style.direction() : TextDirection::LTR, directionalOverride };
        if (!style.collapseWhiteSpace() && style.tabSize())
            run.setTabSize(true, style.tabSize());
        // FIXME: consider moving this to TextRun ctor
        run.setTextSpacingState(spacingState);
        width = fontCascade.width(run);
    }

    if (extendedMeasuring)
        width -= (spaceWidth(fontCascade, useSimplifiedContentMeasuring) + fontCascade.wordSpacing());

    if (UNLIKELY(std::isnan(width) || std::isinf(width)))
        return std::isnan(width) ? 0.0f : maxInlineLayoutUnit();
    return std::max(0.f, width);
}

InlineLayoutUnit TextUtil::width(const InlineTextItem& inlineTextItem, const FontCascade& fontCascade, InlineLayoutUnit contentLogicalLeft)
{
    return TextUtil::width(inlineTextItem, fontCascade, inlineTextItem.start(), inlineTextItem.end(), contentLogicalLeft);
}

InlineLayoutUnit TextUtil::width(const InlineTextItem& inlineTextItem, const FontCascade& fontCascade, unsigned from, unsigned to, InlineLayoutUnit contentLogicalLeft, UseTrailingWhitespaceMeasuringOptimization useTrailingWhitespaceMeasuringOptimization, TextSpacing::SpacingState spacingState)
{
    RELEASE_ASSERT(from >= inlineTextItem.start());
    RELEASE_ASSERT(to <= inlineTextItem.end());

    if (inlineTextItem.isWhitespace()) {
        auto& inlineTextBox = inlineTextItem.inlineTextBox();
        auto useSimplifiedContentMeasuring = inlineTextBox.canUseSimplifiedContentMeasuring();
        auto length = from - to;
        auto singleWhiteSpace = length == 1 || !TextUtil::shouldPreserveSpacesAndTabs(inlineTextBox);

        if (singleWhiteSpace) {
            auto width = spaceWidth(fontCascade, useSimplifiedContentMeasuring);
            if (UNLIKELY(std::isnan(width) || std::isinf(width)))
                return std::isnan(width) ? 0.0f : maxInlineLayoutUnit();
            return std::max(0.f, width);
        }
    }
    return width(inlineTextItem.inlineTextBox(), fontCascade, from, to, contentLogicalLeft, useTrailingWhitespaceMeasuringOptimization, spacingState);
}

InlineLayoutUnit TextUtil::trailingWhitespaceWidth(const InlineTextBox& inlineTextBox, const FontCascade& fontCascade, size_t startPosition, size_t endPosition)
{
    auto text = inlineTextBox.content();
    ASSERT(endPosition > startPosition + 1);
    ASSERT(text[endPosition - 1] == space);
    return width(inlineTextBox, fontCascade, startPosition, endPosition, { }, UseTrailingWhitespaceMeasuringOptimization::Yes) - 
        width(inlineTextBox, fontCascade, startPosition, endPosition - 1, { }, UseTrailingWhitespaceMeasuringOptimization::No);
}

template <typename TextIterator>
static void fallbackFontsForRunWithIterator(SingleThreadWeakHashSet<const Font>& fallbackFonts, const FontCascade& fontCascade, const TextRun& run, TextIterator& textIterator)
{
    auto isRTL = run.rtl();
    auto isSmallCaps = fontCascade.isSmallCaps();
    auto& primaryFont = fontCascade.primaryFont();

    char32_t currentCharacter = 0;
    unsigned clusterLength = 0;
    while (textIterator.consume(currentCharacter, clusterLength)) {

        auto addFallbackFontForCharacterIfApplicable = [&](auto character) {
            if (isSmallCaps)
                character = u_toupper(character);

            auto glyphData = fontCascade.glyphDataForCharacter(character, isRTL);
            if (glyphData.glyph && glyphData.font && glyphData.font != &primaryFont) {
                auto isNonSpacingMark = U_MASK(u_charType(character)) & U_GC_MN_MASK;

                // https://drafts.csswg.org/css-text-3/#white-space-processing
                // "Unsupported Default_ignorable characters must be ignored for text rendering."
                auto isIgnored = isDefaultIgnorableCodePoint(character);

                // If we include the synthetic bold expansion, then even zero-width glyphs will have their fonts added.
                if (isNonSpacingMark || glyphData.font->widthForGlyph(glyphData.glyph, Font::SyntheticBoldInclusion::Exclude))
                    if (!isIgnored)
                        fallbackFonts.add(*glyphData.font);
            }
        };
        addFallbackFontForCharacterIfApplicable(currentCharacter);
        textIterator.advance(clusterLength);
    }
}

TextUtil::FallbackFontList TextUtil::fallbackFontsForText(StringView textContent, const RenderStyle& style, IncludeHyphen includeHyphen)
{
    TextUtil::FallbackFontList fallbackFonts;

    auto collectFallbackFonts = [&](const auto& textRun) {
        if (textRun.text().isEmpty())
            return;

        if (textRun.is8Bit()) {
            Latin1TextIterator textIterator { textRun.span8(), 0, textRun.length() };
            fallbackFontsForRunWithIterator(fallbackFonts, style.fontCascade(), textRun, textIterator);
            return;
        }
        SurrogatePairAwareTextIterator textIterator { textRun.span16(), 0, textRun.length() };
        fallbackFontsForRunWithIterator(fallbackFonts, style.fontCascade(), textRun, textIterator);
    };

    if (includeHyphen == IncludeHyphen::Yes)
        collectFallbackFonts(TextRun { StringView(style.hyphenString().string()), { }, { }, ExpansionBehavior::defaultBehavior(), style.direction() });
    collectFallbackFonts(TextRun { textContent, { }, { }, ExpansionBehavior::defaultBehavior(), style.direction() });
    return fallbackFonts;
}

template <typename TextIterator>
static TextUtil::EnclosingAscentDescent enclosingGlyphBoundsForRunWithIterator(const FontCascade& fontCascade, bool isRTL, TextIterator& textIterator)
{
    auto enclosingAscent = std::optional<InlineLayoutUnit> { };
    auto enclosingDescent = std::optional<InlineLayoutUnit> { };
    auto isSmallCaps = fontCascade.isSmallCaps();
    auto& primaryFont = fontCascade.primaryFont();

    char32_t currentCharacter = 0;
    unsigned clusterLength = 0;
    while (textIterator.consume(currentCharacter, clusterLength)) {

        auto computeTopAndBottomForCharacter = [&](auto character) {
            if (isSmallCaps)
                character = u_toupper(character);

            auto glyphData = fontCascade.glyphDataForCharacter(character, isRTL);
            auto& font = glyphData.font ? *glyphData.font : primaryFont;
            // FIXME: This may need some adjustment for ComplexTextController. See glyphOrigin.
            auto bounds = font.boundsForGlyph(glyphData.glyph);

            enclosingAscent = std::min(enclosingAscent.value_or(bounds.y()), bounds.y());
            enclosingDescent = std::max(enclosingDescent.value_or(bounds.maxY()), bounds.maxY());
        };
        computeTopAndBottomForCharacter(currentCharacter);
        textIterator.advance(clusterLength);
    }
    return { enclosingAscent.value_or(0.f), enclosingDescent.value_or(0.f) };
}

TextUtil::EnclosingAscentDescent TextUtil::enclosingGlyphBoundsForText(StringView textContent, const RenderStyle& style)
{
    if (textContent.isEmpty())
        return { };

    if (textContent.is8Bit()) {
        Latin1TextIterator textIterator { textContent.span8(), 0, textContent.length() };
        return enclosingGlyphBoundsForRunWithIterator(style.fontCascade(), !style.isLeftToRightDirection(), textIterator);
    }
    SurrogatePairAwareTextIterator textIterator { textContent.span16(), 0, textContent.length() };
    return enclosingGlyphBoundsForRunWithIterator(style.fontCascade(), !style.isLeftToRightDirection(), textIterator);
}

TextUtil::WordBreakLeft TextUtil::breakWord(const InlineTextItem& inlineTextItem, const FontCascade& fontCascade, InlineLayoutUnit textWidth, InlineLayoutUnit availableWidth, InlineLayoutUnit contentLogicalLeft)
{
    return breakWord(inlineTextItem.inlineTextBox(), inlineTextItem.start(), inlineTextItem.length(), textWidth, availableWidth, contentLogicalLeft, fontCascade);
}

TextUtil::WordBreakLeft TextUtil::breakWord(const InlineTextBox& inlineTextBox, size_t startPosition, size_t length, InlineLayoutUnit textWidth, InlineLayoutUnit availableWidth, InlineLayoutUnit contentLogicalLeft, const FontCascade& fontCascade)
{
    ASSERT(availableWidth >= 0);
    ASSERT(length);
    auto text = inlineTextBox.content();

    if (UNLIKELY(!textWidth)) {
        ASSERT_NOT_REACHED();
        return { };
    }

    if (inlineTextBox.canUseSimpleFontCodePath()) {

        auto findBreakingPositionInSimpleText = [&] {
            auto userPerceivedCharacterBoundaryAlignedIndex = [&] (auto index) -> size_t {
                if (text.is8Bit())
                    return index;
                auto alignedStartIndex = index;
                U16_SET_CP_START(text, startPosition, alignedStartIndex);
                ASSERT(alignedStartIndex >= startPosition);
                return alignedStartIndex;
            };

            auto nextUserPerceivedCharacterIndex = [&] (auto index) -> size_t {
                if (text.is8Bit())
                    return index + 1;
                U16_FWD_1(text, index, startPosition + length);
                return index;
            };

            auto trySimplifiedBreakingPosition = [&] (auto start) -> std::optional<WordBreakLeft> {
                auto mayUseSimplifiedBreakingPositionForFixedPitch = fontCascade.isFixedPitch() && inlineTextBox.canUseSimplifiedContentMeasuring();
                if (!mayUseSimplifiedBreakingPositionForFixedPitch)
                    return { };
                // FIXME: Check if we could bring webkit.org/b/221581 back for system monospace fonts.
                auto monospaceCharacterWidth = fontCascade.widthOfSpaceString();
                size_t estimatedCharacterCount = floorf(availableWidth / monospaceCharacterWidth);
                auto end = userPerceivedCharacterBoundaryAlignedIndex(std::min(start + estimatedCharacterCount, start + length - 1));
                auto underflowWidth = TextUtil::width(inlineTextBox, fontCascade, start, end, contentLogicalLeft);
                if (underflowWidth > availableWidth || underflowWidth + monospaceCharacterWidth < availableWidth) {
                    // This does not look like a real fixed pitch font. Let's just fall back to regular bisect.
                    // In some edge cases (float precision) using monospaceCharacterWidth here may produce an incorrect off-by-one visual overflow.
                    return { };
                }
                return { WordBreakLeft { end - start, underflowWidth } };
            };
            if (auto leftSide = trySimplifiedBreakingPosition(startPosition))
                return *leftSide;

            auto left = startPosition;
            auto right = left + length - 1;
            // Pathological case of (extremely)long string and narrow lines.
            // Adjust the range so that we can pick a reasonable midpoint.
            auto averageCharacterWidth = InlineLayoutUnit { textWidth / length };
            // Overshot the midpoint so that biscection starts at the left side of the content.
            size_t startOffset = 2 * availableWidth / averageCharacterWidth;
            right = userPerceivedCharacterBoundaryAlignedIndex(std::min(left + startOffset, right));
            // Preserve the left width for the final split position so that we don't need to remeasure the left side again.
            auto leftSideWidth = InlineLayoutUnit { 0 };
            while (left < right) {
                auto middle = userPerceivedCharacterBoundaryAlignedIndex((left + right) / 2);
                ASSERT(middle >= left && middle < right);
                auto endOfMiddleCharacter = nextUserPerceivedCharacterIndex(middle);
                auto width = TextUtil::width(inlineTextBox, fontCascade, startPosition, endOfMiddleCharacter, contentLogicalLeft);
                if (width < availableWidth) {
                    left = endOfMiddleCharacter;
                    leftSideWidth = width;
                } else if (width > availableWidth)
                    right = middle;
                else {
                    right = endOfMiddleCharacter;
                    leftSideWidth = width;
                    break;
                }
            }
            RELEASE_ASSERT(right >= startPosition);
            return WordBreakLeft { right - startPosition, leftSideWidth };
        };
        return findBreakingPositionInSimpleText();
    }

    auto graphemeClusterIterator = NonSharedCharacterBreakIterator { StringView { text }.substring(startPosition, length) };
    auto leftSide = TextUtil::WordBreakLeft { };
    for (auto clusterStartPosition = ubrk_next(graphemeClusterIterator); clusterStartPosition != UBRK_DONE; clusterStartPosition = ubrk_next(graphemeClusterIterator)) {
        auto width = TextUtil::width(inlineTextBox, fontCascade, startPosition, startPosition + clusterStartPosition, contentLogicalLeft);
        if (width > availableWidth)
            return leftSide;
        leftSide = { static_cast<size_t>(clusterStartPosition), width };
    }
    // This content is not supposed to fit availableWidth.
    ASSERT_NOT_REACHED();
    return leftSide;
}

bool TextUtil::mayBreakInBetween(const InlineTextItem& previousInlineItem, const InlineTextItem& nextInlineItem)
{
    // Check if these 2 adjacent non-whitespace inline items are connected at a breakable position.
    ASSERT(!previousInlineItem.isWhitespace() && !nextInlineItem.isWhitespace());

    auto previousContent = previousInlineItem.inlineTextBox().content();
    auto nextContent = nextInlineItem.inlineTextBox().content();
    // Now we need to collect at least 3 adjacent characters to be able to make a decision whether the previous text item ends with breaking opportunity.
    // [ex-][ample] <- second to last[x] last[-] current[a]
    // We need at least 1 character in the current inline text item and 2 more from previous inline items.
    if (!previousContent.is8Bit()) {
        // FIXME: Remove this workaround when we move over to a better way of handling prior-context with Unicode.
        // See the templated CharacterType in nextBreakablePosition for last and lastlast characters.
        nextContent.convertTo16Bit();
    }
    auto& previousContentStyle = previousInlineItem.style();
    auto& nextContentStyle = nextInlineItem.style();
    auto lineBreakIteratorFactory = CachedLineBreakIteratorFactory { nextContent, nextContentStyle.computedLocale(), TextUtil::lineBreakIteratorMode(nextContentStyle.lineBreak()), TextUtil::contentAnalysis(nextContentStyle.wordBreak()) };
    auto previousContentLength = previousContent.length();
    // FIXME: We should look into the entire uncommitted content for more text context.
    UChar lastCharacter = previousContentLength ? previousContent[previousContentLength - 1] : 0;
    if (lastCharacter == softHyphen && previousContentStyle.hyphens() == Hyphens::None)
        return false;
    UChar secondToLastCharacter = previousContentLength > 1 ? previousContent[previousContentLength - 2] : 0;
    lineBreakIteratorFactory.priorContext().set({ secondToLastCharacter, lastCharacter });
    // Now check if we can break right at the inline item boundary.
    // With the [ex-ample], findNextBreakablePosition should return the startPosition (0).
    // FIXME: Check if there's a more correct way of finding breaking opportunities.
    return !findNextBreakablePosition(lineBreakIteratorFactory, 0, nextContentStyle);
}

unsigned TextUtil::findNextBreakablePosition(CachedLineBreakIteratorFactory& lineBreakIteratorFactory, unsigned startPosition, const RenderStyle& style)
{
    auto wordBreak = style.wordBreak();
    auto breakNBSP = style.autoWrap() && style.nbspMode() == NBSPMode::Space;

    if (wordBreak == WordBreak::KeepAll) {
        if (breakNBSP)
            return BreakLines::nextBreakablePosition<BreakLines::LineBreakRules::Special, BreakLines::WordBreakBehavior::KeepAll, BreakLines::NoBreakSpaceBehavior::Break>(lineBreakIteratorFactory, startPosition);
        return BreakLines::nextBreakablePosition<BreakLines::LineBreakRules::Special, BreakLines::WordBreakBehavior::KeepAll, BreakLines::NoBreakSpaceBehavior::Normal>(lineBreakIteratorFactory, startPosition);
    }

    if (wordBreak == WordBreak::AutoPhrase)
        return BreakLines::nextBreakablePosition<BreakLines::LineBreakRules::Special, BreakLines::WordBreakBehavior::AutoPhrase, BreakLines::NoBreakSpaceBehavior::Normal>(lineBreakIteratorFactory, startPosition);

    if (lineBreakIteratorFactory.mode() == TextBreakIterator::LineMode::Behavior::Default) {
        if (breakNBSP)
            return BreakLines::nextBreakablePosition<BreakLines::LineBreakRules::Normal, BreakLines::WordBreakBehavior::Normal, BreakLines::NoBreakSpaceBehavior::Break>(lineBreakIteratorFactory, startPosition);
        return BreakLines::nextBreakablePosition<BreakLines::LineBreakRules::Normal, BreakLines::WordBreakBehavior::Normal, BreakLines::NoBreakSpaceBehavior::Normal>(lineBreakIteratorFactory, startPosition);
    }

    if (breakNBSP)
        return BreakLines::nextBreakablePosition<BreakLines::LineBreakRules::Special, BreakLines::WordBreakBehavior::Normal, BreakLines::NoBreakSpaceBehavior::Break>(lineBreakIteratorFactory, startPosition);

    return BreakLines::nextBreakablePosition<BreakLines::LineBreakRules::Special, BreakLines::WordBreakBehavior::Normal, BreakLines::NoBreakSpaceBehavior::Normal>(lineBreakIteratorFactory, startPosition);
}

bool TextUtil::shouldPreserveSpacesAndTabs(const Box& layoutBox)
{
    // https://www.w3.org/TR/css-text-4/#white-space-collapsing
    auto whitespaceCollapse = layoutBox.style().whiteSpaceCollapse();
    return whitespaceCollapse == WhiteSpaceCollapse::Preserve || whitespaceCollapse == WhiteSpaceCollapse::BreakSpaces;
}

bool TextUtil::shouldPreserveNewline(const Box& layoutBox)
{
    // https://www.w3.org/TR/css-text-4/#white-space-collapsing
    auto whitespaceCollapse = layoutBox.style().whiteSpaceCollapse();
    return whitespaceCollapse == WhiteSpaceCollapse::Preserve || whitespaceCollapse == WhiteSpaceCollapse::PreserveBreaks || whitespaceCollapse == WhiteSpaceCollapse::BreakSpaces;
}

bool TextUtil::isWrappingAllowed(const RenderStyle& style)
{
    // https://www.w3.org/TR/css-text-4/#text-wrap
    return style.textWrapMode() != TextWrapMode::NoWrap;
}

bool TextUtil::shouldTrailingWhitespaceHang(const RenderStyle& style)
{
    // https://www.w3.org/TR/css-text-4/#white-space-phase-2
    return style.whiteSpaceCollapse() == WhiteSpaceCollapse::Preserve && style.textWrapMode() != TextWrapMode::NoWrap;
}

TextBreakIterator::LineMode::Behavior TextUtil::lineBreakIteratorMode(LineBreak lineBreak)
{
    switch (lineBreak) {
    case LineBreak::Auto:
    case LineBreak::AfterWhiteSpace:
    case LineBreak::Anywhere:
        return TextBreakIterator::LineMode::Behavior::Default;
    case LineBreak::Loose:
        return TextBreakIterator::LineMode::Behavior::Loose;
    case LineBreak::Normal:
        return TextBreakIterator::LineMode::Behavior::Normal;
    case LineBreak::Strict:
        return TextBreakIterator::LineMode::Behavior::Strict;
    }
    ASSERT_NOT_REACHED();
    return TextBreakIterator::LineMode::Behavior::Default;
}

TextBreakIterator::ContentAnalysis TextUtil::contentAnalysis(WordBreak wordBreak)
{
    switch (wordBreak) {
    case WordBreak::Normal:
    case WordBreak::BreakAll:
    case WordBreak::KeepAll:
    case WordBreak::BreakWord:
        return TextBreakIterator::ContentAnalysis::Mechanical;
    case WordBreak::AutoPhrase:
        return TextBreakIterator::ContentAnalysis::Linguistic;
    }
    return TextBreakIterator::ContentAnalysis::Mechanical;
}

// True if the character may need the Bidi reordering. If false, the
// `Bidi_Class` of `ch` isn't `R`, `AL`, nor Bidi controls.
// https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=%5B%5B%3Abc%3DR%3A%5D%5B%3Abc%3DAL%3A%5D%5D&g=bc
// https://util.unicode.org/UnicodeJsps/list-unicodeset.jsp?a=[:Bidi_C:]
static ALWAYS_INLINE bool mayBeBidiRTL(char32_t ch)
{
    if (ch < 0x0590)
        return false;
    // General Punctuation such as curly quotes.
    if (ch >= 0x2010 && ch <= 0x2029)
        return false;
    // CJK etc., up to Surrogate Pairs.
    if (ch >= 0x206A && ch <= 0xD7FF)
        return false;
    // Common in CJK.
    if (ch >= 0xFF00 && ch <= 0xFFFF)
        return false;
    return true;
}

bool TextUtil::isStrongDirectionalityCharacter(char32_t character)
{
    if (!mayBeBidiRTL(character))
        return false;

    auto bidiCategory = u_charDirection(character);
    return bidiCategory == U_RIGHT_TO_LEFT
        || bidiCategory == U_RIGHT_TO_LEFT_ARABIC
        || bidiCategory == U_RIGHT_TO_LEFT_EMBEDDING
        || bidiCategory == U_RIGHT_TO_LEFT_OVERRIDE
        || bidiCategory == U_LEFT_TO_RIGHT_EMBEDDING
        || bidiCategory == U_LEFT_TO_RIGHT_OVERRIDE
        || bidiCategory == U_POP_DIRECTIONAL_FORMAT;
}

template<typename CharacterType> ALWAYS_INLINE constexpr bool isNotBidiRTL(CharacterType character)
{
    return !mayBeBidiRTL(character);
}

bool TextUtil::containsStrongDirectionalityText(StringView text)
{
    if (text.is8Bit())
        return false;

    if (![&](auto span) ALWAYS_INLINE_LAMBDA {
        using UnsignedType = std::make_unsigned_t<typename decltype(span)::value_type>;
        constexpr size_t stride = SIMD::stride<UnsignedType>;
        if (span.size() >= stride) {
            auto* cursor = span.data();
            auto* end = cursor + span.size();
            constexpr auto c0590 = SIMD::splat<UnsignedType>(0x0590);
            constexpr auto c2010 = SIMD::splat<UnsignedType>(0x2010);
            constexpr auto c2029 = SIMD::splat<UnsignedType>(0x2029);
            constexpr auto c206A = SIMD::splat<UnsignedType>(0x206A);
            constexpr auto cD7FF = SIMD::splat<UnsignedType>(0xD7FF);
            constexpr auto cFF00 = SIMD::splat<UnsignedType>(0xFF00);
            auto maybeBidiRTL = [&](auto* cursor) ALWAYS_INLINE_LAMBDA {
                auto input = SIMD::load(bitwise_cast<const UnsignedType*>(cursor));
                // ch < 0x0590
                auto cond0 = SIMD::lessThan(input, c0590);
                // General Punctuation such as curly quotes.
                // ch >= 0x2010 && ch <= 0x2029
                auto cond1 = SIMD::bitAnd(SIMD::greaterThanOrEqual(input, c2010), SIMD::lessThanOrEqual(input, c2029));
                // CJK etc., up to Surrogate Pairs.
                // ch >= 0x206A && ch <= 0xD7FF
                auto cond2 = SIMD::bitAnd(SIMD::greaterThanOrEqual(input, c206A), SIMD::lessThanOrEqual(input, cD7FF));
                // Common in CJK.
                // ch >= 0xFF00 && ch <= 0xFFFF
                auto cond3 = SIMD::greaterThanOrEqual(input, cFF00);
                return SIMD::bitNot(SIMD::bitOr(cond0, cond1, cond2, cond3));
            };

            auto result = SIMD::splat<UnsignedType>(0);
            for (; cursor + (stride - 1) < end; cursor += stride)
                result = SIMD::bitOr(result, maybeBidiRTL(cursor));
            if (cursor < end)
                result = SIMD::bitOr(result, maybeBidiRTL(end - stride));
            return SIMD::isNonZero(result);
        }

        for (auto character : span) {
            if (mayBeBidiRTL(character))
                return true;
        }
        return false;
    }(text.span16()))
        return false;

    for (char32_t character : text.codePoints()) {
        if (isStrongDirectionalityCharacter(character))
            return true;
    }

    return false;
}

size_t TextUtil::firstUserPerceivedCharacterLength(const InlineTextBox& inlineTextBox, size_t startPosition, size_t length)
{
    auto textContent = inlineTextBox.content();
    RELEASE_ASSERT(!textContent.isEmpty());

    if (textContent.is8Bit())
        return 1;
    if (inlineTextBox.canUseSimpleFontCodePath()) {
        char32_t character;
        size_t endOfCodePoint = startPosition;
        auto characters = textContent.span16();
        U16_NEXT(characters, endOfCodePoint, textContent.length(), character);
        ASSERT(endOfCodePoint > startPosition);
        return endOfCodePoint - startPosition;
    }
    auto graphemeClustersIterator = NonSharedCharacterBreakIterator { textContent };
    auto nextPosition = ubrk_following(graphemeClustersIterator, startPosition);
    if (nextPosition == UBRK_DONE)
        return length;
    return nextPosition - startPosition;
}

size_t TextUtil::firstUserPerceivedCharacterLength(const InlineTextItem& inlineTextItem)
{
    auto length = firstUserPerceivedCharacterLength(inlineTextItem.inlineTextBox(), inlineTextItem.start(), inlineTextItem.length());
    return std::min<size_t>(inlineTextItem.length(), length);
}

TextDirection TextUtil::directionForTextContent(StringView content)
{
    if (content.is8Bit())
        return TextDirection::LTR;
    auto characters = content.span16();
    return ubidi_getBaseDirection(characters.data(), characters.size()) == UBIDI_RTL ? TextDirection::RTL : TextDirection::LTR;
}

AtomString TextUtil::ellipsisTextInInlineDirection(bool isHorizontal)
{
    if (isHorizontal) {
        static MainThreadNeverDestroyed<const AtomString> horizontalEllipsisStr(span(horizontalEllipsis));
        return horizontalEllipsisStr;
    }
    static MainThreadNeverDestroyed<const AtomString> verticalEllipsisStr(span(verticalEllipsis));
    return verticalEllipsisStr;
}

InlineLayoutUnit TextUtil::hyphenWidth(const RenderStyle& style)
{
    return std::max(0.f, style.fontCascade().width(TextRun { StringView { style.hyphenString() } }));
}

bool TextUtil::hasHangablePunctuationStart(const InlineTextItem& inlineTextItem, const RenderStyle& style)
{
    if (!inlineTextItem.length() || !style.hangingPunctuation().contains(HangingPunctuation::First))
        return false;
    auto leadingCharacter = inlineTextItem.inlineTextBox().content()[inlineTextItem.start()];
    return U_GET_GC_MASK(leadingCharacter) & (U_GC_PS_MASK | U_GC_PI_MASK | U_GC_PF_MASK);
}

float TextUtil::hangablePunctuationStartWidth(const InlineTextItem& inlineTextItem, const RenderStyle& style)
{
    if (!hasHangablePunctuationStart(inlineTextItem, style))
        return { };
    ASSERT(inlineTextItem.length());
    auto leadingPosition = inlineTextItem.start();
    return width(inlineTextItem, style.fontCascade(), leadingPosition, leadingPosition + 1, { });
}

bool TextUtil::hasHangablePunctuationEnd(const InlineTextItem& inlineTextItem, const RenderStyle& style)
{
    if (!inlineTextItem.length() || !style.hangingPunctuation().contains(HangingPunctuation::Last))
        return false;
    auto trailingCharacter = inlineTextItem.inlineTextBox().content()[inlineTextItem.end() - 1];
    return U_GET_GC_MASK(trailingCharacter) & (U_GC_PE_MASK | U_GC_PI_MASK | U_GC_PF_MASK);
}

float TextUtil::hangablePunctuationEndWidth(const InlineTextItem& inlineTextItem, const RenderStyle& style)
{
    if (!hasHangablePunctuationEnd(inlineTextItem, style))
        return { };
    ASSERT(inlineTextItem.length());
    auto trailingPosition = inlineTextItem.end() - 1;
    return width(inlineTextItem, style.fontCascade(), trailingPosition, trailingPosition + 1, { });
}

bool TextUtil::hasHangableStopOrCommaEnd(const InlineTextItem& inlineTextItem, const RenderStyle& style)
{
    if (!inlineTextItem.length() || !style.hangingPunctuation().containsAny({ HangingPunctuation::AllowEnd, HangingPunctuation::ForceEnd }))
        return false;
    auto trailingPosition = inlineTextItem.end() - 1;
    auto trailingCharacter = inlineTextItem.inlineTextBox().content()[trailingPosition];
    auto isHangableStopOrComma = trailingCharacter == 0x002C
        || trailingCharacter == 0x002E || trailingCharacter == 0x060C
        || trailingCharacter == 0x06D4 || trailingCharacter == 0x3001
        || trailingCharacter == 0x3002 || trailingCharacter == 0xFF0C
        || trailingCharacter == 0xFF0E || trailingCharacter == 0xFE50
        || trailingCharacter == 0xFE51 || trailingCharacter == 0xFE52
        || trailingCharacter == 0xFF61 || trailingCharacter == 0xFF64;
    return isHangableStopOrComma;
}

float TextUtil::hangableStopOrCommaEndWidth(const InlineTextItem& inlineTextItem, const RenderStyle& style)
{
    if (!hasHangableStopOrCommaEnd(inlineTextItem, style))
        return { };
    ASSERT(inlineTextItem.length());
    auto trailingPosition = inlineTextItem.end() - 1;
    return width(inlineTextItem, style.fontCascade(), trailingPosition, trailingPosition + 1, { });
}

template<typename CharacterType>
static bool canUseSimplifiedTextMeasuringForCharacters(std::span<const CharacterType> characters, const FontCascade& fontCascade, const Font& primaryFont, bool whitespaceIsCollapsed)
{
    auto* rawCharacters = characters.data();
    for (unsigned i = 0; i < characters.size(); ++i) {
        auto character = rawCharacters[i]; // Not using characters[i] to bypass the bounds check.
        if (!fontCascade.canUseSimplifiedTextMeasuring(character, AutoVariant, whitespaceIsCollapsed, primaryFont))
            return false;
    }
    return true;
}

bool TextUtil::canUseSimplifiedTextMeasuring(StringView textContent, const FontCascade& fontCascade, bool whitespaceIsCollapsed, const RenderStyle* firstLineStyle)
{
    ASSERT(textContent.is8Bit() || FontCascade::characterRangeCodePath(textContent.span16()) == FontCascade::CodePath::Simple);
    // FIXME: All these checks should be more fine-grained at the inline item level.
    if (fontCascade.wordSpacing() || fontCascade.letterSpacing())
        return false;

    // Additional check on the font codepath.
    auto run = TextRun { textContent };
    run.setCharacterScanForCodePath(false);
    if (fontCascade.codePath(run) != FontCascade::CodePath::Simple)
        return false;

    if (firstLineStyle && fontCascade != firstLineStyle->fontCascade())
        return false;

    auto& primaryFont = fontCascade.primaryFont();
    if (primaryFont.syntheticBoldOffset())
        return false;

    if (textContent.is8Bit())
        return canUseSimplifiedTextMeasuringForCharacters(textContent.span8(), fontCascade, primaryFont, whitespaceIsCollapsed);
    return canUseSimplifiedTextMeasuringForCharacters(textContent.span16(), fontCascade, primaryFont, whitespaceIsCollapsed);
}

bool TextUtil::hasPositionDependentContentWidth(StringView textContent)
{
    if (textContent.is8Bit())
        return charactersContain<LChar, tabCharacter>(textContent.span8());
    return charactersContain<UChar, tabCharacter>(textContent.span16());
}

}
}
