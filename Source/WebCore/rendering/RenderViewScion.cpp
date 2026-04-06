/*
 * Copyright (C) 2025 Scion authors. All rights reserved.
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

#include "RenderViewScion.h"
#include "Document.h"
#include "RenderFragmentContainer.h"
#include "RenderLayer.h"
#include "RenderSelection.h"
#include "RenderViewScion.h"
#include <wtf/Assertions.h>

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

extern "C" bool RenderViewScion_needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly(const void*);

extern "C" void RenderViewScion_updateQuirksMode(const void*);

extern "C" bool RenderViewScion_needsEventRegionUpdateForNonCompositedFrame(const void*);

extern "C" void RenderViewScion_repaintRootContents(const void*);

extern "C" void* RenderViewScion_rendererForRootBackground(const void*);

extern "C" struct IntRectRaw RenderViewScion_printRect(const void*);

extern "C" void RenderViewScion_setIsInWindow(bool, void*);

extern "C" void* RenderViewScion_compositor(const void*);

extern "C" bool RenderViewScion_usesCompositing(const void*);

extern "C" IntRectRaw RenderViewScion_unscaledDocumentRect(const void*);

struct LayoutRectRaw {
    int32_t x;
    int32_t y;
    int32_t width;
    int32_t height;
};

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

RenderViewScion::~RenderViewScion()
{
    // TODO(asuhan): implement this
}

const RenderStyle& RenderViewScion::style() const
{
    ASSERT_NOT_REACHED();
    return RenderStyle::defaultStyle();
}

RenderStyle& RenderViewScion::mutableStyle()
{
    ASSERT_NOT_REACHED();
    return RenderStyle::defaultStyle();
}

const RenderStyle* RenderViewScion::parentStyle() const
{
    ASSERT_NOT_REACHED();
    return nullptr;
}

void RenderViewScion::setStyle(RenderStyle&&, StyleDifference)
{
    ASSERT_NOT_REACHED();
}

RenderObject* RenderViewScion::firstChild()
{
    ASSERT_NOT_REACHED();
    return nullptr;
}

bool RenderViewScion::needsLayout() const
{
    ASSERT_NOT_REACHED();
    return false;
}

Document& RenderViewScion::document() const
{
    static Document* unused = nullptr;
    ASSERT_NOT_REACHED();
    return *unused;
}

LocalFrame& RenderViewScion::frame() const
{
    static LocalFrame* unused = nullptr;
    ASSERT_NOT_REACHED();
    return *unused;
}

VisiblePosition RenderViewScion::positionForPoint(const LayoutPoint&, HitTestSource, const RenderFragmentContainer*)
{
    ASSERT_NOT_REACHED();
    return {};
}

void RenderViewScion::repaint(RenderObject::ForceRepaint) const
{
    ASSERT_NOT_REACHED();
}

RenderMultiColumnFlow* RenderViewScion::multiColumnFlow() const
{
    ASSERT_NOT_REACHED();
    return nullptr;
}

void RenderViewScion::updateColumnProgressionFromStyle(const RenderStyle&)
{
    ASSERT_NOT_REACHED();
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

void RenderViewScion::repaintRootContents()
{
    RenderViewScion_repaintRootContents(m_handle);
}

void RenderViewScion::repaintViewAndCompositedLayers()
{
    ASSERT_NOT_REACHED();
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

namespace {

LayoutRect convertLayoutRectRaw(const LayoutRectRaw& r)
{
    return { LayoutUnit::fromRawValue(r.x), LayoutUnit::fromRawValue(r.y), LayoutUnit::fromRawValue(r.width), LayoutUnit::fromRawValue(r.height) };
}

} // namespace

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

FloatSize RenderViewScion::sizeForCSSLargeViewportUnits() const
{
    ASSERT_NOT_REACHED();
    return {};
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

bool RenderViewScion::containerQueryBoxesIsEmpty() const {
    return RenderViewScion_containerQueryBoxesIsEmpty(m_handle);
}

}
