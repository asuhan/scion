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

#pragma once

#include "LayoutUnit.h"
#include "RenderObject.h"
#include "RenderStyle.h"
#include "ScrollTypes.h"

extern "C" void* RenderViewScion_create(void*, const void*);

namespace WebCore {

class RenderFragmentContainer;
class RenderLayer;
class RenderLayerCompositor;
class RenderLayerModelObject;
class RenderMultiColumnFlow;
class RenderObject;
class RenderSelection;

namespace Layout {
class InitialContainingBlock;
class LayoutState;
}

namespace LayoutIntegration {
class LineLayout;
}

class RenderObjectScion final {
public:
    RenderObjectScion(void* handle)
        : m_handle(handle)
    {
    }

    RenderLayer* enclosingLayer() const;

    void setChildrenInline(bool b);

    bool hasLayer() const;

    bool needsLayout() const;

    void setNormalChildNeedsLayoutBit(bool b);

private:
    void* m_handle;
};

class RenderElementScion final {
public:
    RenderElementScion(void* handle)
        : m_handle(handle)
    {
    }

    void attachRendererInternal(RenderObject* child, RenderObject* beforeChild);

private:
    void* m_handle;
};

class RenderLayerModelObjectScion final {
public:
    RenderLayerModelObjectScion(void* handle)
        : m_handle(handle)
    {
    }

    RenderLayer* layer() const;

    CheckedPtr<RenderLayer> checkedLayer() const;

    void* handle() const { return m_handle; }

private:
    void* m_handle;
};

class RenderBoxModelObjectScion final {
public:
    RenderBoxModelObjectScion(void* handle)
        : m_handle(handle)
    {
    }

private:
    void* m_handle;
};

class RenderBoxScion final {
public:
    RenderBoxScion(void* handle)
        : m_handle(handle)
    {
    }

    bool requiresLayerWithScrollableArea() const;

    LayoutUnit width() const;

    LayoutPoint location() const;

    LayoutSize size() const;

    LayoutRect frameRect() const;

    LayoutRect layoutOverflowRect() const;

    LayoutRect visualOverflowRect() const;

    LayoutRect paddingBoxRectIncludingScrollbar() const;

    RenderObject::RepaintRects localRectsForRepaint(RepaintOutlineBounds) const;

    LayoutUnit availableLogicalWidth() const;

    bool hasAutoScrollbar(ScrollbarOrientation) const;

    bool hasAlwaysPresentScrollbar(ScrollbarOrientation) const;

    bool scrollsOverflow() const;

    bool isUnsplittableForPagination() const;

    LayoutPoint topLeftLocation() const;

    void styleWillChange(StyleDifference, const RenderStyle&);

    void willBeDestroyed();

    bool shouldTrimChildMargin(MarginTrimType, const RenderBox&) const;

    void* handle() const { return m_handle; }

private:
    void* m_handle;
};

class RenderBlockScion final {
public:
    RenderBlockScion(void* handle)
        : m_handle(handle)
    {
    }

    void setMarginBeforeForChild(RenderBox& child, LayoutUnit value) const;

    void setMarginAfterForChild(RenderBox& child, LayoutUnit value) const;

    bool canHaveChildren() const;

    String debugDescription() const;

    bool isInlineBlockOrInlineTable() const;

    const RenderStyle& outlineStyleForRepaint() const;

private:
    void* m_handle;
};

class RenderBlockFlowScion final {
public:
    RenderBlockFlowScion(void* handle)
        : m_handle(handle)
    {
    }

    void willBeDestroyed();

    RenderMultiColumnFlow* multiColumnFlow() const;

    bool containsFloats() const;

    void deleteLines();

    void setChildrenInline(bool);

    const LayoutIntegration::LineLayout* inlineLayout() const;

    LayoutIntegration::LineLayout* inlineLayout();

    void styleWillChange(StyleDifference, const RenderStyle&);

private:
    void* m_handle;
};

class RenderViewScion final {
public:
    RenderViewScion(void* handle)
        : m_handle(handle)
        , m_accumulatedRepaintRegion(nullptr)
    {
    }

    ~RenderViewScion();

    RenderSelection& selection();

    bool printing() const;

    LayoutUnit pageOrViewLogicalHeight() const;

    bool requiresLayer() const;

    bool isChildAllowed(const RenderObject&, const RenderStyle&) const;

    void layout();

    void updateLogicalWidth();

    RenderBox::LogicalExtentComputedValues computeLogicalHeight(LayoutUnit logicalHeight, LayoutUnit logicalTop) const;

    int viewHeight() const;

    int viewWidth() const;

    int viewLogicalWidth() const;

    int viewLogicalHeight() const;

    LocalFrameView& frameView() const;

    Ref<LocalFrameView> protectedFrameView() const;

    Layout::InitialContainingBlock& initialContainingBlock();

    Layout::LayoutState& layoutState();

    bool needsRepaintHackAfterCompositingLayerUpdateForDebugOverlaysOnly() const;

    void updateQuirksMode();

    bool needsEventRegionUpdateForNonCompositedFrame() const;

    std::optional<RenderObject::RepaintRects> computeVisibleRectsInContainer(const RenderObject::RepaintRects&, const RenderLayerModelObject* container, RenderObject::VisibleRectContext) const;

    void repaintRootContents();

    void paint(PaintInfo&, const LayoutPoint&);

    RenderElement* rendererForRootBackground() const;

    const IntRect& printRect() const;

    void setIsInWindow(bool);

    RenderLayerCompositor& compositor();

    bool usesCompositing() const;

    IntRect unscaledDocumentRect() const;

    LayoutRect unextendedBackgroundRect() const;

    LayoutRect backgroundRect() const;

    IntRect documentRect() const;

    bool rootElementShouldPaintBaseBackground() const;

    bool shouldPaintBaseBackground() const;

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

    void mapLocalToContainer(const RenderLayerModelObject* repaintContainer, TransformState&, OptionSet<MapCoordinatesMode>, bool* wasFixed) const;

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
    // TODO(asuhan): remove when containerQueryBoxes is implemented
    bool containerQueryBoxesIsEmpty() const;

    void* m_handle;
    void* m_accumulatedRepaintRegion;
    mutable IntRect m_printRect;
};

}
