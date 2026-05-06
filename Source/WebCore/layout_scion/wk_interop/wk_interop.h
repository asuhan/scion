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

struct LineClampRaw {
    uint64_t maximumLines;
    bool shouldDiscardOverflow;
    bool isLegacy;
    bool isValid;
};

struct WordBreakLeftRaw {
    uint64_t length;
    float logicalWidth;
};

struct OptionalFloatRaw {
    float value;
    bool is_valid;
};

struct OptionalIntRaw {
    int32_t value;
    bool is_valid;
};

struct OptionalLayoutUnitRaw {
    int32_t value;
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

struct GlyphDataRaw {
    uint16_t glyph;
    const void* font;
    uint8_t color_glyph_type;
};

struct LineSegmentRaw {
    float logicalLeft;
    float logicalRight;
    bool isValid;
};

struct PathOperationRaw {
    uint8_t type;
    uint8_t referenceBox;
    bool is_valid;
};

struct BlockEllipsisRaw {
    uint8_t type;
    const void* string;
};

struct FloatRectRaw {
    float x;
    float y;
    float width;
    float height;
};

struct LayoutPointRaw {
    int32_t x;
    int32_t y;
};

struct LayoutSizeRaw {
    int32_t width;
    int32_t height;
};

struct LayoutRectRaw {
    int32_t x;
    int32_t y;
    int32_t width;
    int32_t height;
};

struct OptionalLayoutRectRaw {
    struct LayoutRectRaw rect;
    bool is_valid;
};

struct OptionalLineClampRaw {
    uint64_t maximumLines;
    bool shouldDiscardOverflow;
    bool isValid;
};

struct OptionalLegacyLineClampRaw {
    uint64_t maximumLineCount;
    uint64_t currentLineCount;
    bool isValid;
};

struct TextEdgeRaw {
    uint8_t over;
    uint8_t under;
};

struct OptionalTextBoxTrimRaw {
    bool trimFirstFormattedLine;
    struct TextEdgeRaw propagatedTextBoxEdge;
    bool isValid;
};

struct OptionalBool {
    bool value;
    bool is_valid;
};

struct PaintInfoRaw {
    struct LayoutRectRaw rect;
    uint16_t phase;
    uint32_t paint_behavior;
    void* subtree_paint_root;
    void* outline_objects;
    void* overlap_test_requests;
    const void* paint_container;
    bool require_security_origin_access_for_widgets;
    const void* enclosing_self_painting_layer;
    void* region_context;
};

struct LengthBoxRaw {
    const void* top;
    const void* right;
    const void* bottom;
    const void* left;
};

struct ScrollSnapAlignRaw {
    uint8_t blockAlign;
    uint8_t inlineAlign;
};

struct ScrollbarGutterRaw {
    bool isAuto;
    bool bothEdges;
};

struct ScopedNameRaw {
    const void* name;
    int8_t scopeOrdinal;
    bool isIdentifier;
    bool is_valid;
};

struct IntPointRaw {
    int32_t x;
    int32_t y;
};

struct IntSizeRaw {
    int32_t width;
    int32_t height;
};

struct IntRectRaw {
    struct IntPointRaw location;
    struct IntSizeRaw size;
};

struct PaginationRaw {
    uint8_t mode;
    bool behavesLikeColumns;
    uint32_t pageLength;
    uint32_t gap;
};

struct ComputedMarginValuesRaw {
    int32_t before;
    int32_t after;
    int32_t start;
    int32_t end;
};

struct LogicalExtentComputedValuesRaw {
    int32_t extent;
    int32_t position;
    struct ComputedMarginValuesRaw margins;
};

struct StyleContentAlignmentDataRaw {
    uint8_t position;
    uint8_t distribution;
    uint8_t overflow;
};

struct EnclosingCompositingLayerStatusRaw {
    bool fullRepaintAlreadyScheduled;
    void* layer;
};

struct RepaintRectsRaw {
    struct LayoutRectRaw clippedOverflowRect;
    struct OptionalLayoutRectRaw outlineBoundsRect;
};

struct OptionalRepaintRectsRaw {
    struct RepaintRectsRaw rects;
    bool is_valid;
};

struct VisibleRectContextRaw {
    bool hasPositionFixedDescendant;
    bool dirtyRectIsFlipped;
    bool descendantNeedsEnclosingIntRect;
    uint8_t options;
};

struct SRGBARaw {
    uint8_t red;
    uint8_t green;
    uint8_t blue;
    uint8_t alpha;
};

struct FloatPointRaw {
    float x;
    float y;
};

struct FloatSizeRaw {
    float width;
    float height;
};

struct RepaintContainerStatusRaw {
    bool fullRepaintIsScheduled;
    void* renderer;
};

struct FloatQuadRaw {
    struct FloatPointRaw p1;
    struct FloatPointRaw p2;
    struct FloatPointRaw p3;
    struct FloatPointRaw p4;
};

struct HitTestLocationRaw {
    struct LayoutPointRaw point;
    struct LayoutRectRaw boundingBox;
    struct FloatPointRaw transformedPoint;
    struct FloatQuadRaw transformedRect;
    bool isRectBased;
    bool isRectilinear;
};

struct HitTestRequestRaw {
    uint32_t type;
    bool source;
};

struct HitTestResultRaw {
    struct HitTestLocationRaw hitTestLocation;
    void* innerNode;
    void* innerNonSharedNode;
    struct LayoutPointRaw localPoint;
};

uint8_t RenderStyle_unicodeBidi(const void*);
float RenderStyle_tabSizeValue(const void*);
bool RenderStyle_tabSizeIsSpaces(const void*);
const void* RenderStyle_fontCascade(const void*);
uint8_t RenderStyle_textAlign(const void*);
bool RenderStyle_direction(const void*);
uint8_t RenderStyle_whiteSpaceCollapse(const void*);
bool RenderStyle_textWrapMode(const void*);
bool Font_hasVerticalGlyphs(const void*);
const void* Font_fontMetrics(const void*);
struct FloatRectRaw Font_boundsForGlyph(const void* font, uint16_t glyph);
float Font_widthForGlyph(const void* font, uint16_t glyph, uint8_t synthetic_bold_inclusion);
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
int32_t FontMetrics_intCapHeight(const void*);
const void* FontCascade_metricsOfPrimaryFont(const void*);
float FontCascade_floatEmphasisMarkHeight(const void* font_cascade_ptr, const void* mark_ptr);
bool FontCascade_isSmallCaps(const void*);
const void* FontCascade_primaryFont(const void*);
struct GlyphDataRaw FontCascade_glyphDataForCharacter(const void* font_cascade_ptr, uint32_t c, bool mirror, uint8_t variant);
const void* InlineTextBox_content(const void*);
bool InlineTextBox_isCombined(const void*);
bool InlineTextBox_canUseSimplifiedContentMeasuring(const void*);
bool InlineTextBox_canUseSimpleFontCodePath(const void*);
bool InlineTextBox_hasPositionDependentContentWidth(const void*);
bool InlineTextBox_hasStrongDirectionalityContent(const void*);
const void* InlineTextBox_style(const void*);
bool String_isNull(const void*);
bool String_isEmpty(const void*);
unsigned String_length(const void*);
unsigned StringView_length(const void*);
bool StringView_isEmpty(const void*);
uint16_t String_subscript(const void*, unsigned);
const void* String_substring(const void* p, uint32_t position, uint32_t length);
bool String_is8Bit(const void*);
void String_convertTo16Bit(const void*);
uint32_t String_hash(const void*);
bool StringView_is8Bit(const void*);
const void* TextRun_span8(const void*);
const void* TextRun_span16(const void*);
bool TextRun_is8Bit(const void*);
bool TextRun_rtl(const void*);
uint32_t TextRun_length(const void*);
void TextRun_setTabSize(void*, bool, float, bool);
void TextRun_setTextSpacingState(void*, const void*);
const void* TextRun_text(const void*);
uint64_t span8_size(const void*);
uint64_t span16_size(const void*);
uint16_t span8_subscript(const void*, uint64_t);
uint16_t span16_subscript(const void*, uint64_t);
const void* span8_data(const void*);
const void* span16_data(const void*);
bool StringBuilder_isEmpty(const void*);
uint32_t StringBuilder_length(const void*);
void* StringBuilder_view(const void*);
const void* String_span8(const void*);
const void* String_span16(const void*);
const void* StringView_span8(const void*);
const void* StringView_span16(const void*);
const void* StringView_fromString(const void*);
const void* StringView_substring(const void*, unsigned, unsigned);
void StringView_destroy(const void*);
const void* StringView_upconvertedCharacters(const void*);
void UpconvertedCharactersWithSize_destroy(const void*);
void* TextRun_fromStringView(const void*, float, float, bool, bool);
void TextRun_destroy(const void*);
const void* String_new();
const void* String_new_copy(const void*);
const void* String_new_span(const void*);
void StringWrapper_destroy(const void*);
const void* WTF_span_from_uchar(uint16_t);
void CharSpanWrapper8_destroy(const void*);
void CharSpanWrapper16_destroy(const void*);
void* StringBuilder_new();
void StringBuilder_destroy(const void*);
void StringBuilder_append_UChar(void*, uint16_t);
void StringBuilder_append_String(void*, const void*);
void StringBuilder_append_StringView(void*, const void*);
void StringBuilder_append_literal(void*, const char*);
const void* StringBuilder_toString(void*);
const void* Length_empty_new(uint8_t type);
const void* Length_new_int32(int32_t value, uint8_t type, bool has_quirk);
const void* Length_new(int32_t raw_value, uint8_t type, bool has_quirk);
const void* Length_new_float32(float value, uint8_t type, bool has_quirk);
const void* Length_new_float64(double value, uint8_t type, bool has_quirk);
void Length_destroy(const void*);
const void* FloatRect_new(float x, float y, float width, float height);
void FloatRect_destroy(const void*);
const void* Expansion_new(uint8_t left, uint8_t right, float horizontal_expansion);
void Expansion_destroy(const void*);
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
void CachedLineBreakIteratorFactory_destroy(const void*);
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
void EnclosingTopAndBottom_destroy(const void*);
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
void InlineDisplayBox_destroy(const void*);
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
void Ellipsis_destroy(const void*);
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
float TextUtil_hyphenWidth(const void*);
bool AtomString_isNull(const void*);
void AtomString_destroy(const void*);
const void* AtomString_nullAtom();
const void* AtomString_string(const void*);
uint8_t Length_type(const void*);
void Length_setValue_i32(const void* p, uint8_t type, int32_t value);
void Length_setValue_f32(const void* p, uint8_t type, float value);
void Length_setValue(const void* p, uint8_t type, int32_t value);
void Length_imul(const void* p, float value);
float Length_value(const void*);
int32_t Length_intValue(const void*);
float Length_percent(const void*);
bool Length_hasQuirk(const void*);
bool Length_isZero(const void*);
bool Length_isPositive(const void*);
bool Length_isNegative(const void*);
bool Length_isIntrinsic(const void*);
bool Length_isIntrinsicOrAuto(const void*);
float Length_nonNanCalculatedValue(const void*, float);
bool Length_isLegacyIntrinsic(const void*);
bool Length_eq(const void*, const void*);
bool Length_isFixed(const void*);
const void* InlineItemsBuilder_inlineContentCache(const void*);
const void* InlineItemsBuilder_root(const void*);
const void* InlineItemsBuilder_securityOrigin(const void*);
const void* ElementBox_firstChild(const void*);
const void* ElementBox_lastChild(const void*);
const void* ElementBox_firstInFlowChild(const void*);
bool ElementBox_isListMarkerImage(const void*);
bool ElementBox_isListMarkerOutside(const void*);
bool ElementBox_isListMarkerInsideList(const void*);
void* ElementBox_rendererForIntegration(const void*);
bool ElementBox_hasOutOfFlowChild(const void*);
void ElementBox_setBaselineForIntegration(const void*, int32_t);
bool ElementBox_hasBaselineForIntegration(const void*);
int32_t ElementBox_baselineForIntegration(const void*);
void* RenderObject_previousSibling(const void*);
void* RenderObject_nextSibling(const void*);
void* RenderObject_enclosingLayer(const void*);
bool RenderObject_useDarkAppearance(const void*);
bool RenderObject_isRenderElement(const void*);
bool RenderObject_isRenderTableCell(const void*);
bool RenderObject_isRenderMultiColumnSet(const void*);
bool RenderObject_isBody(const void*);
bool RenderObject_everHadLayout(const void*);
bool RenderObject_childrenInline(const void*);
bool RenderObject_isFloating(const void*);
bool RenderObject_isOutOfFlowPositioned(const void*);
bool RenderObject_isRenderText(const void*);
bool RenderObject_isRenderListBox(const void*);
bool RenderObject_isRenderListItem(const void*);
bool RenderObject_isRenderListMarker(const void*);
bool RenderObject_isRenderBlockFlow(const void*);
bool RenderObject_isRenderFlexibleBox(const void*);
bool RenderObject_isRenderBlock(const void*);
bool RenderObject_isRenderInline(const void*);
bool RenderObject_isRenderBox(const void*);
bool RenderObject_isImage(const void*);
bool RenderObject_isFieldset(const void*);
bool RenderObject_isRenderView(const void*);
bool RenderObject_isReplacedOrInlineBlock(const void*);
bool RenderObject_isHorizontalWritingMode(const void*);
bool RenderObject_isRenderFragmentedFlow(const void*);
bool RenderObject_isExcludedFromNormalLayout(const void*);
bool RenderObject_isExcludedAndPlacedInBorder(const void*);
bool RenderObject_hasLayer(const void*);
bool RenderObject_needsLayout(const void*);
bool RenderObject_selfNeedsLayout(const void*);
bool RenderObject_hasNonVisibleOverflow(const void*);
void* RenderObject_view(const void*);
bool RenderObject_isComposited(const void*);
int32_t RenderObject_minPreferredLogicalWidth(const void*);
int32_t RenderObject_maxPreferredLogicalWidth(const void*);
bool RenderObject_isSkippedContentForLayout(const void*);
void RenderObject_setPreviousSibling(void* p, void* previous);
void RenderObject_setNextSibling(void* p, void* next);
void RenderObject_setParent(void* p, void* parent);
void RenderObject_setNeedsLayout(void*, uint8_t);
void* RenderObject_containingBlock(const void*);
const void* RenderObject_style(const void*);
void* RenderObject_layoutBox(void*);
void* RenderObject_parent(void*);
void* RenderView_frameView(const void*);
void* RenderView_layoutState(void*);
void* RenderView_scion(const void*);
void* RenderLayerCompositor_create(void*);
void RenderLayerCompositor_destroy(void*);
bool RenderLayerCompositor_usesCompositing(const void* p);
bool RenderLayerCompositor_hasContentCompositingLayers(const void*);
void RenderLayerCompositor_rootBackgroundColorOrTransparencyChanged(void*);
void RenderLayerCompositor_repaintCompositedLayers(void*);
void RenderLayerCompositor_setIsInWindow(void*, bool);
bool RenderLayoutState_isPaginated(const void*);
int32_t RenderLayoutState_pageLogicalHeight(const void*);
void* RenderLayoutState_lineGrid(const void*);
void RenderLayoutState_setLineClamp(void* p, struct OptionalLineClampRaw lineClamp);
struct OptionalLineClampRaw RenderLayoutState_lineClamp(const void*);
struct OptionalLegacyLineClampRaw RenderLayoutState_legacyLineClamp(const void*);
struct OptionalTextBoxTrimRaw RenderLayoutState_textBoxTrim(const void*);
void RenderLayoutState_setTextBoxTrim(void* p, struct OptionalTextBoxTrimRaw);
struct OptionalBool RenderLayoutState_blockStartTrimming(const void*);
bool RenderLayoutState_hasTextBoxTrimStart(const void*);
bool RenderLayoutState_hasTextBoxTrimEnd(const void* p, const void* candidate_raw);
void* LocalFrame_document(const void*);
bool LocalFrame_shouldUsePrintingLayout(const void*);
float LocalFrame_frameScaleFactor(const void*);
void* LocalFrame_view(const void* p);
void* LocalFrame_eventHandler(void*);
void* LocalFrame_selection(void*);
void LocalFrameViewLayoutContext_scheduleLayout(void*);
bool LocalFrameViewLayoutContext_isInLayout(const void*);
bool LocalFrameViewLayoutContext_needsSkippedContentLayout(const void*);
bool LocalFrameViewLayoutContext_needsFullRepaint(const void*);
void* LocalFrameViewLayoutContext_layoutState(const void*);
bool LocalFrameViewLayoutContext_isPaintOffsetCacheEnabled(const void*);
void LocalFrameViewLayoutContext_checkLayoutState(void*);
struct LayoutSizeRaw LocalFrameViewLayoutContext_layoutDelta(const void*);
void LocalFrameViewLayoutContext_addLayoutDelta(void*, struct LayoutSizeRaw);
void* LocalFrameViewLayoutContext_updateScrollInfoAfterLayoutTransactionIfExists(void*);
bool LocalFrameViewLayoutContext_hasBoxesNeedingTransformUpdateAfterContainerLayout(const void*);
uint32_t LocalFrameViewLayoutContext_layoutIdentifier(const void*);
bool LocalFrameViewLayoutContext_pushLayoutState(void*, void*, struct LayoutSizeRaw, int32_t, bool);
void LocalFrameViewLayoutContext_popLayoutState(void*);
void LocalFrameViewLayoutContext_enablePaintOffsetCache(void*);
void* LocalFrameView_frame(const void*);
void* LocalFrameView_layoutContext(const void*);
bool LocalFrameView_needsLayout(const void*);
void LocalFrameView_setNeedsOneShotDrawingSynchronization(void*);
void LocalFrameView_recalculateScrollbarOverlayStyle(void*);
bool LocalFrameView_isTransparent(const void*);
void LocalFrameView_updateExtendBackgroundIfNecessary(void*);
bool LocalFrameView_hasExtendedBackgroundRectForPainting(const void*);
struct IntRectRaw LocalFrameView_extendedBackgroundRectForPainting(const void*);
struct IntRectRaw LocalFrameView_windowClipRect(const void*);
struct OptionalLayoutRectRaw LocalFrameView_visualViewportOverrideRect(const void*);
struct LayoutRectRaw LocalFrameView_fixedScrollableAreaBoundsInflatedForScrolling(const void*, struct LayoutRectRaw);
struct LayoutRectRaw LocalFrameView_layoutViewportRect(const void*);
struct LayoutRectRaw LocalFrameView_rectForFixedPositionLayout(const void*);
void LocalFrameView_setCannotBlitToWindow(void*);
void LocalFrameView_setContentIsOpaque(void*, bool);
float LocalFrameView_frameScaleFactor(const void*);
struct LayoutPointRaw LocalFrameView_scrollPositionForFixedPosition(const void*);
struct FloatPointRaw LocalFrameView_positionForRootContentLayer(const void*);
bool LocalFrameView_hasSlowRepaintObject(const void*, const void*);
bool LocalFrameView_speculativeTilingEnabled(const void*);
void LocalFrameView_setPaintBehavior(void*, uint32_t);
uint32_t LocalFrameView_paintBehavior(const void*);
struct LayoutPointRaw LocalFrameView_scrollPositionRespectingCustomFixedPosition(const void*);
void LocalFrameView_topContentDirectionDidChange(void*);
struct PaginationRaw LocalFrameView_pagination(const void*);
bool LocalFrameView_hasFlippedBlockRenderers(const void*);
void LocalFrameView_setHasFlippedBlockRenderers(void*, bool);
void LocalFrameView_updateScrollbarSteps(void*);
void LocalFrameView_scrollbarWidthChanged(void*, uint8_t);
bool LocalFrameView_layerAccessPrevented(const void*);
bool LocalFrameView_useSlowRepaintsIfNotOverlapped(const void*);
void* RenderElement_element(const void*);
void* RenderElement_firstChild(const void*);
void* RenderElement_lastChild(const void*);
void RenderElement_setChildNeedsLayout(void* p, uint8_t mark_parents);
bool RenderElement_hasBackground(const void*);
bool RenderElement_hasClipPath(const void*);
bool RenderElement_hasSelfPaintingLayer(const void*);
bool RenderElement_checkForRepaintDuringLayout(const void*);
bool RenderElement_isContinuation(const void*);
bool RenderElement_createsNewFormattingContext(const void*);
void RenderElement_layoutIfNeeded(void*);
bool RenderElement_isWritingModeRoot(const void*);
int32_t RenderBox_x(const void*);
int32_t RenderBox_y(const void*);
int32_t RenderBox_width(const void*);
int32_t RenderBox_height(const void*);
void RenderBox_setX(void*, int32_t);
void RenderBox_setY(void*, int32_t);
void* RenderBox_previousSiblingBox(const void*);
void* RenderBox_nextSiblingBox(const void*);
int32_t RenderBox_marginBefore(const void*, const void*);
void RenderBox_setMarginBefore(void*, int32_t, const void*);
void RenderBox_setMarginAfter(void*, int32_t, const void*);
void RenderBox_clearOverridingContainingBlockContentSize(void*);
void RenderBox_setOverridingLogicalWidthLength(void*, const void*);
void RenderBox_clearOverridingLogicalWidthLength(void*);
void RenderBox_computeAndSetBlockDirectionMargins(void*, const void*);
void RenderBox_repaintDuringLayoutIfMoved(void*, struct LayoutRectRaw);
bool RenderBox_shrinkToAvoidFloats(const void*);
bool RenderBox_avoidsFloats(const void*);
void RenderBox_flipForWritingMode(void* p, struct LayoutPointRaw position);
int32_t RenderBox_availableLogicalWidth(const void*);
int32_t RenderBox_logicalLeft(const void*);
struct LayoutPointRaw RenderBox_location(const void*);
void RenderBox_setLocation(void* p, int32_t x, int32_t y);
void RenderBox_move(void* p, int32_t dx, int32_t dy);
struct LayoutRectRaw RenderBox_frameRect(const void*);
void RenderBox_addLayoutOverflow(void*, struct LayoutRectRaw);
void RenderBox_addVisualOverflow(void* p, struct LayoutRectRaw);
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
struct LayoutRectRaw RenderBox_logicalVisualOverflowRectForPropagation(const void* p, const void* style_raw);
struct LayoutRectRaw RenderBox_layoutOverflowRectForPropagation(const void* p, const void* style_raw);
bool RenderBox_needsPreferredWidthsRecalculation(const void*);
bool RenderBox_hasRelativeLogicalHeight(const void*);
bool RenderBox_isFlexItem(const void*);
const void* RenderBox_shapeOutsideInfo(const void*);
int32_t RenderBoxModelObject_paddingStart(const void*);
int32_t RenderBoxModelObject_paddingEnd(const void*);
int32_t RenderBoxModelObject_borderStart(const void*);
int32_t RenderBoxModelObject_borderAndPaddingBefore(const void*);
int32_t RenderBoxModelObject_borderAndPaddingAfter(const void*);
int32_t RenderBoxModelObject_marginStart(const void*, const void*);
int32_t RenderBoxModelObject_baselinePosition(const void*, uint8_t, bool, uint8_t, uint8_t);
void* RenderBoxModelObject_inlineContinuation(const void*);
bool RenderListMarker_isInside(const void*);
void* RenderListMarker_listItem(void*);
void RenderText_setNeedsVisualReordering(void*);
bool Box_isContainingBlockForOutOfFlowPosition(const void*);
bool Box_isAnonymous(const void*);
bool Box_isBlockLevelBox(const void*);
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
bool Box_isInlineBlockBox(const void*);
bool Box_isInlineTableBox(const void*);
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
bool Box_establishesBlockFormattingContext(const void*);
bool Box_establishesInlineFormattingContext(const void*);
const void* Box_parent(const void*);
const void* Box_nextSibling(const void*);
const void* Box_firstLineStyle(const void*);
const void* Box_associatedRubyAnnotationBox(const void*);
const void* Box_style(const void*);
const void* Box_shape(const void*);
void Box_setIsInlineIntegrationRoot(const void*);
void Box_setIsFirstChildForIntegration(const void*, bool);
void Box_setShape(const void* box_raw, const void* shape);
void* Box_rendererForIntegration(const void*);
const void* RenderStyle_clone(const void*);
const void* RenderStyle_replace(const void*, const void*);
void RenderStyle_destroy(const void*);
uint32_t RenderStyle_pseudoElementType(const void*);
const void* RenderStyle_pseudoElementNameArgument(const void*);
const void* RenderStyle_getCachedPseudoStyle(const void*, uint32_t, const void*);
bool RenderStyle_isFloating(const void*);
uint8_t RenderStyle_position(const void*);
const void* RenderStyle_width(const void*);
const void* RenderStyle_height(const void*);
const void* RenderStyle_minWidth(const void*);
const void* RenderStyle_maxWidth(const void*);
const void* RenderStyle_minHeight(const void*);
const void* RenderStyle_maxHeight(const void*);
const void* RenderStyle_logicalWidth(const void*);
const void* RenderStyle_logicalHeight(const void*);
const void* RenderStyle_logicalMinWidth(const void*);
const void* RenderStyle_logicalMaxWidth(const void*);
const void* RenderStyle_logicalMinHeight(const void*);
const void* RenderStyle_logicalMaxHeight(const void*);
const void* RenderStyle_borderImage(const void*);
float RenderStyle_borderStartWidth(const void*);
float RenderStyle_borderEndWidth(const void*);
const void* RenderStyle_metricsOfPrimaryFont(const void*);
const void* RenderStyle_fontDescription(const void*);
float RenderStyle_computedFontSize(const void*);
uint8_t RenderStyle_rtlOrdering(const void*);
bool RenderStyle_hasDisplayAffectedByAnimations(const void*);
uint8_t RenderStyle_display(const void*);
const void* RenderStyle_left(const void*);
const void* RenderStyle_right(const void*);
const void* RenderStyle_top(const void*);
const void* RenderStyle_bottom(const void*);
const void* RenderStyle_logicalLeft(const void*);
const void* RenderStyle_logicalRight(const void*);
const void* RenderStyle_logicalTop(const void*);
const void* RenderStyle_logicalBottom(const void*);
const void* RenderStyle_backgroundLayers(const void*);
const void* RenderStyle_maskLayers(const void*);
uint8_t RenderStyle_borderCollapse(const void*);
float RenderStyle_horizontalBorderSpacing(const void*);
float RenderStyle_verticalBorderSpacing(const void*);
uint8_t RenderStyle_emptyCells(const void*);
uint8_t RenderStyle_captionSide(const void*);
bool RenderStyle_listStylePosition(const void*);
const void* RenderStyle_boxShadow(const void*);
void* RenderStyle_boxReflect(const void*);
uint8_t RenderStyle_boxDecorationBreak(const void*);
uint8_t RenderStyle_textOverflow(const void*);
uint8_t RenderStyle_wordBreak(const void*);
uint8_t RenderStyle_overflowWrap(const void*);
const void* RenderStyle_computedLocale(const void*);
bool RenderStyle_hasInlineColumnAxis(const void*);
uint8_t RenderStyle_columnProgression(const void*);
float RenderStyle_columnWidth(const void*);
bool RenderStyle_hasAutoColumnWidth(const void*);
bool RenderStyle_hasAutoColumnCount(const void*);
bool RenderStyle_specifiesColumns(const void*);
uint8_t RenderStyle_columnFill(const void*);
const void* RenderStyle_transformOriginX(const void*);
const void* RenderStyle_transformOriginY(const void*);
float RenderStyle_transformOriginZ(const void*);
uint8_t RenderStyle_transformBox(const void*);
bool RenderStyle_affectsTransform(const void*);
bool RenderStyle_hasTransform(const void*);
bool RenderStyle_columnSpan(const void*);
uint16_t RenderStyle_columnCount(const void*);
uint8_t RenderStyle_columnRuleStyle(const void*);
uint16_t RenderStyle_columnRuleWidth(const void*);
bool RenderStyle_columnRuleIsTransparent(const void*);
const void* RenderStyle_textEmphasisMarkString(const void*);
uint8_t RenderStyle_rubyPosition(const void*);
bool RenderStyle_isInterCharacterRubyPosition(const void*);
uint8_t RenderStyle_rubyAlign(const void*);
uint8_t RenderStyle_rubyOverhang(const void*);
uint8_t RenderStyle_textOrientation(const void*);
uint8_t RenderStyle_objectFit(const void*);
int32_t RenderStyle_initialLetterDrop(const void*);
int32_t RenderStyle_initialLetterHeight(const void*);
uint8_t RenderStyle_eventListenerRegionTypes(const void*);
bool RenderStyle_effectiveInert(const void*);
struct LengthBoxRaw RenderStyle_scrollMargin(const void*);
struct LengthBoxRaw RenderStyle_scrollPadding(const void*);
bool RenderStyle_hasSnapPosition(const void*);
struct ScrollSnapAlignRaw RenderStyle_scrollSnapAlign(const void*);
uint8_t RenderStyle_scrollSnapStop(const void*);
struct ScrollbarGutterRaw RenderStyle_scrollbarGutter(const void* p);
uint8_t RenderStyle_scrollbarWidth(const void*);
uint8_t RenderStyle_textSecurity(const void*);
uint8_t RenderStyle_writingMode(const void*);
bool RenderStyle_isHorizontalWritingMode(const void*);
bool RenderStyle_isVerticalWritingMode(const void*);
bool RenderStyle_isFlippedLinesWritingMode(const void*);
bool RenderStyle_isFlippedBlocksWritingMode(const void*);
uint8_t RenderStyle_blockFlowDirection(const void*);
bool RenderStyle_typographicMode(const void*);
uint8_t RenderStyle_imageRendering(const void*);
const void* RenderStyle_filter(const void*);
bool RenderStyle_hasFilter(const void*);
bool RenderStyle_hasReferenceFilterOnly(const void*);
bool RenderStyle_hasBackdropFilter(const void*);
bool RenderStyle_isInSubtreeWithBlendMode(const void*);
uint8_t RenderStyle_blendMode(const void*);
bool RenderStyle_hasBlendMode(const void*);
bool RenderStyle_isolation(const void*);
bool RenderStyle_usesStandardScrollbarStyle(const void*);
int32_t RenderStyle_usedZIndex(const void*);
bool RenderStyle_hasAutoUsedZIndex(const void*);
void RenderStyle_setUsedZIndex(const void*, int32_t);
void RenderStyle_setFlexGrow(const void*, float);
void RenderStyle_setFlexShrink(const void*, float);
void RenderStyle_setAlignSelfPosition(const void*, uint8_t);
void RenderStyle_setFlexDirection(const void*, uint8_t);
void RenderStyle_setFlexWrap(const void*, uint8_t);
void RenderStyle_setColumnSpan(const void*, bool);
void RenderStyle_setLineBoxContain(const void*, uint8_t);
float RenderStyle_computedStrokeWidth(const void*, int32_t, int32_t);
bool RenderStyle_hasExplicitlySetStrokeWidth(const void*);
void* RenderStyle_willChange(const void*);
const void* RenderStyle_hyphenString(const void*);
bool RenderStyle_isDisplayInlineType(const void*);
bool RenderStyle_isOriginalDisplayInlineType(const void*);
bool RenderStyle_isDisplayFlexibleBoxIncludingDeprecatedOrGridBox(const void*);
bool RenderStyle_isDisplayBlockLevel(const void*);
bool RenderStyle_isOriginalDisplayBlockType(const void*);
bool RenderStyle_isDisplayTableOrTablePart(const void*);
bool RenderStyle_isOriginalDisplayListItemType(const void*);
float RenderStyle_letterSpacing(const void*);
int32_t RenderStyle_getBoxShadowHorizontalExtentLeft(const void*);
int32_t RenderStyle_getBoxShadowHorizontalExtentRight(const void*);
int32_t RenderStyle_getBoxShadowVerticalExtentTop(const void*);
int32_t RenderStyle_getBoxShadowVerticalExtentBottom(const void*);
bool RenderStyle_hasBorder(const void*);
bool RenderStyle_hasBorderImage(const void*);
bool RenderStyle_hasUsedAppearance(const void*);
bool RenderStyle_hasBackground(const void*);
bool RenderStyle_hasBorderImageOutsets(const void*);
bool RenderStyle_hasStaticInlinePosition(const void*, bool);
bool RenderStyle_hasStaticBlockPosition(const void*, bool);
bool RenderStyle_hasViewportConstrainedPosition(const void*);
bool RenderStyle_hasVisibleBorder(const void*);
bool RenderStyle_hasPadding(const void*);
bool RenderStyle_hasBackgroundImage(const void*);
bool RenderStyle_hasAnyFixedBackground(const void*);
bool RenderStyle_hasEntirelyFixedBackground(const void*);
uint8_t RenderStyle_floating(const void*);
bool RenderStyle_hasBorderRadius(const void*);
bool RenderStyle_hasOutline(const void*);
uint8_t RenderStyle_outlineStyle(const void*);
uint8_t RenderStyle_overflowX(const void*);
uint8_t RenderStyle_overflowY(const void*);
bool RenderStyle_isOverflowVisible(const void*);
uint8_t RenderStyle_overscrollBehaviorX(const void*);
uint8_t RenderStyle_overscrollBehaviorY(const void*);
uint8_t RenderStyle_visibility(const void*);
uint8_t RenderStyle_usedVisibility(const void*);
uint8_t RenderStyle_verticalAlign(const void*);
const void* RenderStyle_verticalAlignLength(const void*);
const void* RenderStyle_lineHeight(const void*);
float RenderStyle_computedLineHeight(const void*);
const void* InlineFormattingContext_root(const void*);
void* InlineFormattingContext_globalLayoutState(void*);
void InlineFormattingContext_setClearGapAfterLastLine(void*, float);
uint16_t RenderStyle_lineFitEdge(const void*);
uint8_t RenderStyle_marginTrim(const void*);
uint8_t RenderStyle_textIndentType(const void*);
uint8_t RenderStyle_textTransform(const void*);
uint8_t RenderStyle_textDecorationSkipInk(const void*);
float RenderStyle_usedZoom(const void*);
uint8_t RenderStyle_textWrapStyle(const void*);
uint8_t RenderStyle_backgroundClip(const void*);
uint8_t RenderStyle_backgroundSizeType(const void*);
bool RenderStyle_hasTransformRelatedProperty(const void*);
bool RenderStyle_hasPositionedMask(const void*);
bool RenderStyle_hasMask(const void*);
uint8_t RenderStyle_backfaceVisibility(const void*);
float RenderStyle_perspective(const void*);
float RenderStyle_usedPerspective(const void*);
bool RenderStyle_hasPerspective(const void*);
const void* RenderStyle_perspectiveOriginX(const void*);
const void* RenderStyle_perspectiveOriginY(const void*);
uint8_t RenderStyle_lineBoxContain(const void*);
uint8_t RenderStyle_textDecorationsInEffect(const void*);
uint8_t RenderStyle_textDecorationLine(const void*);
uint8_t RenderStyle_textDecorationStyle(const void*);
float RenderStyle_borderLeftWidth(const void*);
uint8_t RenderStyle_borderLeftStyle(const void*);
bool RenderStyle_borderLeftIsTransparent(const void*);
float RenderStyle_borderRightWidth(const void*);
uint8_t RenderStyle_borderRightStyle(const void*);
bool RenderStyle_borderRightIsTransparent(const void*);
float RenderStyle_borderTopWidth(const void*);
uint8_t RenderStyle_borderTopStyle(const void*);
bool RenderStyle_borderTopIsTransparent(const void*);
float RenderStyle_borderBottomWidth(const void*);
uint8_t RenderStyle_borderBottomStyle(const void*);
bool RenderStyle_borderBottomIsTransparent(const void*);
float RenderStyle_outlineSize(const void*);
float RenderStyle_outlineWidth(const void*);
bool RenderStyle_outlineStyleIsAuto(const void*);
bool RenderStyle_hasOutlineInVisualOverflow(const void*);
const void* RenderStyle_clipLeft(const void*);
const void* RenderStyle_clipRight(const void*);
const void* RenderStyle_clipTop(const void*);
const void* RenderStyle_clipBottom(const void*);
uint8_t RenderStyle_clear(const void*);
bool RenderStyle_fieldSizing(const void*);
const void* RenderStyle_textIndent(const void*);
uint8_t RenderStyle_textBoxTrim(const void*);
struct TextEdgeRaw RenderStyle_textBoxEdge(const void*);
bool RenderStyle_isFixedTableLayout(const void*);
const void* RenderStyle_marginTop(const void*);
const void* RenderStyle_marginBottom(const void*);
const void* RenderStyle_marginLeft(const void*);
const void* RenderStyle_marginStart(const void*);
const void* RenderStyle_marginBefore(const void*);
const void* RenderStyle_marginAfter(const void*);
const void* RenderStyle_marginEnd(const void*);
const void* RenderStyle_marginStartUsing(const void*, const void*);
const void* RenderStyle_marginEndUsing(const void*, const void*);
const void* RenderStyle_marginBeforeUsing(const void*, const void*);
const void* RenderStyle_marginAfterUsing(const void*, const void*);
uint8_t RenderStyle_aspectRatioType(const void*);
double RenderStyle_aspectRatioWidth(const void*);
double RenderStyle_aspectRatioHeight(const void*);
double RenderStyle_aspectRatioLogicalWidth(const void*);
double RenderStyle_aspectRatioLogicalHeight(const void*);
double RenderStyle_logicalAspectRatio(const void*);
bool RenderStyle_boxSizingForAspectRatio(const void*);
bool RenderStyle_hasAspectRatio(const void*);
uint8_t RenderStyle_boxAlign(const void*);
float RenderStyle_boxFlex(const void*);
uint32_t RenderStyle_boxFlexGroup(const void*);
bool RenderStyle_boxLines(const void*);
bool RenderStyle_boxOrient(const void*);
uint8_t RenderStyle_boxPack(const void*);
uint32_t RenderStyle_gridAutoRepeatColumnsInsertionPoint(const void*);
uint32_t RenderStyle_gridAutoRepeatRowsInsertionPoint(const void*);
uint8_t RenderStyle_gridAutoRepeatColumnsType(const void*);
uint8_t RenderStyle_gridAutoRepeatRowsType(const void*);
uint64_t RenderStyle_namedGridAreaRowCount(const void*);
uint64_t RenderStyle_namedGridAreaColumnCount(const void*);
uint8_t RenderStyle_gridAutoFlow(const void*);
bool RenderStyle_isGridAutoFlowDirectionColumn(const void*);
bool RenderStyle_isGridAutoFlowAlgorithmDense(const void*);
const void* RenderStyle_marginRight(const void*);
const void* RenderStyle_paddingLeft(const void*);
const void* RenderStyle_paddingRight(const void*);
const void* RenderStyle_paddingBefore(const void*);
const void* RenderStyle_paddingAfter(const void*);
const void* RenderStyle_paddingStart(const void*);
const void* RenderStyle_paddingEnd(const void*);
uint8_t RenderStyle_insideLink(const void*);
bool RenderStyle_isLink(const void*);
bool RenderStyle_insideDefaultButton(const void*);
uint16_t RenderStyle_widows(const void*);
uint16_t RenderStyle_orphans(const void*);
bool RenderStyle_hasAutoWidows(const void*);
bool RenderStyle_hasAutoOrphans(const void*);
uint8_t RenderStyle_breakInside(const void*);
uint8_t RenderStyle_breakBefore(const void*);
uint8_t RenderStyle_breakAfter(const void*);
const void* RenderStyle_paddingTop(const void*);
const void* RenderStyle_paddingBottom(const void*);
uint8_t RenderStyle_hangingPunctuation(const void*);
float RenderStyle_outlineOffset(const void*);
uint8_t RenderStyle_usedContain(const void*);
bool RenderStyle_containsPaint(const void*);
bool RenderStyle_containsLayoutOrPaint(const void*);
uint8_t RenderStyle_containerType(const void*);
uint8_t RenderStyle_contentVisibility(const void*);
uint8_t RenderStyle_usedContentVisibility(const void*);
bool RenderStyle_hasSkippedContent(const void*);
uint8_t RenderStyle_containIntrinsicWidthType(const void*);
uint8_t RenderStyle_containIntrinsicHeightType(const void*);
bool RenderStyle_containIntrinsicWidthHasAuto(const void*);
bool RenderStyle_containIntrinsicHeightHasAuto(const void*);
bool RenderStyle_containIntrinsicLogicalWidthHasAuto(const void*);
bool RenderStyle_containIntrinsicLogicalHeightHasAuto(const void*);
bool RenderStyle_hasAutoLengthContainIntrinsicSize(const void*);
int32_t RenderStyle_order(const void*);
float RenderStyle_flexGrow(const void*);
float RenderStyle_flexShrink(const void*);
const void* RenderStyle_flexBasis(const void*);
uint8_t RenderStyle_flexDirection(const void*);
bool RenderStyle_isRowFlexDirection(const void*);
bool RenderStyle_isColumnFlexDirection(const void*);
uint8_t RenderStyle_flexWrap(const void*);
bool RenderStyle_gridSubgridRows(const void*);
bool RenderStyle_gridSubgridColumns(const void*);
bool RenderStyle_gridMasonryRows(const void*);
bool RenderStyle_gridMasonryColumns(const void*);
uint8_t RenderStyle_boxSizing(const void*);
uint8_t RenderStyle_userModify(const void*);
uint8_t RenderStyle_userDrag(const void*);
uint8_t RenderStyle_userSelect(const void*);
struct StyleContentAlignmentDataRaw RenderStyle_alignContent(const void*);
uint8_t RenderStyle_resize(const void*);
uint8_t RenderStyle_lineAlign(const void*);
uint8_t RenderStyle_lineSnap(const void*);
uint8_t RenderStyle_pointerEvents(const void*);
uint8_t RenderStyle_usedPointerEvents(const void*);
uint8_t RenderStyle_usedTransformStyle3D(const void*);
bool RenderStyle_preserves3D(const void*);
void RenderStyle_setUnicodeBidi(const void*, uint8_t);
void RenderStyle_setTextWrapMode(const void*, bool);
uint8_t RenderStyle_capStyle(const void*);
uint8_t RenderStyle_paintOrder(const void*);
uint8_t RenderStyle_joinStyle(const void*);
const void* RenderStyle_strokeWidth(const void*);
bool RenderStyle_hasVisibleStroke(const void*);
float RenderStyle_strokeMiterLimit(const void*);
bool RenderStyle_hasExplicitlySetColor(const void*);
void* RenderStyle_shapeOutside(const void*);
const void* RenderStyle_shapeMargin(const void*);
float RenderStyle_shapeImageThreshold(const void*);
void* RenderStyle_offsetPath(const void*);
struct PathOperationRaw RenderStyle_clipPath(const void*);
struct BlockEllipsisRaw RenderStyle_blockEllipsis(const void*);
uint64_t RenderStyle_maxLines(const void*);
bool RenderStyle_overflowContinue(const void*);
bool RenderStyle_autoWrap(const void*);
bool RenderStyle_preserveNewline(const void*);
int32_t RenderStyle_textShadowExtent_top(const void*);
int32_t RenderStyle_textShadowExtent_right(const void*);
int32_t RenderStyle_textShadowExtent_bottom(const void*);
int32_t RenderStyle_textShadowExtent_left(const void*);
float RenderStyle_textStrokeWidth(const void*);
float RenderStyle_opacity(const void*);
bool RenderStyle_hasOpacity(const void*);
uint8_t RenderStyle_usedAppearance(const void*);
bool RenderStyle_nbspMode(const void*);
uint8_t RenderStyle_lineBreak(const void*);
int16_t RenderStyle_hyphenationLimitLines(const void*);
uint8_t RenderStyle_hyphens(const void*);
int16_t RenderStyle_hyphenationLimitBefore(const void*);
int16_t RenderStyle_hyphenationLimitAfter(const void*);
const void* RenderStyle_marginStart(const void*);
uint8_t RenderStyle_textEmphasisMark(const void*);
uint8_t RenderStyle_textEmphasisPosition(const void*);
bool RenderStyle_hasTextCombine(const void*);
void RenderStyle_setFloating(const void*, uint8_t);
bool RenderStyle_borderIsEquivalentForPainting(const void*, const void*);
struct ScopedNameRaw RenderStyle_viewTransitionName(const void*);
void RenderStyle_setDisplay(const void*, uint8_t);
void RenderStyle_setPosition(const void*, uint8_t);
void RenderStyle_setTextAlign(const void*, uint8_t);
void RenderStyle_setDirection(const void*, bool);
uint8_t RenderStyle_textAlignLast(const void*);
struct LengthBoxRaw RenderStyle_clip(const void*);
bool RenderStyle_hasClip(const void*);
bool LineBreakTable_unsafeLookup(uint16_t, uint16_t);
uint16_t BreakLines_classify(uint16_t, uint8_t);
void LayoutState_updateQuirksMode(void*, const void*);
void* LayoutState_ensureBlockFormattingState(void*, const void*);
bool LayoutState_inStandardsMode(const void*);
const void* LayoutState_securityOrigin(const void*);
int32_t ConstraintsForInlineContent_horizontal_logicalLeft(const void*);
int32_t ConstraintsForInlineContent_horizontal_logicalWidth(const void*);
int32_t ConstraintsForInlineContent_logicalTop(const void*);
int32_t ConstraintsForInlineContent_visualLeft(const void*);
uint8_t ConstraintsForInlineContent_baseTypeFlags(const void*);
void* LayoutState_ensureGeometryForBox(void*, const void*);
void* LayoutState_geometryForBox(const void*, const void*);
void* LayoutState_createForView(const void*, const void*);
void LayoutState_destroy(const void*);
void* PaintInfo_context(const void*);
void PaintInfo_updateSubtreePaintRootForChildren(void* p, const void*);
bool PaintInfo_shouldPaintWithinRoot(void* p, const void*);
bool PaintInfo_skipRootBackground(const void*);
bool PaintInfo_paintRootBackgroundOnly(const void*);
void* PaintInfo_eventRegionContext(void*);
struct LayoutPositionRaw InlineDamage_layoutStartPosition(const void*);
bool InlineDamage_isInlineItemListDirty(const void*);
void InlineDamage_setInlineItemListClean(void*);
bool InlineDamage_hasDetachedContent(const void*);
const void* CPtrArrElement(const void* const*, uint64_t);
int32_t I32ArrElement(const void*, uint64_t);
struct BoxGeometryHorizontalEdgesRaw BoxGeometry_horizontalMargin(const void*);
int32_t BoxGeometry_marginBefore(const void*);
int32_t BoxGeometry_marginStart(const void*);
int32_t BoxGeometry_marginAfter(const void*);
int32_t BoxGeometry_marginEnd(const void*);
int32_t BoxGeometry_borderBefore(const void*);
int32_t BoxGeometry_borderStart(const void*);
int32_t BoxGeometry_borderEnd(const void*);
int32_t BoxGeometry_paddingStart(const void*);
int32_t BoxGeometry_paddingEnd(const void*);
int32_t BoxGeometry_borderAndPaddingBefore(const void*);
int32_t BoxGeometry_borderAndPaddingAfter(const void*);
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
void BoxGeometry_moveHorizontally(void*, int32_t);
void BoxGeometry_setContentBoxHeight(void*, int32_t);
void BoxGeometry_setContentBoxWidth(void*, int32_t);
void BoxGeometry_setHorizontalMargin(void*, int32_t, int32_t);
void BoxGeometry_setVerticalMargin(void*, int32_t, int32_t);
void BoxGeometry_setBorder(void* p, struct BoxGeometryEdgesRaw);
void BoxGeometry_setVerticalSpaceForScrollbar(void*, int32_t);
void BoxGeometry_setHorizontalSpaceForScrollbar(void*, int32_t);
int32_t BoxGeometry_top(const void*);
int32_t BoxGeometry_left(const void*);
struct GlyphOverflowRaw visualOverflowForDecorations(const void*, float, float);
struct GlyphOverflowRaw visualOverflowForDecorationsByStyle(const void*);
void RenderBlockFlow_setStaticInlinePositionForChild(void* p, void* child_raw, int32_t block_offset_raw, int32_t inline_position_raw);
bool RenderBlockFlow_containsFloats(const void*);
int32_t RenderBlockFlow_lowestFloatLogicalBottom(const void* p, uint8_t float_type_raw);
int32_t RenderBlockFlow_endPaddingWidthForCaret(const void*);
struct OptionalLayoutUnitRaw RenderBlockFlow_lowestInitialLetterLogicalBottom(const void*);
int32_t RenderBlockFlow_maxPositiveMarginBefore(const void*);
int32_t RenderBlockFlow_maxNegativeMarginBefore(const void*);
int32_t RenderBlockFlow_maxPositiveMarginAfter(const void*);
int32_t RenderBlockFlow_maxNegativeMarginAfter(const void*);
bool RenderBlockFlow_hasNonSyntheticBaseline(const void*);
void* RenderBlockFlow_insertFloatingObjectForIFC(void* floating_object_raw, void* float_box_raw);
struct LayoutRectRaw PaintInfo_rect(const void*);
uint16_t PaintInfo_phase(const void*);
void PaintInfo_setPhase(void*, uint16_t);
bool RenderBlock_hasMarginBeforeQuirk(const void*);
bool RenderBlock_hasMarginAfterQuirk(const void*);
void RenderBlock_markForPaginationRelayoutIfNeeded(void*);
bool RenderBlock_containsFloats(const void*);
int32_t RenderBlock_intrinsicBorderForFieldset(const void*);
void RenderBlock_layout(void*);
bool RenderBlock_isSelfCollapsingBlock(const void*);
bool u_hasBinaryProperty_scion(int32_t c, uint32_t which);
uint32_t u_getIntPropertyValue_scion(uint16_t character, uint32_t property);
int32_t u_toupper_scion(int32_t);
void ubidi_close_scion(void*);
struct UBiDiLogicalRunRaw ubidi_getLogicalRun_scion(void* p, int32_t logical_position);
void* ubidi_open_scion();
int32_t ubidi_setPara_scion(void* p, const void* text, uint32_t length, uint8_t para_level);
void ubidi_reorderVisual_scion(const uint8_t* levels, uint64_t length, int32_t* index_map);
uint8_t ubidi_getBaseDirection_scion(const uint16_t* text, int32_t length);
int8_t u_charType_scion(int32_t);
struct NextU16Raw U16_NEXT_scion(const void* characters_raw, uint64_t position, uint32_t content_length);
struct NextU16Raw U16_NEXT_buff_scion(const void* characters_raw, uint64_t position, uint32_t content_length);
uint32_t U16_FWD_1_scion(const void* s_raw, uint32_t i, uint32_t length);
void U16_SET_CP_START_scion(const void* s_raw, uint32_t start, uint32_t i);
bool Hyphenation_canHyphenate(const void*);
uint64_t Hyphenation_lastHyphenLocation(const void* string_raw, uint64_t before_index, const void* locale_identifier_raw);
const void* makeString_scion(const void* string_view_raw, const void* atom_string_raw);
bool WTF_areEssentiallyEqual(float, float);
const void* ShapeOutsideInfo_computedShape(const void*);
bool Shape_lineOverlapsShapeMarginBounds(const void* p, int32_t line_top_raw, int32_t line_height_raw);
struct LineSegmentRaw Shape_getExcludedInterval(const void* p, int32_t logical_top_raw, int32_t logical_height_raw);
void* FormattingContextBoxIteratorAdapter_new(const void*);
void FormattingContextBoxIteratorAdapter_destroy(const void*);
void* FormattingContextBoxIteratorAdapter_begin(void*);
void* FormattingContextBoxIteratorAdapter_end(void*);
void FormattingContextBoxIterator_destroy(const void*);
const void* FormattingContextBoxIterator_deref(void*);
void* FormattingContextBoxIterator_preinc(void*);
bool FormattingContextBoxIterator_equal(const void*, const void*);
void FloatingObject_setIsPlaced(void*, bool);
void FloatingObject_setMarginOffset(void* p, int32_t width, int32_t height);
void FloatingObject_setFrameRect(void* p, int32_t x, int32_t y, int32_t width, int32_t height);
void* RenderLayerModelObject_layer(const void*);
bool RenderLayerModelObject_shouldPlaceVerticalScrollbarOnLeft(const void*);
void* RenderLayer_create(void*);
void RenderLayer_destroy(const void*);
void* RenderLayer_scrollableArea(const void*);
void* RenderLayer_renderer(const void*);
void RenderLayer_insertOnlyThisLayer(void*, bool);
void RenderLayer_setBackingNeedsRepaint(void*, bool);
void RenderLayer_styleChanged(void*, uint8_t, const void*);
bool RenderLayer_cannotBlitToWindow(const void*);
void RenderLayer_updateTransform(void*);
struct EnclosingCompositingLayerStatusRaw RenderLayer_enclosingCompositingLayerForRepaint(const void*, bool);
int32_t RenderLayer_staticInlinePosition(const void*);
int32_t RenderLayer_staticBlockPosition(const void*);
void RenderLayer_setStaticInlinePosition(void* p, int32_t position);
void RenderLayer_setStaticBlockPosition(void* p, int32_t position);
bool RenderLayer_isBackdropRoot(const void*);
bool RenderLayer_isolatesBlending(const void*);
bool RenderLayer_isComposited(const void*);
void RenderLayer_setIsHiddenByOverflowTruncation(void* p, bool is_hidden);
void* Document_frame(const void*);
void* Document_documentElement(const void*);
bool Document_isImageDocument(const void*);
bool Document_isSVGDocument(const void*);
bool Document_isPluginDocument(const void*);
bool Document_hasSVGRootNode(const void*);
float Document_deviceScaleFactor(const void*);
bool Document_useDarkAppearance(const void* raw, const void* style_raw);
void* Document_view(const void* raw);
const void* Document_page(const void*);
const void* Document_settings(const void* raw);
void* Document_renderView(const void* raw);
bool Document_renderTreeBeingDestroyed(const void*);
void* Document_existingAXObjectCache(const void*);
bool Document_printing(const void* raw);
bool Document_paginated(const void* raw);
bool Document_inQuirksMode(const void* raw);
bool Document_inLimitedQuirksMode(const void* raw);
bool Document_inNoQuirksMode(const void*);
void* Document_ownerElement(const void*);
void* Document_topDocument(const void* raw);
uint8_t Document_backForwardCacheState(const void*);
void Document_invalidateRenderingDependentRegions(void*);
bool Document_visualUpdatesAllowed(const void*);
bool Document_inRenderTreeUpdate(const void*);
void* Document_securityOrigin(const void* raw);
bool Document_activeViewTransitionCapturedDocumentElement(const void*);
bool Document_hasViewTransitionPseudoElementTree(const void*);
bool Document_renderingIsSuppressedForViewTransition(const void*);
bool Document_hasTopLayerElement(const void*);
bool Document_hasHighlight(const void*);
bool Document_activeDOMObjectsAreSuspended(const void*);
bool Settings_acceleratedCompositingEnabled(const void*);
bool Settings_acceleratedCompositingForFixedPositionEnabled(const void*);
bool Settings_acceleratedDrawingEnabled(const void*);
bool Settings_alignContentOnBlocksEnabled(const void*);
bool Settings_animatedImageAsyncDecodingEnabled(const void*);
bool Settings_asyncOverflowScrollingEnabled(const void*);
bool Settings_backgroundShouldExtendBeyondPage(const void*);
bool Settings_caretBrowsingEnabled(const void*);
bool Settings_clientCoordinatesRelativeToLayoutViewport(const void*);
bool Settings_css3DTransformBackfaceVisibilityInteroperabilityEnabled(const void*);
bool Settings_cssScrollAnchoringEnabled(const void*);
bool Settings_cssUnprefixedBackdropFilterEnabled(const void*);
bool Settings_fixedBackgroundsPaintRelativeToDocument(const void*);
bool Settings_forceCompositingMode(const void*);
bool Settings_grammarAndSpellingPseudoElementsEnabled(const void*);
bool Settings_highlightAPIEnabled(const void*);
bool Settings_imageSubsamplingEnabled(const void*);
bool Settings_incompleteImageBorderEnabled(const void*);
bool Settings_largeImageAsyncDecodingEnabled(const void*);
bool Settings_layerBasedSVGEngineEnabled(const void*);
bool Settings_legacyLineLayoutVisualCoverageEnabled(const void*);
bool Settings_overlappingBackingStoreProvidersEnabled(const void*);
bool Settings_scrollToTextFragmentEnabled(const void*);
bool Settings_scrollingPerformanceTestingEnabled(const void*);
bool Settings_shouldAllowUserInstalledFonts(const void*);
bool Settings_shouldPrintBackgrounds(const void*);
bool Settings_showDebugBorders(const void*);
bool Settings_showRepaintCounter(const void*);
bool Settings_systemLayoutDirection(const void*);
bool Settings_userInterfaceDirectionPolicy(const void*);
bool Settings_visualViewportEnabled(const void*);
bool Node_hasChildNodes(const void*);
bool Node_isSVGElement(const void*);
bool Node_isPseudoElement(const void*);
bool Node_isBeforePseudoElement(const void*);
bool Node_isAfterPseudoElement(const void*);
bool Node_isDocumentNode(const void*);
bool Node_hasCustomStyleResolveCallbacks(const void*);
bool Node_needsSVGRendererUpdate(const void*);
void Node_setNeedsSVGRendererUpdate(void*, bool);
bool Node_hasEverPaintedImages(const void*);
void Node_setHasEverPaintedImages(void*, bool);
bool Node_isRootEditableElement(const void*);
bool Node_isEditingText(const void*);
bool Node_hasEditableStyle(const void*, bool);
uint32_t Node_computeNodeIndex(const void*);
void* Node_document(const void*);
void* Node_renderer(const void*);
void* Node_renderBox(const void*);
const void* BoxTree_handleNullRootBox(void*);
void BoxTree_buildTreeForInlineContent(void*);
void* InlineWalker_new(const void*);
void InlineWalker_destroy(const void*);
void* InlineWalker_current(void*);
bool InlineWalker_atEnd(void*);
void InlineWalker_advance(void*);
void* FillLayer_image(const void*);
const void* FillLayer_next(const void*);
void* NinePieceImage_image(const void*);
void* ShapeValue_image(const void*);
void* Frame_page(const void*);
bool Frame_isMainFrame(const void*);
bool Frame_isRootFrame(const void*);
const void* Page_dragCaretController(const void*);
void* Page_settings(const void*);
float Page_pageScaleFactor(const void*);
bool Page_delegatesScaling(const void*);
float Page_deviceScaleFactor(const void*);
bool Page_useSystemAppearance(const void*);
bool Page_isVisible(const void*);
bool Page_isInWindow(const void*);
bool Page_hasEverSetVisibilityAdjustment(const void*);
const void* FilterOperations_create();
void FilterOperations_destroy(const void*);
bool FilterOperations_eq(const void*, const void*);
bool FilterOperations_isEmpty(const void*);
uint64_t FilterOperations_size(const void*);
bool FilterOperations_hasFilterThatAffectsOpacity(const void*);
bool FilterOperations_hasFilterThatMovesPixels(const void*);
bool FilterOperations_hasFilterThatShouldBeRestrictedBySecurityOrigin(const void*);
bool FilterOperations_hasReferenceFilter(const void*);
bool FilterOperations_isReferenceFilter(const void*);
bool WillChangeData_canCreateStackingContext(const void*);
bool WillChangeData_createsContainingBlockForAbsolutelyPositioned(const void*, bool);
bool WillChangeData_createsContainingBlockForOutOfFlowPositioned(const void*, bool);
bool WillChangeData_canTriggerCompositing(const void*);
bool WillChangeData_canTriggerCompositingOnInline(const void*);
bool Element_hasNowrapAttr(const void*);
bool Element_hasAltAttr(const void*);
bool Element_hasFontTag(const void*);
bool Element_isFormControlElement(const void*);
bool Element_isDisabledFormControl(const void*);
bool Element_childShouldCreateRenderer(const void* p, const void* child);
bool Element_isLink(const void*);
bool Element_isInTopLayer(const void*);
void Element_willAttachRenderers(void*);
void Element_didAttachRenderers(void*);
void Element_willDetachRenderers(void*);
void Element_didDetachRenderers(void*);
void Element_clearBeforePseudoElement(void*);
void Element_clearAfterPseudoElement(void*);
void Element_clearHoverAndActiveStatusBeforeDetachingRenderer(void*);
bool Element_hasDisplayContents(void*);
void Element_clearDisplayContentsOrNoneStyle(void*);
struct OptionalLayoutUnitRaw Element_lastRememberedLogicalWidth(void*);
struct OptionalLayoutUnitRaw Element_lastRememberedLogicalHeight(void*);
void Element_clearLastRememberedLogicalWidth(void*);
void Element_clearLastRememberedLogicalHeight(void*);
bool Element_isRelevantToUser(void*);
struct IntPointRaw Element_savedLayerScrollPosition(const void*);
void Element_setSavedLayerScrollPosition(void* p, struct IntPointRaw raw);
void RenderGeometryMap_pushView(void* raw, const void* view_raw, struct LayoutSizeRaw scroll_offset_raw, const void* t_raw);
int32_t ScrollView_width(const void*);
int32_t ScrollView_height(const void*);
struct IntRectRaw ScrollView_windowClipRect(const void*);
void ScrollView_positionScrollbarLayers(void*);
uint8_t ScrollView_delegatedScrollingMode(const void*);
struct IntSizeRaw ScrollView_sizeForVisibleContent(const void*, bool);
struct IntSizeRaw ScrollView_layoutSize(const void*);
int32_t ScrollView_layoutWidth(const void*);
int32_t ScrollView_layoutHeight(const void*);
struct IntSizeRaw ScrollView_fixedLayoutSize(const void*);
struct IntSizeRaw ScrollView_contentsSize(const void*);
struct IntPointRaw ScrollView_documentScrollPositionRelativeToViewOrigin(const void*);
struct IntRectRaw ScrollView_windowToContents(const void* p, struct IntRectRaw);
bool ScrollView_isOffscreen(const void*);
bool ScrollView_managesScrollbars(const void*);
void ScrollView_updateScrollbarSteps(void*);
bool ScrollView_useFixedLayout(const void*);
struct IntSizeRaw ScrollView_size(const void*);
struct IntPointRaw ScrollView_location(const void*);
void ScrollView_setFrameRect(void* p, struct IntRectRaw);
struct IntRectRaw ScrollView_frameRect(const void*);
void ScrollView_show(void*);
void ScrollView_hide(void*);
uint8_t ScrollableArea_horizontalScrollbarMode(const void*);
uint8_t ScrollableArea_verticalScrollbarMode(const void*);
struct ScrollbarGutterRaw ScrollableArea_scrollbarGutterStyle(const void*);
uint8_t ScrollableArea_scrollbarWidthStyle(const void*);
bool ScrollableArea_inLiveResize(const void*);
bool ScrollableArea_hasOverlayScrollbars(const void*);
bool ScrollableArea_isScrollCornerVisible(const void*);
struct IntRectRaw ScrollableArea_scrollCornerRect(const void*);
void ScrollableArea_invalidateScrollCorner(void*, struct IntRectRaw);
struct IntPointRaw ScrollableArea_scrollPosition(const void*);
struct IntPointRaw ScrollableArea_scrollOffset(const void*);
bool ScrollableArea_currentScrollType(const void*);
struct IntRectRaw ScrollableArea_visibleContentRect(const void*);
struct IntSizeRaw ScrollableArea_contentsSize(const void*);
bool ScrollableArea_useDarkAppearance(const void*);
void ScrollableArea_scrollbarWidthChanged(void*, uint8_t);
void* RenderSelection_create(void*);
void RenderSelection_destroy(const void*);
const void* InitialContainingBlock_create(const void*);
void InitialContainingBlock_destroy(const void*);
void* ContainerNode_renderer(const void*);
struct SRGBARaw LocalFrameView_documentBackgroundColor(const void*);
bool LocalFrameView_hasEnoughContentForVisualMilestones(const void*);
bool LocalFrameView_isScrollable(void*, bool);
bool LocalFrameView_isTrackingRepaints(const void*);
bool GraphicsContext_paintingDisabled(const void*);
bool GraphicsContext_performingPaintInvalidation(const void*);
bool GraphicsContext_invalidatingControlTints(const void*);
bool GraphicsContext_invalidatingImagesWithAsyncDecodes(const void*);
bool GraphicsContext_detectingContentfulPaint(const void*);
void GraphicsContext_setFillRule(void*, uint8_t);
uint8_t GraphicsContext_strokeStyle(const void*);
void GraphicsContext_setStrokeStyle(void*, uint8_t);
float GraphicsContext_strokeThickness(const void*);
void GraphicsContext_setStrokeThickness(void*, float);
uint8_t GraphicsContext_compositeOperation(const void*);
void GraphicsContext_setCompositeOperation(void*, uint8_t, uint8_t);
float GraphicsContext_alpha(const void*);
void GraphicsContext_setAlpha(void*, float);
uint8_t GraphicsContext_textDrawingMode(const void*);
void GraphicsContext_setTextDrawingMode(void*, uint8_t);
uint8_t GraphicsContext_imageInterpolationQuality(const void*);
void GraphicsContext_setImageInterpolationQuality(void*, uint8_t);
bool GraphicsContext_shouldAntialias(const void*);
void GraphicsContext_setShouldAntialias(void*, bool);
bool GraphicsContext_shouldSubpixelQuantizeFonts(const void*);
void GraphicsContext_setShouldSubpixelQuantizeFonts(void*, bool);
void GraphicsContext_setDrawLuminanceMask(void*, bool);
void GraphicsContext_save(void*, uint8_t);
void GraphicsContext_restore(void*, uint8_t);
void GraphicsContext_drawRect(void*, struct FloatRectRaw, float);
void GraphicsContext_drawLine(void*, struct FloatPointRaw, struct FloatPointRaw);
void GraphicsContext_fillEllipse(void*, struct FloatRectRaw);
void GraphicsContext_strokeEllipse(void*, struct FloatRectRaw);
void GraphicsContext_fillRectWithClipping(void*, struct FloatRectRaw, bool);
void GraphicsContext_fillRect(void* p, struct FloatRectRaw, struct SRGBARaw);
void GraphicsContext_clearRect(void*, struct FloatRectRaw);
void GraphicsContext_strokeRect(void*, struct FloatRectRaw, float);
void GraphicsContext_setLineCap(void*, uint8_t);
void GraphicsContext_setLineJoin(void*, uint8_t);
void GraphicsContext_setMiterLimit(void*, float);
void GraphicsContext_clip(void*, struct FloatRectRaw);
void GraphicsContext_clipOut(void*, struct FloatRectRaw);
struct FloatRectRaw GraphicsContext_computeUnderlineBoundsForText(void*, struct FloatRectRaw, bool);
void GraphicsContext_drawLineForText(void*, struct FloatRectRaw, bool printing, bool doubleUnderlines, uint8_t);
void GraphicsContext_beginTransparencyLayer(void*, float);
void GraphicsContext_endTransparencyLayer(void*);
void GraphicsContext_scale(void*, float);
void GraphicsContext_rotate(void* p, float);
void GraphicsContext_translateBySize(void*, struct FloatSizeRaw);
void GraphicsContext_translateByPoint(void*, struct FloatPointRaw);
void GraphicsContext_translateByXy(void*, float, float);
void GraphicsContext_setContentfulPaintDetected(void*);
bool GraphicsContext_contentfulPaintDetected(const void*);
void* FrameSelection_caretRendererWithoutUpdatingLayout(const void*);
const void* FrameSelection_selection(const void*);
void FrameSelection_setNeedsSelectionUpdate(void* p, bool);
bool FrameSelection_isCaret(const void*);
bool FrameSelection_isFocusedAndActive(const void*);
bool FrameSelection_shouldShowBlockCursor(const void*);
bool VisibleSelection_hasEditableStyle(const void*);
void* DragCaretController_caretRenderer(const void*);
bool DragCaretController_isContentEditable(const void*);
void* EventHandler_autoscrollRenderer(const void*);
void Style_loadPendingResources(const void* style, void* document, const void* element);
bool HTMLElement_hasFrameTag(const void*);
bool HTMLFrameSetElement_noResize(const void*);
int32_t HTMLFrameSetElement_totalRows(const void*);
int32_t HTMLFrameSetElement_totalCols(const void*);
int32_t HTMLFrameSetElement_border(const void*);
bool HTMLFrameSetElement_hasBorderColor(const void*);
void HTMLCanvasElement_setIsSnapshotting(void*, bool);
bool HTMLImageElement_isDeferred(const void*);
bool HTMLInputElement_hasAutoFillStrongPasswordButton(const void*);
uint32_t HTMLSelectElement_size(const void*);
int32_t HTMLSelectElement_activeSelectionStartListIndex(const void*);
int32_t HTMLSelectElement_activeSelectionEndListIndex(const void*);
void HTMLSelectElement_setActiveSelectionEndIndex(void*, int32_t);
bool HTMLSelectElement_allowsNonContiguousSelection(const void*);
unsigned HTMLTextAreaElement_cols(const void*);
const void* CharacterData_data(const void*);
uint32_t CharacterData_length(const void*);
bool CharacterData_containsOnlyASCIIWhitespace(const void*);
uint32_t Editor_compositionStart(const void*);
uint32_t Editor_compositionEnd(const void*);
bool Editor_compositionUsesCustomUnderlines(const void*);
bool Editor_compositionUsesCustomHighlights(const void*);
