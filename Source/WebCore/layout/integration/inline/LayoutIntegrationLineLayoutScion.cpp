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

#include "LayoutIntegrationLineLayoutScion.h"
#include <wtf/Assertions.h>

extern "C" uint64_t LineLayoutScion_create();

struct OptionalLayoutRectRaw {
    struct LayoutRectRaw rect;
    bool is_valid;
};

extern "C" OptionalLayoutRectRaw LineLayoutScion_layout(uint64_t handle);

namespace WebCore {
namespace LayoutIntegration {

LineLayoutScion::LineLayoutScion(RenderBlockFlow& flow)
    : m_flow(&flow)
    , m_handle(LineLayoutScion_create())
{
}

LineLayoutScion::~LineLayoutScion()
{
    ASSERT_NOT_REACHED();
}

static inline bool isContentRendererScion(const RenderObject& renderer)
{
    // FIXME: These fake renderers have their parent set but are not actually in the tree.
    return !renderer.isRenderReplica() && !renderer.isRenderScrollbarPart();
}

RenderBlockFlow* LineLayoutScion::blockContainer(const RenderObject& renderer)
{
    if (!isContentRendererScion(renderer))
        return nullptr;

    for (auto* parent = renderer.parent(); parent; parent = parent->parent()) {
        if (!parent->childrenInline())
            return nullptr;
        if (auto* renderBlockFlow = dynamicDowncast<RenderBlockFlow>(*parent))
            return renderBlockFlow;
    }

    return nullptr;
}

LineLayoutScion* LineLayoutScion::containing(RenderObject&)
{
    ASSERT_NOT_REACHED();
    return {};
}

const LineLayoutScion* LineLayoutScion::containing(const RenderObject&)
{
    ASSERT_NOT_REACHED();
    return {};
}

bool LineLayoutScion::canUseFor(const RenderBlockFlow& flow)
{
    return canUseForLineLayout(flow);
}

bool LineLayoutScion::canUseForPreferredWidthComputation(const RenderBlockFlow&)
{
    ASSERT_NOT_REACHED();
    return {};
}

bool LineLayoutScion::shouldInvalidateLineLayoutPathAfterContentChange(const RenderBlockFlow&, const RenderObject&, const LineLayoutScion&)
{
    ASSERT_NOT_REACHED();
    return {};
}

bool LineLayoutScion::shouldInvalidateLineLayoutPathAfterTreeMutation(const RenderBlockFlow&, const RenderObject&, const LineLayoutScion&, bool)
{
    ASSERT_NOT_REACHED();
    return {};
}

void LineLayoutScion::updateFormattingContexGeometries(LayoutUnit)
{
    ASSERT_NOT_REACHED();
}

void LineLayoutScion::updateOverflow()
{
    ASSERT_NOT_REACHED();
}

void LineLayoutScion::updateStyle(const RenderObject&)
{
    ASSERT_NOT_REACHED();
}

bool LineLayoutScion::insertedIntoTree(const RenderElement&, RenderObject&)
{
    ASSERT_NOT_REACHED();
    return {};
}

bool LineLayoutScion::removedFromTree(const RenderElement&, RenderObject&)
{
    ASSERT_NOT_REACHED();
    return {};
}

bool LineLayoutScion::updateTextContent(const RenderText&, size_t, int)
{
    ASSERT_NOT_REACHED();
    return {};
}

bool LineLayoutScion::rootStyleWillChange(const RenderBlockFlow&, const RenderStyle&)
{
    ASSERT_NOT_REACHED();
    return {};
}

bool LineLayoutScion::styleWillChange(const RenderElement&, const RenderStyle&, StyleDifference)
{
    ASSERT_NOT_REACHED();
    return {};
}

bool LineLayoutScion::boxContentWillChange(const RenderBox&)
{
    ASSERT_NOT_REACHED();
    return {};
}

std::pair<LayoutUnit, LayoutUnit> LineLayoutScion::computeIntrinsicWidthConstraints()
{
    ASSERT_NOT_REACHED();
    return {};
}

std::optional<LayoutRect> LineLayoutScion::layout()
{
    const auto raw = LineLayoutScion_layout(m_handle);
    if (!raw.is_valid) {
        return std::nullopt;
    }
    return LayoutRect(
        LayoutUnit::fromRawValue(raw.rect.x),
        LayoutUnit::fromRawValue(raw.rect.y),
        LayoutUnit::fromRawValue(raw.rect.width),
        LayoutUnit::fromRawValue(raw.rect.height));
}

void LineLayoutScion::paint(PaintInfo&, const LayoutPoint&, const RenderInline*)
{
    ASSERT_NOT_REACHED();
}

bool LineLayoutScion::hitTest(const HitTestRequest&, HitTestResult&, const HitTestLocation&, const LayoutPoint&, HitTestAction, const RenderInline*)
{
    ASSERT_NOT_REACHED();
    return {};
}

void LineLayoutScion::adjustForPagination()
{
    ASSERT_NOT_REACHED();
}

void LineLayoutScion::shiftLinesBy(LayoutUnit)
{
    ASSERT_NOT_REACHED();
}

void LineLayoutScion::collectOverflow()
{
    ASSERT_NOT_REACHED();
}

LayoutRect LineLayoutScion::visualOverflowBoundingBoxRectFor(const RenderInline&) const
{
    ASSERT_NOT_REACHED();
    return {};
}

Vector<FloatRect> LineLayoutScion::collectInlineBoxRects(const RenderInline&) const
{
    ASSERT_NOT_REACHED();
    return {};
}

std::optional<LayoutUnit> LineLayoutScion::clampedContentLogicalHeight() const
{
    ASSERT_NOT_REACHED();
    return {};
}

bool LineLayoutScion::contains(const RenderElement&) const
{
    ASSERT_NOT_REACHED();
    return {};
}

bool LineLayoutScion::isPaginated() const
{
    ASSERT_NOT_REACHED();
    return {};
}

LayoutUnit LineLayoutScion::contentBoxLogicalHeight() const
{
    ASSERT_NOT_REACHED();
    return {};
}

size_t LineLayoutScion::lineCount() const
{
    ASSERT_NOT_REACHED();
    return {};
}

bool LineLayoutScion::hasVisualOverflow() const
{
    ASSERT_NOT_REACHED();
    return {};
}

LayoutUnit LineLayoutScion::firstLinePhysicalBaseline() const
{
    ASSERT_NOT_REACHED();
    return {};
}

LayoutUnit LineLayoutScion::lastLinePhysicalBaseline() const
{
    ASSERT_NOT_REACHED();
    return {};
}

LayoutUnit LineLayoutScion::lastLineLogicalBaseline() const
{
    ASSERT_NOT_REACHED();
    return {};
}

LayoutRect LineLayoutScion::firstInlineBoxRect(const RenderInline&) const
{
    ASSERT_NOT_REACHED();
    return {};
}

LayoutRect LineLayoutScion::enclosingBorderBoxRectFor(const RenderInline&) const
{
    ASSERT_NOT_REACHED();
    return {};
}

InlineIterator::TextBoxIterator LineLayoutScion::textBoxesFor(const RenderText&) const
{
    ASSERT_NOT_REACHED();
    return {};
}

InlineIterator::LeafBoxIterator LineLayoutScion::boxFor(const RenderElement&) const
{
    ASSERT_NOT_REACHED();
    return {};
}

InlineIterator::InlineBoxIterator LineLayoutScion::firstInlineBoxFor(const RenderInline&) const
{
    ASSERT_NOT_REACHED();
    return {};
}

InlineIterator::InlineBoxIterator LineLayoutScion::firstRootInlineBox() const
{
    ASSERT_NOT_REACHED();
    return {};
}

InlineIterator::LineBoxIterator LineLayoutScion::firstLineBox() const
{
    ASSERT_NOT_REACHED();
    return {};
}

InlineIterator::LineBoxIterator LineLayoutScion::lastLineBox() const
{
    ASSERT_NOT_REACHED();
    return {};
}

const RenderBlockFlow& LineLayoutScion::flow() const
{
    ASSERT_NOT_REACHED();
    return *m_flow;
}

RenderBlockFlow& LineLayoutScion::flow()
{
    ASSERT_NOT_REACHED();
    return *m_flow;
}

void LineLayoutScion::releaseCaches(RenderView&)
{
    ASSERT_NOT_REACHED();
}

bool LineLayoutScion::contentNeedsVisualReordering() const
{
    ASSERT_NOT_REACHED();
    return {};
}

bool LineLayoutScion::isDamaged() const
{
    ASSERT_NOT_REACHED();
    return {};
}

const Layout::InlineDamage* LineLayoutScion::damage() const
{
    ASSERT_NOT_REACHED();
    return {};
}

bool LineLayoutScion::hasDetachedContent() const
{
    ASSERT_NOT_REACHED();
    return {};
}

#if ENABLE(TREE_DEBUGGING)
void LineLayoutScion::outputLineTree(WTF::TextStream&, size_t) const
{
    ASSERT_NOT_REACHED();
}
#endif

}
}
