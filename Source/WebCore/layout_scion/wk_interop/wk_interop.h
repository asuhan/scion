#include <stdbool.h>
#include <stdint.h>

struct GlyphOverflowRaw {
    int32_t left;
    int32_t right;
    int32_t top;
    int32_t bottom;
};

struct InlineItemPositionRaw {
    uint64_t index;
    uint64_t offset;
};

struct LayoutPositionRaw {
    uint64_t line_index;
    struct InlineItemPositionRaw inline_item_position;
    int32_t partial_content_top;
    bool is_valid;
};

struct BoxGeometryHorizontalEdgesRaw {
    int32_t start;
    int32_t end;
};

struct BoxGeometryVerticalEdgesRaw {
    int32_t before;
    int32_t after;
};

struct BoxGeometryEdgesRaw {
    struct BoxGeometryHorizontalEdgesRaw horizontal;
    struct BoxGeometryVerticalEdgesRaw vertical;
};

struct BoxGeometryRaw {
    void* orig_ptr;
    struct BoxGeometryEdgesRaw padding;
    int32_t vertical_space_for_scrollbar;
    int32_t horizontal_space_for_scrollbar;
};

struct PlacedFloatsItemRaw {
    const void* layout_box;
    uint8_t position;
    struct BoxGeometryRaw absolute_box_geometry;
    uint64_t placed_by_line;
    bool placed_by_line_is_valid;
};

struct PlacedFloatsRaw {
    const void* block_formatting_context_root;
    const struct PlacedFloatsItemRaw* inline_items;
    const uint64_t inline_items_count;
};

struct WordBreakLeftRaw {
    uint64_t length;
    float logicalWidth;
};

struct HorizontalEdgesRaw {
    int32_t start;
    int32_t end;
};

struct OptionalFloatRaw {
    float value;
    bool is_valid;
};

struct EnclosingAscentDescentRaw {
    float ascent;
    float descent;
};

struct UBiDiLogicalRunRaw {
    int32_t logical_limit;
    uint8_t level;
};

struct ExpansionOpportunityCountRaw {
    uint32_t count;
    bool isAfterExpansion;
};

struct NextU16Raw {
    uint32_t character;
    uint64_t position;
};

uint8_t RenderStyle_unicodeBidi(const void*);
float RenderStyle_tabSizeValue(const void*);
bool RenderStyle_tabSizeIsSpaces(const void*);
const void* RenderStyle_fontCascade(const void*);
uint8_t RenderStyle_textAlign(const void*);
bool RenderStyle_direction(const void*);
uint8_t RenderStyle_whiteSpaceCollapse(const void*);
bool RenderStyle_textWrapMode(const void*);
const void* FontCascade_fontDescription(const void*);
float FontCascade_size(const void*);
float FontCascade_letterSpacing(const void*);
bool FontCascade_canTakeFixedPitchFastContentMeasuring(const void*);
bool FontCascade_enableKerning(const void*);
bool FontCascade_requiresShaping(const void*);
float FontCascade_primaryFontSpaceWidth(const void*);
float FontCascade_widthOfSpaceString(const void*);
float FontCascade_wordSpacing(const void*);
float FontCascade_widthForTextUsingSimplifiedMeasuring(const void*, const void*, bool);
float FontCascade_widthForSimpleTextWithFixedPitch(const void*, const void*, bool);
float FontCascade_width(const void*, const void*);
struct ExpansionOpportunityCountRaw FontCascade_expansionOpportunityCount(
    const void* string_view,
    uint8_t direction,
    uint8_t expansion_behavior_left,
    uint8_t expansion_behavior_right);
float FontDescription_computedSize(const void*);
uint8_t FontDescription_orientation(const void*);
int32_t FontMetrics_intHeight(const void*, uint8_t);
int32_t FontMetrics_intAscent(const void*, uint8_t);
int32_t FontMetrics_intDescent(const void*, uint8_t);
float FontMetrics_lineSpacing(const void*);
int32_t FontMetrics_intLineSpacing(const void*);
struct OptionalFloatRaw FontMetrics_xHeight(const void*);
const void* FontCascade_metricsOfPrimaryFont(const void*);
float FontCascade_floatEmphasisMarkHeight(const void* font_cascade_ptr, const void* mark_ptr);
const void* FontCascade_primaryFont(const void*);
const void* InlineTextBox_content(const void*);
bool InlineTextBox_isCombined(const void*);
bool InlineTextBox_canUseSimplifiedContentMeasuring(const void*);
bool InlineTextBox_canUseSimpleFontCodePath(const void*);
bool InlineTextBox_hasPositionDependentContentWidth(const void*);
bool InlineTextBox_hasStrongDirectionalityContent(const void*);
const void* InlineTextBox_style(const void*);
unsigned String_length(const void*);
unsigned StringView_length(const void*);
uint16_t String_subscript(const void*, unsigned);
bool String_is8Bit(const void*);
void String_convertTo16Bit(const void*);
bool StringView_is8Bit(const void*);
void TextRun_setTabSize(void*, bool, float, bool);
void TextRun_setTextSpacingState(void*, const void*);
uint64_t span8_size(const void*);
uint64_t span16_size(const void*);
uint16_t span8_subscript(const void*, uint64_t);
uint16_t span16_subscript(const void*, uint64_t);
bool StringBuilder_isEmpty(const void*);
uint32_t StringBuilder_length(const void*);
void* StringBuilder_view(const void*);
const void* String_span8(const void*);
const void* String_span16(const void*);
const void* StringView_span8(const void*);
const void* StringView_span16(const void*);
const void* StringView_fromString(const void*);
const void* StringView_substring(const void*, unsigned, unsigned);
const void* StringView_upconvertedCharacters(const void*);
void* TextRun_fromStringView(const void*, float, float, bool, bool);
const void* String_new();
const void* String_new_copy(const void*);
const void* String_new_span(const void*);
const void* WTF_span_from_uchar(uint16_t);
void* StringBuilder_new();
void StringBuilder_append_UChar(void*, uint16_t);
void StringBuilder_append_StringView(void*, const void*);
const void* Length_new(uint8_t type);
const void* FloatRect_new(float x, float y, float width, float height);
const void* Expansion_new(uint8_t left, uint8_t right, float horizontal_expansion);
const void* Text_new(
    uint64_t start,
    uint64_t length,
    uint32_t partially_visible_content_length,
    bool has_partially_visible_content_length,
    const void* original_content,
    const void* adjusted_content_to_render,
    bool has_hyphen);
void* CachedLineBreakIteratorFactory_new(
    const void* string_view,
    const void* locale,
    uint8_t mode,
    uint8_t content_analysis);
void* CachedLineBreakIteratorFactory_stringView(const void*);
uint8_t CachedLineBreakIteratorFactory_mode(const void*);
const void* CachedLineBreakIteratorFactory_get(const void*);
void* CachedLineBreakIteratorFactory_priorContext(void*);
int64_t CachedTextBreakIterator_following(const void*, uint32_t);
uint32_t PriorContext_length(const void*);
uint16_t PriorContext_lastCharacter(const void*);
uint16_t PriorContext_secondToLastCharacter(const void*);
void PriorContext_set(void*, uint16_t, uint16_t);
const void* EnclosingTopAndBottom_new(float top, float bottom);
const void* InlineDisplayBox_new(
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
    const void* text);
const void* InlineDisplayLine_new(
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
    const void* ellipsis);
void InlineLayoutResult_displayContent_addLine(void* inline_layout_result, const void* line);
void InlineLayoutResult_displayContent_addBox(void* inline_layout_result, const void* box);
void InlineLayoutResult_setRange(void* inline_layout_result, uint8_t range);
const void* TextUtil_ellipsisTextInInlineDirection(bool is_horizontal);
const void* Ellipsis_new(uint8_t type, float x, float y, float width, float height, const void* text);
struct WordBreakLeftRaw TextUtil_breakWord(
    const void* inline_text_box,
    uint64_t start_position,
    uint64_t length,
    float text_width,
    float available_width,
    float content_logical_left,
    const void* font_cascade);
uint64_t TextUtil_firstUserPerceivedCharacterLength(
    const void* inline_text_box, uint64_t start_position, uint64_t length);
struct EnclosingAscentDescentRaw TextUtil_enclosingGlyphBoundsForText(
    const void* text_content_raw, const void* style_raw);
bool AtomString_isNull(const void*);
const void* AtomString_string(const void*);
uint8_t Length_type(const void*);
float Length_value(const void*);
float Length_percent(const void*);
float Length_nonNanCalculatedValue(const void*, float);
bool Length_eq(const void*, const void*);
bool Length_isFixed(const void*);
const void* InlineItemsBuilder_inlineContentCache(const void*);
const void* InlineItemsBuilder_root(const void*);
const void* InlineItemsBuilder_securityOrigin(const void*);
const void* ElementBox_firstChild(const void*);
const void* ElementBox_firstInFlowChild(const void*);
bool ElementBox_isListMarkerImage(const void*);
bool ElementBox_isListMarkerOutside(const void*);
bool ElementBox_isListMarkerInsideList(const void*);
void* ElementBox_rendererForIntegration(const void*);
bool ElementBox_hasOutOfFlowChild(const void*);
void ElementBox_setBaselineForIntegration(const void*, int32_t);
bool ElementBox_hasBaselineForIntegration(const void*);
int32_t ElementBox_baselineForIntegration(const void*);
bool RenderObject_isRenderListItem(const void*);
bool RenderObject_isRenderListMarker(const void*);
bool RenderObject_isRenderBlockFlow(const void*);
bool RenderObject_isRenderFlexibleBox(const void*);
bool RenderObject_isRenderBlock(const void*);
bool RenderObject_isRenderBox(const void*);
bool RenderObject_isImage(const void*);
bool RenderObject_isFieldset(const void*);
void* RenderObject_containingBlock(const void*);
const void* RenderObject_style(const void*);
void* RenderObject_layoutBox(void*);
void* RenderObject_parent(void*);
void RenderElement_layoutIfNeeded(void*);
bool RenderElement_isWritingModeRoot(const void*);
int32_t RenderBox_availableLogicalWidth(const void*);
int32_t RenderBox_contentWidth(const void*);
int32_t RenderBox_contentHeight(const void*);
int32_t RenderBox_contentLogicalSize_width(const void*);
int32_t RenderBox_contentLogicalSize_height(const void*);
int32_t RenderBox_paddingBoxWidth(const void*);
int32_t RenderBox_paddingBoxHeight(const void*);
int32_t RenderBox_paddingBoxRectIncludingScrollbar_width(const void*);
int32_t RenderBox_paddingBoxRectIncludingScrollbar_height(const void*);
int32_t RenderBox_paddingBoxRectIncludingScrollbar_x(const void*);
int32_t RenderBox_paddingBoxRectIncludingScrollbar_y(const void*);
bool RenderBox_isFlexItem(const void*);
const void* RenderBox_shapeOutsideInfo(const void*);
int32_t RenderBoxModelObject_paddingStart(const void*);
int32_t RenderBoxModelObject_borderStart(const void*);
int32_t RenderBoxModelObject_marginStart(const void*, const void*);
int32_t RenderBoxModelObject_baselinePosition(const void*, uint8_t, bool, uint8_t, uint8_t);
bool RenderListMarker_isInside(const void*);
void* RenderListMarker_listItem(void*);
bool Box_isContainingBlockForOutOfFlowPosition(const void*);
bool Box_isAnonymous(const void*);
bool Box_isBlockContainer(const void*);
bool Box_isInlineLevelBox(const void*);
bool Box_isInlineBox(const void*);
bool Box_isInlineTextBox(const void*);
bool Box_isPositioned(const void*);
bool Box_isInFlowPositioned(const void*);
bool Box_isOutOfFlowPositioned(const void*);
bool Box_isFixedPositioned(const void*);
bool Box_isFloatingPositioned(const void*);
bool Box_isAtomicInlineBox(const void*);
bool Box_isInitialContainingBlock(const void*);
bool Box_isRubyAnnotationBox(const void*);
bool Box_isRuby(const void*);
bool Box_isRubyBase(const void*);
bool Box_isRubyInlineBox(const void*);
bool Box_isWordBreakOpportunity(const void*);
bool Box_isLineBreakBox(const void*);
bool Box_isListMarkerBox(const void*);
bool Box_isReplacedBox(const void*);
bool Box_isInlineIntegrationRoot(const void*);
bool Box_isFirstChildForIntegration(const void*);
bool Box_isElementBox(const void*);
bool Box_establishesFormattingContext(const void*);
bool Box_establishesInlineFormattingContext(const void*);
const void* Box_parent(const void*);
const void* Box_nextSibling(const void*);
const void* Box_firstLineStyle(const void*);
const void* Box_style(const void*);
const void* Box_shape(const void*);
const void* RenderStyle_metricsOfPrimaryFont(const void*);
const void* RenderStyle_fontDescription(const void*);
uint8_t RenderStyle_textOverflow(const void*);
const void* RenderStyle_computedLocale(const void*);
const void* RenderStyle_textEmphasisMarkString(const void*);
int32_t RenderStyle_initialLetterDrop(const void*);
bool RenderStyle_isHorizontalWritingMode(const void*);
bool RenderStyle_isVerticalWritingMode(const void*);
uint8_t RenderStyle_blockFlowDirection(const void*);
float RenderStyle_computedStrokeWidth(const void*, int32_t, int32_t);
bool RenderStyle_isOriginalDisplayInlineType(const void*);
bool RenderStyle_isOriginalDisplayListItemType(const void*);
float RenderStyle_letterSpacing(const void*);
int32_t RenderStyle_getBoxShadowHorizontalExtentLeft(const void*);
int32_t RenderStyle_getBoxShadowHorizontalExtentRight(const void*);
int32_t RenderStyle_getBoxShadowVerticalExtentTop(const void*);
int32_t RenderStyle_getBoxShadowVerticalExtentBottom(const void*);
uint8_t RenderStyle_floating(const void*);
uint8_t RenderStyle_overflowX(const void*);
uint8_t RenderStyle_verticalAlign(const void*);
const void* RenderStyle_verticalAlignLength(const void*);
const void* RenderStyle_lineHeight(const void*);
float RenderStyle_computedLineHeight(const void*);
const void* InlineFormattingContext_root(const void*);
void* InlineFormattingContext_globalLayoutState(void*);
uint16_t RenderStyle_lineFitEdge(const void*);
uint8_t RenderStyle_textDecorationSkipInk(const void*);
uint8_t RenderStyle_lineBoxContain(const void*);
uint8_t RenderStyle_textDecorationsInEffect(const void*);
float RenderStyle_borderLeftWidth(const void*);
float RenderStyle_borderRightWidth(const void*);
float RenderStyle_borderTopWidth(const void*);
float RenderStyle_borderBottomWidth(const void*);
float RenderStyle_outlineSize(const void*);
bool RenderStyle_hasOutlineInVisualOverflow(const void*);
const void* RenderStyle_textIndent(const void*);
const void* RenderStyle_marginTop(const void*);
const void* RenderStyle_marginBottom(const void*);
const void* RenderStyle_marginLeft(const void*);
const void* RenderStyle_marginRight(const void*);
const void* RenderStyle_paddingLeft(const void*);
const void* RenderStyle_paddingRight(const void*);
const void* RenderStyle_paddingTop(const void*);
const void* RenderStyle_paddingBottom(const void*);
bool RenderStyle_autoWrap(const void*);
int32_t RenderStyle_textShadowExtent_top(const void*);
int32_t RenderStyle_textShadowExtent_right(const void*);
int32_t RenderStyle_textShadowExtent_bottom(const void*);
int32_t RenderStyle_textShadowExtent_left(const void*);
bool RenderStyle_nbspMode(const void*);
int16_t RenderStyle_hyphenationLimitLines(const void*);
const void* RenderStyle_marginStart(const void*);
uint8_t RenderStyle_textEmphasisFill(const void*);
uint8_t RenderStyle_textEmphasisPosition(const void*);
bool RenderStyle_hasTextCombine(const void*);
bool LineBreakTable_unsafeLookup(uint16_t, uint16_t);
uint16_t BreakLines_classify(uint16_t, uint8_t);
bool LayoutState_inStandardsMode(const void*);
const void* LayoutState_securityOrigin(const void*);
int32_t ConstraintsForInlineContent_horizontal_logicalLeft(const void*);
int32_t ConstraintsForInlineContent_horizontal_logicalWidth(const void*);
int32_t ConstraintsForInlineContent_logicalTop(const void*);
int32_t ConstraintsForInlineContent_visualLeft(const void*);
uint8_t ConstraintsForInlineContent_baseTypeFlags(const void*);
void* LayoutState_ensureGeometryForBox(void*, const void*);
void* LayoutState_geometryForBox(const void*, const void*);
struct LayoutPositionRaw InlineDamage_layoutStartPosition(const void*);
void InlineDamage_setInlineItemListClean(void*);
const void* CPtrArrElement(const void* const*, uint64_t);
int32_t I32ArrElement(const void*, uint64_t);
struct HorizontalEdgesRaw BoxGeometry_horizontalMargin(const void*);
int32_t BoxGeometry_marginBefore(const void*);
int32_t BoxGeometry_marginStart(const void*);
int32_t BoxGeometry_marginAfter(const void*);
int32_t BoxGeometry_marginEnd(const void*);
int32_t BoxGeometry_borderStart(const void*);
int32_t BoxGeometry_borderEnd(const void*);
int32_t BoxGeometry_paddingStart(const void*);
int32_t BoxGeometry_paddingEnd(const void*);
int32_t BoxGeometry_borderAndPaddingBefore(const void*);
int32_t BoxGeometry_horizontalBorderAndPadding(const void*);
int32_t BoxGeometry_verticalBorderAndPadding(const void*);
int32_t BoxGeometry_contentBoxLeft(const void*);
int32_t BoxGeometry_contentBoxRight(const void*);
int32_t BoxGeometry_contentBoxHeight(const void*);
int32_t BoxGeometry_contentBoxWidth(const void*);
int32_t BoxGeometry_borderBoxHeight(const void*);
int32_t BoxGeometry_borderBoxWidth(const void*);
int32_t BoxGeometry_marginBoxHeight(const void*);
int32_t BoxGeometry_marginBoxWidth(const void*);
int32_t BoxGeometry_marginBorderAndPaddingStart(const void*);
int32_t BoxGeometry_marginBorderAndPaddingEnd(const void*);
int32_t BoxGeometry_horizontalMarginBorderAndPadding(const void*);
void BoxGeometry_setTopLeft(void*, int32_t, int32_t);
void BoxGeometry_setLeft(void*, int32_t);
void BoxGeometry_setContentBoxHeight(void*, int32_t);
void BoxGeometry_setContentBoxWidth(void*, int32_t);
void BoxGeometry_setHorizontalMargin(void*, int32_t, int32_t);
void BoxGeometry_setVerticalSpaceForScrollbar(void*, int32_t);
void BoxGeometry_setHorizontalSpaceForScrollbar(void*, int32_t);
int32_t BoxGeometry_top(const void*);
int32_t BoxGeometry_left(const void*);
struct GlyphOverflowRaw visualOverflowForDecorations(const void*, float, float);
bool RenderBlockFlow_hasNonSyntheticBaseline(const void*);
void ubidi_close_scion(void*);
struct UBiDiLogicalRunRaw ubidi_getLogicalRun_scion(void* p, int32_t logical_position);
void* ubidi_open_scion();
int32_t ubidi_setPara_scion(void* p, const void* text, uint32_t length, uint8_t para_level);
void ubidi_reorderVisual_scion(const uint8_t* levels, uint64_t length, int32_t* index_map);
struct NextU16Raw U16_NEXT_scion(const void* characters_raw, uint64_t position, uint32_t content_length);
