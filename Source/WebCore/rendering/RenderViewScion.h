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

#pragma once

#include <wtf/CheckedRef.h>
#include <wtf/FastMalloc.h>

#include "FloatSize.h"
#include "LayoutPoint.h"
#include "LocalFrameView.h"
#include "RenderStyle.h"
#include "VisiblePosition.h"

extern "C" void* RenderViewScion_create(void*, const void*);

namespace WebCore {

class RenderLayer;
class RenderLayerCompositor;
class RenderFragmentContainer;

DECLARE_ALLOCATOR_WITH_HEAP_IDENTIFIER(WebCore_RenderViewScion);

class RenderViewScion final : public CanMakeCheckedPtr<RenderViewScion> {
    WTF_MAKE_FAST_ALLOCATED_WITH_HEAP_IDENTIFIER(WebCore_RenderViewScion);
    WTF_OVERRIDE_DELETE_FOR_CHECKED_PTR(RenderViewScion);

public:
    RenderViewScion(void* handle)
        : m_handle(handle)
        , m_accumulatedRepaintRegion(nullptr)
    {
    }

    ~RenderViewScion();

    const RenderStyle& style() const;

    RenderStyle& mutableStyle();

    const RenderStyle* parentStyle() const;

    void setStyle(RenderStyle&&, StyleDifference minimalStyleDifference = StyleDifference::Equal);

    RenderObject* firstChild();

    bool needsLayout() const;

    Document& document() const;

    LocalFrame& frame() const;

    VisiblePosition positionForPoint(const LayoutPoint&, HitTestSource, const RenderFragmentContainer*);

    void repaint(RenderObject::ForceRepaint = RenderObject::ForceRepaint::No) const;

    RenderMultiColumnFlow* multiColumnFlow() const;

    void updateColumnProgressionFromStyle(const RenderStyle&);

    RenderSelection& selection();

    bool printing() const;

    LayoutUnit pageOrViewLogicalHeight() const;

    bool requiresLayer() const;

    bool isChildAllowed(const RenderObject&, const RenderStyle&) const;

    void layout();

    void updateLogicalWidth();

    int viewHeight() const;

    int viewWidth() const;

    int viewLogicalWidth() const;

    int viewLogicalHeight() const;

    LocalFrameView& frameView() const;

    Ref<LocalFrameView> protectedFrameView() const;

    bool needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly() const;

    void updateQuirksMode();

    bool needsEventRegionUpdateForNonCompositedFrame() const;

    void repaintRootContents();

    void repaintViewAndCompositedLayers();

    RenderElement* rendererForRootBackground() const;

    void setIsInWindow(bool);

    RenderLayerCompositor& compositor();

    bool usesCompositing() const;

    IntRect unscaledDocumentRect() const;

    IntRect documentRect() const;

    bool rootElementShouldPaintBaseBackground() const;

    bool shouldPaintBaseBackground() const;

    FloatSize sizeForCSSLargeViewportUnits() const;

    bool hasQuotesNeedingUpdate() const;

    bool hasRenderersWithOutline() const;

    uint64_t rendererCount() const;

    bool hasSoftwareFilters() const;

    void didCreateRenderer();

    void didDestroyRenderer();

    void updateVisibleViewportRect(const IntRect&);

    void resumePausedImageAnimationsIfNeeded(const IntRect&);

    RenderLayer* takeStyleChangeLayerTreeMutationRoot();

    const SingleThreadWeakHashSet<const RenderBox>& containerQueryBoxes() const;

    SingleThreadWeakPtr<RenderElement> viewTransitionRoot() const;

    void styleDidChange(StyleDifference, const RenderStyle*);

    const RenderObject* pushMappingToContainer(const RenderLayerModelObject* ancestorToStopAt, RenderGeometryMap&) const;

    bool requiresColumns(int desiredColumnCount) const;

    void computeColumnCountAndWidth();

    void updateInitialContainingBlockSize();

    bool shouldUsePrintingLayout() const;

    void setWk(void*);

    void* createRepaintRegionAccumulator() const;

    static void destroyRepaintRegionAccumulator(void*);

    void* handle() const { return m_handle; }

private:
    void* m_handle;
    void* m_accumulatedRepaintRegion;
};

}