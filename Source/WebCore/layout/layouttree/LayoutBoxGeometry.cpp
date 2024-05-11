/*
 * Copyright (C) 2018 Apple Inc. All rights reserved.
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
#include "LayoutBoxGeometry.h"

#include <wtf/TZoneMallocInlines.h>

struct HorizontalEdgesRaw {
    int32_t start;
    int32_t end;
};

extern "C" WEBCORE_EXPORT HorizontalEdgesRaw BoxGeometry_horizontalMargin(const void* p)
{
    auto edges = static_cast<const WebCore::Layout::BoxGeometry*>(p)->horizontalMargin();
    return { edges.start.rawValue(), edges.end.rawValue() };
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_marginBefore(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->marginBefore().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_marginStart(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->marginStart().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_marginAfter(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->marginAfter().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_marginEnd(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->marginEnd().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_borderStart(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->borderStart().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_borderEnd(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->borderEnd().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_paddingStart(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->paddingStart().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_paddingEnd(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->paddingEnd().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_borderAndPaddingBefore(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->borderAndPaddingBefore().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_horizontalBorderAndPadding(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->horizontalBorderAndPadding().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_verticalBorderAndPadding(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->verticalBorderAndPadding().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_contentBoxLeft(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->contentBoxLeft().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_contentBoxRight(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->contentBoxRight().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_contentBoxHeight(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->contentBoxHeight().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_contentBoxWidth(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->contentBoxWidth().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_borderBoxHeight(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->borderBoxHeight().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_borderBoxWidth(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->borderBoxWidth().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_marginBoxHeight(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->marginBoxHeight().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_marginBoxWidth(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->marginBoxWidth().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_marginBorderAndPaddingStart(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->marginBorderAndPaddingStart().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_marginBorderAndPaddingEnd(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->marginBorderAndPaddingEnd().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_horizontalMarginBorderAndPadding(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->horizontalMarginBorderAndPadding().rawValue();
}

extern "C" WEBCORE_EXPORT void BoxGeometry_setTopLeft(void* p, int32_t x, int32_t y)
{
    static_cast<WebCore::Layout::BoxGeometry*>(p)->setTopLeft({ WebCore::LayoutUnit::fromRawValue(x), WebCore::LayoutUnit::fromRawValue(y) });
}

extern "C" WEBCORE_EXPORT void BoxGeometry_setContentBoxHeight(void* p, int32_t height)
{
    static_cast<WebCore::Layout::BoxGeometry*>(p)->setContentBoxHeight(WebCore::LayoutUnit::fromRawValue(height));
}

extern "C" WEBCORE_EXPORT void BoxGeometry_setContentBoxWidth(void* p, int32_t width)
{
    static_cast<WebCore::Layout::BoxGeometry*>(p)->setContentBoxWidth(WebCore::LayoutUnit::fromRawValue(width));
}

extern "C" WEBCORE_EXPORT void BoxGeometry_setHorizontalMargin(void* p, int32_t start, int32_t end)
{
    static_cast<WebCore::Layout::BoxGeometry*>(p)->setHorizontalMargin(WebCore::Layout::BoxGeometry::HorizontalEdges { WebCore::LayoutUnit::fromRawValue(start), WebCore::LayoutUnit::fromRawValue(end) });
}

extern "C" WEBCORE_EXPORT void BoxGeometry_setVerticalSpaceForScrollbar(void* p, int32_t scrollbar_height)
{
    static_cast<WebCore::Layout::BoxGeometry*>(p)->setVerticalSpaceForScrollbar(WebCore::LayoutUnit::fromRawValue(scrollbar_height));
}

extern "C" WEBCORE_EXPORT void BoxGeometry_setHorizontalSpaceForScrollbar(void* p, int32_t scrollbar_width)
{
    static_cast<WebCore::Layout::BoxGeometry*>(p)->setHorizontalSpaceForScrollbar(WebCore::LayoutUnit::fromRawValue(scrollbar_width));
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_top(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->top().rawValue();
}

extern "C" WEBCORE_EXPORT int32_t BoxGeometry_left(const void* p)
{
    return static_cast<const WebCore::Layout::BoxGeometry*>(p)->left().rawValue();
}

namespace WebCore {
namespace Layout {

WTF_MAKE_TZONE_OR_ISO_ALLOCATED_IMPL(BoxGeometry);

BoxGeometry::BoxGeometry(const BoxGeometry& other)
    : m_topLeft(other.m_topLeft)
    , m_contentBoxWidth(other.m_contentBoxWidth)
    , m_contentBoxHeight(other.m_contentBoxHeight)
    , m_margin(other.m_margin)
    , m_border(other.m_border)
    , m_padding(other.m_padding)
    , m_verticalSpaceForScrollbar(other.m_verticalSpaceForScrollbar)
    , m_horizontalSpaceForScrollbar(other.m_horizontalSpaceForScrollbar)
#if ASSERT_ENABLED
    , m_hasValidTop(other.m_hasValidTop)
    , m_hasValidLeft(other.m_hasValidLeft)
    , m_hasValidHorizontalMargin(other.m_hasValidHorizontalMargin)
    , m_hasValidVerticalMargin(other.m_hasValidVerticalMargin)
    , m_hasValidBorder(other.m_hasValidBorder)
    , m_hasValidPadding(other.m_hasValidPadding)
    , m_hasValidContentBoxHeight(other.m_hasValidContentBoxHeight)
    , m_hasValidContentBoxWidth(other.m_hasValidContentBoxWidth)
    , m_hasPrecomputedMarginBefore(other.m_hasPrecomputedMarginBefore)
#endif
{
}

BoxGeometry::~BoxGeometry()
{
}

Rect BoxGeometry::marginBox() const
{
    auto borderBox = this->borderBox();

    Rect marginBox;
    marginBox.setTop(borderBox.top() - marginBefore());
    marginBox.setLeft(borderBox.left() - marginStart());
    marginBox.setHeight(borderBox.height() + marginBefore() + marginAfter());
    marginBox.setWidth(borderBox.width() + marginStart() + marginEnd());
    return marginBox;
}

Rect BoxGeometry::borderBox() const
{
    Rect borderBox;
    borderBox.setTopLeft({ });
    borderBox.setSize({ borderBoxWidth(), borderBoxHeight() });
    return borderBox;
}

Rect BoxGeometry::paddingBox() const
{
    auto borderBox = this->borderBox();

    Rect paddingBox;
    paddingBox.setTop(borderBox.top() + borderBefore());
    paddingBox.setLeft(borderBox.left() + borderStart());
    paddingBox.setHeight(borderBox.bottom() - verticalSpaceForScrollbar() - borderAfter() - borderBefore());
    paddingBox.setWidth(borderBox.width() - borderEnd() - horizontalSpaceForScrollbar() - borderStart());
    return paddingBox;
}

Rect BoxGeometry::contentBox() const
{
    Rect contentBox;
    contentBox.setTop(contentBoxTop());
    contentBox.setLeft(contentBoxLeft());
    contentBox.setWidth(contentBoxWidth());
    contentBox.setHeight(contentBoxHeight());
    return contentBox;
}

void BoxGeometry::reset()
{
    setTopLeft({ });

    setHorizontalMargin({ });
    setVerticalMargin({ });
    setBorder({ });
    setPadding({ });

    setContentBoxSize({ });

    setVerticalSpaceForScrollbar({ });
    setHorizontalSpaceForScrollbar({ });
}

}
}

