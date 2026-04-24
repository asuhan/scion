/*
 * Copyright (C) 2026 Scion authors. All rights reserved.
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

#include "RenderObjectsScion.h"
#include "Document.h"
#include "LayoutInitialContainingBlock.h"
#include "LayoutIntegrationLineLayout.h"
#include "LayoutRect.h"
#include "LayoutRectRaw.h"
#include "RenderFragmentContainer.h"
#include "RenderLayer.h"
#include "RenderSelection.h"
#include "RenderView.h"
#include "ScrollTypes.h"
#include <wtf/Assertions.h>
#include <wtf/CheckedRef.h>
#include <wtf/FastMalloc.h>

extern "C" void* RenderObjectScion_parent(const void*);

extern "C" void* RenderObjectScion_enclosingLayer(const void*);

extern "C" void* RenderObjectScion_enclosingFragmentedFlow(const void*);

extern "C" bool RenderObjectScion_isRenderElement(const void*);

extern "C" bool RenderObjectScion_isRenderBlockFlow(const void*);

extern "C" bool RenderObjectScion_isRenderInline(const void*);

extern "C" bool RenderObjectScion_isRenderLayerModelObject(const void*);

extern "C" bool RenderObjectScion_isRenderEmbeddedObject(const void*);

extern "C" bool RenderObjectScion_isRenderMedia(const void*);

extern "C" bool RenderObjectScion_isRenderIFrame(const void*);

extern "C" bool RenderObjectScion_isRenderImage(const void*);

extern "C" bool RenderObjectScion_isRenderReplica(const void*);

extern "C" bool RenderObjectScion_isRenderVideo(const void*);

extern "C" bool RenderObjectScion_isRenderViewTransitionCapture(const void*);

extern "C" bool RenderObjectScion_isRenderWidget(const void*);

extern "C" bool RenderObjectScion_isRenderHTMLCanvas(const void*);

extern "C" bool RenderObjectScion_isHTMLMarquee(const void*);

extern "C" bool RenderObjectScion_childrenInline(const void*);

extern "C" void RenderObjectScion_setChildrenInline(void*, bool);

extern "C" bool RenderObjectScion_fragmentedFlowState(const void*);

extern "C" bool RenderObjectScion_isRenderSVGModelObject(const void*);

extern "C" bool RenderObjectScion_isRenderSVGRoot(const void*);

extern "C" bool RenderObjectScion_isRenderSVGText(const void*);

extern "C" bool RenderObjectScion_isSVGLayerAwareRenderer(const void*);

extern "C" bool RenderObjectScion_isSVGRenderer(const void*);

extern "C" bool RenderObjectScion_isPositioned(const void*);

extern "C" bool RenderObjectScion_isFixedPositioned(const void*);

extern "C" bool RenderObjectScion_isStickilyPositioned(const void*);

extern "C" bool RenderObjectScion_isRenderBox(const void*);

extern "C" bool RenderObjectScion_isRenderTableRow(const void*);

extern "C" bool RenderObjectScion_isRenderView(const void*);

extern "C" bool RenderObjectScion_isInline(const void*);

extern "C" bool RenderObjectScion_hasReflection(const void*);

extern "C" bool RenderObjectScion_isRenderFragmentedFlow(const void*);

extern "C" bool RenderObjectScion_hasLayer(const void*);

extern "C" bool RenderObjectScion_needsLayout(const void*);

extern "C" bool RenderObjectScion_hasNonVisibleOverflow(const void*);

extern "C" bool RenderObjectScion_hasPotentiallyScrollableOverflow(const void*);

extern "C" bool RenderObjectScion_hasTransformRelatedProperty(const void*);

extern "C" bool RenderObjectScion_isTransformed(const void*);

extern "C" bool RenderObjectScion_capturedInViewTransition(const void*);

extern "C" bool RenderObjectScion_effectiveCapturedInViewTransition(const void*);

extern "C" void* RenderObjectScion_view(const void*);

extern "C" void* RenderObjectScion_document(const void*);

extern "C" void* RenderObjectScion_frame(void*);

extern "C" const void* RenderObjectScion_page(const void*);

extern "C" const void* RenderObjectScion_settings(const void*);

extern "C" const void* RenderObjectScion_style(const void*);

struct RepaintContainerStatusRaw {
    bool fullRepaintIsScheduled;
    void* renderer;
};

extern "C" RepaintContainerStatusRaw RenderObjectScion_containerForRepaint(const void*);

extern "C" void RenderObjectScion_repaintUsingContainer(const void*, void*, LayoutRectRaw, bool);

extern "C" LayoutRectRaw RenderObjectScion_clippedOverflowRectForRepaint(const void*, void*);

extern "C" bool RenderObjectScion_renderTreeBeingDestroyed(const void*);

extern "C" bool RenderObjectScion_isSkippedContent(const void*);

extern "C" uint8_t RenderObjectScion_usedPointerEvents(const void*);

extern "C" void RenderObjectScion_setNormalChildNeedsLayoutBit(void*, bool);

extern "C" bool RenderObjectScion_isSetNeedsLayoutForbidden(const void*);

extern "C" const void* RenderElementScion_style(const void*);

extern "C" void RenderElementScion_setStyle(void*, const void*, uint8_t);

extern "C" void* RenderElementScion_element(const void*);

extern "C" void* RenderElementScion_firstChild(const void*);

extern "C" void* RenderElementScion_lastChild(const void*);

extern "C" bool RenderElementScion_shouldApplyPaintContainment(const void*);

extern "C" void RenderElementScion_didAttachChild(void*, void*);

extern "C" void RenderElementScion_setChildNeedsLayout(void*, bool);

extern "C" bool RenderElementScion_shouldApplyLayoutOrPaintContainment(const void*);

extern "C" bool RenderElementScion_repaintAfterLayoutIfNeeded(void*, void*, bool, bool, RepaintRectsRaw, RepaintRectsRaw);

extern "C" bool RenderElementScion_isTransparent(const void*);

extern "C" float RenderElementScion_opacity(const void*);

extern "C" bool RenderElementScion_hasMask(const void*);

extern "C" bool RenderElementScion_hasClipOrNonVisibleOverflow(const void*);

extern "C" bool RenderElementScion_hasClipPath(const void*);

extern "C" bool RenderElementScion_isViewTransitionRoot(const void*);

extern "C" bool RenderElementScion_requiresRenderingConsolidationForViewTransition(const void*);

extern "C" bool RenderElementScion_hasFilter(const void*);

extern "C" bool RenderElementScion_hasBackdropFilter(const void*);

extern "C" bool RenderElementScion_hasBlendMode(const void*);

extern "C" void RenderElementScion_attachRendererInternal(void*, void*, void*);

extern "C" void* RenderElementScion_detachRendererInternal(void*, void*);

extern "C" bool RenderElementScion_renderBlockHasRareData(const void*);

extern "C" void RenderElementScion_setFirstChild(void*, void*);

extern "C" void RenderElementScion_setLastChild(void*, void*);

extern "C" void* RenderLayerModelObjectNative_layer(const void* p);

extern "C" bool RenderLayerModelObjectScion_shouldPlaceVerticalScrollbarOnLeft(const void* p);

extern "C" void* RenderBoxModelObjectScion_continuation(const void* p);

extern "C" bool RenderBoxScion_requiresLayerWithScrollableArea(const void*);

extern "C" int32_t RenderBoxScion_width(const void*);

extern "C" LayoutPointRaw RenderBoxScion_location(const void*);

struct LayoutSizeRaw {
    int32_t width;
    int32_t height;
};

extern "C" LayoutSizeRaw RenderBoxScion_size(const void*);

extern "C" LayoutRectRaw RenderBoxScion_frameRect(const void*);

extern "C" LayoutRectRaw RenderBoxScion_layoutOverflowRect(const void*);

extern "C" LayoutRectRaw RenderBoxScion_visualOverflowRect(const void*);

extern "C" LayoutRectRaw RenderBoxScion_paddingBoxRectIncludingScrollbar(const void*);

extern "C" RepaintRectsRaw RenderBoxScion_localRectsForRepaint(const void*, bool);

extern "C" int32_t RenderBoxScion_availableLogicalWidth(const void*);

extern "C" bool RenderBoxScion_hasAutoScrollbar(const void*, uint8_t);

extern "C" bool RenderBoxScion_hasAlwaysPresentScrollbar(const void*, uint8_t);

extern "C" bool RenderBoxScion_scrollsOverflow(const void*);

extern "C" bool RenderBoxScion_isUnsplittableForPagination(const void*);

extern "C" LayoutPointRaw RenderBoxScion_topLeftLocation(const void*);

extern "C" void RenderBoxScion_styleWillChange(void*, uint8_t, const void*);

extern "C" void RenderBoxScion_willBeDestroyed(void*);

extern "C" bool RenderBoxScion_shouldTrimChildMargin(const void*, uint8_t, void*);

extern "C" void RenderBlockScion_setMarginBeforeForChild(const void*, void*, int32_t);

extern "C" void RenderBlockScion_setMarginAfterForChild(const void*, void*, int32_t);

extern "C" bool RenderBlockScion_canHaveChildren(const void*);

extern "C" const void* RenderBlockScion_debugDescription(const void*);

extern "C" bool RenderBlockScion_isInlineBlockOrInlineTable(const void*);

extern "C" const void* RenderBlockScion_outlineStyleForRepaint(const void*);

extern "C" void RenderBlockFlowScion_willBeDestroyed(void*);

extern "C" void* RenderBlockFlowScion_multiColumnFlow(const void*);

extern "C" bool RenderBlockFlowScion_containsFloats(const void*);

extern "C" void RenderBlockFlowScion_deleteLines(void*);

extern "C" void RenderBlockFlowScion_setChildrenInline(void*, bool);

extern "C" void* RenderBlockFlowScion_inlineLayout(void*);

extern "C" void RenderBlockFlowScion_styleWillChange(void*, uint8_t, const void*);

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

extern "C" bool RenderViewScion_printing(const void*);

extern "C" int32_t RenderViewScion_pageOrViewLogicalHeight(const void*);

extern "C" void* RenderViewScion_selection(const void*);

extern "C" bool RenderViewScion_requiresLayer(const void*);

extern "C" bool RenderViewScion_isChildAllowed(const void*, void*, const void*);

extern "C" void RenderViewScion_layout(void*);

extern "C" void RenderViewScion_updateLogicalWidth(void*);

extern "C" struct LogicalExtentComputedValuesRaw RenderViewScion_computeLogicalHeight(const void*, int32_t, int32_t);

extern "C" int32_t RenderViewScion_viewHeight(const void*);

extern "C" int32_t RenderViewScion_viewWidth(const void*);

extern "C" int32_t RenderViewScion_viewLogicalWidth(const void*);

extern "C" int32_t RenderViewScion_viewLogicalHeight(const void*);

extern "C" void* RenderViewScion_frameView(const void*);

extern "C" const void* RenderViewScion_initialContainingBlock(const void*);

extern "C" void* RenderViewScion_layoutState(const void*);

extern "C" bool RenderViewScion_needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly(const void*);

extern "C" void RenderViewScion_updateQuirksMode(const void*);

extern "C" bool RenderViewScion_needsEventRegionUpdateForNonCompositedFrame(const void*);

struct OptionalRepaintRectsRaw {
    RepaintRectsRaw rects;
    bool is_valid;
};

struct VisibleRectContextRaw {
    bool hasPositionFixedDescendant;
    bool dirtyRectIsFlipped;
    bool descendantNeedsEnclosingIntRect;
    uint8_t options;
};

extern "C" OptionalRepaintRectsRaw RenderViewScion_computeVisibleRectsInContainer(const void*, RepaintRectsRaw, const void*, VisibleRectContextRaw);

extern "C" void RenderViewScion_repaintRootContents(const void*);

extern "C" void RenderViewScion_paint(void*, void*, LayoutPointRaw);

extern "C" void* RenderViewScion_rendererForRootBackground(const void*);

extern "C" struct IntRectRaw RenderViewScion_printRect(const void*);

extern "C" void RenderViewScion_setIsInWindow(bool, void*);

extern "C" void* RenderViewScion_compositor(const void*);

extern "C" bool RenderViewScion_usesCompositing(const void*);

extern "C" IntRectRaw RenderViewScion_unscaledDocumentRect(const void*);

extern "C" struct LayoutRectRaw RenderViewScion_unextendedBackgroundRect(const void*);

extern "C" struct LayoutRectRaw RenderViewScion_backgroundRect(const void*);

extern "C" IntRectRaw RenderViewScion_documentRect(const void*);

extern "C" bool RenderViewScion_rootElementShouldPaintBaseBackground(const void*);

extern "C" bool RenderViewScion_shouldPaintBaseBackground(const void*);

extern "C" bool RenderViewScion_hasQuotesNeedingUpdate(const void*);

extern "C" bool RenderViewScion_hasRenderersWithOutline(const void*);

extern "C" bool RenderViewScion_hasSoftwareFilters(const void*);

extern "C" uint64_t RenderViewScion_rendererCount(const void*);

extern "C" void RenderViewScion_didCreateRenderer(void*);

extern "C" void RenderViewScion_didDestroyRenderer(void*);

extern "C" void RenderViewScion_updateVisibleViewportRect(const void*, IntRectRaw);

extern "C" void RenderViewScion_resumePausedImageAnimationsIfNeeded(const void*, IntRectRaw);

extern "C" void* RenderViewScion_takeStyleChangeLayerTreeMutationRoot(const void*);

extern "C" void* RenderViewScion_viewTransitionRoot(const void*);

extern "C" void RenderViewScion_styleDidChange(void*, uint8_t, const void*);

extern "C" void RenderViewScion_mapLocalToContainer(const void*, void*, void*, uint8_t, bool*);

extern "C" void* RenderViewScion_pushMappingToContainer(const void*, const void*, void*);

extern "C" bool RenderViewScion_requiresColumns(const void*, int32_t desiredColumnCount);

extern "C" void RenderViewScion_computeColumnCountAndWidth(void*);

extern "C" void RenderViewScion_updateInitialContainingBlockSize(void*);

extern "C" bool RenderViewScion_shouldUsePrintingLayout(const void*);

extern "C" void RenderViewScion_setWk(void*, void*);

extern "C" void* RepaintRegionAccumulator_create(void*);

extern "C" void RepaintRegionAccumulator_destroy(void*);

extern "C" bool RenderViewScion_containerQueryBoxesIsEmpty(const void*);

namespace WebCore {

RenderElement* RenderObjectScion::parent() const { return static_cast<RenderElement*>(RenderObjectScion_parent(m_handle)); }

RenderLayer* RenderObjectScion::enclosingLayer() const { return static_cast<RenderLayer*>(RenderObjectScion_enclosingLayer(m_handle)); }

RenderFragmentedFlow* RenderObjectScion::enclosingFragmentedFlow() const { return static_cast<RenderFragmentedFlow*>(RenderObjectScion_enclosingFragmentedFlow(m_handle)); }

bool RenderObjectScion::isRenderElement() const { return RenderObjectScion_isRenderElement(m_handle); }

bool RenderObjectScion::isRenderBlockFlow() const { return RenderObjectScion_isRenderBlockFlow(m_handle); }

bool RenderObjectScion::isRenderInline() const { return RenderObjectScion_isRenderInline(m_handle); }

bool RenderObjectScion::isRenderLayerModelObject() const { return RenderObjectScion_isRenderLayerModelObject(m_handle); }

bool RenderObjectScion::isRenderEmbeddedObject() const { return RenderObjectScion_isRenderEmbeddedObject(m_handle); }

bool RenderObjectScion::isRenderMedia() const { return RenderObjectScion_isRenderMedia(m_handle); }

bool RenderObjectScion::isRenderIFrame() const { return RenderObjectScion_isRenderIFrame(m_handle); }

bool RenderObjectScion::isRenderImage() const { return RenderObjectScion_isRenderImage(m_handle); }

bool RenderObjectScion::isRenderReplica() const { return RenderObjectScion_isRenderReplica(m_handle); }

bool RenderObjectScion::isRenderVideo() const { return RenderObjectScion_isRenderVideo(m_handle); }

bool RenderObjectScion::isRenderViewTransitionCapture() const { return RenderObjectScion_isRenderViewTransitionCapture(m_handle); }

bool RenderObjectScion::isRenderWidget() const { return RenderObjectScion_isRenderWidget(m_handle); }

bool RenderObjectScion::isRenderHTMLCanvas() const { return RenderObjectScion_isRenderHTMLCanvas(m_handle); }

bool RenderObjectScion::isHTMLMarquee() const { return RenderObjectScion_isHTMLMarquee(m_handle); }

bool RenderObjectScion::childrenInline() const { return RenderObjectScion_childrenInline(m_handle); }

void RenderObjectScion::setChildrenInline(bool b) { RenderObjectScion_setChildrenInline(m_handle, b); }

RenderObject::FragmentedFlowState RenderObjectScion::fragmentedFlowState() const
{
    return RenderObjectScion_fragmentedFlowState(m_handle)
        ? RenderObject::FragmentedFlowState::InsideFlow
        : RenderObject::FragmentedFlowState::NotInsideFlow;
}

bool RenderObjectScion::isRenderSVGModelObject() const { return RenderObjectScion_isRenderSVGModelObject(m_handle); }

bool RenderObjectScion::isRenderSVGRoot() const { return RenderObjectScion_isRenderSVGRoot(m_handle); }

bool RenderObjectScion::isRenderSVGText() const { return RenderObjectScion_isRenderSVGText(m_handle); }

bool RenderObjectScion::isSVGLayerAwareRenderer() const { return RenderObjectScion_isSVGLayerAwareRenderer(m_handle); }

bool RenderObjectScion::isSVGRenderer() const { return RenderObjectScion_isSVGRenderer(m_handle); }

bool RenderObjectScion::isPositioned() const { return RenderObjectScion_isPositioned(m_handle); }

bool RenderObjectScion::isFixedPositioned() const { return RenderObjectScion_isFixedPositioned(m_handle); }

bool RenderObjectScion::isStickilyPositioned() const { return RenderObjectScion_isStickilyPositioned(m_handle); }

bool RenderObjectScion::isRenderBox() const { return RenderObjectScion_isRenderBox(m_handle); }

bool RenderObjectScion::isRenderTableRow() const { return RenderObjectScion_isRenderTableRow(m_handle); }

bool RenderObjectScion::isRenderView() const { return RenderObjectScion_isRenderView(m_handle); }

bool RenderObjectScion::isInline() const { return RenderObjectScion_isInline(m_handle); }

bool RenderObjectScion::hasReflection() const { return RenderObjectScion_hasReflection(m_handle); }

bool RenderObjectScion::isRenderFragmentedFlow() const { return RenderObjectScion_isRenderFragmentedFlow(m_handle); }

bool RenderObjectScion::hasLayer() const { return RenderObjectScion_hasLayer(m_handle); }

bool RenderObjectScion::needsLayout() const { return RenderObjectScion_needsLayout(m_handle); }

bool RenderObjectScion::hasNonVisibleOverflow() const { return RenderObjectScion_hasNonVisibleOverflow(m_handle); }

bool RenderObjectScion::hasPotentiallyScrollableOverflow() const { return RenderObjectScion_hasPotentiallyScrollableOverflow(m_handle); }

bool RenderObjectScion::hasTransformRelatedProperty() const { return RenderObjectScion_hasTransformRelatedProperty(m_handle); }

bool RenderObjectScion::isTransformed() const { return RenderObjectScion_isTransformed(m_handle); }

bool RenderObjectScion::capturedInViewTransition() const { return RenderObjectScion_capturedInViewTransition(m_handle); }

bool RenderObjectScion::effectiveCapturedInViewTransition() const { return RenderObjectScion_effectiveCapturedInViewTransition(m_handle); }

RenderView& RenderObjectScion::view() const { return *static_cast<RenderView*>(RenderObjectScion_view(m_handle)); }

Document& RenderObjectScion::document() const { return *static_cast<Document*>(RenderObjectScion_document(m_handle)); }

Ref<Document> RenderObjectScion::protectedDocument() const { return document(); }

LocalFrame& RenderObjectScion::frame() { return *static_cast<LocalFrame*>(RenderObjectScion_frame(m_handle)); }

Page& RenderObjectScion::page() const { return *const_cast<Page*>(static_cast<const Page*>(RenderObjectScion_page(m_handle))); }

Settings& RenderObjectScion::settings() const { return *const_cast<Settings*>(static_cast<const Settings*>(RenderObjectScion_settings(m_handle))); }

const RenderStyle& RenderObjectScion::style() const { return *static_cast<const RenderStyle*>(RenderObjectScion_style(m_handle)); }

RenderObject::RepaintContainerStatus RenderObjectScion::containerForRepaint() const
{
    const auto r = RenderObjectScion_containerForRepaint(m_handle);
    return { r.fullRepaintIsScheduled, static_cast<const RenderLayerModelObject*>(r.renderer) };
}

namespace {

LayoutRectRaw convertLayoutRect(const LayoutRect& r)
{
    return { r.x().rawValue(), r.y().rawValue(), r.width().rawValue(), r.height().rawValue() };
}

LayoutRect convertLayoutRectRaw(const LayoutRectRaw& r)
{
    return { LayoutUnit::fromRawValue(r.x), LayoutUnit::fromRawValue(r.y), LayoutUnit::fromRawValue(r.width), LayoutUnit::fromRawValue(r.height) };
}

} // namespace

void RenderObjectScion::repaintUsingContainer(SingleThreadWeakPtr<const RenderLayerModelObject>&& repaintContainer, const LayoutRect& r, bool shouldClipToLayer) const
{
    RenderObjectScion_repaintUsingContainer(m_handle, const_cast<RenderLayerModelObject*>(repaintContainer.get()), convertLayoutRect(r), shouldClipToLayer);
}

LayoutRect RenderObjectScion::clippedOverflowRectForRepaint(const RenderLayerModelObject* repaintContainer) const
{
    return convertLayoutRectRaw(
        RenderObjectScion_clippedOverflowRectForRepaint(
            m_handle, const_cast<RenderLayerModelObject*>(repaintContainer)));
}

bool RenderObjectScion::renderTreeBeingDestroyed() const { return RenderObjectScion_renderTreeBeingDestroyed(m_handle); }

bool RenderObjectScion::isSkippedContent() const { return RenderObjectScion_isSkippedContent(m_handle); }

PointerEvents RenderObjectScion::usedPointerEvents() const { return static_cast<PointerEvents>(RenderObjectScion_usedPointerEvents(m_handle)); }

void RenderObjectScion::setNormalChildNeedsLayoutBit(bool b) { RenderObjectScion_setNormalChildNeedsLayoutBit(m_handle, b); }

bool RenderObjectScion::isSetNeedsLayoutForbidden() const { return RenderObjectScion_isSetNeedsLayoutForbidden(m_handle); }

const RenderStyle& RenderElementScion::style() const
{
    return *static_cast<const RenderStyle*>(RenderElementScion_style(m_handle));
}

void RenderElementScion::setStyle(RenderStyle&& style, StyleDifference minimalStyleDifference)
{
    RenderElementScion_setStyle(m_handle, &style, static_cast<uint8_t>(minimalStyleDifference));
}

Element* RenderElementScion::element() const
{
    return static_cast<Element*>(RenderElementScion_element(m_handle));
}

RefPtr<Element> RenderElementScion::protectedElement() const
{
    return element();
}

RenderObject* RenderElementScion::firstChild() const
{
    return static_cast<RenderObject*>(RenderElementScion_firstChild(m_handle));
}

RenderObject* RenderElementScion::lastChild() const
{
    return static_cast<RenderObject*>(RenderElementScion_lastChild(m_handle));
}

bool RenderElementScion::shouldApplyPaintContainment() const
{
    return RenderElementScion_shouldApplyPaintContainment(m_handle);
}

void RenderElementScion::didAttachChild(RenderObject& child)
{
    assert(!child.isScion());
    RenderElementScion_didAttachChild(m_handle, &child);
}

void RenderElementScion::setChildNeedsLayout(MarkingBehavior markParents)
{
    RenderElementScion_setChildNeedsLayout(m_handle, markParents == MarkContainingBlockChain);
}

bool RenderElementScion::shouldApplyLayoutOrPaintContainment() const
{
    return RenderElementScion_shouldApplyLayoutOrPaintContainment(m_handle);
}

namespace {

RepaintRectsRaw convertRepaintRects(const RenderObject::RepaintRects& rects)
{
    return { convertLayoutRect(rects.clippedOverflowRect), { convertLayoutRect(rects.outlineBoundsRect.value_or({})), static_cast<bool>(rects.outlineBoundsRect) } };
}

} // namespace

bool RenderElementScion::repaintAfterLayoutIfNeeded(SingleThreadWeakPtr<const RenderLayerModelObject>&& repaintContainer, RequiresFullRepaint requiresFullRepaint, const RenderObject::RepaintRects& oldRects, const RenderObject::RepaintRects& newRects)
{
    if (repaintContainer->scion()) {
        assert(is<RenderView>(repaintContainer.get()));
        return RenderElementScion_repaintAfterLayoutIfNeeded(
            m_handle,
            repaintContainer->scion(),
            true,
            requiresFullRepaint == RequiresFullRepaint::Yes,
            convertRepaintRects(oldRects),
            convertRepaintRects(newRects));
    }
    const auto repaintsContainerRaw = static_cast<const void*>(repaintContainer.get());
    return RenderElementScion_repaintAfterLayoutIfNeeded(
        m_handle,
        const_cast<void*>(repaintsContainerRaw),
        false,
        requiresFullRepaint == RequiresFullRepaint::Yes,
        convertRepaintRects(oldRects),
        convertRepaintRects(newRects));
}

bool RenderElementScion::isTransparent() const
{
    return RenderElementScion_isTransparent(m_handle);
}

float RenderElementScion::opacity() const
{
    return RenderElementScion_opacity(m_handle);
}

bool RenderElementScion::hasMask() const
{
    return RenderElementScion_hasMask(m_handle);
}

bool RenderElementScion::hasClipOrNonVisibleOverflow() const
{
    return RenderElementScion_hasClipOrNonVisibleOverflow(m_handle);
}

bool RenderElementScion::hasClipPath() const
{
    return RenderElementScion_hasClipPath(m_handle);
}

bool RenderElementScion::isViewTransitionRoot() const
{
    return RenderElementScion_isViewTransitionRoot(m_handle);
}

bool RenderElementScion::requiresRenderingConsolidationForViewTransition() const
{
    return RenderElementScion_requiresRenderingConsolidationForViewTransition(m_handle);
}

bool RenderElementScion::hasFilter() const
{
    return RenderElementScion_hasFilter(m_handle);
}

bool RenderElementScion::hasBackdropFilter() const
{
    return RenderElementScion_hasBackdropFilter(m_handle);
}

bool RenderElementScion::hasBlendMode() const
{
    return RenderElementScion_hasBlendMode(m_handle);
}

void RenderElementScion::attachRendererInternal(RenderObject* child, RenderObject* beforeChild)
{
    RenderElementScion_attachRendererInternal(m_handle, child, beforeChild);
}

RenderPtr<RenderObject> RenderElementScion::detachRendererInternal(RenderObject& renderer)
{
    return RenderPtr<RenderObject>(static_cast<RenderObject*>(RenderElementScion_detachRendererInternal(m_handle, &renderer)));
}

bool RenderElementScion::renderBlockHasRareData() const
{
    return RenderElementScion_renderBlockHasRareData(m_handle);
}

void RenderElementScion::setFirstChild(RenderObject* firstChild)
{
    RenderElementScion_setFirstChild(m_handle, firstChild);
}

void RenderElementScion::setLastChild(RenderObject* lastChild)
{
    RenderElementScion_setLastChild(m_handle, lastChild);
}

RenderLayer* RenderLayerModelObjectScion::layer() const
{
    return static_cast<RenderLayer*>(RenderLayerModelObjectNative_layer(m_handle));
}

CheckedPtr<RenderLayer> RenderLayerModelObjectScion::checkedLayer() const
{
    return layer();
}

bool RenderLayerModelObjectScion::shouldPlaceVerticalScrollbarOnLeft() const
{
    return RenderLayerModelObjectScion_shouldPlaceVerticalScrollbarOnLeft(m_handle);
}

RenderBoxModelObject* RenderBoxModelObjectScion::continuation() const
{
    return static_cast<RenderBoxModelObject*>(RenderBoxModelObjectScion_continuation(m_handle));
}

bool RenderBoxScion::requiresLayerWithScrollableArea() const
{
    return RenderBoxScion_requiresLayerWithScrollableArea(m_handle);
}

LayoutUnit RenderBoxScion::width() const
{
    return LayoutUnit::fromRawValue(RenderBoxScion_width(m_handle));
}

LayoutPoint RenderBoxScion::location() const
{
    const auto point = RenderBoxScion_location(m_handle);
    return { LayoutUnit::fromRawValue(point.x), LayoutUnit::fromRawValue(point.y) };
}

LayoutSize RenderBoxScion::size() const
{
    const auto sizeRaw = RenderBoxScion_size(m_handle);
    return { LayoutUnit::fromRawValue(sizeRaw.width), LayoutUnit::fromRawValue(sizeRaw.height) };
}

namespace {

RenderObject::RepaintRects convertRepaintRectsRaw(const RepaintRectsRaw& rects)
{
    return { convertLayoutRectRaw(rects.clippedOverflowRect), rects.outlineBoundsRect.is_valid ? convertLayoutRectRaw(rects.outlineBoundsRect.rect) : LayoutRect {} };
}

} // namespace

LayoutRect RenderBoxScion::frameRect() const
{
    return convertLayoutRectRaw(RenderBoxScion_frameRect(m_handle));
}

LayoutRect RenderBoxScion::layoutOverflowRect() const
{
    return convertLayoutRectRaw(RenderBoxScion_layoutOverflowRect(m_handle));
}

LayoutRect RenderBoxScion::visualOverflowRect() const
{
    return convertLayoutRectRaw(RenderBoxScion_visualOverflowRect(m_handle));
}

LayoutRect RenderBoxScion::paddingBoxRectIncludingScrollbar() const
{
    return convertLayoutRectRaw(RenderBoxScion_paddingBoxRectIncludingScrollbar(m_handle));
}

RenderObject::RepaintRects RenderBoxScion::localRectsForRepaint(RepaintOutlineBounds repaintOutlineBounds) const
{
    return convertRepaintRectsRaw(RenderBoxScion_localRectsForRepaint(m_handle, repaintOutlineBounds == RepaintOutlineBounds::Yes));
}

LayoutUnit RenderBoxScion::availableLogicalWidth() const
{
    return LayoutUnit::fromRawValue(RenderBoxScion_availableLogicalWidth(m_handle));
}

bool RenderBoxScion::hasAutoScrollbar(ScrollbarOrientation orientation) const
{
    return RenderBoxScion_hasAutoScrollbar(m_handle, static_cast<uint8_t>(orientation));
}

bool RenderBoxScion::hasAlwaysPresentScrollbar(ScrollbarOrientation orientation) const
{
    return RenderBoxScion_hasAlwaysPresentScrollbar(m_handle, static_cast<uint8_t>(orientation));
}

bool RenderBoxScion::scrollsOverflow() const
{
    return RenderBoxScion_scrollsOverflow(m_handle);
}

bool RenderBoxScion::isUnsplittableForPagination() const
{
    return RenderBoxScion_isUnsplittableForPagination(m_handle);
}

LayoutPoint RenderBoxScion::topLeftLocation() const
{
    const auto point = RenderBoxScion_topLeftLocation(m_handle);
    return { LayoutUnit::fromRawValue(point.x), LayoutUnit::fromRawValue(point.y) };
}

void RenderBoxScion::styleWillChange(StyleDifference diff, const RenderStyle& newStyle)
{
    RenderBoxScion_styleWillChange(m_handle, static_cast<uint8_t>(diff), &newStyle);
}

void RenderBoxScion::willBeDestroyed()
{
    RenderBoxScion_willBeDestroyed(m_handle);
}

bool RenderBoxScion::shouldTrimChildMargin(MarginTrimType marginTrimType, const RenderBox& child) const
{
    return RenderBoxScion_shouldTrimChildMargin(m_handle, static_cast<uint8_t>(marginTrimType), const_cast<void*>(static_cast<const void*>(&child)));
}

void RenderBlockScion::setMarginBeforeForChild(RenderBox& child, LayoutUnit value) const
{
    RenderBlockScion_setMarginBeforeForChild(m_handle, &child, value.rawValue());
}

void RenderBlockScion::setMarginAfterForChild(RenderBox& child, LayoutUnit value) const
{
    RenderBlockScion_setMarginAfterForChild(m_handle, &child, value.rawValue());
}

bool RenderBlockScion::canHaveChildren() const
{
    return RenderBlockScion_canHaveChildren(m_handle);
}

String RenderBlockScion::debugDescription() const
{
    const auto original = static_cast<const String*>(RenderBlockScion_debugDescription(m_handle));
    const auto copy = *original;
    delete original;
    return copy;
}

bool RenderBlockScion::isInlineBlockOrInlineTable() const
{
    return RenderBlockScion_isInlineBlockOrInlineTable(m_handle);
}

const RenderStyle& RenderBlockScion::outlineStyleForRepaint() const
{
    return *static_cast<const RenderStyle*>(RenderBlockScion_outlineStyleForRepaint(m_handle));
}

void RenderBlockFlowScion::willBeDestroyed()
{
    RenderBlockFlowScion_willBeDestroyed(m_handle);
}

RenderMultiColumnFlow* RenderBlockFlowScion::multiColumnFlow() const
{
    return static_cast<RenderMultiColumnFlow*>(RenderBlockFlowScion_multiColumnFlow(m_handle));
}

bool RenderBlockFlowScion::containsFloats() const
{
    return RenderBlockFlowScion_containsFloats(m_handle);
}

void RenderBlockFlowScion::deleteLines()
{
    RenderBlockFlowScion_deleteLines(m_handle);
}

void RenderBlockFlowScion::setChildrenInline(bool value)
{
    RenderBlockFlowScion_setChildrenInline(m_handle, value);
}

const LayoutIntegration::LineLayout* RenderBlockFlowScion::inlineLayout() const
{
    return static_cast<const LayoutIntegration::LineLayout*>(RenderBlockFlowScion_inlineLayout(m_handle));
}

LayoutIntegration::LineLayout* RenderBlockFlowScion::inlineLayout()
{
    return static_cast<LayoutIntegration::LineLayout*>(RenderBlockFlowScion_inlineLayout(m_handle));
}

void RenderBlockFlowScion::styleWillChange(StyleDifference diff, const RenderStyle& newStyle)
{
    RenderBlockFlowScion_styleWillChange(m_handle, static_cast<uint8_t>(diff), &newStyle);
}

RenderViewScion::~RenderViewScion()
{
    // TODO(asuhan): implement this
}

RenderSelection& RenderViewScion::selection()
{
    return *static_cast<RenderSelection*>(RenderViewScion_selection(m_handle));
}

bool RenderViewScion::printing() const
{
    return RenderViewScion_printing(m_handle);
}

LayoutUnit RenderViewScion::pageOrViewLogicalHeight() const
{
    return LayoutUnit::fromRawValue(RenderViewScion_pageOrViewLogicalHeight(m_handle));
}

bool RenderViewScion::requiresLayer() const
{
    return RenderViewScion_requiresLayer(m_handle);
}

bool RenderViewScion::isChildAllowed(const RenderObject& child, const RenderStyle& style) const
{
    return RenderViewScion_isChildAllowed(m_handle, const_cast<void*>(static_cast<const void*>(&child)), &style);
}

void RenderViewScion::layout()
{
    RenderViewScion_layout(m_handle);
}

void RenderViewScion::updateLogicalWidth()
{
    RenderViewScion_updateLogicalWidth(m_handle);
}

RenderBox::LogicalExtentComputedValues RenderViewScion::computeLogicalHeight(LayoutUnit logicalHeight, LayoutUnit logicalTop) const
{
    const auto e = RenderViewScion_computeLogicalHeight(m_handle, logicalHeight.rawValue(), logicalTop.rawValue());
    return {
        LayoutUnit::fromRawValue(e.extent),
        LayoutUnit::fromRawValue(e.position),
        { LayoutUnit::fromRawValue(e.margins.before), LayoutUnit::fromRawValue(e.margins.after), LayoutUnit::fromRawValue(e.margins.start), LayoutUnit::fromRawValue(e.margins.end) }
    };
}

int RenderViewScion::viewHeight() const
{
    return RenderViewScion_viewHeight(m_handle);
}

int RenderViewScion::viewWidth() const
{
    return RenderViewScion_viewWidth(m_handle);
}

int RenderViewScion::viewLogicalWidth() const
{
    return RenderViewScion_viewLogicalWidth(m_handle);
}

int RenderViewScion::viewLogicalHeight() const
{
    return RenderViewScion_viewLogicalHeight(m_handle);
}

LocalFrameView& RenderViewScion::frameView() const
{
    return *static_cast<LocalFrameView*>(RenderViewScion_frameView(m_handle));
}

Ref<LocalFrameView> RenderViewScion::protectedFrameView() const
{
    return frameView();
}

Layout::InitialContainingBlock& RenderViewScion::initialContainingBlock()
{
    return *const_cast<Layout::InitialContainingBlock*>(static_cast<const Layout::InitialContainingBlock*>(RenderViewScion_initialContainingBlock(m_handle)));
}

Layout::LayoutState& RenderViewScion::layoutState()
{
    return *static_cast<Layout::LayoutState*>(RenderViewScion_layoutState(m_handle));
}

bool RenderViewScion::needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly() const
{
    return RenderViewScion_needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly(m_handle);
}

void RenderViewScion::updateQuirksMode()
{
    RenderViewScion_updateQuirksMode(m_handle);
}

bool RenderViewScion::needsEventRegionUpdateForNonCompositedFrame() const
{
    return RenderViewScion_needsEventRegionUpdateForNonCompositedFrame(m_handle);
}

namespace {

VisibleRectContextRaw convertVisibleRectContext(WebCore::RenderObject::VisibleRectContext context)
{
    return { context.hasPositionFixedDescendant, context.dirtyRectIsFlipped, context.descendantNeedsEnclosingIntRect, static_cast<uint8_t>(context.options.toRaw()) };
}

} // namespace

std::optional<WebCore::RenderObject::RepaintRects> RenderViewScion::computeVisibleRectsInContainer(const WebCore::RenderObject::RepaintRects& rects, const RenderLayerModelObject* container, WebCore::RenderObject::VisibleRectContext context) const
{
    if (!container || !container->scion()) {
        ASSERT_NOT_REACHED();
    }
    const auto rectsRaw = convertRepaintRects(rects);
    const auto contextRaw = convertVisibleRectContext(context);
    const auto raw = RenderViewScion_computeVisibleRectsInContainer(m_handle, rectsRaw, container->scion(), contextRaw);
    if (!raw.is_valid) {
        return {};
    }
    return convertRepaintRectsRaw(raw.rects);
}

void RenderViewScion::repaintRootContents()
{
    RenderViewScion_repaintRootContents(m_handle);
}

namespace {

LayoutPointRaw convertLayoutPoint(const LayoutPoint& point) { return { point.x().rawValue(), point.y().rawValue() }; }

} // namespace

void RenderViewScion::paint(PaintInfo& paintInfo, const LayoutPoint& paintOffset)
{
    RenderViewScion_paint(m_handle, &paintInfo, convertLayoutPoint(paintOffset));
}

RenderElement* RenderViewScion::rendererForRootBackground() const
{
    return static_cast<RenderElement*>(RenderViewScion_rendererForRootBackground(m_handle));
}

const IntRect& RenderViewScion::printRect() const
{
    const auto r = RenderViewScion_printRect(m_handle);
    m_printRect = { { r.location.x, r.location.y }, { r.size.width, r.size.height } };
    return m_printRect;
}

void RenderViewScion::setIsInWindow(bool isInWindow)
{
    RenderViewScion_setIsInWindow(isInWindow, m_handle);
}

RenderLayerCompositor& RenderViewScion::compositor()
{
    return *static_cast<RenderLayerCompositor*>(RenderViewScion_compositor(m_handle));
}

bool RenderViewScion::usesCompositing() const
{
    return RenderViewScion_usesCompositing(m_handle);
}

IntRect RenderViewScion::unscaledDocumentRect() const
{
    const auto raw = RenderViewScion_unscaledDocumentRect(m_handle);
    return IntRect({ raw.location.x, raw.location.y }, { raw.size.width, raw.size.height });
}

LayoutRect RenderViewScion::unextendedBackgroundRect() const
{
    return convertLayoutRectRaw(RenderViewScion_unextendedBackgroundRect(m_handle));
}

LayoutRect RenderViewScion::backgroundRect() const
{
    return convertLayoutRectRaw(RenderViewScion_backgroundRect(m_handle));
}

IntRect RenderViewScion::documentRect() const
{
    const auto raw = RenderViewScion_documentRect(m_handle);
    return IntRect({ raw.location.x, raw.location.y }, { raw.size.width, raw.size.height });
}

bool RenderViewScion::rootElementShouldPaintBaseBackground() const
{
    return RenderViewScion_rootElementShouldPaintBaseBackground(m_handle);
}

bool RenderViewScion::shouldPaintBaseBackground() const
{
    return RenderViewScion_shouldPaintBaseBackground(m_handle);
}

bool RenderViewScion::hasQuotesNeedingUpdate() const
{
    return RenderViewScion_hasQuotesNeedingUpdate(m_handle);
}

bool RenderViewScion::hasRenderersWithOutline() const
{
    return RenderViewScion_hasRenderersWithOutline(m_handle);
}

uint64_t RenderViewScion::rendererCount() const
{
    return RenderViewScion_rendererCount(m_handle);
}

bool RenderViewScion::hasSoftwareFilters() const
{
    return RenderViewScion_hasSoftwareFilters(m_handle);
}

void RenderViewScion::didCreateRenderer()
{
    RenderViewScion_didCreateRenderer(m_handle);
}

void RenderViewScion::didDestroyRenderer()
{
    RenderViewScion_didDestroyRenderer(m_handle);
}

namespace {

IntRectRaw convertIntRect(const IntRect& r)
{
    return { r.location().x(), r.location().y(), r.size().width(), r.size().height() };
}

} // namespace

void RenderViewScion::updateVisibleViewportRect(const IntRect& visibleRect)
{
    RenderViewScion_updateVisibleViewportRect(m_handle, convertIntRect(visibleRect));
}

void RenderViewScion::resumePausedImageAnimationsIfNeeded(const IntRect& visibleRect)
{
    RenderViewScion_resumePausedImageAnimationsIfNeeded(m_handle, convertIntRect(visibleRect));
}

RenderLayer* RenderViewScion::takeStyleChangeLayerTreeMutationRoot()
{
    return static_cast<RenderLayer*>(RenderViewScion_takeStyleChangeLayerTreeMutationRoot(m_handle));
}

const SingleThreadWeakHashSet<const RenderBox>& RenderViewScion::containerQueryBoxes() const
{
    static SingleThreadWeakHashSet<const RenderBox> unused;
    if (containerQueryBoxesIsEmpty()) {
        return unused;
    }
    ASSERT_NOT_REACHED();
    return unused;
}

SingleThreadWeakPtr<RenderElement> RenderViewScion::viewTransitionRoot() const
{
    return static_cast<RenderElement*>(RenderViewScion_viewTransitionRoot(m_handle));
}

void RenderViewScion::styleDidChange(StyleDifference diff, const RenderStyle* oldStyle)
{
    RenderViewScion_styleDidChange(m_handle, static_cast<uint8_t>(diff), oldStyle);
}

void RenderViewScion::mapLocalToContainer(const RenderLayerModelObject* ancestorContainer, TransformState& transformState, OptionSet<MapCoordinatesMode> mode, bool* wasFixed) const
{
    RenderViewScion_mapLocalToContainer(m_handle, const_cast<RenderLayerModelObject*>(ancestorContainer), &transformState, mode.toRaw(), wasFixed);
}

const RenderObject* RenderViewScion::pushMappingToContainer(const RenderLayerModelObject* ancestorToStopAt, RenderGeometryMap& geometryMap) const
{
    return static_cast<const RenderObject*>(RenderViewScion_pushMappingToContainer(m_handle, ancestorToStopAt ? ancestorToStopAt->scion() : nullptr, &geometryMap));
}

bool RenderViewScion::requiresColumns(int desiredColumnCount) const
{
    return RenderViewScion_requiresColumns(m_handle, desiredColumnCount);
}

void RenderViewScion::computeColumnCountAndWidth()
{
    RenderViewScion_computeColumnCountAndWidth(m_handle);
}

void RenderViewScion::updateInitialContainingBlockSize()
{
    RenderViewScion_updateInitialContainingBlockSize(m_handle);
}

bool RenderViewScion::shouldUsePrintingLayout() const
{
    return RenderViewScion_shouldUsePrintingLayout(m_handle);
}

void RenderViewScion::setWk(void* wk)
{
    RenderViewScion_setWk(wk, m_handle);
}

void* RenderViewScion::createRepaintRegionAccumulator() const
{
    return RepaintRegionAccumulator_create(m_handle);
}

void RenderViewScion::destroyRepaintRegionAccumulator(void* accumulatedRepaintRegion)
{
    RepaintRegionAccumulator_destroy(accumulatedRepaintRegion);
}

bool RenderViewScion::containerQueryBoxesIsEmpty() const
{
    return RenderViewScion_containerQueryBoxesIsEmpty(m_handle);
}

}