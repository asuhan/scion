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

extern "C" bool RenderViewScion_requiresLayer(void*);

extern "C" void* RenderViewScion_frameView(void*);

extern "C" bool RenderViewScion_needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly(const void*);

extern "C" void RenderViewScion_updateQuirksMode(const void*);

extern "C" void RenderViewScion_setIsInWindow(bool, void*);

extern "C" void* RenderViewScion_compositor(void*);

extern "C" bool RenderViewScion_usesCompositing(void*);

extern "C" IntRectRaw RenderViewScion_unscaledDocumentRect(const void*);

extern "C" IntRectRaw RenderViewScion_documentRect(const void*);

extern "C" bool RenderViewScion_hasSoftwareFilters(const void*);

extern "C" void RenderViewScion_updateVisibleViewportRect(const void*, IntRectRaw);

extern "C" void RenderViewScion_styleDidChange(void*, uint8_t, const void*);

extern "C" void* RenderViewScion_pushMappingToContainer(void*, void*, void*);

extern "C" void RenderViewScion_setWk(void*, void*);

extern "C" void* RepaintRegionAccumulator_create(void*);

extern "C" void RepaintRegionAccumulator_destroy(void*);

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
    static RenderSelection* unused = nullptr;
    ASSERT_NOT_REACHED();
    return *unused;
}

bool RenderViewScion::requiresLayer() const
{
    return RenderViewScion_requiresLayer(m_handle);
}

LocalFrameView& RenderViewScion::frameView() const
{
    return *static_cast<LocalFrameView*>(RenderViewScion_frameView(m_handle));
}

bool RenderViewScion::needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly() const
{
    return RenderViewScion_needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly(m_handle);
}

void RenderViewScion::updateQuirksMode()
{
    RenderViewScion_updateQuirksMode(m_handle);
}

void RenderViewScion::repaintRootContents()
{
    ASSERT_NOT_REACHED();
}

void RenderViewScion::repaintViewAndCompositedLayers()
{
    ASSERT_NOT_REACHED();
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

IntRect RenderViewScion::documentRect() const
{
    const auto raw = RenderViewScion_documentRect(m_handle);
    return IntRect({ raw.location.x, raw.location.y }, { raw.size.width, raw.size.height });
}

FloatSize RenderViewScion::sizeForCSSLargeViewportUnits() const
{
    ASSERT_NOT_REACHED();
    return {};
}

uint64_t RenderViewScion::rendererCount() const
{
    ASSERT_NOT_REACHED();
    return 0;
}

bool RenderViewScion::hasSoftwareFilters() const
{
    return RenderViewScion_hasSoftwareFilters(m_handle);
}

void RenderViewScion::didCreateRenderer()
{
    ASSERT_NOT_REACHED();
}

void RenderViewScion::updateVisibleViewportRect(const IntRect& visibleRect)
{
    RenderViewScion_updateVisibleViewportRect(m_handle, { visibleRect.location().x(), visibleRect.location().y(), visibleRect.size().width(), visibleRect.size().height( ) });
}

const SingleThreadWeakHashSet<const RenderBox>& RenderViewScion::containerQueryBoxes() const
{
    static SingleThreadWeakHashSet<const RenderBox> unused;
    ASSERT_NOT_REACHED();
    return unused;
}

void RenderViewScion::styleDidChange(StyleDifference diff, const RenderStyle* oldStyle)
{
    RenderViewScion_styleDidChange(m_handle, static_cast<uint8_t>(diff), oldStyle);
}

const RenderObject* RenderViewScion::pushMappingToContainer(const RenderLayerModelObject* ancestorToStopAt, RenderGeometryMap& geometryMap) const
{
    return static_cast<const RenderObject*>(RenderViewScion_pushMappingToContainer(m_handle, ancestorToStopAt ? ancestorToStopAt->scion() : nullptr, &geometryMap));
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

}
